# modules/secret-manager/variables.tf

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "environment" {
  description = "Ambiente: dev o prod"
  type        = string
}
