# Changelog

Formato: [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/). Versionado: SemVer. Cada versión
publicada es un tag `harness-vX.Y.Z`.

## [Sin publicar]

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

- Política de merge `policy/opa/pr_gates.rego` (con 14 tests): sin *drift*, release firmada,
  versión mínima del harness (`0.1.0`), ficheros del harness solo por PR de upgrade del bot, código
  solo con spec ya fusionada (salvo releases y excepción visible `no-spec-required`), OpenSpec
  válido y, en PR de agentes (`aidlc`), evidencia de los tres validadores en `PASS`.

### Corregido
- Estándares §2: el backend es Python 3.14.
