# 🏛️ Arquitectura GCP — BookShelf Cloud

Repositorio: jenpronet/bookshelf-cloud-devops

---

## Diagrama de Arquitectura

```mermaid
graph TB
    subgraph GitHub["GitHub — jenpronet/bookshelf-cloud-devops"]
        DEV["feature/* branch"]
        PR["Pull Request"]
        MAIN["main branch"]
        TAG["git tag v1.x.x"]
    end

    subgraph CI["GitHub Actions — CI Pipeline"]
        LINT["🧹 Lint + Format\nBlack + Flake8"]
        TEST["🧪 Tests\nPytest"]
        BUILD["🐳 Docker Build"]
    end

    subgraph CD["GitHub Actions — CD Pipeline"]
        PUSH_IMG["📦 Push imagen\nArtifact Registry"]
        DEPLOY_DEV["🚀 Deploy DEV\nauto"]
        APPROVAL["👤 Aprobación\nmanual"]
        DEPLOY_PROD["🚀 Deploy PROD\ncon tag"]
    end

    subgraph GCP_DEV["GCP — Ambiente DEV"]
        AR_DEV["Artifact Registry\nbookshelf/api:sha"]
        CR_DEV["Cloud Run\nbookshelf-dev\nmin=0, max=2"]
        SM_DEV["Secret Manager\ndb-url-dev\nsecret-key-dev"]
        SA_DEV["Service Account\nbookshelf-cloudrun-dev"]
    end

    subgraph GCP_PROD["GCP — Ambiente PROD"]
        AR_PROD["Artifact Registry\nbookshelf/api:v1.x.x"]
        CR_PROD["Cloud Run\nbookshelf-prod\nmin=1, max=10"]
        SM_PROD["Secret Manager\ndb-url-prod\nsecret-key-prod"]
        SA_PROD["Service Account\nbookshelf-cloudrun-prod"]
    end

    subgraph STATE["Terraform State — GCS"]
        GCS_DEV["gs://bookshelf-tfstate-dev"]
        GCS_PROD["gs://bookshelf-tfstate-prod"]
    end

    DEV --> PR
    PR --> LINT --> TEST --> BUILD
    MAIN --> PUSH_IMG --> DEPLOY_DEV
    TAG --> APPROVAL --> DEPLOY_PROD

    PUSH_IMG --> AR_DEV
    DEPLOY_DEV --> CR_DEV
    CR_DEV --> SM_DEV
    CR_DEV --> SA_DEV

    PUSH_IMG --> AR_PROD
    DEPLOY_PROD --> CR_PROD
    CR_PROD --> SM_PROD
    CR_PROD --> SA_PROD

    GCP_DEV -.-> GCS_DEV
    GCP_PROD -.-> GCS_PROD
```

---

## Descripción de Componentes

### GitHub Actions (CI/CD)
El pipeline tiene tres momentos clave: en PR valida código, en push a `main` despliega a DEV automáticamente, y en tag/release despliega a PROD con aprobación manual.

### Artifact Registry
Repositorio centralizado de imágenes Docker dentro de GCP. Las imágenes de DEV se etiquetan con el SHA del commit; las de PROD con el tag SemVer (`v1.x.x`).

### Cloud Run
Servicio serverless que ejecuta los contenedores. DEV escala a cero (ahorra costos), PROD mantiene al menos 1 instancia activa para no tener cold starts.

### Secret Manager
Almacena credenciales sensibles (DATABASE_URL, SECRET_KEY). Cloud Run las inyecta como variables de entorno en tiempo de ejecución. Nunca se hardcodean en el código ni en Terraform.

### Service Accounts + IAM
Dos Service Accounts por ambiente con mínimo privilegio: una para Cloud Run (solo lee secretos e imágenes) y otra para GitHub Actions (solo publica imágenes y despliega).

### Backend GCS
El estado de Terraform se guarda en Cloud Storage con versionado, lo que permite trabajo en equipo y recuperación ante errores.

---

## Flujo de un Deploy

```
1. Developer abre PR desde feature/* → main
2. CI: lint + tests + docker build (automático)
3. Code review aprobado → merge a main
4. CD: build imagen → push a Artifact Registry → deploy a DEV (automático)
5. QA valida en DEV
6. Developer crea tag: git tag v1.x.x && git push origin v1.x.x
7. CD: solicita aprobación manual en GitHub Actions
8. Aprobador confirma → deploy a PROD
```
