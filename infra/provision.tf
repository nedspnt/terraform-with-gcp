# GCP provider

provider "google" {
    project = var.gcp_project
    region = var.gcp_region
}

resource "google_project_service" "composer_api" {
    provider = google
    project = var.gcp_project
    service = "composer.googleapis.com"
    disable_on_destroy = false  // prevent automatic disabling of all environments
}

resource "google_service_account" "custom_service_account" {
    provider = google
    account_id = "custom-service-account"
    display_name = "Custom Service Account"
}

resource "google_project_iam_member" "custom_service_account" {
    provider = google
    project = var.gcp_project
    member = format("serviceAccount:%s", google_service_account.custom_service_account.email)
    role = "roles/composer.worker"
}

resource "google_service_account_iam_member" "custom_service_account" {
    provider = google
    service_account_id = google_service_account.custom_service_account.name
    role = "roles/composer.ServiceAgentV2Ext"
    member = format("serviceAccount:service-%s@cloudcomposer-accounts.iam.gserviceaccount.com", var.gcp_project_number)
}

resource "google_composer_environment" "example_environment" {
    provider = google
    name = "my-example-environment"

    config {
        software_config {
          image_version = "composer-2.5.4-airflow-2.6.3"
        }

        node_config {
          service_account = google_service_account.custom_service_account.email
        }
    }
}

