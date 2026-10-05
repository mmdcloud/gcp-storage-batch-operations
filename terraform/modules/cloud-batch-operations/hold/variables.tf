variable "job_id" {
  description = "Unique ID of the storage batch operations job."
  type        = string
}

variable "project" {
  description = "Project ID. Defaults to the provider project."
  type        = string
  default     = null
}

variable "bucket" {
  description = "Name of the bucket the job runs against."
  type        = string
}

variable "delete_protection" {
  description = "Set true to block terraform destroy of the job resource."
  type        = bool
  default     = false
}

# ---- Object selection: exactly one of prefixes / manifest (or neither = all objects) ----

variable "included_object_prefixes" {
  description = "Object name prefixes to include. Mutually exclusive with manifest_location."
  type        = list(string)
  default     = null
}

variable "manifest_location" {
  description = "GCS URI of a CSV manifest listing objects (gs://bucket/path/manifest.csv). Mutually exclusive with included_object_prefixes."
  type        = string
  default     = null
}

# ---- Transformation: exactly one must be set ----

variable "put_metadata" {
  description = "Update object metadata."
  type = object({
    content_disposition = optional(string)
    content_encoding    = optional(string)
    content_language    = optional(string)
    content_type        = optional(string)
    cache_control       = optional(string)
    custom_time         = optional(string)
    custom_metadata     = optional(map(string))
  })
  default = null
}

variable "delete_object" {
  description = "Delete objects. Set permanent_object_deletion_enabled = true to also delete noncurrent versions permanently."
  type = object({
    permanent_object_deletion_enabled = bool
  })
  default = null
}

variable "put_object_hold" {
  description = "Set/unset object holds. Values are SET or UNSET."
  type = object({
    event_based_hold = optional(string)
    temporary_hold   = optional(string)
  })
  default = null
}

variable "rewrite_object" {
  description = "Rewrite objects (e.g. re-encrypt with a new Cloud KMS key)."
  type = object({
    kms_key = string
  })
  default = null
}

# ---- Validation ----

locals {
  transformations_set = length([for t in [var.put_metadata, var.delete_object, var.put_object_hold, var.rewrite_object] : t if t != null])
}

check "single_transformation" {
  assert {
    condition     = local.transformations_set == 1
    error_message = "Exactly one of put_metadata, delete_object, put_object_hold, rewrite_object must be set."
  }
}

check "single_selector" {
  assert {
    condition     = !(var.included_object_prefixes != null && var.manifest_location != null)
    error_message = "Set either included_object_prefixes or manifest_location, not both."
  }
}