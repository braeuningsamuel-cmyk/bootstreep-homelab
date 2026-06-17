#!/bin/bash
# Update System + alle Docker-Container
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

[ "$EUID" -eq 0 ] && die "Nicht als root ausführen"

echo "============================================"
echo "  Update All – $(date '+%Y-%m-%d %H:%M')"
echo "============================================"

echo ""
echo "── System Update ──"
sudo apt update 2>&1 | tail -2
sudo apt upgrade -y 2>&1 | tail -2
sudo apt autoremove -y 2>&1 | tail -2
log "apt Update fertig"

echo ""
echo "── Watchtower pausieren ──"
docker stop watchtower 2>/dev/null && log "Watchtower gestoppt" || true

echo ""
echo "── Docker Images pullen ──"
pulled=0 failed=0
for dir in "$HOME"/docker/*/; do
    [ -f "$dir/compose.yml" ] || continue
    name=$(basename "$dir")
    [ "$name" = "amp-instances" ] && continue
    info "Pulling $name..."
    if (cd "$dir" && docker compose pull) 2>/dev/null; then
        pulled=$((pulled + 1))
    else
        warn "Pull fehlgeschlagen: $name"
        failed=$((failed + 1))
    fi
done
log "$pulled gepullt, $failed fehlgeschlagen"

echo ""
echo "── Container neu starten (Rolling) ──"
[ -d "$HOME/docker/caddy" ] && (cd "$HOME/docker/caddy" && docker compose up -d) || true
for dir in "$HOME"/docker/*/; do
    [ -f "$dir/compose.yml" ] || continue
    name=$(basename "$dir")
    [ "$name" = "caddy" ] && continue
    [ "$name" = "amp-instances" ] && continue
    (cd "$dir" && docker compose up -d) 2>/dev/null || warn "Restart: $name"
done

echo ""
echo "── Watchtower reaktivieren ──"
docker start watchtower 2>/dev/null && log "Watchtower läuft" || true

echo ""
echo "── Docker Cleanup ──"
docker image prune -af --filter "until=168h" 2>/dev/null || true
docker builder prune -af 2>/dev/null || true

echo ""
echo "── Health-Check ──"
sleep 5
"$SCRIPT_DIR/health-check.sh" || true

echo ""
log "Update fertig"
