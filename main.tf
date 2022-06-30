# module "bucket" {
#   source = "terraform-google-modules/cloud-storage/google"
#   version = "3.2.0"
#   names       = var.bucket_name
#   project_id = var.project_id
#   location   = "us-east1"
#   prefix = ""
# }

## IN CASE OF MORE COMPLEX CONFIG USE MODULE RATHER THAN THE RAW RESOURCE

resource "google_storage_bucket" "trigger_bucket" {
  name          = var.bucket_name[0]
  force_destroy = true
  location      = "us-east1"
  project       = var.project_id
  storage_class = "REGIONAL"
}

# module "pubsub" {
#   source  = "terraform-google-modules/pubsub/google"
#   version = "~> 1.8"
#   topic      = var.topic_name
#   project_id = var.project_id
#   }

## IN CASE OF MORE COMPLEX CONFIG USE MODULE RATHER THAN THE RAW RESOURCE

resource "google_pubsub_topic" "topic" {
  project      = var.project_id
  name         = var.topic_name
}

## BIGQUERY MODULE USED FOR EASE 

module "bigquery" {
  source                     = "terraform-google-modules/bigquery/google"
  version = "5.4.1"
  dataset_id                 = var.dataset_name
  dataset_name               = var.dataset_name
  description                = "Fpay dataset test"
  project_id                 = var.project_id
  location                   = "us-east1"
  delete_contents_on_destroy = var.delete_contents_on_destroy
  tables = [
    {
      table_id           = "covid",
      schema             = file("covid_bq_schema.json"),
      time_partitioning  = null,
      range_partitioning = null,
      expiration_time    = 2524604400000, # 2050/01/01
      clustering         = [],
      labels = {
        env      = "dev"
        billable = "true"
        owner    = "ipachon"
      },
    }
  ]
  dataset_labels = {
    env      = "dev"
    billable = "true"
    owner    = "ipachon"
  }
}
## GCP FUNCTION MODULE USED FOR EASE 

module "localhost_function" {
  source = "terraform-google-modules/event-function/google"

  description = "Returns back the random file content"
  entry_point = "hello_gcs"

  event_trigger = {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.trigger_bucket.name
  }
  
  name             = var.function_name
  project_id       = var.project_id
  region           = "us-east1"
  source_directory = "${path.module}/function_source"
  runtime          = "python39"

  # source_dependent_files = [local_file.file]
  depends_on             = [google_storage_bucket.trigger_bucket]
}

resource "null_resource" "wait_for_function" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [module.localhost_function]
}