#!/bin/bash
# Bootstreep Homelab – Logs anzeigen
# Usage: ./logs.sh <container-name> [-f]
set -euo pipefail

if [ $# -eq 0 ]; then
    echo "Usage: $0 <container-name> [-f]"
    echo "Beispiele: pihole, unbound, jellyfin, ollama"
    echo "  -f  = folgen (wie tail -f)"
    exit 1
fi

FOLLOW=""
NAME="$1"
shift
if [ "${1:-}" = "-f" ]; then
    FOLLOW="-f"
fi

docker logs $FOLLOW "$NAME" 2>&1 || echo "Container $NAME nicht gefunden"
