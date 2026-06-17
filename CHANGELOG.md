# Changelog

## v4.1.0 (2026-06-17) – DevSecOps CI + Phase1 Audit-Fixes

### Security & Privacy
- **H10**: backup-all.sh: `ENCRYPT=true` als Default (verschlüsselte Backups)
- **H8**: Telegram-Bot: `sys.exit(1)` wenn `ALLOWED_CHAT_IDS` leer
- **P3**: Open WebUI: `ANONYMOUS_USAGE_STATS=false` (merged + compose)
- **P8**: n8n: `N8N_METRICS=false` (merged + compose)
- **P10**: setup-cron.sh: `$HOME_DIR` → `$SCRIPT_DIR` (undefinierte Variable gefixt)
- **gitleaks**: CI: `continue-on-error` entfernt (Secrets brechen jetzt den Build)

### CI/CD (Phase 2)
- **ci.yml**: 8 Jobs – ShellCheck, yamllint, ruff, markdownlint, gitleaks, Compose Validate, Pinned Tags, Env Consistency
- **security-audit.yml**: Wöchentlicher Sicherheitslauf (Trivy, Gitleaks Full History, Image-Check)
- **dependabot.yml**: Docker-Ecosystem hinzugefügt
- **CODEOWNERS**: Automatische Review-Zuweisung
- **CONTRIBUTING.md**: Stark erweitert mit Code-Style-Guide + CI-Referenz
- **SECURITY.md**: Auf v4.1.x aktualisiert

### Bugfixes
- **M1**: bootstrap.sh: `/home/$USER` → `$HOME` (Caddyfile-Heredoc)
- **M2**: Crontab-Idempotenz: `grep -q` Guards vor crontab-Einträgen
- **M4**: Watchtower: `WATCHTOWER_NO_STARTUP_UPDATE=true`
- **M5**: Caddy-Volume: Absoluter Pfad `$HOME/docker/caddy/Caddyfile`

### Performance
- **Perf2**: Healthcheck `interval: 30s` → `60s` in 8 Compose-Dateien
- **Perf5**: Unbound Cache: msg-cache 64→128m, rrset-cache 128→256m

### AI Integration
- **Telegram-Bot**: `/ask`-Befehl via LiteLLM statt direkter Ollama-API
- **.env.example**: `LITELLM_URL`/`LITELLM_API_KEY`/`LITELLM_MODEL` statt `OLLAMA_URL`/`OLLAMA_MODEL`

## v4.0.0 (2026-06-17) – Enterprise Audit + V4 Architecture

### Critical Fixes
- **cloud-init/ ansible/ bootstrap/**: Repo-URLs auf `braeuningsamuel-cmyk/bootstreep-homelab` korrigiert
- **compose/dns.yml**: Unbound Root-Hints-Volume + benötigte Capabilities hinzugefügt
- **compose/dns.yml**: Pi-hole Image `2024.07.0` → `2025.03.0`
- **compose/watchtower.yml**: `WATCHTOWER_ROLLING_RESTART=true` (Container nacheinander updaten)

### Network Isolation (BREAKING)
- **Neu**: Docker-Netzwerke `frontend` + `backend` statt gemeinsamem `homelab`
- **caddy.yml**: Brückt zwischen `frontend` (öffentlich) und `backend` (intern)
- **heimdall.yml**: Nur auf `frontend` (Dashboard)
- **Alle anderen Services**: Auf `backend` (kein direkter Zugriff von außen)
- **Caddyfile**: Rate Limiting (20 req/s/IP), Request Logging, LAN-Whitelist

### Infrastructure
- **compose/monitoring.yml**: Grafana 11 + Prometheus + Loki + Node Exporter + cAdvisor
- **compose/litellm.yml**: Unified AI Gateway vor Ollama
- **compose/chromadb.yml**: Vektordatenbank für RAG
- **compose/authentik.yml**: SSO für alle Dienste
- **compose/crowdsec.yml**: WAF + IP Reputation (Fail2Ban-Ersatz)
- **compose/minio.yml**: S3-kompatibler Object Storage

### Backup & Security
- **scripts/backup-all.sh**: DB-Dumps (Vaultwarden, n8n, Nextcloud PostgreSQL), ZFS Snapshots
- **scripts/disaster-recovery.sh**: 8 DR-Szenarien mit Recovery-Anleitungen
- **scripts/decrypt-secrets.sh**: SOPS-.env-Entschlüsselung
- **ansible/roles/storage/main.yml**: Vollständige ZFS-Rolle (Pool, Datasets, Snapshots, Cron)
- **.sops.yaml**: SOPS-Konfiguration für verschlüsselte Secrets
- **ansible/group_vars/all.yml**: Vault-Integration, ZFS-Disk-Variablen

### CI
- **ci.yml**: gitleaks `continue-on-error` (kein Lizenz-Zwang)
- **compose/monitoring.yml**: Prometheus + Loki + Promtail + Grafana-Konfigurationen

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
