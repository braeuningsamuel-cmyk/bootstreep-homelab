#!/bin/bash
################################################################################
# Phase 6: Storage setup (ZFS or ext4)
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${BOOTSTRAP_DIR}/config"

if [[ -f "${CONFIG_DIR}/storage.env" ]]; then
    # shellcheck disable=SC1091
    source "${CONFIG_DIR}/storage.env"
fi

STORAGE_ROOT="${STORAGE_ROOT:-/opt/docker}"
USE_ZFS="${USE_ZFS:-false}"

info "Phase 6: Storage layout at ${STORAGE_ROOT}"

mkdir -p "${STORAGE_ROOT}"/{compose,stacks,data,configs,backups,logs,monitoring,media,downloads,database}
chown -R root:docker "${STORAGE_ROOT}"
chmod -R 755 "${STORAGE_ROOT}"

if [[ "${USE_ZFS}" == "true" ]] && command -v zpool &>/dev/null; then
    ok "ZFS already available"
fi

ok "Storage layout created"