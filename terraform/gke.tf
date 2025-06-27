# terraform/gke.tf

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

resource "google_container_cluster" "gke" {
  name               = "${var.project_name}-gke-cluster"
  location           = var.gcp_region
  initial_node_count = 2
  min_master_version = var.kubernetes_version

  node_config {
    machine_type = var.gke_machine_type
  }
}

resource "google_storage_bucket" "velero_backups_gcs" {
  name     = "${var.project_name}-velero-backups-gcp"
  location = "US" # La localité doit être multi-régionale pour une meilleure résilience
  force_destroy = true
}
