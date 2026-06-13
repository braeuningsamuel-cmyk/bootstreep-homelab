#!/bin/bash
set -euo pipefail

# =============================================================================
# Atlas.Lab Homelab Bootstrap v3.3
# Für Ubuntu 24.04 LTS – Ein Befehl, fertiges Homelab
#
# Usage:
#   chmod +x bootstrap.sh && ./bootstrap.sh
#
# Optional: Variablen vor Ausführung setzen:
#   SERVER_IP=192.168.178.20     # Statische IP deines Servers
#   PIHOLE_PASS="mein-passwort"  # Pi-hole Web-Interface Passwort
#   TIMEZONE="Europe/Berlin"     # Zeitzone
#   SKIP_AI_AGENT=false          # KI-Assistent (Telegram Bot) überspringen
# =============================================================================

# ─── Konfiguration ────────────────────────────────────────────────────────────
SERVER_IP="${SERVER_IP:-192.168.178.20}"
PIHOLE_PASS="${PIHOLE_PASS:-admin}"
TIMEZONE="${TIMEZONE:-Europe/Berlin}"
SKIP_AI_AGENT="${SKIP_AI_AGENT:-false}"
USER="${USER:-$(whoami)}"
HOME_DIR="${HOME:-/home/$USER}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${CYAN}[i]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }

# ─── Docker-Helfer mit Retry ────────────────────────────────────────────────
dc_up() {
    local dir="$1"
    local name="$2"
    local max_attempts=3
    local attempt=1
    while [ "$attempt" -le "$max_attempts" ]; do
        if cd ~/docker/"$dir" && docker compose up -d 2>/dev/null; then
            log "$name gestartet."
            return 0
        fi
        warn "$name: Startversuch $attempt/$max_attempts fehlgeschlagen – warte 5s..."
        sleep 5
        attempt=$((attempt + 1))
    done
    err "$name konnte nach $max_attempts Versuchen nicht gestartet werden."
    return 1
}

info "Atlas.Lab Homelab Bootstrap v3.3"
info "Server-IP: $SERVER_IP"
info "Zeitzone:  $TIMEZONE"
echo ""

# ─── Pre-Flight Checks ──────────────────────────────────────────────────────
pre_flight_checks() {
    local errors=0

    if [ "$EUID" -eq 0 ]; then
        err "Bitte nicht als root ausführen. Der Script verwendet sudo bei Bedarf."
        errors=$((errors + 1))
    fi

    if ! echo "$SERVER_IP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'; then
        err "SERVER_IP='$SERVER_IP' ist keine gültige IP-Adresse."
        errors=$((errors + 1))
    fi

    for cmd in curl git wget; do
        if ! command -v "$cmd" &>/dev/null; then
            warn "'$cmd' nicht gefunden – wird in Step 1 installiert."
        fi
    done

    # Speicherplatz prüfen (mindestens 20GB frei)
    local available
    available=$(df / --output=avail 2>/dev/null | tail -1)
    if [ -n "$available" ] && [ "$available" -lt 20971520 ]; then
        warn "Weniger als 20GB freier Speicher ($((available / 1024 / 1024)) GB) – Modell-Downloads könnten fehlschlagen."
    fi

    if [ "$errors" -gt 0 ]; then
        err "$errors Fehler gefunden. Script wird abgebrochen."
        exit 1
    fi

    log "Pre-Flight Checks bestanden."
}
pre_flight_checks

echo ""

# ─── 1. SYSTEM-GRUNDLAGEN ─────────────────────────────────────────────────────
section_1_system() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  1.  SYSTEM-GRUNDLAGEN                            ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "Paketquellen aktualisieren..."
    sudo apt update -y 2>&1 | tail -3 || warn "apt update hatte Warnungen"
    sudo apt upgrade -y 2>&1 | tail -5 || warn "apt upgrade hatte Warnungen"

    log "Wichtige Pakete installieren..."
    sudo apt install -y curl git wget htop nano ufw fail2ban \
        unattended-upgrades ca-certificates gnupg lsb-release \
        net-tools iperf3 smartmontools dnsutils nodejs npm 2>&1 | tail -3

    log "Zeitzone setzen: $TIMEZONE"
    sudo timedatectl set-timezone "$TIMEZONE" 2>/dev/null || warn "Zeitzone konnte nicht gesetzt werden"

    log "Unattended-Upgrades konfigurieren..."
    sudo dpkg-reconfigure --priority=low unattended-upgrades 2>/dev/null || true

    # Fortschritt speichern VOR möglichem Neustart
    echo "STEP1=done" >> "$HOME_DIR/.bootstrap-progress" 2>/dev/null || true

    echo ""
    warn "System-Upgrade abgeschlossen. Ein Neustart wird empfohlen."
    warn "→ Nach dem Neustart bootstrap.sh erneut starten (erkennt bereits erledigte Schritte)."
    echo ""
    read -rp "Jetzt neu starten? (y/N): " reboot_now
    if [ "$reboot_now" = "y" ] || [ "$reboot_now" = "Y" ]; then
        log "Neustart wird durchgeführt..."
        sudo reboot
    fi
}

