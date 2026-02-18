# ─────────────────────────────────────────────
# modules/iam/main.tf
#
# Crea las Service Accounts y asigna permisos mínimos.
# Principio: cada servicio solo tiene acceso a lo que necesita.
# ─────────────────────────────────────────────

# Service Account para Cloud Run (la app en producción)
resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "bookshelf-cloudrun-${var.environment}"
  display_name = "BookShelf Cloud Run SA [${var.environment}]"
  description  = "Service Account usada por Cloud Run para ejecutar la app"
}

# Service Account para GitHub Actions (CI/CD pipeline)
resource "google_service_account" "github_actions_sa" {
  project      = var.project_id
  account_id   = "bookshelf-github-${var.environment}"
  display_name = "BookShelf GitHub Actions SA [${var.environment}]"
  description  = "Service Account usada por GitHub Actions para deploy"
}

# ── Permisos para Cloud Run SA ──────────────────────────

# Leer imágenes desde Artifact Registry
resource "google_project_iam_member" "cloudrun_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Acceder a secretos en Secret Manager
resource "google_project_iam_member" "cloudrun_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# ── Permisos para GitHub Actions SA ────────────────────

# Publicar imágenes en Artifact Registry
resource "google_project_iam_member" "github_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Desplegar en Cloud Run
resource "google_project_iam_member" "github_cloudrun_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
}

# Permitir que GitHub Actions use la SA de Cloud Run
resource "google_service_account_iam_member" "github_sa_user" {
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_actions_sa.email}"
}
