#!/bin/bash
# Bootstreep Homelab – Service neustarten
# Usage: ./restart-service.sh <container-name>
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <container-name>"
    echo "Beispiele: pihole, unbound, jellyfin, ollama, nextcloud-aio"
    exit 1
fi

NAME="$1"
echo "Starte $NAME neu..."
# Name-Mapping: nextcloud-aio → nextcloud (Ordnername)
DIR_NAME="$NAME"
[ "$NAME" = "nextcloud-aio" ] && DIR_NAME="nextcloud"
if docker compose -f ~/docker/"$DIR_NAME"/compose.yml restart 2>/dev/null; then
    docker ps --filter "name=$NAME" --format "{{.Names}} {{.Status}}"
    exit 0
elif docker restart "$NAME" 2>/dev/null; then
    docker ps --filter "name=$NAME" --format "{{.Names}} {{.Status}}"
    exit 0
else
    echo "Container $NAME nicht gefunden"
    exit 1
fi
