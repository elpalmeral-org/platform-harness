---
description: Base de seguridad de Meridian (resumen operativo). Siempre activa en los repos de producto.
applyTo: "**"
---

# Base de seguridad (resumen)

Versión completa y citable: skill `corporate-grounding` (`[[corpus/02-security-baseline.md]]`).

- **Secretos** (§2, BLOCKER): nunca credenciales en el repo, ni en tests ni en documentación. Viven en
  1Password y llegan por External Secrets o secretos de CI.
- **Entrada** (§3): validación en la frontera (Pydantic, `extra="forbid"`); solo SQL parametrizado; nada
  de `pickle`/`eval` sobre datos externos; la salida de un LLM es entrada no confiable.
- **Autorización** (§4, BLOCKER): cada endpoint declara su control de autorización.
- **Cadena de suministro** (§5): imágenes solo de CI, con SBOM, escaneadas y firmadas; *actions* por SHA
  e imágenes base por digest.
- **Dependencias** (§6): versión fijada en lockfile, registro oficial, mantenimiento activo.
- **Agentes** (§7): proponen por PR; no fusionan ni aprueban; el PR lleva cambio OpenSpec, motor, rol y
  versión del harness; los ficheros del harness no se editan a mano.
