#!/usr/bin/env python3
"""
Bootstreep AI Agent – Telegram Bot
===================================
Dein persönlicher Server-Assistent via Telegram.

Funktionen:
- Server-Status abfragen (Docker, System, DNS)
- Dienste neustarten
- Logs abrufen
- Backup auslösen
- SSH-Befehle auf dem Server ausführen
- Aktuelle Belegung (CPU, RAM, Speicher)
- Updates ausführen
- Ollama-KI-Chat (optional)

Basiert auf dem Konzept aus Homelab-Server-Guide v3.3
"""

import os
import subprocess
import logging
from datetime import datetime
from pathlib import Path

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

# ─── Konfiguration ────────────────────────────────────────────────────────────
from dotenv import load_dotenv
load_dotenv(Path.home() / 'ai-agent' / '.env')

BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN', '')
ALLOWED_IDS = os.getenv('ALLOWED_CHAT_IDS', '')
ALLOWED_CHAT_IDS = [int(x.strip()) for x in ALLOWED_IDS.split(',') if x.strip()] if ALLOWED_IDS else []
SERVER_NAME = os.getenv('SERVER_NAME', 'Bootstreep')
OLLAMA_HOST = os.getenv('OLLAMA_HOST', 'http://127.0.0.1:11434')
OLLAMA_MODEL = os.getenv('OLLAMA_MODEL', 'mistral:7b')

logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# ─── Autorisierung ────────────────────────────────────────────────────────────
def authorized(func):
    """Decorator: Nur autorisierte Chat-IDs (ALLOWED_CHAT_IDS muss gesetzt sein)"""
    async def wrapper(update: Update, context: ContextTypes.DEFAULT_TYPE):
        if not update.effective_chat:
            return
        if not ALLOWED_CHAT_IDS:
            await update.message.reply_text('⛔ Keine Chat-IDs konfiguriert. Setze ALLOWED_CHAT_IDS in .env')
            return
        if update.effective_chat.id not in ALLOWED_CHAT_IDS:
            await update.message.reply_text('⛔ Nicht autorisiert.')
            return
        return await func(update, context)
    return wrapper

# ─── Shell-Ausführung ────────────────────────────────────────────────────────
ALLOWED_CMDS = {'docker', 'systemctl', 'journalctl', 'cat', 'ls', 'df', 'free',
                'uptime', 'ps', 'top', 'ip', 'ping', 'dig', 'curl', 'wget',
                'tail', 'head', 'grep', 'find', 'du', 'stat', 'whoami', 'id'}

def run_cmd(cmd: str, timeout: int = 30) -> str:
    """Führt einen sicheren Shell-Befehl aus."""
    import shlex
    try:
        parts = shlex.split(cmd)
        if not parts:
            return '❌ Leerer Befehl'
        base = parts[0].split('/')[-1]
        if base not in ALLOWED_CMDS:
            return f'❌ Befehl "{base}" nicht erlaubt. Erlaubt: {", ".join(sorted(ALLOWED_CMDS))}'
        result = subprocess.run(
            parts, shell=False, capture_output=True, text=True, timeout=timeout
        )
        out = result.stdout.strip()
        err = result.stderr.strip()
        if result.returncode != 0:
            return f'❌ Fehler ({result.returncode}):\n{err[:500]}'
        return out[:2000] if out else err[:500] or '✅ OK (keine Ausgabe)'
    except subprocess.TimeoutExpired:
        return '⏱ Timeout (30s)'
    except Exception as e:
        return f'❌ Exception: {e}'

# ─── BEFEHLE ──────────────────────────────────────────────────────────────────

