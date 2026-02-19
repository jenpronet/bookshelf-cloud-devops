# 📋 SUBMISSION — Prueba Técnica DevOps / CI/CD & Release Management
# BookShelf Cloud — Passline

---

## 🔗 Link del Repositorio

**https://github.com/jenpronet/bookshelf-cloud-devops**

---

## 🤖 Links a runs de CI

| Evento | Link | Estado |
|--------|------|--------|
| Pull Request (feature/ci-setup → main) | https://github.com/jenpronet/bookshelf-cloud-devops/actions/runs/22163180699 | ✅ Pasó |
| Push a main | https://github.com/jenpronet/bookshelf-cloud-devops/actions/runs/22163476333 | ✅ Pasó |

---

## 🏷️ Tag / Release

| Tag | Link | Descripción |
|-----|------|-------------|
| `v0.1.0` | https://github.com/jenpronet/bookshelf-cloud-devops/releases/tag/v0.1.0 | Setup inicial CI/CD pipeline |

---

## 📦 Artefacto publicado (imagen Docker)

La imagen Docker se construye y valida en cada run del CI pipeline.
El paso de publicación a Artifact Registry está preparado en el CD pipeline
pero no se ejecuta hasta conectar un proyecto GCP real.

**Estado actual:**
```
✅ Build de imagen: funcional (verificado en CI — job "Docker Build")
⏳ Push a Artifact Registry: pipeline listo, pendiente de conectar GCP

# Cuando se conecte GCP, la imagen estará disponible en:
us-central1-docker.pkg.dev/PROJECT_ID/bookshelf/bookshelf-api:SHA_DEL_COMMIT
us-central1-docker.pkg.dev/PROJECT_ID/bookshelf/bookshelf-api:latest
```

**Para conectar GCP y activar el push real:**
```
1. Crear proyecto GCP
2. Ejecutar: cd infra/envs/dev && terraform init && terraform apply
3. Agregar secrets en GitHub:
   GCP_PROJECT_ID, GCP_REGION, GCP_SA_KEY
4. El CD pipeline publicará automáticamente en el próximo push a main
```

---

## 📝 Resumen de decisiones principales

Se construyó una base sólida de CI/CD para BookShelf Cloud sobre el repo
`aws-samples/python-fastapi-demo-docker` (fork en `jenpronet/bookshelf-cloud-devops`),
cubriendo los 5 bloques solicitados:

**1. Repo hygiene:** Se adoptó GitHub Flow con ramas `feature/*`, `fix/*` y `hotfix/*`.
Versionamiento SemVer con Conventional Commits. Branch protection rules en `main`
con checks obligatorios de CI antes del merge.

**2. CI Pipeline:** GitHub Actions con 3 jobs encadenados: lint/format (Black + Flake8),
tests (Pytest con cobertura), y Docker build. El pipeline corre en cada PR y push a `main`,
publicando un resumen accionable con tabla de estado en cada run.

**3. IaC con Terraform:** Diseño modular (`modules/` reutilizables + `envs/` por ambiente)
para GCP con Artifact Registry, Cloud Run, IAM con mínimo privilegio y Secret Manager.
Backend remoto en GCS documentado. DEV escala a cero; PROD mantiene mínimo 1 instancia.

**4. CD Pipeline:** GitHub Actions como orquestador. Push a `main` dispara deploy automático
a DEV. Tags `v*.*.*` disparan deploy a PROD con aprobación manual obligatoria. Smoke test
incluido post-deploy en ambos ambientes. Rollback documentado con tres opciones (< 10 min).

**5. Kubernetes (GKE):** Manifests completos para app FastAPI y Postgres (solo DEV).
Secrets referenciados sin valores sensibles. Health checks (startup, liveness, readiness)
y rolling update con `maxUnavailable=0` para zero-downtime deployments.

**Con más tiempo haría:**
- Implementar Workload Identity Federation (OIDC) para eliminar JSON keys estáticas
- Agregar HorizontalPodAutoscaler (HPA) en los manifests de GKE para PROD
- Implementar External Secrets Operator para sincronizar GCP Secret Manager con K8s
- Agregar escaneo de imagen con Trivy en el pipeline de CI
- Crear un golden path / plantilla para estandarizar esto en 20 servicios
- Agregar alertas en Cloud Monitoring atadas al smoke test del CD

---

## 🌐 URL del servicio (Cloud Run)

El IaC está preparado pero no desplegado en GCP real (sin proyecto GCP disponible).
La URL del servicio estará disponible como output de Terraform al ejecutar:

```bash
cd infra/envs/dev
terraform apply
terraform output service_url
# → https://bookshelf-dev-XXXX-uc.a.run.app
```

---

## 📁 Estructura del repositorio

```
bookshelf-cloud-devops/
├── .github/
│   └── workflows/
│       ├── ci.yml              ← CI: lint + tests + docker build
│       └── cd.yml              ← CD: build + push + deploy dev/prod
├── server/                     ← código FastAPI (fork del repo base)
│   ├── app/
│   │   ├── main.py
│   │   ├── connect.py
│   │   └── models.py
│   └── requirements.txt
├── tests/
│   └── test_basic.py           ← smoke tests del pipeline CI
├── k8s/                        ← manifests Kubernetes para GKE
│   ├── namespace.yaml
│   ├── app/
│   ├── db/
│   └── secrets/
├── infra/                      ← Terraform IaC para GCP
│   ├── modules/
│   │   ├── artifact-registry/
│   │   ├── cloud-run/
│   │   ├── iam/
│   │   └── secret-manager/
│   ├── envs/
│   │   ├── dev/
│   │   └── prod/
│   └── README.md
├── docs/
│   ├── RELEASE_PROCESS.md      ← estrategia de ramas + SemVer
│   ├── DEPLOYMENT.md           ← cómo promover a cada ambiente
│   ├── ROLLBACK.md             ← rollback paso a paso
│   ├── GKE_RUNBOOK.md          ← deploy + rolling update en GKE
│   └── ARCHITECTURE_GCP.md     ← diagrama de arquitectura GCP
├── SUBMISSION.md               ← este archivo
├── AI_USAGE.md                 ← transparencia uso de IA
└── Dockerfile
```

---

## 🐘 Técnica Elefante Blanco

Este proyecto fue construido con asistencia de Claude (Anthropic) como herramienta
de apoyo en la generación de código, pipelines y documentación. Toda decisión técnica
fue revisada, validada y defendible por el autor. Ver `AI_USAGE.md` para detalle completo.

---

*Prueba Técnica DevOps — Passline | Repositorio: jenpronet/bookshelf-cloud-devops*
