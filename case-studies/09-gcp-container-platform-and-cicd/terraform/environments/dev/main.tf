resource "google_project_service" "gcp_services" {
  for_each = toset(var.gcp_service_list)
  service  = each.key
}

module "security_dev" {
  depends_on = [google_project_service.gcp_services]
  source   = "../../modules/security"
  location = var.location
  secrets = {
    "${var.env_name}_smtp_password"          = var.smtp_password
    "${var.env_name}_jwt_secret"             = var.jwt_secret
    "${var.env_name}_job_trigger_key"        = var.job_key
    "${var.env_name}_admin_default_password" = var.admin_password
    "${var.env_name}_sql_app_password"       = var.sql_password
  }
}

module "iam_dev" {
  depends_on = [google_project_service.gcp_services]
  source                    = "../../modules/iam"
  project_id                = var.project_id
  project_number            = var.project_number
  location                  = var.location
  gh_repo_workload_identity = var.github_repository

  cloud_run_name_be  = "app-backend-${var.env_name}"
  cloud_run_name_wrk = "app-worker-${var.env_name}"
  cloud_tasks_name   = module.messaging.cloud_tasks_queues_details["app-tasks-${var.env_name}"].name

  # Centralize service account definitions for the service_accounts.tf resources.
  service_accounts = {
    sa_github_actions = { account_id = "sa-github-actions", display_name = "GitHub Actions Service Account" }
    sa_monitoring     = { account_id = "sa-monitoring", display_name = "Monitoring Service Account" }
    sa_cloudrun_fe    = { account_id = "sa-cloudrun-fe-${var.env_name}", display_name = "Cloud Run Frontend Service Account" }
    sa_cloudrun_be    = { account_id = "sa-cloudrun-be-${var.env_name}", display_name = "Cloud Run Backend Service Account" }
    sa_cloudrun_wrk   = { account_id = "sa-cloudrun-worker-${var.env_name}", display_name = "Cloud Run Worker Service Account" }
    sa_cloudtasks     = { account_id = "sa-cloudtasks-${var.env_name}", display_name = "Cloud Tasks Service Account" }
    sa_fnc_cleanup    = { account_id = "sa-function-cleaner-${var.env_name}", display_name = "Function Cleanup Service Account" }
    sa_vm             = { account_id = "sa-vm-${var.env_name}", display_name = "Compute Instance Service Account" }
  }

  # Centralize project-level IAM bindings consumed by bindings.tf and locals.tf.
  bindings = {
    "roles/iam.serviceAccountTokenCreator" = [
      "serviceAccount:${var.monitoring_service_account}",
      "serviceAccount:sa-cloudrun-be-${var.env_name}@${var.project_id}.iam.gserviceaccount.com"
    ]
    "roles/secretmanager.secretAccessor" = [
      "serviceAccount:sa-cloudrun-be-${var.env_name}@${var.project_id}.iam.gserviceaccount.com",
      "serviceAccount:sa-cloudrun-worker-${var.env_name}@${var.project_id}.iam.gserviceaccount.com"
    ]
    "roles/cloudsql.client" = [
      "serviceAccount:sa-cloudrun-be-${var.env_name}@${var.project_id}.iam.gserviceaccount.com"
    ]
    "projects/${var.project_id}/roles/SA_Start_Stop" = [
      "serviceAccount:sa-github-actions@${var.project_id}.iam.gserviceaccount.com"
    ]
    "roles/viewer" = [
      "serviceAccount:sa-monitoring@${var.project_id}.iam.gserviceaccount.com"
    ]
    "roles/cloudasset.viewer" = [
      "serviceAccount:sa-monitoring@${var.project_id}.iam.gserviceaccount.com"
    ]
  }

  # Grant GitHub deployment permissions to the selected resources.
  github_permissions = {
    service_accounts = {
      role      = "roles/iam.serviceAccountUser"
      resources = ["sa-cloudrun-fe-${var.env_name}", "sa-cloudrun-be-${var.env_name}", "sa-cloudrun-worker-${var.env_name}"]
    }
    cloud_run = {
      role      = "roles/run.developer"
      resources = ["app-frontend-${var.env_name}", "app-backend-${var.env_name}", "app-worker-${var.env_name}"]
    }
    artifact_registry = {
      role      = "roles/artifactregistry.writer"
      resources = ["app-images"]
    }
  }
}

module "ci_cd_dev" {
  depends_on = [google_project_service.gcp_services]
  source     = "../../modules/ci_cd"
  location   = var.location
  art_reg_id = ["app-images"]
}

module "storage_dev" {
  depends_on = [google_project_service.gcp_services]
  source = "../../modules/storage"
  buckets_map = {
    function_artifacts = {
      name     = var.function_bucket_name
      location = var.location
    }
  }
}

