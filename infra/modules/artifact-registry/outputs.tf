# modules/artifact-registry/outputs.tf

output "repository_url" {
  description = "URL completa del repositorio para hacer docker push"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.bookshelf.repository_id}"
}

output "repository_id" {
  description = "ID del repositorio creado"
  value       = google_artifact_registry_repository.bookshelf.repository_id
}
