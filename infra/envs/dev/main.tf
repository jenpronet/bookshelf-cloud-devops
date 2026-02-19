# ─────────────────────────────────────────────
# infra/envs/dev/main.tf
#
# Stack completo del ambiente DEV.
# Llama a los módulos con configuración de desarrollo:
# recursos más pequeños, escala a cero, acceso público.
# ─────────────────────────────────────────────

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  # ── Backend remoto en GCS ──────────────────
  # Guarda el estado de Terraform en un bucket de GCS
  # en vez de localmente. Permite trabajo en equipo.
  #
  # ANTES DE USAR: crear el bucket manualmente:
  #   gsutil mb gs://bookshelf-tfstate-dev
  #   gsutil versioning set on gs://bookshelf-tfstate-dev
  #
  backend "gcs" {
    bucket = "bookshelf-tfstate-dev"
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
  environment   = "dev"
}

# ── Módulo: IAM / Service Accounts ─────────────
module "iam" {
  source      = "../../modules/iam"
  project_id  = var.project_id
  environment = "dev"
}

# ── Módulo: Secret Manager ──────────────────────
module "secrets" {
  source      = "../../modules/secret-manager"
  project_id  = var.project_id
  environment = "dev"
}

# ── Módulo: Cloud Run ───────────────────────────
module "cloud_run" {
  source = "../../modules/cloud-run"

  project_id  = var.project_id
  region      = var.region
  environment = "dev"

  # Imagen Docker — se actualiza en cada deploy via CI/CD
  image_url = "${var.region}-docker.pkg.dev/${var.project_id}/bookshelf/api:latest"

  # Service Account creada por el módulo IAM
  service_account_email = module.iam.cloud_run_sa_email

  # Secretos creados por el módulo secrets
  db_url_secret_id  = module.secrets.db_url_secret_id
  app_secret_key_id = module.secrets.app_secret_key_id

  # DEV: escala a cero (ahorra costos), acceso público
  min_instances       = 0
  max_instances       = 2
  cpu                 = "1000m"
  memory              = "512Mi"
  allow_public_access = true
}
