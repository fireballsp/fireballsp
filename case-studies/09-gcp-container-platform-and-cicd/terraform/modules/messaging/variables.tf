variable "location" { type = string }

variable "queue_name" { type = list(string) }

variable "service_account" {
  type     = string
  default  = null
  nullable = true
}
