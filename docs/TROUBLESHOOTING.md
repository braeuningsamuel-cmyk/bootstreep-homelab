# Troubleshooting

## Bootstrap fails at phase X

1. Check the log: `cat bootstrap/logs/bootstrap-*.log | tail -100`
2. Run individual phase: `sudo bash bootstrap/scripts/0X-*.sh`
3. Most phases are idempotent — re-running is safe

## Docker service won't start

```bash
docker compose logs <service>
docker compose ps
docker compose restart <service>
```

## Traefik not getting certificate

1. Check Cloudflare API key is valid
2. Check DNS: `dig <your-domain>` should point to your server
3. Check Traefik logs: `docker logs traefik`
4. Verify 80/443 are open: `sudo ufw status`

## Authentik login fails

1. Reset admin via Authentik shell:
   ```bash
   docker exec -it authentik-server ak create_admin_user
   ```
2. Check database: `docker logs authentik-postgresql`

## Fail2Ban locked me out

```bash
sudo fail2ban-client set sshd unbanip <your-ip>
```

## Restore from backup

```bash
# List snapshots
restic -r s3:... snapshots

# Restore specific snapshot
restic -r s3:... restore <snapshot-id> --target /opt/docker
```

## Performance issues

1. Check resource usage: `btop`
2. Check Docker stats: `docker stats`
3. Check disk I/O: `iostat -xz 1`
4. Check logs in Loki: `https://grafana.<domain>`

## Network issues

```bash
# DNS
systemd-resolve --status

# NTP
chronyc tracking

# Connectivity
ping 1.1.1.1
curl -I https://github.com
```

## Reset entire stack

```bash
# Stop everything
cd bootstrap/compose/traefik && docker compose down
cd ../portainer && docker compose down
# ... repeat for each

# Or stop all Docker containers
docker stop $(docker ps -aq)

# Restart bootstrap
sudo ./bootstrap/bootstrap.sh
```

## Logs

- Bootstrap logs: `bootstrap/logs/`
- Docker logs: `docker logs <container>` or `docker compose logs`
- System logs: `journalctl -u <service>`
- Aggregated: Grafana Loki at `https://grafana.<domain>`