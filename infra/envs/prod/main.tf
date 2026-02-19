# ─────────────────────────────────────────────
# infra/envs/prod/main.tf
#
# Stack completo del ambiente PROD.
# Más recursos, sin escala a cero, acceso restringido.
# ─────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # Backend remoto en GCS para PROD
  # ANTES DE USAR: crear el bucket manualmente:
  #   gsutil mb gs://bookshelf-tfstate-prod
  #   gsutil versioning set on gs://bookshelf-tfstate-prod
  #
  backend "gcs" {
    bucket = "bookshelf-tfstate-prod"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ── Módulo: Artifact Registry ──────────────────
module "artifact_registry" {
  source        = "../../modules/artifact-registry"
  project_id    = var.project_id
  region        = var.region
  repository_id = "bookshelf"
  environment   = "prod"
}

# ── Módulo: IAM / Service Accounts ─────────────
module "iam" {
  source      = "../../modules/iam"
  project_id  = var.project_id
  environment = "prod"
}

# ── Módulo: Secret Manager ──────────────────────
module "secrets" {
  source      = "../../modules/secret-manager"
  project_id  = var.project_id
  environment = "prod"
}

# ── Módulo: Cloud Run ───────────────────────────
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id  = var.project_id
  region      = var.region
  environment = "prod"

  # En prod se usa el tag de la release, no latest
  image_url = "${var.region}-docker.pkg.dev/${var.project_id}/bookshelf/api:${var.image_tag}"

  service_account_email = module.iam.cloud_run_sa_email
  db_url_secret_id      = module.secrets.db_url_secret_id
  app_secret_key_id     = module.secrets.app_secret_key_id

  # PROD: siempre al menos 1 instancia activa (no escala a cero)
  # más recursos, sin acceso público directo
  min_instances       = 1
  max_instances       = 10
  cpu                 = "2000m"
  memory              = "1Gi"
  allow_public_access = false
}
