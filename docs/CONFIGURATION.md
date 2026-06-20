# Configuration Reference

## bootstrap.env

```bash
TZ=Europe/Berlin
DOMAIN=homelab.example.com
EMAIL=admin@example.com
CLOUDFLARE_EMAIL=admin@example.com
CLOUDFLARE_API_KEY=your_api_key
TAILSCALE_AUTHKEY=tskey-xxx
```

## users.env

```bash
ADMIN_USER=admin
DOCKER_USER=docker
SERVICE_USER=service
ADMIN_SSH_KEY="ssh-ed25519 AAAA..."
```

## network.env

```bash
PRIMARY_DNS=1.1.1.1
SECONDARY_DNS=9.9.9.9
USE_DOH=true
USE_IPV6=true
NTP_SERVERS=time.cloudflare.com,pool.ntp.org
TAILSCALE_HOSTNAME=bootstreep-homelab
```

## storage.env

```bash
STORAGE_ROOT=/opt/docker
USE_ZFS=false
DATA_DISK=/dev/sdb
ZFS_POOL=tank
```

## docker.env

```bash
DOCKER_NETWORK=homelab
DOCKER_SUBNET=172.20.0.0/16
LOG_MAX_SIZE=10m
LOG_MAX_FILE=3
```

## Service .env files

Each compose stack has its own `.env`:

```bash
DOMAIN=homelab.example.com
GRAFANA_PASSWORD=change_me
POSTGRES_PASSWORD=change_me
AUTHENTIK_SECRET_KEY=change_me
```

These are loaded by Docker Compose via `${VAR}` substitution.

## Secrets Storage

- Never commit `.env` files (gitignored)
- Use `secrets/` directory for credentials (gitignored)
- Document required vars in `.env.example`