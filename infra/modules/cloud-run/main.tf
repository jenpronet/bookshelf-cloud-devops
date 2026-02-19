# ─────────────────────────────────────────────
# modules/cloud-run/main.tf
#
# Despliega la app BookShelf en Cloud Run.
# Cloud Run es serverless — solo pagas cuando hay tráfico.
# ─────────────────────────────────────────────

resource "google_cloud_run_v2_service" "bookshelf" {
  project  = var.project_id
  name     = "bookshelf-${var.environment}"
  location = var.region

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      # Imagen Docker desde Artifact Registry
      image = var.image_url

      # Recursos asignados al contenedor
      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # Puerto donde escucha la app FastAPI
      ports {
        container_port = 8000
      }

      # Variables de entorno — los valores sensibles
      # vienen de Secret Manager, nunca hardcodeados
      env {
        name = "ENVIRONMENT"
        value = var.environment
      }

      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = var.db_url_secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = var.app_secret_key_id
            version = "latest"
          }
        }
      }

      # Health check — Cloud Run verifica que la app responde
      startup_probe {
        http_get {
          path = "/health"
          port = 8000
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 8000
        }
        period_seconds    = 30
        failure_threshold = 3
      }
    }
  }

  labels = {
    env     = var.environment
    app     = "bookshelf"
    managed = "terraform"
  }
}

# Permitir acceso público al servicio (sin autenticación)
# Solo en dev — en prod se puede restringir
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count    = var.allow_public_access ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.bookshelf.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
