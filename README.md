# Bootstreep Homelab 🚀

**Ein Befehl – fertiges Homelab mit 21+ Diensten + KI-Assistent**

```
chmod +x bootstrap.sh && ./bootstrap.sh
```

---

## Übersicht

Dieses Repository enthält ein vollständiges Bootstrap-Script für einen Ubuntu 24.04 Homelab-Server. Es installiert und konfiguriert automatisch **21+ Dienste** – plus einen **KI-Assistenten per Telegram**.

| Komponente | Beschreibung |
|---|---|
| **DNS** | Pi-hole (Werbeblocker) + Unbound (Resolver) |
| **Privatsphäre** | Tor SOCKS5-Proxy + Websurfx (Metasuchmaschine) |
| **KI / Lokale LLMs** | Ollama (Mistral, Llama, DeepSeek, Phi) + Hermes + Open WebUI |
| **Workflow Automation** | n8n (Make/Zapier-Alternative) |
| **Medien** | Jellyfin + SABnzbd + Sonarr + Radarr + Prowlarr + Bazarr |
| **Cloud & Sync** | Nextcloud AIO + Syncthing |
| **Dashboard** | Heimdall (Startseite für alle Dienste) |
| **Monitoring** | Uptime Kuma |
| **Voice** | TeamSpeak3 |
| **Game-Server** | AMP (Minecraft, Valheim uvm.) |
| **Reverse Proxy** | Caddy (Auto-HTTPS) |
| **VPN** | WireGuard via PiVPN oder Tailscale |
| **Netzwerkfreigabe** | Samba |
| **Game-Server** | AMP (Minecraft, Valheim uvm.) |
| **📱 KI-Agent** | Telegram Bot mit Server-Steuerung, Daily Briefing, E-Mail, Kalender |
| **🖥️ Eigenes Dashboard** | Bootstreep Server Control – Caddy-Server (Port 80) + Desktop-App (Tauri) |

## Architektur

```
                    ┌─────────────────────────────┐
                    │       Internet / FritzBox     │
                    │       192.168.178.1           │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │   Ubuntu 24.04 LTS Server    │
                    │      192.168.178.20          │
                    │                              │
                    │  ┌──────────────────────┐    │
                    │  │   Caddy (80/443)      │    │
                    │  │   Reverse Proxy       │    │
                    │  └──┬───┬───┬───┬───┬───┘    │
                    │     │   │   │   │   │         │
                    │  ┌──▼──▼──▼──▼──▼──▼──────┐  │
                    │  │  Docker Netzwerk        │  │
                    │  │  "homelab"              │  │
                    │  │                         │  │
│  │  Pi-hole  ←  Unbound    │  │
│  │  Tor → Websurfx         │  │
│  │  Ollama + Open WebUI    │  │
│  │  Hermes + n8n           │  │
│  │  Jellyfin + Arr-Stack   │  │
│  │  Nextcloud + Syncthing  │  │
│  │  Heimdall + Uptime Kuma │  │
│  │  TeamSpeak + AMP       │  │
                    │  └─────────────────────────┘  │
                    │                              │
                    │  ┌──────────────────────┐    │
                    │  │  KI-Assistent         │    │
                    │  │  Telegram Bot         │    │
                    │  │  Ollama + Briefing    │    │
                    │  └──────────────────────┘    │
                    └──────────────────────────────┘
```

## Port-Übersicht

| Dienst | Port | Typ |
|---|---|---|
| Pi-hole | `53` / `8081` | Docker |
| Unbound | `5335` (127.0.0.1) | Docker |
| Websurfx | `8080` | Docker |
| Tor | `9050` (127.0.0.1) | Docker |
| Bootstreep Dashboard | `80` | Caddy (Statisch) |
| Caddy | `443` | Docker |
| Nextcloud AIO | `8082` / `9443` | Docker |
| Jellyfin | `8096` | Docker |
| Sonarr | `8989` | Docker |
| Radarr | `7878` | Docker |
| Prowlarr | `9696` | Docker |
| Bazarr | `6767` | Docker |
| Hermes | `3000` | Node |
| Open WebUI | `3002` | Docker |
| n8n | `5678` | Docker |
| Ollama API | `11434` (127.0.0.1) | Docker |
| TeamSpeak3 | `9987/udp` / `10011` / `30033` | Docker |
| AMP | `8087` / `8088` | Docker |
| Uptime Kuma | `3001` | Docker |
| Syncthing | `8384` / `22000` / `21027/udp` | Docker |
| WireGuard | `51820/udp` | PiVPN |
| SABnzbd | `8085` | Docker |
| Heimdall | `8090` / `8091` | Docker |
| Samba | `445` | System |

