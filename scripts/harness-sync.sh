#!/usr/bin/env bash
# Publica/actualiza los roles de uhp/roles.yaml como meridian/<rol> en HarnessRouter (F4.7,
# ADR 0033). Script local, NO GitHub Action: se descubrió al intentarlo que uhp.apl.elpalmeral.es
# no resuelve desde un runner de GitHub (el lab es solo LAN/VPN, "Todo sale, nada entra") y el
# runner self-hosted de ARC (arc-aidlc) solo está instalado en meridian-orders (ADR 0031,
# alcance de un solo repo a propósito) — platform-harness no tiene ningún runner con LAN. Se
# ejecuta a mano, desde un Mac con la VPN WireGuard activa, con la clave en 1Password (nunca en
# variables de entorno del shell, nunca en un secreto de CI de este repo).
#
# Uso: scripts/harness-sync.sh
# Requiere: op (1Password CLI) con sesión activa, curl, jq, yq.
#
# Idempotente: el "name" de un harness no es buscable por el servidor (confirmado contra la API
# real), así que cada rol se busca por nombre en el listado completo antes de decidir si crear
# (POST) o actualizar (PUT) — nunca crea un duplicado por relanzarlo.

set -euo pipefail
cd "$(dirname "$0")/.."

HR_URL="https://uhp.apl.elpalmeral.es/api/harness/v1"
API_KEY="$(op read -n 'op://agentic-lab/harnessrouter/api_key')"

echo "GET /harnesses (listado para buscar por name)"
status=$(curl -s -o /tmp/harness-sync-existing.json -w '%{http_code}' --max-time 15 \
  -H "Authorization: Bearer $API_KEY" \
  "$HR_URL/harnesses")
if [ "$status" != "200" ]; then
  echo "::error::GET /harnesses devolvió HTTP $status, no 200."
  cat /tmp/harness-sync-existing.json
  exit 1
fi

yq -o=json '.roles' uhp/roles.yaml > /tmp/harness-sync-roles.json
for role in $(jq -r 'keys[]' /tmp/harness-sync-roles.json); do
  echo "=== $role ==="
  name="meridian/$role"
  base=$(jq -r --arg r "$role" '.[$r].base' /tmp/harness-sync-roles.json)
  model=$(jq -r --arg r "$role" '.[$r].model' /tmp/harness-sync-roles.json)
  disabled=$(jq -c --arg r "$role" '.[$r].disabledTools // []' /tmp/harness-sync-roles.json)

  jq -n \
    --arg name "$name" \
    --arg base "$base" \
    --arg model "$model" \
    --argjson disabled "$disabled" \
    --rawfile prompt ".apm/agents/$role.agent.md" \
    '{name: $name, base: $base, default_model: $model, system_prompt: $prompt, disabled_tools: $disabled}' \
    > /tmp/harness-sync-body.json

  existing_id=$(jq -r --arg n "$name" '.harnesses[] | select(.name == $n) | .id' /tmp/harness-sync-existing.json | head -1)

  if [ -n "$existing_id" ]; then
    echo "ya existe ($existing_id) -> PUT"
    status=$(curl -s -o /tmp/harness-sync-result.json -w '%{http_code}' --max-time 20 -X PUT \
      -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
      --data @/tmp/harness-sync-body.json "$HR_URL/harnesses/$existing_id")
  else
    echo "no existe -> POST"
    status=$(curl -s -o /tmp/harness-sync-result.json -w '%{http_code}' --max-time 20 -X POST \
      -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
      --data @/tmp/harness-sync-body.json "$HR_URL/harnesses")
  fi

  if [ "$status" != "200" ]; then
    echo "::error::$name: HTTP $status"
    cat /tmp/harness-sync-result.json
    exit 1
  fi
  echo "$name -> $(jq -r '.id' /tmp/harness-sync-result.json)"
done
