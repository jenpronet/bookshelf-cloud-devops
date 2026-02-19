# 📘 GKE RUNBOOK — BookShelf Cloud

Repositorio: jenpronet/bookshelf-cloud-devops

Guía paso a paso para desplegar, actualizar y hacer rollback
de la app BookShelf en Google Kubernetes Engine (GKE).

---

## Prerequisitos

```bash
# 1. Instalar kubectl
# https://kubernetes.io/docs/tasks/tools/

# 2. Instalar gcloud CLI y autenticarse
gcloud auth login
gcloud config set project TU-PROJECT-ID

# 3. Conectarse al cluster GKE
gcloud container clusters get-credentials bookshelf-cluster \
  --region=us-central1 \
  --project=TU-PROJECT-ID

# 4. Verificar conexión
kubectl get nodes
# Deberías ver los nodos del cluster listados
```

---

## Cómo desplegar en GKE (primera vez)

Seguir estos pasos en orden. Cada comando aplica un grupo de recursos.

### Paso 1 — Crear el Namespace

```bash
kubectl apply -f k8s/namespace.yaml

# Verificar
kubectl get namespaces | grep bookshelf
```

### Paso 2 — Cargar los Secrets

```bash
# Nunca usar el archivo secrets.yaml con valores reales.
# Cargar directamente con kubectl:

kubectl create secret generic bookshelf-secrets \
  --namespace=bookshelf \
  --from-literal=database-url="postgresql://user:pass@postgres-service:5432/bookshelf" \
  --from-literal=secret-key="mi-secret-key-segura" \
  --from-literal=db-user="bookshelf_user" \
  --from-literal=db-password="mi-password-seguro"

# Verificar que el secret existe (sin mostrar los valores)
kubectl get secrets -n bookshelf
```

### Paso 3 — Desplegar la base de datos (solo DEV)

```bash
kubectl apply -f k8s/db/pvc.yaml
kubectl apply -f k8s/db/deployment.yaml
kubectl apply -f k8s/db/service.yaml

# Esperar que Postgres esté listo
kubectl rollout status deployment/postgres -n bookshelf
# Esperado: "deployment 'postgres' successfully rolled out"

# Verificar pod corriendo
kubectl get pods -n bookshelf -l component=database
```

### Paso 4 — Desplegar la app FastAPI

```bash
kubectl apply -f k8s/app/configmap.yaml
kubectl apply -f k8s/app/deployment.yaml
kubectl apply -f k8s/app/service.yaml

# Esperar que la app esté lista
kubectl rollout status deployment/bookshelf-api -n bookshelf
# Esperado: "deployment 'bookshelf-api' successfully rolled out"

# Verificar pods corriendo
kubectl get pods -n bookshelf -l component=api
```

### Paso 5 — Obtener la IP externa

```bash
# Esperar que el LoadBalancer asigne la IP (puede tomar 1-2 min)
kubectl get service bookshelf-service -n bookshelf -w

# Cuando aparezca EXTERNAL-IP:
# NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)
# bookshelf-service    LoadBalancer   10.0.0.5      34.123.456.789   80:32xxx/TCP

# Smoke test
curl -s -o /dev/null -w "%{http_code}" http://34.123.456.789/health
# Esperado: 200
```

### Paso 6 — Desplegar todo de una sola vez (shortcut)

```bash
# Alternativa: aplicar todos los manifests de una vez
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets/    # (solo si los valores ya están reemplazados)
kubectl apply -f k8s/db/
kubectl apply -f k8s/app/
```

---

## Cómo hacer Rolling Update (actualizar la app sin downtime)

Un rolling update reemplaza los pods de uno en uno, garantizando
que siempre haya pods disponibles durante la actualización.

### Opción A — Actualizar la imagen (más común en CI/CD)

