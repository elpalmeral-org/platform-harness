# Política de merge de los repos de producto de Meridian (ADR 0023, ADR 0025).
# La evalúa el check `harness-ok` en cada PR: lo que no cumple, no se fusiona. Las excepciones
# son visibles (etiquetas que quedan en el PR y avisos en la salida), nunca silenciosas.
#
# Entrada (la construye el workflow harness-ok):
#   checks:  {"apm-audit": "success|failure", "harness-signature": "...", "openspec": "...|skipped"}
#   harness: {"version": "X.Y.Z"}                    versión del harness fijada en apm.lock.yaml
#   pr:      {"author", "title", "labels": [], "changed_files": [], "body",
#             "openspec_changes_in_base": []}       cambios OpenSpec del PR que YA están en la rama base

package meridian.pr_gates

import rego.v1

# Subir este valor obliga al parque a aceptar el PR de upgrade: los repos con un harness más
# antiguo dejan de poder fusionar (ADR 0023).
minimum_harness_version := "0.1.0"

platform_bot := "elpalmeral-platform-bot[bot]"

validators := ["spec-validator", "security-gate", "impl-conformance"]

# Ficheros que instala o genera el harness: no se editan a mano (base de seguridad §7).
harness_paths := [
	"apm.yml", "apm.lock.yaml", "AGENTS.md", "CLAUDE.md", ".mcp.json", "opencode.json",
	".claude/", ".agents/", ".codex/", ".opencode/",
	".github/instructions/", ".github/agents/", ".github/prompts/", ".github/hooks/",
	".github/mcp.json", ".github/copilot-instructions.md",
]

default allow := false

allow if count(deny) == 0

labels := {l | some l in input.pr.labels}

# ------------------------------------------------------------------ hechos

touches_code if {
	some f in input.pr.changed_files
	startswith(f, "apps/")
	contains(f, "/src/")
}

touches_harness if {
	some f in input.pr.changed_files
	some p in harness_paths
	startswith(f, p)
}

release_pr if {
	input.pr.author == platform_bot
	startswith(input.pr.title, "chore(release)")
}

harness_upgrade_pr if {
	input.pr.author == platform_bot
	"harness-upgrade" in labels
}

spec_approved if count(object.get(input.pr, "openspec_changes_in_base", [])) > 0

agent_pr if "aidlc" in labels

verdict_pass(role) if {
	regex.match(sprintf(`<summary>%s · PASS</summary>`, [role]), object.get(input.pr, "body", ""))
}

# ------------------------------------------------------------------ reglas (cada una, con remedio)

deny contains "drift del harness: `apm audit --ci` falla. Los ficheros del harness no se editan a mano; llegan por un PR de upgrade" if {
	input.checks["apm-audit"] != "success"
}

deny contains "la release del harness fijada en apm.lock.yaml no tiene una firma válida de la plataforma" if {
	input.checks["harness-signature"] != "success"
}

deny contains msg if {
	semver.compare(input.harness.version, minimum_harness_version) < 0
	msg := sprintf("harness %s por debajo del mínimo %s: fusiona antes el PR de upgrade pendiente", [input.harness.version, minimum_harness_version])
}

deny contains "el PR cambia ficheros del harness y no es un upgrade de la plataforma (autor elpalmeral-platform-bot[bot] y etiqueta harness-upgrade)" if {
	touches_harness
	not harness_upgrade_pr
}

deny contains "el PR cambia código (apps/*/src/) sin un cambio OpenSpec aprobado: usa /feature y fusiona antes el PR de la spec" if {
	touches_code
	not spec_approved
	not release_pr
	not "no-spec-required" in labels
}

deny contains "OpenSpec inválido: ejecuta `openspec validate --all --strict`" if {
	not input.checks.openspec in {"success", "skipped"}
}

deny contains msg if {
	agent_pr
	some role in validators
	not verdict_pass(role)
	msg := sprintf("PR de agente sin evidencia de `%s · PASS` en el cuerpo: vuelve a lanzar /feature (fase B)", [role])
}

# ------------------------------------------------------------------ avisos (no bloquean, se ven)

warn contains "excepción: el PR cambia código sin spec gracias a la etiqueta no-spec-required" if {
	touches_code
	not spec_approved
	not release_pr
	"no-spec-required" in labels
}
