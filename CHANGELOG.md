# Changelog

## v3.13.0 (2026-06-17) – Privacy-First + Performance Max

### Privacy (BREAKING)
- **bootstrap.sh**: Pi-hole Passwort MUSS stark sein (min. 12 Zeichen, kein 'admin')
- **bootstrap.sh**: Auto-Generierung von Pi-hole Passwort wenn nicht gesetzt
- **docker-compose-all.yml**: Pi-hole IPv6 deaktiviert, Telemetrie aus
- **open-webui.yml**: 4 Telemetrie-Flags deaktiviert
- **vaultwarden.yml**: DISABLE_TELEMETRY=true, Signups sicher konfigurierbar
- **unbound.conf**: DNS-over-HTTPS zu Cloudflare + Quad9, strikte DNSSEC-Validierung
- **docker daemon**: `ipv6: false`, `ip-forward: false` (IPv6-Leak-Schutz)
- **bootstrap.sh**: Ubuntu whoopsie + popularity-contest + apport deinstalliert
- **bootstrap.sh**: Kernel sysctl Hardening (rp_filter, syncookies, martians, etc.)
- **bootstrap.sh**: IPv6 komplett via sysctl deaktiviert
- **bootstrap.sh**: NetworkManager Connectivity Check deaktiviert
- **bootstrap.sh**: SSH `DebianBanner no`, `MaxStartups`, `RekeyLimit`
- **telegram-bot.py**: command whitelist, `shell=False`, ALLOWED_CHAT_IDS Pflicht
- **scripts/sanitize-logs.sh**: NEU – regelmäßige IP-Anonymisierung in Logs
- **Caddyfile**: Security Headers (HSTS, CSP, X-Frame-Options, Permissions-Policy)
- **watchtower.yml**: WATCHTOWER_DISABLE_ANALYTICS=true
- **ai-agent.service**: `NoNewPrivileges`, `ProtectSystem=strict`, `PrivateTmp`
- **Caddy**: `cap_add: NET_BIND_SERVICE` für Ports <1024

### Performance
- **bootstrap.sh**: TCP BBR Congestion Control + FastOpen aktiviert
- **bootstrap.sh**: zram (50% RAM als komprimierter Swap)
- **bootstrap.sh**: vm.swappiness=10, vfs_cache_pressure=50
- **bootstrap.sh**: I/O noatime/nodiratime, Scheduler `none` für SSDs
- **bootstrap.sh**: irqbalance installiert
- **docker daemon**: `max-concurrent-downloads: 10`, `max-concurrent-uploads: 5`
- **ollama.yml**: `OLLAMA_NUM_PARALLEL=4`, `OLLAMA_MAX_LOADED_MODELS=2`
- **Caddyfile**: Gzip/Brotli Compression + Cache-Control Header
- **bootstrap.sh**: Systemd-Timer statt Cron (genauere Intervalle)
- **update-all.sh**: Docker Cleanup (image prune + builder prune)
- **Alle Images gepinnt**: keine `:latest`-Tags außer unbound/valheim

### Features
- **profile**: Neue Profile `full/minimal/media/ai/privacy`
- **bootstrap.sh**: 17 Sections (Sysctl Harden, Log-Sanitize, Docker Cleanup)
- **ai-agent**: `daily_briefing.py` mit Wetter, Aktien, News, E-Mail, Kalender
- **scripts/lib.sh**: Gemeinsame Helper-Funktionen
- **compose/watchtower.yml**: Auto-Updates + Telemetrie aus
- **compose/vaultwarden.yml**: Passwort-Manager mit SMTP + Admin-Token

### Fixes
- **bootstrap.sh**: `warn()` vor erster Verwendung definiert
- **bootstrap.sh**: Docker-Installer-Checksum echt verifiziert
- **bootstrap.sh**: `sshd -t` validation vor Restart (kein Lockout)
- **caddy.yml**: `cap_drop: ALL` + `cap_add: NET_BIND_SERVICE` (Port 80)
- **backup-all.sh**: GPG-Verschlüsselung für .env + sysctl-Backup
- **health-check.sh**: Fail2Ban + Backup-Alter + BBR-Status
- **docker-compose-all.yml**: Alle Images gepinnt, Telemetrie-Flags

### Cleanup
- **Entfernt**: `ai-agent/__init__.py`, `cloud-init/`, `docs/` (veraltet)
- **NEU**: `scripts/lib.sh` (shared helpers)
- **NEU**: `scripts/docker-cleanup.sh`, `scripts/sanitize-logs.sh`

## v3.11.4 (2026-06-15) – Security & CI Hardening
(vorherige Versionen siehe Git-History)
