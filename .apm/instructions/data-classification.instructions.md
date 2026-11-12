---
description: Clasificación de datos de Meridian y qué datos puede recibir cada modelo. Siempre activa.
applyTo: "**"
---

# Clasificación de datos (resumen)

Versión completa y citable: skill `corporate-grounding` (`[[corpus/03-data-classification.md]]`).

- **Clases** (§1): C1 pública · C2 interna (ids, cantidades, métricas) · C3 personal o confidencial
  (cliente, pago, riesgo de un cliente) · C4 restringida (claves).
- **Tratamiento** (§2): C3 nunca en logs, trazas, *fixtures* ni listados (se enmascara en la frontera);
  C4 nunca sale del gestor de secretos.
- **DPIA** (§3, BLOCKER): un tratamiento nuevo de C3 exige Nota DPIA en el `design.md`.
- **Modelos** (§4): Claude y OpenRouter reciben **solo C1 y C2**. **C3 solo al modelo local**,
  minimizada y trazada con `data_class=c3`. C4, a ningún modelo. Si una tarea necesita C3 y no hay rol
  local, se rediseña.
