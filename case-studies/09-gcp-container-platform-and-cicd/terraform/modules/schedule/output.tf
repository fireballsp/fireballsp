output "scheduler_job_ids" {
  value = { for k, v in google_cloud_scheduler_job.cron_job : k => v.id }
}

output "scheduler_job_state" {
  value = { for k, v in google_cloud_scheduler_job.cron_job : k => v.state }
}