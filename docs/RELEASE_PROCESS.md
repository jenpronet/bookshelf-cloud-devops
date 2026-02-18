# 📦 RELEASE PROCESS — BookShelf Cloud

Documento que explica cómo trabajamos en equipo con el código: cómo se organizan
las ramas, cómo se versiona y qué controles se aplican antes de que algo llegue
a producción.

Repositorio: https://github.com/jenpronet/bookshelf-cloud-devops

---

## 1. Estrategia de Ramas (Branch Strategy)

Usamos un flujo basado en **GitHub Flow** simplificado, pensado para equipos
que hacen deploys frecuentes.

```
main               ← rama principal, siempre estable y desplegable
  └── feature/*    ← desarrollo de nuevas funcionalidades
  └── fix/*        ← corrección de bugs
  └── hotfix/*     ← fix urgente directo a main
```

### Reglas claras:

| Rama | Propósito | ¿Se despliega? |
|------|-----------|----------------|
| `main` | Código productivo, siempre listo | Sí → producción |
| `feature/*` | Desarrollo de nuevas funcionalidades | No (solo en PR) |
| `fix/*` | Corrección de bugs no urgentes | No (solo en PR) |
| `hotfix/*` | Fix urgente que va directo a main | Sí, con cuidado |

### Flujo de trabajo día a día:

```
1. Crear rama desde main
   git checkout -b feature/nombre-de-la-feature

2. Trabajar y commitear con mensajes descriptivos
   git commit -m "feat: agregar endpoint GET /books"

3. Abrir Pull Request hacia main

4. Pasar los checks automáticos (CI pipeline)

5. Revisión de al menos 1 persona del equipo

6. Merge → deploy automático al ambiente correspondiente
```

### Ejemplo real en este repo:

```
git checkout -b feature/ci-setup    ← rama de trabajo actual
# ... cambios ...
git push origin feature/ci-setup
# Abrir PR: feature/ci-setup → main
# CI corre automáticamente en el PR
```

---

## 2. Tags y Releases (Versionamiento SemVer)

Usamos **Semantic Versioning (SemVer)**: `MAJOR.MINOR.PATCH`

| Parte | Cuándo cambia | Ejemplo |
|-------|---------------|---------|
| `MAJOR` | Cambio que rompe compatibilidad (breaking change) | `1.0.0 → 2.0.0` |
| `MINOR` | Nueva funcionalidad sin romper nada existente | `1.0.0 → 1.1.0` |
| `PATCH` | Corrección de bug o mejora pequeña | `1.0.0 → 1.0.1` |

### Cómo crear un release:

```bash
# 1. Asegúrate de estar en main y con todo actualizado
git checkout main
git pull origin main

# 2. Crear el tag con un mensaje descriptivo
git tag -a v1.0.0 -m "Release v1.0.0: setup inicial CI/CD pipeline"

# 3. Subir el tag al repositorio
git push origin v1.0.0
```

> 💡 El tag dispara automáticamente el pipeline de release en GitHub Actions,
> que construye la imagen Docker final y la promueve a producción
> (con aprobación manual).

### Convención de mensajes de commit (Conventional Commits):

```
feat:     nueva funcionalidad
fix:      corrección de bug
docs:     cambio en documentación
chore:    tarea de mantenimiento (deps, configs)
refactor: refactorización sin cambio funcional
test:     agregar o modificar tests
ci:       cambios en pipeline/CI
```

---

## 3. Checks Obligatorios antes del Merge (Branch Protection)

Nadie puede hacer merge a `main` sin pasar estos controles.
Se configuran como **Branch Protection Rules** en GitHub.

### Checks requeridos en PR hacia `main`:

```
✅ CI: Lint y formato de código (flake8 / black)
✅ CI: Tests unitarios (pytest)
✅ CI: Build de imagen Docker exitoso
✅ Code Review: al menos 1 aprobación de otro miembro del equipo
✅ Branch actualizada: la rama debe estar al día con main
```

### Cómo configurar en GitHub:

```
Ir a: github.com/jenpronet/bookshelf-cloud-devops
  → Settings
    → Branches
      → Add branch protection rule

Branch name pattern: main

Marcar:
☑ Require a pull request before merging
  ☑ Require approvals: 1
☑ Require status checks to pass before merging
  → Agregar: lint-and-test, docker-build
☑ Require branches to be up to date before merging
☑ Do not allow bypassing the above settings
```

> ⚠️ Nadie puede saltarse estos checks, ni los admins del repo.
> Esto garantiza que `main` siempre esté en condiciones de ser desplegado.

---

## Resumen Visual del Flujo Completo

```
Developer
    │
    ├─ git checkout -b feature/nombre
    │
    ├─ abre Pull Request → main
    │       │
    │       ├─ 🤖 CI corre automáticamente
    │       │     ├─ lint / format (black + flake8)
    │       │     ├─ tests (pytest)
    │       │     └─ docker build
    │       │
    │       └─ 👀 Code Review (1 aprobación)
    │
    ├─ Merge a main
    │       │
    │       └─ 🚀 Deploy automático a DEV
    │
    └─ git tag v1.x.x
            │
            └─ 🚀 Deploy a PROD (con aprobación manual)
```

---

*Repositorio: https://github.com/jenpronet/bookshelf-cloud-devops*
*Documento mantenido por el equipo de ingeniería. Última revisión: 2025.*
