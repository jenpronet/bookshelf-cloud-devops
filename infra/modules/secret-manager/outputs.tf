# modules/secret-manager/outputs.tf

output "db_url_secret_id" {
  description = "ID del secreto de la URL de base de datos"
  value       = google_secret_manager_secret.db_url.secret_id
}

output "app_secret_key_id" {
  description = "ID del secreto de la app secret key"
  value       = google_secret_manager_secret.app_secret_key.secret_id
}
