# Bootstreep Homelab — Architecture

> **Status:** production-ready, security-hardened.
> **Stack:** Ubuntu 24.04 LTS · Docker Compose · Traefik · Authentik SSO · Prometheus/Loki/Alloy · CrowdSec WAF · LiteLLM (local LLM).

---

## 1. System Overview

Bootstreep is a **single-node, privacy-first homelab bootstrapper**. It deploys a
curated set of self-hosted services on one Ubuntu 24.04 box, fronted by a
single reverse proxy, with a 5-layer security posture.

```
                ┌──────────────────────────────────────────────────────────┐
                │                     Internet                              │
                └────────────────────────┬─────────────────────────────────┘
                                         │
                              ┌──────────▼──────────┐
                              │   Traefik (80/443)  │  ← TLS (Let's Encrypt / Cloudflare)
                              │   + Cloudflare DNS  │
                              │   + Authentik SSO   │  ← OIDC / forward-auth
                              │   + CrowdSec WAF    │  ← behavioral IDS
                              └──────────┬──────────┘
                                         │
        ┌────────────────────────────────┼─────────────────────────────────┐
        │            internal Docker network `homelab` (bridge)            │
        │                                                                  │
        │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────────┐│
        │  │ Portainer│ │ Authentik│ │  Caddy   │ │ Homepage │ │  ...    ││
        │  └──────────┘ └──────────┘ └──────────┘ └──────────┘ └─────────┘│
        └────────────────────────────────┬─────────────────────────────────┘
                                         │
                              ┌──────────▼──────────┐
                              │  Logging: Loki      │ ← Promtail + Alloy (host logs)
                              │  Metrics: Prometheus│ ← node-exporter + cadvisor
                              │  Dashboards: Grafana│
                              └──────────┬──────────┘
                                         │
                              ┌──────────▼──────────┐
                              │   Alerts:           │ ← Alertmanager (Slack/Email)
                              │   Backups: Restic   │ ← daily → B2/S3 + local
                              └─────────────────────┘
```

---

## 2. Layered Security Posture

| Layer | Component | Purpose |
|---|---|---|
| **L1 — Edge** | Cloudflare DNS + Tunnel | DDoS shield, hides origin IP |
| **L2 — TLS** | Traefik + Let's Encrypt / Cloudflare | Auto-renewing certs |
| **L3 — WAF** | CrowdSec + Traefik bouncer | Behavioral IDS, ban repeat offenders |
| **L4 — SSO** | Authentik (OIDC + forward-auth) | Single identity, MFA, RBAC |
| **L5 — App** | Cap-drop + non-root + `:ro` docker.sock + seccomp | Minimize container blast radius |

---

## 3. Service Catalog

### Reverse Proxy / Edge
- **traefik** — public entrypoint. `:80` + `:443`. Cloudflare DNS challenge.
- **caddy** — secondary proxy for internal-only services that prefer Caddyfile config.

### Identity
- **authentik** — SSO server + IdP. OIDC for downstream apps; forward-auth for the rest.
- **authentik-worker** — background tasks (email, federation sync).

### Observability
- **prometheus** — metrics scrape (15d retention).
- **loki** — log aggregation (label-driven, no full-text index).
- **alloy** — host + docker log shipping.
- **grafana** — dashboards. SSO via Authentik.
- **promtail** *(legacy, replaced by alloy for new deploys)* — alternative log shipper.

### Management
- **portainer** — Docker UI. Read-only docker.sock. SSO via Authentik.
- **homepage** — dashboard landing page.
- **watchtower** — auto-update Docker images (cron 04:00). **The only service allowed `:rw` docker.sock** by design.
- **uptime-kuma** — service health monitoring.
- **hermes** — internal chat/automation helper.

### Apps
- **vaultwarden** — password manager (Bitwarden-compatible).
- **nextcloud** — files/calendar/contacts.
- **jellyfin** — media server.
- **minio** — S3-compatible object storage.
- **litellm** — LLM gateway (local models).
- **ollama** — model server.
- **open-webui** — chat UI for local LLMs.
- **n8n** — workflow automation.
- **bazarr / prowlarr / radarr** — *arr media stack.
- **chromadb** — vector DB for RAG.
- **monitoring** — alertmanager + receivers.

### Special Hosts
- **crowdsec** — runs in `network_mode: host` so it can inspect host-level traffic. Justified, documented.
- **amp + amp-instances** — game-server panel. Per-game stacks in `compose/amp-instances/`.

---

## 4. Data Flow

### Inbound request (web)
1. DNS → Cloudflare (or direct) → Traefik on `:443`
2. CrowdSec bouncer consults decision list → allow/ban
3. Traefik routes by Host → Authentik forward-auth middleware (if route requires SSO)
4. Authentik validates session, forwards `X-authentik-*` headers
5. Traefik forwards to internal service on `homelab` network

