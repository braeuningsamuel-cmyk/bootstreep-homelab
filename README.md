# Bootstreep Homelab Bootstrap

> Production-grade bootstrap for Ubuntu Server 24.04 LTS — turns a fresh install into a fully-configured enterprise homelab with Traefik, Docker, monitoring, SSO, backups, and security hardening.

## Features

- **Idempotent Bash scripts** — safe to re-run
- **Modular 11-phase pipeline** — run all or skip individual phases
- **Enterprise security stack** — UFW, Fail2Ban, AppArmor, kernel hardening, SSH keys only
- **Production Docker Compose stacks** — Traefik, Portainer, Authentik, Vaultwarden, Grafana, Prometheus, Loki, Alloy, Uptime Kuma, Watchtower, Homepage
- **Backup system** — Restic + Rclone with S3/Hetzner/Backblaze support
- **Logging** — journalctl rotation + Loki aggregation
- **System report** — automated `system-report.md` after every run

## Quick Start

```bash
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
sudo ./bootstrap/bootstrap.sh
```

## Requirements

- Ubuntu Server 24.04 LTS (or 22.04 LTS)
- amd64 or arm64
- Minimum 4 GB RAM, 32 GB free disk
- Root or sudo access
- Public domain pointing to your server (for Let's Encrypt via Cloudflare)

## Configuration

Edit files in `bootstrap/config/` before running:

- `bootstrap.env` — domain, email, Cloudflare API key, Tailscale key
- `users.env` — admin user, SSH key
- `network.env` — DNS servers, NTP
- `storage.env` — storage root, optional ZFS
- `docker.env` — Docker network and logging

## Phase Pipeline

| Phase | Script | Purpose |
|-------|--------|---------|
| 1 | `01-system.sh` | OS check, inventory, network validation |
| 2 | `02-packages.sh` | apt update + unattended-upgrades |
| 3 | `03-base-packages.sh` | Install base tools (curl, vim, btop, etc.) |
| 4 | `04-users.sh` | Create admin, docker, service users + SSH keys |
| 5 | `05-security.sh` | SSH hardening, UFW, Fail2Ban, AppArmor, sysctl |
| 6 | `06-storage.sh` | Create /opt/docker layout |
| 7 | `07-docker.sh` | Docker CE from official repo |
| 8 | `08-network.sh` | systemd-resolved, Chrony, Tailscale |
| 9 | `09-backups.sh` | Restic + Rclone backup pipeline |
| 10 | `10-services.sh` | Deploy all Docker Compose stacks |
| 11 | `11-finish.sh` | Generate system-report.md |

## Flags

```bash
./bootstrap/bootstrap.sh --dry-run    # show what would happen
./bootstrap/bootstrap.sh --debug      # bash tracing
./bootstrap/bootstrap.sh --silent     # minimal output
./bootstrap/bootstrap.sh --backup     # full backup before changes
./bootstrap/bootstrap.sh --skip 11    # skip specific phase
```

## After Installation

Access services via `https://<service>.<your-domain>`:

- Traefik dashboard: `https://traefik.your-domain`
- Portainer: `https://portainer.your-domain`
- Authentik SSO: `https://auth.your-domain`
- Grafana: `https://grafana.your-domain`
- Prometheus: `https://prometheus.your-domain`
- Vaultwarden: `https://vault.your-domain`
- Uptime Kuma: `https://status.your-domain`
- Homepage: `https://home.your-domain`

## Documentation

- [INSTALL.md](docs/INSTALL.md) — detailed installation
- [CONFIGURATION.md](docs/CONFIGURATION.md) — config reference
- [SERVICES.md](docs/SERVICES.md) — service catalogue
- [SECURITY.md](docs/SECURITY.md) — security model
- [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — common issues

## License

MIT — see [LICENSE](LICENSE)