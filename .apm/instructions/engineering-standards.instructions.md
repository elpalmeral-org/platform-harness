---
description: Estándares de ingeniería de Meridian (resumen operativo). Siempre activos en los repos de producto.
applyTo: "**"
---

# Estándares de ingeniería (resumen)

Versión completa y citable: skill `corporate-grounding` (`[[corpus/01-engineering-standards.md]]`).

- **Sin spec no hay código** (§3): toda feature parte de un cambio OpenSpec aprobado que cita el corpus
  (`[[corpus/<doc>.md]] §N`) con la consecuencia concreta.
- **Stack** (§2): backend Python 3.14 + FastAPI con `uv`; frontend Angular 22 + TypeScript estricto.
- **Fronteras** (§4, BLOCKER): los *routers* no tienen lógica de negocio; los servicios de dominio no
  hacen I/O; los componentes de Angular no llaman a la API directamente.
- **API** (§5): OpenAPI; un cambio incompatible exige versión mayor y nota de migración.
- **Tests** (§6): test por módulo nuevo, comportamiento observable, cobertura del backend ≥ 90 %.
- **Errores** (§7): excepciones de dominio tipadas; nada de `except:` desnudos ni errores tragados.
- **LLM** (§8, BLOCKER): toda llamada a un modelo se traza con modelo, tokens, coste y `data_class`.
- **Simplicidad** (§9): nada de abstracciones para un solo uso.
- **Entrega** (§10): solo por la plataforma (CI firmado, PR en `platform-gitops`, `gitops-ok`).
