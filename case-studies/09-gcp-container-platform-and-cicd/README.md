# Google Cloud Container Platform and CI/CD Automation

## Overview

This case study describes GitHub Actions workflows for building and publishing Docker images to Google Artifact Registry (GAR) and deploying application services to Google Cloud Run, alongside Terraform-managed Google Cloud infrastructure. The workflow examples cover four pipelines:

| Component | Published image | Destination | Trigger |
|---|---|---|---|
| Backend | `app-backend` | Cloud Run (`app-backend-service`) | Manual |
| Frontend | `app-frontend` | Cloud Run (`app-frontend-service`) | Manual |
| Worker | `app-worker` | Cloud Run (`app-worker-service`) | Manual |
| Database migrations | `database-migrations` | Artifact Registry | `push` on monitored paths or manual |

The three application services use two chained jobs: `build-and-push` and `deploy`. The deployment job starts only after the build-and-push job succeeds. The database workflow prepares migration files and publishes its image without deploying it to Cloud Run.

Product, project, service, and image names have been anonymized. The technical workflow and configuration patterns are retained.

The [Terraform configuration](terraform/README.md) documents the companion infrastructure: reusable modules, environment composition, IAM, Workload Identity Federation (WIF), Artifact Registry, Cloud Run, Cloud SQL, networking, and supporting services. Terraform provisions the cloud resources and GitHub-to-Google identity trust; GitHub Actions uses that federation to build, publish, and deploy application images. Terraform's own remote runs use separately configured Terraform Cloud credentials, not the GitHub Actions deployment identity.

The Terraform files are a generic, configurable portfolio example: they contain placeholders and sample images, not a production-ready copy of the application environment. See the Terraform guide for prerequisites, inputs, operational caveats, and deployment details.

## Objectives and technical decisions

- **Controlled execution:** The backend, frontend, and worker use `workflow_dispatch`, allowing an operator to start the workflow manually and select the branch to process.
- **Traceable publishing:** Each image is tagged with `latest` and the commit SHA (`${{ github.sha }}`).
- **Keyless authentication:** The workflows use Workload Identity Federation (WIF) to obtain temporary Google Cloud credentials instead of storing a long-lived service-account key in the repository.
- **Image promotion:** For all three services, the deployment job references the `latest` tag published by the preceding job.
- **Migration image build:** The database workflow synchronizes migration files from the backend into the database image's build context.

Google Cloud settings are supplied through variables in a GitHub environment, such as `GCP_REGION`, `GCP_PROJECT_ID`, `GAR_REPOSITORY`, `WORKLOAD_IDENTITY_PROVIDER`, and `SERVICE_ACCOUNT`. Their values are configured outside version-controlled files; this document shows only the variable references.

## Common workflow: application services

### 1. Manual trigger and branch selection

The operator starts the workflow from **Actions** in GitHub and provides `target_branch`. The input is required and defaults to `main`. The `actions/checkout@v4` step checks out the selected branch so the build uses the requested version.

### 2. Google Cloud authentication

The build job calls `google-github-actions/auth@v2`, using the WIF provider and service account configured in the GitHub environment. Authentication generates a temporary access token without creating a persistent credentials file on the runner.

### 3. Artifact Registry login

`docker/login-action@v3` uses the access token as the password to authenticate to the regional registry `${GCP_REGION}-docker.pkg.dev`, with the username `oauth2accesstoken`.

### 4. Build and publish the image

`docker/build-push-action@v5` builds the image using the component-specific context and Dockerfile. With `push: true`, the image is pushed to GAR with two tags:

- `latest`, which points to the most recently published version;
- `${{ github.sha }}`, which identifies the commit used for the build.

The frontend also passes `VITE_API_URL` as a build argument. The backend and worker do not configure build arguments in their workflows.

### 5. Deploy to Cloud Run

After `build-and-push` completes, the `deploy` job authenticates to Google Cloud again with `google-github-actions/auth@v3`, this time creating the credentials file required by the deployment action. `google-github-actions/deploy-cloudrun@v3` deploys the `:latest` image to the configured service and region.

