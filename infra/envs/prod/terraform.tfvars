# infra/envs/prod/terraform.tfvars
# ─────────────────────────────────────────────
# IMPORTANTE: no subir este archivo al repo.
# Está en .gitignore.
# El image_tag se pasa desde el pipeline, no aquí.
# ─────────────────────────────────────────────

project_id = "TU-PROJECT-ID-PROD"   # Reemplazar con tu project ID real
region     = "us-central1"
