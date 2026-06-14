# Security Policy

## Reporting a Vulnerability

We take the security of Bootstreep Homelab seriously. If you discover a security vulnerability, please report it responsibly.

**Do not** open a public issue for security vulnerabilities.

Instead, send a description to the repository maintainer via GitHub Issues with the label `security`.

We will acknowledge receipt within 48 hours and provide a timeline for the fix.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.x     | :white_check_mark: |
| < 3.0   | :x:                |

## Best Practices for Users

- Run the bootstrap only on trusted networks
- Change default passwords (Pi-hole: admin, etc.)
- Enable 2FA on GitHub account
- Keep your system updated: sudo apt update && sudo apt upgrade
- Regularly backup Docker volumes: bash ~/scripts/backup-all.sh