# ─── 2. DOCKER-INSTALLATION ───────────────────────────────────────────────────
section_2_docker() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  2.  DOCKER-INSTALLATION                          ║"
    echo "╚══════════════════════════════════════════════════╝"

    if command -v docker &>/dev/null; then
        log "Docker bereits installiert – überspringe."
    else
        log "Docker Engine installieren..."
        curl -fsSL https://get.docker.com | sudo sh
    fi

    if groups "$USER" | grep -q docker; then
        log "Benutzer $USER bereits in docker-Gruppe."
    else
        sudo usermod -aG docker "$USER"
        warn "Benutzer $USER wurde zur docker-Gruppe hinzugefügt."
        warn "→ Für Docker-Zugriff: 'newgrp docker' in neuer Shell oder aus-/einloggen."
    fi

    log "Docker Compose Version:"
    docker compose version

    if docker network inspect homelab &>/dev/null 2>&1; then
        log "Docker-Netzwerk 'homelab' existiert bereits."
    else
        log "Docker-Netzwerk 'homelab' erstellen..."
        docker network create homelab
    fi

    log "Docker-Verzeichnisstruktur anlegen..."
    mkdir -p ~/docker
    for dir in dns tor websurfx ollama open-webui jellyfin sabnzbd n8n sonarr radarr prowlarr bazarr \
               syncthing nextcloud uptime-kuma caddy hermes heimdall; do
        mkdir -p ~/docker/"$dir"
    done
}

# ─── 3. SSH-HÄRTUNG ───────────────────────────────────────────────────────────
section_3_ssh_harden() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  3.  SSH-HÄRTUNG                                  ║"
    echo "╚══════════════════════════════════════════════════╝"

    SSH_CFG="/etc/ssh/sshd_config"

    if grep -q "^PasswordAuthentication no" "$SSH_CFG" 2>/dev/null; then
        log "SSH bereits gehärtet."
        return
    fi

    warn "SSH-Konfiguration wird angepasst: PasswordAuthentication no, PermitRootLogin no"
    sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' "$SSH_CFG"
    sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "$SSH_CFG"
    if ! grep -q "^PasswordAuthentication no" "$SSH_CFG"; then
        echo "PasswordAuthentication no" | sudo tee -a "$SSH_CFG" >/dev/null
    fi

    sudo sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' "$SSH_CFG"
    sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' "$SSH_CFG"
    if ! grep -q "^PermitRootLogin no" "$SSH_CFG"; then
        echo "PermitRootLogin no" | sudo tee -a "$SSH_CFG" >/dev/null
    fi

    sudo systemctl restart ssh
    log "SSH-Dienst neugestartet."

    log "SSH-Client-Konfiguration bereitstellen..."
    mkdir -p ~/.ssh
    if [ ! -f ~/.ssh/config ] || ! grep -q "Host homelab" ~/.ssh/config 2>/dev/null; then
        cp config/ssh/client-config ~/.ssh/config
        sed -i "s/192\.168\.178\.20/$SERVER_IP/g" ~/.ssh/config
        chmod 600 ~/.ssh/config
        log "→ ~/.ssh/config eingerichtet (Host homelab → $SERVER_IP)."
    else
        log "SSH-Client-Konfiguration existiert bereits."
    fi

    warn "WICHTIG: Stelle sicher, dass du deinen SSH-Key hinterlegt hast:"
    warn "  ssh-copy-id -i ~/.ssh/id_ed25519.pub $USER@$SERVER_IP"
    warn "→ Erst NACH dem Testen in einer NEUEN Session die SSH-Verbindung schließen!"
}

