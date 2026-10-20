output "cloud_run_urls" {
  description = "Mapping of all Cloud Run services and their respective URLs"
  value = {
    for name, service in google_cloud_run_v2_service.cloud_run_service : name => service.uri
  }
}