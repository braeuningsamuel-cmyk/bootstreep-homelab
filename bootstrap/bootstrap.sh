#!/bin/bash
################################################################################
# Bootstrap Master Script for Bootstreep Homelab
# Target: Ubuntu Server 24.04 LTS
# Author: BraeuningsSamuel-Cmyk
# License: MIT
################################################################################

set -Eeuo pipefail
IFS=$'\n\t'

# Globals
readonly SCRIPT_NAME="bootstreep-bootstrap"
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly LOGS_DIR="${SCRIPT_DIR}/logs"
readonly LOG_FILE="${LOGS_DIR}/bootstrap-$(date +%Y%m%d-%H%M%S).log"
readonly SYSTEM_REPORT="${SCRIPT_DIR}/system-report.md"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Flags
DRY_RUN=false
DEBUG=false
SILENT=false
BACKUP_MODE=false
SKIP_PHASES=()

mkdir -p "${LOGS_DIR}"

################################################################################
# Logging
################################################################################
log() {
    local level="$1"
    shift
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    [[ "${SILENT}" == "true" ]] && return 0
    case "${level}" in
        INFO)  echo -e "${BLUE}[INFO]${NC} ${msg}" ;;
        OK)    echo -e "${GREEN}[ OK]${NC} ${msg}" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} ${msg}" ;;
        ERROR) echo -e "${RED}[FAIL]${NC} ${msg}" ;;
    esac
    echo "[${ts}] [${level}] ${msg}" >> "${LOG_FILE}"
}

info() { log INFO "$@"; }
ok()   { log OK "$@"; }
warn() { log WARN "$@"; }
err()  { log ERROR "$@" >&2; }

################################################################################
# Helpers
################################################################################
require_root() {
    [[ $EUID -eq 0 ]] || { err "Must be run as root"; exit 1; }
}

require_ubuntu() {
    if ! grep -qi 'ubuntu' /etc/os-release; then
        err "Not Ubuntu"; exit 1
    fi
    local ver
    ver=$(grep VERSION_ID /etc/os-release | cut -d'"' -f2)
    info "Detected Ubuntu ${ver}"
}

run() {
    if [[ "${DRY_RUN}" == "true" ]]; then
        info "[DRY-RUN] $*"
    else
        "$@"
    fi
}

################################################################################
# Argument parsing
################################################################################
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)   DRY_RUN=true ;;
            --debug)     DEBUG=true; set -x ;;
            --silent)    SILENT=true ;;
            --backup)    BACKUP_MODE=true ;;
            --skip)      shift; SKIP_PHASES+=("$1") ;;
            --version)   echo "${SCRIPT_NAME} v${SCRIPT_VERSION}"; exit 0 ;;
            --help)      usage ;;
            *)           err "Unknown option: $1"; usage ;;
        esac
        shift
    done
}

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Options:
  --dry-run      Show what would happen
  --debug        Verbose tracing
  --silent       Minimal output
  --backup       Full backup before changes
  --skip NUM     Skip a phase (e.g. --skip 11)
  --version      Show version
  --help         Show this help
EOF
    exit 1
}

################################################################################
# Phase execution
################################################################################
should_skip() {
    local phase="$1"
    for s in "${SKIP_PHASES[@]:-}"; do
        [[ "$s" == "$phase" ]] && return 0
    done
    return 1
}

run_phase() {
    local phase="$1"
    local script="${SCRIPT_DIR}/scripts/${phase}-*.sh"
    if should_skip "${phase}"; then
        info "Skipping phase ${phase}"
        return 0
    fi
    if [[ -f ${script} ]]; then
        info "==> Running phase ${phase}"
        bash "${script}"
        ok "Phase ${phase} complete"
    else
        warn "Phase ${phase} script not found, skipping"
    fi
}

################################################################################
# Final report
################################################################################
generate_report() {
    info "Generating system-report.md"
    {
        echo "# Bootstreep System Report"
        echo ""
        echo "Generated: $(date)"
        echo ""
        echo "## Host"
        echo "- Hostname: $(hostname)"
        echo "- IP: $(hostname -I | awk '{print $1}')"
        echo "- OS: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
        echo ""
        echo "## Resources"
        echo "- CPU: $(lscpu | grep 'Model name' | cut -d: -f2 | xargs)"
        echo "- RAM: $(free -h | awk '/Mem:/ {print $2}')"
        echo "- Disk: $(df -h / | awk 'NR==2 {print $2}')"
        echo ""
        echo "## Docker"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Docker not installed"
        echo ""
        echo "## Firewall"
        ufw status 2>/dev/null || echo "UFW not installed"
        echo ""
        echo "## Listening Ports"
        ss -tlnp 2>/dev/null || netstat -tlnp 2>/dev/null || echo "No tools available"
    } > "${SYSTEM_REPORT}"
    ok "Report at ${SYSTEM_REPORT}"
}

################################################################################
# Main
################################################################################
main() {
    parse_args "$@"
    require_root
    require_ubuntu

    info "Bootstreep Homelab Bootstrap v${SCRIPT_VERSION}"
    info "Logs: ${LOG_FILE}"

    if [[ "${BACKUP_MODE}" == "true" ]]; then
        bash "${SCRIPT_DIR}/scripts/09-backups.sh"
    fi

    for phase in 01-system 02-packages 03-users 04-security 05-storage \
                 06-docker 07-network 08-monitoring 09-backups \
                 10-services 11-finish; do
        run_phase "${phase}"
    done

    generate_report
    ok "Bootstrap complete!"
}

main "$@"