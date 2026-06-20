#!/bin/bash
################################################################################
# Phase 7: Docker CE Installation (official repository)
################################################################################
set -Eeuo pipefail

info "Phase 7: Docker installation"

if command -v docker &>/dev/null; then
    ok "Docker already installed: $(docker --version)"
    exit 0
fi

apt-get install -y ca-certificates curl gnupg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker daemon config
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "features": {
    "buildkit": true
  },
  "default-runtime": "runc"
}
EOF

systemctl enable docker
systemctl restart docker
docker run --rm hello-world
ok "Docker installed: $(docker --version)"