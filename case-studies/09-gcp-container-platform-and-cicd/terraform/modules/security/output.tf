output "secret_metadata" {
  value = {
    for key, secret in google_secret_manager_secret.secret-basic :
    key => {
      id        = secret.id
      secret_id = secret.secret_id
    }
  }
}