# ─── 4. FIREWALL (UFW) ───────────────────────────────────────────────────────
section_4_firewall() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  4.  FIREWALL (UFW)                               ║"
    echo "╚══════════════════════════════════════════════════╝"

    if sudo ufw status | grep -q "active"; then
        log "UFW ist bereits aktiv."
        return
    fi

    log "UFW-Regeln setzen..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh

    # LAN-Zugriff auf Web-Interfaces
    sudo ufw allow from 192.168.0.0/16 to any port 8081,8082,8096,3000,3001,8087,8384,8989,7878,9696,6767

    # Samba-Netzwerkfreigabe
    sudo ufw allow 445/tcp

    # WireGuard VPN
    sudo ufw allow 51820/udp

    log "UFW aktivieren..."
    sudo ufw --force enable
    sudo ufw status numbered
}

# ─── 5. DNS (Pi-hole + Unbound) ──────────────────────────────────────────────
section_5_dns() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  5.  DNS (Pi-hole + Unbound)                      ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "Systemd-resolved deaktivieren (Port 53 freigeben)..."
    sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    sudo systemctl restart systemd-resolved

    log "DNS-Verzeichnisse anlegen..."
    mkdir -p ~/docker/dns/etc-pihole ~/docker/dns/etc-dnsmasq.d

    log "Unbound-Konfiguration bereitstellen..."
    cp config/dns/unbound.conf ~/docker/dns/unbound.conf

    log "DNS-Compose-Datei bereitstellen..."
    cp compose/dns.yml ~/docker/dns/compose.yml

    log "DNS-Container starten..."
    cd ~/docker/dns && docker compose up -d

    log "Warte auf Pi-hole (max 30s)..."
    local pihole_ready=0
    for i in $(seq 1 30); do
        if docker exec pihole pihole status 2>/dev/null | grep -qi "online\|running\|aktiv"; then
            pihole_ready=1
            break
        fi
        sleep 1
    done
    [ "$pihole_ready" -eq 1 ] && log "Pi-hole ist bereit" || warn "Pi-hole wurde nicht rechtzeitig fertig"

    log "Pi-hole Adlists konfigurieren..."
    docker exec pihole sh -c "echo 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts' > /etc/pihole/adlists.list" 2>/dev/null || true
    docker exec pihole sh -c "echo 'https://big.oisd.nl/' >> /etc/pihole/adlists.list" 2>/dev/null || true
    docker exec pihole pihole -g 2>/dev/null || warn "Gravity-Update fehlgeschlagen"

    log "DNSSEC-Test durchführen..."
    sleep 2
    if dig sigfail.verteiltesysteme.net @127.0.0.1 +short 2>/dev/null | grep -q "192.168.178.1"; then
        warn "DNSSEC sigfail erwartet: kein Ergebnis – alles gut (DNSSEC blockiert korrekt)"
    fi
    if dig sigok.verteiltesysteme.net @127.0.0.1 +short 2>/dev/null | grep -q "134.91.78.139"; then
        log "DNSSEC-Validierung funktioniert (sigok aufgelöst)"
    else
        warn "DNSSEC-Test sigok fehlgeschlagen – ggf. Propagation abwarten"
    fi
}

# ─── 6. TOR + WEBSURFX (PRIVATSPHÄRE) ────────────────────────────────────────
section_6_privacy() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  6.  TOR + WEBSURFX (PRIVATSPHÄRE)                ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "Tor-SOCKS5-Proxy starten..."
    cp compose/tor.yml ~/docker/tor/compose.yml
    cd ~/docker/tor && docker compose up -d

    log "Websurfx bauen und starten..."
    if [ ! -d ~/docker/websurfx/src ]; then
        git clone https://github.com/neon-mmd/websurfx.git ~/docker/websurfx/src
    fi
    cp config/websurfx/config.lua ~/docker/websurfx/src/config.lua

    if docker image inspect websurfx:local &>/dev/null 2>&1; then
        log "Websurfx-Image bereits gebaut."
    else
        cd ~/docker/websurfx/src && docker build -t websurfx:local .
    fi

    cp compose/websurfx.yml ~/docker/websurfx/compose.yml
    cd ~/docker/websurfx && docker compose up -d
}

