#!/usr/bin/env python3
"""Hook PreToolUse del harness de Meridian: bloquea cualquier llamada a una herramienta cuyo
contenido tenga forma de credencial (base de seguridad §2).

- Es una red extra, no el contrato: si algo falla, deja pasar (fail-open). Las puertas que
  bloquean de verdad son las de CI.
- Agnóstico de la herramienta: recorre TODO lo que llegue en la entrada (Claude, Codex y Copilot
  usan formas distintas) y no depende de nombres de herramienta.
- Para denegar: exit 2 con el motivo en stderr (Claude Code y Codex) y, además, un JSON de decisión
  en stdout que entienden Claude Code (hookSpecificOutput) y Copilot (permissionDecision).
- Nunca imprime el valor encontrado: solo qué tipo de credencial parece.
"""

from __future__ import annotations

import json
import re
import sys

PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    ("clave de acceso de AWS", re.compile(r"\b(AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("clave privada", re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA |ENCRYPTED )?PRIVATE KEY-----")),
    ("token de GitHub", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{36}\b|\bgithub_pat_[A-Za-z0-9_]{60,}")),
    ("clave de Anthropic", re.compile(r"\bsk-ant-[A-Za-z0-9_\-]{20,}")),
    ("clave de OpenRouter", re.compile(r"\bsk-or-v1-[A-Za-z0-9]{20,}")),
    ("clave de OpenAI", re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_\-]{32,}")),
    ("token de Slack", re.compile(r"\bxox[abposr]-[A-Za-z0-9-]{10,}")),
    ("JWT", re.compile(r"\beyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}")),
    (
        "secreto asignado en claro",
        re.compile(
            r"(?i)\b(?:api[_-]?key|secret|passw(?:or)?d|token|client[_-]?secret)\b\s*[=:]\s*['\"][^'\"\s]{16,}['\"]"
        ),
    ),
]


def strings(value: object) -> list[str]:
    """Todas las cadenas de la entrada, a cualquier profundidad (incluido JSON dentro de cadenas)."""
    out: list[str] = []
    if isinstance(value, str):
        out.append(value)
        if value[:1] in "{[":
            try:
                out.extend(strings(json.loads(value)))
            except ValueError:
                pass
    elif isinstance(value, dict):
        for v in value.values():
            out.extend(strings(v))
    elif isinstance(value, list):
        for v in value:
            out.extend(strings(v))
    return out


def main() -> int:
    try:
        event = json.load(sys.stdin)
    except Exception:
        return 0
    try:
        payload = {k: v for k, v in event.items() if k in ("tool_input", "toolArgs", "tool_args", "input", "arguments")}
        text = "\n".join(strings(payload or event))
        for kind, pattern in PATTERNS:
            if pattern.search(text):
                reason = (
                    f"Bloqueado por el harness: el contenido parece una {kind}. Los secretos viven en "
                    "1Password y llegan por External Secrets o secretos de CI, nunca en el repo ni en "
                    "comandos ([[corpus/02-security-baseline.md]] §2)."
                )
                print(
                    json.dumps(
                        {
                            "permissionDecision": "deny",
                            "permissionDecisionReason": reason,
                            "hookSpecificOutput": {
                                "hookEventName": "PreToolUse",
                                "permissionDecision": "deny",
                                "permissionDecisionReason": reason,
                            },
                        },
                        ensure_ascii=False,
                    )
                )
                print(reason, file=sys.stderr)
                return 2
        return 0
    except Exception:
        return 0  # fail-open: es una red extra


if __name__ == "__main__":
    sys.exit(main())
