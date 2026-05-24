terraform {
  backend "gcs" {
    bucket = "moorthy-terraform-state"
    prefix = "gcp-task/dev"
  }
}
