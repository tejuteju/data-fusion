provider "google" {
  project=var.project_id
}
data "google_project" "project"{

}
locals {
 googleapis = [
   "datafusion.googleapis.com"
 ]
}
resource "google_project_service" "apis" {
 for_each           = toset(local.googleapis)
 project            = var.project_id
 service            = each.key
 disable_on_destroy = false
}
resource "google_service_account" "dataproc_sa" {
  account_id   = var.sa
  display_name = "A service account that will be used in the dataproc clusters"
}
resource "google_project_iam_member" "dataproc_datafusuion_runner" {
  project = var.project_id
  role    = "roles/datafusion.runner"
  member  = "serviceAccount:${google_service_account.dataproc_sa.email}"
}
resource "google_service_account_iam_member" "datafusion_user_dataproc_sa" {
  service_account_id = google_service_account.dataproc_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-datafusion.iam.gserviceaccount.com"
}
resource "google_compute_network" "custom-test" {
  name                    = var.network
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "df-subnet" {
  name          = var.sub_network
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.custom-test.id 
}

resource "google_data_fusion_instance" "data-fusion-private-instance" {
  name                          = var.df_instance
  region                        = var.region
  type                          = var.edition
  enable_stackdriver_logging    = var.enable_logging
  private_instance              = var.private_instance
  network_config {
    network                     = google_compute_network.custom-test.name
    ip_allocation               = var.private_ip_range
  }
  labels = {
    example_key = var.label_value
  }
  dataproc_service_account = google_service_account.dataproc_sa.email
}
