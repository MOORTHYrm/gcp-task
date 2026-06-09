# ─────────────────────────────────────────────
# Enable Required GCP APIs
# ─────────────────────────────────────────────
resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

# ─────────────────────────────────────────────
# VPC Network
# ─────────────────────────────────────────────
resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.apis]
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  ip_cidr_range = "10.0.0.0/18"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.48.0.0/14"
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.52.0.0/20"
  }
}

# ─────────────────────────────────────────────
# Artifact Registry — pythontest
# ─────────────────────────────────────────────
resource "google_artifact_registry_repository" "pythontest" {
  provider      = google
  location      = var.region
  repository_id = var.registry_name
  description   = "Docker repository for Python app"
  format        = "DOCKER"
  depends_on    = [google_project_service.apis]
}

# ─────────────────────────────────────────────
# Service Account for GKE Nodes
# ─────────────────────────────────────────────
resource "google_service_account" "gke_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "gke_sa_roles" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/stackdriver.resourceMetadata.writer",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.gke_sa.email}"
}

# ─────────────────────────────────────────────
# GKE Cluster — prod-cluster
# ─────────────────────────────────────────────
resource "google_container_cluster" "primary" {
  provider = google-beta
  name     = var.cluster_name
  location = var.zone
  deletion_protection = false  # Set this to false

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  depends_on = [
    google_project_service.apis,
    google_compute_subnetwork.subnet,
  ]
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    preemptible  = false
    machine_type = var.machine_type
    disk_size_gb = 50
    disk_type    = "pd-standard"

    service_account = google_service_account.gke_sa.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    labels = {
      env     = "production"
      cluster = var.cluster_name
    }

    tags = ["gke-node", var.cluster_name]
  }
}

# ─────────────────────────────────────────────
# Static External IP for Load Balancer
# ─────────────────────────────────────────────
resource "google_compute_global_address" "lb_ip" {
  name       = "${var.app_name}-lb-ip"
  depends_on = [google_project_service.apis]
}

# ─────────────────────────────────────────────
# Cloud DNS — import existing zone, add A records
# Run first: terraform import google_dns_managed_zone.prod_zone prod-zone
# ─────────────────────────────────────────────
resource "google_dns_managed_zone" "prod_zone" {
  name        = "prod-zone"
  dns_name    = "${var.domain}."
  description = "DNS zone for ${var.domain}"
  depends_on  = [google_project_service.apis]

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_dns_record_set" "app_a_record" {
  name         = "${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.prod_zone.name
  rrdatas      = [google_compute_global_address.lb_ip.address]
}

resource "google_dns_record_set" "app_www_record" {
  name         = "www.${var.domain}."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.prod_zone.name
  rrdatas      = [google_compute_global_address.lb_ip.address]
}

# ─────────────────────────────────────────────
# GitHub Actions Service Account
# (NO SA key — blocked by org policy)
# Uses Workload Identity Federation instead
# ─────────────────────────────────────────────
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions SA (Workload Identity)"
}

resource "google_project_iam_member" "github_actions_roles" {
  for_each = toset([
    "roles/artifactregistry.writer",
    "roles/container.developer",
    "roles/iam.serviceAccountTokenCreator",
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# ─────────────────────────────────────────────
# Workload Identity Federation
# Keyless auth: GitHub OIDC token → GCP access token
# ─────────────────────────────────────────────
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-actions-pool"
  display_name              = "GitHub Actions Pool"
  disabled                  = false
  depends_on                = [google_project_service.apis]
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC Provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  # Only YOUR repo can authenticate — security boundary
  attribute_condition = "attribute.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "github_wif_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_repo}"
}
