# -------------------------------------------------------------------------------
# Service Accounts & Core Identifiers
# -------------------------------------------------------------------------------
data "google_storage_transfer_project_service_account" "default" {
  project = var.project_id
}

resource "random_id" "id" {
  byte_length = 8
}

module "source_bucket" {
  source        = "./modules/gcs"
  project_id    = var.project_id
  name          = "${var.source_bucket_name_prefix}-${var.project_id}"
  storage_class = var.storage_class
  location      = var.source_bucket_location
  force_destroy = var.bucket_force_destroy
  cors          = []
  contents      = var.source_files
  notifications = [
    {
      event_types    = ["OBJECT_FINALIZE"]
      payload_format = "JSON_API_V1"
      topic_id       = module.gcs_updates.topic_id
    }
  ]
  uniform_bucket_level_access = true
}

module "destination_bucket" {
  source                      = "./modules/gcs"
  project_id                  = var.project_id
  name                        = "${var.destination_bucket_name_prefix}-${var.project_id}"
  storage_class               = var.storage_class
  location                    = var.destination_bucket_location
  force_destroy               = var.bucket_force_destroy
  cors                        = []
  contents                    = []
  uniform_bucket_level_access = true
}

# Notification Pub/Sub Topic for STS status alerts
module "notification_topic" {
  source        = "./modules/pubsub"
  topic_name    = var.pubsub_topic_name
  enable_schema = false
}