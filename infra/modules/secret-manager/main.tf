# ─────────────────────────────────────────────
# modules/secret-manager/main.tf
#
# Gestiona los secretos de la app en GCP Secret Manager.
# NUNCA se hardcodean valores aquí — los valores
# se cargan manualmente o via pipeline, nunca en el código.
# ─────────────────────────────────────────────

# Habilitar la API de Secret Manager en el proyecto
resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

# Secreto: URL de conexión a la base de datos
resource "google_secret_manager_secret" "db_url" {
  project   = var.project_id
  secret_id = "bookshelf-db-url-${var.environment}"

  labels = {
    env     = var.environment
    app     = "bookshelf"
    managed = "terraform"
  }

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# Secreto: Secret key de la app (para JWT, sessions, etc.)
resource "google_secret_manager_secret" "app_secret_key" {
  project   = var.project_id
  secret_id = "bookshelf-secret-key-${var.environment}"

  labels = {
    env     = var.environment
    app     = "bookshelf"
    managed = "terraform"
  }

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# ── IMPORTANTE ─────────────────────────────────────────
# Los valores de los secretos NO se definen aquí.
# Se cargan así DESPUÉS de aplicar Terraform:
#
#   echo -n "postgresql://user:pass@host/db" | \
#   gcloud secrets versions add bookshelf-db-url-dev --data-file=-
#
#   echo -n "mi-secret-key-segura" | \
#   gcloud secrets versions add bookshelf-secret-key-dev --data-file=-
# ───────────────────────────────────────────────────────
