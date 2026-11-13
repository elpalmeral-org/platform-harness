package meridian.uhp_roles

import rego.v1

valid_roles := {
	"roles": {
		"spec-writer": {"provider": "openrouter", "base": "opencode", "model": "deepseek/deepseek-v3.2"},
		"implementer": {"provider": "openrouter", "base": "opencode", "model": "deepseek/deepseek-v3.2"},
		"spec-validator": {"provider": "openrouter", "base": "opencode", "model": "deepseek/deepseek-v3.2"},
	},
}

test_allow_sin_anthropic if {
	allow with input as valid_roles
}

test_deny_provider_anthropic if {
	roles := json.patch(valid_roles, [{
		"op": "replace",
		"path": "/roles/implementer/provider",
		"value": "anthropic",
	}])
	deny["rol implementer: provider \"anthropic\" no permitido en el motor A (ADR 0025, sin Anthropic)"] with input as roles
	not allow with input as roles
}

test_deny_base_claude_code if {
	roles := json.patch(valid_roles, [{
		"op": "replace",
		"path": "/roles/implementer/base",
		"value": "claude-code",
	}])
	deny["rol implementer: base \"claude-code\" no permitida en el motor A (ADR 0025, sin Anthropic)"] with input as roles
	not allow with input as roles
}

test_deny_model_anthropic_slug if {
	roles := json.patch(valid_roles, [{
		"op": "replace",
		"path": "/roles/implementer/model",
		"value": "anthropic/claude-sonnet-5",
	}])
	not allow with input as roles
}

test_deny_model_claude_sin_anthropic_en_el_nombre if {
	roles := json.patch(valid_roles, [{
		"op": "replace",
		"path": "/roles/spec-validator/model",
		"value": "some-provider/claude-clone",
	}])
	not allow with input as roles
}
