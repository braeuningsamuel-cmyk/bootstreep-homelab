#!/bin/bash
################################################################################
# Phase 5: SSH Hardening + Firewall + Fail2Ban + Kernel Hardening
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${BOOTSTRAP_DIR}/config"

if [[ -f "${CONFIG_DIR}/users.env" ]]; then
    # shellcheck disable=SC1091
    source "${CONFIG_DIR}/users.env"
fi
ADMIN_USER="${ADMIN_USER:-admin}"

info "Phase 5: Security hardening"

# Backup sshd_config
cp /etc/ssh/sshd_config "/etc/ssh/sshd_config.bak.$(date +%s)"

cat > /etc/ssh/sshd_config.d/00-hardening.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers ${ADMIN_USER}
X11Forwarding no
AllowTcpForwarding no
PermitEmptyPasswords no
EOF

systemctl restart sshd
ok "SSH hardened"

# UFW
apt-get install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment "SSH"
ufw allow 80/tcp comment "HTTP"
ufw allow 443/tcp comment "HTTPS"
# Optional
ufw allow 51820/udp comment "WireGuard" 2>/dev/null || true
ufw --force enable
ok "UFW configured"

# Fail2Ban
apt-get install -y fail2ban
cat > /etc/fail2ban/jail.local <<'EOF'
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3

[traefik-auth]
enabled = true
filter = traefik-auth
logpath = /var/log/traefik/access.log
maxretry = 5
EOF

cat > /etc/fail2ban/filter.d/traefik-auth.conf <<'EOF'
[Definition]
failregex = ^<HOST> -.*"(GET|POST).*HTTP.*" (401|403)
ignoreregex =
EOF

systemctl enable fail2ban
systemctl restart fail2ban
ok "Fail2Ban configured"

# Kernel hardening
cat > /etc/sysctl.d/99-hardening.conf <<'EOF'
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ip4.conf.all.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.tcp_syncookies = 1
kernel.randomize_va_space = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF
sysctl --system
ok "Kernel hardened"

# AppArmor
apt-get install -y apparmor apparmor-utils
aa-enforce /etc/apparmor.d/* 2>/dev/null || true
ok "AppArmor enabled"

# Auditd
apt-get install -y auditd
systemctl enable auditd
ok "Security stack complete"