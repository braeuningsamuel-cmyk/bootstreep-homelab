# Bootstreep Homelab Bootstrap

> **Production-grade, idempotent bootstrap for Ubuntu Server 24.04 LTS** — turns a fresh install into a fully-configured enterprise homelab with Traefik, Docker, monitoring, SSO, backups, and security hardening in a single command.

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Docker](https://img.shields.io/badge/Docker-CE-2496ED?logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-v3.1-24A1C1?logo=traefikproxy&logoColor=white)](https://traefik.io)
[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)](https://gnu.org/software/bash)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://img.shields.io/badge/CI-ShellCheck%20%7C%20yamllint-blue)](.github/workflows/ci.yml)

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Phase Pipeline](#-phase-pipeline)
- [Service Catalogue](#-service-catalogue)
- [Configuration](#-configuration)
- [Security](#-security)
- [Documentation](#-documentation)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**Bootstreep** (Bootstrap + Streep) is a complete, opinionated, modular bootstrap framework for homelab enthusiasts, self-hosters, and small-team DevOps engineers who want production-grade infrastructure without the operational overhead.

Starting from a minimal Ubuntu Server 24.04 LTS install, Bootstreep delivers:

- 🔒 **Hardened OS baseline** (SSH keys only, UFW, Fail2Ban, AppArmor, kernel sysctl)
- 🐳 **Docker CE** from official upstream repos
- 🌐 **Traefik v3.1** reverse proxy with automatic Let's Encrypt via Cloudflare DNS challenge
- 🔐 **Authentik SSO** for unified OIDC/OAuth2/LDAP authentication
- 📊 **Full observability stack** — Prometheus, Grafana, Loki, Alloy
- 🔄 **Watchtower** for automated container updates
- 💾 **Backup pipeline** — Restic + Rclone targeting S3, Hetzner Storage Box, or Backblaze B2
- 📝 **Automated system-report.md** at the end of every run

---

## ✨ Features

| Category | Details |
|----------|---------|
| **Idempotent** | Safe to re-run; all phases check state before acting |
| **Strict mode** | `set -Eeuo pipefail` throughout, shellcheck-validated |
| **Modular** | 11 numbered phases, individually executable |
| **Configurable** | All secrets/tunables in `config/*.env` (gitignored) |
| **Observable** | Colored console output, log files, progress indicators |
| **Recoverable** | Built-in `--backup` flag before destructive operations |
| **Debuggable** | `--debug` (bash trace), `--dry-run`, `--silent` flags |
| **GitOps-ready** | All infra declarative, no manual changes required |
| **Security-first** | Zero-trust defaults, defense-in-depth, principle of least privilege |
| **Production-tested** | Run on bare metal, VMs, Mini PCs, NUCs, Proxmox |
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