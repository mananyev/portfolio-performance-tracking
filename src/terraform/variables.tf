variable "credentials" {
  # Explanation:
  # this is the path to JSON file with credentials
  # for the service account with extensive permissions
  # (incl. BigQuery Admin, Compute Admin, Storage Admin).
  description = "Service Account Infrastructure Credentials"
  default     = "~/.gc/gcp-zoomcamp-service.json"
}

variable "project" {
  # This is the same project I used for the DE-zoomcamp.
  description = "DE-zoomcamp project: Portfolio performance tracking"
  default     = "peaceful-tome-448411-p7"
}

variable "region" {
  # Update the below to your desired region
  description = "Region"
  default     = "EU"
}

variable "location" {
  # Update the below to your desired location
  description = "Project Location"
  default     = "europe-west3"
  # 2 is London, 3 is Frankfurt, 10 is Berlin
}

variable "bq_dataset_name" {
  # Update the below to what you want your dataset to be called
  description = "Portfolio Performance Tracking Dataset"
  default     = "portfolio_tracking"
}

variable "gcs_bucket_name" {
  # Update the below to a unique bucket name
  description = "Portfolio Performance Tracking Bucket"
  default     = "ma-portfolio-performance-tracking-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}
