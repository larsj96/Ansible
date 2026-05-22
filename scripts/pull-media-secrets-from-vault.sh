#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out_file="${1:-$repo_root/group_vars/media_secrets.yml}"
VAULT_ADDR="${VAULT_ADDR:-http://10.0.0.37:8200}"
VAULT_MEDIA_SECRET_PATH="${VAULT_MEDIA_SECRET_PATH:-homelab/data/media/media1}"

if [ -z "${VAULT_TOKEN:-}" ] && [ -f "$HOME/.config/homelab/vault.env" ]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/homelab/vault.env"
fi

if [ -z "${VAULT_TOKEN:-}" ]; then
  echo "VAULT_TOKEN is not set and $HOME/.config/homelab/vault.env was not found" >&2
  exit 1
fi

tmp_json="$(mktemp)"
trap 'rm -f "$tmp_json"' EXIT

curl -fsS \
  -H "X-Vault-Token: $VAULT_TOKEN" \
  "$VAULT_ADDR/v1/$VAULT_MEDIA_SECRET_PATH" \
  > "$tmp_json"

umask 077
mkdir -p "$(dirname "$out_file")"

python3 - "$tmp_json" "$out_file" <<'PY'
import json
import sys

in_file, out_file = sys.argv[1:3]
with open(in_file, encoding="utf-8") as f:
    payload = json.load(f)

data = payload.get("data", {}).get("data", {})
keys = [
    "plex_claim",
    "unpackerr_sonarr_api_key",
    "unpackerr_radarr_api_key",
]

with open(out_file, "w", encoding="utf-8") as f:
    f.write("---\n")
    f.write("# Generated from HashiCorp Vault. Do not commit.\n")
    for key in keys:
        value = data.get(key, "") or ""
        f.write(f"{key}: {json.dumps(str(value))}\n")
PY

chmod 600 "$out_file"
echo "Wrote $out_file from Vault path $VAULT_MEDIA_SECRET_PATH"
