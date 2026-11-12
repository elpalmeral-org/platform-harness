# platform-harness

Harness corporativo del [agentic-platform-lab](https://github.com/elpalmeral-org/agentic-platform-lab):
todo lo que rodea al modelo y decide cómo trabaja (estándares, mandatos de agente, skills, herramientas
MCP y políticas), tratado como **producto versionado y firmado**.

Es **agnóstico del modelo y de la herramienta**: se escribe en formatos abiertos y lo consumen dos motores.

| | Motor A · abierto | Motor B · Claude |
|---|---|---|
| Ejecuta | HarnessRouter (UHP) | Claude Code |
| Modelos | OpenRouter (sin modelos de Anthropic) y un modelo local | Claude (suscripción) |
| Recibe el harness | `harness-sync`: un harness inmutable `meridian/<rol>@X.Y.Z` por rol | APM, en el formato de cada herramienta |

Decisiones: ADR [0022](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0022-harness-repo-propio-formatos-abiertos.md)
(repo propio, formatos abiertos) ·
[0023](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0023-apm-distribucion-harness-ok.md)
(APM y `harness-ok`) ·
[0024](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0024-harnessrouter-en-f4-proveedores.md)
(HarnessRouter) ·
[0025](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0025-dos-motores-un-harness.md)
(dos motores). Diseño: [lab/harness](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/lab/harness.md).

## Qué hay aquí

| Ruta | Qué es | Formato | Desde |
|---|---|---|---|
| `apm.yml` | Manifiesto del paquete: nombre, **versión del harness**, herramientas destino, MCP | APM | v0.1.0 |
| `.apm/instructions/` | Estándares corporativos, siempre activos | `*.instructions.md` | v0.1.0 |
| `.apm/agents/` | Mandatos de agente (spec-writer, implementer, validadores) | `*.agent.md` | v0.1.0 |
| `.apm/prompts/` | Comandos (`/feature`) | `*.prompt.md` | v0.1.0 |
| `.apm/skills/` | Capacidades bajo demanda | Agent Skills (`SKILL.md`) | v0.1.0 |
| `.apm/hooks/` | Guardarraíles dentro del agente (donde la herramienta los soporte) | JSON | v0.1.0 |
| `.apm/skills/corporate-grounding/references/` | Corpus corporativo citable (`[[corpus/…]] §N`); viaja con la skill de *grounding* | Markdown | v0.1.0 |
| `policy/` | Política de merge (OPA) y política de APM | Rego · YAML | v0.1.0 |
| `uhp/roles.yaml` | Motor A: rol → base + modelo + proveedor | YAML | v0.1.0 |

Solo se versiona la **fuente**. Lo que APM genera (`AGENTS.md`, `.claude/`, `.github/instructions/`…)
se comitea en los repos que consumen el harness, no aquí.

## Cómo se consume (desde F4.3)

```yaml
# apm.yml del repo consumidor
dependencies:
  apm:
    - elpalmeral-org/platform-harness#harness-v0.1.0
```

`apm install` genera los ficheros de cada herramienta y `apm.lock.yaml`. El check `harness-ok` comprueba
en cada PR que no hay *drift*, que la release está firmada y que la versión es al menos la mínima.

## Versiones

- La versión de `apm.yml` es la del harness. Un cambio de criterio en un validador es *minor*; uno que
  obliga a los repos a cambiar, *major*.
- Una release es un tag **`harness-vX.Y.Z`**. Solo un administrador del repo puede crearlo (ruleset
  `tags-harness`) y las releases son **inmutables**.

## Trabajar en local

```bash
brew install apm          # CI fija la versión: 0.35.0
apm install --dry-run     # valida el manifiesto
apm compile --dry-run     # muestra qué generaría para cada herramienta
```

## Licencia

[Apache-2.0](LICENSE).
