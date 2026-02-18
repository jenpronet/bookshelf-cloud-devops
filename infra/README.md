# 🏗️ Infraestructura BookShelf Cloud — GCP con Terraform

Repositorio: jenpronet/bookshelf-cloud-devops

---

## Estructura

```
infra/
├── modules/                  ← bloques reutilizables
│   ├── artifact-registry/    ← repositorio de imágenes Docker
│   ├── cloud-run/            ← servicio serverless de la app
│   ├── iam/                  ← service accounts y permisos
│   └── secret-manager/       ← gestión de secretos
└── envs/
    ├── dev/                  ← ambiente de desarrollo
    └── prod/                 ← ambiente de producción
```

---

## Prerequisitos

```bash
# 1. Instalar Terraform >= 1.5.0
# https://developer.hashicorp.com/terraform/install

# 2. Instalar y autenticar gcloud CLI
gcloud auth application-default login
gcloud config set project TU-PROJECT-ID

# 3. Habilitar las APIs necesarias en GCP
gcloud services enable \
  run.googleapis.com \
  artifactregistry.googleapis.com \
  secretmanager.googleapis.com \
  iam.googleapis.com
```

---

## Cómo ejecutar en DEV

```bash
# 1. Crear el bucket para el estado remoto (solo la primera vez)
gsutil mb gs://bookshelf-tfstate-dev
gsutil versioning set on gs://bookshelf-tfstate-dev

# 2. Ir al ambiente dev
cd infra/envs/dev

# 3. Configurar variables
cp terraform.tfvars terraform.tfvars.local
# Editar terraform.tfvars con tu project_id real

# 4. Inicializar Terraform
terraform init

# 5. Ver qué va a crear (sin aplicar nada)
terraform plan

# 6. Aplicar la infraestructura
terraform apply

# 7. Ver outputs (URL del servicio, etc.)
terraform output
```

---

## Cómo ejecutar en PROD

```bash
# Mismo proceso pero desde infra/envs/prod/
cd infra/envs/prod

# En prod, el image_tag se pasa como variable
terraform init
terraform plan -var="image_tag=v1.0.0"
terraform apply -var="image_tag=v1.0.0"
```

---

## Cargar secretos después de aplicar

```bash
# Los secretos se crean vacíos con Terraform.
# Sus VALORES se cargan así (nunca en el código):

echo -n "postgresql://user:pass@host:5432/db" | \
  gcloud secrets versions add bookshelf-db-url-dev --data-file=-

echo -n "mi-secret-key-muy-segura" | \
  gcloud secrets versions add bookshelf-secret-key-dev --data-file=-
```

---

## Destruir infraestructura

```bash
# ⚠️ Solo usar en dev, nunca en prod sin aprobación
cd infra/envs/dev
terraform destroy
```

---

## Decisiones de diseño

**Módulos vs stacks:** cada módulo es independiente y reutilizable. Los `envs/` son los stacks que componen los módulos con configuración específica por ambiente. Esto permite cambiar configuración de dev sin tocar prod.

**Backend remoto GCS:** el estado de Terraform se guarda en GCS con versionado habilitado. Permite trabajo en equipo y recovery ante pérdida del estado local.

**Principio de mínimo privilegio:** cada Service Account solo tiene los permisos estrictamente necesarios. Cloud Run solo lee; GitHub Actions solo escribe imágenes y despliega.
