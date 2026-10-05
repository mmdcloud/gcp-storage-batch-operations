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

  dynamic "put_object_hold" {
    for_each = var.put_object_hold != null ? [var.put_object_hold] : []
    content {
      event_based_hold = put_object_hold.value.event_based_hold
      temporary_hold   = put_object_hold.value.temporary_hold
    }
  }
}