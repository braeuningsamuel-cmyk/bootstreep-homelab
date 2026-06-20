# Security Policy

## Supported Versions

| Version | Supported          |
|---------|--------------------|
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via email to: **security@example.com** (replace with your actual contact)

You should receive a response within 48 hours. If for some reason you do not, please follow up via email to ensure we received your original message.

Please include the following information:

- Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit it

## Security Best Practices

When deploying Bootstreep:

1. **Never commit secrets** — use `.env` files (gitignored)
2. **Use SSH keys only** — disable password authentication
3. **Enable UFW** — only ports 22, 80, 443 should be open
4. **Enable Fail2Ban** — protects against brute force
5. **Keep updated** — Watchtower auto-updates containers daily
6. **Monitor** — check Grafana dashboards regularly
7. **Backup** — verify Restic backups work
8. **Audit** — run `lynis audit system` quarterly

## Security Updates

Security updates are released as patch versions (e.g. 1.0.1 → 1.0.2) and announced in [CHANGELOG.md](CHANGELOG.md).

Subscribe to GitHub Releases to be notified:

1. Go to https://github.com/braeuningsamuel-cmyk/bootstreep-homelab
2. Click "Watch" → "Custom" → "Releases"

## Acknowledgments

We thank the following security researchers for responsibly disclosing vulnerabilities:

_None yet — be the first!_

## Disclosure Policy

When we receive a security report, we will:

1. Confirm receipt within 48 hours
2. Investigate and validate the issue
3. Develop a fix and release a patch
4. Publicly disclose the issue after the patch is released
5. Credit the reporter (if desired)