## Schnellstart

### 1. Server vorbereiten

Empfohlene Hardware: **Dell OptiPlex 7080** (i7-10700, 32GB RAM, 1TB NVMe) – ca. 320–380€ gebraucht.

Ubuntu 24.04 LTS installieren, statische IP eintragen (z.B. `192.168.178.20`), SSH-Zugriff einrichten:

```bash
# Auf deinem PC (nicht Server):
ssh-keygen -t ed25519 -C "homelab-key"
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@192.168.178.20
```

Dann auf dem Server:

```bash
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
chmod +x bootstrap.sh
./bootstrap.sh
```

### 2. Nach dem Setup

Nach Neustart alle Dienste prüfen:

```bash
~/scripts/health-check.sh
```

### 3. KI-Assistent aktivieren

```bash
nano ~/ai-agent/.env
# → Telegram Bot Token von @BotFather eintragen
sudo systemctl start ai-agent
```

## AI Agent Feature (Telegram Bot)

Der integrierte KI-Assistent verwandelt deinen Server in einen **persönlichen Assistenten** – erreichbar per Telegram von überall.

### Befehle

| Befehl | Beschreibung |
|---|---|
| `/status` | Server-Status (CPU, RAM, Docker) |
| `/services` | Alle laufenden Container anzeigen |
| `/restart <name>` | Dienst neustarten |
| `/logs <name>` | Logs anzeigen |
| `/update` | System + Container updaten |
| `/backup` | Backup auslösen |
| `/health` | Health-Check |
| `/df` | Speicherplatz |
| `/network` | Offene Ports + IPs |
| `/dns` | DNS-Test |
| `/exec <cmd>` | Beliebiges Kommando |
| `/ask <frage>` | Frage an lokale KI (Ollama) |
| `/briefing` | Tägliche Zusammenfassung |

### Daily Briefing

Der Bot kann dir jeden Morgen eine Zusammenfassung senden mit:
- **Wetter** (OpenWeatherMap)
- **Aktienkurse** (Yahoo Finance)
- **Tech-News** (Hacker News, RSS)
- **E-Mail-Zusammenfassung** (Gmail IMAP)
- **Kalender-Termine** (Nextcloud ICS)

Im Systemd-Service mit `--briefing` Flag:

```bash
0 7 * * * /usr/bin/python3 ~/ai-agent/daily.py --send-telegram
```

### Integration mit GenSpark Claw & anderen AI Agents

Dieses Bootstrap-Setup ist designed, um mit AI-Agent-Plattformen wie **GenSpark Claw** zu funktionieren:

1. **Lokale Installation**: Der Agent läuft auf dem Server selbst (Telegram Bot + Ollama)
2. **Remote-Steuerung**: SSH-Key-basierte Authentifizierung für agentischen Zugriff
3. **Docker-Integration**: Alle Dienste sind per Docker-API steuerbar
4. **Erweiterbar**: Eigene Tools als Python-Module einbindbar

> **Hinweis:** GenSpark Claw (ab $19.99/Monat) bietet zusätzliche Cloud-Features wie Computer-Use, Browser-Automation und Multi-App-Integrationen. Der Telegram Bot hier ist die **Open-Source-Alternative** für die lokale Server-Steuerung.

## Verzeichnisstruktur

