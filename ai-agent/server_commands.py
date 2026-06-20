#!/usr/bin/env python3
"""
Server-Commands für AI-Agent v3.13.0
Privacy-First: Lokale Ausführung, keine externen Calls
"""

import subprocess
from pathlib import Path
import re


ALLOWED_LOCAL_COMMANDS = {
    "df": [["df", "-h"]],
    "free": [["free", "-h"]],
    "docker_ps": [["docker", "ps", "--format", "table {{.Names}}\t{{.Status}}\t{{.Ports}}"]],
    "ufw_status": [["ufw", "status", "verbose"]],
    "fail2ban_status": [["fail2ban-client", "status"]],
}

ALLOWED_REMOTE_COMMANDS = {
    "status": "systemctl --failed --no-pager",
    "disk": "df -h",
    "memory": "free -h",
    "docker": "docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'",
}

ALLOWED_DOCKER_ACTIONS = {"ps", "up", "down", "restart", "logs"}
CONTAINER_RE = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}$")


def run_local(command_name: str, timeout: int = 30) -> tuple:
    commands = ALLOWED_LOCAL_COMMANDS.get(command_name)
    if not commands:
        return False, f"Nicht erlaubt: {command_name}"
    try:
        ok = True
        output = []
        for cmd in commands:
            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=timeout, shell=False
            )
            ok = ok and result.returncode == 0
            output.append((result.stdout or result.stderr).strip())
        return ok, "\n".join(part for part in output if part)
    except Exception as e:
        return False, str(e)


def run_command(cmd: list, timeout: int = 30) -> tuple:
    """Compatibility wrapper for callers that pass exact safe commands."""
    for name, commands in ALLOWED_LOCAL_COMMANDS.items():
        if cmd in commands:
            return run_local(name, timeout)
    return False, f"Nicht erlaubt: {' '.join(cmd) if cmd else ''}"


def run_remote(host: str, user: str, command_name: str, key: str = None) -> tuple:
    if not CONTAINER_RE.match(host) or not CONTAINER_RE.match(user):
        return False, "Ungueltiger Host oder Benutzer"
    cmd = ALLOWED_REMOTE_COMMANDS.get(command_name)
    if not cmd:
        return False, f"Remote-Kommando nicht erlaubt: {command_name}"
    ssh_cmd = [
        "ssh",
        "-o",
        "StrictHostKeyChecking=accept-new",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "BatchMode=yes",
        f"{user}@{host}",
        cmd,
    ]
    if key:
        key_path = Path(key).expanduser().resolve()
        ssh_dir = (Path.home() / ".ssh").resolve()
        if ssh_dir not in key_path.parents or not key_path.is_file():
            return False, "SSH-Key nicht erlaubt"
        ssh_cmd.insert(2, "-i")
        ssh_cmd.insert(3, str(key_path))
    try:
        result = subprocess.run(
            ssh_cmd, capture_output=True, text=True, timeout=30, shell=False
        )
        return result.returncode == 0, (result.stdout or result.stderr).strip()
    except Exception as e:
        return False, str(e)


def docker_action(action: str, container: str = None) -> tuple:
    if action not in ALLOWED_DOCKER_ACTIONS:
        return False, f"Unbekannte Aktion: {action}"
    if container:
        if not CONTAINER_RE.match(container):
            return False, f"Ungueltiger Containername: {container}"
        compose_dir = Path.home() / "docker"
        if not compose_dir.exists():
            return False, f"Compose-Verzeichnis nicht gefunden: {compose_dir}"
        for sub in compose_dir.iterdir():
            if not sub.is_dir():
                continue
            compose_file = sub / "compose.yml"
            if not compose_file.exists():
                continue
            check = subprocess.run(
                [
                    "docker",
                    "ps",
                    "--filter",
                    f"name={container}",
                    "--format",
                    "{{.Names}}",
                ],
                capture_output=True,
                text=True,
                shell=False,
            )
            if container in check.stdout.splitlines():
                cmd = ["docker", "compose", "-f", str(compose_file)]
                if action == "up":
                    cmd.append("up")
                    cmd.append("-d")
                elif action == "down":
                    cmd.append("down")
                elif action == "restart":
                    cmd.append("restart")
                elif action == "logs":
                    cmd.extend(["logs", "--tail", "50"])
                result = subprocess.run(
                    cmd, capture_output=True, text=True, shell=False
                )
                return result.returncode == 0, (result.stdout or result.stderr).strip()
        return False, f"Container nicht gefunden: {container}"
    else:
        if action != "ps":
            return False, "Docker-Aktion ohne Container nicht erlaubt"
        cmd = ["docker", "ps"]
        result = subprocess.run(cmd, capture_output=True, text=True, shell=False)
        return result.returncode == 0, (result.stdout or result.stderr).strip()


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("Usage: server_commands.py <action> [container]")
        sys.exit(1)
    action = sys.argv[1]
    container = sys.argv[2] if len(sys.argv) > 2 else None
    ok, out = docker_action(action, container)
    print(out)
    sys.exit(0 if ok else 1)
