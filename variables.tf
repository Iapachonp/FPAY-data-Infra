variable "project_id" {
  description = "ID of the project in which to provision resources."
  type        = string
  default     = "ipachon-test"
}
variable "bucket_name" {
  description = "Name of the bucket to be created"
  type        = list(string)
  default     = ["dataops-test-7e904d691bf2"]
}
variable "topic_name" {
  description = "Name of the pubsub topic"
  type        = string
  default     = "topic-dataops-test"
}
variable "dataset_name" {
  description = "Name of the pubsub topic"
  type        = string
  default     = "dt_test"
}
variable "delete_contents_on_destroy"{
  description = "if enabled, all tables will be destroyed if apply terraform destroy otherwise it will fail"
  type = bool
  default = true
}
variable "function_name" {
  description = "Name of the GCP function"
  type        = string
  default     = "function-dataops-tes"
}
variable "cron_job_name" {
  description = "Name of the cronjob for covid ingestion"
  type        = string
  default     = "cron-job-covid-ingerstion"
}
variable "topic_cron_job_name" {
  description = "Name of the topic for covid ingestion"
  type        = string
  default     = "topic-cron-job-covid"
}
variable "csv_function_name" {
  description = "Name of the function that will upload csv covid file to the bucket"
  type        = string
  default     = "csv_function_name"
}
