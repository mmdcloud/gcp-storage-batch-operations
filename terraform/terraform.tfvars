# -------------------------------------------------------------------------------
# Environment Overrides
# -------------------------------------------------------------------------------
project_id = "encoded-alpha-457108-e8"
region     = "asia-south1"

# Bucket Names and Locations
source_bucket_name_prefix      = "source"
source_bucket_location         = "asia-south1"
destination_bucket_name_prefix = "destination"
destination_bucket_location    = "asia-south2"
storage_class                  = "STANDARD"
bucket_force_destroy           = true

# Pub/Sub Messaging
pubsub_topic_name              = "sts-notifications"
gcs_updates_topic_name         = "gcs-source-bucket-events"
transfer_subscription_name     = "sts-event-stream-sub"
subscription_message_retention = "604800s"
subscription_ack_deadline      = 30

# Transfer Job Settings
transfer_job_description      = "Scheduled GCS to GCS Storage Transfer Service"
replication_job_description   = "Continuous replication from raw to processed bucket"
schedule_end_offset_hours     = 48
schedule_start_offset_minutes = 5
schedule_repeat_interval      = "86400s" # Daily execution
delete_objects_unique_in_sink = false

# Sample Input Files
source_files = [
  {
    name        = "image-1.jpg"
    content     = ""
    source_path = "../src/image-1.jpg"
  },
  {
    name        = "image-2.jpg"
    content     = ""
    source_path = "../src/image-2.jpg"
  },
  {
    name        = "image-3.jpg"
    content     = ""
    source_path = "../src/image-3.jpg"
  }
]