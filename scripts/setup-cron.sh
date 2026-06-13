#!/bin/bash
# Atlas.Lab Homelab – Cron-Jobs einrichten
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

info "Cron-Jobs für Homelab-Wartung einrichten..."
echo ""

# Wöchentliches Update (Sonntag 3 Uhr)
(crontab -l 2>/dev/null | grep -q "update-all.sh") && warn "Cron: update-all.sh bereits vorhanden." || {
    (crontab -l 2>/dev/null; echo "0 3 * * 0 $HOME/scripts/update-all.sh >/dev/null 2>&1") | crontab -
    log "Cron: update-all.sh → So 3:00 Uhr"
}

# Wöchentliches Backup (Sonntag 4 Uhr)
(crontab -l 2>/dev/null | grep -q "backup-all.sh") && warn "Cron: backup-all.sh bereits vorhanden." || {
    (crontab -l 2>/dev/null; echo "0 4 * * 0 $HOME/scripts/backup-all.sh >/dev/null 2>&1") | crontab -
    log "Cron: backup-all.sh → So 4:00 Uhr"
}

# Health-Check alle 30 Minuten
(crontab -l 2>/dev/null | grep -q "health-check.sh") && warn "Cron: health-check.sh bereits vorhanden." || {
    (crontab -l 2>/dev/null; echo "*/30 * * * * $HOME/scripts/health-check.sh >/dev/null 2>&1") | crontab -
    log "Cron: health-check.sh → alle 30 Minuten"
}

# Pi-hole Gravity-Updates (täglich 2 Uhr)
(crontab -l 2>/dev/null | grep -q "pihole -g") && warn "Cron: Pi-hole gravity bereits vorhanden." || {
    (crontab -l 2>/dev/null; echo "0 2 * * * docker exec pihole pihole -g >/dev/null 2>&1") | crontab -
    log "Cron: Pi-hole Gravity → täglich 2:00 Uhr"
}

echo ""
log "Aktuelle Crontab:"
crontab -l
