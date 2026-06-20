# Bootstreep Homelab Bootstrap

> **Enterprise-grade, idempotent bootstrap framework for Ubuntu Server 24.04 LTS** — turns a fresh install into a fully-configured homelab in **one command**.

[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20LTS-E95420?logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Docker](https://img.shields.io/badge/Docker-CE-2496ED?logo=docker&logoColor=white)](https://docker.com)
[![Traefik](https://img.shields.io/badge/Traefik-v3.1-24A1C1?logo=traefikproxy&logoColor=white)](https://traefik.io)
[![Bash](https://img.shields.io/badge/Bash-5.x-4EAA25?logo=gnubash&logoColor=white)](https://gnu.org/software/bash)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://img.shields.io/badge/CI-6%20jobs-blue)](.github/workflows/ci.yml)
[![Stars](https://img.shields.io/github/stars/braeuningsamuel-cmyk/bootstreep-homelab?style=social)](https://github.com/braeuningsamuel-cmyk/bootstreep-homelab)

---

## 🎯 Was ist drin? — Alle 11 Services auf einen Blick

Bootstreep deployt **11 produktionsreife Docker-Services** + **5-Layer-Security-Stack** + **Backup-Pipeline** in einem einzigen Befehl:

| # | Service | Zweck | Technologie | Standard-Port |
|---|---------|-------|-------------|--------------|
| 🔀 | **Traefik v3.1** | Reverse Proxy + SSL/TLS | Traefik | 80, 443 |
| 🔐 | **Authentik** | SSO / Identity Provider | Go + Python | 9000 |
| 🗄️ | **Authentik PostgreSQL** | Identity Database | PostgreSQL 16 | 5432 |
| ⚡ | **Authentik Redis** | Identity Cache | Redis 7 | 6379 |
| 🐳 | **Portainer CE** | Docker Management UI | Portainer | 9443 |
| 🔑 | **Vaultwarden** | Password Manager | Rust | 80 |
| 📊 | **Grafana** | Metriken-Dashboards | Grafana | 3000 |
| 📈 | **Prometheus** | Metriken-Sammlung | Prometheus | 9090 |
| 📜 | **Loki** | Log-Aggregation | Grafana Loki | 3100 |
| 🔄 | **Alloy** | Log/Metrik-Collector | Grafana Alloy | 12345 |
| 💚 | **Uptime Kuma** | Uptime-Monitoring | Node.js | 3001 |
| 🏠 | **Homepage** | Service-Dashboard | Node.js | 3000 |
| 🔄 | **Watchtower** | Auto-Updates | Go | - |

**Zusätzlich inkludiert:**

| Komponente | Zweck |
|-----------|-------|
| 🛡️ **UFW Firewall** | Network Edge Protection |
| 🚫 **Fail2Ban** | Intrusion Detection (SSH + Traefik) |
| 🔒 **AppArmor** | Mandatory Access Control |
| 🐳 **Docker CE** | Container Runtime |
| ⏰ **Chrony** | NTP Time Sync |
| 🌐 **systemd-resolved** | DNS-over-HTTPS |
| 💾 **Restic** | Backup Engine |
| ☁️ **Rclone** | Cloud Backup Targets |
| 🔧 **Systemd Service** | Auto-Start |
| 🔁 **Rollback Script** | Disaster Recovery |

---

## 🤔 Was ist Bootstreep?

**Bootstreep** ist ein vollständiges, modulares und **idempotentes** Bootstrap-Framework für Homelab-Enthusiasten, Self-Hoster und DevOps-Engineers. Es transformiert eine frische Ubuntu Server 24.04 LTS Installation in eine **produktionsreife Enterprise-Architektur** — mit nur einem Befehl.

### Warum Bootstreep?

Andere Bootstrap-Skripte sind entweder zu simpel (kein Security, keine Observability) oder zu komplex (schwer anzupassen, keine Tests). Bootstreep bietet die perfekte Balance:

- ✅ **11 modulare Phasen** — jede einzeln ausführbar
- ✅ **Idempotent** — kann beliebig oft ausgeführt werden
- ✅ **Getestet** — 24 BATS-Tests + 6 GitHub Actions Jobs
- ✅ **Security-First** — 5-Layer-Defense (UFW, Fail2Ban, AppArmor, sysctl, SSH)
- ✅ **GitOps-Ready** — alles in Git, keine manuellen Änderungen
- ✅ **Production-Ready** — Healthchecks, Resource Limits, Auto-Updates
- ✅ **Rollback-Fähig** — automatisches Recovery aus Restic-Backups
- ✅ **Production-Stack** — 11 Services (Traefik, Authentik, Grafana, ...)

### Was du bekommst

| Kategorie | Stack |
|-----------|-------|
| **Reverse Proxy** | Traefik v3.1 mit Let's Encrypt via Cloudflare DNS Challenge |
| **SSO** | Authentik mit PostgreSQL + Redis (OIDC, OAuth2, LDAP, SAML) |
| **Container Management** | Portainer CE |
| **Passwort-Manager** | Vaultwarden (Bitwarden-kompatibel) |
| **Metriken** | Prometheus + Grafana |
| **Logs** | Loki + Grafana Alloy |
| **Uptime-Monitoring** | Uptime Kuma |
| **Dashboard** | Homepage |
| **Auto-Updates** | Watchtower (täglich 04:00) |
| **Backup** | Restic + Rclone (S3, Hetzner, Backblaze B2) |

---

## 🚀 Quick Start (3 Schritte)

### 1️⃣ Clone & Configure

```bash
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab

# Konfiguration kopieren
cp bootstrap/config/bootstrap.env.example bootstrap/config/bootstrap.env
cp bootstrap/config/users.env.example bootstrap/config/users.env

# Cloudflare API Token eintragen (https://dash.cloudflare.com/profile/api-tokens)
nano bootstrap/config/bootstrap.env
# → CLOUDFLARE_API_KEY=...

# SSH Public Key eintragen
nano bootstrap/config/users.env
# → ADMIN_SSH_KEY="ssh-ed25519 AAAA..."
```

### 2️⃣ Bootstrap ausführen

```bash
# Trockenlauf (zeigt nur was passieren würde)
sudo ./bootstrap/bootstrap.sh --dry-run

# Echter Lauf (10-15 Minuten)
sudo ./bootstrap/bootstrap.sh
```

### 3️⃣ Verifizieren

```bash
# System-Report anzeigen
cat system-report.md

# Alle Container prüfen
docker ps

# Services via HTTPS aufrufen
# https://traefik.homelab.example.com
# https://grafana.homelab.example.com
# https://auth.homelab.example.com
```

---

## 📋 Inhaltsverzeichnis

- [Übersicht](#-was-ist-bootstreep)
- [Quick Start](#-quick-start-3-schritte)
- [Features](#-features)
- [Architektur](#-architektur)
- [11-Phasen-Pipeline](#-11-phasen-pipeline)
- [Services](#-services)
- [Konfiguration](#-konfiguration)
- [Security-Modell](#-security-modell)
- [Verwendung](#-verwendung)
- [CI/CD & Tests](#-cicd--tests)
- [Dokumentation](#-dokumentation)
- [Roadmap](#-roadmap)
- [Mitwirken](#-mitwirken)
- [Lizenz](#-lizenz)

---

## ✨ Features

### 🎯 Production-Grade

| Feature | Details |
|---------|---------|
| **Idempotent** | Jede Phase prüft State vor Aktion — sicher mehrfach ausführbar |
| **Strict Mode** | `set -Eeuo pipefail` durchgängig, shellcheck-validiert |
| **Modular** | 11 nummerierte Phasen, einzeln ausführbar |
| **Konfigurierbar** | Alle Secrets/Tunables in `config/*.env` (gitignored) |
| **Observability** | Colored Output, Log-Files, Progress-Indikatoren |
| **Recoverable** | `--backup` Flag vor destruktiven Operationen |
| **Debuggable** | `--debug` (Bash Trace), `--dry-run`, `--silent` |
| **GitOps-Ready** | Alles deklarativ, keine manuellen Änderungen |

### 🔐 Security-First

| Layer | Implementation |
|-------|----------------|
| **SSH** | PermitRootLogin no, PasswordAuthentication no, key-only, MaxAuthTries 3 |
| **Firewall** | UFW deny-incoming default, explizite Allow-List (22, 80, 443) |
| **IDS** | Fail2Ban SSH + Traefik Jails |
| **Kernel** | rp_filter, SYN cookies, ASLR, protected symlinks |
| **MAC** | AppArmor enforced profiles |
| **Docker** | no-new-privileges, log rotation, live-restore, overlay2 |
| **Auth** | Authentik SSO (OIDC/OAuth2), Signups deaktiviert |
| **Secrets** | `.env` Dateien (gitignored), keine Hardcodes |
| **Audit** | Auditd installiert und aktiviert |

### 🧪 Getestet & CI-Validated

- **24 BATS-Tests** für Bash-Scripts
- **6 GitHub Actions Jobs**: shellcheck, yamllint, bats, secrets, markdown-lint, docker-validate
- **100% der Compose-Files** haben Healthchecks, Resource Limits, Restart Policies
- **0 hardcoded secrets** über alle Dateien
- **Strict mode** in allen Bash-Scripts

---

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────┐
│           INTERNET / CLOUDFLARE (DDoS Protection)        │
└─────────────────────────┬───────────────────────────────┘
                          │ Ports 80/443
                          ▼
┌─────────────────────────────────────────────────────────┐
│  EDGE: Traefik v3.1                                       │
│  • Let's Encrypt via Cloudflare DNS Challenge            │
│  • Auto-Renewal alle 60 Tage                             │
│  • Rate Limiting (100 req/s per IP)                       │
│  • Security Headers (HSTS, X-Frame, CSP)                  │
└─────────────────────────┬───────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            │   Docker Network: homelab  │
            │   (172.20.0.0/16)          │
            └─────────────┬─────────────┘
                          │
    ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┐
    ▼      ▼      ▼      ▼      ▼      ▼      ▼      ▼
 Authen- Portai- Vault- Grafana Prom  Loki  Uptime Home
  tik    ner    warden                       Kuma  page
  SSO    Docker Passw.                       Mon.
    │      │      │      │      │      │      │      │
    └──────┴──────┴──────┴──────┴──────┴──────┴──────┘
                          │
                          ▼
    ┌─────────────────────────────────────────────┐
    │  Observability Backend (Alloy + Prometheus) │
    └─────────────────────────────────────────────┘
                          │
                          ▼
    ┌─────────────────────────────────────────────┐
    │  HOST: Ubuntu 24.04 LTS                      │
    │  • UFW, Fail2Ban, AppArmor, sysctl           │
    │  • Docker CE (overlay2, live-restore)        │
    │  • Backup: Restic → S3/Hetzner/B2           │
    └─────────────────────────────────────────────┘
```

Siehe [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) für Details.

---

## 📦 11-Phasen-Pipeline

| # | Phase | Zweck | Idempotent |
|---|-------|-------|:----------:|
| 1 | `01-system.sh` | OS-Check, Hardware-Inventory, Netzwerk-Validierung | ✅ |
| 2 | `02-packages.sh` | apt update + unattended-upgrades | ✅ |
| 3 | `03-base-packages.sh` | curl, wget, vim, btop, htop, etc. | ✅ |
| 4 | `04-users.sh` | admin, docker, service users + SSH-Keys | ✅ |
| 5 | `05-security.sh` | SSH + UFW + Fail2Ban + sysctl | ✅ |
| 6 | `06-storage.sh` | `/opt/docker` Layout erstellen | ✅ |
| 7 | `07-docker.sh` | Docker CE Installation (offizielles Repo) | ✅ |
| 8 | `08-network.sh` | systemd-resolved + Chrony + Tailscale | ✅ |
| 9 | `09-backups.sh` | Restic + Rclone Pipeline | ✅ |
| 10 | `10-services.sh` | Alle Docker Compose Stacks deployen | ✅ |
| 11 | `11-finish.sh` | `system-report.md` generieren | ✅ |

Einzelne Phase ausführen:

```bash
sudo bash bootstrap/scripts/05-security.sh
```

Phase überspringen:

```bash
sudo ./bootstrap/bootstrap.sh --skip 11
```

---

## 🛠️ Services (11 Stacks)

| Service | URL-Pattern | Zweck | Auth |
|---------|------------|-------|------|
| **Traefik** | `https://traefik.<domain>` | Reverse Proxy Dashboard | Authentik |
| **Portainer** | `https://portainer.<domain>` | Docker Management UI | First-Visit |
| **Authentik** | `https://auth.<domain>` | SSO / OIDC / OAuth2 | First-Visit Admin |
| **Vaultwarden** | `https://vault.<domain>` | Passwort-Manager | First-Visit |
| **Grafana** | `https://grafana.<domain>` | Metriken-Dashboards | admin / env |
| **Prometheus** | `https://prometheus.<domain>` | Metriken-Sammlung | none |
| **Loki** | intern | Log-Aggregation | none |
| **Alloy** | `http://<host>:12345` | Log/Metrik-Collector | none |
| **Uptime Kuma** | `https://status.<domain>` | Uptime-Monitoring | First-Visit |
| **Homepage** | `https://home.<domain>` | Service-Dashboard | none |
| **Watchtower** | intern | Auto-Update Container | none |

Alle Stacks haben:
- ✅ Healthchecks
- ✅ Resource Limits (CPU + Memory)
- ✅ `no-new-privileges:true`
- ✅ Log-Rotation (10m × 3 files)
- ✅ Restart-Policies
- ✅ `.env.example` Template

---

## ⚙️ Konfiguration

Alle Konfiguration in `bootstrap/config/*.env` Dateien:

```bash
# bootstrap.env
DOMAIN=homelab.example.com
[email protected]
CLOUDFLARE_EMAIL=admin@example.com
CLOUDFLARE_API_KEY=your_cloudflare_token_here
TAILSCALE_AUTHKEY=tskey-auth_xxxxxxxxx

# users.env
ADMIN_USER=admin
ADMIN_SSH_KEY="ssh-ed25519 AAAA... your_key_here"

# network.env
PRIMARY_DNS=1.1.1.1
SECONDARY_DNS=9.9.9.9
USE_DOH=true
NTP_SERVERS=time.cloudflare.com,pool.ntp.org

# storage.env
STORAGE_ROOT=/opt/docker
USE_ZFS=false

# docker.env
DOCKER_NETWORK=homelab
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3
```

Siehe [docs/CONFIGURATION.md](docs/CONFIGURATION.md) für Details.

---

## 🔐 Security-Modell

Bootstreep implementiert **Defense in Depth** auf 5 Ebenen:

### Layer 1: Network Edge
- Cloudflare Proxy (DDoS-Protection)
- UFW Firewall (allow 22, 80, 443 only)
- Fail2Ban (SSH + Traefik Jails)

### Layer 2: Host OS
- SSH key-only authentication
- Root-Login deaktiviert
- MaxAuthTries 3
- AppArmor enforced
- Kernel sysctl hardening

### Layer 3: Container Runtime
- Docker mit `no-new-privileges`
- Read-only docker.sock mounts
- Resource Limits (CPU, Memory)
- Healthchecks
- Log Rotation

### Layer 4: Application
- Authentik SSO für unified authentication
- OIDC/OAuth2 für Service-Integration
- Keine öffentlichen Registrierungen
- Nur Invitation-basierte User-Provisionierung

### Layer 5: Data
- Verschlüsselte Backups (Restic)
- Secrets in `.env` (gitignored)
- Database-Passwörter ≥32 Zeichen

```bash
# Security-Audit ausführen
sudo lynis audit system
sudo aa-status
sudo fail2ban-client status
```

Siehe [docs/SECURITY.md](docs/SECURITY.md) für Details.

---

## 💻 Verwendung

### Makefile (empfohlen)

```bash
make help        # Alle verfügbaren Commands anzeigen
make install     # Bootstrap auf Zielsystem ausführen
make test        # BATS Tests ausführen
make lint        # shellcheck + yamllint
make secrets     # Hardcoded-Secrets scannen
make validate    # lint + secrets
make deploy      # Alle Docker Stacks deployen
make backup      # Backup-Script ausführen
make logs        # Service-Logs anschauen
make report      # System-Report generieren
make update      # Docker Images aktualisieren
make clean       # Docker Resources aufräumen
make all         # Alles (lint + test + validate)
make ci          # CI Pipeline (GitHub Actions)
```

### CLI-Flags

```bash
./bootstrap/bootstrap.sh --dry-run    # Zeigt nur was passieren würde
./bootstrap/bootstrap.sh --debug      # Bash Tracing
./bootstrap/bootstrap.sh --silent     # Minimale Ausgabe
./bootstrap/bootstrap.sh --backup     # Voll-Backup vor Änderungen
./bootstrap/bootstrap.sh --skip 11    # Spezifische Phase überspringen
./bootstrap/bootstrap.sh --version    # Version anzeigen
./bootstrap/bootstrap.sh --help       # Hilfe anzeigen
```

### Rollback (Notfall)

```bash
# Verfügbare Snapshots anzeigen
sudo ./bootstrap/scripts/rollback.sh --list

# Von letztem Snapshot wiederherstellen
sudo ./bootstrap/scripts/rollback.sh latest

# Von spezifischem Snapshot wiederherstellen
sudo ./bootstrap/scripts/rollback.sh 7e188ff
```

### Systemd Auto-Start

```bash
sudo cp config/systemd/bootstreep-homelab.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now bootstreep-homelab.service
sudo systemctl status bootstreep-homelab.service
```

---

## 🧪 CI/CD & Tests

### GitHub Actions (6 Jobs)

| Job | Tool | Was wird geprüft |
|-----|------|------------------|
| **shellcheck** | ShellCheck | Bash Script Qualität |
| **yamllint** | yamllint | YAML Structure & Style |
| **bats** | BATS | 24 Bash Tests |
| **secrets** | grep | Hardcoded Credentials |
| **markdown-lint** | markdownlint-cli2 | Dokumentation |
| **docker-validate** | YAML parser | Compose-Files |

### Lokales Testen

```bash
# Alles testen
make all

# Nur BATS
make bats

# Nur Linting
make lint

# Secret-Scan
make secrets
```

### BATS Tests (24 Tests)

Coverage in `tests/bootstrap.bats`:

- ✅ Script existence + executability
- ✅ Bash shebang correctness
- ✅ Strict mode validation
- ✅ CLI flag tests
- ✅ Config files presence
- ✅ Compose files validation
- ✅ Healthchecks present
- ✅ Resource limits present
- ✅ Restart policies present
- ✅ No hardcoded secrets
- ✅ Documentation completeness

---

## 📚 Dokumentation

| Dokument | Zweck |
|----------|-------|
| [INSTALL.md](docs/INSTALL.md) | Detaillierte Installations-Anleitung |
| [CONFIGURATION.md](docs/CONFIGURATION.md) | Konfigurations-Referenz |
| [SERVICES.md](docs/SERVICES.md) | Service-Katalog |
| [SECURITY.md](docs/SECURITY.md) | Security-Modell |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Häufige Probleme |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | System-Architektur |
| [TESTING.md](docs/TESTING.md) | Test-Anleitung |

---

## 🗺️ Roadmap

### v1.0 (Current) ✅
- 11-Phasen Bootstrap Pipeline
- 11 Production Docker Stacks
- 24 BATS Tests
- 6 CI Jobs
- Comprehensive Documentation

### v1.1 (Next)
- [ ] CrowdSec WAF Integration
- [ ] Immich (Google Photos Replacement)
- [ ] Paperless-NGX (Dokumenten-Management)
- [ ] Jellyfin Media Stack (Sonarr/Radarr/Bazarr)
- [ ] SOPS/Age Secrets Encryption

### v2.0
- [ ] Multi-Node Cluster Support (K3s)
- [ ] Terraform Provider für full IaC
- [ ] Ansible Roles für fine-grained Control
- [ ] ArgoCD GitOps Workflow

### v3.0
- [ ] Full Agent-Driven Operations (Hermes Integration)
- [ ] Self-Healing Platform
- [ ] Marketplace für Service-Templates

---

## 🤝 Mitwirken

Beiträge sind willkommen! Siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Richtlinien.

Vor einem PR:
1. `make lint` muss clean sein
2. `make bats` muss 100% bestehen
3. `make secrets` muss clean sein
4. `set -Eeuo pipefail` muss am Anfang jedes neuen Scripts sein
5. Dokumentation in `docs/` aktualisieren
6. Auf einer frischen Ubuntu 24.04 VM testen

---

## 📄 Lizenz

MIT © 2025 [BraeuningsSamuel-Cmyk](https://github.com/braeuningsamuel-cmyk)

Siehe [LICENSE](LICENSE) für Volltext.

---

## 🙏 Danksagungen

- [Traefik](https://traefik.io) — Reverse Proxy
- [Authentik](https://goauthentik.io) — SSO
- [Portainer](https://portainer.io) — Docker UI
- [Vaultwarden](https://github.com/dani-garcia/vaultwarden) — Passwort-Manager
- [Grafana](https://grafana.com) — Observability
- [Prometheus](https://prometheus.io) — Metriken
- [Loki](https://grafana.com/oss/loki/) — Logs
- [Restic](https://restic.net) — Backups
- Allen anderen Open-Source-Maintainern, die solche Projekte ermöglichen.