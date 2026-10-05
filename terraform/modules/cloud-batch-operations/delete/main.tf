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

  dynamic "delete_object" {
    for_each = var.delete_object != null ? [var.delete_object] : []
    content {
      permanent_object_deletion_enabled = delete_object.value.permanent_object_deletion_enabled
    }
  }
}