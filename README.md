<p align="center">
  <img src="https://img.shields.io/badge/version-4.0.0-6C5CE7?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/status-enterprise--inspired-00B894?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/license-unlicense-6C5CE7?style=for-the-badge" alt="License">
  <br>
  <img src="https://img.shields.io/badge/services-30+-6C5CE7?style=flat-square" alt="Services">
  <img src="https://img.shields.io/badge/security-hardened-00B894?style=flat-square" alt="Security">
  <img src="https://img.shields.io/badge/privacy-first-00B894?style=flat-square" alt="Privacy">
  <img src="https://img.shields.io/badge/ai-local-6C5CE7?style=flat-square" alt="AI">
  <img src="https://img.shields.io/badge/monitoring-grafana-F09D51?style=flat-square" alt="Grafana">
  <img src="https://img.shields.io/badge/docker-compose-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/ansible-%231A1918?style=flat-square&logo=ansible&logoColor=white" alt="Ansible">
  <img src="https://img.shields.io/badge/ubuntu-24.04-E95420?style=flat-square&logo=ubuntu&logoColor=white" alt="Ubuntu">
</p>

<h1 align="center">Bootstreep Homelab</h1>

<p align="center">
  <b>Enterprise-inspiriertes Privacy-First Homelab</b><br>
  <i>30+ gehärtete Docker-Services · Lokale KI · SSO · Monitoring · WAF</i>
</p>

<p align="center">
  <code>chmod +x bootstrap.sh && ./bootstrap.sh</code>
</p>

<br>

---

## Übersicht

Bootstreep verwandelt einen frischen Ubuntu 24.04 Server in ein vollständiges,
Privacy-First Homelab mit **Enterprise-Architektur** – in einem Befehl.

| Bereich | Technologie |
|---------|------------|
| 🔐 **Sicherheit** | CrowdSec WAF, Authentik SSO, Rate Limiting, AppArmor, Kernel Hardening |
| 🕵️ **Privacy** | DNS-over-HTTPS, Pi-hole, Tor-Proxy, Keine Telemetrie, IPv6 deaktiviert |
| 🤖 **KI** | Ollama, LiteLLM Gateway, ChromaDB RAG, Open WebUI, Telegram AI-Agent |
| 📊 **Monitoring** | Grafana, Prometheus, Loki, cAdvisor, Node Exporter, Uptime Kuma |
| ☁️ **Cloud** | Nextcloud AIO, Syncthing, Vaultwarden |
| 🎬 **Media** | Jellyfin, Sonarr, Radarr, Prowlarr, Bazarr, SABnzbd |
| ⚡ **Performance** | TCP BBR, zram, I/O-Optimierung, Parallel-Container-Start |
| 💾 **Backup** | DB-Dumps, ZFS Snapshots, 8 Disaster-Recovery-Szenarien, SOPS |

<br>

---

## Quick Start

```bash
# Auf dem Server:
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
chmod +x bootstrap.sh

# Volles Setup:
./bootstrap.sh

# Oder mit Profil:
INSTALL_PROFILE=ai OLLAMA_MODELS=full ./bootstrap.sh
```

### Profile

| Profil | Enthält |
|--------|---------|
| `full` | Alle 30+ Dienste |
| `minimal` | DNS + Cloud + Media + Basis |
| `media` | DNS + Media + VPN |
| `ai` | System + DNS + KI + AI-Agent |
| `privacy` | Full + maximale Privacy |

<br>

---

## Architektur (v4.0)

```
┌─────────────────────────────────────────────┐
│              Caddy Reverse Proxy             │
│      Rate Limiting · Request Logging         │
│         LAN-Whitelist · Security Headers     │
└────┬──────────┬──────────┬──────────┬───────┘
     │          │          │          │
┌────▼────┐ ┌──▼───┐ ┌──▼───┐ ┌──▼──────┐
│  DNS    │ │  KI   │ │ Web  │ │ Sicherh. │
├─────────┤ ├───────┤ ├──────┤ ├─────────┤
│ Pi-hole │ │Ollama │ │Nextcl│ │CrowdSec │
│ Unbound │ │LiteLLM│ │Syncth│ │Authentik │
│ DoH/Tor │ │Chroma │ │n8n   │ │MinIO    │
└─────────┘ └───────┘ └──────┘ └─────────┘
┌─────────────────────────────────────────────┐
│              Backend Network                 │
├─────────────────────────────────────────────┤
│  Frontend: Caddy + Heimdall                  │
│  Docker-Netzwerk-Isolation                   │
└─────────────────────────────────────────────┘
┌─────────────────────────────────────────────┐
│  Monitoring: Grafana · Prometheus · Loki     │
│  cAdvisor · Node Exporter · Uptime Kuma     │
└─────────────────────────────────────────────┘
```

<br>

---

## Alle Dienste

### Kern-Infrastruktur
| Dienst | Port | Beschreibung |
|--------|------|-------------|
| Caddy | `80, 443` | Reverse Proxy + Dashboard |
| Pi-hole | `8081` | DNS-Werbeblocker |
| Unbound | `5335` | DNS-over-HTTPS Resolver |
| Authentik | `9000` | SSO-Portal |
| CrowdSec | `–` | WAF + IP-Reputation |

### KI & RAG
| Dienst | Port | Beschreibung |
|--------|------|-------------|
| Ollama | `11434` | Lokale KI-Modelle |
| Open WebUI | `3002` | KI-Chat-UI |
| LiteLLM | `4000` | Unified KI-API-Gateway |
| ChromaDB | `8000` | Vektordatenbank (RAG) |
| Hermes | `3000` | Alternative KI-Chat-UI |

