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
| `.apm/hooks/` | Guardarraíles dentro del agente: `block-secrets`. Llegan a Claude Code, Codex y Copilot; OpenCode no tiene hooks. Son una red extra: lo que bloquea de verdad son las puertas de CI | JSON + Python estándar | v0.1.0 |
| `.apm/skills/corporate-grounding/references/` | Corpus corporativo citable (`[[corpus/…]] §N`); viaja con la skill de *grounding* | Markdown | v0.1.0 |
| `policy/opa/` | Política de merge de los repos de producto (`pr_gates.rego` + tests): *drift*, firma, versión mínima, spec aprobada, evidencia de los validadores. La evalúa `harness-ok`. `uhp_roles.rego` + tests: ningún rol del motor A usa provider/base/modelo de Anthropic (ADR 0025) | Rego | v0.1.0 |
| `uhp/roles.yaml` | Motor A: rol → base + modelo + proveedor | YAML | v0.1.0 |
| `tests/` | Tests de los scripts del harness (`uv run pytest tests`) | pytest | v0.1.0 |
| `.github/workflows/validate.yml` | CI: `apm install/compile --dry-run`, `opa test`, `pytest`. Check obligatorio `validate-ok` en el ruleset de `main` | GitHub Actions | v0.1.0 |
| `.github/workflows/release.yml` | Release firmada al crear el tag `harness-vX.Y.Z` (ADR 0027): `apm pack` + cosign *keyless* + GitHub Release | GitHub Actions | v0.1.0 |

Solo se versiona la **fuente**. Lo que APM genera (`AGENTS.md`, `.claude/`, `.github/instructions/`…)
se comitea en los repos que consumen el harness, no aquí.

La política de **instalación** (qué paquetes, MCP y herramientas se permiten en la org) no vive aquí:
está en [`elpalmeral-org/.github/apm-policy.yml`](https://github.com/elpalmeral-org/.github/blob/main/apm-policy.yml),
donde APM la descubre sola en cada `apm install`.

## Cómo se consume (desde F4.3)

```yaml
# apm.yml del repo consumidor
dependencies:
  apm:
    - elpalmeral-org/platform-harness#5df5c1e1830094d033f12224fef72d20717229ab # harness-v0.1.1
```

El pin es el **SHA del commit**, no el tag: `apm-policy.yml` (`require_pinned_constraint`) solo
reconoce como *pinned* un SHA de 40 caracteres o un tag literal `vX.Y.Z` — `harness-vX.Y.Z` no
encaja en ese patrón y se trataría como una rama que sigue moviéndose. Busca el SHA del último tag
con `git rev-parse harness-vX.Y.Z^{commit}` en este repo.

`apm install` genera los ficheros de cada herramienta y `apm.lock.yaml` (que sí guarda la versión,
`0.1.1`, leída del `apm.yml` de ese commit). El check `harness-ok` comprueba en cada PR que no hay
*drift* (`apm audit --ci`), que la release fijada tiene una firma válida (`cosign verify-blob`
contra la release de GitHub) y que la versión es al menos la mínima. La primera vez que un repo
adopta el harness, el PR lleva la etiqueta `harness-adopt`
([ADR 0028](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0028-excepcion-adopcion-inicial-harness.md));
las siguientes veces, la etiqueta es `harness-upgrade` (F4.4).

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
uv sync --group dev && uv run pytest -q tests   # scripts del harness (pytest en .venv, vía uv)
opa test -v policy/opa                          # política de merge
```

## Licencia

[Apache-2.0](LICENSE).
