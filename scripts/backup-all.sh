#!/bin/bash
# Backup aller Docker-Volumes + Configs + DBs (v4.0)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

[ "$EUID" -eq 0 ] && die "Nicht als root ausführen"

BACKUP_ROOT="${BACKUP_ROOT:-$HOME/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
ENCRYPT="${ENCRYPT:-false}"
GPG_RECIPIENT="${GPG_RECIPIENT:-}"
SKIP_DB="${SKIP_DB:-false}"

TIMESTAMP=$(date +%Y-%m-%d_%H%M)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

echo "============================================"
echo "  Backup nach $BACKUP_DIR"
echo "============================================"

echo ""
echo "── Datenbank-Backups ──"
if [ "$SKIP_DB" != "true" ]; then
    # Vaultwarden (SQLite)
    if docker exec vaultwarden sqlite3 /data/db.sqlite3 ".backup '/tmp/vaultwarden.db'" 2>/dev/null; then
        docker cp vaultwarden:/tmp/vaultwarden.db "$BACKUP_DIR/vaultwarden.db" 2>/dev/null || true
        docker exec vaultwarden rm -f /tmp/vaultwarden.db 2>/dev/null || true
        log "✓ Vaultwarden DB"
    fi

    # n8n (SQLite)
    if docker exec n8n sqlite3 /home/node/.n8n/database.sqlite ".backup '/tmp/n8n.db'" 2>/dev/null; then
        docker cp n8n:/tmp/n8n.db "$BACKUP_DIR/n8n.db" 2>/dev/null || true
        docker exec n8n rm -f /tmp/n8n.db 2>/dev/null || true
        log "✓ n8n DB"
    fi

    # Nextcloud (PostgreSQL) via Nextcloud AIO
    if docker ps --format '{{.Names}}' | grep -q nextcloud-aio-pgsql; then
        docker exec nextcloud-aio-pgsql pg_dumpall -U nextcloud > "$BACKUP_DIR/nextcloud.sql" 2>/dev/null && \
        gzip "$BACKUP_DIR/nextcloud.sql" && log "✓ Nextcloud PostgreSQL"
    fi
fi

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

# ZFS Snapshots
if command -v zfs &>/dev/null && zfs list -H bootstreep 2>/dev/null; then
    zfs snapshot -r bootstreep@backup-"$TIMESTAMP" && log "✓ ZFS Snapshot bootstreep@backup-$TIMESTAMP"
fi

echo ""
echo "── System-Configs ──"
[ -f /etc/docker/daemon.json ] && sudo cp /etc/docker/daemon.json "$BACKUP_DIR/"
[ -f /etc/samba/smb.conf ] && sudo cp /etc/samba/smb.conf "$BACKUP_DIR/"
[ -f /etc/fail2ban/jail.local ] && sudo cp /etc/fail2ban/jail.local "$BACKUP_DIR/"
[ -f /etc/sysctl.d/99-bootstreep.conf ] && sudo cp /etc/sysctl.d/99-bootstreep.conf "$BACKUP_DIR/"
[ -f /etc/ssh/sshd_config ] && sudo cp /etc/ssh/sshd_config "$BACKUP_DIR/"

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
echo "── Backup-Integrität ──"
total_files=$(find "$BACKUP_DIR" -type f | wc -l)
total_size=$(du -sh "$BACKUP_DIR" | cut -f1)
log "Dateien: $total_files, Größe: $total_size"

echo ""
echo "── Alte Backups aufräumen ──"
deleted=$(find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" -mtime +"$RETENTION_DAYS" -exec rm -rf {} \; -print 2>/dev/null | wc -l)
log "$deleted alte Backups gelöscht (>$RETENTION_DAYS Tage)"

echo ""
du -sh "$BACKUP_DIR"
echo ""
log "Backup fertig: $BACKUP_DIR"
