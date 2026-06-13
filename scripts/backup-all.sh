#!/bin/bash
# Atlas.Lab Homelab – Backup-All Script (3-2-1-Regel)
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

BACKUP=~/backups/$(date +%Y%m%d-%H%M)
mkdir -p "$BACKUP"

log "Ollama-Daten sichern..."
docker run --rm -v ollama_ollama_data:/data -v "$BACKUP":/backup alpine tar czf /backup/ollama.tar.gz -C /data . 2>/dev/null || warn "Ollama-Volume nicht gefunden"

log "Pi-hole-Daten sichern..."
docker run --rm -v dns_etc-pihole:/data -v "$BACKUP":/backup alpine tar czf /backup/pihole.tar.gz -C /data . 2>/dev/null || warn "Pi-hole-Volume nicht gefunden"

log "Pi-hole Teleporter-Export..."
docker exec pihole pihole -a -t "$BACKUP/teleporter.tar.gz" 2>/dev/null || warn "Pi-hole Teleporter fehlgeschlagen"

log "Umgebungsvariablen sichern..."
cp ~/docker/*/.env "$BACKUP"/ 2>/dev/null || true

log "SSH-Konfiguration sichern..."
sudo cp /etc/ssh/sshd_config "$BACKUP"/ 2>/dev/null || true
cp ~/.ssh/config "$BACKUP"/ 2>/dev/null || true

log "UFW-Regeln exportieren..."
sudo ufw status numbered > "$BACKUP/ufw.txt" 2>/dev/null || true

log "Docker-Compose-Dateien sichern..."
cp -r ~/docker "$BACKUP/docker-configs" 2>/dev/null || true

log "Crontab sichern..."
crontab -l > "$BACKUP/crontab.txt" 2>/dev/null || true

SIZE=$(du -sh "$BACKUP" | cut -f1)
log "Backup abgeschlossen: $BACKUP ($SIZE)"
warn "→ Kopiere das Backup auf ein separates Laufwerk / NAS!"
