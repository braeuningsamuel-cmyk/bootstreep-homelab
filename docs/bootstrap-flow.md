# Bootstrap Flow

## Übersicht

Der Bootstrap-Prozess automatisiert die gesamte Einrichtung eines Homelab-Servers.
Das Script `bootstrap.sh` ist der zentrale Einstiegspunkt.

## Ablauf

```
bootstrap.sh starten
    │
    ├── 1. System-Grundlagen (apt update, Pakete, Zeitzone)
    ├── 2. Docker-Installation (Engine, Compose, Netzwerk)
    ├── 3. SSH-Härtung (PasswordAuth no, RootLogin no, Client-Config)
    ├── 4. Firewall (UFW, LAN-Whitelist, Samba, WireGuard)
    ├── 5. DNS (Pi-hole + Unbound, Adlists, DNSSEC-Test)
    ├── 6. Tor + Websurfx (Privatsphäre)
    ├── 7. KI (Ollama + Modelle + Hermes + Open WebUI)
    ├── 8. Medien (Jellyfin + SABnzbd + Arr-Stack)
    ├── 9. Cloud (Nextcloud AIO + Syncthing)
    ├── 10. Zugriff (Samba + Uptime Kuma + Caddy + Cron)
    ├── 11. WireGuard VPN + Tailscale
    ├── 12. AI Agent (Telegram Bot)
    └── 13. NVIDIA GPU (optional)
```

## Fortschrittsverfolgung

Das Script verwendet eine Marker-Datei `~/.bootstrap-progress`:

```
STEP1=done
STEP2=done
STEP3=done
...
```

Bei erneutem Start werden bereits erledigte Schritte übersprungen.
Das ermöglicht:
- **Wiederaufnahme nach Neustart** (z.B. nach Step 1)
- **Gezieltes Überspringen** durch Setzen von Variablen
- **Erneutes Ausführen einzelner Schritte** durch Löschen der Marker

## Variablen

Vor Ausführung können folgende Variablen gesetzt werden:

| Variable | Standard | Beschreibung |
|---|---|---|
| `SERVER_IP` | `192.168.178.20` | Statische IP des Servers |
| `PIHOLE_PASS` | `admin` | Pi-hole Web-Passwort |
| `TIMEZONE` | `Europe/Berlin` | Zeitzone |
| `SKIP_AI_AGENT` | `false` | KI-Assistent überspringen |

Beispiel:
```bash
SERVER_IP=10.0.0.50 PIHOLE_PASS="geheim" ./bootstrap.sh
```

## Cloud-Init (vollautomatisch)

Für vollautomatische Provisionierung (z.B. Proxmox, libvirt):
1. `cloud-init/user-data.example` anpassen
2. Als `user-data` bei VM-Erstellung angeben
3. System installiert sich selbstständig

Siehe: `docs/cloud-init-flow.md`

## Manuelle Wiederherstellung

Falls der Server neu aufgesetzt werden muss:
```bash
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
./bootstrap.sh
```
