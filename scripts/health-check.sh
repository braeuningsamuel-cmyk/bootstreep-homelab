#!/bin/bash
# Bootstreep Homelab – Health-Check Script
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Bootstreep Homelab – Health Check               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

info "=== Docker-Container Status ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
info "=== Einzelcheck ==="
for name in pihole unbound tor websurfx jellyfin ollama hermes open-webui n8n syncthing uptime-kuma nextcloud-aio sonarr radarr prowlarr bazarr sabnzbd heimdall teamspeak amp caddy; do
    state=$(docker inspect --format='{{.State.Status}}' "$name" 2>/dev/null || echo "?")
    case "$state" in
        running) log "$name läuft" ;;
        "?")     warn "$name nicht gefunden" ;;
        *)       err "$name: $state" ;;
    esac
done

echo ""
info "=== DNS Test ==="
SERVER_IP="${SERVER_IP:-192.168.178.20}"
if dig google.de @"$SERVER_IP" +short &>/dev/null; then
    log "DNS-Auflösung funktioniert ($SERVER_IP)"
else
    err "DNS-Auflösung fehlgeschlagen"
fi

echo ""
info "=== System-Ressourcen ==="
free -h | grep -E "^(Mem|Speicher)"
df -h / | tail -1
echo "Uptime: $(uptime -p)"
echo "Last:   $(uptime | awk -F'load average:' '{print $2}')"

echo ""
info "=== Dienste-Status ==="
for svc in ssh ufw systemd-resolved; do
    if systemctl is-active --quiet "$svc"; then
        log "$svc läuft"
    else
        warn "$svc läuft nicht"
    fi
done

echo ""
info "=== Docker Volumes ==="
docker volume ls --format "table {{.Name}}\t{{.Driver}}" | head -20

echo ""
log "Health Check abgeschlossen."
