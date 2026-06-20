# Installation Guide

## 1. Prerequisites

- Fresh Ubuntu Server 24.04 LTS installation
- Public IPv4 address (or Tailscale for VPN-only)
- Domain with Cloudflare DNS (for Let's Encrypt DNS challenge)
- SSH access to your server

## 2. Prepare Cloudflare

1. Create API token at https://dash.cloudflare.com/profile/api-tokens
2. Permissions needed: Zone:DNS:Edit, Zone:Zone:Read
3. Copy token to `bootstrap/config/bootstrap.env`

## 3. Clone Repository

```bash
git clone https://github.com/braeuningsamuel-cmyk/bootstreep-homelab.git
cd bootstreep-homelab
```

## 4. Edit Configuration

Edit `bootstrap/config/*.env`:

```bash
nano bootstrap/config/bootstrap.env
# Set DOMAIN, EMAIL, CLOUDFLARE_API_KEY
```

```bash
nano bootstrap/config/users.env
# Set ADMIN_USER and ADMIN_SSH_KEY
```

## 5. Run Bootstrap

```bash
sudo ./bootstrap/bootstrap.sh
```

Or with flags:

```bash
sudo ./bootstrap/bootstrap.sh --backup    # backup first
sudo ./bootstrap/bootstrap.sh --debug      # verbose
sudo ./bootstrap/bootstrap.sh --skip 11    # skip phase 11
```

## 6. Post-Install

1. Open Traefik dashboard at `https://traefik.<your-domain>`
2. Open Authentik at `https://auth.<your-domain>` and create admin
3. Open Grafana at `https://grafana.<your-domain>` (default admin/admin)
4. Review `system-report.md` for service status

## 7. Configure Backups

```bash
# Initialize Restic repo (example: S3)
restic -r s3:s3.amazonaws.com/my-bucket init

# Test backup
sudo /opt/docker/scripts/backup-all.sh
```

## Troubleshooting

If a phase fails, check `bootstrap/logs/bootstrap-*.log`. You can re-run individual phases:

```bash
sudo bash bootstrap/scripts/05-security.sh
```