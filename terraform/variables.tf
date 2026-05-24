variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "project-6b73a1f9-ef42-4074-81a"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone (prod-zone)"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
  default     = "prod-cluster"
}

variable "registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "pythontest"
}

variable "domain" {
  description = "Domain name for the Load Balancer"
  type        = string
  default     = "devopstrends.online"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "python-app"
}

variable "node_count" {
  description = "Number of nodes per zone in the GKE node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "GCE machine type for GKE nodes"
  type        = string
  default     = "e2-medium"
}

variable "min_node_count" {
  description = "Minimum nodes for autoscaling"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum nodes for autoscaling"
  type        = number
  default     = 2
}

variable "github_repo" {
  description = "GitHub repo in owner/repo format — used to scope Workload Identity"
  type        = string
  default     = "MOORTHYrm/gcp-task"
}
