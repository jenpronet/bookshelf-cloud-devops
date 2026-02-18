# modules/iam/outputs.tf

output "cloud_run_sa_email" {
  description = "Email de la Service Account de Cloud Run"
  value       = google_service_account.cloud_run_sa.email
}

output "github_actions_sa_email" {
  description = "Email de la Service Account de GitHub Actions"
  value       = google_service_account.github_actions_sa.email
}
