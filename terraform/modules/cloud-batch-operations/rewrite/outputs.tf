output "id" {
  description = "Resource ID of the batch operations job."
  value       = google_storage_batch_operations_job.this.id
}

output "job_id" {
  description = "Job ID."
  value       = google_storage_batch_operations_job.this.job_id
}