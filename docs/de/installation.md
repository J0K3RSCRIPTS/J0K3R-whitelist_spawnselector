# Installation

## Voraussetzungen

| Abhängigkeit    | Version | Anmerkung                                 |
|-----------------|---------|-------------------------------------------|
| **RedM Server** | aktuell | FXServer mit akzeptiertem `rdr3_warning`  |
| **VORP Core**   | aktuell | https://github.com/VORPCORE/vorp_core-lua |
| **VORP Inventory** | aktuell | https://github.com/VORPCORE/vorp_inventory-lua |
| **oxmysql**     | aktuell | https://github.com/overextended/oxmysql   |
| **MariaDB / MySQL** | 5.7+ | für die Speicherung des Whitelist-Status  |

Ein Discord-Bot ist **optional** — nur erforderlich wenn du:
- das Quiz für Spieler überspringen willst, die bereits eine Whitelist-Rolle haben
- nach bestandenem Quiz automatisch eine Discord-Rolle vergeben möchtest
- Webhook-Logs verschicken willst (die brauchen aber **keinen** Bot, nur eine Webhook-URL)

---

## 1. Resource in den Server kopieren

Den gesamten `J0K3R-whitelist_spawnselector/`-Ordner in dein `resources/`-Verzeichnis kopieren.

```
your-server/
├── resources/
│   ├── [vorp]/
│   │   ├── vorp_core/
│   │   ├── vorp_inventory/
│   │   └── ...
│   ├── J0K3R-whitelist_spawnselector/   ← hier
│   └── ...
└── server.cfg
```

---

## 2. SQL importieren

Die Resource erstellt eine eigene Tabelle `j0k3r_whitelist`. Das Install-Script einmalig in der VORP-Datenbank ausführen:

```sql
SOURCE J0K3R-whitelist_spawnselector/sql/install.sql;
```

Oder per Terminal:

```bash
mysql -u USER -p DATENBANK < resources/J0K3R-whitelist_spawnselector/sql/install.sql
```

Verifizieren, dass die Tabelle existiert:

```sql
SHOW TABLES LIKE 'j0k3r_whitelist';
DESCRIBE j0k3r_whitelist;
```

Du solltest fünf Spalten sehen: `id`, `identifier`, `charidentifier`, `passed`, `chosen_spawn`, `passed_at`.

> **Hinweis:** Für die Bann-Mechanik wird **keine** zusätzliche Tabelle benötigt. VORP speichert Banns direkt in der bestehenden `users`-Tabelle (Spalten `banned` + `banneduntil`), die VORP Core automatisch anlegt.

---

## 3. Resource in `server.cfg` starten

```cfg
ensure J0K3R-whitelist_spawnselector
```

Stelle sicher, dass sie **nach** `vorp_core`, `vorp_inventory` und `oxmysql` geladen wird.

Wenn du die Discord-Bot-Features nutzen möchtest, ergänze außerdem:

```cfg
set discord_token "DEIN_BOT_TOKEN_HIER"
```

(Wie du an einen Bot-Token kommst, erklärt [discord-setup.md](discord-setup.md).)

---

## 4. Startup-Banner überprüfen

Server starten. In der Konsole solltest du sehen:

```
+----------------------------------------------------+
|   J0K3R-whitelist_spawnselector by J0K3R-Scripts   |
|   Discord: https://discord.gg/DH8tW6vSxV           |
|   Free script, contributions welcome               |
+----------------------------------------------------+
[J0K3R-whitelist_spawnselector] loaded v1.0.0  •  framework: vorp_core  •  locale: en  •  jobs: false  •  policy: first
```

Falls stattdessen rot folgendes erscheint:

```
[J0K3R-whitelist_spawnselector] WARNING: Table 'j0k3r_whitelist' is missing!
```

→ Zurück zu Schritt 2.

---

## 5. Erster Test

Verbinde dich mit deinem Server und erstelle einen brandneuen Charakter. Die Whitelist-UI sollte automatisch nach der Charaktererstellung erscheinen.

Falls nichts passiert:
- `Config.Debug = true` setzen und in der Server-Konsole nach `[J0K3R-whitelist]`-Logs schauen
- Du kannst auch den Debug-Befehl `/spawnselector` benutzen (funktioniert nur wenn Debug aktiv ist)

→ Weiter mit [configuration.md](configuration.md), um das Script anzupassen.

---

## Dateistruktur-Übersicht

```
J0K3R-whitelist_spawnselector/
├── fxmanifest.lua
├── config.lua          ← alle Einstellungen
├── locale.lua          ← UI-Übersetzungen (en + de)
├── shared.lua          ← LANG / Shuffle-Helfer
├── client/main.lua     ← NUI-Steuerung, Charakter-Hooks
├── server/
│   ├── main.lua        ← Logik, DB, Belohnungen, Webhooks
│   └── discord.lua     ← Discord-API-Integration
├── sql/install.sql
├── ui/
│   ├── index.html
│   ├── style.css       ← responsive (1080p/1440p/4K)
│   ├── script.js
│   ├── img/            ← Spawn-Karten & Hintergrund
│   └── fonts/
└── docs/
    ├── en/             ← englische Doku
    └── de/             ← diese deutsche Doku
```
