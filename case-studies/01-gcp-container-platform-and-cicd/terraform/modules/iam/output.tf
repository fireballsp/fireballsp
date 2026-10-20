output "sa_emails" {
  value       = { for k, v in google_service_account.sa : k => v.email }
  description = "Service account email addresses keyed by their configuration names."
}

output "sa_email" {
  value       = { for k, v in google_service_account.sa : k => v.email }
  description = "Compatibility alias for sa_emails."
}