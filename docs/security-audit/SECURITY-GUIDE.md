# Security Audit — Docker Socket Exposure (Phase 1)

**Originally:** 2026-06-18 working notes
**Now:** archived alongside the deep audit in [`2026-06-20-REPORT.md`](./2026-06-20-REPORT.md)

---

## Critical Risk #3 — Phase 1 Fix Required

Services with `docker.sock` mount MUST be audited and restricted.

**Watchtower (allowed)**: Only if you need auto-updates.

```yaml
# REMOVED from amp.yml, portainer.yml
volumes:
  /var/run/docker.sock:/var/run/docker.sock   <-- DANGER!
```

**Why it's dangerous:** A container with read-write access to
`/var/run/docker.sock` can issue `docker run --privileged -v /:/host` and get
root on the host kernel. Even read-only socket access allows enumeration of
all containers, their env vars (often containing secrets), and their network
topology.

---

## Mitigation table (current state)

| Service | Socket mount | Verdict |
|---|---|---|
| `homepage` | `:ro` | OK |
| `portainer` | `:ro` | OK (post-2026-06-20 patch) |
| `traefik` | `:ro` | OK |
| `uptime-kuma` | `:ro` | OK |
| `watchtower` | `:rw` | **Required** for image updates |
| `nextcloud` | `:ro` | OK (AIO exception documented) |
| `promtail` | `unix://` (metadata) | OK (read-only API calls) |

## Other audit notes

- All docker-compose files in this repo are scanned weekly by `security-audit.yml` CI.
- `cap_drop: [ALL]` is the new baseline (applied 2026-06-20).
- `no-new-privileges: true` is now universal.

See [`PHASE1-NOTES.md`](./PHASE1-NOTES.md) for the chronological change log.