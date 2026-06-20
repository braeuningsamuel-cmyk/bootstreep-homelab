#!/bin/bash
################################################################################
# Phase 3: Base packages installation
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

PACKAGES=(
    curl wget git jq nano vim
    btop htop ncdu tree rsync
    unzip zip ca-certificates gnupg
    lsb-release software-properties-common
    apt-transport-https
)

info "Installing base packages"
apt-get install -y "${PACKAGES[@]}"
ok "Base packages installed"