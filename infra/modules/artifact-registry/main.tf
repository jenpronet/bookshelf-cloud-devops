# ─────────────────────────────────────────────
# modules/artifact-registry/main.tf
#
# Crea el repositorio de imágenes Docker en GCP.
# Es el equivalente a Docker Hub pero dentro de GCP.
# ─────────────────────────────────────────────

resource "google_artifact_registry_repository" "bookshelf" {
  provider      = google
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "Repositorio de imágenes Docker para BookShelf Cloud"
  format        = "DOCKER"

  labels = {
    env     = var.environment
    app     = "bookshelf"
    managed = "terraform"
  }
}
