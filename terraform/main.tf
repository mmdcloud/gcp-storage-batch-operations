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

module "set_metadata_job" {
  source = "./modules/cloud-batch-operations"

  job_id                   = "tf-job"
  bucket                   = module.source_bucket.bucket_name
  included_object_prefixes = ["bkt"]

  put_metadata = {
    custom_metadata = { key = "value" }
  }
}

module "delete_from_manifest" {
  source = "./modules/cloud-batch-operations"

  job_id            = "purge-old"
  bucket            = module.source_bucket.bucket_name
  manifest_location = "gs://${module.source_bucket.bucket_name}/manifests/purge.csv"
  delete_protection = true

  delete_object = {
    permanent_object_deletion_enabled = false
  }
}

module "rekey_job" {
  source = "./modules/cloud-batch-operations"

  job_id = "rekey"
  bucket = module.source_bucket.bucket_name

  rewrite_object = {
    kms_key = google_kms_crypto_key.key.id
  }
}

module "object_hold_job" {
  source = "./modules/cloud-batch-operations"

  job_id = "object-hold-job"
  bucket = module.source_bucket.bucket_name
  put_object_hold = {
    event_based_hold = ""
    temporary_hold   = ""
  }
}