# El motor A (UHP / HarnessRouter) nunca lleva modelos de Anthropic (ADR 0025): Claude llega solo
# por Claude Code con la suscripción personal, motor B, que no pasa por `uhp/roles.yaml`.
#
# Entrada: `uhp/roles.yaml` convertido a JSON (p.ej. `yq -o=json uhp/roles.yaml`), forma
#   {"version": 1, "roles": {"<rol>": {"provider": "...", "base": "...", "model": "..."}}}

package meridian.uhp_roles

import rego.v1

default allow := false

allow if count(deny) == 0

anthropic_providers := {"anthropic"}

anthropic_bases := {"claude-code"}

deny contains msg if {
	some role, cfg in input.roles
	cfg.provider in anthropic_providers
	msg := sprintf("rol %s: provider %q no permitido en el motor A (ADR 0025, sin Anthropic)", [role, cfg.provider])
}

deny contains msg if {
	some role, cfg in input.roles
	cfg.base in anthropic_bases
	msg := sprintf("rol %s: base %q no permitida en el motor A (ADR 0025, sin Anthropic)", [role, cfg.base])
}

deny contains msg if {
	some role, cfg in input.roles
	contains(lower(cfg.model), "anthropic")
	msg := sprintf("rol %s: modelo %q parece de Anthropic, no permitido en el motor A (ADR 0025)", [role, cfg.model])
}

deny contains msg if {
	some role, cfg in input.roles
	contains(lower(cfg.model), "claude")
	msg := sprintf("rol %s: modelo %q parece de Anthropic, no permitido en el motor A (ADR 0025)", [role, cfg.model])
}
