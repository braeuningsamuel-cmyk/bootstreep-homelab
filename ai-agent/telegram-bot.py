#!/usr/bin/env python3
"""
Bootstreep AI Agent – Telegram Bot v4.0.0
Privacy-First: lokale KI via LiteLLM, command whitelist, shell=False
"""

import logging
import os
import subprocess
import sys
from pathlib import Path

import requests

try:
    from dotenv import load_dotenv
    from telegram import Update
    from telegram.constants import ParseMode
    from telegram.ext import (
        Application,
        CommandHandler,
        ContextTypes,
        MessageHandler,
        filters,
    )
except ImportError:
    print(
        "Dependencies fehlen: source ~/ai-agent/venv/bin/activate && pip install -r requirements.txt"
    )
    sys.exit(1)

env_path = Path.home() / "ai-agent" / ".env"
if env_path.exists():
    load_dotenv(env_path)
else:
    print(f"FEHLER: {env_path} nicht gefunden!")
    sys.exit(1)

logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    level=os.getenv("LOG_LEVEL", "INFO"),
)
logger = logging.getLogger("ai-agent")

TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
ALLOWED_CHATS = set(
    int(x.strip()) for x in os.getenv("ALLOWED_CHAT_IDS", "").split(",") if x.strip()
)

if not TOKEN:
    print("FEHLER: TELEGRAM_BOT_TOKEN nicht gesetzt!")
    sys.exit(1)

if not ALLOWED_CHATS:
    print("FEHLER: ALLOWED_CHAT_IDS ist leer – Bot würde auf NIEMANDEN reagieren!")
    sys.exit(1)

ALLOWED_CMDS = {
    "docker",
    "systemctl",
    "ufw",
    "fail2ban-client",
    "tail",
    "cat",
    "ls",
    "df",
    "free",
    "uptime",
    "dig",
    "ping",
    "curl",
    "ssh",
}


def check_auth(update: Update) -> bool:
    if not ALLOWED_CHATS:
        return False
    return update.effective_chat.id in ALLOWED_CHATS


def run_cmd(cmd: list, timeout: int = 30) -> tuple:
    if not cmd or cmd[0] not in ALLOWED_CMDS:
        return False, f"Kommando nicht erlaubt: {cmd[0] if cmd else ''}"
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
            shell=False,
        )
        return True, (result.stdout or result.stderr or "(leer)").strip()[:3500]
    except subprocess.TimeoutExpired:
        return False, "Timeout"
    except Exception as e:
        return False, str(e)


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    await update.message.reply_text(
        "🏠 *Bootstreep AI Agent*\n\n"
        "/status – System-Status\n/services – Laufende Container\n"
        "/restart <name> – Dienst neustarten\n/logs <name> – Logs anzeigen\n"
        "/update – System + Container updaten\n/backup – Backup erstellen\n"
        "/health – Health-Check\n/df – Speicherplatz\n"
        "/network – Netzwerk-Info\n/dns – DNS-Test\n"
        "/ask <frage> – Frage an lokale KI\n/briefing – Tägliche Zusammenfassung\n\n"
        f"User-ID: `{update.effective_chat.id}`",
        parse_mode=ParseMode.MARKDOWN,
    )


