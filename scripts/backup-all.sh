#!/bin/bash
# Backup aller Docker-Volumes + Configs
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

[ "$EUID" -eq 0 ] && die "Nicht als root ausführen"

BACKUP_ROOT="${BACKUP_ROOT:-$HOME/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
ENCRYPT="${ENCRYPT:-false}"
GPG_RECIPIENT="${GPG_RECIPIENT:-}"

TIMESTAMP=$(date +%Y-%m-%d_%H%M)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "============================================"
echo "  Backup nach $BACKUP_DIR"
echo "============================================"

echo ""
echo "── Docker Volumes ──"
vol_count=0
for vol in $(docker volume ls -q); do
    info "Backup $vol..."
    if docker run --rm \
        -v "$vol:/source:ro" \
        -v "$BACKUP_DIR:/backup" \
        alpine sh -c "tar czf /backup/vol_${vol}.tar.gz -C /source ." 2>/dev/null; then
        vol_count=$((vol_count + 1))
    else
        warn "Fehler: $vol"
    fi
done
log "$vol_count Volumes gesichert"

echo ""
echo "── Verzeichnisse ──"
for d in docker config hermes ai-agent scripts; do
    [ -d "$HOME/$d" ] && tar czf "$BACKUP_DIR/dir_${d}.tar.gz" -C "$HOME" "$d" && log "✓ ~/$d"
done

echo ""
echo "── System-Configs ──"
[ -f /etc/docker/daemon.json ] && sudo cp /etc/docker/daemon.json "$BACKUP_DIR/"
[ -f /etc/samba/smb.conf ] && sudo cp /etc/samba/smb.conf "$BACKUP_DIR/"
[ -f /etc/fail2ban/jail.local ] && sudo cp /etc/fail2ban/jail.local "$BACKUP_DIR/"
[ -f /etc/sysctl.d/99-bootstreep.conf ] && sudo cp /etc/sysctl.d/99-bootstreep.conf "$BACKUP_DIR/"

echo ""
echo "── .env-Dateien ──"
env_files=$(find "$HOME" \( -name ".env" -path "*/docker/*" -o -name ".env" -path "*/ai-agent/*" \) 2>/dev/null)
if [ -n "$env_files" ]; then
    if [ "$ENCRYPT" = "true" ] && [ -n "$GPG_RECIPIENT" ]; then
        echo "$env_files" | while read -r f; do
            gpg --batch --yes --recipient "$GPG_RECIPIENT" \
                --output "$BACKUP_DIR/env_$(basename "$(dirname "$f")").gpg" \
                --encrypt "$f"
        done
        log ".env mit GPG verschlüsselt"
    else
        warn ".env UNVERSCHLÜSSELT (ENCRYPT=true GPG_RECIPIENT=mail@x für Verschlüsselung)"
        mkdir -p "$BACKUP_DIR/env"
        echo "$env_files" | while read -r f; do
            cp "$f" "$BACKUP_DIR/env/$(basename "$(dirname "$f")").env"
        done
    fi
fi

echo ""
echo "── Alte Backups aufräumen ──"
deleted=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" -mtime +"$RETENTION_DAYS" -exec rm -rf {} \; -print 2>/dev/null | wc -l)
log "$deleted alte Backups gelöscht (>$RETENTION_DAYS Tage)"

echo ""
du -sh "$BACKUP_DIR"
echo ""
log "Backup fertig: $BACKUP_DIR"
