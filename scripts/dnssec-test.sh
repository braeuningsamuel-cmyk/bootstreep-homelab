#!/bin/bash
# DNSSEC-Validierung testen
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

DNS="${1:-127.0.0.1}"

echo "============================================"
echo "  DNSSEC-Test (Server: $DNS)"
echo "============================================"

if ! command -v dig &>/dev/null; then
    echo "dig fehlt: sudo apt install dnsutils"
    exit 1
fi

echo ""
echo "── Test 1: sigfail (sollte blockiert sein) ──"
result=$(dig +short sigfail.verteiltesysteme.net @"$DNS" 2>/dev/null)
[ -z "$result" ] && printf "${GREEN}✓${NC} Blockiert\n" || printf "${RED}✗${NC} Antwort: %s\n" "$result"

echo ""
echo "── Test 2: sigok (sollte 134.91.78.139) ──"
result=$(dig +short sigok.verteiltesysteme.net @"$DNS" 2>/dev/null)
echo "$result" | grep -q "134.91.78.139" && printf "${GREEN}✓${NC} OK\n" || printf "${RED}✗${NC} %s\n" "$result"

echo ""
echo "── Test 3: google.com ──"
result=$(dig +short google.com @"$DNS" 2>/dev/null | head -1)
[ -n "$result" ] && printf "${GREEN}✓${NC} %s\n" "$result" || printf "${RED}✗${NC}\n"

echo ""
echo "── Test 4: ads.doubleclick.net (Werbung blockiert?) ──"
result=$(dig +short ads.doubleclick.net @"$DNS" 2>/dev/null)
[ -z "$result" ] && printf "${GREEN}✓${NC} Blockiert\n" || printf "${YELLOW}!${NC} Antwort: %s\n" "$result"

echo ""
echo "============================================"
echo "Fertig"
