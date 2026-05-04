# Discord Webhook-Logs

Das Script kann Log-Embeds an Discord-Channels schicken für drei Events:

- 🟢 **Player spawned** (nach bestandener Whitelist)
- 🔴 **Quiz failed** (Spieler wurde gekickt oder gebannt)
- ⛔ **Player banned** (Quiz-Fehlschlag mit `EnableTempBanOnFail`)

> **Webhooks brauchen KEINEN Discord-Bot.** Sie nutzen einfache Webhook-URLs. Wenn du die Bot-Features (Rollen-Check / Vergabe) willst, siehe [discord-setup.md](discord-setup.md).

---

## Schritt 1: Webhook-URL in Discord erstellen

1. In Discord zum **Channel** gehen, in dem die Logs erscheinen sollen
2. Zahnrad-Icon neben dem Channel-Namen → **Edit Channel**
3. **Integrations** → **Webhooks** → **New Webhook**
4. Namen vergeben (z.B. `Whitelist Logs`) und Avatar (optional)
5. **Copy Webhook URL** klicken

Du bekommst etwas wie:
```
https://discord.com/api/webhooks/1234567890/abcdefghijklmn-OPQRSTUVWXYZ_1234567890abcdefghijklmnopqrstuv
```

---

## Schritt 2: Resource konfigurieren

In `config.lua`:

```lua
Config.Webhooks = {
    EnableSpawnLog = true,
    EnableQuizLog  = true,
    EnableBanLog   = true,

    SpawnLogUrl = "https://discord.com/api/webhooks/.../spawn",
    QuizLogUrl  = "",   -- leer -> fällt auf SpawnLogUrl zurück
    BanLogUrl   = "",   -- leer -> fällt auf SpawnLogUrl zurück

    Username  = "J0K3R Whitelist",
    AvatarUrl = "",
    Colors = {
        Spawn      = 0x3e7c47,   -- grün
        QuizFailed = 0x8b1a1a,   -- dunkelrot
        Ban        = 0x8b1a1a,   -- dunkelrot
    },
    Fields = {
        Identifiers = true,
        Character   = true,
        Spawn       = true,
        Rewards     = true,
    },
}
```

Du kannst **alle drei Log-Typen in den gleichen Channel** schicken (lass `QuizLogUrl` und `BanLogUrl` leer), oder **drei separate Channels** nutzen:

```lua
SpawnLogUrl = "https://.../spawns-channel-webhook",
QuizLogUrl  = "https://.../quiz-failures-webhook",
BanLogUrl   = "https://.../bans-webhook",
```

---

## Referenz: alle Einstellungen

### Toggles

| Option | Default | Beschreibung |
|--------|---------|--------------|
| `EnableSpawnLog` | `false` | Jeden erfolgreichen Spawn loggen |
| `EnableQuizLog` | `false` | Jeden fehlgeschlagenen Quiz-Versuch loggen (egal ob Bann oder Kick) |
| `EnableBanLog` | `false` | Jeden Bann durch dieses Script loggen |

### URLs

| Option | Beschreibung |
|--------|--------------|
| `SpawnLogUrl` | Webhook-URL für Spawn-Logs |
| `QuizLogUrl` | Webhook-URL für Quiz-Fehlschläge (Fallback auf `SpawnLogUrl` wenn leer) |
| `BanLogUrl` | Webhook-URL für Banns (Fallback auf `SpawnLogUrl` wenn leer) |

### Visuelle Anpassung

| Option | Beschreibung |
|--------|--------------|
| `Username` | Bot-Name neben jeder Nachricht |
| `AvatarUrl` | Optionales Avatar für den Webhook (Discord-Default wenn leer) |
| `Colors.Spawn` | Embed-Farbe für Spawn-Events. Dezimal (z.B. `4099399`) oder hex (`0x3e7c47`) |
| `Colors.QuizFailed` | Embed-Farbe für Quiz-Fehlschläge |
| `Colors.Ban` | Embed-Farbe für Banns |

