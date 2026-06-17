#!/bin/bash
# Disaster Recovery – 8 Szenarien
# Bootstreep Homelab v4.0
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

RESTORE_ROOT="${RESTORE_ROOT:-$HOME/backups}"
HOSTNAME="$(hostname)"

case "${1:-help}" in

# ════════════════════════════════════════════════════════════
# SZENARIO 1: SSD Totalausfall
# ════════════════════════════════════════════════════════════
ssd-failure)
    echo "═══ SZENARIO 1: SSD TOTALAUSFALL ═══"
    echo ""
    echo "Phase 1: Neue Hardware bereitstellen"
    echo "  1. Ubuntu 24.04 LTS auf neuer SSD installieren"
    echo "  2. git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git"
    echo ""
    echo "Phase 2: ZFS importieren"
    echo "  zpool import bootstreep"
    echo "  zpool scrub bootstreep"
    echo ""
    echo "Phase 3: Docker-Netzwerke"
    docker network create frontend 2>/dev/null || true
    docker network create backend 2>/dev/null || true
    echo ""
    echo "Phase 4: Compose neu deployen"
    echo "  cd ~/docker && for d in */; do"
    echo "    (cd \"$d\" && docker compose up -d)"
    echo "  done"
    echo ""
    echo "Recovery-Zeit: ~2h (abhängig von Download-Geschwindigkeit)"
    echo "Letztes Backup: $(find "$RESTORE_ROOT" -maxdepth 1 -type d -name '20*' | sort | tail -1)"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 2: Host kompromittiert
# ════════════════════════════════════════════════════════════
compromised)
    echo "═══ SZENARIO 2: HOST KOMPROMITTIERT ═══"
    echo ""
    echo "Phase 1: Isolation"
    echo "  sudo ufw default deny incoming"
    echo "  sudo ufw deny out to any"
    echo "  sudo ufw --force enable"
    echo "  sudo systemctl stop docker"
    echo "  sudo systemctl stop sshd"
    echo ""
    echo "Phase 2: Snapshots sichern"
    if command -v zfs &>/dev/null; then
        zfs snapshot -r bootstreep@forensic-$(date +%Y%m%d)
        echo "  ZFS Snapshots gesichert für Forensik"
    fi
    echo ""
    echo "Phase 3: Neuinstallation"
    echo "  Server formatieren → Ubuntu 24.04 → Repo klonen"
    echo "  Wichtig: ALLE Passwörter rotieren!"
    echo "  Wichtig: Telegram Bot Token neu generieren!"
    echo "  Wichtig: SSH-Keys neu ausrollen!"
    echo ""
    echo "Phase 4: Restore"
    echo "  neuestes Backup auswählen (VOR Kompromittierung):"
    ls -1t "$RESTORE_ROOT"/20* 2>/dev/null | head -3 || echo "  KEIN BACKUP VORHANDEN"
    echo ""
    echo "Recovery-Zeit: ~4-8h inkl. Forensik"
    echo "Prävention: Wazuh/Security-Onion, Auditd, SELinux"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 3: Ransomware
# ════════════════════════════════════════════════════════════
ransomware)
    echo "═══ SZENARIO 3: RANSOMWARE ═══"
    echo ""
    echo "Phase 1: SOFORTHANDELN"
    echo "  sudo ufw default deny incoming"
    echo "  sudo ufw deny out to any"
    echo "  sudo ufw --force enable"
    echo "  sudo poweroff (physischer Not-Aus)"
    echo ""
    echo "Phase 2: Backup-Integrität prüfen"
    if command -v zfs &>/dev/null; then
        echo "  ZFS Snapshots (unveränderlich durch read-only):"
        zfs list -t snapshot -o name -H 2>/dev/null | tail -10 || echo "  Keine Snapshots"
    fi
    echo ""
    echo "Phase 3: Air-Gapped Backup"
    echo "  Externe Platte anschließen (NUR NACH FORMATIERUNG!)"
    echo "  sudo mount /dev/sdX1 /mnt/restore"
    echo "  cp -a $RESTORE_ROOT /mnt/restore/"
    echo ""
    echo "Phase 4: Restore (nach Neuinstallation)"
    echo "  1. Ubuntu 24.04 installieren"
    echo "  2. ZFS Pool importieren (Snapshots sind sicher!)"
    echo "  3. zfs rollback -r bootstreep@vor-letztem-tag"
    echo "  4. Git Repo klonen"
    echo "  5. Alle Secrets rotieren (GENERATIONELL!)"
    echo ""
    echo "Recovery-Zeit: ~6-12h"
    echo "Prävention: 3-2-1, Air-Gapped Backups, read-only Snapshots"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 4: Defektes Docker Update
