#!/usr/bin/env bash
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://10.0.0.37:8200}"
VAULT_MEDIA_KV_PATH="${VAULT_MEDIA_KV_PATH:-homelab/media/media1}"
VAULT_MEDIA_SECRET_PATH="${VAULT_MEDIA_SECRET_PATH:-homelab/data/media/media1}"

if [ -z "${VAULT_TOKEN:-}" ] && [ -f "$HOME/.config/homelab/vault.env" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/homelab/vault.env"
fi

if [ -z "${VAULT_TOKEN:-}" ]; then
  echo "VAULT_TOKEN is not set and $HOME/.config/homelab/vault.env was not found" >&2
  exit 1
fi

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 key value" >&2
  echo "Example: $0 plex_claim claim-xxxxxxxx" >&2
  exit 1
fi

key="$1"
value="$2"

case "$key" in
  plex_claim|unpackerr_sonarr_api_key|unpackerr_radarr_api_key) ;;
  *)
    echo "Unsupported media secret key: $key" >&2
    exit 1
    ;;
esac

tmp_current="$(mktemp)"
tmp_payload="$(mktemp)"
trap 'rm -f "$tmp_current" "$tmp_payload"' EXIT

curl -fsS \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/$VAULT_MEDIA_SECRET_PATH" \
  > "$tmp_current"

python3 - "$tmp_current" "$tmp_payload" "$key" "$value" <<'PY'
import json
import sys

current_file, payload_file, key, value = sys.argv[1:5]
with open(current_file, encoding="utf-8") as f:
    current = json.load(f)

data = current.get("data", {}).get("data", {})
data[key] = value

with open(payload_file, "w", encoding="utf-8") as f:
    json.dump({"data": data}, f)
PY

curl -fsS \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  -H "Content-Type: application/json" \
  -X POST \
  --data @"$tmp_payload" \
  "$VAULT_ADDR/v1/$VAULT_MEDIA_SECRET_PATH" \
  >/dev/null

echo "Updated $key in Vault path $VAULT_MEDIA_KV_PATH"
