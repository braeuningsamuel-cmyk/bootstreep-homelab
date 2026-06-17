#!/bin/bash
# Container-Logs anzeigen
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

usage() {
    cat <<EOF
Usage: $0 <container> [docker-logs-flags...]

Beispiele:
  $0 pihole
  $0 jellyfin --tail 50
  $0 ollama -f
EOF
    exit 1
}

[ $# -eq 0 ] && usage

container="$1"
shift

dc_for_container logs "$container" "$@"