```bash
# Actualizar la imagen con el nuevo tag de la release
kubectl set image deployment/bookshelf-api \
  bookshelf-api=us-central1-docker.pkg.dev/PROJECT_ID/bookshelf/bookshelf-api:v1.2.0 \
  -n bookshelf

# Monitorear el rolling update en tiempo real
kubectl rollout status deployment/bookshelf-api -n bookshelf

# Ver el historial de actualizaciones
kubectl rollout history deployment/bookshelf-api -n bookshelf
```

### Opción B — Aplicar cambios en el deployment.yaml

```bash
# Editar la imagen en k8s/app/deployment.yaml
# Luego aplicar:
kubectl apply -f k8s/app/deployment.yaml

# Monitorear
kubectl rollout status deployment/bookshelf-api -n bookshelf
```

### ¿Qué pasa durante el rolling update?

```
Estado inicial:  [Pod v1] [Pod v1]   (2 réplicas activas)
                                      ↓ maxSurge=1
Paso 1:          [Pod v1] [Pod v1] [Pod v2-nuevo]   (crea 1 nuevo)
                                      ↓ readinessProbe OK en v2
Paso 2:          [Pod v1] [Pod v2-nuevo]             (elimina 1 viejo)
                                      ↓ maxSurge=1 de nuevo
Paso 3:          [Pod v1] [Pod v2-nuevo] [Pod v2-nuevo]
                                      ↓
Paso 4:          [Pod v2-nuevo] [Pod v2-nuevo]       (completo ✅)
```

---

## Cómo hacer Rollback

### Rollback inmediato a la versión anterior

```bash
# Revertir al deployment anterior (el más rápido)
kubectl rollout undo deployment/bookshelf-api -n bookshelf

# Verificar que el rollback aplicó
kubectl rollout status deployment/bookshelf-api -n bookshelf

# Ver qué versión está corriendo ahora
kubectl get deployment bookshelf-api -n bookshelf \
  -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### Rollback a una versión específica del historial

```bash
# Ver el historial de revisiones
kubectl rollout history deployment/bookshelf-api -n bookshelf
# REVISION  CHANGE-CAUSE
# 1         Inicial v1.0.0
# 2         Actualización v1.1.0
# 3         Actualización v1.2.0  ← versión actual (con bug)

# Rollback a la revisión 2 (v1.1.0)
kubectl rollout undo deployment/bookshelf-api \
  --to-revision=2 \
  -n bookshelf

# Verificar
kubectl rollout status deployment/bookshelf-api -n bookshelf
```

### Smoke test post-rollback

```bash
# Obtener IP del servicio
EXTERNAL_IP=$(kubectl get service bookshelf-service -n bookshelf \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Smoke test
curl -s -o /dev/null -w "%{http_code}" "http://${EXTERNAL_IP}/health"
# Esperado: 200
```

---

## Comandos útiles de diagnóstico

```bash
# Ver todos los recursos del namespace
kubectl get all -n bookshelf

# Ver logs de la app en tiempo real
kubectl logs -f deployment/bookshelf-api -n bookshelf

# Ver logs de un pod específico
kubectl logs -f POD-NAME -n bookshelf

# Describir un pod con sus eventos (útil para debug)
kubectl describe pod POD-NAME -n bookshelf

# Ver eventos del namespace (errores, warnings)
kubectl get events -n bookshelf --sort-by='.lastTimestamp'

# Entrar al contenedor para debug
kubectl exec -it POD-NAME -n bookshelf -- /bin/sh
```

---

## Diferencias DEV vs PROD en Kubernetes

| Configuración | DEV | PROD |
|---------------|-----|------|
| Réplicas app | 2 | 3+ (con HPA) |
| Base de datos | Postgres en cluster | Cloud SQL gestionado |
| Storage | PVC standard (HDD) | PVC premium (SSD) |
| Recursos app | 250m CPU / 256Mi RAM | 500m CPU / 512Mi RAM |
| Service type | LoadBalancer | LoadBalancer + Ingress |
| Secrets | kubectl manual | GCP Secret Manager + ESO |

---

*Documento mantenido por el equipo de ingeniería. Última revisión: 2025.*
