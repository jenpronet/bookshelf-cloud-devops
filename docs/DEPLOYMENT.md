# 🚀 DEPLOYMENT — BookShelf Cloud

Repositorio: jenpronet/bookshelf-cloud-devops

Este documento explica cómo se despliega la app a cada ambiente
y cómo se promueve de DEV a PROD.

---

## Ambientes disponibles

| Ambiente | Trigger | Aprobación | Recursos | Acceso |
|----------|---------|------------|----------|--------|
| **DEV** | Push a `main` | Automático | 0-2 instancias, 512Mi | Público |
| **PROD** | Tag `v*.*.*` | Manual requerida | 1-10 instancias, 1Gi | Restringido |

---

## Flujo completo de un deploy

```
1. Developer trabaja en feature/* branch
        ↓
2. Abre Pull Request → main
   CI corre: lint + tests + docker build
        ↓
3. Code review aprobado → Merge a main
        ↓
4. CD se dispara automáticamente:
   - Build imagen → push a Artifact Registry con SHA del commit
   - Deploy automático a DEV
   - Smoke test en DEV
        ↓
5. QA valida en DEV (URL disponible en el summary del workflow)
        ↓
6. Si todo está bien → crear release tag
   git tag -a v1.2.0 -m "Release v1.2.0: descripción"
   git push origin v1.2.0
        ↓
7. CD detecta el tag → solicita aprobación manual
   (GitHub → Actions → workflow en espera → Review deployments)
        ↓
8. Aprobador revisa y confirma → Deploy a PROD
   - Build imagen con tag SemVer
   - Deploy a Cloud Run PROD
   - Smoke test en PROD
```

---

## Cómo hacer deploy a DEV

DEV se despliega **automáticamente** con cada push a `main`. No se necesita hacer nada manual.

```bash
# Simplemente hacer merge a main
git checkout main
git merge feature/mi-feature
git push origin main
# ↑ Esto dispara el CD automáticamente
```

Para ver el deploy en progreso:
```
GitHub → Actions → "CD Pipeline — BookShelf Cloud" → run más reciente
```

---

## Cómo hacer deploy a PROD

PROD solo se despliega con un **tag SemVer** y requiere **aprobación manual**.

### Paso 1 — Crear el tag de release

```bash
# Asegurarse de estar en main actualizado
git checkout main
git pull origin main

# Crear el tag (usar SemVer: MAJOR.MINOR.PATCH)
git tag -a v1.2.0 -m "Release v1.2.0: descripción del cambio"
git push origin v1.2.0
```

### Paso 2 — Aprobar el deploy en GitHub

```
1. Ir a: github.com/jenpronet/bookshelf-cloud-devops/actions
2. Buscar el workflow disparado por el tag v1.2.0
3. El job "Deploy → PROD" estará en estado "Waiting"
4. Click en "Review deployments"
5. Seleccionar "prod" y click en "Approve and deploy"
```

### Paso 3 — Verificar el deploy

```bash
# Ver el estado del servicio en PROD
gcloud run services describe bookshelf-prod \
  --region=us-central1 \
  --format='value(status.url)'

# Smoke test manual
curl -s -o /dev/null -w "%{http_code}" https://URL-DE-PROD/health
# Esperado: 200
```

---

## Diferencias de configuración por ambiente

| Configuración | DEV | PROD |
|---------------|-----|------|
| `min-instances` | 0 (escala a cero) | 1 (siempre activo) |
| `max-instances` | 2 | 10 |
| `memory` | 512Mi | 1Gi |
| `cpu` | 1 | 2 |
| `allow-unauthenticated` | ✅ Sí | ❌ No |
| Tag de imagen | SHA del commit | Tag SemVer (v1.x.x) |
| Secretos | `*-dev` | `*-prod` |
| Aprobación | Automático | Manual requerida |

---

## Configurar Secrets en GitHub

Antes de que el CD funcione, configurar estos secrets:

```
GitHub → Settings → Secrets and variables → Actions → New repository secret

GCP_PROJECT_ID  → ID del proyecto GCP (ej: my-project-123)
GCP_REGION      → Región GCP (ej: us-central1)
GCP_SA_KEY      → JSON key de la Service Account de GitHub Actions
```

## Configurar Ambiente PROD con aprobación manual

```
GitHub → Settings → Environments → New environment → "prod"
  → Required reviewers → agregar tu usuario o equipo
  → Save protection rules
```

---

## Smoke test incluido en el pipeline

Después de cada deploy, el pipeline corre automáticamente:

```bash
# El pipeline ejecuta esto contra /health (o / como fallback):
curl -s -o /dev/null -w "%{http_code}" "${SERVICE_URL}/health"

# Si el HTTP code está entre 200-499 → deploy exitoso ✅
# Si es 500+ → deploy falla y se notifica ❌
```

---

*Documento mantenido por el equipo de ingeniería. Última revisión: 2025.*
