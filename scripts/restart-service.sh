#!/bin/bash
# Einzelne Services neustarten
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<EOF
Usage: $0 <container> [container...]

Container:
$(all_containers | tr ' ' '\n' | sed 's/^/  /')
EOF
    exit 1
}

[ $# -eq 0 ] && usage

for container in "$@"; do
    echo ""
    info "Neustart: $container"
    dc_for_container restart "$container" || { err "Restart fehlgeschlagen: $container"; continue; }
    info "Warte auf Health (max 30s)..."
    for _ in $(seq 1 30); do
        container_running "$container" && { log "$container läuft"; break; }
        sleep 1
    done
    container_running "$container" || err "$container läuft nach 30s nicht!"
done

echo ""
log "Fertig"
