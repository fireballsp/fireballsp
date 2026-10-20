variable "location" { type = string }

variable "scheduler_jobs" {
  type = map(object({
    schedule  = string
    time_zone = string
    http_target = object({
      uri         = string
      http_method = string
      headers     = map(string)
    })
  }))
}