# Security Policy

## Reporting a Vulnerability

**Do not** open public issues for security vulnerabilities.

Use GitHub's Security Advisory feature:
https://github.com/braeuningsamuel-cmyk/bootstreep-homelab/security/advisories

We will acknowledge within 48 hours and provide a fix timeline.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 4.1.x   | ✅ Yes |
| 4.0.x   | ⚠️ Critical fixes only |
| < 4.0   | ❌ No |

## Best Practices

- ✅ SSH-Key-Authentifizierung (nie Passwort)
- ✅ Pi-hole Passwort: min. 12 Zeichen, generiert via `openssl rand -base64 16`
- ✅ 2FA auf GitHub
- ✅ `pre-commit install` für Secret-Scanning (gitleaks)
- ✅ Regelmäßige Backups: `~/scripts/backup-all.sh`
- ✅ Updates: `~/scripts/update-all.sh` (Sonntag 3:00)
- ✅ CrowdSec aktiv (optional) oder Fail2Ban
- ✅ Authentik SSO für alle Web-Dienste (optional)
- ✅ Rate Limiting in Caddy (20 req/s/IP)
- ✅ UFW aktiv: `sudo ufw status`
- ✅ Kernel gehärtet: sysctl (BBR, rp_filter, syncookies, martians)

## Built-in Hardening (v4.0.0)

- **SSH**: Nur Ed25519, starke Ciphers/MACs/Kex, keine Passwörter, RekeyLimit
- **UFW**: Nur LAN-Zugriff auf Web-Interfaces, Rate-Limiting
- **Fail2Ban**: 3 Versuche → 1h Ban (Recidive: 1 Woche)
- **Docker**: `no-new-privileges`, `cap_drop: ALL`, Logging rotiert, userland-proxy: false
- **AppArmor**: aktiviert + auditd
- **Seccomp**: Default Docker Seccomp-Profil aktiv
- **Privacy**: IPv6 aus, DoH zu Cloudflare/Quad9, Telemetrie deaktiviert
- **Kernel**: rp_filter=1, syncookies=1, martians logged, ICMP Broadcast ignore
- **TCP**: BBR Congestion Control, FastOpen, große Puffer
- **Logs**: Regelmäßige IP-Anonymisierung via sanitize-logs.sh
