"""Tests del hook block_secrets: formas de entrada de Claude Code, Codex y Copilot."""

import json
import subprocess
import sys
from pathlib import Path

HOOK = Path(__file__).resolve().parents[1] / ".apm" / "hooks" / "scripts" / "block_secrets.py"
FAKE_GH = "ghp_" + "a1B2" * 9  # 36 caracteres: forma de token, no es real
FAKE_OR = "sk-or-v1-" + "0f" * 32


def run(event: object) -> subprocess.CompletedProcess[str]:
    return subprocess.run([sys.executable, str(HOOK)], input=json.dumps(event), capture_output=True, text=True)


def test_claude_write_con_token_se_bloquea() -> None:
    r = run({"hook_event_name": "PreToolUse", "tool_name": "Write", "tool_input": {"file_path": "a.py", "content": f"T = '{FAKE_GH}'"}})
    assert r.returncode == 2
    out = json.loads(r.stdout)
    assert out["hookSpecificOutput"]["permissionDecision"] == "deny"
    assert FAKE_GH not in r.stdout + r.stderr  # nunca repite el secreto


def test_claude_edit_multiedit() -> None:
    r = run({"tool_name": "MultiEdit", "tool_input": {"edits": [{"old_string": "x", "new_string": f"key: '{FAKE_OR}'"}]}})
    assert r.returncode == 2


def test_bash_con_secreto_en_el_comando() -> None:
    r = run({"tool_name": "Bash", "tool_input": {"command": f"gh secret set X --body {FAKE_GH}"}})
    assert r.returncode == 2


def test_copilot_toolargs_como_cadena_json() -> None:
    r = run({"toolName": "edit", "toolArgs": json.dumps({"path": "b.ts", "new_str": "-----BEGIN OPENSSH PRIVATE KEY-----"})})
    assert r.returncode == 2
    assert json.loads(r.stdout)["permissionDecision"] == "deny"


def test_asignacion_en_claro() -> None:
    r = run({"tool_input": {"content": 'password = "Sup3rS3cretValue!!"'}})
    assert r.returncode == 2


def test_codigo_normal_pasa() -> None:
    r = run({"tool_name": "Write", "tool_input": {"content": "def total(order):\n    return sum(i.price for i in order.items)\n"}})
    assert r.returncode == 0 and r.stdout == ""


def test_referencia_a_variable_pasa() -> None:
    r = run({"tool_input": {"content": 'token = os.environ["PORT_TOKEN"]'}})
    assert r.returncode == 0


def test_entrada_rota_falla_abierto() -> None:
    r = subprocess.run([sys.executable, str(HOOK)], input="no es json", capture_output=True, text=True)
    assert r.returncode == 0
