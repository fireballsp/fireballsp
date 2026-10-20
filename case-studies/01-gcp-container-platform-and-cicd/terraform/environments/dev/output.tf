output "sa_emails" {
  description = "Map of all service accounts created by the IAM module (Key => Email)."
  value       = module.iam_dev.sa_emails
}

output "secret_metadata" {
  description = "Mapping of all secrets and their metadata"
  value       = module.security_dev.secret_metadata
}

output "cloud_run_urls" {
  description = "Mapping of all Cloud Run services and their respective URLs"
  value       = module.serverless_dev.cloud_run_urls
}

output "check_expirations_scheduler_job" {
  description = "Name of the Cloud Scheduler job that calls /tasks/check-expirations."
  value       = "check-expiration"
}

output "postgres_instance_public_ip" {
  value = module.database_dev.postgres_instance_public_ip
}

output "instances_public_ips" {
  value = module.compute_dev.instances_public_ips
}

output "artifact_registry_repository_urls" {
  value = module.ci_cd_dev.repository_urls
}

output "vpc_subnets_info" {
  value = module.networking_dev.subnets_info
}

output "scheduler_job_state" {
  value = module.schedule.scheduler_job_state
}
