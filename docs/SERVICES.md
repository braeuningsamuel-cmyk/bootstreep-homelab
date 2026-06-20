# Services

| Service | URL | Purpose | Default Credentials |
|---------|-----|---------|---------------------|
| Traefik | `https://traefik.<domain>` | Reverse proxy, Let's Encrypt | none (auth via Authentik) |
| Portainer | `https://portainer.<domain>` | Docker management UI | create on first visit |
| Authentik | `https://auth.<domain>` | SSO/OIDC/OAuth2 | create admin on first visit |
| Vaultwarden | `https://vault.<domain>` | Password manager | create on first visit |
| Grafana | `https://grafana.<domain>` | Metrics dashboards | admin / `${GRAFANA_PASSWORD}` |
| Prometheus | `https://prometheus.<domain>` | Metrics collection | none |
| Loki | internal | Log aggregation | none |
| Alloy | `http://<host>:12345` | Log/metric collector | none |
| Uptime Kuma | `https://status.<domain>` | Uptime monitoring | create on first visit |
| Homepage | `https://home.<domain>` | Dashboard | none |
| Watchtower | internal | Auto-updates | none |

## Adding Services

1. Create a new directory under `bootstrap/compose/<service>/`
2. Add `docker-compose.yml`
3. Reference `${DOMAIN}` and other env vars
4. Add to `bootstrap/scripts/10-services.sh`
5. Restart bootstrap or `cd compose/<service> && docker compose up -d`

## Network

All services join the `homelab` Docker network. DNS resolution works via container name.

## Persistence

- `/opt/docker/data` — service data
- `/opt/docker/configs` — configuration files
- `/opt/docker/backups` — Restic snapshots
- `/opt/docker/logs` — service logs (rotated)