# ─── 7. OLLAMA + HERMES (KI) ────────────────────────────────────────────────
section_7_ai() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  7.  OLLAMA + HERMES (LOKALE KI)                  ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "Ollama starten..."
    cp compose/ollama.yml ~/docker/ollama/compose.yml
    cd ~/docker/ollama && docker compose up -d

    log "KI-Modelle herunterladen (ca. 15–25 Min)..."
    docker exec ollama ollama pull mistral:7b 2>/dev/null || true
    docker exec ollama ollama pull llama3.2:3b 2>/dev/null || true
    docker exec ollama ollama pull deepseek-coder:6.7b 2>/dev/null || true
    docker exec ollama ollama pull llama3.2:8b 2>/dev/null || true
    docker exec ollama ollama pull phi4:14b 2>/dev/null || true

    log "Hermes KI-Chat-Oberfläche per Docker starten..."
    if [ ! -d ~/hermes ]; then
        git clone https://github.com/Hermes-Project/hermes.git ~/hermes
        cp ~/hermes/.env.example ~/hermes/.env
        log "→ .env-Datei in ~/hermes/.env – ggf. API-Keys eintragen."
    fi
    cp compose/hermes.yml ~/docker/hermes/compose.yml
    cd ~/docker/hermes && docker compose up -d
    log "→ Hermes läuft auf http://$SERVER_IP:3000"

    log "Open WebUI (alternative Chat-Oberfläche) starten..."
    cp compose/open-webui.yml ~/docker/open-webui/compose.yml
    cd ~/docker/open-webui && docker compose up -d
    log "→ Open WebUI läuft auf http://$SERVER_IP:3002"
}

# ─── 8. JELLYFIN + ARR-STACK (MEDIEN) ────────────────────────────────────────
section_8_media() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  8.  JELLYFIN + ARR-STACK (MEDIATHEK)             ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "Medienverzeichnisse anlegen..."
    mkdir -p ~/media/{movies,series,music,photos,books}
    mkdir -p ~/downloads/{complete,incomplete}

    log "Jellyfin starten..."
    cp compose/jellyfin.yml ~/docker/jellyfin/compose.yml
    cd ~/docker/jellyfin && docker compose up -d

    log "Download-Client (SABnzbd) starten..."
    cp compose/sabnzbd.yml ~/docker/sabnzbd/compose.yml
    cd ~/docker/sabnzbd && docker compose up -d

    log "Arr-Stack starten (Sonarr, Radarr, Prowlarr, Bazarr)..."
    for service in sonarr radarr prowlarr bazarr; do
        cp "compose/$service.yml" ~/docker/"$service"/compose.yml
        cd ~/docker/"$service" && docker compose up -d
    done

    log "n8n Workflow-Automation starten..."
    cp compose/n8n.yml ~/docker/n8n/compose.yml
    cd ~/docker/n8n && docker compose up -d
}

# ─── 9. NEXTCLOUD + SYNCTHING (CLOUD + SYNC) ────────────────────────────────
section_9_cloud() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  9.  NEXTCLOUD + SYNCTHING (CLOUD & SYNC)         ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "Nextcloud AIO starten..."
    sudo mkdir -p /opt/nextcloud-data
    sudo chown -R "$USER":"$USER" /opt/nextcloud-data

    cp compose/nextcloud.yml ~/docker/nextcloud/compose.yml
    cd ~/docker/nextcloud && docker compose up -d

    log "Nextcloud-Passwort abrufen..."
    docker logs nextcloud-aio 2>&1 | grep "password" || warn "Initialpasswort prüfen: docker logs nextcloud-aio"

    log "Syncthing starten..."
    cp compose/syncthing.yml ~/docker/syncthing/compose.yml
    cd ~/docker/syncthing && docker compose up -d
}

# ─── 10. SAMBA + GAMES + VPN (ZUGRIFF) ───────────────────────────────────────
section_10_access() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 10.  SAMBA + GAMES + VPN (ZUGRIFF)                ║"
    echo "╚══════════════════════════════════════════════════╝"

    # SAMBA
    log "Samba-Netzwerkfreigabe einrichten..."
    if ! command -v samba &>/dev/null; then
        sudo apt install samba -y
    fi

    SMB_CONF="/etc/samba/smb.conf"
    if ! grep -q "^\[media\]" "$SMB_CONF" 2>/dev/null; then
        cat <<EOSMB | sudo tee -a "$SMB_CONF" >/dev/null

