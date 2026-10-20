variable "env_name" {
  type        = string
  default     = "dev"
  description = "Deployment environment name."
}

variable "location" {
  type    = string
  default = "us-east1"

  description = "Default region for this environment."
}

variable "project_id" {
  type        = string
  description = "Google Cloud project ID."
}

variable "project_number" {
  type        = string
  description = "Google Cloud project number."
}

variable "smtp_password" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "job_key" {
  type      = string
  sensitive = true
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "sql_password" {
  type      = string
  sensitive = true
}

variable "gcp_service_list" {
  description = "The list of APIs necessary for the project"
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
    "servicenetworking.googleapis.com",
    "iap.googleapis.com",
    "secretmanager.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "cloudtrace.googleapis.com",
    "cloudprofiler.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "appoptimize.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudasset.googleapis.com",
    "securitycenter.googleapis.com",
    "cloudtasks.googleapis.com",
    "cloudfunctions.googleapis.com"
  ]
}

variable "smtp_host" {
  type        = string
  description = "SMTP server hostname."
}

variable "smtp_user" {
  type        = string
  description = "SMTP account username."
}

variable "smtp_from" {
  type        = string
  description = "Sender address used for outbound email."
}

variable "frontend_api_url" {
  type        = string
  description = "Public base URL of the frontend API."
}

variable "frontend_origin" {
  type        = string
  description = "Allowed frontend origin used for CORS."
}

variable "frontend_url" {
  type        = string
  description = "Public frontend URL."
}

variable "worker_service_url" {
  type        = string
  description = "Cloud Run URL of the worker service."
}

variable "github_repository" {
  type        = string
  description = "GitHub owner/repository allowed by workload identity federation."
}

variable "monitoring_service_account" {
  type        = string
  description = "External monitoring service account email, without the serviceAccount: prefix."
}

variable "database_allowed_ips" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Approved client IP ranges allowed to connect to Cloud SQL."
}

variable "subnet_cidr" {
  type        = string
  description = "Private CIDR range for the regional VPC subnet."
}

variable "function_bucket_name" {
  type        = string
  description = "Globally unique Cloud Storage bucket name for function source artifacts."
}

variable "function_source_archive" {
  type        = string
  description = "Path to a locally supplied function source ZIP, relative to this environment directory."
}

variable "migration_image" {
  type        = string
  description = "Container image URI for the database migration job."
}

variable "db_instance_name" {
  type    = string
  default = "app-db-dev"

  description = "Cloud SQL instance name used by the backend service."
}

variable "database_name" {
  type        = string
  default     = "application"
  description = "Name of the application database."
}

variable "check_expirations_schedule" {
  type        = string
  default     = "0 0 * * *"
  description = "Cloud Scheduler cron expression for GET /tasks/check-expirations."
}

variable "check_expirations_time_zone" {
  type        = string
  default     = "Etc/UTC"
  description = "IANA time zone used by the scheduler."
}

variable "check_expirations_http_uri" {
  type        = string
  nullable    = true
  default     = null
  description = "Full request URI. If null, the backend Cloud Run URL is used."
}
