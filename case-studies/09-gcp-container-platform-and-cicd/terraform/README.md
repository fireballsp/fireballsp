# Google Cloud Infrastructure

This Terraform configuration defines an infrastructure deployment for a sample application on Google Cloud. Environment-specific composition lives in `environments/dev`; reusable infrastructure is grouped into local modules under `modules`.

The configuration uses generic resource names and placeholder inputs. It does not include a project ID, custom domain, external account identity, production IP allowlist, or application artifact. Supply values for your own environment before planning or applying.

For the portfolio overview of how this infrastructure relates to image packaging and application deployment, see [Google Cloud Container Platform and CI/CD Automation](../README.md). This guide remains the implementation reference for the Terraform configuration; the case study explains the broader portfolio context and GitHub Actions workflows.

## Repository layout

```text
.
├── environments/
│   └── dev/
│       ├── main.tf          # Root composition and module wiring
│       ├── locals.tf        # Runtime environment maps
│       ├── variables.tf     # Environment inputs and defaults
│       ├── provider.tf      # Google provider configuration
│       ├── output.tf        # Deployment outputs
│       └── terraform.tfvars.example
├── modules/
│   ├── ci_cd/               # Artifact Registry repositories
│   ├── compute/             # Compute Engine instances and startup metadata
│   │   └── scripts/         # Instance startup scripts
│   ├── database/            # Cloud SQL for PostgreSQL, database, and user
│   ├── iam/                 # Service accounts, project IAM, GitHub OIDC
│   ├── messaging/           # Cloud Tasks queues
│   ├── networking/          # VPC, subnetworks, and IAP SSH firewall rule
│   ├── schedule/            # Cloud Scheduler HTTP jobs
│   ├── security/            # Secret Manager secrets and versions
│   ├── serverless/          # Cloud Run services/jobs and Cloud Functions
│   └── storage/             # Cloud Storage buckets
└── README.md
```

Each module declares its inputs in `variables.tf`, resources in `main.tf` (and focused companion files where needed), and exported values in `output.tf`. For example, IAM bindings and service accounts have separate files, while Compute Engine startup scripts are stored under `modules/compute/scripts`.

### Environment composition

`environments/dev/main.tf` composes the modules and enables the Google Cloud APIs listed in `variables.tf`. Its infrastructure includes:

- Project-level IAM, service accounts, and Workload Identity Federation for GitHub Actions.
- An Artifact Registry repository and a private Cloud Storage bucket for function source artifacts.
- Cloud Run frontend, backend, and worker services, plus a database migration job.
- A Cloud SQL for PostgreSQL instance and application database.
- A regional VPC/subnetwork, an IAP SSH firewall rule, and a Compute Engine maintenance instance.
- A Cloud Tasks queue and a Cloud Scheduler job that calls the backend expiration endpoint.
- Secret Manager values used by the backend and worker, plus a Cloud Function sourced from an operator-provided archive.

The Cloud Run service image values in this sample are generic placeholders. Replace them with the images for your application before deployment.

## Google Cloud services and resources

The Terraform configuration manages resources in these Google Cloud services:

| Google Cloud service | Resources configured |
| --- | --- |
| IAM | Project role bindings, a custom role, service accounts, service account IAM bindings, and a Workload Identity Federation pool/provider for GitHub Actions. |
| Artifact Registry | Docker image repository and repository IAM binding. |
| Cloud Storage | Private function-artifact bucket and uploaded function source object. |
| Cloud Run | Frontend, backend, and worker services; a database migration job; service IAM bindings; and Cloud SQL connection permissions. |
| Cloud Functions (2nd gen) | HTTP-triggered function deployed from the supplied source archive. |
| Cloud SQL | PostgreSQL instance, application database, and database user. |
| Compute Engine | Shielded VM and an IAP-only SSH firewall rule. |
| VPC networking | Custom VPC, regional subnetworks, and firewall configuration. |
| Cloud Tasks | Task queue with dispatch-rate, retry, and logging settings. |
| Cloud Scheduler | Scheduled HTTP request to the backend expiration endpoint. |
| Secret Manager | Application secrets and their secret versions. |
| Service Usage / Google Cloud project services | Enables the APIs required by the deployment. |

The environment also enables APIs for Cloud Resource Manager, Cloud Storage, Compute Engine, Cloud Run, Artifact Registry, Cloud Build, Cloud SQL Admin, Serverless VPC Access, Service Networking, IAP, Secret Manager, Cloud Monitoring, Cloud Logging, Cloud Trace, Cloud Profiler, Error Reporting, App Optimize, Cloud Scheduler, Cloud Asset Inventory, Security Command Center, Cloud Tasks, and Cloud Functions. Enabling an API does not mean this configuration creates a resource in every corresponding product; the table above lists resources explicitly managed by Terraform.

## Module reference

| Module | Responsibility |
| --- | --- |
| `ci_cd` | Creates Docker repositories in Artifact Registry. |
| `compute` | Creates Compute Engine instances and loads startup scripts from the module. |
| `database` | Creates a PostgreSQL Cloud SQL instance, database, and application user. |
| `iam` | Creates service accounts, role bindings, and GitHub OIDC federation resources. |
| `messaging` | Creates Cloud Tasks queues with retry and rate-limit settings. |
| `networking` | Creates a custom VPC, regional subnetworks, and an IAP SSH firewall rule. |
| `schedule` | Creates Cloud Scheduler HTTP jobs. |
| `security` | Creates Secret Manager secrets and versions from sensitive input values. |
| `serverless` | Creates Cloud Run services and jobs, uploads function source archives, and deploys Cloud Functions (2nd gen). |
| `storage` | Creates Cloud Storage buckets with uniform bucket-level access and public access prevention. |