The backend updates or merges the `TEAM_INVITE_EXPIRES_AT_MINUTES` environment variable, using `240` as a fallback when the variable is not defined in the GitHub environment. The frontend and worker do not pass additional `env_vars` in this step.

### 6. Post-deployment check

All three workflows run `curl` against the URL returned by the deployment action. This is a basic connectivity check; it does not replace a health check that explicitly validates the HTTP status code or runs functional tests.

### Working-directory differences

The three application workflows share the same overall structure and are documented once above. Only the component-specific image/service identifiers and build paths differ:

- **Backend:** build context `./app/backend`; Dockerfile `./app/Dockerfile.backend`.
- **Frontend:** build context `./app/frontend`; Dockerfile `./app/Dockerfile.frontend`. It also passes `VITE_API_URL` as a build argument.
- **Worker:** build context `./app/worker`; Dockerfile `./app/Dockerfile.worker`.

The original repository uses different working paths for each component. These differences are noted here rather than repeating otherwise equivalent workflow YAML.

## Database migration image workflow

1. **Trigger:** The workflow runs on `push` to `main` or `dev` when files change under the configured migration directories, or it can be started manually with `target_branch`.
2. **Checkout:** For a manual run, it checks out the selected branch. On a `push` event, the input expression is empty and checkout uses the event reference.
3. **Synchronization:** Copies backend migration files into `app/database/prisma/prisma/migrations/`, which is part of the image build context.
4. **Configured wait:** A step named `Wait for 2 minutes` runs `sleep 60s`; the current wait is therefore one minute.
5. **Authentication and login:** Authenticates to Google Cloud through WIF and logs in to Artifact Registry, following the same general pattern as the application build jobs.
6. **Build and publish:** Builds with `app/database/prisma/Dockerfile` and publishes `database-migrations` with the `latest` and commit-SHA tags.
7. **No service deployment:** The workflow ends after publishing the image; it has no Cloud Run deployment job.

## Relevant variables and permissions

The workflows declare minimum permissions in YAML to read repository contents (`contents: read`) and obtain a federated identity token (`id-token: write`). The application builds use a GitHub environment that provides the configured variables and environment controls.

Variables referenced include:

- `WORKLOAD_IDENTITY_PROVIDER`: Workload Identity Federation provider.
- `SERVICE_ACCOUNT`: service account authorized to perform the operations.
- `GCP_REGION`: Artifact Registry and Cloud Run region.
- `GCP_PROJECT_ID`: Google Cloud project identifier.
- `GAR_REPOSITORY`: Artifact Registry image repository.
- `VITE_API_URL`: API URL supplied to the frontend build.
- `TEAM_INVITE_EXPIRES_AT_MINUTES`: optional backend setting with a workflow-defined fallback.

## Workflow implementation excerpts

The following excerpts illustrate the implementation without repeating three nearly identical application workflows. Replace the anonymized names and paths with the values used in the target repository.

### Application service workflow: build, push, and deploy

```yaml
name: Docker Build, Push and Deploy (Application Service)

on:
  workflow_dispatch:
    inputs:
      target_branch:
        description: 'Which branch should be processed?'
        required: true
        default: 'main'

env:
  IMAGE_NAME: app-service
  SERVICE: app-service

permissions:
  contents: read
  id-token: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    environment: CLOUD_ENVIRONMENT

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.target_branch }}

      - id: auth
        name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          token_format: access_token
          workload_identity_provider: ${{ vars.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.SERVICE_ACCOUNT }}
          create_credentials_file: false

      - name: Docker Auth
        uses: docker/login-action@v3
        with:
          registry: ${{ vars.GCP_REGION }}-docker.pkg.dev
          username: oauth2accesstoken
          password: ${{ steps.auth.outputs.access_token }}

      - name: Build and push application image
        uses: docker/build-push-action@v5
        with:
          # Set these paths for the selected component.
          context: ./app/component
          file: ./app/Dockerfile.component
          push: true
          tags: |
            ${{ vars.GCP_REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPOSITORY }}/${{ env.IMAGE_NAME }}:latest
            ${{ vars.GCP_REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPOSITORY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    environment: CLOUD_ENVIRONMENT
    permissions:
      contents: read
      id-token: write

    steps:
      - id: auth
        name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v3
        with:
          workload_identity_provider: ${{ vars.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.SERVICE_ACCOUNT }}
          create_credentials_file: true

      - id: deploy
        uses: google-github-actions/deploy-cloudrun@v3
        with:
          service: ${{ env.SERVICE }}
          region: ${{ vars.GCP_REGION }}
          image: ${{ vars.GCP_REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPOSITORY }}/${{ env.IMAGE_NAME }}:latest

      - name: Check deployment endpoint
        run: curl "${{ steps.deploy.outputs.url }}"
```

