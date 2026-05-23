output "gke_cluster_name" {
  description = "GKE Cluster name"
  value       = google_container_cluster.primary.name
}

output "gke_cluster_endpoint" {
  description = "GKE Cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "gke_zone" {
  description = "GKE Cluster zone"
  value       = google_container_cluster.primary.location
}

output "artifact_registry_url" {
  description = "Artifact Registry URL for Docker push"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${var.registry_name}"
}

output "load_balancer_ip" {
  description = "Static IP address of the Load Balancer — add this as an A record in your registrar"
  value       = google_compute_global_address.lb_ip.address
}

output "dns_nameservers" {
  description = "Cloud DNS nameservers — point your domain registrar to these"
  value       = google_dns_managed_zone.prod_zone.name_servers
}

output "workload_identity_provider" {
  description = "Workload Identity Provider — paste as GCP_WORKLOAD_IDENTITY_PROVIDER GitHub secret"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_actions_sa_email" {
  description = "GitHub Actions SA email — paste as GCP_SA_EMAIL GitHub secret"
  value       = google_service_account.github_actions_sa.email
}
