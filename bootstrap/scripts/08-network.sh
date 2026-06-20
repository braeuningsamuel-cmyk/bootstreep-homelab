#!/bin/bash
################################################################################
# Phase 8: Network configuration (DNS, NTP, Tailscale)
################################################################################
set -Eeuo pipefail

info "Phase 8: Network configuration"

# systemd-resolved with Cloudflare + Quad9
mkdir -p /etc/systemd/resolved.conf.d
cat > /etc/systemd/resolved.conf.d/dns.conf <<'EOF'
[Resolve]
DNS=1.1.1.1 9.9.9.9 2606:4700:4700::1111
FallbackDNS=1.0.0.1 149.112.112.112
DNSOverTLS=yes
DNSSEC=yes
EOF

systemctl restart systemd-resolved

# Chrony
apt-get install -y chrony
cat > /etc/chrony/chrony.conf <<'EOF'
pool time.cloudflare.com iburst maxsources 4
pool pool.ntp.org iburst maxsources 4
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF
systemctl enable --now chrony
ok "Chrony configured"

# Tailscale (optional, non-fatal)
if command -v tailscale &>/dev/null; then
    ok "Tailscale already installed"
else
    curl -fsSL https://tailscale.com/install.sh | sh || warn "Tailscale install skipped"
fi

ok "Network setup complete"