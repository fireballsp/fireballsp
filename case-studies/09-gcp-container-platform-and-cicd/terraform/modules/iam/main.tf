# Custom role for automation and deployment pipelines.
resource "google_project_iam_custom_role" "SA_Start_Stop" {
  role_id     = "SA_Start_Stop"
  title       = "ServiceAccount-Start_Stop"
  description = "Role to allow service accounts to start and stop Compute Engine instances"
  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.start",
    "compute.instances.stop"
  ]
}

# GitHub Actions permissions are assigned to selected deployment resources.

# Allow GitHub Actions to impersonate deployment service accounts.
resource "google_service_account_iam_member" "github_sa_user" {
  for_each           = toset(var.github_permissions["service_accounts"].resources)
  service_account_id = "projects/${var.project_id}/serviceAccounts/${each.key}@${var.project_id}.iam.gserviceaccount.com"
  role               = var.github_permissions["service_accounts"].role
  member             = "serviceAccount:${google_service_account.sa["sa_github_actions"].email}"
}

# Allow GitHub Actions to manage and update Cloud Run services.
resource "google_cloud_run_v2_service_iam_member" "github_run" {
  for_each = toset(var.github_permissions["cloud_run"].resources)
  project  = var.project_id
  location = var.location
  name     = each.key
  role     = var.github_permissions["cloud_run"].role
  member   = "serviceAccount:${google_service_account.sa["sa_github_actions"].email}"
}

# Allow GitHub Actions to push images to Artifact Registry.
resource "google_artifact_registry_repository_iam_member" "github_registry" {
  for_each   = toset(var.github_permissions["artifact_registry"].resources)
  project    = var.project_id
  location   = var.location
  repository = each.key
  role       = var.github_permissions["artifact_registry"].role
  member     = "serviceAccount:${google_service_account.sa["sa_github_actions"].email}"
}

# Permissions for communication between Cloud Run and Cloud Tasks.

# Allow the frontend service to invoke the backend securely.
resource "google_cloud_run_v2_service_iam_member" "sa_cloudrun_fe_base" {
  project  = var.project_id
  location = var.location
  name     = var.cloud_run_name_be
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.sa["sa_cloudrun_fe"].email}"
}

# Allow the backend service to enqueue Cloud Tasks.
resource "google_cloud_tasks_queue_iam_member" "sa_cloudrun_be_tasks_enqueuer" {
  project  = var.project_id
  location = var.location
  name     = var.cloud_tasks_name
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${google_service_account.sa["sa_cloudrun_be"].email}"
}

# Allow Cloud Tasks to act as its service account.
resource "google_service_account_iam_member" "sa_cloudrun_tasks_ActAs" {
  service_account_id = google_service_account.sa["sa_cloudtasks"].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa["sa_cloudtasks"].email}"
}

# Allow the backend service to act as its service account.
resource "google_service_account_iam_member" "sa_cloudrun_be_ActAs" {
  service_account_id = google_service_account.sa["sa_cloudrun_be"].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.sa["sa_cloudrun_be"].email}"
}

# Allow Cloud Tasks to invoke asynchronous backend and worker routes.
resource "google_cloud_run_v2_service_iam_member" "sa_cloudtasks_invoker_be" {
  project  = var.project_id
  location = var.location
  name     = var.cloud_run_name_be
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.sa["sa_cloudtasks"].email}"
}

resource "google_cloud_run_v2_service_iam_member" "sa_cloudtasks_invoker_wrk" {
  project  = var.project_id
  location = var.location
  name     = var.cloud_run_name_wrk
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.sa["sa_cloudtasks"].email}"
}

# Configure service agents and workload identity federation.

data "google_project" "project" {}

# Allow the Cloud Tasks service agent to manage its queue service account.
resource "google_service_account_iam_member" "cloud_tasks_service_agent_user" {
  service_account_id = google_service_account.sa["sa_cloudtasks"].name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-cloudtasks.iam.gserviceaccount.com"
}

# Use GitHub OIDC federation instead of static service account keys.
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Workload Identity Pool"
  description               = "Identity pool for GitHub Actions"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.owner"      = "assertion.repository_owner"
    "attribute.refs"       = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  attribute_condition = "attribute.repository == '${var.gh_repo_workload_identity}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Bind the external OIDC provider to the GitHub Actions service account.
resource "google_service_account_iam_member" "github_workload_identity" {
  service_account_id = google_service_account.sa["sa_github_actions"].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.gh_repo_workload_identity}"

  depends_on = [google_service_account.sa]
}