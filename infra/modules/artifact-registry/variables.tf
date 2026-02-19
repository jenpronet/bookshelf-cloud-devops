# modules/artifact-registry/variables.tf

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región GCP donde se crea el registro (ej: us-central1)"
  type        = string
}

variable "repository_id" {
  description = "Nombre del repositorio en Artifact Registry"
  type        = string
  default     = "bookshelf"
}

variable "environment" {
  description = "Ambiente: dev o prod"
  type        = string
}
