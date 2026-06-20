#!/bin/bash
################################################################################
# Phase 11: Final report generation
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORT="${BOOTSTRAP_DIR}/system-report.md"

info "Phase 11: Generating final report"

{
    echo "# Bootstreep Homelab - System Report"
    echo ""
    echo "Generated: $(date)"
    echo ""
    echo "## Host Information"
    echo "| Field | Value |"
    echo "|-------|-------|"
    echo "| Hostname | $(hostname) |"
    echo "| IP Address | $(hostname -I | awk '{print $1}') |"
    echo "| OS | $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2) |"
    echo "| Kernel | $(uname -r) |"
    echo "| Uptime | $(uptime -p) |"
    echo ""
    echo "## Hardware"
    echo "- **CPU**: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "- **Cores**: $(nproc)"
    echo "- **RAM**: $(free -h | awk '/Mem:/ {print $2}')"
    echo "- **Root Disk**: $(df -h / | awk 'NR==2 {print $2" used:"$3" free:"$4}')"
    echo ""
    echo "## Security"
    echo "| Component | Status |"
    echo "|-----------|--------|"
    echo "| UFW | $(ufw status | head -1) |"
    echo "| Fail2Ban | $(systemctl is-active fail2ban) |"
    echo "| AppArmor | $(aa-status --enabled 2>/dev/null && echo active || echo inactive) |"
    echo ""
    echo "## Docker Containers"
    echo '```'
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker not installed"
    echo '```'
    echo ""
    echo "## Listening Ports"
    echo '```'
    ss -tlnp 2>/dev/null | head -20
    echo '```'
    echo ""
    echo "## Installed Packages (custom)"
    echo "- Docker CE: $(docker --version 2>/dev/null || echo N/A)"
    echo "- Tailscale: $(tailscale version 2>/dev/null | head -1 || echo N/A)"
    echo ""
    echo "## Next Steps"
    echo "1. Configure DNS in Cloudflare"
    echo "2. Run Traefik dashboard to verify"
    echo "3. Configure Authentik admin user"
    echo "4. Set up Grafana dashboards"
    echo "5. Configure backup targets in Restic"
} > "${REPORT}"

ok "Report: ${REPORT}"
cat "${REPORT}" | head -50