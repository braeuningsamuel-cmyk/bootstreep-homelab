#!/usr/bin/env python3
"""
Daily Briefing v3.13.0 – Wetter, Aktien, News, Kalender
Privacy: Alle Daten lokal / über direkte API-Calls (kein Tracking)
"""

import os
import sys
import json
import smtplib
import email
import imaplib
import urllib.request
import urllib.parse
import xml.etree.ElementTree as ET
from datetime import datetime, timedelta
from pathlib import Path

try:
    from dotenv import load_dotenv
except ImportError:
    print("python-dotenv fehlt")
    sys.exit(1)

env_path = Path.home() / "ai-agent" / ".env"
if env_path.exists():
    load_dotenv(env_path)

def get_weather() -> str:
    api_key = os.getenv("OPENWEATHER_API_KEY")
    lat = os.getenv("LATITUDE", "52.52")
    lon = os.getenv("LONGITUDE", "13.40")
    if not api_key:
        return "🌤️ Wetter: API-Key fehlt"
    try:
        url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={api_key}&units=metric&lang=de"
        with urllib.request.urlopen(url, timeout=10) as r:
            data = json.loads(r.read())
        temp = data["main"]["temp"]
        desc = data["weather"][0]["description"]
        city = data.get("name", "Unbekannt")
        return f"🌤️ Wetter in {city}: {temp:.1f}°C, {desc}"
    except Exception as e:
        return f"🌤️ Wetter: Fehler ({e})"

def get_stocks() -> str:
    symbols = os.getenv("STOCK_SYMBOLS", "").split(",")
    if not symbols or not symbols[0]:
        return "📈 Aktien: keine Symbole konfiguriert"
    lines = ["📈 Aktien:"]
    for sym in symbols[:5]:
        sym = sym.strip()
        if not sym:
            continue
        try:
            url = f"https://query1.finance.yahoo.com/v8/finance/chart/{sym}?interval=1d&range=1d"
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=10) as r:
                data = json.loads(r.read())
            meta = data["chart"]["result"][0]["meta"]
            price = meta["regularMarketPrice"]
            prev = meta.get("chartPreviousClose", price)
            change = ((price - prev) / prev) * 100
            emoji = "🟢" if change >= 0 else "🔴"
            lines.append(f"  {emoji} {sym}: ${price:.2f} ({change:+.2f}%)")
        except Exception as e:
            lines.append(f"  ⚠️ {sym}: Fehler")
    return "\n".join(lines)

def get_news() -> str:
    feeds_str = os.getenv("NEWS_FEEDS", "")
    if not feeds_str:
        return "📰 News: keine Feeds konfiguriert"
    feeds = feeds_str.split(",")
    lines = ["📰 Top-News:"]
    for feed_url in feeds[:3]:
        feed_url = feed_url.strip()
        if not feed_url:
            continue
        try:
            with urllib.request.urlopen(feed_url, timeout=10) as r:
                content = r.read()
            root = ET.fromstring(content)
            ns = {"atom": "http://www.w3.org/2005/Atom"}
            items = root.findall(".//item") or root.findall(".//atom:entry", ns)
            for item in items[:2]:
                title = (item.find("title") or item.find("atom:title", ns)).text
                title = title.strip()[:80]
                lines.append(f"  • {title}")
        except Exception:
            continue
    return "\n".join(lines)

def get_emails() -> str:
    user = os.getenv("GMAIL_USER")
    password = os.getenv("GMAIL_APP_PASSWORD")
    if not user or not password:
        return "📧 E-Mail: nicht konfiguriert"
    try:
        M = imaplib.IMAP4_SSL("imap.gmail.com")
        M.login(user, password)
        M.select("INBOX")
        since = (datetime.now() - timedelta(days=1)).strftime("%d-%b-%Y")
        typ, data = M.search(None, f'(SINCE {since})')
        ids = data[0].split()
        lines = [f"📧 E-Mails (letzte 24h): {len(ids)}"]
        for num in ids[:3]:
            typ, msg_data = M.fetch(num, "(RFC822.HEADER)")
            if msg_data and msg_data[0]:
                raw = msg_data[0][1].decode("utf-8", errors="ignore")
                msg = email.message_from_string(raw)
                subj = msg.get("Subject", "(kein Betreff)")[:60]
                frm = msg.get("From", "")[:40]
                lines.append(f"  • {subj} ({frm})")
        M.logout()
        return "\n".join(lines)
    except Exception as e:
        return f"📧 E-Mail: Fehler ({e})"

def get_calendar() -> str:
    url = os.getenv("CALENDAR_ICS_URL")
    if not url:
        return "📅 Kalender: nicht konfiguriert"
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            content = r.read().decode("utf-8", errors="ignore")
        events = []
        for block in content.split("BEGIN:VEVENT")[1:]:
            end = block.find("END:VEVENT")
            event = block[:end]
            summary = ""
            dtstart = ""
            for line in event.split("\n"):
                if line.startswith("SUMMARY:"):
                    summary = line[8:].strip()
                elif line.startswith("DTSTART:"):
                    dtstart = line[8:].strip()[:16]
            if summary:
                events.append(f"  • {dtstart}: {summary[:50]}")
        if events:
            return "📅 Termine heute:\n" + "\n".join(events[:5])
        return "📅 Keine Termine"
    except Exception as e:
        return f"📅 Kalender: Fehler ({e})"

def main():
    today = datetime.now().strftime("%d.%m.%Y")
    sections = [
        f"📰 Bootstreep Daily Briefing – {today}",
        "",
        get_weather(),
        "",
        get_stocks(),
        "",
        get_news(),
        "",
        get_emails(),
        "",
        get_calendar(),
    ]
    print("\n".join(sections))

    if "--telegram" in sys.argv:
        bot_token = os.getenv("TELEGRAM_BOT_TOKEN")
        chat_id = os.getenv("BRIEFING_CHAT_ID")
        if bot_token and chat_id:
            try:
                text = "\n".join(sections)
                url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
                data = urllib.parse.urlencode({
                    "chat_id": chat_id,
                    "text": text[:4000],
                    "parse_mode": "Markdown",
                }).encode()
                urllib.request.urlopen(url, data=data, timeout=10)
                print(f"\n✓ An Telegram gesendet")
            except Exception as e:
                print(f"\n⚠ Telegram-Fehler: {e}")

if __name__ == "__main__":
    main()