@authorized
async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/start – Begrüßung und Hilfe"""
    help_text = (
        f'🤖 *{SERVER_NAME} AI Agent*\n\n'
        'Dein Server-Assistent. Verfügbare Befehle:\n\n'
        '*/status* – Server-Status (CPU, RAM, Docker)\n'
        '*/services* – Alle Docker-Container\n'
        '*/restart* `<name>` – Dienst neustarten\n'
        '*/logs* `<name>` – Letzte Logs eines Containers\n'
        '*/update* – System + Container updaten\n'
        '*/backup* – Backup auslösen\n'
        '*/health* – Health-Check\n'
        '*/df* – Speicherplatz\n'
        '*/network* – Netzwerk-Statistik\n'
        '*/dns* – DNS-Test\n'
        '*/exec* `<befehl>` – Beliebiges Kommando\n\n'
        '*/briefing* – Tägliche Zusammenfassung\n'
        '*/ask* `<frage>` – Frage an lokale KI (Ollama)\n\n'
        '📱 *Telegram-Integration:*\n'
        'Sende mir eine Nachricht – ich leite sie an die KI weiter'
    )
    await update.message.reply_text(help_text, parse_mode='Markdown')

@authorized
async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/status – Server-Status"""
    uptime = run_cmd('uptime -p')
    mem = run_cmd("free -h | awk '/^Mem:/{print $3\"/\"$2}'")
    cpu = run_cmd("top -bn1 | awk '/Cpu/{print $2}'")
    disk = run_cmd("df -h / | awk 'NR==2{print $3\"/\"$2\" (\"$5\")\"}'")
    docker = run_cmd('docker ps --format "{{.Names}}: {{.Status}}" | head -20')

    msg = (
        f'📊 *{SERVER_NAME} Status*\n'
        f'⏱ Uptime: `{uptime}`\n'
        f'💾 RAM: `{mem}`\n'
        f'⚙️ CPU: `{cpu}%`\n'
        f'💿 Festplatte: `{disk}`\n\n'
        f'🐳 *Docker:*\n`{docker or "Keine Container"}`'
    )
    await update.message.reply_text(msg, parse_mode='Markdown')

