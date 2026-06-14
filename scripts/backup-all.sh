#!/bin/bash
# Bootstreep Homelab – Backup-All Script (3-2-1-Regel)
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

BACKUP=~/backups/$(date +%Y%m%d-%H%M)
mkdir -p "$BACKUP"

log "Alle Docker-Volumes sichern..."
for volume in $(docker volume ls -q); do
    name="$(echo "$volume" | tr '/' '_')"
    docker run --rm -v "$volume":/data -v "$BACKUP":/backup alpine tar czf "/backup/${name}.tar.gz" -C /data . 2>/dev/null || \
        warn "Volume $volume konnte nicht gesichert werden"
done

log "Pi-hole Teleporter-Export..."
docker exec pihole pihole -a -t "$BACKUP/teleporter.tar.gz" 2>/dev/null || warn "Pi-hole Teleporter fehlgeschlagen"

log "Umgebungsvariablen sichern..."
if cp ~/docker/*/.env "$BACKUP"/ 2>/dev/null; then
    if command -v gpg &>/dev/null && [ -n "${BACKUP_GPG_RECIPIENT:-}" ]; then
        for f in "$BACKUP"/*.env; do
            [ -f "$f" ] && gpg --yes --recipient "$BACKUP_GPG_RECIPIENT" --encrypt "$f" && rm "$f"
        done
        log ".env-Dateien mit GPG verschlüsselt"
    else
        warn ".env-Dateien unverschlüsselt (GPG nicht konfiguriert)"
    fi
fi

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