**Component-specific note:** Set `IMAGE_NAME`, `SERVICE`, `context`, and `file` for the backend, frontend, or worker. The frontend workflow additionally passes `VITE_API_URL` under `build-args`. The backend deployment additionally merges `TEAM_INVITE_EXPIRES_AT_MINUTES`, defaulting to `240`. The working-directory/build-path differences are listed in the note above instead of duplicating the workflow.

### Database migration image: build and push

```yaml
name: Build and Push Database Migration Image

on:
  push:
    branches: [main, dev]
    paths:
      - 'app/backend/prisma/migrations/**'
      - 'app/database/prisma/**'
  workflow_dispatch:
    inputs:
      target_branch:
        description: 'Which branch should be processed?'
        required: true
        default: 'main'

env:
  IMAGE_NAME: database-migrations

jobs:
  build-db-image:
    runs-on: ubuntu-latest
    environment: CLOUD_ENVIRONMENT
    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.target_branch }}

      - name: Sync migrations
        run: |
          echo "Syncing backend migrations to the database image context..."
          mkdir -p ./app/database/prisma/prisma/migrations/
          cp -f -r ./app/backend/prisma/migrations/* ./app/database/prisma/prisma/migrations/

      - name: Wait for 2 minutes
        run: sleep 60s

      - id: auth
        name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          token_format: access_token
          workload_identity_provider: ${{ vars.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ vars.SERVICE_ACCOUNT }}
          create_credentials_file: false

      - name: Docker Auth
        uses: docker/login-action@v3
        with:
          registry: ${{ vars.GCP_REGION }}-docker.pkg.dev
          username: oauth2accesstoken
          password: ${{ steps.auth.outputs.access_token }}

      - name: Build and push database image
        uses: docker/build-push-action@v5
        with:
          context: ./app/database/prisma
          file: ./app/database/prisma/Dockerfile
          push: true
          tags: |
            ${{ vars.GCP_REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPOSITORY }}/${{ env.IMAGE_NAME }}:latest
            ${{ vars.GCP_REGION }}-docker.pkg.dev/${{ vars.GCP_PROJECT_ID }}/${{ vars.GAR_REPOSITORY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
```

## Presentation summary

> “I automated packaging for backend, frontend, and worker services into Docker images, with versioned publishing to Google Artifact Registry and chained deployments to Cloud Run. Authentication between GitHub Actions and Google Cloud uses Workload Identity Federation. I also implemented a workflow to package the database migration image, synchronizing backend migrations before the build. Application services can be triggered manually with a selected branch, and images are tagged with both `latest` and the commit SHA.”

## Current-state observations

- Deployment jobs use `latest`, even though an SHA tag is also published. The commit identifier is available in the registry, but deployments do not explicitly select that immutable tag.
- The `curl` step makes a basic request to the Cloud Run URL. Stronger automated validation could check the HTTP status code or run dedicated smoke tests; this is not part of the current documented behavior.
- The Prisma step named `Wait for 2 minutes` waits for 60 seconds because its command is `sleep 60s`. This document describes the command as implemented rather than changing the workflow behavior.
