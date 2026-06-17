#!/bin/bash
#
# bootstrap.sh: Manual provisioning script for an existing Ubuntu server.
#
# This script installs Ansible, clones the homelab-base repository,
# and runs ansible-pull to apply the configuration.

set -e

REPO_URL="https://github.com/andresvidoza/homelab-base.git"
REPO_DIR="/opt/homelab-base"

# Update package cache and install dependencies
sudo apt-get update
sudo apt-get install -y git curl ansible

# Clone or update the repository
if [ -d "$REPO_DIR" ]; then
  echo "Updating existing repository..."
  cd "$REPO_DIR"
  sudo git pull
else
  echo "Cloning repository..."
  sudo git clone "$REPO_URL" "$REPO_DIR"
fi

# Run ansible-pull
cd "$REPO_DIR"
ansible-pull -U "$REPO_URL" -d "$REPO_DIR" ansible/site.yml

echo "Bootstrap complete."
