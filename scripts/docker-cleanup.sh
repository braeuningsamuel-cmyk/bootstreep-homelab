#!/bin/bash
# Docker Cleanup (wöchentlich via Cron)
set -euo pipefail

echo "=== Docker Cleanup: $(date) ==="
echo ""
echo "── Aktuelle Nutzung ──"
docker system df

echo ""
echo "── Image Cleanup (168h) ──"
docker image prune -af --filter "until=168h" 2>/dev/null || true
echo ""

echo "── Builder Cache Cleanup ──"
docker builder prune -af 2>/dev/null || true
echo ""

echo "── Network Cleanup ──"
docker network prune -f 2>/dev/null || true
echo ""

echo "── Nach Cleanup ──"
docker system df
echo ""
echo "✓ Docker Cleanup abgeschlossen"
