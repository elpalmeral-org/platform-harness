---
name: corporate-grounding
description: Úsala ANTES de escribir un proposal.md o design.md de OpenSpec, y al revisar un PR contra las normas de Meridian. Recupera y cita el corpus corporativo (estándares de ingeniería, base de seguridad, clasificación de datos) para que specs y revisiones se apoyen en las normas reales y no en buenas prácticas genéricas.
---

# Grounding en el corpus corporativo

Toda spec y toda revisión se anclan al corpus de Meridian, que viaja con esta skill (`references/`)
y está fijado a la versión del harness: funciona igual en el portátil y en el gateway UHP, sin red.

| Documento | Cita | Úsalo para |
|---|---|---|
| `references/01-engineering-standards.md` | `[[corpus/01-engineering-standards.md]] §N` | stack, fronteras, API, tests, errores, observabilidad, entrega |
| `references/02-security-baseline.md` | `[[corpus/02-security-baseline.md]] §N` | secretos, entrada, autorización, cadena de suministro, agentes |
| `references/03-data-classification.md` | `[[corpus/03-data-classification.md]] §N` | clases de datos, DPIA, qué datos recibe cada modelo |

## Procedimiento

1. Identifica qué toca la petición: datos (¿alguno C3?), endpoints, dependencias, llamadas a modelos.
2. Lee **completos** los documentos aplicables (son cortos a propósito).
3. Escribe el bloque de *grounding* en `proposal.md`:

```markdown
## Grounding y cumplimiento

Corpus del harness vX.Y.Z:
- [[corpus/01-engineering-standards.md]] §4 — fronteras: …consecuencia para esta feature…
- [[corpus/02-security-baseline.md]] §3 — validación de entrada: …consecuencia…
- [[corpus/03-data-classification.md]] §1-§4 — datos que toca: C2 / C3 ⇒ Nota DPIA: sí/no; modelo permitido: …
```

4. Cada cita dice la **consecuencia para esta feature**, no el título de la sección. Una cita sin
   consecuencia es relleno: elimínala.

## Fallo a evitar

Citas genéricas («seguimos la base de seguridad»). El `security-gate` cruza las citas con el diff: un
*grounding* vago suspende igual que uno ausente.