[media]
   path = $HOME_DIR/media
   browseable = yes
   read only = no
   guest ok = no
   valid users = $USER
   force user = $USER
EOSMB
        sudo smbpasswd -a "$USER" 2>/dev/null || warn "Samba-Passwort bereits gesetzt."
        sudo systemctl restart smbd
        log "Samba läuft. Zugriff: \\\\$SERVER_IP\\media"
    else
        log "Samba-Freigabe [media] existiert bereits."
    fi

    # Uptime Kuma
    log "Uptime Kuma (Monitoring) starten..."
    cp compose/uptime-kuma.yml ~/docker/uptime-kuma/compose.yml
    cd ~/docker/uptime-kuma && docker compose up -d

    # Heimdall Dashboard
    log "Heimdall Dashboard starten..."
    cp compose/heimdall.yml ~/docker/heimdall/compose.yml
    cd ~/docker/heimdall && docker compose up -d

    # Cron-Jobs für automatisierte Wartung
    log "Cron-Jobs einrichten..."
    (crontab -l 2>/dev/null | grep -q "update-all.sh") && log "Cron-Jobs bereits vorhanden." || {
        (crontab -l 2>/dev/null; echo "0 3 * * 0 $HOME_DIR/scripts/update-all.sh >/dev/null 2>&1") | crontab -
        (crontab -l 2>/dev/null; echo "0 4 * * 0 $HOME_DIR/scripts/backup-all.sh >/dev/null 2>&1") | crontab -
        (crontab -l 2>/dev/null; echo "*/30 * * * * $HOME_DIR/scripts/health-check.sh >/dev/null 2>&1") | crontab -
        log "→ Wöchentliches Update (So 3 Uhr), Backup (So 4 Uhr), Health-Check (alle 30 Min)"
    }

    # Caddy Reverse Proxy
    log "Caddy Reverse-Proxy starten..."
    cp compose/caddy.yml ~/docker/caddy/compose.yml
    cp config/caddy/Caddyfile ~/docker/caddy/Caddyfile 2>/dev/null || true
    cd ~/docker/caddy && docker compose up -d

    warn "Game-Server (AMP) manuell installieren:"
    warn "  bash <(wget -qO- https://getamp.sh)"
    warn "  → Docker=yes, Minecraft=yes, Steam=yes"
    warn "  → Web-UI: http://$SERVER_IP:8087"
    warn ""

    warn "Playit.gg (Tunnel) manuell:"
    warn "  curl -SsL https://playit.cloud/install.sh | bash"
}

# ─── 11. WIREGUARD VPN ───────────────────────────────────────────────────────
section_11_wireguard() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 11.  WIREGUARD VPN (PIVPN)                        ║"
    echo "╚══════════════════════════════════════════════════╝"

    if command -v pivpn &>/dev/null; then
        log "PiVPN ist bereits installiert."
        return
    fi

    warn "PiVPN / WireGuard interaktiv installieren:"
    warn "  curl -L https://install.pivpn.io | bash"
    warn "  → WireGuard auswählen, DNS: $SERVER_IP, Port: 51820 UDP"
    warn "  → Nach Installation: pivpn add && pivpn -qr"
    echo ""
    warn "Alternativ: Tailscale (einfacher, kein Port-Forwarding nötig):"
    warn "  curl -fsSL https://tailscale.com/install.sh | sh"
    warn "  sudo tailscale up"
    warn "  → Verbindung zu deinem Tailscale-Netzwerk (tailscale.com)"
}

# ─── 13. GPU/NVIDIA (OPTIONAL) ──────────────────────────────────────────────
section_13_gpu() {
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║    OPTIONAL: GPU/NVIDIA-TREIBER                   ║"
    echo "╚══════════════════════════════════════════════════╝"

    warn "NVIDIA-GPU-Treiber werden NICHT automatisch installiert."
    warn "Falls du eine NVIDIA-GPU für Ollama/Jellyfin nutzen willst:"
    echo ""
    warn "  sudo apt install -y nvidia-driver-535 nvidia-container-toolkit"
    warn "  sudo reboot"
    warn ""
    warn "Nach Installation: docker compose -f ~/docker/ollama/compose.yml up -d"
    echo ""
    read -rp "Jetzt NVIDIA-Treiber installieren? (y/N): " install_nvidia
    if [ "$install_nvidia" = "y" ] || [ "$install_nvidia" = "Y" ]; then
        sudo apt install -y nvidia-driver-535 nvidia-container-toolkit
        log "NVIDIA-Treiber installiert. Neustart erforderlich."
        read -rp "Jetzt neu starten? (y/N): " reboot_nvidia
        [ "$reboot_nvidia" = "y" ] || [ "$reboot_nvidia" = "Y" ] && sudo reboot
    fi
}

