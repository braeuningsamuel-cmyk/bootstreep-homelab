#!/bin/bash
# Cron-Jobs einrichten
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

crontab -l > "$HOME/.crontab.bak" 2>/dev/null || true

echo "Aktuelle Crontab:"
crontab -l 2>/dev/null || echo "(leer)"
echo ""

(crontab -l 2>/dev/null; \
 echo "0 3 * * 0 $SCRIPT_DIR/update-all.sh >/dev/null 2>&1"; \
 echo "0 4 * * 0 $SCRIPT_DIR/backup-all.sh >/dev/null 2>&1"; \
 echo "*/30 * * * * $SCRIPT_DIR/health-check.sh >/dev/null 2>&1"; \
 echo "0 5 * * 0 $HOME_DIR/scripts/docker-cleanup.sh >/dev/null 2>&1"; \
 echo "0 2 * * 6 $HOME_DIR/scripts/sanitize-logs.sh >/dev/null 2>&1") | crontab -

echo "Neue Crontab:"
crontab -l
echo ""
echo "✓ Cron-Jobs eingerichtet:"
echo "  - Update:     So 3:00"
echo "  - Backup:     So 4:00"
echo "  - Healthcheck: alle 30 Min"
echo "  - Docker Cleanup: So 5:00"
echo "  - Log-Anonymisierung: Sa 2:00"
