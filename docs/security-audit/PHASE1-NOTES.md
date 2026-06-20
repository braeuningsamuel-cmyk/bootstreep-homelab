# Bootstreep Homelab Security Hardening Report

**Generated:** 2026-06-18 (v5.0, Phase 1 notes)
**Status:** SUPERSEDED by `docs/audit/2026-06-20-REPORT.md`

This document was originally a working set of hardening notes while iterating
through Phase 1 of the security review. The full audit (with patches applied)
now lives at [`docs/audit/2026-06-20-REPORT.md`](./2026-06-20-REPORT.md).
Kept here as historical context.

---

## Phase 1 — Critical Fixes (status: implemented)

### 1.1 Docker Socket Exposure
**Finding:** Multiple services mounted `/var/run/docker.sock` as read-write,
granting them effective root on the host.

**Fix (applied 2026-06-19):**
- `bootstrap/compose/homepage/docker-compose.yml` — `:ro` added
- `bootstrap/compose/portainer/docker-compose.yml` — `:ro` added (was `:rw`)
- `bootstrap/compose/traefik/docker-compose.yml` — `:ro` (unchanged, was already `:ro`)
- `bootstrap/compose/uptime-kuma/docker-compose.yml` — `:ro` (unchanged)
- `bootstrap/compose/watchtower/docker-compose.yml` — **kept `:rw`** (required for image updates)
- `compose/nextcloud.yml` — `:ro` (was `:rw`)
- `compose/watchtower.yml` — `:ro`

**Documented exceptions:**
- **Watchtower** needs `:rw` to orchestrate image pulls and restarts.
- **Nextcloud AIO** — the AIO master container requires Docker orchestration.
  Documented as an accepted risk; the AIO container itself runs with
  `no-new-privileges` and a non-root UID.
- **Promtail** uses `unix:///var/run/docker.sock` for log metadata (label
  discovery). It's read-only at the docker-API level even though the underlying
  file mount is `:rw` (a file permission, not a Docker socket permission).

### 1.2 File Access Security
**Finding:** Initial concern about path canonicalization in `ai-agent/`.

**Fix (applied 2026-06-20):** See audit report §B1 and §B5 — `server_commands.py`
now uses `DOCKER_ROOT` env override and validates `compose_file.resolve().relative_to(DOCKER_ROOT)`.

### 1.3 SSH Execution Audit
**Finding:** `server_commands.py` accepted arbitrary `host` and `command` for
remote SSH.

**Fix (applied 2026-06-19):** `run_remote()` now:
- Validates `host` and `user` against `CONTAINER_RE`
- Looks up the command in `ALLOWED_REMOTE_COMMANDS` allowlist (no arbitrary input)
- Canonicalizes SSH keys under `~/.ssh` only

---

## Phase 2 — Implemented (2026-06-19)

See [`phase2-patch1.txt`](./phase2-patch1.txt) for the change list. All items
are now tracked in [`2026-06-20-REPORT.md`](./2026-06-20-REPORT.md).

## Phase 3+ — Roadmap

- Replace auto-keyscan in `bootstreep-dashboard` (separate repo).
- Migrate from `bash -lc` to `bash -c` for SSH commands (separate repo).
- Add BATS coverage for `docker_action` and `run_remote`.
- Add Prometheus rules for: docker.sock write attempts, brute-force on Traefik,
  failed Authentik logins, disk >85% on any service volume.