# ════════════════════════════════════════════════════════════
docker-fail)
    echo "═══ SZENARIO 4: DEFEKTES DOCKER UPDATE ═══"
    echo ""

    # Letzte funktionierende Version ermitteln
    LAST_WORKING=$(docker ps -q 2>/dev/null | wc -l)
    echo "Aktuell laufende Container: $LAST_WORKING"

    echo ""
    echo "Phase 1: Rollback einzelner Container"
    echo "  docker compose down"
    echo "  # Image-Tag in compose.yml zurücksetzen"
    echo "  docker compose up -d"
    echo ""
    echo "Phase 2: Docker-CE Downgrade"
    echo "  sudo apt-get install docker-ce=5:27.0.0"
    echo ""
    echo "Phase 3: Restore aus Backup"
    echo "  docker run --rm -v vol_name:/target -v $RESTORE_ROOT:/backup"
    echo "    alpine sh -c 'tar xzf /backup/vol_name.tar.gz -C /target'"
    echo ""
    echo "Recovery-Zeit: ~30min"
    echo "Prävention: WATCHTOWER_ROLLING_RESTART=true (bereits gesetzt)"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 5: Stromausfall
# ════════════════════════════════════════════════════════════
power-outage)
    echo "═══ SZENARIO 5: STROMAUSFALL ═══"
    echo ""

    # ZFS-Integrität prüfen
    if command -v zfs &>/dev/null; then
        echo "ZFS Pool Status:"
        zpool status bootstreep 2>/dev/null || echo "  Kein bootstreep Pool"
        echo ""
        echo "Letzter Scrubbing:"
        zpool status bootstreep 2>/dev/null | grep scan || echo "  Nie gescrubbt"
        echo ""
        echo "Phase 1: ZFS scruben"
        echo "  sudo zpool scrub bootstreep"
    fi

    echo ""
    echo "Phase 2: Docker-Volumes prüfen"
    echo "  docker volume ls -q | while read v; do"
    echo "    docker run --rm -v \$v:/source alpine sh -c 'ls /source' >/dev/null || warn \"\$v beschädigt\""
    echo "  done"
    echo ""
    echo "Phase 3: Services starten"
    echo "  cd ~/docker && for d in */; do"
    echo "    (cd \"$d\" && docker compose up -d)"
    echo "  done"
    echo ""
    echo "Recovery-Zeit: ~15min"
    echo "Prävention: USV (Unterbrechungsfreie Stromversorgung)"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 6: Datenbank beschädigt
# ════════════════════════════════════════════════════════════
db-corrupt)
    echo "═══ SZENARIO 6: DATENBANK BESCHÄDIGT ═══"
    echo ""

    # Vaultwarden
    if docker ps --format '{{.Names}}' | grep -q vaultwarden; then
        echo "Vaultwarden SQLite prüfen..."
        docker exec vaultwarden sqlite3 /data/db.sqlite3 "PRAGMA integrity_check;" 2>/dev/null && \
            echo "  ✓ Vaultwarden DB OK" || echo "  ✗ Vaultwarden DB BESCHÄDIGT"
        echo ""
        echo "Restore:"
        echo "  docker compose -f ~/docker/vaultwarden/compose.yml down"
        echo "  docker run --rm -v vaultwarden_data:/target \\
            -v $RESTORE_ROOT/<backup>:/backup \\
            alpine sh -c 'tar xzf /backup/vol_vaultwarden_data.tar.gz -C /target'"
        echo "  docker compose -f ~/docker/vaultwarden/compose.yml up -d"
    fi

    # Nextcloud
    if docker ps --format '{{.Names}}' | grep -q nextcloud-aio-pgsql; then
        echo ""
        echo "Nextcloud PostgreSQL Restore:"
        echo "  gunzip < $RESTORE_ROOT/<backup>/nextcloud.sql.gz | \\
            docker exec -i nextcloud-aio-pgsql psql -U nextcloud"
    fi

    # n8n
    if docker ps --format '{{.Names}}' | grep -q n8n; then
        echo ""
        echo "n8n SQLite Restore:"
        echo "  docker compose -f ~/docker/n8n/compose.yml down"
        echo "  docker cp $RESTORE_ROOT/<backup>/n8n.db n8n:/home/node/.n8n/database.sqlite"
        echo "  docker compose -f ~/docker/n8n/compose.yml up -d"
    fi

    echo ""
    echo "Recovery-Zeit: ~10min pro DB"
    echo "Prävention: backup-all.sh mit DB-Dumps (bereits integriert)"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 7: DNS Ausfall
