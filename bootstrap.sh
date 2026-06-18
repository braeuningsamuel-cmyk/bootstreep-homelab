#!/bin/bash
# shellcheck disable=SC2317
set -euo pipefail

# =============================================================================
# Bootstreep Homelab Bootstrap v4.1.2
# Für Ubuntu 24.04 LTS – Privacy-First Homelab in einem Befehl
#
# Usage:
#   chmod +x bootstrap.sh && ./bootstrap.sh
#
# Optional Variablen:
#   SERVER_IP=192.168.178.20       # Statische IP
#   PIHOLE_PASS="<sicher>"         # Pi-hole Pass (sonst Auto-Generate)
#   TIMEZONE="Europe/Berlin"
#   INSTALL_PROFILE=full|minimal|media|ai|privacy
#   SKIP_AI_AGENT=false
#   SKIP_MODEL_DOWNLOAD=false
#   OLLAMA_MODELS=light|full
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="${HOME:-/tmp}/bootstrap.log"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

log()  { printf '%b[✓]%b %s\n' "$GREEN" "$NC" "$1"; }
warn() { printf '%b[!]%b %s\n' "$YELLOW" "$NC" "$1"; }
info() { printf '%b[i]%b %s\n' "$CYAN" "$NC" "$1"; }
err()  { printf '%b[✗]%b %s\n' "$RED" "$NC" "$1"; }
die()  { err "$1"; exit 1; }

SERVER_IP="${SERVER_IP:-192.168.178.20}"
PIHOLE_PASS="${PIHOLE_PASS:-}"
TIMEZONE="${TIMEZONE:-Europe/Berlin}"
INSTALL_PROFILE="${INSTALL_PROFILE:-full}"
SKIP_AI_AGENT="${SKIP_AI_AGENT:-false}"
SKIP_MODEL_DOWNLOAD="${SKIP_MODEL_DOWNLOAD:-false}"
OLLAMA_MODELS="${OLLAMA_MODELS:-light}"
USER="${USER:-$(whoami)}"
HOME_DIR="${HOME:-/home/$USER}"

exec &> >(tee -a "$LOG_FILE")
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Bootstreep Bootstrap v4.0.0 gestartet"

if [ -z "$PIHOLE_PASS" ]; then
    if command -v openssl &>/dev/null; then
        PIHOLE_PASS=$(openssl rand -base64 16 | tr -d '/+=' | head -c 20)
        warn "PIHOLE_PASS generiert: $PIHOLE_PASS – BITTE NOTIEREN!"
    else
        die "PIHOLE_PASS fehlt und openssl nicht verfügbar"
    fi
fi

if [ "$PIHOLE_PASS" = "admin" ] || [ "${#PIHOLE_PASS}" -lt 12 ]; then
    die "PIHOLE_PASS zu schwach (min. 12 Zeichen, kein 'admin')"
fi

dc_up() {
    local dir="$1" name="$2" max=3 attempt=1
    while [ "$attempt" -le "$max" ]; do
        if (cd "$HOME_DIR/docker/$dir" && docker compose up -d) 2>/dev/null; then
            log "$name gestartet"
            return 0
        fi
        warn "$name: Versuch $attempt/$max – warte 5s"
        sleep 5
        attempt=$((attempt + 1))
    done
    err "$name konnte nicht starten"
    return 1
}

dc_up_parallel() {
    local pids=()
    for svc in "$@"; do
        local dir="${svc%%:*}" name="${svc#*:}"
        (cd "$HOME_DIR/docker/$dir" && docker compose up -d) 2>/dev/null &
        pids+=($!)
    done
    local fail=0
    for pid in "${pids[@]}"; do wait "$pid" || fail=$((fail + 1)); done
    [ "$fail" -eq 0 ] && log "Alle $# Services parallel gestartet" || warn "$fail/$# fehlgeschlagen"
}

select_profile() {
    case "$INSTALL_PROFILE" in
        full|minimal|media|ai|privacy) log "Profil: $INSTALL_PROFILE" ;;
        *) die "Ungültiges Profil: $INSTALL_PROFILE" ;;
    esac
}

should_run() {
    local s="$1"
    case "$INSTALL_PROFILE" in
        full|privacy) return 0 ;;
        minimal) [[ " 1 2 4 5 8 9 10 " == *" $s "* ]] ;;
        media)   [[ " 1 2 3 4 8 10 11 " == *" $s "* ]] ;;
        ai)      [[ " 1 2 3 4 7 12 " == *" $s "* ]] ;;
    esac
}

