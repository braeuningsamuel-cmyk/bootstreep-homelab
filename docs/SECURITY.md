# Security Model

## Layered Defense

### 1. SSH Hardening
- PermitRootLogin no
- PasswordAuthentication no
- PubkeyAuthentication only
- MaxAuthTries 3
- AllowUsers enforced
- ClientAliveInterval 300

### 2. Firewall (UFW)
- Default deny incoming
- Default allow outgoing
- Open ports: 22, 80, 443
- Optional: 51820/udp (WireGuard), 41641/udp (Tailscale)

### 3. Fail2Ban
- SSH jail (3 retries)
- Traefik-auth jail (5 retries on 401/403)
- 1h ban time

### 4. Kernel Hardening (sysctl)
- Reverse path filtering
- SYN cookies
- ICMP broadcast ignore
- ASLR (randomize_va_space = 2)
- Protected symlinks/hardlinks

### 5. AppArmor
- All profiles enforced
- Additional profiles via aa-genprof

### 6. Docker
- No privileged containers (in compose stacks)
- Read-only docker.sock where possible
- Log rotation: max-size 10m, max-file 3
- Live-restore enabled
- overlay2 storage driver

### 7. Authentication
- Authentik SSO at `https://auth.<domain>`
- OIDC/OAuth2/LDAP support
- Signups disabled
- Invitation-only

### 8. Secrets Management
- All secrets in `.env` files (gitignored)
- Use Vaultwarden for password sharing
- Future: SOPS/Age for Git-encrypted secrets

## Audit

```bash
# Run security audit
sudo lynis audit system

# View AppArmor status
sudo aa-status

# View Fail2Ban status
sudo fail2ban-client status
```

## Incident Response

1. Check `journalctl -u <service>` for issues
2. Review `bootstrap/logs/` for bootstrap errors
3. Restore from Restic backup if data corruption
4. Review CrowdSec alerts for WAF events