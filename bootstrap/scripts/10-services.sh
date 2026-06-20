#!/bin/bash
################################################################################
# Phase 10: Deploy Docker Compose stacks (Traefik, Portainer, Authentik, etc.)
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_ROOT="${COMPOSE_ROOT:-/opt/docker/stacks}"

info "Phase 10: Deploy Docker stacks"

deploy_stack() {
    local name="$1"
    local path="${BOOTSTRAP_DIR}/compose/${name}"
    if [[ -d "${path}" ]]; then
        info "Deploying stack: ${name}"
        (cd "${path}" && docker compose up -d) || warn "Stack ${name} failed"
    fi
}

deploy_stack "traefik"
deploy_stack "portainer"
deploy_stack "authentik"
deploy_stack "vaultwarden"
deploy_stack "grafana"
deploy_stack "prometheus"
deploy_stack "loki"
deploy_stack "alloy"
deploy_stack "uptime-kuma"
deploy_stack "watchtower"
deploy_stack "homepage"

ok "Docker stacks deployed"