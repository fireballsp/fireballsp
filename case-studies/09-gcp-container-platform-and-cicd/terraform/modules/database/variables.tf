variable "location" { type = string }

variable "pqsql_saas_name" { type = string }

variable "pqsql_saas_database_name" { type = string }

variable "sql_password" {
  type      = string
  sensitive = true
}

variable "allowed_ips" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}