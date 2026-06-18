#!/bin/bash
#
# install-ollama.sh: Installs Ollama.
#

set -euo pipefail

SHA256_EXPECTED="${OLLAMA_INSTALL_SHA256:-}"
if [ -n "$SHA256_EXPECTED" ]; then
    curl -fsSL https://ollama.com/install.sh -o /tmp/ollama-install.sh
    echo "$SHA256_EXPECTED  /tmp/ollama-install.sh" | sha256sum -c || { rm -f /tmp/ollama-install.sh; exit 1; }
    sh /tmp/ollama-install.sh
    rm -f /tmp/ollama-install.sh
else
    curl -fsSL https://ollama.com/install.sh | sh
fi

echo "Ollama installation complete."
