#!/bin/bash
################################################################################
# Phase 4: User management
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${BOOTSTRAP_DIR}/config"

# Load user config
if [[ -f "${CONFIG_DIR}/users.env" ]]; then
    # shellcheck disable=SC1091
    source "${CONFIG_DIR}/users.env"
fi

ADMIN_USER="${ADMIN_USER:-admin}"
DOCKER_USER="${DOCKER_USER:-docker}"
SERVICE_USER="${SERVICE_USER:-service}"

info "Phase 4: User management"

create_user() {
    local user="$1"
    if id "${user}" &>/dev/null; then
        ok "User ${user} exists"
        return 0
    fi
    adduser --disabled-password --gecos "" "${user}"
    passwd -l "${user}"
    ok "Created user ${user}"
}

create_user "${ADMIN_USER}"
create_user "${DOCKER_USER}"
create_user "${SERVICE_USER}"

# Groups
usermod -aG sudo,docker "${ADMIN_USER}"
usermod -aG docker "${SERVICE_USER}"

# SSH keys for admin
ADMIN_HOME="/home/${ADMIN_USER}"
mkdir -p "${ADMIN_HOME}/.ssh"
chmod 700 "${ADMIN_HOME}/.ssh"
if [[ ! -f "${ADMIN_HOME}/.ssh/authorized_keys" ]]; then
    touch "${ADMIN_HOME}/.ssh/authorized_keys"
fi
chmod 600 "${ADMIN_HOME}/.ssh/authorized_keys"
chown -R "${ADMIN_USER}:${ADMIN_USER}" "${ADMIN_HOME}/.ssh"

# Sudo without password for admin
echo "${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${ADMIN_USER}"
chmod 0440 "/etc/sudoers.d/${ADMIN_USER}"

ok "User management complete"