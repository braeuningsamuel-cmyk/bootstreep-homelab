#!/bin/bash
# Atlas.Lab Homelab – DNSSEC-Test
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║  Atlas.Lab Homelab – DNSSEC-Validierung          ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

DNS_SERVER="${1:-127.0.0.1}"

echo "Test 1: DNSSEC-sigfail (sollte KEINE Antwort liefern – DNSSEC blockiert)"
sigfail=$(dig sigfail.verteiltesysteme.net @"$DNS_SERVER" +short 2>/dev/null || true)
if [ -z "$sigfail" ]; then
    log "sigfail: Keine Antwort (DNSSEC blockiert korrekt)"
else
    warn "sigfail: $sigfail (ungefiltert)"
fi

echo ""
echo "Test 2: DNSSEC-sigok (sollte 134.91.78.139 liefern)"
sigok=$(dig sigok.verteiltesysteme.net @"$DNS_SERVER" +short 2>/dev/null || true)
if echo "$sigok" | grep -q "134.91.78.139"; then
    log "sigok: $sigok (DNSSEC-Validierung funktioniert)"
else
    err "sigok: $sigok (Validierung fehlgeschlagen)"
fi

echo ""
echo "Test 3: Google-DNS-Auflösung"
google=$(dig google.de @"$DNS_SERVER" +short 2>/dev/null | head -1 || true)
if [ -n "$google" ]; then
    log "google.de → $google"
else
    err "google.de nicht auflösbar"
fi

echo ""
echo "Test 4: DNSSEC-Status (Pi-hole)"
docker exec pihole pihole -c 2>/dev/null | head -15 || warn "Pi-hole nicht erreichbar"
