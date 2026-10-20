variable "project_id" { type = string }

variable "location" { type = string }

variable "service_accounts" {
  type    = map(object({ account_id = string, display_name = string }))
  default = {}
}

variable "bindings" {
  type    = map(list(string))
  default = {}
}

variable "cloud_run_name_be" { type = string }

variable "cloud_run_name_wrk" { type = string }

variable "cloud_tasks_name" { type = string }

variable "github_permissions" {
  type = map(object({
    role      = string
    resources = list(string)
  }))
}

variable "project_number" { type = string }

variable "gh_repo_workload_identity" { type = string }