resource "google_sql_database_instance" "postgres_instance_name" {
  name             = var.pqsql_saas_name
  database_version = "POSTGRES_15"
  region           = var.location

  settings {
    tier = "db-f1-micro"

    disk_size = 10
    disk_type = "PD_HDD"

    ip_configuration {
      ssl_mode     = "ENCRYPTED_ONLY"
      ipv4_enabled = true

      dynamic "authorized_networks" {
        for_each = var.allowed_ips
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.value
        }
      }
    }

    backup_configuration {
      enabled = false
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }

    database_flags {
      name  = "log_connections"
      value = "on"
    }

    database_flags {
      name  = "log_disconnections"
      value = "on"
    }

    database_flags {
      name  = "log_min_messages"
      value = "warning"
    }

    database_flags {
      name  = "log_checkpoints"
      value = "on"
    }

    database_flags {
      name  = "log_lock_waits"
      value = "on"
    }

    database_flags {
      name  = "log_temp_files"
      value = "0"
    }

    database_flags {
      name  = "log_min_duration_statement"
      value = "-1"
    }
  }

  deletion_protection = false

  lifecycle {
    ignore_changes = [
      settings[0].activation_policy,
    ]
  }
}

resource "google_sql_database" "postgres_instance_database" {
  name     = var.pqsql_saas_database_name
  instance = google_sql_database_instance.postgres_instance_name.name

  depends_on = [google_sql_database_instance.postgres_instance_name]
}

resource "google_sql_user" "db_user" {
  name     = "usr_master_app"
  instance = google_sql_database_instance.postgres_instance_name.name
  password = var.sql_password

  depends_on = [google_sql_database_instance.postgres_instance_name]
}