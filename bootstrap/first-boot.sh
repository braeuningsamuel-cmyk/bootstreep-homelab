#!/bin/bash
#
# first-boot.sh: Script executed by cloud-init on first boot.
#
# This script runs ansible-pull to apply the main site playbook.

set -e

REPO_URL="https://github.com/your-user/homelab-base.git"
REPO_DIR="/opt/homelab-base"

# Run ansible-pull
ansible-pull -U "$REPO_URL" -d "$REPO_DIR" ansible/site.yml

echo "First boot provisioning complete."
