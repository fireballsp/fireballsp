output "repository_urls" {
  value = {
    for k, repo in google_artifact_registry_repository.gcp_artifact_registry :
    k => "${repo.location}-docker.pkg.dev/${repo.project}/${repo.repository_id}"
  }
}