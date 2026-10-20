resource "google_artifact_registry_repository" "gcp_artifact_registry" {
  for_each = toset(var.art_reg_id)

  location      = var.location
  repository_id = each.key
  format        = "DOCKER"

  cleanup_policies {
    id     = "maintain-last-3-versions"
    action = "KEEP"
    most_recent_versions {
      keep_count = 3
    }
  }
}