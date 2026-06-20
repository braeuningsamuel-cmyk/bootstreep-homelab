#!/usr/bin/env bash
################################################################################
# Rollback script - Restores homelab from backup
# Usage: sudo ./rollback.sh [snapshot-id]
#        sudo ./rollback.sh --list
################################################################################

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG="/var/log/bootstreep-rollback-$(date +%Y%m%d-%H%M%S).log"

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log() {
    local level="$1"
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "$LOG"
}

info() { echo -e "${GREEN}[INFO]${NC} $*"; log "INFO" "$*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; log "WARN" "$*" >&2; }
err()  { echo -e "${RED}[FAIL]${NC} $*"; log "ERROR" "$*" >&2; }

require_root() {
    [[ $EUID -eq 0 ]] || { err "Must be run as root"; exit 1; }
}

list_snapshots() {
    info "Available Restic snapshots:"
    if [[ -n "${RESTIC_REPOSITORY:-}" ]]; then
        restic -r "${RESTIC_REPOSITORY}" snapshots
    else
        warn "RESTIC_REPOSITORY not set. Listing local backups:"
        ls -la /opt/docker/backups/
    fi
}

restore_snapshot() {
    local snapshot="${1:-latest}"

    info "Rolling back to snapshot: $snapshot"
    echo ""
    warn "⚠️  This will:"
    echo "  1. Stop all running Docker containers"
    echo "  2. Restore /opt/docker/data from backup"
    echo "  3. Restore /opt/docker/configs from backup"
    echo "  4. Restart Docker services"
    echo ""
    read -rp "Are you sure? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
        info "Rollback cancelled"
        exit 0
    fi

    # 1. Stop all services
    info "Stopping all Docker services..."
    for compose_file in "${SCRIPT_DIR}/../compose"/*/docker-compose.yml; do
        if [[ -f "$compose_file" ]]; then
            (cd "$(dirname "$compose_file")" && docker compose down) || warn "Failed to stop: $compose_file"
        fi
    done

    # 2. Restore from Restic
    if [[ -n "${RESTIC_REPOSITORY:-}" ]]; then
        info "Restoring from Restic snapshot: $snapshot"
        restic -r "${RESTIC_REPOSITORY}" restore "$snapshot" \
            --target / \
            --include /opt/docker/data \
            --include /opt/docker/configs
    else
        # Local backup fallback
        local backup_file="/opt/docker/backups/docker-volumes-${snapshot}.tar.gz"
        if [[ -f "$backup_file" ]]; then
            info "Restoring from local backup: $backup_file"
            tar xzf "$backup_file" -C /
        else
            err "No backup found for snapshot: $snapshot"
            exit 1
        fi
    fi

    # 3. Restart services
    info "Starting Docker services..."
    for compose_file in "${SCRIPT_DIR}/../compose"/*/docker-compose.yml; do
        if [[ -f "$compose_file" ]]; then
            (cd "$(dirname "$compose_file")" && docker compose up -d) || warn "Failed to start: $compose_file"
        fi
    done

    info "✅ Rollback complete!"
    info "Log: $LOG"
}

usage() {
    cat <<EOF
Bootstreep Homelab Rollback Tool

Usage:
  $0 [snapshot-id]   Restore from specific snapshot (default: latest)
  $0 --list          List available snapshots
  $0 --help          Show this help

Examples:
  $0 --list                                # Show all snapshots
  $0 latest                                # Restore from latest
  $0 7e188ff                               # Restore specific snapshot

Environment variables (required for Restic):
  RESTIC_REPOSITORY    Path to Restic repository (s3:, b2:, /path/)
  RESTIC_PASSWORD      Restic encryption password

Log file: $LOG
EOF
}

main() {
    require_root

    case "${1:-}" in
        --list|-l)     list_snapshots ;;
        --help|-h)     usage ;;
        "")            usage; exit 1 ;;
        *)             restore_snapshot "$1" ;;
    esac
}

main "$@"