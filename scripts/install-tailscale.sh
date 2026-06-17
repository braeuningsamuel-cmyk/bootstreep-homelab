#!/bin/bash
#
# install-tailscale.sh: Installs Tailscale.
#

set -e

curl -fsSL https://tailscale.com/install.sh | sh

echo "Tailscale installation complete."