### Log pipeline
1. Container stdout → Loki via Promtail/Alloy (JSON driver)
2. Host journald → Alloy → Loki
3. Grafana queries Loki with LogQL → dashboard

### Metrics pipeline
1. node-exporter + cadvisor scrape system + container metrics
2. Prometheus scrapes exporters every 15s
3. Grafana renders Prometheus data
4. Alertmanager evaluates rules → Slack/Email

### Backup pipeline
1. cron `@daily` → `backup-all.sh`
2. Restic snapshots `~/docker/volumes/`, configs, `/etc/`, and the AI agent state dir
3. Push to Backblaze B2 (encrypted, deduplicated)
4. Health-check exit code → systemd unit → journald

---

## 5. File / Volume Layout

```
/home/<user>/
├── docker/
│   ├── traefik/        ← bind-mounted config + acme.json
│   ├── auth-data/
│   ├── grafana-data/
│   ├── prometheus-data/
│   └── ... (one folder per stack)
├── ai-agent/
│   ├── .env            ← TELEGRAM_BOT_TOKEN, ALLOWED_CHAT_IDS, LITELLM_*
│   ├── venv/
│   ├── server_commands.py
│   └── telegram-bot.py
├── scripts/
│   ├── backup-all.sh
│   ├── health-check.sh
│   ├── update-all.sh
│   └── dnssec-test.sh
└── ~/bootstreep-homelab/   ← this repo
    ├── bootstrap/
    ├── compose/
    ├── ansible/
    ├── cloud-init/
    ├── libvirt/
    ├── docs/
    └── tests/
```

---

## 6. Networking

- **External interfaces:** `:80` (HTTP→HTTPS), `:443` (HTTPS). Optionally `:2222` SSH (non-default port).
- **Internal Docker network:** `homelab` (bridge). All services attach here by default.
- **Database services** (none yet exposed externally) should attach to a *second* internal network `data` with no path to Traefik.
- **Service discovery:** Docker DNS (`<service>` resolves on `homelab`).

---

## 7. Secrets Management

- **Loaded at runtime** from `.env` files (not in repo).
- **`.env.example`** ships as the template — no real values.
- **Backup encryption keys** live in `~/.config/restic/` and are *not* on the host's filesystem backup target.
- **Telegram bot token + allowed chat IDs** are loaded from `~/ai-agent/.env`.
- **Traefik dashboard auth** uses basic-auth hash in `compose/traefik/dynamic/`.

For production: migrate to **HashiCorp Vault** or **Authentik's secret store** — see [ROADMAP.md](./ROADMAP.md).

---

## 8. Operational Runbook

### Adding a new service
1. Create `compose/<service>.yml` in this repo.
2. Add `traefik.enable=true` labels if it should be public.
3. Add Authentik forward-auth middleware if it requires SSO.
4. Add healthcheck + deploy.resources + cap_drop + pids_limit.
5. `make validate && make bats && docker compose -f compose/<service>.yml up -d`
6. PR into `main`. Watchtower handles image updates daily.

### Rolling back a service
```bash
docker compose -f compose/<service>.yml down
git checkout HEAD~1 -- compose/<service>.yml
docker compose -f compose/<service>.yml up -d
```

### Disaster recovery
1. Restore from latest Restic snapshot: `restic restore latest --target /`
2. Re-run `make install` (idempotent).
3. Re-import Authentik config (exported weekly).
4. Verify healthchecks all green.

---

## 9. Threat Model

### What we defend against
- Internet-wide port scans → Cloudflare + fail2ban + CrowdSec
- Credential stuffing → Authentik MFA + rate limiting
- Container escape → `cap_drop: ALL`, `:ro` docker.sock, non-root UID
- Supply chain → pinned base images (`node:22-alpine`), Dependabot, weekly OS updates
- Data exfiltration via logs → label-based log routing, no sensitive logs to public Loki

### What we **don't** defend against (out of scope)
- Compromised Authentik admin account
- Physical access to the host
- Side-channel attacks against LiteLLM model loading
- 0-day in Traefik/CrowdSec (mitigated by < 7-day update SLA via Watchtower)

---

## 10. Quality Bar

Every PR must satisfy:

- [ ] Compose file has `healthcheck`, `deploy.resources`, `cap_drop`, `no-new-privileges`, `pids_limit`
- [ ] New service has `.env.example` entry
- [ ] `make lint && make bats && make secrets` passes locally
- [ ] `make validate` passes in CI
- [ ] Update `docs/audit/` if the change alters the threat model

---

**Maintained by:** Samuel Bräuning · License: MIT