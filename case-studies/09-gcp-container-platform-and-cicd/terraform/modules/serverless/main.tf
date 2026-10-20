resource "google_cloud_run_v2_service" "cloud_run_service" {
  for_each = var.cloudrun_services_map

  name     = each.key
  location = var.location
  ingress  = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  deletion_protection = false

  scaling {
    min_instance_count = 0
    max_instance_count = 1
  }

  template {
    service_account  = each.value.sa_email_address
    session_affinity = each.value.session_affinity

    # Cloud SQL Volumes (Dinamizado pela flag)
    dynamic "volumes" {
      for_each = each.value.cloudsql_instance ? [1] : []
      content {
        name = "cloudsql"
        cloud_sql_instance {
          instances = ["${var.project_id}:${var.location}:${var.db_instance_name}"]
        }
      }
    }

    containers {
      image = each.value.docker_image

      dynamic "env" {
        for_each = each.value.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = each.value.env_secrets
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }

      ports {
        container_port = each.value.exposed_port
      }

      resources {
        cpu_idle = true
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      dynamic "volume_mounts" {
        for_each = each.value.cloudsql_instance ? [1] : []
        content {
          name       = "cloudsql"
          mount_path = "/cloudsql"
        }
      }
    }

    annotations = {
      "run.googleapis.com/cloudsql-instances"          = "${var.project_id}:${var.location}:${var.db_instance_name}"
      "run.googleapis.com/cloudsql-instance-iam-authn" = "true"
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  lifecycle {
    ignore_changes = [
      client,
      client_version,
      template[0].containers[0].image,
      template[0].labels,
      template[0].annotations,
      labels,
      annotations,
    ]
  }
}

resource "google_project_iam_member" "cloudsql_client" {
  for_each = {
    for k, v in var.cloudrun_services_map : k => v
    if v.cloudsql_instance
  }

  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${each.value.sa_email_address}"
}

resource "google_project_iam_member" "cloudsql_instanceUser" {
  for_each = {
    for k, v in var.cloudrun_services_map : k => v
    if v.cloudsql_instance
  }

  project = var.project_id
  role    = "roles/cloudsql.instanceUser"
  member  = "serviceAccount:${each.value.sa_email_address}"
}

resource "google_cloud_run_service_iam_member" "public_access" {
  for_each = var.cloudrun_services_map

  location = var.location
  service  = google_cloud_run_v2_service.cloud_run_service[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Section to be used for Cloud Run Jobs
resource "google_cloud_run_v2_job" "jobs" {
  for_each = var.cloudrun_jobs_map

  name     = each.key
  location = var.location
  project  = var.project_id

  template {
    template {
      service_account = each.value.sa_email_address
      timeout         = "600s"

      dynamic "volumes" {
        for_each = each.value.cloudsql_instance ? [1] : []
        content {
          name = "cloudsql"
          cloud_sql_instance {
            instances = ["${var.project_id}:${var.location}:${var.db_instance_name}"]
          }
        }
      }

      containers {
        image = each.value.docker_image

        dynamic "env" {
          for_each = each.value.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "volume_mounts" {
          for_each = each.value.cloudsql_instance ? [1] : []
          content {
            name       = "cloudsql"
            mount_path = "/cloudsql"
          }
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      launch_stage,
      client,
      client_version,
      template[0].template[0].containers[0].image
    ]
  }
}


resource "google_storage_bucket_object" "functions_source_zip" {
  for_each     = var.cloudrun_functions_map
  name         = "source/${each.key}.zip"
  bucket       = var.bucket_name
  source       = each.value.source_archive
  content_type = "application/zip"
}


resource "google_cloudfunctions2_function" "functions" {
  for_each    = var.cloudrun_functions_map
  name        = each.key
  location    = var.location
  description = each.value.description

  build_config {
    runtime     = each.value.runtime
    entry_point = each.value.entry_point

    source {
      storage_source {
        bucket = google_storage_bucket_object.functions_source_zip[each.key].bucket
        object = google_storage_bucket_object.functions_source_zip[each.key].name
      }
    }
  }

  service_config {
    min_instance_count               = 0
    max_instance_count               = 1
    max_instance_request_concurrency = 1
    available_memory                 = "256M"
    timeout_seconds                  = 60
    service_account_email            = each.value.sa_email_address
    environment_variables            = each.value.env_vars

    ingress_settings = "ALLOW_INTERNAL_ONLY"

    all_traffic_on_latest_revision = true
  }
}