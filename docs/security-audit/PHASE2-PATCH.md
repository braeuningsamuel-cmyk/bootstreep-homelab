# Phase 2 Implementation: Command and File Access Hardening

**Date:** 2026-06-19
**Status:** IMPLEMENTED (and superseded by `docs/audit/2026-06-20-REPORT.md`)

---

## Changes applied in `bootstreep-homelab`

### `ai-agent/server_commands.py`
- `run_local()`: command names must be in `ALLOWED_LOCAL_COMMANDS`. Arbitrary
  shell is rejected. `subprocess.run` uses `shell=False`.
- `run_remote()`: `host`/`user` validated against `CONTAINER_RE`. `command_name`
  looked up in `ALLOWED_REMOTE_COMMANDS` allowlist. SSH key paths are
  canonicalized and restricted to `~/.ssh`. `StrictHostKeyChecking=accept-new`.
- `docker_action()`: action must be in `ALLOWED_DOCKER_ACTIONS = {ps, up, down,
  restart, logs}`. Container names validated against `CONTAINER_RE`. Compose
  file existence checked before exec.

### `ai-agent/telegram-bot.py`
- `ALLOWED_CMDS` whitelist: `bash, docker, df, hostname, python3, ss`.
- `is_allowed_command()`: enforces exact arg forms (e.g. `df -h`, `docker ps
  --format ...`, `docker compose -f <path> restart`, `docker logs --tail N <name>`).
- For `bash`/`python3` invocations: only allows paths in `ALLOWED_SCRIPTS`
  (5 scripts: health-check, update-all, backup-all, dnssec-test, daily.py).
- `cmd_restart` and `cmd_logs` enforce that the target container's `compose.yml`
  lives under `~/docker/<container>/compose.yml`.

### `compose/amp.yml` & `docker-compose-all.yml`
- AMP no longer mounts `/var/run/docker.sock` (the AMP instance control plane
  uses HTTP, not Docker socket).

### Docker Compose hardening (applied 2026-06-20)
- All 12 `bootstrap/compose/*/docker-compose.yml` now have
  `cap_drop: [ALL]` + `pids_limit: 256`.
- All have `no-new-privileges: true`.
- Portainer and others: docker.sock changed to `:ro` (Portainer only; Watchtower
  keeps `:rw`).

---

## Documented exceptions (2026-06-19 audit)

- **Nextcloud AIO** keeps read-only docker.sock access because the AIO image
  requires Docker orchestration. Tradeoff accepted; the container runs with
  `no-new-privileges` and a non-root UID.
- **Watchtower** keeps read-only docker.sock access for update orchestration.
  (Originally `:rw` — reduced to `:ro` on 2026-06-20 except where image updates
  are explicitly required.)
- **Promtail** uses docker.sock metadata for log discovery (label-based log
  routing).

---

## Verification (2026-06-19)

```bash
python -m py_compile ai-agent/server_commands.py ai-agent/telegram-bot.py
rg -n "docker\.sock|cap_drop: \[\]" compose docker-compose-all.yml
```

Both passed on 2026-06-19.

---

## Verification (2026-06-20, deep audit)

- `python -m py_compile ai-agent/*.py` — OK
- 78 YAML files validated
- 0 secrets in tracked files
- `git diff --stat`: 13 files changed, 88 insertions(+), 15 deletions(-)

See [`2026-06-20-REPORT.md`](./2026-06-20-REPORT.md) for the full report.