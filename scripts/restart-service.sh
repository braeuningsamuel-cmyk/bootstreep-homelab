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
docker compose -f ~/docker/"$NAME"/compose.yml restart 2>/dev/null || \
    docker restart "$NAME" 2>/dev/null || \
    echo "Container $NAME nicht gefunden"
docker ps --filter "name=$NAME" --format "{{.Names}} {{.Status}}"
