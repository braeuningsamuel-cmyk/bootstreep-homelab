#!/bin/bash
# Cron-Jobs einrichten
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

crontab -l > "$HOME/.crontab.bak" 2>/dev/null || true

echo "Aktuelle Crontab:"
crontab -l 2>/dev/null || echo "(leer)"
echo ""

crontab -l 2>/dev/null > /tmp/cron.current
grep -q "update-all.sh" /tmp/cron.current 2>/dev/null || echo "0 3 * * 0 $SCRIPT_DIR/update-all.sh >/dev/null 2>&1" >> /tmp/cron.current
grep -q "backup-all.sh" /tmp/cron.current 2>/dev/null || echo "0 4 * * 0 $SCRIPT_DIR/backup-all.sh >/dev/null 2>&1" >> /tmp/cron.current
grep -q "health-check.sh" /tmp/cron.current 2>/dev/null || echo "*/30 * * * * $SCRIPT_DIR/health-check.sh >/dev/null 2>&1" >> /tmp/cron.current
grep -q "docker-cleanup.sh" /tmp/cron.current 2>/dev/null || echo "0 5 * * 0 $SCRIPT_DIR/docker-cleanup.sh >/dev/null 2>&1" >> /tmp/cron.current
grep -q "sanitize-logs.sh" /tmp/cron.current 2>/dev/null || echo "0 2 * * 6 $SCRIPT_DIR/sanitize-logs.sh >/dev/null 2>&1" >> /tmp/cron.current
crontab /tmp/cron.current
rm -f /tmp/cron.current

echo "Neue Crontab:"
crontab -l
echo ""
echo "✓ Cron-Jobs eingerichtet:"
echo "  - Update:     So 3:00"
echo "  - Backup:     So 4:00"
echo "  - Healthcheck: alle 30 Min"
echo "  - Docker Cleanup: So 5:00"
echo "  - Log-Anonymisierung: Sa 2:00"
