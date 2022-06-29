module "bucket" {
  source = "terraform-google-modules/cloud-storage/google"
  version = "3.2.0"
  names       = var.bucket_name
  project_id = var.project_id
  location   = "us-east1"
  prefix = ""
}

module "pubsub" {
  source  = "terraform-google-modules/pubsub/google"
  version = "~> 1.8"
  topic      = var.topic_name
  project_id = var.project_id
  }

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