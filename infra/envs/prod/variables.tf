# infra/envs/prod/variables.tf

variable "project_id" {
  description = "ID del proyecto GCP para PROD"
  type        = string
}

variable "region" {
  description = "Región GCP (ej: us-central1)"
  type        = string
  default     = "us-central1"
}

variable "image_tag" {
  description = "Tag de la imagen Docker a desplegar (ej: v1.2.0)"
  type        = string
  # Se pasa desde el pipeline en cada release:
  # terraform apply -var="image_tag=v1.2.0"
}