> 💡 Discord-Embed-Farben sind 24-Bit-RGB. Nutze einen Color-Picker wie https://htmlcolorcodes.com/ um den Hex-Wert zu finden.

### Felder-Toggles

Jedes Feld im **Spawn-Log** kann einzeln deaktiviert werden:

| Toggle | Versteckt |
|--------|-----------|
| `Fields.Identifiers = false` | Steam, License, Discord-ID-Zeilen |
| `Fields.Character = false` | Charakter-Name, Char-ID, Sex, Age |
| `Fields.Spawn = false` | Spawn-Titel, Beschreibung, Koordinaten |
| `Fields.Rewards = false` | Items, Currency, Job-Status |

---

## Wie sieht jeder Log aus?

### 🟢 Spawn-Log

```
🟢 Player spawned
A player has completed the whitelist process and spawned.

┌── Player ──────────────────────────────┐
│ `John_Doe` (ID: 7)                     │
└────────────────────────────────────────┘

Steam        License           Discord
`steam:1100..` `license:abc..`  <@123456789>

Character        Char ID    Sex / Age
John Marston     8          m / 38

Spawn
**Valentine**
A bustling town in the heart of New Hanover.

Coords
`-174.75, 622.22, 114.03 (h 236.2)`

Items
`bread` × 5, `water` × 3

Currency
$500

Job
citizen (grade 0) ✅ assigned

[footer] J0K3R-whitelist_spawnselector
[timestamp] 2026-01-15T18:42:11Z
```

### 🔴 Quiz-Failed-Log

```
🔴 Quiz failed
Player failed the quiz and was temp-banned for 30 minutes.

Player        `John_Doe` (ID: 7)
Steam         `steam:1100...`     Discord  <@123456789>
Character     John Marston
Result        **2 / 5** correct

[timestamp] ...
```

### ⛔ Ban-Log

```
⛔ Player banned
You failed the whitelist test. You can try again in 30 minutes.

Identifier    `license:abc...`
Player        `John_Doe` (ID: 7)
Duration      30 min                Until    2026-01-15 19:12:11

[timestamp] ...
```

---

## Fehlerdiagnose

| Problem | Wahrscheinliche Ursache |
|---------|--------------------------|
| Kein Log in Discord | Prüfe `Config.Webhooks.EnableSpawnLog = true` und ob die URL gefüllt ist. Server-Konsole nach `[J0K3R-whitelist][webhook]`-Errors mit HTTP-Status absuchen. |
| HTTP 401 / 404 | Webhook-URL ist falsch, gelöscht oder unvollständig kopiert |
| HTTP 429 | Discord rate-limited (zu viele Spawns in kurzer Zeit). Erholt sich automatisch. |
| Embed zeigt `n/a`-Felder | Spieler hat kein Steam/Discord verlinkt oder Char hat keinen Namen. Felder via `Fields.*` deaktivieren. |
| Embed-Timestamps falsch | Discord zeigt sie in der Zeitzone des Betrachters — das ist normal. Server-Logs nutzen intern UTC ISO. |

Verbose-Logging mit `Config.Debug = true`. Dann werden alle Nicht-200/204-Webhook-Antworten in der Server-Konsole geloggt.

---

## Datenschutz

Der Spawn-Log enthält **Steam-ID, License und Discord-ID** des Spielers. Das sind technische Identifier, aber du solltest trotzdem:

- Den Log-Channel nur für Staff/Admins zugänglich machen
- Keine Screenshots der Logs öffentlich teilen
- Lokale Datenschutzgesetze beachten (DSGVO etc.) beim Speichern dieser Infos

Die `Identifiers`-Feld-Gruppe komplett deaktivieren:

```lua
Config.Webhooks.Fields.Identifiers = false
```

Dann bleiben im Log nur In-Game-Spielername + Charakter-Info.
