
resource "google_storage_bucket" "trigger_bucket" {
  name          = var.bucket_name[0]
  force_destroy = true
  location      = "us-east1"
  project       = var.project_id
  storage_class = "REGIONAL"
}

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
  service_account_email      = "ipachon-test@appspot.gserviceaccount.com"

  # source_dependent_files = [local_file.file]
  depends_on             = [google_storage_bucket.trigger_bucket]
}

resource "null_resource" "wait_for_function" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [module.localhost_function]
}

###################################################################################
############## CSV2BUCKET INGESTION FUNCTION AND CRONJOB CONFIGURATION ############
###################################################################################

resource "google_pubsub_topic" "topic2" {
  name = var.topic_cron_job_name
  project      = var.project_id
  message_retention_duration = "86600s"
}

resource "google_pubsub_subscription" "sub_topic2" {
  name  = "topic-covid-subscription"
  project      = var.project_id
  topic = google_pubsub_topic.topic2.name

  labels = {
    foo = "bar"
  }

  # 30 days
  message_retention_duration = "86600s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }

  enable_message_ordering    = false
}

resource "google_cloud_scheduler_job" "job" {
  name        = var.cron_job_name
  description = "cron job for covid csv ingestion"
  schedule    = "0 5 * * *" #Ingestion will be every day at 5am UTC
  project      = var.project_id
  region      = "us-east1"

  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.topic2.id
    data       = base64encode("https://github.com/nytimes/covid-19-data/blob/master/live/us-states.csv")
  }
}

module "localhost_function2" {
  source = "terraform-google-modules/event-function/google"

  description = "Returns back the random file content"
  entry_point = "main_pub_sub"

  event_trigger = {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.topic2.name
  }

  name             = var.csv_function_name
  project_id       = var.project_id
  region           = "us-east1"
  source_directory = "${path.module}/csv_2_bucket_function"
  runtime          = "python39"

  # source_dependent_files = [local_file.file]
  depends_on             = [google_pubsub_topic.topic2]
}

resource "null_resource" "wait_for_function_csv" {
  provisioner "local-exec" {
    command = "sleep 60"
  }

  depends_on = [module.localhost_function2]
}