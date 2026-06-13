# Architecture

## Overview

Das Atlas.Lab Homelab Bootstrap besteht aus mehreren Schichten, die zusammen ein vollständiges Homelab auf Ubuntu 24.04 aufbauen.

## Layers

### Layer 0: Hardware & OS
- Ubuntu 24.04 LTS (minimal server)
- Empfohlen: Dell OptiPlex 7080 (i7-10700, 32GB RAM, 1TB NVMe)
- Statische IP im LAN (z.B. 192.168.178.20)

### Layer 1: System-Grundlagen
- SSH-Härtung (PasswordAuthentication no, PermitRootLogin no)
- UFW Firewall mit LAN-Whitelist
- Fail2Ban, unattended-upgrades
- Docker Engine + Docker Compose
- Docker-Netzwerk `homelab` (Bridge)

### Layer 2: Docker-Services
Alle Dienste laufen als Docker-Container im `homelab` Netzwerk:

```
┌─────────────┐     ┌──────────────┐
│  Internet    │────▶│  Caddy       │
│  (FritzBox)  │     │  :80/:443    │
└─────────────┘     └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────▼────┐ ┌────▼────┐ ┌────▼────┐
        │ Pi-hole  │ │  Tor    │ │ Ollama  │
        │ :53/8081 │ │ :9050   │ │ :11434  │
        └─────┬────┘ └─────────┘ └────┬────┘
              │                       │
        ┌─────▼────┐           ┌──────▼──────┐
        │ Unbound  │           │ Open WebUI  │
        │ :5335    │           │ :3002       │
        └──────────┘           └─────────────┘

┌─────────────┐  ┌──────────────────┐  ┌──────────────┐
│  Jellyfin   │  │  Arr-Stack       │  │  Nextcloud   │
│  :8096      │  │  :8989/7878/..   │  │  :8082       │
└─────────────┘  └──────────────────┘  └──────────────┘

┌─────────────┐  ┌─────────────┐  ┌──────────────┐
│  Syncthing  │  │  SABnzbd    │  │  Uptime Kuma │
│  :8384      │  │  :8085      │  │  :3001       │
└─────────────┘  └─────────────┘  └──────────────┘

┌─────────────┐  ┌─────────────┐  ┌──────────────┐
│  n8n        │  │  Samba      │  │  WireGuard   │
│  :5678      │  │  :445       │  │  :51820/udp  │
└─────────────┘  └─────────────┘  └──────────────┘
```

### Layer 3: KI-Assistent (AI Agent)
- Telegram Bot (Python, python-telegram-bot v21+)
- Ollama-Integration für `/ask`
- Daily Briefing (Wetter, Aktien, News, E-Mail, Kalender)
- Systemd-Service mit Autostart

### Layer 4: Automatisierung & Wartung
- `bootstrap.sh` – Ein Befehl, fertiges Homelab
- `scripts/update-all.sh` – Wöchentliches Update
- `scripts/backup-all.sh` – Backup aller Konfigurationen
- `scripts/health-check.sh` – Status-Überwachung
- Cron-Jobs für automatische Wartung
- Cloud-Init Support für vollautomatische Provisionierung

## DNS-Architektur

```
FritzBox (192.168.178.1)
    │
    │ DNS-Anfrage an Server (192.168.178.20)
    ▼
Pi-hole (Port 53) – Werbeblocker + DNS-Server
    │
    │ Weiterleitung an Unbound
    ▼
Unbound (Port 5335) – Recursiver Resolver mit DNSSEC
    │
    │ Direkte Auflösung bei Root-Servern
    ▼
Internet (DNS-over-UDP, keine Third-Party-DNS)
```

## Medien-Workflow

```
Usenet / Torrent
    │
    ▼
SABnzbd (:8085) – Download-Client
    │
    ├──► Sonarr (:8989) – Serien-Verwaltung
    │       │
    │       ▼
    │   Jellyfin (:8096) – Mediathek
    │
    ├──► Radarr (:7878) – Film-Verwaltung
    │       │
    │       ▼
    │   Jellyfin (:8096)
    │
    ├──► Prowlarr (:9696) – Indexer-Manager
    │
    └──► Bazarr (:6767) – Untertitel
```

## Sicherheits-Architektur

```
Internet ───► UFW Firewall ───► SSH (Port 22, nur Key)
    │              │
    │              ├──► Caddy (Port 80/443)
    │              │       │
    │              │       └──► Reverse Proxy zu Web-Interfaces
    │              │
    │              ├──► WireGuard (Port 51820/udp)
    │              │
    │              └──► Samba (Port 445, LAN only)
    │
    └──► Fail2Ban (brute-force Schutz)
    └──► unattended-upgrades (automatische Sicherheits-Updates)
    └──► DNSSEC (Pi-hole + Unbound)
```
