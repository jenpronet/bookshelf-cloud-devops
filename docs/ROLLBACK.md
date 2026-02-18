# 🔄 ROLLBACK RUNBOOK — BookShelf Cloud

Repositorio: jenpronet/bookshelf-cloud-devops

Este documento describe los pasos exactos para hacer rollback
en cada ambiente cuando un deploy sale mal.

---

## ¿Cuándo hacer rollback?

Hacer rollback inmediatamente si después de un deploy se detecta:

```
❌ Smoke test falla (HTTP 500 en /health)
❌ Aumento súbito de errores en logs
❌ La app no responde o responde lento
❌ Reportes de usuarios con errores críticos
❌ El equipo de QA detecta regresión grave
```

**Regla de oro:** ante la duda, hacer rollback primero e investigar después.

---

## Opción A — Rollback rápido via gcloud (recomendado)

Cloud Run guarda las revisiones anteriores automáticamente.
Este es el método más rápido — sin necesidad de re-deployar.

### Rollback en DEV

```bash
# 1. Ver las revisiones disponibles del servicio DEV
gcloud run revisions list \
  --service=bookshelf-dev \
  --region=us-central1 \
  --sort-by="~creationTimestamp" \
  --limit=5

# El output se ve así:
# REVISION              ACTIVE  SERVICE         DEPLOYED
# bookshelf-dev-00005   yes     bookshelf-dev   2025-01-15
# bookshelf-dev-00004           bookshelf-dev   2025-01-14  ← volver aquí
# bookshelf-dev-00003           bookshelf-dev   2025-01-13

# 2. Apuntar el 100% del tráfico a la revisión anterior
gcloud run services update-traffic bookshelf-dev \
  --region=us-central1 \
  --to-revisions=bookshelf-dev-00004=100

# 3. Verificar que el rollback aplicó
gcloud run services describe bookshelf-dev \
  --region=us-central1 \
  --format='value(status.traffic)'

# 4. Smoke test para confirmar que está OK
curl -s -o /dev/null -w "%{http_code}" \
  "$(gcloud run services describe bookshelf-dev \
    --region=us-central1 \
    --format='value(status.url)')/health"
# Esperado: 200
```

### Rollback en PROD

```bash
# 1. Ver las revisiones disponibles de PROD
gcloud run revisions list \
  --service=bookshelf-prod \
  --region=us-central1 \
  --sort-by="~creationTimestamp" \
  --limit=5

# 2. Apuntar el 100% del tráfico a la revisión estable anterior
gcloud run services update-traffic bookshelf-prod \
  --region=us-central1 \
  --to-revisions=bookshelf-prod-00004=100

# 3. Verificar el rollback
gcloud run services describe bookshelf-prod \
  --region=us-central1 \
  --format='value(status.traffic)'

# 4. Smoke test PROD
curl -s -o /dev/null -w "%{http_code}" \
  "$(gcloud run services describe bookshelf-prod \
    --region=us-central1 \
    --format='value(status.url)')/health"
# Esperado: 200
```

---

## Opción B — Rollback via GitHub Actions (re-deploy de versión anterior)

Usar cuando se quiere re-deployar una imagen específica por su tag.

```bash
# 1. Identificar el tag estable anterior en GitHub
git tag --sort=-version:refname | head -5
# v1.2.0  ← versión con el bug
# v1.1.0  ← versión estable anterior ✅

# 2. Crear un nuevo tag de rollback que apunte al commit anterior
git tag -a v1.2.1-rollback v1.1.0 \
  -m "Rollback: revert to v1.1.0 due to issue in v1.2.0"
git push origin v1.2.1-rollback

# 3. Esto dispara el CD pipeline automáticamente
#    → Build imagen con tag v1.2.1-rollback
#    → Solicita aprobación manual para PROD
#    → Deploy con la imagen de v1.1.0
```

---

## Opción C — Rollback manual de imagen específica

Cuando se conoce exactamente qué imagen se quiere desplegar.

```bash
# Deploy directo de una imagen específica de Artifact Registry
gcloud run deploy bookshelf-prod \
  --image=us-central1-docker.pkg.dev/PROJECT_ID/bookshelf/bookshelf-api:v1.1.0 \
  --region=us-central1 \
  --platform=managed \
  --quiet

# Verificar
gcloud run services describe bookshelf-prod \
  --region=us-central1 \
  --format='value(status.url)'
```

---

## Checklist de rollback completo

Seguir estos pasos en orden:

```
□ 1. DETECTAR — Confirmar que el problema existe
      → Revisar logs: gcloud run services logs read bookshelf-prod --region=us-central1
      → Revisar métricas en GCP Console → Cloud Run → bookshelf-prod

□ 2. COMUNICAR — Avisar al equipo antes de actuar
      → Notificar en el canal de Slack/Teams correspondiente
      → Indicar: qué falló, qué versión está afectada, que se va a hacer rollback

□ 3. EJECUTAR — Aplicar el rollback (Opción A es la más rápida)
      → gcloud run services update-traffic bookshelf-prod \
           --region=us-central1 \
           --to-revisions=REVISION-ESTABLE=100

□ 4. VERIFICAR — Confirmar que el servicio está OK
      → Smoke test: curl /health
      → Revisar logs post-rollback
      → Confirmar que los errores desaparecieron

□ 5. DOCUMENTAR — Crear un issue en GitHub
      → Qué salió mal
      → Qué versión se revirtió
      → Hora del incidente y del rollback
      → Próximos pasos para el fix

□ 6. FIX — Resolver el bug en una rama nueva
      → git checkout -b fix/nombre-del-bug
      → Corregir, testear, PR → merge → nuevo deploy
```

---

## Comandos útiles de diagnóstico

```bash
# Ver logs en tiempo real de PROD
gcloud run services logs tail bookshelf-prod \
  --region=us-central1

# Ver logs históricos de los últimos 30 minutos
gcloud run services logs read bookshelf-prod \
  --region=us-central1 \
  --limit=100

# Ver qué imagen está desplegada actualmente
gcloud run services describe bookshelf-prod \
  --region=us-central1 \
  --format='value(spec.template.spec.containers[0].image)'

# Ver todas las revisiones con su imagen
gcloud run revisions list \
  --service=bookshelf-prod \
  --region=us-central1 \
  --format='table(name,spec.containers[0].image,creationTimestamp)'
```

---

## Tiempo objetivo de rollback

| Paso | Tiempo estimado |
|------|-----------------|
| Detectar el problema | 2-5 min |
| Comunicar al equipo | 1-2 min |
| Ejecutar rollback (Opción A) | < 2 min |
| Verificar smoke test | 1-2 min |
| **Total** | **< 10 min** |

---

*Documento mantenido por el equipo de ingeniería. Ante cualquier incidente, este runbook es la referencia primaria. Última revisión: 2025.*
