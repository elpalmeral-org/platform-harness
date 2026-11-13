package meridian.pr_gates_test

import rego.v1

import data.meridian.pr_gates

evidence := concat("\n", [
	"<details><summary>spec-validator · PASS</summary>…</details>",
	"<details><summary>security-gate · PASS</summary>…</details>",
	"<details><summary>impl-conformance · PASS</summary>…</details>",
])

feature_pr := {
	"checks": {"apm-audit": "success", "harness-signature": "success", "openspec": "success"},
	"harness": {"version": "0.1.0"},
	"pr": {
		"author": "virgo1985",
		"title": "feat: order-risk-score",
		"labels": ["aidlc"],
		"changed_files": ["apps/backend/src/meridian_orders/service.py", "apps/backend/tests/test_service.py"],
		"openspec_changes_in_base": ["order-risk-score"],
		"body": evidence,
	},
}

test_pr_de_agente_completo_pasa if {
	pr_gates.allow with input as feature_pr
}

test_drift_bloquea if {
	not pr_gates.allow with input as json.patch(feature_pr, [{"op": "replace", "path": "/checks/apm-audit", "value": "failure"}])
}

test_firma_invalida_bloquea if {
	not pr_gates.allow with input as json.patch(feature_pr, [{"op": "replace", "path": "/checks/harness-signature", "value": "failure"}])
}

test_harness_antiguo_bloquea if {
	inp := json.patch(feature_pr, [{"op": "replace", "path": "/harness/version", "value": "0.0.9"}])
	not pr_gates.allow with input as inp
	some m in pr_gates.deny with input as inp
	contains(m, "por debajo del mínimo")
}

test_repo_sin_harness_bloquea if {
	inp := json.patch(feature_pr, [{"op": "remove", "path": "/harness/version"}])
	not pr_gates.allow with input as inp
	some m in pr_gates.deny with input as inp
	contains(m, "no usa el harness")
}

test_codigo_sin_spec_aprobada_bloquea if {
	not pr_gates.allow with input as json.patch(feature_pr, [{"op": "replace", "path": "/pr/openspec_changes_in_base", "value": []}])
}

test_openspec_invalido_bloquea if {
	not pr_gates.allow with input as json.patch(feature_pr, [{"op": "replace", "path": "/checks/openspec", "value": "failure"}])
}

test_pr_de_agente_sin_un_veredicto_bloquea if {
	body := replace(evidence, "security-gate · PASS", "security-gate · FAIL")
	not pr_gates.allow with input as json.patch(feature_pr, [{"op": "replace", "path": "/pr/body", "value": body}])
}

test_pr_humano_no_necesita_evidencia if {
	inp := json.patch(feature_pr, [
		{"op": "replace", "path": "/pr/labels", "value": []},
		{"op": "replace", "path": "/pr/body", "value": "Cambio a mano"},
	])
	pr_gates.allow with input as inp
}

test_persona_editando_el_harness_bloquea if {
	inp := json.patch(feature_pr, [{"op": "add", "path": "/pr/changed_files/-", "value": ".claude/agents/security-gate.md"}])
	not pr_gates.allow with input as inp
}

test_upgrade_del_bot_pasa if {
	inp := json.patch(feature_pr, [
		{"op": "replace", "path": "/pr/author", "value": "elpalmeral-platform-bot[bot]"},
		{"op": "replace", "path": "/pr/title", "value": "chore(harness): upgrade 0.1.0 → 0.2.0"},
		{"op": "replace", "path": "/pr/labels", "value": ["harness-upgrade"]},
		{"op": "replace", "path": "/pr/changed_files", "value": ["apm.yml", "apm.lock.yaml", ".claude/settings.json"]},
		{"op": "replace", "path": "/pr/openspec_changes_in_base", "value": []},
		{"op": "replace", "path": "/pr/body", "value": ""},
	])
	pr_gates.allow with input as inp
}

test_etiqueta_harness_upgrade_de_una_persona_no_basta if {
	inp := json.patch(feature_pr, [
		{"op": "replace", "path": "/pr/labels", "value": ["harness-upgrade"]},
		{"op": "replace", "path": "/pr/changed_files", "value": ["apm.lock.yaml"]},
	])
	not pr_gates.allow with input as inp
}

test_release_please_pasa_sin_spec if {
	inp := json.patch(feature_pr, [
		{"op": "replace", "path": "/pr/author", "value": "elpalmeral-platform-bot[bot]"},
		{"op": "replace", "path": "/pr/title", "value": "chore(release): 0.2.0"},
		{"op": "replace", "path": "/pr/labels", "value": ["autorelease: pending"]},
		{"op": "replace", "path": "/pr/changed_files", "value": ["CHANGELOG.md", "apps/backend/src/meridian_orders/__init__.py"]},
		{"op": "replace", "path": "/pr/openspec_changes_in_base", "value": []},
	])
	pr_gates.allow with input as inp
}

test_dependabot_sin_codigo_pasa if {
	inp := json.patch(feature_pr, [
		{"op": "replace", "path": "/pr/author", "value": "dependabot[bot]"},
		{"op": "replace", "path": "/pr/labels", "value": ["dependencies"]},
		{"op": "replace", "path": "/pr/changed_files", "value": ["apps/backend/uv.lock", "apps/backend/pyproject.toml"]},
		{"op": "replace", "path": "/pr/openspec_changes_in_base", "value": []},
		{"op": "replace", "path": "/checks/openspec", "value": "skipped"},
	])
	pr_gates.allow with input as inp
}

test_excepcion_visible if {
	inp := json.patch(feature_pr, [
		{"op": "replace", "path": "/pr/labels", "value": ["no-spec-required"]},
		{"op": "replace", "path": "/pr/openspec_changes_in_base", "value": []},
	])
	pr_gates.allow with input as inp
	count(pr_gates.warn) == 1 with input as inp
}
