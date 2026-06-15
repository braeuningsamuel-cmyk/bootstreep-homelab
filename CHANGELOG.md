# Changelog

## v3.11.2 (2026-06-15) – Docker-Images stabilisiert

### Fixes (CRITICAL)
- **open-webui.yml**: Doppelter Tag `:v0.9.6:main` → `:v0.9.6` korrigiert
- **uptime-kuma.yml**: Doppelter Tag `:2:latest` → `:2` korrigiert

### Fixes (HIGH)
- **nextcloud.yml**: Explizites `cap_drop: ALL` hinzugefügt
- **bootstrap.sh**: `amp-instances` in mkdir-Loop aufgenommen
- **bootstrap.sh**: YOUR_GITHUB_USERNAME Platzhalter-Validierung hinzugefügt
- **bootstrap.sh**: Caddyfile-Copy: Silent Fail (`|| true`) entfernt
- **CHANGELOG.md**: v3.11.0, v3.11.1, v3.11.2 Einträge ergänzt

### Fixes (MEDIUM)
- **bootstrap.sh / README.md / docker-compose-all.yml**: Version v3.11.0 → v3.11.2
- **README.md**: Garbled Markdown-Tabelle korrigiert (`|`n`-Artefakt entfernt)
- **README.md**: `--send-telegram` → `--telegram` (korrektes Flag)
- **telegram-bot.py**: Unused Import `datetime` entfernt
- **server_commands.py**: Unused Import `Optional` entfernt
- **restart-service.sh**: `nextcloud-aio` → `nextcloud` Ordnernamen-Mapping
- **bootstrap.sh**: Timeout (600s) für Modell-Pulls hinzugefügt

### Fixes (LOW)
- **bootstrap.sh**: `amp-instances` mkdir vor Copy (Silent Fail behoben)
- **docker-compose-all.yml**: Hermes: `npm install` nur bei fehlendem `node_modules`
- **update-all.sh**: AMP Game-Instanzen-Sub-Loop hinzugefügt
- **backup-all.sh**: Keine `.env`-Dateien: Informative Meldung statt Stille
- **health-check.sh**: Hardcodierte IP → `hostname -I` dynamisch

## v3.10.0 (2026-06-14) – 30-Bug Audit

### Security (CRITICAL)
- **lib.rs**: Command-Injection via `process_kill` → Signal-Whitelist validierung
- **capabilities**: 44 `bootstreep:allow-*` Berechtigungen hinzugefügt

### Fixes (HIGH)
- **nextcloud.yml / amp.yml**: Cap_Drop ALL Kommentare hinzugefügt (Docker Socket)
- **bootstrap.sh**: Bash-Aliases entfernt (zerstören non-interactive shells)
- **backup-all.sh**: .env Verschlüsselung via GPG (optional)

### Fixes (MEDIUM)
- **daily_briefing.py**: Unused imports entfernt, Kalender-Filter korrigiert
- **telegram-bot.py**: Unused imports entfernt
- **bootstrap-flow.md**: Step 14 (Dashboard) hinzugefügt
- **lib.rs**: Redundanter Import entfernt
- **README.md**: Doppelte Game-Server Zeile entfernt

### Fixes (LOW)
- **README.md**: ASCII-Diagramm Ausrichtung korrigiert
- **restart-service.sh / logs.sh**: Korrekte Exit-Codes

## v3.9.1 (2026-06-14) – Security Audit Fixes

### Security
- **bootstrap.sh**: Code Injection via `source "$PROGRESS_FILE"` → SichereParser
- **telegram-bot.py**: Shell Injection via `shell=True` → Command-Whitelist + `shell=False`
- **telegram-bot.py**: Unauthentifizierter Zugriff verhindert (ALLOWED_CHAT_IDS muss gesetzt sein)

### Fixes
- **docker-compose-all.yml**: Caddy Volume-Pfad korrigiert (`./docker/caddy/` → `./caddy/`)
- **Fail2Ban**: `logpath` entfernt, `backend = systemd` für Ubuntu 24.04
- **Versionen**: Alle Dateien auf v3.9.1 synchronisiert

## v3.9.0 (2026-06-14) – Persönliche Daten entfernt

### Cleanup
- GitHub-Username durch `YOUR_GITHUB_USERNAME` ersetzt
- `atlaslab-dashboard` Referenzen in bootstrap.sh entfernt
- `ATLAS.LAB DASHBOARD` → `BOOTSTREEP DASHBOARD`

## v3.8.0 (2026-06-14) – Security Hardening für alle Compose Files

### Security
- Alle 20 individuellen Compose-Files: `security_opt: [no-new-privileges:true]` + `cap_drop: [ALL]`
- Healthchecks für alle Services
- `json-file` Logging mit `max-size: 10m` + `max-file: 3`

## v3.7.0 (2026-06-13) – Healthchecks & Deployment Optimierung

### Compose
- **Healthchecks** für alle 21 Services: Pi-hole, Unbound, Tor, Websurfx, Ollama, Hermes, Open WebUI, Jellyfin, SABnzbd, Sonarr, Radarr, Prowlarr, Bazarr, Nextcloud, Syncthing, Uptime Kuma, Heimdall, TeamSpeak3, AMP, Caddy, n8n
- **Abhängigkeiten** mit `condition: service_healthy`: Open WebUI → Ollama, Hermes → Ollama, Websurfx → Tor
- Startreihenfolge garantiert durch Health-Checks statt bloßer `depends_on`

### Bootstrap
- **Modell-Pull**: Überspringt bereits heruntergeladene Ollama-Modelle (kein erneutes Pull)
- **Arr-Stack**: Paralleler Start von Sonarr, Radarr, Prowlarr, Bazarr
- Fortschrittsmeldungen für jedes Modell-Update

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
- GitHub URL: https://github.com/YOUR_GITHUB_USERNAME/bootstreep-homelab
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
