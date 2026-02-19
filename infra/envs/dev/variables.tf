# infra/envs/dev/variables.tf

variable "project_id" {
  description = "ID del proyecto GCP para DEV"
  type        = string
}

variable "region" {
  description = "Región GCP (ej: us-central1)"
  type        = string
  default     = "us-central1"
}
