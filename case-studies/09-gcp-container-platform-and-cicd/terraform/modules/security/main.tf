resource "google_secret_manager_secret" "secret-basic" {
  for_each  = var.secrets
  secret_id = each.key

  replication {
    user_managed {
      replicas {
        location = var.location
      }
    }
  }

  deletion_protection = false
}

resource "google_secret_manager_secret_version" "secret-basic-version" {
  for_each    = var.secrets
  secret      = google_secret_manager_secret.secret-basic[each.key].id
  secret_data = each.value
}