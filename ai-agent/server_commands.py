"""
Bootstreep AI Agent – Server Commands
=====================================
Low-Level-Funktionen für SSH-Homelab-Steuerung.
Wird vom Telegram-Bot verwendet.
"""

import subprocess
import os
from pathlib import Path

from dotenv import load_dotenv
load_dotenv(Path.home() / 'ai-agent' / '.env')

SSH_USER = os.getenv('SSH_USER', 'admin')
SERVER_IP = os.getenv('SERVER_IP', '192.168.178.20')
SSH_KEY_PATH = os.getenv('SSH_KEY_PATH', os.path.expanduser('~/.ssh/id_ed25519'))


def ssh_run(cmd: str, timeout: int = 30) -> str:
    """Führt einen Befehl per SSH auf dem Homelab-Server aus."""
    ssh_cmd = [
        'ssh', '-i', SSH_KEY_PATH,
        '-o', 'StrictHostKeyChecking=no',
        '-o', 'ConnectTimeout=5',
        f'{SSH_USER}@{SERVER_IP}',
        cmd
    ]
    try:
        result = subprocess.run(
            ssh_cmd, capture_output=True, text=True, timeout=timeout
        )
        out = result.stdout.strip()
        err = result.stderr.strip()
        if result.returncode != 0:
            return f'Fehler ({result.returncode}): {err[:500]}'
        return out[:2000] or '✅ OK'
    except subprocess.TimeoutExpired:
        return '⏱ Timeout'
    except Exception as e:
        return f'❌ {e}'


def docker_list() -> str:
    """Listet alle laufenden Container."""
    return ssh_run("docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")


def docker_restart(name: str) -> str:
    """Startet einen Container neu."""
    return ssh_run(f'docker restart {name}')


def docker_logs(name: str, lines: int = 30) -> str:
    """Zeigt die letzten Logs eines Containers."""
    return ssh_run(f'docker logs --tail {lines} {name} 2>&1')


def system_status() -> dict:
    """Gibt System-Informationen als Dict zurück."""
    cpu = ssh_run("top -bn1 | awk '/Cpu/{print $2}'")
    mem = ssh_run("free -h | awk '/^Mem:/{print $3\"/\"$2}'")
    disk = ssh_run("df -h / | awk 'NR==2{print $3\"/\"$2}'")
    uptime = ssh_run('uptime -p')
    docker = ssh_run("docker ps --format '{{.Names}}' | paste -sd ','")
    return {
        'cpu': cpu,
        'memory': mem,
        'disk': disk,
        'uptime': uptime,
        'docker_containers': docker
    }


def update_all() -> str:
    """Führt Update-All Script aus."""
    return ssh_run('bash ~/scripts/update-all.sh', timeout=120)


def backup_all() -> str:
    """Führt Backup-Script aus."""
    return ssh_run('bash ~/scripts/backup-all.sh', timeout=120)


def health_check() -> str:
    """Führt Health-Check aus."""
    return ssh_run('bash ~/scripts/health-check.sh')