# ─── 12. AI AGENT (TELEGRAM BOT + ASSISTANT) ─────────────────────────────────
section_12_ai_agent() {
    if [ "$SKIP_AI_AGENT" = "true" ]; then
        info "AI Agent übersprungen (SKIP_AI_AGENT=true)."
        return
    fi

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 12.  AI AGENT (TELEGRAM BOT + ASSISTANT)          ║"
    echo "╚══════════════════════════════════════════════════╝"

    log "AI-Agent-Setup starten..."

    # Python Telegram Bot setup
    log "Telegram Bot einrichten..."
    if ! command -v python3 &>/dev/null; then
        sudo apt install -y python3 python3-pip python3-venv
    fi

    mkdir -p ~/ai-agent
    if [ ! -f ~/ai-agent/.env ]; then
        cp ai-agent/.env.example ~/ai-agent/.env
        warn "→ Telegram Bot-Token eintragen: nano ~/ai-agent/.env"
    fi

    # Python-Venv
    if [ ! -d ~/ai-agent/venv ]; then
        python3 -m venv ~/ai-agent/venv
        source ~/ai-agent/venv/bin/activate
        pip install python-telegram-bot requests schedule openai
        deactivate
    fi

    # Bot-Service installieren
    cp ai-agent/telegram-bot.py ~/ai-agent/bot.py
    cp ai-agent/daily_briefing.py ~/ai-agent/daily.py
    cp ai-agent/server_commands.py ~/ai-agent/commands.py

    log "Bot als Systemd-Service registrieren..."
    sudo tee /etc/systemd/system/ai-agent.service >/dev/null <<EOSVC
[Unit]
Description=Atlas.Lab AI Agent (Telegram Bot)
After=network.target docker.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME_DIR/ai-agent
ExecStart=$HOME_DIR/ai-agent/venv/bin/python $HOME_DIR/ai-agent/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOSVC

    sudo systemctl daemon-reload
    sudo systemctl enable ai-agent 2>/dev/null || true
    warn "Bot starten nach Konfiguration: sudo systemctl start ai-agent"
    warn "→ Logs: journalctl -u ai-agent -f"
}

