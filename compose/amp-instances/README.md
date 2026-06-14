Game-Server-Instanzen (Alternativen zu AMP)
============================================

Diese Docker Compose Dateien sind eigenständige Game-Server, die OHNE AMP auskommen.
Nützlich wenn du keine AMP Lizenz hast oder einzelne Server schnell starten willst.

## Verwendung

```bash
# Minecraft
docker compose -f compose/amp-instances/minecraft.yml up -d

# Valheim
docker compose -f compose/amp-instances/valheim.yml up -d
```

## Ports

| Server    | Port(s)          |
|-----------|------------------|
| Minecraft | 25565 (TCP)      |
| Valheim   | 2456-2458 (UDP)  |

## Mit AMP

Wenn du AMP verwendest (http://SERVER_IP:8087), werden Game-Server direkt über das AMP Web-UI verwaltet.
Die eigenständigen Templates hier sind nur als Alternative gedacht.