module "serverless_dev" {
  depends_on = [
    google_project_service.gcp_services,
    module.ci_cd_dev,
    module.storage_dev,
  ]
  source                 = "../../modules/serverless"
  db_instance_name       = var.db_instance_name
  location               = var.location
  project_id             = var.project_id
  bucket_name            = module.storage_dev.buckets_details["function_artifacts"].name

  cloudrun_functions_map = {
    "revision-cleaner-${var.env_name}" = {
      entry_point      = "clean_inactive_revisions"
      runtime          = "python312"
      description      = "Function responsible for cleaning up old revisions from Cloud Run services to avoid hitting quota limits."
      source_archive   = "${path.root}/${var.function_source_archive}"
      env_vars         = local.cloudrun_function_clean_vars
      sa_email_address = module.iam_dev.sa_emails["sa_fnc_cleanup"]
    }
  }
  cloudrun_jobs_map = {
    "app-migrations-${var.env_name}" = {
      docker_image      = var.migration_image
      sa_email_address  = module.iam_dev.sa_emails["sa_cloudrun_be"]
      cloudsql_instance = true
      env_vars          = local.migration_env_vars
    }
  }
  cloudrun_services_map = {
    "app-frontend-${var.env_name}" = {
      docker_image      = "us-docker.pkg.dev/cloudrun/container/hello"
      exposed_port      = 80
      sa_email_address  = module.iam_dev.sa_emails["sa_cloudrun_fe"]
      session_affinity  = true
      cloudsql_instance = false
      env_vars          = local.fe_env_vars
    },
    "app-backend-${var.env_name}" = {
      docker_image      = "us-docker.pkg.dev/cloudrun/container/hello"
      exposed_port      = 3000
      sa_email_address  = module.iam_dev.sa_emails["sa_cloudrun_be"]
      session_affinity  = false
      cloudsql_instance = true
      env_vars          = local.be_env_vars
      env_secrets       = local.be_env_secrets
    },
    "app-worker-${var.env_name}" = {
      docker_image      = "us-docker.pkg.dev/cloudrun/container/hello"
      exposed_port      = 3002
      sa_email_address  = module.iam_dev.sa_emails["sa_cloudrun_wrk"]
      session_affinity  = false
      cloudsql_instance = true
      env_vars          = local.wrk_env_vars
      env_secrets       = local.wrk_env_secrets
    }
  }
}

module "database_dev" {
  depends_on = [google_project_service.gcp_services]
  source                   = "../../modules/database"
  location                 = var.location
  pqsql_saas_name          = var.db_instance_name
  pqsql_saas_database_name = var.database_name
  sql_password             = var.sql_password
  allowed_ips              = var.database_allowed_ips
}

module "networking_dev" {
  depends_on = [google_project_service.gcp_services]
  source   = "../../modules/networking"
  location = var.location
  vpc_name = "app-network-${var.env_name}"
  vpc_subnet_values = {
    (var.location) = var.subnet_cidr
  }
}

module "compute_dev" {
  depends_on = [google_project_service.gcp_services]
  source          = "../../modules/compute"
  location        = var.location
  vpc_network     = module.networking_dev.vpc_network
  subnet_id       = module.networking_dev.subnets_info[var.location].name
  instance_map = {
    "maintenance-vm-${var.env_name}" = {
      machine_type     = "n2-standard-2"
      image_family     = "ubuntu-minimal-2404-lts-amd64"
      image_project    = "ubuntu-os-cloud"
      user_data_script = "cloudflared"
      service_account  = module.iam_dev.sa_emails["sa_vm"]
    }
  }
}

module "messaging" {
  depends_on      = [google_project_service.gcp_services]
  source          = "../../modules/messaging"
  location        = var.location
  queue_name      = ["app-tasks-${var.env_name}"]
  # Keep this unused compatibility input null so the queue module does not depend on IAM.
  service_account = null
}

data "google_secret_manager_secret_version" "job_key" {
  secret = "${var.env_name}_job_trigger_key"
}

module "schedule" {
  depends_on = [google_project_service.gcp_services]
  source   = "../../modules/schedule"
  location = var.location
  scheduler_jobs = {
    "check-expiration" = {
      schedule  = var.check_expirations_schedule
      time_zone = var.check_expirations_time_zone
      http_target = {
        uri = coalesce(
          var.check_expirations_http_uri,
          "${module.serverless_dev.cloud_run_urls["app-backend-${var.env_name}"]}/tasks/check-expirations",
        )
        http_method = "GET"
        headers = {
          "Accept"            = "application/json",
          "x-job-trigger-key" = data.google_secret_manager_secret_version.job_key.secret_data
        }
      }
    }
  }
}