## Prerequisites

- A Terraform Cloud organization and workspace connected to this configuration.
- The workspace working directory set to `case-studies/09-gcp-container-platform-and-cicd/terraform/environments/dev`.
- Google Cloud credentials for Terraform Cloud runs. Prefer Terraform Cloud dynamic provider credentials with Google Cloud Workload Identity Federation; alternatively, configure the Google provider credentials as a protected, sensitive workspace variable according to your organization's policy.
- A Google Cloud project with billing enabled. The configuration enables the required APIs during apply.
- A GitHub repository if GitHub Actions will use the configured Workload Identity Federation.
- A compatible Cloud Function source archive and the container image for the migration job. These artifacts are not included in this repository.

Terraform Cloud performs the plan and apply using credentials configured for the workspace. An interactive `gcloud auth application-default login` session on a developer's computer is **not** used by Terraform Cloud and is not required for remote runs. The provider receives the target project through the `project_id` Terraform variable.

The IAM module in this repository creates a Workload Identity Federation provider for GitHub Actions. That provider is separate from Terraform Cloud authentication; configure Terraform Cloud's Google Cloud dynamic credentials and corresponding Google Cloud trust/IAM setup in Terraform Cloud and Google Cloud.

## Configure inputs

Set the required Terraform variables in the Terraform Cloud workspace under **Variables**. Mark passwords, tokens, and other secret values as sensitive. Use [terraform.tfvars.example](./environments/dev/terraform.tfvars.example) as a reference for variable names and expected shapes; do not upload placeholder values as production configuration. Never commit real credentials or deployment-specific identifiers.

Required inputs:

| Input | Purpose |
| --- | --- |
| `project_id`, `project_number` | Target Google Cloud project identifiers. |
| `smtp_password`, `jwt_secret`, `job_key`, `admin_password`, `sql_password` | Sensitive values placed in Secret Manager; the SQL password also configures the database user. |
| `smtp_host`, `smtp_user`, `smtp_from` | Outbound email configuration. |
| `frontend_api_url`, `frontend_origin`, `frontend_url` | Frontend and CORS URLs. |
| `worker_service_url` | Cloud Run URL used by backend and worker task configuration. |
| `github_repository` | `OWNER/REPOSITORY` allowed by the GitHub OIDC provider. |
| `monitoring_service_account` | External monitoring service account email, without a `serviceAccount:` prefix. |
| `database_allowed_ips` | Approved Cloud SQL client IP ranges as `{ name, value }` objects. |
| `subnet_cidr` | Private CIDR range for the regional subnet. |
| `function_bucket_name` | Globally unique bucket name for function artifacts. |
| `function_source_archive` | Path to the function ZIP, relative to `environments/dev` in the Terraform Cloud run directory. Make the artifact available to the run without committing private or sensitive content. |
| `migration_image` | Full container image URI for the database migration job. |

`env_name` defaults to `dev`, `location` defaults to `us-east1`, and the database and schedule settings have generic defaults. The scheduler uses UTC by default; set `check_expirations_time_zone` if it should follow a different time zone. Review all defaults for your environment. `check_expirations_http_uri` may be set explicitly; when it is `null`, Terraform uses the backend service URL.

Terraform Cloud stores workspace state remotely. Restrict workspace access and protect saved plans and run logs. Marking a variable as sensitive masks its value in the UI and logs, but does not prevent the value from being stored in Terraform state.

## Run Terraform Cloud plans and applies

Connect the repository to a Terraform Cloud workspace, set its working directory to `case-studies/09-gcp-container-platform-and-cicd/terraform/environments/dev`, configure the Google Cloud credentials and required Terraform variables, then queue a plan. Review the plan in Terraform Cloud and confirm the apply according to the workspace's approval policy.

Terraform Cloud runs `init`, validation, planning, and applying for the configured workspace. Use the Terraform Cloud workspace UI or its configured VCS workflow to queue and review runs; do not run `terraform apply` locally against the remote workspace unless the workspace is intentionally configured for CLI-driven remote execution.

For optional local development, install the pinned Terraform provider version and authenticate the Google provider locally (for example, with Application Default Credentials):

```powershell
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

Local authentication is only for local Terraform operations and does not configure Terraform Cloud. Before local operations, initialize from `case-studies/09-gcp-container-platform-and-cicd/terraform/environments/dev`, provide the same required variables securely, and follow the workspace's execution mode. Review plans carefully, especially IAM grants, public IP allocation, Cloud SQL exposure, and resource replacement.

After deployment, Terraform outputs service URLs, service account addresses, network details, repository URLs, and public IP addresses. Treat these outputs as environment information and do not publish them without review.

To remove the environment, queue and review a destroy plan through the Terraform Cloud workspace.

## Operational and security considerations

- The generic resource names are not a migration map for an existing deployment. Applying this anonymized configuration against existing state may recreate or replace resources; inspect the plan and migrate state deliberately if needed.
- Cloud SQL has public IPv4 enabled and restricts authorized networks using `database_allowed_ips`. Provide only approved CIDRs.
- Review database backup and deletion-protection settings before production use; the module defaults currently disable both.
- The serverless module grants `allUsers` the Cloud Run Invoker role while configuring internal-only ingress. Confirm the intended invocation model for the target project.
- Sensitive values are managed by Secret Manager, but Terraform state still contains provider-managed values. Protect state, plans, and local variable files.
- Function source archives are intentionally external inputs. Provide a compatible artifact at the configured path; no archive is bundled or required to inspect this repository.
