---
description: Punto de entrada gobernado para una feature (AIDLC). Primera vez, de la petición al PR de la spec (puerta 1). Con la spec fusionada, de la spec al PR de código con la evidencia de los validadores (puerta 2).
argument-hint: '<cambio> "<petición>" | #<issue> | <cambio>'
---

# /feature · de la petición a un PR gobernado

La única forma sancionada de empezar una feature. Los agentes **proponen**; las puertas que bloquean
son deterministas; **deciden las personas** fusionando los PR. Este comando nunca fusiona ni aprueba.

Argumentos: `$ARGUMENTS`

## 0 · ¿En qué fase estamos?

- Si el argumento es `#<n>`: lee el *issue* (`gh issue view <n>`) como petición y deriva un nombre de
  cambio en *kebab-case*.
- `git fetch origin`. Si `openspec/changes/<cambio>/` **no** existe en `origin/main` → **Fase A**.
- Si existe en `origin/main` y aún tiene tareas sin marcar → **Fase B**.
- Si no hay nada que hacer, dilo y termina.

## Fase A · Spec (termina en la puerta 1)

1. Delega en el agente **`spec-writer`** con la petición y el nombre del cambio.
2. Comprueba tú mismo `openspec validate <cambio> --strict`.
3. Rama `spec/<cambio>` desde `origin/main`; commit convencional `docs(spec): <cambio>`; push.
4. PR con título `spec: <cambio>` y como cuerpo el resumen del `spec-writer`, más la petición
   (o «Closes #<n>») y la versión del harness (de `apm.lock.yaml`).
5. **PARA.** Di que la spec queda pendiente de aprobación: se aprueba **fusionando su PR**. Cuando esté
   fusionada, se vuelve a lanzar `/feature <cambio>`.

## Fase B · Código (termina en la puerta 2)

1. Rama `feat/<cambio>` desde `origin/main`.
2. Delega en el agente **`implementer`**.
3. Lanza los tres validadores sobre el resultado: **`spec-validator`**, **`security-gate`** e
   **`impl-conformance`**. Guarda su salida tal cual.
4. Si alguno da `VERDICT: FAIL`: vuelve al `implementer` con los hallazgos y repite (máximo 2 vueltas).
   Si sigue fallando, **PARA** y explica qué falta: no se abre un PR que los validadores rechazan.
5. Commits convencionales que referencian el cambio; push; PR con título `feat: <cambio>` y cuerpo:

   ```markdown
   ## Cambio
   openspec/changes/<cambio>/ · spec aprobada en #<PR de la spec>

   ## Resumen
   <resumen del implementer>

   ## Evidencia del harness
   Harness: platform-harness <versión> · motor: <A (UHP, <modelo>) | B (Claude Code)>

   <details><summary>spec-validator · PASS|FAIL</summary>
   (salida literal)
   </details>
   <details><summary>security-gate · PASS|FAIL</summary>
   (salida literal)
   </details>
   <details><summary>impl-conformance · PASS|FAIL</summary>
   (salida literal)
   </details>
   ```

6. **PARA.** El CI repite las puertas deterministas; el merge (puerta 2) lo decide una persona.
