#!/bin/bash
# Log-Anonymisierung (IPs aus Logs entfernen – Privacy)
set -euo pipefail

LOG_DIRS="/var/log $HOME/bootstrap.log $HOME/ai-agent"
COUNT=0

for target in $LOG_DIRS; do
    if [ -f "$target" ]; then
        sudo sed -i -E 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/x.x.x.x/g' "$target" 2>/dev/null || true
        COUNT=$((COUNT + 1))
    elif [ -d "$target" ]; then
        while IFS= read -r -d '' f; do
            sudo sed -i -E 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/x.x.x.x/g' "$f" 2>/dev/null || true
            COUNT=$((COUNT + 1))
        done < <(find "$target" \( -name "*.log" -o -name "*.txt" \) -print0 2>/dev/null)
    fi
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Log-Anonymisierung: $COUNT Dateien verarbeitet"
