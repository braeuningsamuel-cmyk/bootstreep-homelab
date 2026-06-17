#!/bin/bash
# Decrypt .env files managed with SOPS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

[ "$EUID" -eq 0 ] && die "Nicht als root ausführen"

if ! command -v sops &>/dev/null; then
    die "SOPS nicht installiert. Installiere: pip install sops"
fi

ENV_DIR="${1:-$HOME/docker}"

echo ""
echo "── Entschlüssele .env Dateien ──"
count=0
while IFS= read -r -d '' enc; do
    dir=$(dirname "$enc")
    plain="$dir/.env"
    name=$(basename "$dir")
    if [ ! -f "$plain" ]; then
        sops decrypt "$enc" > "$plain" 2>/dev/null && log "✓ $name" || warn "✗ $name"
        count=$((count + 1))
    fi
done < <(find "$ENV_DIR" -name "*.enc.env" -print0 2>/dev/null)

log "$count .env Dateien entschlüsselt"