# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado: SemVer. Cada versión
publicada es un tag `harness-vX.Y.Z`.

## [Sin publicar]

### Añadido
- `policy/opa/pr_gates.rego`: excepción visible `harness-adopt` para que un repo adopte el harness
  por primera vez sin que lo abra el bot ([ADR 0028](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0028-excepcion-adopcion-inicial-harness.md)).
  Descubierto al implementar F4.3 en `meridian-orders`: la regla existente solo dejaba pasar
  `harness_upgrade_pr` (bot + `harness-upgrade`), y una adopción inicial no tiene versión previa que
  "actualizar". 2 tests nuevos (22/22 en total).

## [0.1.0] - 2026-11-13

Primera release firmada del harness ([ADR 0027](https://github.com/elpalmeral-org/agentic-platform-lab/blob/main/docs/adr/0027-release-firmada-platform-harness.md)): tag `harness-v0.1.0`.

### Añadido
- Esqueleto del paquete APM (`apm.yml`, `.apm/`) con destino Claude Code, Copilot, Codex y OpenCode.
- Skill `corporate-grounding` con el corpus corporativo citable (`references/`): estándares de ingeniería v4.0, base de seguridad v3.0 y
  clasificación de datos v2.0, con la matriz de qué datos recibe cada modelo (C3 solo al modelo local).
- Instrucciones siempre activas (`.apm/instructions/`): resumen operativo de los tres documentos.
- Mandatos de agente (`.apm/agents/`): `spec-writer`, `implementer` y tres validadores de solo lectura
  (`spec-validator`, `security-gate`, `impl-conformance`) con veredicto estricto.
- Comando `/feature` (`.apm/prompts/feature.prompt.md`): fase A hasta el PR de la spec (puerta 1) y
  fase B hasta el PR de código con la evidencia de los validadores (puerta 2). Acepta un *issue*.

- Servidor MCP `port` (catálogo de Port, región EU) en **solo lectura**, instalado en las cuatro
  herramientas; la skill `corporate-grounding` consulta con él el contexto del servicio.

- Hook `block-secrets` (`PreToolUse`): bloquea cualquier llamada a una herramienta (escritura,
  edición o comando) cuyo contenido tenga forma de credencial. Sin dependencias (Python estándar),
  falla en abierto y nunca repite el valor. Llega a Claude Code, Codex y Copilot; OpenCode no tiene
  hooks. Tests en `tests/`.

- Política de merge `policy/opa/pr_gates.rego` (con 15 tests): el repo usa el harness, sin *drift*, release firmada,
  versión mínima del harness (`0.1.0`), ficheros del harness solo por PR de upgrade del bot, código
  solo con spec ya fusionada (salvo releases y excepción visible `no-spec-required`), OpenSpec
  válido y, en PR de agentes (`aidlc`), evidencia de los tres validadores en `PASS`.

- `uhp/roles.yaml`: para los 5 roles del motor A (HarnessRouter / UHP), base `opencode` y modelo
  único `deepseek/deepseek-v3.2` en OpenRouter; de momento ningún rol en el modelo local (Bonsai).
  Política `policy/opa/uhp_roles.rego` (con 5 tests): ningún rol usa provider, base o modelo de
  Anthropic (ADR 0025).

- CI obligatorio (ADR 0026): `.github/workflows/validate.yml` ejecuta en cada PR `apm install/compile
  --dry-run` (apm-cli 0.35.0 vía pip, no brew), `opa test -v policy/opa` y `uv run pytest tests`; el
  check agregado `validate-ok` pasa a ser obligatorio en el ruleset de `main`. `pyproject.toml` +
  `uv.lock` fijan el entorno de `tests/` (antes no había ninguno: `pytest` solo estaba en Brewfile).

- Release firmada (ADR 0027): `.github/workflows/release.yml` se dispara al crear el tag
  `harness-vX.Y.Z` (ruleset `tags-harness`, solo admin). Empaqueta con `apm pack` (formato
  `claude-plugin`, zip), firma el bundle con `cosign sign-blob --yes --bundle` (formato moderno:
  firma + certificado + prueba de Rekor en un solo `.sigstore.json`) usando la identidad OIDC del
  propio *workflow* (no una identidad personal) y publica una GitHub Release con el `.zip`, el
  `.sigstore.json` y un `manifest.json` (`tag`, `commit`, `digest`, `format`, `archive`, `signature`).

### Corregido
- Estándares §2: el backend es Python 3.14.