# ─── START ═══════════════════════════════════════════════════════════════════
main() {
    # Logging: alles in Datei mitschreiben
    LOG_FILE="$HOME_DIR/bootstrap.log"
    exec &> >(tee -a "$LOG_FILE")
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Atlas.Lab Homelab Bootstrap gestartet"

    # Marker-Datei für Fortschritt
    PROGRESS_FILE="$HOME_DIR/.bootstrap-progress"

    load_progress() {
        if [ -f "$PROGRESS_FILE" ]; then
            source "$PROGRESS_FILE"
        fi
    }

    save_progress() {
        echo "$1=done" >> "$PROGRESS_FILE"
    }

    load_progress

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║     Atlas.Lab Homelab Bootstrap v3.3             ║"
    echo "║     Automatischer Setup für Ubuntu 24.04         ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""

    # COMPOSE- und CONFIG-Dateien ins Home kopieren
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    # Config-Dateien zentral bereitstellen
    cp -r "$SCRIPT_DIR/config" ~/ 2>/dev/null || true
    # Utility-Scripts kopieren
    mkdir -p ~/scripts
    cp "$SCRIPT_DIR"/scripts/*.sh ~/scripts/ 2>/dev/null || true
    chmod +x ~/scripts/*.sh 2>/dev/null || true
    # docker-compose-all.yml für merged Deployment bereitstellen
    cp "$SCRIPT_DIR/docker-compose-all.yml" ~/docker/ 2>/dev/null || true

    [ -z "${STEP1:-}" ] && { section_1_system;   save_progress "STEP1"; }
    [ -z "${STEP2:-}" ] && { section_2_docker;   save_progress "STEP2"; }
    [ -z "${STEP3:-}" ] && { section_3_ssh_harden;  save_progress "STEP3"; }
    [ -z "${STEP4:-}" ] && { section_4_firewall;    save_progress "STEP4"; }
    [ -z "${STEP5:-}" ] && { section_5_dns;      save_progress "STEP5"; }
    [ -z "${STEP6:-}" ] && { section_6_privacy;  save_progress "STEP6"; }
    [ -z "${STEP7:-}" ] && { section_7_ai;       save_progress "STEP7"; }
    [ -z "${STEP8:-}" ] && { section_8_media;    save_progress "STEP8"; }
    [ -z "${STEP9:-}" ] && { section_9_cloud;    save_progress "STEP9"; }
    [ -z "${STEP10:-}" ] && { section_10_access; save_progress "STEP10"; }
    [ -z "${STEP11:-}" ] && { section_11_wireguard; save_progress "STEP11"; }
    [ -z "${STEP12:-}" ] && { section_12_ai_agent;  save_progress "STEP12"; }
    [ -z "${STEP13:-}" ] && { section_13_gpu;      save_progress "STEP13"; }

    # Falls der Benutzer neu zur docker-Gruppe hinzugefügt wurde
    if groups "$USER" | grep -q docker; then
        :
    else
        warn "Bitte einmal aus- und wieder einloggen (oder 'newgrp docker' ausführen)."
    fi

    # ─── Finale Überprüfung ──────────────────────────────────────────────
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  🔍  SERVICE-VERIFIKATION                        ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    log "Überprüfe laufende Docker-Container..."
    local running=0 expected=0
    for container in pihole unbound tor websurfx jellyfin ollama hermes open-webui \
                     sabnzbd sonarr radarr prowlarr bazarr n8n syncthing \
                     nextcloud-aio uptime-kuma heimdall caddy; do
        expected=$((expected + 1))
        if docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null | grep -q "running"; then
            running=$((running + 1))
        fi
    done
    log "$running von $expected erwarteten Containern laufen."
    if [ "$running" -lt "$expected" ]; then
        warn "Nicht alle Container laufen. Prüfe mit: ~/scripts/health-check.sh"
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bootstrap abgeschlossen"

    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  ✅  HOMELAB-SETUP ABGESCHLOSSEN!                ║"
    echo "╚══════════════════════════════════════════════════╝"
    echo ""
    echo "  Web-Interfaces:"
    echo "    Pi-hole     → http://$SERVER_IP:8081/admin"
    echo "    Websurfx    → http://$SERVER_IP:8080"
    echo "    Nextcloud   → http://$SERVER_IP:8082"
    echo "    Jellyfin    → http://$SERVER_IP:8096"
    echo "    Hermes      → http://$SERVER_IP:3000"
    echo "    Open WebUI  → http://$SERVER_IP:3002"
    echo "    n8n         → http://$SERVER_IP:5678"
    echo "    SABnzbd     → http://$SERVER_IP:8085"
    echo "    Heimdall    → http://$SERVER_IP:8090"
    echo "    Uptime Kuma → http://$SERVER_IP:3001"
    echo "    Sonarr      → http://$SERVER_IP:8989"
    echo "    Radarr      → http://$SERVER_IP:7878"
    echo "    Prowlarr    → http://$SERVER_IP:9696"
    echo "    Bazarr      → http://$SERVER_IP:6767"
    echo "    Syncthing   → http://$SERVER_IP:8384"
    echo "    AMP         → http://$SERVER_IP:8087"
    echo ""
    echo "  VPN (PiVPN):  $SERVER_IP:51820/udp"
    echo "  Samba:        \\\\$SERVER_IP\\media"
    echo ""
    echo "  Nützliche Befehle:"
    echo "    ~/scripts/update-all.sh    – Alle Container + System updaten"
    echo "    ~/scripts/backup-all.sh    – Backup erstellen"
    echo "    ~/scripts/health-check.sh  – Status prüfen"
    echo "    ~/scripts/dnssec-test.sh   – DNSSEC-Validierung testen"
    echo ""
    echo "  AI Agent (Telegram):"
    echo "    nano ~/ai-agent/.env       – Token eintragen"
    echo "    sudo systemctl start ai-agent"
    echo ""
    echo "  Logs:"
    echo "    ~/bootstrap.log            – Vollständiges Setup-Log"
    echo "    ~/.bootstrap-progress      – Fortschritts-Marker"
    echo ""
    echo "───────────────────────────────────────────────────"
}

main "$@"
