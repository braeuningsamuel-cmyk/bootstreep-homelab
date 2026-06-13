# Changelog

## v3.6.0 (2026-06-13) – Security & Performance Hardening

### Security
- **Compose**: `security_opt: [no-new-privileges:true]` + `cap_drop: [ALL]` auf alle Container
- **SSH**: Schwache Ciphers/MACs/KEX deaktiviert (nur chacha20-poly1305, aes256-gcm, curve25519)
- **SSH**: LoginGraceTime 30s, MaxAuthTries 3, ClientAliveInterval 300s
- **Fail2Ban**: SSH-Jail aktiviert (3 Versuche → 1h Ban)
- **UFW**: SSH Rate Limiting (`ufw limit ssh`)
- **Docker Daemon**: `no-new-privileges: true`, `userland-proxy: false`, `live-restore: true`
- **Dashboard CSP**: `object-src 'none'`, `base-uri 'self'`, `form-action 'self'`
- **Dashboard**: `withGlobalTauri: false` (API nicht global exponiert)
- **Logging**: `json-file` mit `max-size: 10m` + `max-file: 3` auf allen kritischen Services

### Performance
- **Resource Limits**: Ollama 14g/8 CPU, Jellyfin 4g/4 CPU, n8n 1g, Caddy 256m
- **Docker Daemon**: `overlay2` storage driver, `65536` nofile ulimits
- **Parallel Start**: `dc_up_parallel()` für unabhängige Services
- **Bootstrap**: Docker Daemon JSON-Konfiguration (logging, storage, ulimits)

### Compose
- Alle 21 Services im merged File haben jetzt Security-Baseline
- Resource Limits für Ollama, Jellyfin, n8n, Caddy
- Logging-Konfiguration für alle kritischen Container

## v3.5.0 (2026-06-13) – Bootstreep Rename

### Breaking Changes
- Repository renamed from `atlaslab-homelab-bootstrap` to `bootstreep-homelab`
- GitHub URL: https://github.com/braeuningsamuel-cmyk/bootstreep-homelab
- Dashboard repo renamed from `atlaslab-dashboard` to `bootstreep-dashboard`
- `ATLAS.LAB` branding → `BOOTSTREEP` throughout all files

### Bugfixes (15 Audit Issues)
- **Critical**: `dc_up()` now uses subshell `(cd ...)` – no longer kills CWD
- **Critical**: `die()` function defined before first use (was undefined)
- **Critical**: Caddyfile mount added to `docker-compose-all.yml` (Caddy was unconfigured)
- **Critical**: `backup-all.sh` now loops over ALL named volumes (was only 2/18)
- **High**: Dashboard: removed duplicate AMP row, added Samba/WireGuard/Syncthing 22000+21027
- **High**: Dashboard port checker: added ports 8091, 21027, 22000
- **High**: 9 compose files switched from bind mounts to named volumes (data location consistency)
- **High**: 7 hardcoded `TZ: Europe/Berlin` → `${TIMEZONE:-Europe/Berlin}`
- **Medium**: Section order: 12 (AI Agent) now before 13 (GPU) and 14 (Dashboard)
- **Medium**: DNSSEC sigfail test checks for empty output (not 192.168.178.1)
- **Medium**: `dpkg-reconfigure` uses `DEBIAN_FRONTEND=noninteractive`
- **Medium**: Dashboard Caddyfile insertion uses portable heredoc (not GNU sed `\n`)
- **Low**: Logging starts before pre-flight checks (catches all output)

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

Initial release based on Atlas.Lab Homelab Server Guide v3.3 (pre-rename).
- 18 Docker services: Pi-hole, Unbound, Tor, Websurfx, Ollama, Jellyfin, SABnzbd, Sonarr, Radarr, Prowlarr, Bazarr, Nextcloud AIO, Syncthing, Uptime Kuma, Caddy, Samba, WireGuard/PiVPN, AMP
- Single `bootstrap.sh` for Ubuntu 24.04 deployment
- Cloud-init support
