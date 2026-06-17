#!/bin/bash
#
# install-casaos.sh: Installs CasaOS.
#

set -e

curl -fsSL https://get.casaos.io | sudo bash

echo "CasaOS installation complete."