# ════════════════════════════════════════════════════════════
dns-fail)
    echo "═══ SZENARIO 7: DNS AUSFALL ═══"
    echo ""

    # DNS-Test
    if command -v dig &>/dev/null; then
        echo "Pi-hole Status:"
        dig +short google.com @127.0.0.1 2>/dev/null | head -1 || echo "  ✗ Keine Antwort von Pi-hole"
        echo ""
        echo "Unbound Status:"
        dig +short google.com @127.0.0.1 -p 5335 2>/dev/null | head -1 || echo "  ✗ Keine Antwort von Unbound"
    fi

    echo ""
    echo "Phase 1: Container neustarten"
    echo "  docker restart unbound"
    echo "  sleep 5"
    echo "  docker restart pihole"
    echo ""
    echo "Phase 2: Logs prüfen"
    echo "  docker logs unbound --tail 30"
    echo "  docker logs pihole --tail 30"
    echo ""
    echo "Phase 3: Fallback auf öffentliche DNS"
    echo "  echo 'nameserver 1.1.1.1' | sudo tee /etc/resolv.conf"
    echo "  echo 'nameserver 9.9.9.9' | sudo tee -a /etc/resolv.conf"
    echo ""
    echo "Phase 4: DNSSEC testen"
    echo "  scripts/dnssec-test.sh"
    echo ""
    echo "Recovery-Zeit: ~5min"
    echo "Prävention: Zwei DNS-Upstreams (Cloudflare + Quad9, bereits konfiguriert)"
    ;;

# ════════════════════════════════════════════════════════════
# SZENARIO 8: Internet Ausfall
# ════════════════════════════════════════════════════════════
internet-fail)
    echo "═══ SZENARIO 8: INTERNET AUSFALL ═══"
    echo ""

    echo "Auswirkungen:"
    echo "  - ❸ Alle Cloud-Dienste: nicht erreichbar"
    echo "  - ❸ Sonarr/Radarr: kein Indexer-Zugriff"
    echo "  - ❸ AI Agent: kein Telegram"
    echo "  - ❸ Watchtower: keine Updates"
    echo "  - ❷ DNS: Nur Cache (Pi-hole + Unbound)"
    echo "  - ❷ Syncthing: Kein Sync mit Remote"
    echo "  - ❶ Lokale KI: VOLL funktionsfähig"
    echo "  - ❶ Jellyfin: VOLL funktionsfähig (lokale Medien)"
    echo "  - ❶ Nextcloud: LAN-Sync funktioniert"
    echo "  - ❶ Vaultwarden: VOLL funktionsfähig"
    echo "  - ❶ TeamSpeak: VOLL funktionsfähig (LAN)"
    echo "  - ❶ Heimdall: VOLL funktionsfähig"
    echo ""
    echo "LAN-Betrieb fortsetzen:"
    echo "  Alle lokalen Dienste laufen normal weiter."
    echo "  DNS arbeitet aus dem Cache."
    echo ""
    echo "Wiederherstellung:"
    echo "  Sobald Internet zurück:"
    echo "  - Pi-hole und Unbound syncen sich automatisch"
    echo "  - Syncthing sync automatisch"
    echo "  - n8n verarbeitet aufgelaufene Workflows"
    echo ""
    echo "Recovery: Autonom (kein Eingriff nötig)"
    echo "Prävention: Lokale Services only (bereits gegeben)"
    ;;

# ════════════════════════════════════════════════════════════
# HILFE
# ════════════════════════════════════════════════════════════
help|*)
    echo "Bootstreep Disaster Recovery v4.0"
    echo ""
    echo "Usage: $0 <szenario>"
    echo ""
    echo "Szenarien:"
    echo "  ssd-failure      SSD Totalausfall"
    echo "  compromised      Host kompromittiert"
    echo "  ransomware       Ransomware-Angriff"
    echo "  docker-fail      Defektes Docker Update"
    echo "  power-outage     Stromausfall"
    echo "  db-corrupt       Datenbank beschädigt"
    echo "  dns-fail         DNS Ausfall"
    echo "  internet-fail    Internet Ausfall"
    echo ""
    echo "Beispiel: $0 ssd-failure"
    ;;
esac