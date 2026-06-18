#!/bin/bash
# Health-Check aller Homelab-Services
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib.sh"

echo "============================================"
echo "  Bootstreep Health-Check – $(date '+%Y-%m-%d %H:%M')"
echo "============================================"
echo ""

echo "── System ──"
printf "  Uptime:  %s\n" "$(uptime -p)"
printf "  Load:    %s\n" "$(awk '{print $1, $2, $3}' /proc/loadavg)"
printf "  RAM:     %s / %s\n" \
    "$(free -h | awk '/^Mem:/ {print $3}')" \
    "$(free -h | awk '/^Mem:/ {print $2}')"
printf "  Disk /:  %s used (%s free)\n" \
    "$(df -h / | awk 'NR==2 {print $5}')" \
    "$(df -h / | awk 'NR==2 {print $4}')"
printf "  IP:      %s\n" "$(hostname -I 2>/dev/null | awk '{print $1}')"
printf "  BBR:     %s\n" "$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')"
echo ""

echo "── Docker ──"
if ! docker info &>/dev/null; then
    err "Docker-Daemon läuft NICHT"
    exit 1
fi
log "Docker-Daemon läuft"
echo ""

echo "── Container ──"
ok=0 fail=0 expected=0
for c in $(all_containers); do
    expected=$((expected + 1))
    if container_running "$c"; then
        printf "  ${GREEN}✓${NC} %-20s running\n" "$c"
        ok=$((ok + 1))
    else
        printf "  ${RED}✗${NC} %-20s NOT running\n" "$c"
        fail=$((fail + 1))
    fi
done
printf "\nSummary: %d/%d OK\n" "$ok" "$expected"
echo ""

echo "── DNS ──"
if command -v dig &>/dev/null; then
    if dig +short google.com @127.0.0.1 2>/dev/null | grep -q .; then
        log "DNS funktioniert"
    else
        err "DNS funktioniert NICHT"
        fail=$((fail + 1))
    fi
    if ! dig sigfail.verteiltesysteme.net @127.0.0.1 +short 2>/dev/null | grep -q .; then
        log "DNSSEC sigfail blockiert"
    fi
fi
echo ""

echo "── Fail2Ban ──"
if sudo fail2ban-client status sshd 2>/dev/null | grep -q "Status for the jail"; then
    local_banned=$(sudo fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $NF}')
    printf "  SSH-Jail aktiv (%s Bans)\n" "${local_banned:-0}"
fi
echo ""

echo "── Backups ──"
if [ -d "$HOME/backups" ]; then
    latest=$(find "$HOME/backups" -maxdepth 1 -type d -name "20*" | sort -r | head -1)
    if [ -n "$latest" ]; then
        printf "  Letztes: %s\n" "$(basename "$latest")"
    else
        warn "Keine Backups"
    fi
fi
echo ""

echo "── TCP Stack ──"
printf "  CC: %s | FastOpen: %s\n" \
    "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" \
    "$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null)"
echo ""

echo "============================================"
[ "$fail" -eq 0 ] && log "ALLES OK" || warn "$fail Probleme"
exit "$fail"
