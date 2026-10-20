locals {
  fe_env_vars = {
    NODE_ENV     = "production"
    VITE_API_URL = var.frontend_api_url
  }

  be_env_vars = {
    NODE_ENV                     = "production"
    GCP_PROJECT_ID               = var.project_id
    CLOUD_TASKS_LOCATION         = var.location
    CLOUD_TASKS_QUEUE            = "app-tasks-${var.env_name}"
    CLOUD_TASKS_WORKER_URL       = var.worker_service_url
    CLOUD_TASKS_INVOKER_SA_EMAIL = module.iam_dev.sa_emails["sa_cloudtasks"]
    CLOUD_TASKS_OIDC_AUDIENCE    = var.worker_service_url
    CORS_ORIGIN                  = var.frontend_origin
    DB_CONNECTION_TIMEOUT_MS     = "2500"
    DATABASE_URL                 = "postgresql://usr_master_app:${var.sql_password}@/${var.database_name}?host=/cloudsql/${var.project_id}:${var.location}:${var.db_instance_name}"
    JWT_EXPIRATION               = "7d"
    JWT_REFRESH_EXPIRATION       = "24h"
    TEAM_INVITE_EXPIRES_AT_MINUTES = "240"
    SMTP_HOST                    = var.smtp_host
    SMTP_PORT                    = 587
    SMTP_USER                    = var.smtp_user
    SMTP_FROM                    = var.smtp_from
    FRONTEND_URL                 = var.frontend_url
  }

  be_env_secrets = {
    ADMIN_DEFAULT_PASSWORD = {
      secret_name = "${var.env_name}_admin_default_password"
      version     = "latest"
    }
    SQL_APP_PASSWORD = {
      secret_name = "${var.env_name}_sql_app_password"
      version     = "latest"
    }
    JOB_TRIGGER_KEY = {
      secret_name = "${var.env_name}_job_trigger_key"
      version     = "latest"
    }
    JWT_SECRET = {
      secret_name = "${var.env_name}_jwt_secret"
      version     = "latest"
    }
    SMTP_PASS = {
      secret_name = "${var.env_name}_smtp_password"
      version     = "latest"
    }
  }

  wrk_env_vars = {
    NODE_ENV                     = "production"
    DB_CONNECTION_TIMEOUT_MS     = "2500"
    DATABASE_URL                 = "postgresql://usr_master_app:${var.sql_password}@/${var.database_name}?host=/cloudsql/${var.project_id}:${var.location}:${var.db_instance_name}"
    JWT_EXPIRATION               = "7d"
    JWT_REFRESH_EXPIRATION       = "24h"
    CLOUD_TASKS_OIDC_AUDIENCE    = var.worker_service_url
    CLOUD_TASKS_INVOKER_SA_EMAIL = module.iam_dev.sa_emails["sa_cloudtasks"]
    SMTP_HOST                    = var.smtp_host
    SMTP_PORT                    = 587
    SMTP_USER                    = var.smtp_user
    SMTP_FROM                    = var.smtp_from
  }

  wrk_env_secrets = {
    JOB_TRIGGER_KEY = {
      secret_name = "${var.env_name}_job_trigger_key"
      version     = "latest"
    }
    JWT_SECRET = {
      secret_name = "${var.env_name}_jwt_secret"
      version     = "latest"
    }
    SMTP_PASS = {
      secret_name = "${var.env_name}_smtp_password"
      version     = "latest"
    }
  }

  migration_env_vars = {
    DB_CONNECTION_TIMEOUT_MS = "2500"
    DATABASE_URL             = "postgresql://usr_master_app:${var.sql_password}@localhost/${var.database_name}?host=/cloudsql/${var.project_id}:${var.location}:${var.db_instance_name}"
  }

  cloudrun_function_clean_vars = {
    PROJECT_ID = var.project_id
    LOCATION   = var.location
  }
}
