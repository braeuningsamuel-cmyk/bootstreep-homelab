#!/bin/bash
################################################################################
# Phase 1: System preparation and inventory
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${BOOTSTRAP_DIR}/bootstrap.sh" --silent 2>/dev/null || true

info "Phase 1: System check"

# Check Ubuntu
require_ubuntu

# Network check
if ! ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
    err "No network"; exit 1
fi
ok "Network OK"

# DNS check
if ! getent hosts github.com &>/dev/null; then
    err "DNS broken"; exit 1
fi
ok "DNS OK"

# Inventory
mkdir -p "${BOOTSTRAP_DIR}/logs"
INVENTORY="${BOOTSTRAP_DIR}/logs/inventory.txt"
{
    echo "=== Bootstreep System Inventory ==="
    echo "Date: $(date)"
    echo "Hostname: $(hostname)"
    echo "Kernel: $(uname -a)"
    echo "OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo "CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
    echo "Cores: $(nproc)"
    echo "RAM: $(free -h | awk '/Mem:/ {print $2}')"
    echo "Disks:"
    lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE
    echo "Network Interfaces:"
    ip -br addr
    echo "Free Space (/): $(df -h / | awk 'NR==2 {print $4}')"
} > "${INVENTORY}"
ok "Inventory saved to ${INVENTORY}"