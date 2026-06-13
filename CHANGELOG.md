# Changelog

## v3.4.0 (2026-06-13)

### Core Stability
- `dc_up()` retry helper applied to all 17 docker compose calls (3 attempts, 5s delay)
- Docker HEALTHCHECK added to Pi-hole (DNS query), Ollama (API endpoint), Caddy (HTTP)
- `depends_on` ordering in all compose files: pihole→unbound, open-webui/hermes→ollama, websurfx→tor
- Docker daemon pre-check (`docker info`) before compose operations
- Model pulls refactored with per-model progress logging

### Bugfixes
- Pi-hole volume regex in `backup-all.sh` — `etc-pihole` → `pihole_etc`
- `health-check.sh`: added missing `hermes` container to check loop
- Removed unused `openai>=1.0` from requirements.txt (package not imported anywhere)
- Removed orphan `OPENAI_API_KEY` from `.env.example` (unreferenced in code)
- Removed dead `import requests` from `daily_briefing.py`

### New Services
- Hermes AI Chat UI added to `docker-compose-all.yml`
- `TIMEZONE` variable interpolation in merged compose (7 services)

### Documentation
- README: fixed duplicate `bootstrap.sh` entry in directory tree
- README: updated architecture overview and port table

## v3.3.0 (2026-06-12)

### Security & Production Hardening
- Pre-flight checks: root block, IP validation, disk space >20GB, tool availability
- Full logging to `~/bootstrap.log`
- Progress marker file (`~/.bootstrap-progress`) with reboot-safe resume
- SSH config template with `$SERVER_IP` substitution
- UFW firewall rules for LAN and VPN access
- Retry helper `dc_up()` with 3 attempts

### Service Expansion
- n8n (workflow automation, port 5678)
- Open WebUI (Ollama chat UI, port 3002)
- Heimdall (dashboard, port 8090)
- Hermes migrated from host process to Docker Compose

### AI Agent
- Telegram bot with 14 commands (status, services, restart, logs, update, backup, health, df, network, dns, exec, ask, briefing)
- Daily briefing: weather (OpenWeatherMap), stocks (Yahoo Finance), news (RSS), email (Gmail IMAP), calendar (ICS)
- SSH automation via `server_commands.py`
- Systemd service for auto-restart

## v3.0.0 (2026-06-10)

Initial release based on Atlas.Lab Homelab Server Guide v3.3.
- 18 Docker services: Pi-hole, Unbound, Tor, Websurfx, Ollama, Jellyfin, SABnzbd, Sonarr, Radarr, Prowlarr, Bazarr, Nextcloud AIO, Syncthing, Uptime Kuma, Caddy, Samba, WireGuard/PiVPN, AMP
- Single `bootstrap.sh` for Ubuntu 24.04 deployment
- Cloud-init support
