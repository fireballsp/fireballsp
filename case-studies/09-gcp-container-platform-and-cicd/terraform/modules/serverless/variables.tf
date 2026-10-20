variable "location" { type = string }

variable "project_id" { type = string }

variable "db_instance_name" { type = string }

variable "bucket_name" { type = string }

variable "cloudrun_functions_map" {
  default = {} # Allows the variable to be optional with an empty map as default
  type = map(object({
    entry_point      = string
    runtime          = string
    description      = string
    source_archive   = string
    env_vars         = map(string)
    sa_email_address = string
  }))
}

variable "cloudrun_jobs_map" {
  default = {} # Allows the variable to be optional with an empty map as default
  type = map(object({
    docker_image      = string
    sa_email_address  = string
    cloudsql_instance = bool
    env_vars          = map(string)
  }))
}

variable "cloudrun_services_map" {
  type = map(object({
    docker_image      = string
    exposed_port      = number
    sa_email_address  = string
    session_affinity  = bool
    cloudsql_instance = bool
    env_vars          = map(string)
    env_secrets = optional(map(object({
      secret_name = string
      version     = string
    })), {})
  }))
}
