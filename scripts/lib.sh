#!/bin/bash
# Gemeinsame Funktionen für alle scripts/
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()  { printf '%b[✓]%b %s\n' "$GREEN" "$NC" "$1"; }
warn() { printf '%b[!]%b %s\n' "$YELLOW" "$NC" "$1"; }
info() { printf '%b[i]%b %s\n' "$CYAN" "$NC" "$1"; }
err()  { printf '%b[✗]%b %s\n' "$RED" "$NC" "$1"; }
die()  { err "$1"; exit 1; }

container_to_dir() {
    case "$1" in
        pihole|unbound) echo "dns" ;;
        tor) echo "tor" ;;
        websurfx) echo "websurfx" ;;
        ollama) echo "ollama" ;;
        open-webui) echo "open-webui" ;;
        hermes) echo "hermes" ;;
        jellyfin) echo "jellyfin" ;;
        sabnzbd) echo "sabnzbd" ;;
        sonarr) echo "sonarr" ;;
        radarr) echo "radarr" ;;
        prowlarr) echo "prowlarr" ;;
        bazarr) echo "bazarr" ;;
        n8n) echo "n8n" ;;
        syncthing) echo "syncthing" ;;
        nextcloud-aio) echo "nextcloud" ;;
        uptime-kuma) echo "uptime-kuma" ;;
        heimdall) echo "heimdall" ;;
        teamspeak) echo "teamspeak" ;;
        amp) echo "amp" ;;
        caddy) echo "caddy" ;;
        watchtower) echo "watchtower" ;;
        vaultwarden) echo "vaultwarden" ;;
        minecraft) echo "amp-instances" ;;
        valheim) echo "amp-instances" ;;
        *) echo "" ;;
    esac
}

container_running() {
    docker inspect --format='{{.State.Status}}' "$1" 2>/dev/null | grep -q running
}

all_containers() {
    echo "pihole unbound tor websurfx ollama hermes open-webui jellyfin sabnzbd \
        sonarr radarr prowlarr bazarr n8n syncthing nextcloud-aio uptime-kuma \
        heimdall teamspeak amp caddy watchtower vaultwarden"
}

dc_for_container() {
    local action="$1" container="$2"
    shift 2
    local dir
    dir="$(container_to_dir "$container")"
    [ -z "$dir" ] && die "Unbekannter Container: $container"
    local compose_dir="$HOME/docker/$dir"
    [ ! -d "$compose_dir" ] && die "Compose-Pfad fehlt: $compose_dir"
    case "$action" in
        up)       (cd "$compose_dir" && docker compose up -d) ;;
        down)     (cd "$compose_dir" && docker compose down) ;;
        restart)  (cd "$compose_dir" && docker compose restart) ;;
        pull)     (cd "$compose_dir" && docker compose pull) ;;
        logs)     (cd "$compose_dir" && docker compose logs "$@") ;;
        *) die "Unbekannte Aktion: $action" ;;
    esac
}