### Monitoring
| Dienst | Port | Beschreibung |
|--------|------|-------------|
| Grafana | `3000` | Metriken + Dashboards |
| Prometheus | `9090` | Metrik-Sammlung |
| Loki | `3100` | Log-Aggregation |
| cAdvisor | `8080` | Container-Metriken |
| Node Exporter | `9100` | Host-Metriken |
| Uptime Kuma | `3001` | Uptime-Monitoring |

### Media & Downloads
| Dienst | Port | Beschreibung |
|--------|------|-------------|
| Jellyfin | `8096` | Media-Streaming |
| Sonarr | `8989` | Serien-Management |
| Radarr | `7878` | Filme-Management |
| Prowlarr | `9696` | Indexer-Management |
| Bazarr | `6767` | Untertitel |
| SABnzbd | `8085` | Usenet-Downloads |

### Cloud & Sync
| Dienst | Port | Beschreibung |
|--------|------|-------------|
| Nextcloud AIO | `8082` | Self-hosted Cloud |
| Syncthing | `8384` | P2P-Datei-Sync |
| Vaultwarden | `8093` | Passwort-Manager |

### Tools & Automation
| Dienst | Port | Beschreibung |
|--------|------|-------------|
| n8n | `5678` | Workflow-Automation |
| Heimdall | `8090` | Dashboard |
| Websurfx | `8080` | Meta-Suche (via Tor) |
| TeamSpeak | `9987` | Voice-Chat |
| AMP | `8087` | Game-Server-Manager |
| Watchtower | `–` | Auto-Updates (Rolling) |
| MinIO | `9000` | S3-kompatibler Storage |

<br>

---

## Sicherheit

| Layer | Maßnahme |
|-------|----------|
| 🧱 **Firewall** | UFW + CrowdSec WAF (IP-Reputation) |
| 🔑 **SSH** | Nur Ed25519-Keys, keine Passwörter, RekeyLimit |
| 🛡️ **Rate Limit** | Caddy: 20 req/s/IP |
| 🔒 **Docker** | `no-new-privileges`, `cap_drop: ALL`, seccomp |
| ⚙️ **Kernel** | rp_filter, syncookies, martians, BBR |
| 📡 **Netzwerk** | `frontend` / `backend` Isolation |
| 🕵️ **Privacy** | DoH, Tor-Proxy, IPv6 deaktiviert, keine Telemetrie |
| 📝 **Logs** | IP-Anonymisierung (wöchentlich) |
| 🔐 **Secrets** | SOPS-Verschlüsselung für `.env` |

<br>

---

## Performance

| Optimierung | Wirkung |
|------------|---------|
| TCP BBR + FastOpen | Höherer Durchsatz, niedrigere Latenz |
| zram (50% RAM) | Komprimierter Swap |
| I/O noatime | Reduzierte Disk-Writes |
| vm.swappiness=10 | Mehr Cache, weniger Swap |
| Parallel-Start | Unabhängige Services gleichzeitig |
| OLLAMA_NUM_PARALLEL=4 | 4 gleichzeitige KI-Requests |
| Caddy Gzip/Brotli | Komprimierte Auslieferung |

<br>

---

## Backup & Disaster Recovery

```bash
~/scripts/backup-all.sh              # Volumes + DBs + Configs
~/scripts/disaster-recovery.sh       # 8 DR-Szenarien
~/scripts/decrypt-secrets.sh         # SOPS-Entschlüsselung
```

**8 simulierte Szenarien**: SSD-Failure, Kompromittierung, Ransomware,
Docker-Fail, Stromausfall, DB-Korruption, DNS-Fail, Internet-Fail

<br>

---

## Projektstruktur

```
├── bootstrap.sh                     Ein-Klick-Setup
├── docker-compose-all.yml           Alle Dienste (merged)
├── compose/                         30+ Docker-Compose-Definitionen
│   ├── dns.yml                      Pi-hole + Unbound
│   ├── monitoring.yml               Grafana + Prometheus + Loki
│   ├── litellm.yml                  KI-API-Gateway
│   ├── chromadb.yml                 Vektordatenbank
│   ├── authentik.yml                SSO
│   ├── crowdsec.yml                 WAF
│   └── minio.yml                    S3-Storage
├── scripts/                         15 Utility-Scripts
├── config/                          Caddy, Unbound, SSH, Websurfx
├── ai-agent/                        Telegram-Bot (14 Commands)
├── ansible/                         Ansible-Rollen
├── cloud-init/                      Cloud-Init-Profile
└── .github/workflows/               CI (ShellCheck, yamllint, ruff, gitleaks)
```

<br>

---

## AI-Agent (Telegram)

**14 Befehle** für die Server-Verwaltung via Telegram:

```
/status /services /restart /logs /update /backup /health
/df /network /dns /ask /briefing /start /help
```

- Command-Whitelist · `shell=False` · `ALLOWED_CHAT_IDS` Pflicht
- Nutzt lokales Ollama (keine Cloud-API)
- Tägliches Briefing mit Wetter, Aktien, News, E-Mails

<br>

---

<p align="center">
  <i>Privacy-First · Local AI · No Telemetry · Enterprise Architecture</i>
  <br><br>
  <a href="http://unlicense.org"><img src="https://img.shields.io/badge/license-public%20domain-6C5CE7?style=for-the-badge" alt="Public Domain"></a>
  <br><br>
  <i>Freedom over control · Privacy by design · <a href="http://unlicense.org">Public Domain</a></i>
</p>
