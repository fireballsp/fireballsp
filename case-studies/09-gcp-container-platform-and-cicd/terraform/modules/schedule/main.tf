resource "google_cloud_scheduler_job" "cron_job" {
  for_each = var.scheduler_jobs

  name             = each.key
  region           = var.location
  description      = "Job for ${each.key}"
  schedule         = each.value.schedule
  time_zone        = each.value.time_zone
  attempt_deadline = "320s"

  http_target {
    http_method = each.value.http_target.http_method
    uri         = each.value.http_target.uri
    headers     = each.value.http_target.headers
  }
}