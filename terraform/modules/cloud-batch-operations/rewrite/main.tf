resource "google_storage_batch_operations_job" "this" {
  job_id            = var.job_id
  project           = var.project
  delete_protection = var.delete_protection

  bucket_list {
    buckets {
      bucket = var.bucket

      dynamic "prefix_list" {
        for_each = var.included_object_prefixes != null ? [1] : []
        content {
          included_object_prefixes = var.included_object_prefixes
        }
      }

      dynamic "manifest" {
        for_each = var.manifest_location != null ? [1] : []
        content {
          manifest_location = var.manifest_location
        }
      }
    }
  }
  
  dynamic "rewrite_object" {
    for_each = var.rewrite_object != null ? [var.rewrite_object] : []
    content {
      kms_key = rewrite_object.value.kms_key
    }
  }
}