```
bootstreep-homelab/
├── bootstrap.sh              # Master-Setup-Script
├── docker-compose-all.yml    # Alle Dienste in einer Datei
├── compose/                  # Docker Compose Definitionen
│   ├── dns.yml               # Pi-hole + Unbound
│   ├── tor.yml               # Tor SOCKS5-Proxy
│   ├── websurfx.yml          # Metasuchmaschine
│   ├── ollama.yml            # Lokale LLM-Engine
│   ├── open-webui.yml        # KI-Chat-Oberfläche (Port 3002)
│   ├── hermes.yml            # KI-Chat (Port 3000, Docker)
│   ├── n8n.yml               # Workflow-Automation (Port 5678)
│   ├── jellyfin.yml          # Mediathek
│   ├── sonarr.yml            # Serien-Automatisierung
│   ├── radarr.yml            # Film-Automatisierung
│   ├── prowlarr.yml          # Indexer-Manager
│   ├── bazarr.yml            # Untertitel
│   ├── sabnzbd.yml           # Download-Client
│   ├── syncthing.yml         # Datei-Sync
│   ├── nextcloud.yml         # Cloud
│   ├── uptime-kuma.yml       # Monitoring
│   ├── heimdall.yml          # Dashboard
│   ├── teamspeak.yml         # Sprachserver (Port 9987)
│   ├── amp.yml               # Game-Server-Manager (Port 8087)
│   └── caddy.yml             # Reverse Proxy
├── cloud-init/               # Automatische Provisionierung
│   └── user-data.example
├── config/                   # Konfigurationsdateien
│   ├── dns/unbound.conf
│   ├── websurfx/config.lua
│   ├── caddy/Caddyfile
│   └── ssh/client-config
├── docs/                     # Dokumentation
│   ├── architecture.md
│   ├── bootstrap-flow.md
│   └── cloud-init-flow.md
├── scripts/                  # Utility-Scripts
│   ├── update-all.sh         # Update-All
│   ├── backup-all.sh         # Backup-All
│   ├── health-check.sh       # Status-Prüfung
│   ├── dnssec-test.sh        # DNSSEC-Validierung
│   ├── setup-cron.sh         # Cron-Jobs einrichten
│   ├── restart-service.sh    # Einzeldienst neustarten
│   └── logs.sh               # Logs anzeigen
├── ai-agent/                 # KI-Assistent
│   ├── .env.example          # Konfigurationsvorlage
│   ├── telegram-bot.py       # Telegram Bot
│   ├── daily_briefing.py     # Tägliche Zusammenfassung
│   ├── server_commands.py    # SSH-Homelab-Commands
│   └── requirements.txt      # Python-Dependencies
└── README.md
```

## Nützliche Befehle

```bash
# Status prüfen
~/scripts/health-check.sh

# Alles updaten
~/scripts/update-all.sh

# Backup erstellen
~/scripts/backup-all.sh

# Dienst neustarten
~/scripts/restart-service.sh jellyfin

# Logs anzeigen
~/scripts/logs.sh pihole -f

# In Container einsteigen
docker exec -it ollama sh

# Firewall-Status
sudo ufw status numbered

# System-Ressourcen
htop
```

## Sicherheit

| Maßnahme | Status |
|---|---|
| SSH-Key-Authentifizierung | ✅ Automatisch |
| PasswordAuthentication no | ✅ Automatisch |
| PermitRootLogin no | ✅ Automatisch |
| UFW Firewall | ✅ Automatisch (LAN-Whitelist) |
| Fail2Ban | ✅ Installiert |
| Unattended-Upgrades | ✅ Aktiviert |
| DNSSEC | ✅ Aktiviert (Pi-hole) |
| WireGuard VPN | Optional (PiVPN) |
| Tailscale VPN | Optional (Zero-Config) |
| Cron-Jobs (Update/Backup) | ✅ Automatisch |
| Samba-Passwortschutz | ✅ Aktiviert |

## Hardware-Empfehlung

| Komponente | Empfehlung | Preis (ca.) |
|---|---|---|
| **Mini-PC** | Dell OptiPlex 7080 (i7-10700, 32GB, 1TB NVMe) | 320–380€ |
| **Alternative** | Intel NUC 13 Pro (i7, 32GB, 1TB) | 500–700€ |
| **NAS (optional)** | Synology DS224+ (Backup-Ziel) | 300€ |
| **Stromverbrauch** | ca. 15–30W im Idle | ~40€/Jahr |

## Lizenz

MIT – siehe [LICENSE](LICENSE).

---

*Bootstreep Homelab v3.5.0*
