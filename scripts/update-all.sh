#!/bin/bash
# Atlas.Lab Homelab – Update-All Script
# Führt System-Updates und alle Container-Updates durch
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

info "=== System-Updates ===" && sudo apt update && sudo apt upgrade -y

info "=== Docker-Container updaten ==="
cd ~/docker
for d in */; do
    if [ -f "$d/compose.yml" ]; then
        log "Update: ${d%/}"
        (cd "$d" && docker compose pull && docker compose up -d)
    fi
done

info "=== KI-Modelle aktualisieren ==="
docker exec ollama ollama pull mistral:7b 2>/dev/null || warn "Ollama nicht erreichbar"
docker exec ollama ollama pull llama3.2:3b 2>/dev/null || true
docker exec ollama ollama pull deepseek-coder:6.7b 2>/dev/null || true
docker exec ollama ollama pull llama3.2:8b 2>/dev/null || true
docker exec ollama ollama pull phi4:14b 2>/dev/null || true

info "=== Pi-hole aktualisieren ==="
docker exec pihole pihole -up 2>/dev/null || warn "Pi-hole nicht erreichbar"
docker exec pihole pihole -g 2>/dev/null || true

info "=== Docker-Cleanup ==="
docker system prune -af --volumes 2>/dev/null || true

log "Update abgeschlossen!"
