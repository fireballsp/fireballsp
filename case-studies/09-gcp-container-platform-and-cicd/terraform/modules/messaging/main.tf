resource "google_cloud_tasks_queue" "queues" {
  for_each = toset(var.queue_name)
  name     = each.key
  location = var.location

  rate_limits {
    max_concurrent_dispatches = 3
    max_dispatches_per_second = 2
  }

  retry_config {
    max_attempts       = 5
    max_retry_duration = "0s"
    max_backoff        = "60s"
    min_backoff        = "5s"
    max_doublings      = 4
  }

  stackdriver_logging_config {
    sampling_ratio = 0.1
  }
}