# 🤖 AI_USAGE.md — Transparencia de uso de IA

Repositorio: jenpronet/bookshelf-cloud-devops
Prueba Técnica DevOps — Passline

---

## IA utilizada

**Claude (Anthropic)** — modelo Claude Sonnet via claude.ai
Usado como asistente principal durante toda la prueba técnica.

---

## Qué se le pidió a la IA y en qué partes influyó

### Bloque 1 — Repo hygiene + versionamiento

**Prompt / instrucción:**
> "Genera los tres puntos que se indican de forma ordenada y genera el entregable
> indicado (RELEASE_PROCESS.md) hazlo en un tono entendible, resumido y claro
> para cualquier persona"

**Influyó en:**
- Estructura y contenido de `docs/RELEASE_PROCESS.md`
- Definición de la estrategia de ramas (GitHub Flow)
- Tabla de Branch Protection Rules
- Diagrama ASCII del flujo completo

---

### Bloque 2 — CI Pipeline

**Prompt / instrucción:**
> "Crea un pipeline GitHub Actions que corra lint/format y tests, haga build Docker
> de la app y publique resultados claros. El repo a usar es jenpronet/bookshelf-cloud-devops
> rama feature/ci-setup"

**Iteraciones adicionales por el usuario (debugging real):**
- Ajuste de paths `app/` → `server/` al ver la estructura real del repo
- Fix de `black` formatting en `server/app/connect.py`
- Corrección de `--extend-ignore=F401` en Flake8
- Agregar `httpx` como dependencia del TestClient
- Fix de `PYTHONPATH` para resolver imports
- Corrección del import path a `server/app/main.py`
- Simplificación de tests a `os.path` para evitar problemas de import con DB

**Influyó en:**
- `.github/workflows/ci.yml` (generado y depurado iterativamente)
- `tests/test_basic.py` (múltiples versiones hasta pasar el CI)
- Diagnóstico y solución de cada error del pipeline

---

### Bloque 3 — Terraform + GCP

**Prompt / instrucción:**
> "Genera la infraestructura en GCP con Terraform con separación por ambientes,
> Artifact Registry, Service Accounts, Secret Manager, Cloud Run, estructura modular"

**Influyó en:**
- `infra/modules/artifact-registry/` (main.tf, variables.tf, outputs.tf)
- `infra/modules/cloud-run/` (main.tf, variables.tf, outputs.tf)
- `infra/modules/iam/` (main.tf, variables.tf, outputs.tf)
- `infra/modules/secret-manager/` (main.tf, variables.tf, outputs.tf)
- `infra/envs/dev/` (main.tf, variables.tf, terraform.tfvars)
- `infra/envs/prod/` (main.tf, variables.tf, terraform.tfvars)
- `infra/README.md`
- `docs/ARCHITECTURE_GCP.md` con diagrama Mermaid

---

### Bloque 4 — CD Pipeline + Documentación

**Prompt / instrucción:**
> "Genera el CD pipeline con Opción A (GitHub Actions), dos ambientes dev y prod
> con configuración distinta, rollback runbook con pasos concretos y los tres
> entregables: cd.yml, DEPLOYMENT.md y ROLLBACK.md"

**Iteración adicional:**
- Fix del trigger `push_tag` (no existe) → corregido a `push.tags`

**Influyó en:**
- `.github/workflows/cd.yml`
- `docs/DEPLOYMENT.md`
- `docs/ROLLBACK.md`

---

### Bloque 5 — Kubernetes / GKE

**Prompt / instrucción:**
> "Genera los manifests para GKE con app, base de datos (solo dev), secrets sin
> valores sensibles y probes/health checks básicos. Con GKE_RUNBOOK.md que incluya
> cómo desplegar, rolling update y rollback"

**Influyó en:**
- `k8s/namespace.yaml`
- `k8s/app/configmap.yaml`
- `k8s/app/deployment.yaml`
- `k8s/app/service.yaml`
- `k8s/db/pvc.yaml`
- `k8s/db/deployment.yaml`
- `k8s/db/service.yaml`
- `k8s/secrets/secrets.yaml`
- `docs/GKE_RUNBOOK.md`

---

### Documentos finales

**Influyó en:**
- `SUBMISSION.md` — estructura y resumen de decisiones, ayuda en la redaccion
- `AI_USAGE.md` — este archivo, ayuda en la redaccion

---

## Qué hizo el autor (sin IA)

- Crear y configurar el repositorio `jenpronet/bookshelf-cloud-devops` en GitHub
- Ejecutar todos los comandos de git (commits, push, tags, branches)
- Revisar y validar cada archivo generado antes de subirlo
- Debuggear los errores reales del CI (Black, Flake8, pytest, imports)
- Aplicar los fixes iterativos en el repo local
- Tomar decisiones sobre qué opciones usar (Opción A en CD, Opción 1 en GKE)
- Verificar que el CI pasara verde en GitHub Actions
- Revisar la estructura real del repo para ajustar paths

---

## Consideración importante

Toda decisión técnica fue revisada, comprendida y validada por el autor
antes de aplicarla. El uso de IA fue como herramienta de asistencia y
aceleración, no como caja negra. El autor puede explicar y defender
cada decisión tomada sin asistencia de IA durante la entrevista.

---

*Repositorio: jenpronet/bookshelf-cloud-devops | Prueba Técnica Passline 2025*
