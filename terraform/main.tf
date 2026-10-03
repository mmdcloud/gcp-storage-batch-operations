# Storage Intelligence must be enabled for batch operations to work
resource "google_storage_control_project_intelligence_config" "project_intel" {
  # The project ID or project number
  name           = var.project_id
  edition_config = "STANDARD"

  # Optional: Define bucket filters to narrow down the scope
  filter {
    included_cloud_storage_locations {
      locations = ["us-central1", "asia-south"]
    }
    excluded_cloud_storage_buckets {
      bucket_id_regexes = ["temp-cache-*", "test-bucket-*"]
    }
  }
}

# -------------------------------------------------------------------------------
# Service Accounts & Core Identifiers
# -------------------------------------------------------------------------------
resource "random_id" "id" {
  byte_length = 8
}

data "google_project" "project" {}

module "gcs_updates" {
  source        = "./modules/pubsub"
  topic_name    = var.gcs_updates_topic_name
  enable_schema = false
  topic_iam     = {}
  subscriptions = {}
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
    custom_metadata = { name = "madmax" }
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

resource "google_kms_key_ring" "gcs" {
  name     = "${var.source_bucket_name_prefix}-keyring"
  location = var.source_bucket_location # must match the bucket location
  project  = var.project_id
}

resource "google_kms_crypto_key" "key" {
  name            = "${var.source_bucket_name_prefix}-key"
  key_ring        = google_kms_key_ring.gcs.id
  rotation_period = "7776000s" # 90 days
  purpose         = "ENCRYPT_DECRYPT"

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = "SOFTWARE" # use "HSM" if you need it
  }

  lifecycle {
    prevent_destroy = false # set true outside of dev; keys can't be fully deleted
  }
}


# Storage Batch Operations service agent (performs the rewrite)
resource "google_kms_crypto_key_iam_member" "batch_ops_agent" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-storagebatchoperations.iam.gserviceaccount.com"
}

module "rekey_job" {
  source = "./modules/cloud-batch-operations"

  job_id                   = "rekey"
  included_object_prefixes = [""]
  bucket                   = module.source_bucket.bucket_name

  rewrite_object = {
    kms_key = google_kms_crypto_key.key.id
  }
}

module "object_hold_job" {
  source = "./modules/cloud-batch-operations"

  job_id                   = "object-hold-job"
  included_object_prefixes = [""]
  bucket                   = module.source_bucket.bucket_name
  put_object_hold = {
    event_based_hold = "SET"
  }
}