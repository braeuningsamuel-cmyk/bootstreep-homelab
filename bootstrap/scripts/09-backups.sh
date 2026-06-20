#!/bin/bash
################################################################################
# Phase 9: Backup system (Restic + Rclone)
################################################################################
set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_DIR="${BOOTSTRAP_DIR}/config"
BACKUP_ROOT="${BACKUP_ROOT:-/opt/docker/backups}"

info "Phase 9: Backup system"

mkdir -p "${BACKUP_ROOT}"/{restic,rclone,db,configs}

apt-get install -y restic rclone

cat > "${BOOTSTRAP_DIR}/scripts/backup-all.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
TS=$(date +%Y%m%d-%H%M%S)
BACKUP_ROOT="/opt/docker/backups"

# Docker volumes
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  -v "${BACKUP_ROOT}:/backup" \
  alpine tar czf "/backup/docker-volumes-${TS}.tar.gz" /var/lib/docker/volumes 2>/dev/null || true

# Compose files
tar czf "${BACKUP_ROOT}/configs/compose-${TS}.tar.gz" /opt/docker/compose /opt/docker/stacks

# Restic snapshot
if [[ -n "${RESTIC_REPOSITORY:-}" ]]; then
    restic backup /opt/docker/data /opt/docker/configs
    restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6
fi

echo "[✓] Backup completed: ${TS}"
EOF
chmod +x "${BOOTSTRAP_DIR}/scripts/backup-all.sh"

cat > /etc/cron.d/bootstreep-backup <<'EOF'
0 3 * * * root /opt/docker/scripts/backup-all.sh >> /var/log/bootstreep-backup.log 2>&1
EOF

ok "Backup system configured"