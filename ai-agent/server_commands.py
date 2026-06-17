#!/usr/bin/env python3
"""
Server-Commands für AI-Agent v3.13.0
Privacy-First: Lokale Ausführung, keine externen Calls
"""

import subprocess
import os
from pathlib import Path

def run_local(cmd: list, timeout: int = 30) -> tuple:
    ALLOWED = {"docker", "systemctl", "ufw", "fail2ban-client", "ls", "cat", "df", "free"}
    if not cmd or cmd[0] not in ALLOWED:
        return False, f"Nicht erlaubt: {cmd[0] if cmd else ''}"
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout, shell=False)
        return True, (result.stdout or result.stderr).strip()
    except Exception as e:
        return False, str(e)

def run_remote(host: str, user: str, cmd: str, key: str = None) -> tuple:
    ssh_cmd = [
        "ssh",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "BatchMode=yes",
        f"{user}@{host}",
        cmd,
    ]
    if key:
        ssh_cmd.insert(2, "-i")
        ssh_cmd.insert(3, key)
    try:
        result = subprocess.run(ssh_cmd, capture_output=True, text=True, timeout=30, shell=False)
        return result.returncode == 0, (result.stdout or result.stderr).strip()
    except Exception as e:
        return False, str(e)

def docker_action(action: str, container: str = None) -> tuple:
    if container:
        compose_dir = Path.home() / "docker"
        for sub in compose_dir.iterdir():
            if not sub.is_dir():
                continue
            compose_file = sub / "compose.yml"
            if not compose_file.exists():
                continue
            check = subprocess.run(
                ["docker", "ps", "--filter", f"name={container}", "--format", "{{.Names}}"],
                capture_output=True, text=True, shell=False
            )
            if container in check.stdout:
                cmd = ["docker", "compose", "-f", str(compose_file)]
                if action == "up":
                    cmd.append("up"); cmd.append("-d")
                elif action == "down":
                    cmd.append("down")
                elif action == "restart":
                    cmd.append("restart")
                elif action == "logs":
                    cmd.extend(["logs", "--tail", "50"])
                else:
                    return False, f"Unbekannte Aktion: {action}"
                result = subprocess.run(cmd, capture_output=True, text=True, shell=False)
                return result.returncode == 0, (result.stdout or result.stderr).strip()
        return False, f"Container nicht gefunden: {container}"
    else:
        cmd = ["docker", action]
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