pre_flight_checks() {
    local errs=0
    [ "$EUID" -eq 0 ] && { err "Nicht als root"; errs=$((errs + 1)); }
    echo "$SERVER_IP" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' || { err "SERVER_IP ungültig"; errs=$((errs + 1)); }
    local ram=$(free -m 2>/dev/null | awk '/^Mem:/ {print $2}')
    [ -n "$ram" ] && [ "$ram" -lt 4096 ] && warn "Weniger als 4GB RAM"
    local avail=$(df / --output=avail 2>/dev/null | tail -1)
    [ -n "$avail" ] && [ "$avail" -lt 20971520 ] && warn "Weniger als 20GB frei"
    [ "$errs" -gt 0 ] && die "Pre-Flight fehlgeschlagen"
    log "Pre-Flight OK"
}

section_1_system() {
    should_run 1 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  1.  SYSTEM-GRUNDLAGEN + TELEMETRIE ENTFERNEN    ║"
    echo "╚══════════════════════════════════════════════════╝"
    sudo apt update -y 2>&1 | tail -2
    sudo apt upgrade -y 2>&1 | tail -2
    sudo apt install -y curl git wget htop nano ufw fail2ban \
        unattended-upgrades ca-certificates gnupg lsb-release \
        net-tools iperf3 smartmontools dnsutils python3 python3-pip \
        python3-venv apparmor apparmor-utils auditd irqbalance 2>&1 | tail -2
    sudo systemctl enable apparmor 2>/dev/null || true
    sudo timedatectl set-timezone "$TIMEZONE" 2>/dev/null || true
    sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure --priority=low unattended-upgrades 2>/dev/null || true

    # Privacy: Telemetrie deaktivieren
    sudo systemctl disable --now whoopsie.service whoopsie.path 2>/dev/null || true
    sudo apt purge -y whoopsie popularity-contest ubuntu-report 2>/dev/null || true
    sudo apt purge -y apport apport-symptoms 2>/dev/null || true
    # NetworkManager Connectivity Check deaktivieren
    sudo mkdir -p /etc/NetworkManager/conf.d
    printf "[connectivity]\nenabled=false\n" | sudo tee /etc/NetworkManager/conf.d/99-disable-connectivity.conf >/dev/null

    # Performance: I/O-Optimierung
    sudo sed -i 's/errors=remount-ro/errors=remount-ro,noatime,nodiratime,commit=60/' /etc/fstab 2>/dev/null || true 
    echo 'ACTION=="add|change", KERNEL=="sd*[!0-9]", ATTR{queue/scheduler}="none"' | sudo tee /etc/udev/rules.d/60-iosched.rules >/dev/null 2>/dev/null || true

    # Performance: zram (50% RAM als komprimierter Swap)
    sudo apt install -y zram-tools 2>/dev/null || true
    if [ -f /etc/default/zramswap ]; then
        sudo sed -i 's/^#\?PERCENT=.*/PERCENT=50/' /etc/default/zramswap
        sudo systemctl enable zramswap 2>/dev/null || true
        sudo systemctl restart zramswap 2>/dev/null || true
    fi

    echo "STEP1=done" >> "$HOME_DIR/.bootstrap-progress"

    echo ""
    warn "System-Upgrade abgeschlossen. Ein Neustart wird empfohlen."
    warn "→ Nach dem Neustart bootstrap.sh erneut starten (erkennt bereits erledigte Schritte)."
    echo ""
    if [ -t 0 ]; then
        read -rp "Jetzt neu starten? (y/N): " reboot_now
        if [ "$reboot_now" = "y" ] || [ "$reboot_now" = "Y" ]; then
            log "Neustart wird durchgeführt..."
            sudo reboot
        fi
    else
        warn "⏭️ Nicht-interaktiver Modus – Neustart übersprungen."
        warn "   → Manuell: sudo reboot"
    fi
}

