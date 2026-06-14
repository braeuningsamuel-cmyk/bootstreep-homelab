#!/usr/bin/env python3
"""
Bootstreep AI Agent – Daily Briefing
=====================================
Erstellt eine tägliche Zusammenfassung mit:
- Wetter
- Aktienkurse
- Tech-News (RSS)
- Termine (Kalender)
- Ungelesene E-Mails (optional)

Usage:
    from daily_briefing import get_briefing
    briefing = await get_briefing()
"""

import os
import asyncio
from datetime import datetime, date
from pathlib import Path
from xml.etree import ElementTree

from dotenv import load_dotenv
load_dotenv(Path.home() / 'ai-agent' / '.env')

import aiohttp

SERVER_NAME = os.getenv('SERVER_NAME', 'Bootstreep')
NEWS_RSS_URLS = os.getenv('NEWS_RSS_URLS', 'https://rss.nytimes.com/services/xml/rss/nyt/World.xml,https://feeds.bbci.co.uk/news/rss.xml')
STOCK_TICKERS = os.getenv('STOCK_TICKERS', 'AAPL,MSFT,GOOGL,TSLA').split(',')
OPENWEATHER_API_KEY = os.getenv('OPENWEATHER_API_KEY', '')
WEATHER_CITY = os.getenv('WEATHER_CITY', 'Berlin')
GMAIL_USER = os.getenv('GMAIL_USER', '')
GMAIL_APP_PASSWORD = os.getenv('GMAIL_APP_PASSWORD', '')
CALENDAR_ICS_URL = os.getenv('CALENDAR_ICS_URL', '')

# ─── Wetter ───────────────────────────────────────────────────────────────────
async def get_weather() -> str:
    if not OPENWEATHER_API_KEY:
        return '🌤 Wetter: kein API-Key (OPENWEATHER_API_KEY)'
    try:
        url = f'https://api.openweathermap.org/data/2.5/weather?q={WEATHER_CITY}&appid={OPENWEATHER_API_KEY}&units=metric&lang=de'
        async with aiohttp.ClientSession() as session:
            async with session.get(url, timeout=10) as resp:
                data = await resp.json()
                temp = data['main']['temp']
                desc = data['weather'][0]['description']
                humidity = data['main']['humidity']
                return f'🌤 {WEATHER_CITY}: {temp}°C, {desc}, Luftfeuchte {humidity}%'
    except Exception as e:
        return f'🌤 Wetter: Fehler ({e})'

# ─── Aktien ────────────────────────────────────────────────────────────────────
async def get_stocks() -> str:
    if not STOCK_TICKERS:
        return ''
    lines = []
    for ticker in STOCK_TICKERS:
        ticker = ticker.strip()
        if not ticker:
            continue
        try:
            url = f'https://query1.finance.yahoo.com/v8/finance/chart/{ticker}?interval=1d'
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=10) as resp:
                    data = await resp.json()
                    price = data['chart']['result'][0]['meta']['regularMarketPrice']
                    prev = data['chart']['result'][0]['meta']['previousClose']
                    change = ((price - prev) / prev) * 100
                    sign = '+' if change >= 0 else ''
                    lines.append(f'  {ticker}: ${price:.2f} ({sign}{change:.1f}%)')
        except Exception:
            lines.append(f'  {ticker}: n/a')
    return '📈 *Aktien:*\n' + '\n'.join(lines)

# ─── News ─────────────────────────────────────────────────────────────────────
async def get_news() -> str:
    urls = [u.strip() for u in NEWS_RSS_URLS.split(',') if u.strip()]
    if not urls:
        return ''
    headlines = []
    for url in urls[:2]:  # max 2 Feeds
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, timeout=10) as resp:
                    text = await resp.text()
                    root = ElementTree.fromstring(text)
                    ns = {'': 'http://www.w3.org/2005/Atom'}
                    # Versuche Atom
                    entries = root.findall('.//entry', ns) or root.findall('.//item')
                    for entry in entries[:4]:
                        title_el = entry.find('title')
                        if title_el is not None:
                            headlines.append(f'• {title_el.text[:120]}')
        except Exception:
            pass
    if not headlines:
        return ''
    return '📰 *News:*\n' + '\n'.join(headlines[:8])

# ─── E-Mail (Zusammenfassung) ────────────────────────────────────────────────
async def get_emails() -> str:
    if not GMAIL_USER or not GMAIL_APP_PASSWORD:
        return ''
    try:
        import imaplib
        import email as email_lib
        from email.header import decode_header

        mail = imaplib.IMAP4_SSL('imap.gmail.com')
        mail.login(GMAIL_USER, GMAIL_APP_PASSWORD)
        mail.select('INBOX')

        status, msgs = mail.search(None, 'UNSEEN')
        if status != 'OK' or not msgs[0]:
            return '📧 Keine ungelesenen E-Mails.'

        ids = msgs[0].split()[-5:]  # letzte 5 ungelesene
        senders = []
        subjects = []
        for eid in ids:
            status, data = mail.fetch(eid, '(BODY.PEEK[HEADER.FIELDS (FROM SUBJECT)])')
            if status != 'OK':
                continue
            for part in data:
                if isinstance(part, tuple):
                    msg = email_lib.message_from_bytes(part[1])
                    sender = str(decode_header(msg.get('From', ''))[0][0])
                    subject = str(decode_header(msg.get('Subject', ''))[0][0])
                    senders.append(sender.split('<')[0].strip()[:30])
                    subjects.append(subject[:60])

        mail.logout()
        if not senders:
            return '📧 Keine neuen E-Mails.'
        lines = [f'  {s}: {t}' for s, t in zip(senders, subjects)]
        return '📧 *Neue E-Mails:*\n' + '\n'.join(lines)
    except Exception as e:
        return f'📧 E-Mail: Fehler ({e})'

# ─── Termine ──────────────────────────────────────────────────────────────────
async def get_calendar() -> str:
    if not CALENDAR_ICS_URL:
        return ''
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(CALENDAR_ICS_URL, timeout=aiohttp.ClientTimeout(total=10)) as resp:
                text = await resp.text()

        today = date.today().strftime('%Y%m%d')
        events = []
        in_today = False
        for line in text.split('\n'):
            if line.startswith('DTSTART') and today in line:
                in_today = True
            elif line.startswith('DTSTART') and today not in line:
                in_today = False
            elif in_today and line.startswith('SUMMARY:'):
                events.append(line[8:])
        if events:
            return '📅 *Termine heute:*\n' + '\n'.join(f'• {e}' for e in events[:5])
        return ''
    except Exception:
        return ''

# ─── Hauptfunktion ────────────────────────────────────────────────────────────
async def get_briefing() -> str:
    """Erstellt das vollständige Daily Briefing."""
    date_str = datetime.now().strftime('%d.%m.%Y')
    parts = [f'📋 *{SERVER_NAME} Daily Briefing* – {date_str}\n']

    weather, stocks, news, emails, calendar = await asyncio.gather(
        get_weather(), get_stocks(), get_news(), get_emails(), get_calendar()
    )

    for p in [weather, stocks, news, emails, calendar]:
        if p:
            parts.append(p)
            parts.append('')

    return '\n'.join(parts)


if __name__ == '__main__':
    """Test: Einmaliges Briefing ausgeben"""
    async def _test():
        print(await get_briefing())
    asyncio.run(_test())