@authorized
async def cmd_services(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/services – Alle Dienste auflisten"""
    out = run_cmd("docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'")
    msg = f'🐳 *Dienste auf {SERVER_NAME}:*\n```\n{out}\n```'
    await update.message.reply_text(msg, parse_mode='Markdown')

@authorized
async def cmd_restart(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/restart <name> – Dienst neustarten"""
    if not context.args:
        await update.message.reply_text('Usage: /restart <container-name>')
        return
    name = context.args[0]
    out = run_cmd(f'docker restart {name}')
    await update.message.reply_text(f'🔄 Neustart von *{name}*:\n{out}', parse_mode='Markdown')

@authorized
async def cmd_logs(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/logs <name> – Letzte Logs"""
    if not context.args:
        await update.message.reply_text('Usage: /logs <container-name>')
        return
    name = context.args[0]
    lines = context.args[1] if len(context.args) > 1 else '30'
    out = run_cmd(f'docker logs --tail {lines} {name} 2>&1')
    msg = f'📋 *Logs: {name}* (letzte {lines} Zeilen)\n```\n{out[:3000]}\n```'
    await update.message.reply_text(msg, parse_mode='Markdown')

@authorized
async def cmd_update(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/update – Updates ausführen"""
    await update.message.reply_text('🔄 *Update gestartet...*', parse_mode='Markdown')
    out = run_cmd('bash ~/scripts/update-all.sh', timeout=120)
    await update.message.reply_text(f'✅ *Update abgeschlossen:*\n{out[:2000]}', parse_mode='Markdown')

@authorized
async def cmd_backup(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/backup – Backup auslösen"""
    await update.message.reply_text('💾 *Backup gestartet...*', parse_mode='Markdown')
    out = run_cmd('bash ~/scripts/backup-all.sh', timeout=120)
    await update.message.reply_text(f'✅ *Backup:*\n{out[:2000]}', parse_mode='Markdown')

@authorized
async def cmd_health(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/health – Health-Check"""
    out = run_cmd('bash ~/scripts/health-check.sh')
    await update.message.reply_text(f'🏥 *Health Check:*\n```\n{out[:3000]}\n```', parse_mode='Markdown')

@authorized
async def cmd_df(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/df – Speicherplatz"""
    out = run_cmd("df -h | grep -E '^/dev|Filesystem'")
    await update.message.reply_text(f'💿 *Speicherplatz:*\n```\n{out}\n```', parse_mode='Markdown')

@authorized
async def cmd_network(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/network – Netzwerk-Statistik"""
    ip = run_cmd("ip -4 addr show | grep inet | awk '{print $2}' | head -5")
    connections = run_cmd("ss -tulpn | head -20")
    msg = f'🌐 *Netzwerk {SERVER_NAME}:*\nIPs:\n`{ip}`\n\nOffene Ports:\n```\n{connections}\n```'
    await update.message.reply_text(msg, parse_mode='Markdown')

@authorized
async def cmd_dns(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/dns – DNS-Test"""
    out = run_cmd("dig google.de +short")
    pihole = run_cmd("docker exec pihole pihole -c -j 2>/dev/null | head -5 || echo 'n/a'")
    msg = f'🔍 *DNS-Test:*\nGoogle: `{out}`\nPi-hole: `{pihole}`'
    await update.message.reply_text(msg, parse_mode='Markdown')

@authorized
async def cmd_exec(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/exec <befehl> – Beliebiges Kommando"""
    if not context.args:
        await update.message.reply_text('Usage: /exec <shell-befehl>')
        return
    cmd = ' '.join(context.args)
    out = run_cmd(cmd, timeout=30)
    await update.message.reply_text(f'`$ {cmd}`\n```\n{out[:3000]}\n```', parse_mode='Markdown')

@authorized
async def cmd_ask(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/ask <frage> – Frage an lokale KI (Ollama)"""
    if not context.args:
        await update.message.reply_text('Usage: /ask <deine-frage>')
        return
    question = ' '.join(context.args)

    await update.message.reply_text('🧠 *Denke nach...*', parse_mode='Markdown')

    try:
        import requests
        payload = {
            'model': OLLAMA_MODEL,
            'prompt': f'Beantworte kurz und präzise auf Deutsch: {question}',
            'stream': False
        }
        resp = requests.post(f'{OLLAMA_HOST}/api/generate', json=payload, timeout=30)
        if resp.status_code == 200:
            answer = resp.json().get('response', 'Keine Antwort.')
            await update.message.reply_text(f'🧠 *{OLLAMA_MODEL}:*\n{answer[:2000]}', parse_mode='Markdown')
        else:
            await update.message.reply_text(f'Ollama-Fehler: {resp.status_code}')
    except Exception as e:
        await update.message.reply_text(f'Ollama nicht erreichbar: {e}')

@authorized
async def cmd_briefing(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """/briefing – Tägliche Zusammenfassung"""
    await update.message.reply_text('📰 *Erstelle Briefing...*', parse_mode='Markdown')
    try:
        from daily import get_briefing
        briefing = await get_briefing()
        await update.message.reply_text(briefing[:4000], parse_mode='Markdown')
    except ImportError:
        await update.message.reply_text('Daily Briefing-Modul nicht verfügbar.')
    except Exception as e:
        await update.message.reply_text(f'Fehler: {e}')

# ─── Freitext-Nachrichten ────────────────────────────────────────────────────
async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Fängt Freitext-Nachrichten und leitet sie an Ollama weiter."""
    if not update.message or not update.message.text:
        return

    text = update.message.text

    # Nur auf KI-Nachfragen antworten, wenn der Text kein Befehl ist
    if any(text.startswith(f'/{c}') for c in [
        'start', 'status', 'services', 'restart', 'logs', 'update',
        'backup', 'health', 'df', 'network', 'dns', 'exec', 'ask', 'briefing'
    ]):
        return

    # Kurz und Direkt – wie Jarvis
    if len(text) > 5:
        await update.message.reply_text('🤖 *Nachdenken...*', parse_mode='Markdown')
        try:
            import requests
            payload = {
                'model': OLLAMA_MODEL,
                'prompt': f'Du bist {SERVER_NAME} AI Agent. Antworte kurz, hilfreich, auf Deutsch: {text}',
                'stream': False
            }
            resp = requests.post(f'{OLLAMA_HOST}/api/generate', json=payload, timeout=30)
            if resp.status_code == 200:
                answer = resp.json().get('response', '🤷')
                await update.message.reply_text(answer[:2000])
            else:
                await update.message.reply_text(f'[Ollama: {resp.status_code}]')
        except Exception as e:
            await update.message.reply_text(f'[KI offline: {e}]')

# ─── MAIN ──────────────────────────────────────────────────────────────────────
def main():
    if not BOT_TOKEN:
        logger.error('TELEGRAM_BOT_TOKEN nicht gesetzt!')
        logger.error('Kopiere ai-agent/.env.example nach ~/ai-agent/.env und trage Token ein.')
        return

    app = Application.builder().token(BOT_TOKEN).build()

    app.add_handler(CommandHandler('start', cmd_start))
    app.add_handler(CommandHandler('status', cmd_status))
    app.add_handler(CommandHandler('services', cmd_services))
    app.add_handler(CommandHandler('restart', cmd_restart))
    app.add_handler(CommandHandler('logs', cmd_logs))
    app.add_handler(CommandHandler('update', cmd_update))
    app.add_handler(CommandHandler('backup', cmd_backup))
    app.add_handler(CommandHandler('health', cmd_health))
    app.add_handler(CommandHandler('df', cmd_df))
    app.add_handler(CommandHandler('network', cmd_network))
    app.add_handler(CommandHandler('dns', cmd_dns))
    app.add_handler(CommandHandler('exec', cmd_exec))
    app.add_handler(CommandHandler('ask', cmd_ask))
    app.add_handler(CommandHandler('briefing', cmd_briefing))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    logger.info(f'{SERVER_NAME} AI Agent startet...')
    app.run_polling()

if __name__ == '__main__':
    main()
