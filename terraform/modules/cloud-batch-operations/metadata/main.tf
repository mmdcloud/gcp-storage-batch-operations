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

  dynamic "put_metadata" {
    for_each = var.put_metadata != null ? [var.put_metadata] : []
    content {
      content_disposition = put_metadata.value.content_disposition
      content_encoding    = put_metadata.value.content_encoding
      content_language    = put_metadata.value.content_language
      content_type        = put_metadata.value.content_type
      cache_control       = put_metadata.value.cache_control
      custom_time         = put_metadata.value.custom_time
      custom_metadata     = put_metadata.value.custom_metadata
    }
  }
}