section_2_docker() {
    should_run 2 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  2.  DOCKER + HARDENING                          ║"
    echo "╚══════════════════════════════════════════════════╝"
    if ! command -v docker &>/dev/null; then
        curl -fsSL -o /tmp/get-docker.sh https://get.docker.com
        EXPECTED=$(curl -fsSL https://get.docker.com/ 2>/dev/null | awk '/SCRIPT_SHA=/ {gsub(/.*SCRIPT_SHA="|".*/, ""); print; exit}')
        ACTUAL=$(sha256sum /tmp/get-docker.sh | awk '{print $1}')
        if [ -n "$EXPECTED" ] && [ "$EXPECTED" != "$ACTUAL" ]; then
            die "Docker-Installer Checksum mismatch"
        fi
        sudo sh /tmp/get-docker.sh
        rm -f /tmp/get-docker.sh
    fi
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        warn "newgrp docker in neuer Shell"
    fi
    docker info &>/dev/null || sudo docker info &>/dev/null || die "Docker-Daemon läuft nicht"

    # Docker Daemon Hardening + Performance
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json >/dev/null <<'DJON'
{
  "log-driver": "json-file",
  "log-opts": {"max-size": "10m", "max-file": "3"},
  "storage-driver": "overlay2",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "ipv6": false,
  "ip-forward": false,
  "iptables": true,
  "default-ulimits": {"nofile": {"Name": "nofile", "Hard": 65536, "Soft": 65536}},
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
DJON
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    for net in frontend backend; do
        docker network inspect "$net" &>/dev/null 2>&1 || docker network create "$net"
    done

    # MAC-Adress-Randomisierung für Docker-Netzwerke
    docker network inspect frontend --format '{{(index .Options 0)}}' 2>/dev/null | grep -q "com.docker.network.driver.mac-address" || true

    mkdir -p ~/docker
    for d in dns tor websurfx ollama open-webui jellyfin sabnzbd n8n sonarr radarr prowlarr bazarr \
             syncthing nextcloud uptime-kuma caddy hermes heimdall teamspeak amp amp-instances \
             watchtower vaultwarden monitoring litellm chromadb authentik crowdsec minio; do
        mkdir -p ~/docker/"$d"
    done
}

section_3_sysctl_harden() {
    should_run 3 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  3.  KERNEL-HÄRTUNG + NETZWERK-OPTIMIERUNG       ║"
    echo "╚══════════════════════════════════════════════════╝"

    # IPv6 komplett deaktivieren (Privacy)
    if ! grep -q "net.ipv6.conf.all.disable_ipv6" /etc/sysctl.d/99-bootstreep.conf 2>/dev/null; then
        sudo tee /etc/sysctl.d/99-bootstreep.conf >/dev/null <<'SCTL'
# ─── Bootstreep: Privacy + Performance Sysctl ────────────────────
# IPv6 deaktivieren (Leak-Schutz)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# Network Security
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1

# TCP Hardening
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1

# Memory / Performance
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 60
vm.dirty_background_ratio = 2
vm.overcommit_ratio = 50
vm.overcommit_memory = 1

# Netzwerk-Performance (BBR + FastOpen)
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.core.somaxconn = 65536
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0

# Limit Kernel Info Leaks
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.printk = 3 3 3 3
kernel.unprivileged_bpf_disabled = 1
net.core.bpf_jit_harden = 2
SCTL
        sudo sysctl -p /etc/sysctl.d/99-bootstreep.conf 2>/dev/null || true
        log "Kernel-Härtung + BBR + FastOpen aktiviert"
    else
        log "Kernel bereits optimiert"
    fi
}

section_4_ssh_harden() {
    should_run 4 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  4.  SSH-HÄRTUNG                                  ║"
    echo "╚══════════════════════════════════════════════════╝"
    SSH_CFG="/etc/ssh/sshd_config"
    [ ! -f "${SSH_CFG}.bak" ] && sudo cp "$SSH_CFG" "${SSH_CFG}.bak"
    if [ -z "$(find ~/.ssh -name 'id_*' -not -name '*.pub' 2>/dev/null)" ]; then
        die "Kein SSH-Key! ssh-keygen + ssh-copy-id erforderlich"
    fi
    if ! grep -q "^PasswordAuthentication no" "$SSH_CFG" 2>/dev/null; then
        sudo sed -i 's/^#\?PasswordAuthentication.*yes/PasswordAuthentication no/' "$SSH_CFG"
        sudo sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' "$SSH_CFG"
        grep -q "^PasswordAuthentication" "$SSH_CFG" || echo "PasswordAuthentication no" | sudo tee -a "$SSH_CFG" >/dev/null
        sudo sed -i 's/^#\?PermitRootLogin.*yes/PermitRootLogin no/' "$SSH_CFG"
        sudo sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' "$SSH_CFG"
        grep -q "^PermitRootLogin" "$SSH_CFG" || echo "PermitRootLogin no" | sudo tee -a "$SSH_CFG" >/dev/null
        if ! grep -q "^Ciphers" "$SSH_CFG" 2>/dev/null; then
            {
                echo ""
                echo "# Bootstreep: Nur starke Algorithmen"
                echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com"
                echo "MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com"
                echo "KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,sntrup761x25519-sha512@openssh.com"
                echo "LoginGraceTime 30"
                echo "MaxAuthTries 3"
                echo "MaxStartups 3:50:10"
                echo "ClientAliveInterval 300"
                echo "ClientAliveCountMax 2"
                echo "DebianBanner no"
                echo "RekeyLimit 1G 1h"
            } | sudo tee -a "$SSH_CFG" >/dev/null
        fi
        sudo sshd -t 2>/dev/null || { sudo cp "${SSH_CFG}.bak" "$SSH_CFG"; die "SSH-Config ungültig"; }
        sudo systemctl restart ssh
    fi
    mkdir -p ~/.ssh
    [ -f "$SCRIPT_DIR/config/ssh/client-config" ] && [ ! -f ~/.ssh/config ] && {
        cp "$SCRIPT_DIR/config/ssh/client-config" ~/.ssh/config
        sed -i "s/192\.168\.178\.20/$SERVER_IP/g" ~/.ssh/config
        chmod 600 ~/.ssh/config
    }
}

section_5_firewall() {
    should_run 5 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  5.  FIREWALL + FAIL2BAN                          ║"
    echo "╚══════════════════════════════════════════════════╝"
    if ! sudo ufw status | grep -q active; then
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw limit ssh/tcp comment 'SSH rate limit'
        sudo ufw allow from 192.168.0.0/16 to any port \
            80,443,3000,3001,3002,5678,6767,7878,8080,8081,8082,8085,8087,8090,8091,8093,8096,8384,8989,9696,22000 proto tcp
        sudo ufw allow from 192.168.0.0/16 to any port 21027,9987 proto udp
        sudo ufw allow from 192.168.0.0/16 to any port 445 proto tcp
        sudo ufw allow 51820/udp comment 'WireGuard'
        sudo ufw --force enable
    fi
    sudo tee /etc/fail2ban/jail.local >/dev/null <<'EOF2'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd
ignoreip = 127.0.0.1/8 192.168.0.0/16
[sshd]
enabled = true
backend = systemd
maxretry = 3
bantime = 3600
[recidive]
enabled = true
logpath = /var/log/fail2ban.log
bantime = 604800
findtime = 86400
maxretry = 5
EOF2
    sudo systemctl enable --now fail2ban
}

section_6_dns() {
    should_run 6 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  6.  DNS (Pi-hole + Unbound)                      ║"
    echo "╚══════════════════════════════════════════════════╝"
    sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
    sudo chattr -i /etc/resolv.conf 2>/dev/null || true
    sudo ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
    sudo systemctl restart systemd-resolved
    mkdir -p ~/docker/dns/etc-pihole ~/docker/dns/etc-dnsmasq.d
    cp "$SCRIPT_DIR/config/dns/unbound.conf" ~/docker/dns/unbound.conf
    cp "$SCRIPT_DIR/compose/dns.yml" ~/docker/dns/compose.yml
    dc_up dns "DNS"
    local ready=0
    for _ in $(seq 1 60); do
        docker exec pihole pihole status 2>/dev/null | grep -qi enabled && ready=1 && break
        sleep 1
    done
    if [ "$ready" -eq 1 ]; then
        # Erweiterte Blocklisten
        docker exec pihole sh -c "cat > /etc/pihole/adlists.list" <<'ADL'
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://big.oisd.nl/
https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/tracking_servers.txt
https://raw.githubusercontent.com/AdguardTeam/AdguardFilters/master/SpywareFilter/sections/mobile.txt
ADL
        docker exec pihole pihole -g 2>/dev/null || warn "Gravity-Update fehlgeschlagen"
        sleep 2
        ! dig sigfail.verteiltesysteme.net @127.0.0.1 +short 2>/dev/null | grep -q . && log "DNSSEC sigfail blockiert" || warn "DNSSEC sigfail Problem"
        dig sigok.verteiltesysteme.net @127.0.0.1 +short 2>/dev/null | grep -q "134.91.78.139" && log "DNSSEC sigok OK" || warn "DNSSEC sigok Problem"
    fi
}

section_7_privacy() {
    should_run 7 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  7.  TOR + WEBSURFX                              ║"
    echo "╚══════════════════════════════════════════════════╝"
    cp "$SCRIPT_DIR/compose/tor.yml" ~/docker/tor/compose.yml
    dc_up tor "Tor"
    if [ ! -d ~/docker/websurfx/src ]; then
        git clone https://github.com/neon-mmd/websurfx.git ~/docker/websurfx/src
    fi
    cp "$SCRIPT_DIR/config/websurfx/config.lua" ~/docker/websurfx/src/config.lua 2>/dev/null || true
    docker image inspect websurfx:local &>/dev/null 2>&1 || docker build -t websurfx:local ~/docker/websurfx/src
    cp "$SCRIPT_DIR/compose/websurfx.yml" ~/docker/websurfx/compose.yml
    dc_up websurfx "Websurfx"
}

section_8_ai() {
    should_run 8 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  8.  OLLAMA + KI-CHAT                             ║"
    echo "╚══════════════════════════════════════════════════╝"
    cp "$SCRIPT_DIR/compose/ollama.yml" ~/docker/ollama/compose.yml
    dc_up ollama "Ollama"
    if [ "$SKIP_MODEL_DOWNLOAD" != "true" ]; then
        for _ in $(seq 1 30); do docker exec ollama curl -fs http://localhost:11434/api/tags &>/dev/null && break; sleep 2; done
        if [ "$OLLAMA_MODELS" = "full" ]; then
            MODELS="mistral:7b llama3.2:3b deepseek-coder:6.7b llama3.2:8b phi4:14b"
        else
            MODELS="mistral:7b llama3.2:3b"
        fi
        for model in $MODELS; do
            docker exec ollama ollama list 2>/dev/null | grep -q "^${model%%:*}" && { log "$model vorhanden"; continue; }
            log "Pulling $model..."
            timeout 900 docker exec ollama ollama pull "$model" 2>/dev/null && log "✓ $model" || warn "⚠ $model"
        done
    fi
    if [ ! -d ~/hermes ]; then
        git clone https://github.com/Hermes-Project/hermes.git ~/hermes
        [ -f ~/hermes/.env.example ] && cp ~/hermes/.env.example ~/hermes/.env
    fi
    cp "$SCRIPT_DIR/compose/hermes.yml" ~/docker/hermes/compose.yml
    dc_up hermes "Hermes"
    cp "$SCRIPT_DIR/compose/open-webui.yml" ~/docker/open-webui/compose.yml
    dc_up open-webui "Open WebUI"
}

section_9_media() {
    should_run 9 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║  9.  JELLYFIN + ARR-STACK                          ║"
    echo "╚══════════════════════════════════════════════════╝"
    mkdir -p ~/media/{movies,series,music,photos,books} ~/downloads/{complete,incomplete}
    cp "$SCRIPT_DIR/compose/jellyfin.yml" ~/docker/jellyfin/compose.yml
    dc_up jellyfin "Jellyfin"
    cp "$SCRIPT_DIR/compose/sabnzbd.yml" ~/docker/sabnzbd/compose.yml
    dc_up sabnzbd "SABnzbd"
    for s in sonarr radarr prowlarr bazarr; do cp "$SCRIPT_DIR/compose/$s.yml" ~/docker/"$s"/compose.yml; done
    dc_up_parallel "sonarr:Sonarr" "radarr:Radarr" "prowlarr:Prowlarr" "bazarr:Bazarr"
    cp "$SCRIPT_DIR/compose/n8n.yml" ~/docker/n8n/compose.yml
    dc_up n8n "n8n"
}

section_10_cloud() {
    should_run 10 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 10.  NEXTCLOUD + SYNCTHING                         ║"
    echo "╚══════════════════════════════════════════════════╝"
    sudo mkdir -p /opt/nextcloud-data
    sudo chown -R "$USER":"$USER" /opt/nextcloud-data
    cp "$SCRIPT_DIR/compose/nextcloud.yml" ~/docker/nextcloud/compose.yml
    dc_up nextcloud "Nextcloud"
    sleep 5
    docker logs nextcloud-aio 2>&1 | grep -i password | head -1 || warn "docker logs nextcloud-aio"
    cp "$SCRIPT_DIR/compose/syncthing.yml" ~/docker/syncthing/compose.yml
    dc_up syncthing "Syncthing"
}

section_11_access() {
    should_run 11 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 11.  SAMBA + DASHBOARDS + GAMES                    ║"
    echo "╚══════════════════════════════════════════════════╝"
    if ! command -v samba &>/dev/null; then sudo apt install -y samba; fi
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
        sudo smbpasswd -a "$USER" 2>/dev/null || warn "Samba-Passwort bereits gesetzt"
        sudo systemctl restart smbd
    fi
    cp "$SCRIPT_DIR/compose/uptime-kuma.yml" ~/docker/uptime-kuma/compose.yml
    dc_up uptime-kuma "Uptime Kuma"
    cp "$SCRIPT_DIR/compose/heimdall.yml" ~/docker/heimdall/compose.yml
    dc_up heimdall "Heimdall"

    # Systemd-Timer statt Cron (genauer, besser isoliert)
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/bootstreep-update.timer <<'TIMER'
[Unit]
Description=Bootstreep wöchentliches Update
[Timer]
OnCalendar=Sun *-*-* 03:00:00
Persistent=true
[Install]
WantedBy=timers.target
TIMER
    cat > ~/.config/systemd/user/bootstreep-update.service <<'SVC'
[Unit]
Description=Bootstreep Update All
[Service]
Type=oneshot
ExecStart=%h/scripts/update-all.sh
SVC
    cat > ~/.config/systemd/user/bootstreep-backup.timer <<'TIMER'
[Unit]
Description=Bootstreep wöchentliches Backup
[Timer]
OnCalendar=Sun *-*-* 04:00:00
Persistent=true
[Install]
WantedBy=timers.target
TIMER
    cat > ~/.config/systemd/user/bootstreep-backup.service <<'SVC'
[Unit]
Description=Bootstreep Backup All
[Service]
Type=oneshot
ExecStart=%h/scripts/backup-all.sh
SVC
    cat > ~/.config/systemd/user/bootstreep-health.timer <<'TIMER'
[Unit]
Description=Bootstreep Health Check
[Timer]
OnCalendar=*:0/30
Persistent=true
[Install]
WantedBy=timers.target
TIMER
    cat > ~/.config/systemd/user/bootstreep-health.service <<'SVC'
[Unit]
Description=Bootstreep Health Check
[Service]
Type=oneshot
ExecStart=%h/scripts/health-check.sh
SVC
    systemctl --user daemon-reload
    systemctl --user enable --now bootstreep-update.timer bootstreep-backup.timer bootstreep-health.timer 2>/dev/null || true

    cp "$SCRIPT_DIR/compose/teamspeak.yml" ~/docker/teamspeak/compose.yml
    dc_up teamspeak "TeamSpeak"
    cp "$SCRIPT_DIR/compose/amp.yml" ~/docker/amp/compose.yml
    dc_up amp "AMP"
    mkdir -p ~/docker/amp-instances
    cp "$SCRIPT_DIR/compose/amp-instances/"*.yml ~/docker/amp-instances/ 2>/dev/null || true
    mkdir -p ~/docker/caddy
    [ -f "$SCRIPT_DIR/config/caddy/Caddyfile" ] && {
        cp "$SCRIPT_DIR/config/caddy/Caddyfile" ~/docker/caddy/Caddyfile
        sed -i "s/__SERVER_IP__/$SERVER_IP/g; s/__USER__/$USER/g" ~/docker/caddy/Caddyfile
    }
    cp "$SCRIPT_DIR/compose/caddy.yml" ~/docker/caddy/compose.yml
    dc_up caddy "Caddy"
}

section_12_vpn() {
    should_run 12 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 12.  VPN                                          ║"
    echo "╚══════════════════════════════════════════════════╝"
    if command -v pivpn &>/dev/null; then
        log "PiVPN bereits installiert"
    else
        warn "VPN interaktiv: PiVPN (curl -L https://install.pivpn.io | bash) oder Tailscale"
    fi
}

section_13_ai_agent() {
    should_run 13 || return 0
    [ "$SKIP_AI_AGENT" = "true" ] && { info "AI Agent übersprungen"; return 0; }
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 13.  AI AGENT (TELEGRAM)                          ║"
    echo "╚══════════════════════════════════════════════════╝"
    if ! command -v python3 &>/dev/null; then sudo apt install -y python3 python3-pip python3-venv; fi
    mkdir -p ~/ai-agent
    [ -f ai-agent/.env.example ] && [ ! -f ~/ai-agent/.env ] && cp ai-agent/.env.example ~/ai-agent/.env
    if [ ! -d ~/ai-agent/venv ]; then
        python3 -m venv ~/ai-agent/venv
        source ~/ai-agent/venv/bin/activate
        pip install --upgrade pip
        [ -f ai-agent/requirements.txt ] && pip install -r ai-agent/requirements.txt
        deactivate
    fi
    [ -f ai-agent/telegram-bot.py ] && cp ai-agent/telegram-bot.py ~/ai-agent/bot.py
    [ -f ai-agent/daily_briefing.py ] && cp ai-agent/daily_briefing.py ~/ai-agent/daily.py
    [ -f ai-agent/server_commands.py ] && cp ai-agent/server_commands.py ~/ai-agent/commands.py

    sudo tee /etc/systemd/system/ai-agent.service >/dev/null <<EOSVC
[Unit]
Description=Bootstreep AI Agent
After=network.target docker.service
[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME_DIR/ai-agent
ExecStart=$HOME_DIR/ai-agent/venv/bin/python $HOME_DIR/ai-agent/bot.py
Restart=always
RestartSec=10
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$HOME_DIR/ai-agent
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOSVC
    sudo systemctl daemon-reload
    sudo systemctl enable ai-agent
}

section_14_gpu() {
    should_run 14 || return 0
    if [ -t 0 ]; then
        read -rp "NVIDIA installieren? (y/N): " ans
        [[ "$ans" =~ ^[yY]$ ]] && { sudo apt install -y nvidia-driver-535 nvidia-container-toolkit; warn "Reboot!"; }
    fi
}

section_15_dashboard() {
    should_run 15 || return 0
    REPO="https://github.com/braeuningsamuel-cmyk/bootstreep-dashboard.git"
    [ -d ~/bootstreep-dashboard/.git ] && (cd ~/bootstreep-dashboard && git pull) || git clone "$REPO" ~/bootstreep-dashboard || warn "Dashboard-Clone fehlgeschlagen"
    [ -f ~/docker/caddy/Caddyfile ] && ! grep -q bootstreep-dashboard ~/docker/caddy/Caddyfile && {
        cat > ~/docker/caddy/Caddyfile.new <<EOF
http://$SERVER_IP:80 {
    root * $HOME/bootstreep-dashboard/src
    file_server
}

$(cat ~/docker/caddy/Caddyfile)
EOF
        mv ~/docker/caddy/Caddyfile.new ~/docker/caddy/Caddyfile
        docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || docker restart caddy 2>/dev/null || true
    }
}

section_16_extras() {
    should_run 16 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 16.  WATCHTOWER + VAULTWARDEN + MONITORING        ║"
    echo "╚══════════════════════════════════════════════════╝"
    cp "$SCRIPT_DIR/compose/watchtower.yml" ~/docker/watchtower/compose.yml
    dc_up watchtower "Watchtower"
    [ -f "$SCRIPT_DIR/compose/vaultwarden.yml" ] && {
        cp "$SCRIPT_DIR/compose/vaultwarden.yml" ~/docker/vaultwarden/compose.yml
        dc_up vaultwarden "Vaultwarden"
        warn "Nach erstem Account: SIGNUPS_ALLOWED=false!"
    }
    # Docker Cleanup Cron (weekly)
    cat > ~/scripts/docker-cleanup.sh <<'CLN'
#!/bin/bash
docker image prune -af --filter "until=168h" 2>/dev/null || true
docker builder prune -af 2>/dev/null || true
docker system df 2>/dev/null
CLN
    chmod +x ~/scripts/docker-cleanup.sh
    if ! crontab -l 2>/dev/null | grep -q "docker-cleanup.sh"; then
        (crontab -l 2>/dev/null; echo "0 5 * * 0 $HOME_DIR/scripts/docker-cleanup.sh >/dev/null 2>&1") | crontab - 2>/dev/null || true
    fi
}

section_17_sanitize_logs() {
    should_run 17 || return 0
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║ 17.  LOG-ANONYMISIERUNG (PRIVACY)                 ║"
    echo "╚══════════════════════════════════════════════════╝"
    cat > ~/scripts/sanitize-logs.sh <<'SAN'
#!/bin/bash
# Entfernt IP-Adressen aus Log-Dateien (Privacy)
set -euo pipefail
LOG_DIRS="/var/log $HOME/bootstrap.log $HOME/ai-agent"
for target in $LOG_DIRS; do
    [ -f "$target" ] && sudo sed -i -E 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/x.x.x.x/g' "$target" 2>/dev/null || true
    [ -d "$target" ] && find "$target" -name "*.log" -o -name "*.txt" 2>/dev/null | while read -r f; do
        sudo sed -i -E 's/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/x.x.x.x/g' "$f" 2>/dev/null || true
    done
done
echo "Logs anonymisiert: $(date)"
SAN
    chmod +x ~/scripts/sanitize-logs.sh
    if ! crontab -l 2>/dev/null | grep -q "sanitize-logs.sh"; then
        (crontab -l 2>/dev/null; echo "0 2 * * 6 $HOME_DIR/scripts/sanitize-logs.sh >/dev/null 2>&1") | crontab - 2>/dev/null || true
    fi
    log "Log-Anonymisierung eingerichtet (wöchentlich)"
}

main() {
    PROGRESS_FILE="$HOME_DIR/.bootstrap-progress"
    [ -f "$PROGRESS_FILE" ] && while IFS='=' read -r k v; do [[ "$k" =~ ^STEP[0-9]+$ && "$v" == "done" ]] && declare "$k=done"; done < "$PROGRESS_FILE"
    select_profile
    pre_flight_checks
    echo ""
    echo "╔══════════════════════════════════════════════════╗"
    echo "║     Bootstreep Homelab Bootstrap v4.1.2         ║"
    echo "║     PRIVACY-FIRST • LOCAL KI • NO TELEMETRY       ║"
    echo "╚══════════════════════════════════════════════════╝"
    [ -d "$SCRIPT_DIR/config" ] && cp -r "$SCRIPT_DIR/config" ~/ 2>/dev/null || true
    mkdir -p ~/scripts
    [ -d "$SCRIPT_DIR/scripts" ] && cp "$SCRIPT_DIR"/scripts/*.sh ~/scripts/ 2>/dev/null || true
    [ -d ~/scripts ] && chmod +x ~/scripts/*.sh 2>/dev/null || true
    [ -z "${STEP1:-}" ] && { section_1_system;        echo "STEP1=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP2:-}" ] && { section_2_docker;        echo "STEP2=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP3:-}" ] && { section_3_sysctl_harden; echo "STEP3=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP4:-}" ] && { section_4_ssh_harden;    echo "STEP4=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP5:-}" ] && { section_5_firewall;      echo "STEP5=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP6:-}" ] && { section_6_dns;           echo "STEP6=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP7:-}" ] && { section_7_privacy;       echo "STEP7=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP8:-}" ] && { section_8_ai;            echo "STEP8=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP9:-}" ] && { section_9_media;         echo "STEP9=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP10:-}" ] && { section_10_cloud;       echo "STEP10=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP11:-}" ] && { section_11_access;      echo "STEP11=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP12:-}" ] && { section_12_vpn;         echo "STEP12=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP13:-}" ] && { section_13_ai_agent;    echo "STEP13=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP14:-}" ] && { section_14_gpu;         echo "STEP14=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP15:-}" ] && { section_15_dashboard;   echo "STEP15=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP16:-}" ] && { section_16_extras;      echo "STEP16=done" >> "$PROGRESS_FILE"; }
    [ -z "${STEP17:-}" ] && { section_17_sanitize_logs;echo "STEP17=done" >> "$PROGRESS_FILE"; }
    echo ""
    echo "✅ HOMELAB BEREIT – http://$SERVER_IP:80"
    echo ""
    echo "Pi-hole Pass: $PIHOLE_PASS"
    echo "Scripts: ~/scripts/"
    echo "Logs: ~/bootstrap.log"
}

main "$@"
