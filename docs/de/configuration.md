# Konfiguration

Alle Einstellungen befinden sich in **`config.lua`** im Resource-Hauptordner. Diese Doku erklärt jede Option.

## Inhalt

- [Allgemein](#allgemein)
- [Feature-Toggles](#feature-toggles)
- [Job-Vergabe](#job-vergabe)
- [Spawn-Koordinaten speichern](#spawn-koordinaten-speichern)
- [Character-Policy](#character-policy)
- [Quiz-Einstellungen](#quiz-einstellungen)
- [Bann-Provider](#bann-provider)
- [Discord-Einstellungen](#discord-einstellungen)
- [Webhook-Logs](#webhook-logs)
- [Design / NUI-Optik](#design--nui-optik)

---

## Allgemein

```lua
Config.Debug   = true   -- Debug-Modus (aktiviert /spawnselector + Konsolen-Logs)
Config.Locale  = "en"   -- UI-Sprache: "en" oder "de" (siehe locale.lua)
```

| Option | Typ | Default | Beschreibung |
|--------|-----|---------|--------------|
| `Debug` | bool | `true` | Wenn `true`, werden Debug-Infos geloggt und der Befehl `/spawnselector` registriert. **In Production ausschalten.** |
| `Locale` | string | `"en"` | UI-Sprache. Mitgeliefert: `"en"` und `"de"`. Eigene Sprache: siehe [Neue Sprache hinzufügen](#neue-sprache-hinzufügen). |

---

## Feature-Toggles

Jede Hauptkomponente kann einzeln an- oder abgeschaltet werden.

```lua
Config.EnableSpawnSelector         = true
Config.EnableRules                 = true
Config.EnableQuiz                  = true
Config.EnableQuizTimer             = true
Config.EnableTempBanOnFail         = false
Config.EnableDiscordRoleCheck      = true
Config.EnableDiscordRoleAssignment = true
```

| Option | Effekt bei `true` |
|--------|-------------------|
| `EnableSpawnSelector` | Visueller Spawn-Selector als erste Stage |
| `EnableRules` | Server-Regeln mit Scroll-bis-zum-Ende-Pflicht |
| `EnableQuiz` | Whitelist-Quiz mit zufälligen Fragen |
| `EnableQuizTimer` | Countdown-Timer im Quiz; bei Ablauf automatisches Fail |
| `EnableTempBanOnFail` | Bei Quiz-Fehlschlag temporär bannen statt nur kicken |
| `EnableDiscordRoleCheck` | Discord-Rolle prüfen; falls vorhanden, Prozess überspringen |
| `EnableDiscordRoleAssignment` | Nach Bestehen automatisch Discord-Rollen vergeben/entfernen |

Du kannst beliebig kombinieren — z.B. `EnableSpawnSelector + EnableQuiz` (ohne Regeln) oder `EnableRules + EnableQuiz` (ohne Spawn-Wahl).

---

## Re-Validierung beim Connect

```lua
Config.EnableConnectRevalidation = false
Config.RevalidationKickMessage   = "Du bist nicht mehr whitelisted auf diesem Server. Bitte kontaktiere das Staff-Team."
```

**Was es macht:** Wenn `true`, validiert das Script **jeden Spieler bei JEDEM Connect** — nicht nur bei Charakter-Erstellung. Falls die Discord-Whitelist-Rolle entfernt wurde (oder kein DB-Eintrag existiert), wird der Spieler sofort vom Server gekickt.

**Use Cases:**
- 🔒 **Rollen-Entfernung erkennen:** Wenn ein Spieler aus deinem Discord gebannt wird (und die Rolle entfernt wird), kann er sich nicht mehr auf den RedM-Server schleichen.
- 🛡️ **Anti-Evasion:** Ein User, der dein Discord verlässt, verliert die Rolle automatisch (Discord-Verhalten) — und wird daher gekickt.
- 🧹 **Whitelist-Cleanup:** Jemanden manuell aus der DB entfernen (`DELETE FROM j0k3r_whitelist...`) reicht, um ihn beim nächsten Connect zu kicken.

**Validierungs-Matrix:**

| DB-Eintrag | Discord-Rolle | `EnableConnectRevalidation = false` | `EnableConnectRevalidation = true` |
|:----------:|:-------------:|-------------------------------------|------------------------------------|
| ✅ | ✅ | ✅ Durchlassen | ✅ Durchlassen |
| ✅ | ❌ | ✅ Durchlassen ⚠️ | ❌ **Kick** (Rolle verloren) |
| ❌ | ✅ | ✅ Auto-markieren + durchlassen | ✅ Auto-markieren + durchlassen |
| ❌ | ❌ (neuer Char) | ➡️ Prozess starten | ➡️ Prozess starten |
| ❌ | ❌ (bestehender Char) | ✅ Durchlassen ⚠️ | ❌ **Kick** |

> ⚠️ Der Default `false` ist abwärtskompatibel — einmal whitelisted in der DB = für immer whitelisted. Schalte das ein, falls du strenger durchsetzen willst.

> **Tipp:** Für maximale Sicherheit kombiniere `EnableConnectRevalidation = true` mit `EnableDiscordRoleCheck = true`. So wird die Discord-Rolle zur einzigen Wahrheitsquelle — und das Entfernen ist identisch mit dem Bannen vom Server.

---

## Job-Vergabe

```lua
Config.EnableJobAssignment = false
```

Globaler Schalter, ob VORP `job` / `jobgrade` / `joblabel` beim Spawn gesetzt werden.

**Auf `false` setzen**, wenn du ein eigenes Job-System hast (vorp_jobs, eigenes Menü etc.) und nicht möchtest, dass dieses Script den Job überschreibt.

**Auf `true` setzen**, damit das Script Jobs basierend auf dem `job`-Block in jedem Spawn vergibt.

### Pro-Spawn-Override

Jeder Eintrag in `Config.Spawns` kann den globalen Schalter überschreiben:

```lua
["MEIN_SPAWN"] = {
    -- ...
    job        = { name = "myjob", grade = 0, label = "Mein Job" },
    enableJob  = true,   -- hier IMMER vergeben, auch wenn global = false
    -- enableJob = false -> hier NIE vergeben, auch wenn global = true
    -- enableJob = nil   -> dem globalen Config.EnableJobAssignment folgen
},
```

Volle Details in [spawn-points.md](spawn-points.md).

---

## Spawn-Koordinaten speichern

```lua
Config.SaveSpawnAsDefaultSpawn = true
```

Wenn `true`, wird der gewählte Spawn als Standard-Spawn-Koordinate des Charakters gespeichert. Bei zukünftigen Logins erscheint der Spieler dort statt am VORP-Default.

Der Aufruf ist in `pcall` gewrappt, falls deine VORP-Version `updateCharPos` nicht unterstützt.

---

## Character-Policy

```lua
Config.CharacterPolicy = "first"
```

Bestimmt, wie oft der Whitelist-Prozess läuft.

| Wert | Verhalten |
|------|-----------|
| `"first"` | **(Default, empfohlen)** Prozess **einmal pro Account**. Sobald irgendein Charakter besteht, ist der ganze Account whitelisted. |
| `"perchar"` | Jeder neue Charakter muss erneut Spawn wählen und (optional) Quiz machen. |
| `"perplayer"` | Verhält sich wie `"first"` — nur als Alias zur Klarheit beibehalten. |

> **Hinweis zur DB:** Bei `"first"` oder `"perplayer"` wird die Spalte `charidentifier` in `j0k3r_whitelist` als `0` (NULL) gespeichert, weil die Whitelist account-weit gilt. Nur `"perchar"` schreibt die echte Charakter-ID. Das ist gewollt.

---

## Quiz-Einstellungen

```lua
Config.QuizQuestionsPerTest = 5
Config.MaxMistakesAllowed   = 1
Config.QuizTimeSeconds      = 180
Config.TempBanMinutes       = 30
Config.ShuffleAnswers       = true
```

| Option | Default | Beschreibung |
|--------|---------|--------------|
| `QuizQuestionsPerTest` | `5` | Wie viele Fragen zufällig aus `Config.Questions` gezogen werden |
| `MaxMistakesAllowed` | `1` | Erlaubte Fehler. `0` = streng, `2` = locker |
| `QuizTimeSeconds` | `180` | Gesamtzeit in Sekunden. Server-side validiert (Anti-Cheat). |
| `TempBanMinutes` | `30` | Bann-Dauer in Minuten bei Quiz-Fehlschlag (nur bei `EnableTempBanOnFail = true` und `BanProvider = "vorp_admin"`) |
| `ShuffleAnswers` | `true` | Antworten pro Frage zufällig mischen (Server merkt sich den korrekten Index) |

Den Frage-Pool änderst du im `Config.Questions`-Block in der `config.lua`. Du kannst beliebig viele Fragen hinzufügen — `QuizQuestionsPerTest` davon werden pro Versuch zufällig gezogen.

---

## Bann-Provider

```lua
Config.BanProvider = "drop_only"
```

| Wert | Verhalten |
|------|-----------|
| `"vorp_admin"` | Updated `users.banned` + `users.banneduntil`. **VORP Core blockt den Spieler automatisch beim nächsten Connect** — voll vorp_admin-kompatibel. |
| `"drop_only"` | Nur `DropPlayer(...)`, kein DB-Eintrag. Nützlich für Tests oder eigene Ban-Manager. |

Jeder andere Wert wird sicherheitshalber wie `"drop_only"` behandelt.

---

## Discord-Einstellungen

```lua
Config.Discord = {
    GuildId               = "DEINE_GUILD_ID",
    WhitelistedRoleId     = "DEINE_WHITELIST_ROLLEN_ID",
    AssignRoleAfterPass   = "DEINE_WHITELIST_ROLLEN_ID",
    RemoveRoleAfterPass   = "",
    TokenConvarName       = "discord_token",
}
```

| Option | Beschreibung |
|--------|--------------|
| `GuildId` | ID deines Discord-Servers (Guild) |
| `WhitelistedRoleId` | Die Rolle, die ein Spieler hat, wenn er bereits whitelisted ist. Wird von `EnableDiscordRoleCheck` verwendet |
| `AssignRoleAfterPass` | Rolle, die nach bestandenem Quiz vergeben wird |
| `RemoveRoleAfterPass` | Rolle, die nach Bestehen entfernt wird (z.B. "Gast"-Rolle). Leer lassen (`""`) zum Überspringen |
| `TokenConvarName` | Name des Convars mit dem Bot-Token. Default: `discord_token` (in `server.cfg` mit `set discord_token "..."`) |

> **Niemals den Bot-Token in `config.lua`!** Immer das Convar in `server.cfg` nutzen. Komplettes Bot-Setup: [discord-setup.md](discord-setup.md).

---

## Webhook-Logs

```lua
Config.Webhooks = {
    EnableSpawnLog = false,
    EnableQuizLog  = false,
    EnableBanLog   = false,

    SpawnLogUrl = "",
    QuizLogUrl  = "",
    BanLogUrl   = "",

    Username  = "J0K3R Whitelist",
    AvatarUrl = "",
    Colors = {
        Spawn      = 0x3e7c47,
        QuizFailed = 0x8b1a1a,
        Ban        = 0x8b1a1a,
    },
    Fields = {
        Identifiers = true,
        Character   = true,
        Spawn       = true,
        Rewards     = true,
    },
}
```

Volle Doku: [webhooks.md](webhooks.md).

---

## Design / NUI-Optik

```lua
Config.Design = {
    PrimaryColor      = "#c9a559",   -- Goldton (Akzent)
    SecondaryColor    = "#8b1a1a",   -- Dunkelrot (Fehler)
    SuccessColor      = "#3e7c47",   -- Grün (Bestanden)
    BackgroundColor   = "#1a0f08",   -- Dunkler Holzbraun
    TextColor         = "#f4e8d0",   -- Pergament-Cream
    Opacity           = 0.92,        -- Hintergrund-Transparenz
    BorderColor       = "#c9a559",
    FontHeader        = "RDR Lino",
    FontBody          = "HapnaSlabSerif",
    BackgroundImage   = "img/background.webp",
}
```

Diese Werte werden als CSS-Variablen ans NUI gesendet. Du kannst sie ändern, ohne die CSS-Datei anfassen zu müssen.

| Option | Beschreibung |
|--------|--------------|
| `PrimaryColor` | Buttons, Card-Titel, Akzent-Text. Hex-Format. |
| `SecondaryColor` | Fehler-Zustände (Quiz failed, Bann-Warnung). |
| `SuccessColor` | "Bestanden!"-Screen, Bestätigungen. |
| `BackgroundColor` | Hinter den Karten/Panels. Halbtransparenter Overlay. |
| `TextColor` | Standard-Body-Text-Farbe. |
| `Opacity` | Wie dunkel der Overlay ist. `1.0` = ganz opak, `0.5` = halbtransparent. |
| `BorderColor` | Karten- und Panel-Rahmen. |
| `FontHeader` | Headlines, Buttons, Card-Titel. Muss zu einer `@font-face`-Deklaration in `style.css` passen. |
| `FontBody` | Body-Text und Antworten. |
| `BackgroundImage` | Pfad relativ zu `ui/` (z.B. `img/background.webp`). |

Um Schriften zu ersetzen oder neue hinzuzufügen, lege die `.ttf`/`.woff2`-Datei in `ui/fonts/` ab und passe den `@font-face`-Block in `style.css` an.

---

## Neue Sprache hinzufügen

In `locale.lua` einen neuen Block ergänzen:

```lua
Locales["fr"] = {
    notify_title           = "Système de Liste Blanche",
    spawn_select_title     = "Choisissez votre spawn",
    -- ... alle Schlüssel aus Locales["en"] kopieren und übersetzen
}
```

Dann `Config.Locale = "fr"` setzen.

Wenn ein Schlüssel in deinem Sprachpaket fehlt, fällt das Script automatisch auf Englisch zurück (und gibt `[MISSING_LOCALE:key]` aus, falls der Schlüssel auch dort fehlt).
