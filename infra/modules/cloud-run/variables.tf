# modules/cloud-run/variables.tf

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región GCP (ej: us-central1)"
  type        = string
}

variable "environment" {
  description = "Ambiente: dev o prod"
  type        = string
}

variable "image_url" {
  description = "URL completa de la imagen Docker en Artifact Registry"
  type        = string
  # Ejemplo: us-central1-docker.pkg.dev/mi-proyecto/bookshelf/api:latest
}

variable "service_account_email" {
  description = "Email de la Service Account que usará Cloud Run"
  type        = string
}

variable "db_url_secret_id" {
  description = "ID del secreto de la URL de base de datos en Secret Manager"
  type        = string
}

variable "app_secret_key_id" {
  description = "ID del secreto de la app secret key en Secret Manager"
  type        = string
}

variable "min_instances" {
  description = "Mínimo de instancias (0 = escala a cero cuando no hay tráfico)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Máximo de instancias (límite de escalado)"
  type        = number
  default     = 3
}

variable "cpu" {
  description = "CPU asignada al contenedor (ej: 1000m = 1 CPU)"
  type        = string
  default     = "1000m"
}

variable "memory" {
  description = "Memoria asignada al contenedor (ej: 512Mi)"
  type        = string
  default     = "512Mi"
}

variable "allow_public_access" {
  description = "Si true, el servicio es accesible públicamente sin autenticación"
  type        = bool
  default     = false
}
