# modules/cloud-run/outputs.tf

output "service_url" {
  description = "URL pública del servicio Cloud Run"
  value       = google_cloud_run_v2_service.bookshelf.uri
}

output "service_name" {
  description = "Nombre del servicio Cloud Run"
  value       = google_cloud_run_v2_service.bookshelf.name
}