async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    ok, out = run_cmd(["bash", str(Path.home() / "scripts" / "health-check.sh")])
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_services(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    ok, out = run_cmd(
        ["docker", "ps", "--format", "table {{.Names}}\t{{.Status}}\t{{.Ports}}"]
    )
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_restart(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    if not context.args:
        await update.message.reply_text("Usage: /restart <container>")
        return
    container = context.args[0]
    await update.message.reply_text(f"🔄 Neustart: {container}...")
    ok, out = run_cmd(
        [
            "docker",
            "compose",
            "-f",
            f"{Path.home()}/docker/{container}/compose.yml",
            "restart",
        ],
        timeout=60,
    )
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_logs(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    if not context.args:
        await update.message.reply_text("Usage: /logs <container> [anzahl]")
        return
    container = context.args[0]
    lines = context.args[1] if len(context.args) > 1 else "50"
    ok, out = run_cmd(["docker", "logs", "--tail", lines, container])
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_update(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    await update.message.reply_text("🔄 Update startet (kann dauern)...")
    ok, out = run_cmd(
        ["bash", str(Path.home() / "scripts" / "update-all.sh")], timeout=900
    )
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_backup(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    await update.message.reply_text("💾 Backup startet...")
    ok, out = run_cmd(
        ["bash", str(Path.home() / "scripts" / "backup-all.sh")], timeout=900
    )
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_health(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    ok, out = run_cmd(["bash", str(Path.home() / "scripts" / "health-check.sh")])
    await update.message.reply_text(
        f"```\n{out[:3500]}\n```", parse_mode=ParseMode.MARKDOWN
    )


async def cmd_df(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    ok, out = run_cmd(["df", "-h"])
    await update.message.reply_text(f"```\n{out}\n```", parse_mode=ParseMode.MARKDOWN)


async def cmd_network(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    hostname = run_cmd(["hostname", "-I"])[1]
    listening = run_cmd(["ss", "-tlnp"])[1]
    await update.message.reply_text(
        f"IPs: `{hostname.strip()}`\n\nListening:\n```\n{listening[:2000]}\n```",
        parse_mode=ParseMode.MARKDOWN,
    )


async def cmd_dns(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    ok, out = run_cmd(["bash", str(Path.home() / "scripts" / "dnssec-test.sh")])
    await update.message.reply_text(f"```\n{out}\n```", parse_mode=ParseMode.MARKDOWN)


async def cmd_ask(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    if not context.args:
        await update.message.reply_text("Usage: /ask <frage>")
        return
    question = " ".join(context.args)
    await update.message.reply_text("🤔 Denke nach...")
    litellm_url = os.getenv("LITELLM_URL", "http://127.0.0.1:4000")
    litellm_key = os.getenv("LITELLM_API_KEY", "sk-bootstreep")
    model = os.getenv("LITELLM_MODEL", "mistral")
    try:
        resp = requests.post(
            f"{litellm_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {litellm_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": model,
                "messages": [{"role": "user", "content": question}],
                "stream": False,
            },
            timeout=120,
        )
        resp.raise_for_status()
        answer = resp.json()["choices"][0]["message"]["content"]
        await update.message.reply_text(f"🤖 {answer[:3500]}")
    except Exception as e:
        await update.message.reply_text(f"Fehler: {str(e)[:500]}")


async def cmd_briefing(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    await update.message.reply_text("📰 Briefing wird erstellt...")
    ok, out = run_cmd(
        ["python3", str(Path.home() / "ai-agent" / "daily.py")], timeout=120
    )
    await update.message.reply_text(out[:3500])


async def unknown(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not check_auth(update):
        return
    await update.message.reply_text("❓ Unbekannter Befehl. /start für Hilfe.")


def main():
    logger.info("Starting Bot...")
    app = Application.builder().token(TOKEN).build()

    handlers = [
        CommandHandler("start", cmd_start),
        CommandHandler("help", cmd_start),
        CommandHandler("status", cmd_status),
        CommandHandler("services", cmd_services),
        CommandHandler("restart", cmd_restart),
        CommandHandler("logs", cmd_logs),
        CommandHandler("update", cmd_update),
        CommandHandler("backup", cmd_backup),
        CommandHandler("health", cmd_health),
        CommandHandler("df", cmd_df),
        CommandHandler("network", cmd_network),
        CommandHandler("dns", cmd_dns),
        CommandHandler("ask", cmd_ask),
        CommandHandler("briefing", cmd_briefing),
        MessageHandler(filters.COMMAND, unknown),
    ]
    for h in handlers:
        app.add_handler(h)

    logger.info(f"Bot läuft. Erlaubte Chats: {ALLOWED_CHATS}")
    app.run_polling(drop_pending_updates=True)


if __name__ == "__main__":
    main()
