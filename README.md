# Bootstreep Homelab 🚀

**Privacy-First Homelab – Ein Befehl, 20+ Dienste, lokale KI**

```bash
chmod +x bootstrap.sh && ./bootstrap.sh
```

---

## 🎯 Features

- **Privacy-First**: DNS-over-HTTPS, Tor-Proxy, lokale KI (keine Cloud)
- **Keine Telemetrie**: Ubuntu whoopsie, Open WebUI, Vaultwarden aus
- **Hardened**: SSH-Key-only, Fail2Ban, UFW, AppArmor, Docker, Kernel sysctl
- **Performance**: TCP BBR, FastOpen, zram, I/O-Optimierung, Parallel-Start
- **Lokale KI**: Ollama + Open WebUI + Hermes (Mistral, Llama, DeepSeek, Phi)
- **Self-Hosted Cloud**: Nextcloud + Syncthing
- **Media-Stack**: Jellyfin + Sonarr/Radarr/Prowlarr/Bazarr + SABnzbd
- **VPN**: WireGuard (PiVPN) oder Tailscale
- **Monitoring**: Uptime Kuma + AI-Agent (Telegram)
- **20+ Container**: alles per `INSTALL_PROFILE=...` wählbar

---

## 📊 Profile

| Profil | Was wird installiert |
|--------|----------------------|
| `full` | Alle 20+ Dienste (Standard) |
| `minimal` | DNS + Cloud + Media + Zugriff |
| `media` | DNS + Media + Zugriff + VPN |
| `ai` | System + DNS + KI + AI-Agent |
| `privacy` | Full + maximale Privacy-Einstellungen |

---

## 🚀 Schnellstart

```bash
# SSH-Key hinterlegen (auf deinem PC):
ssh-keygen -t ed25519 -C "homelab"
ssh-copy-id -i ~/.ssh/id_ed25519.pub admin@SERVER_IP

# Bootstrap (auf dem Server):
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
chmod +x bootstrap.sh

# Standard:
./bootstrap.sh

# Oder mit Profil:
INSTALL_PROFILE=privacy PIHOLE_PASS="meinSicheresPass123!" ./bootstrap.sh
```

### Nach Setup

```bash
~/scripts/health-check.sh      # Status
~/scripts/dnssec-test.sh       # DNSSEC prüfen
nano ~/ai-agent/.env            # Telegram-Token
sudo systemctl start ai-agent
```

---

## 🌐 Dienste (Standard-Ports)

| Dienst | Port | Beschreibung |
|--------|------|-------------|
| Caddy | 80, 443 | Reverse Proxy + Dashboard |
| Pi-hole | 8081 | DNS-Werbeblocker |
| Unbound | 5335 (intern) | DoH-Resolver |
| Jellyfin | 8096 | Media-Streaming |
| Nextcloud | 8082 | Self-hosted Cloud |
| Sonarr | 8989 | Serien |
| Radarr | 7878 | Filme |
| Prowlarr | 9696 | Indexer |
| Bazarr | 6767 | Untertitel |
| SABnzbd | 8085 | Downloads |
| Ollama | 11434 (intern) | Lokale KI |
| Open WebUI | 3002 | KI-Chat |
| Hermes | 3000 | KI-Chat (alt.) |
| Syncthing | 8384 | P2P-Sync |
| n8n | 5678 | Workflows |
| Heimdall | 8090 | Dashboard |
| Uptime Kuma | 3001 | Monitoring |
| TeamSpeak | 9987 | Voice |
| AMP | 8087 | Game-Server |
| Websurfx | 8080 | Meta-Suche (Tor) |
| Vaultwarden | 8093 | Passwörter |
| Watchtower | - | Auto-Updates |

---

## 🛡️ Privacy + Security

| Feature | Wo |
|---------|-----|
| DNS-over-HTTPS | Unbound → Cloudflare/Quad9 |
| Werbeblocker | Pi-hole (5 Listen) |
| DNSSEC | Pi-hole + Unbound (strikt) |
| Tor-Proxy | SOCKS5 auf 127.0.0.1:9050 |
| IPv6 deaktiviert | Docker + Kernel sysctl |
| Lokale KI | Ollama (kein Cloud-Call) |
| Keine Telemetrie | Ubuntu, Open WebUI, Vaultwarden, Watchtower |
| Kernel Härtung | rp_filter, syncookies, martians, BBR |
| Gehärtete SSH | Nur Ed25519, starke Algorithmen, RekeyLimit |
| Fail2Ban | SSH + Recidive |
| AppArmor | aktiviert |
| Log-Sanitierung | IP-Anonymisierung (wöchentlich) |
| Backup-GPG | Optional für .env |

---

## ⚡ Performance

| Optimierung | Detail |
|------------|--------|
| TCP BBR | bbr + fq qdisc (Höherer Durchsatz) |
| TCP FastOpen | Reduziert Latenz |
| zram Swap | 50% RAM als komprimierter Swap |
| I/O noatime | Reduziert Disk-Writes |
| swappiness=10 | Weniger Swap, mehr Cache |
| Docker Parallel | dc_up_parallel() für unabhängige Services |
| Ollama Concurrent | 4 parallele Requests, 2 Modelle |
| Caddy Compression | Gzip/Brotli, Cache-Header |
| Systemd Timer | Genauere Planung als Cron |

---

## 📁 Struktur

```
bootstreep-homelab/
├── bootstrap.sh              # Master-Script (17 Sections)
├── docker-compose-all.yml    # Alle Dienste merged
├── compose/                  # 24 Compose-Files
├── scripts/                  # 10 Utility-Scripts
├── config/                   # 4 Konfigurationen
├── ai-agent/                 # Telegram-Bot (14 Commands)
├── .github/workflows/        # CI (5 Jobs)
└── ...
```

---

## 🤖 AI-Agent (Telegram)

- 14 Befehle: `/status /services /restart /logs /update /backup /health /df /network /dns /ask /briefing /start /help`
- Command-Whitelist, `shell=False`, ALLOWED_CHAT_IDS erforderlich
- Lokale Ollama-KI (keine Cloud)

---

## 🔒 Sicherheit

- SSH: Nur Ed25519-Keys, keine Passwörter, RekeyLimit
- UFW: Nur LAN-Zugriff, Rate-Limiting
- Fail2Ban: 3 Versuche → 1h Ban (Recidive: 1 Woche)
- Docker: no-new-privileges, cap_drop: ALL, seccomp
- Kernel: rp_filter, syncookies, martians
- Updates: Sonntag 3:00 (System) + Watchtower (Container)

---

## 📜 Lizenz

MIT – siehe LICENSE.

**Bootstreep Homelab v3.13.0 – Privacy-First • Local AI • No Telemetry**
