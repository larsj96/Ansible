#!/usr/bin/env bash
set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://10.0.0.37:8200}"
VAULT_MEDIA_KV_PATH="${VAULT_MEDIA_KV_PATH:-homelab/media/media1}"

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

vault kv patch "$VAULT_MEDIA_KV_PATH" "$key=$value" >/dev/null
echo "Updated $key in Vault path $VAULT_MEDIA_KV_PATH"
