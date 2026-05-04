# Discord-Bot-Setup

Diese Anleitung führt dich durch das Setup eines Discord-Bots für zwei optionale Features:

1. **Rollen-Check** — Quiz für Spieler überspringen, die bereits eine Whitelist-Rolle haben
2. **Rollen-Vergabe** — automatisch eine Rolle nach bestandenem Quiz zuweisen (und optional eine "Gast"-Rolle entfernen)

> **Webhook-Logs brauchen KEINEN Bot.** Die nutzen einfache Webhook-URLs. Wenn du nur Logs willst, überspringe diese Anleitung und lies stattdessen [webhooks.md](webhooks.md).

---

## Schritt 1: Discord-Application erstellen

1. Gehe zu https://discord.com/developers/applications
2. Klick auf **"New Application"** (oben rechts)
3. Namen vergeben — z.B. `J0K3R Whitelist Bot`
4. ToS akzeptieren, **Create** klicken

---

## Schritt 2: Bot-User erstellen & Token holen

1. Linke Sidebar → **"Bot"**
2. (Falls gefragt) **"Add Bot"** klicken → bestätigen
3. Unter **Token** → **"Reset Token"** → Token kopieren
   - ⚠️ **Der Token wird nur einmal angezeigt.** Wenn du ihn verlierst, musst du ihn neu generieren.
4. In deine `server.cfg` eintragen:
   ```cfg
   set discord_token "MTAxxxxxxxxxxxxxxxxxxxxxxxx.G..."
   ```
   - **Niemals den Token in `config.lua`** — könnte über Escrow oder Git leaken.

---

## Schritt 3: ⭐ Privileged Gateway Intents aktivieren

Das ist **der häufigste vergessene Schritt.** Ohne diese Intents kann der Bot keine Member-Rollen abfragen.

Im **Bot**-Tab nach unten scrollen zu **"Privileged Gateway Intents"**:

| Intent | Erforderlich? | Wofür |
|--------|---------------|-------|
| ✅ **SERVER MEMBERS INTENT** | **JA — PFLICHT** | Damit der Bot Member-Infos abfragen kann via `GET /guilds/{id}/members/{id}` |
| ❌ Presence Intent | Nein | Online/Offline-Status irrelevant |
| ❌ Message Content Intent | Nein | Wir lesen keine Nachrichten |

**SERVER MEMBERS INTENT** an → **Save Changes** klicken.

---

## Schritt 4: Invite-URL generieren

1. Linke Sidebar → **"OAuth2"** → **"URL Generator"**
2. Unter **Scopes** ankreuzen:
   - ✅ `bot`
   - ✅ `applications.commands` (optional, schadet nicht)
3. Unter **Bot Permissions** ankreuzen:
   - ✅ **Manage Roles** ← **PFLICHT**
   - ✅ View Channels (Default)
   - ✅ Read Message History (optional)

4. Am unteren Rand erscheint die **Generated URL** — kopieren.

> 💡 Für Tests kannst du auch `Administrator` ankreuzen, um dem Bot alle Permissions zu geben. In Production aber lieber Minimum-Permissions.

---

## Schritt 5: Bot zum Discord-Server einladen

1. Generierte URL im Browser öffnen
2. Deinen Discord-Server aus dem Dropdown wählen
3. **Authorize** klicken → ggf. Captcha lösen
4. Der Bot ist jetzt im Server (als offline — das ist normal, siehe Schritt 7)

---

## Schritt 6: ⭐ Rollen-Hierarchie fixen

Das ist **der zweithäufigste vergessene Schritt.** Discord verbietet einem Bot, Rollen zu modifizieren, die in der Hierarchie **über** seiner eigenen Rolle stehen.

1. In deinem Discord-Server → **Server Settings** → **Roles**
2. Du siehst eine Liste aller Rollen. Die Bot-Rolle (heißt meist wie dein Bot) ist meistens irgendwo unten.
3. **Bot-Rolle nach OBEN ziehen**, mindestens **über** die Whitelist-Rolle.

**Korrekte Hierarchie** (oben = höher):
```
├── @Owner / Admin
├── 🤖 J0K3R Whitelist Bot      ← Bot-Rolle hier ODER HÖHER
├── ✅ Whitelisted               ← die zu vergebende Rolle
├── 👤 Guest
└── @everyone
```

**Falsch** (führt zu HTTP 403):
```
├── ✅ Whitelisted               ← über dem Bot
├── 🤖 J0K3R Whitelist Bot      ← kann Rolle darüber nicht ändern
└── @everyone
```

---

## Schritt 7: Resource konfigurieren

In `config.lua`:

```lua
Config.Discord = {
    GuildId               = "123456789012345678",        -- Rechtsklick aufs Server-Icon -> Server-ID kopieren
    WhitelistedRoleId     = "987654321098765432",        -- Rechtsklick auf die Rolle -> Rollen-ID kopieren
    AssignRoleAfterPass   = "987654321098765432",        -- meist gleich der Whitelist-Rolle
    RemoveRoleAfterPass   = "",                            -- leer = nichts entfernen
    TokenConvarName       = "discord_token",
}

Config.EnableDiscordRoleCheck      = true
Config.EnableDiscordRoleAssignment = true
```

> **IDs in Discord kopieren:**
> 1. Discord → Settings → Advanced → **Developer Mode** aktivieren
> 2. Rechtsklick auf Server / Rolle / Channel → **"... ID kopieren"**

---

## Schritt 8: Neustart und Test

```
restart J0K3R-whitelist_spawnselector
```

> ⚠️ Hinweis: Der Bot nutzt Discords **REST-API**, nicht das Gateway. Daher erscheint der Bot in der Mitgliederliste als **OFFLINE**, auch wenn alles korrekt funktioniert. Vertraue nicht dem Online-Indikator — vertraue den Konsolen-Logs.

### Test-Szenario A: Spieler MIT der Rolle

1. Stelle sicher, dass dein Test-Account die `Whitelisted`-Rolle in Discord hat
2. DB zurücksetzen: `DELETE FROM j0k3r_whitelist WHERE identifier = 'license:DEINE_LICENSE';`
3. Mit RedM-Server verbinden und neuen Char erstellen
4. Die Whitelist-UI sollte **NICHT** öffnen
5. Du solltest die in-game Notification bekommen: *"Existing whitelist role detected - skipping quiz."*
6. Die DB sollte jetzt einen Eintrag mit `passed = 1` haben

### Test-Szenario B: Spieler OHNE Rolle

1. Entferne die `Whitelisted`-Rolle vom Test-Account in Discord
2. DB nochmal zurücksetzen
3. Verbinden → Quiz erscheint → bestehen
4. **Server-Konsole sollte zeigen:**
   ```
   ^2[J0K3R-whitelist][discord] ✅ Role assigned to 123456789 (role=987654321098765432)^7
   ```
5. **In Discord:** der Test-Account hat jetzt die `Whitelisted`-Rolle ✅

---

## Fehlerdiagnose

Das neue Logging in `discord.lua` sagt dir genau, was hängt. Mapping-Tabelle:

| Konsolen-Output | Ursache | Fix |
|-----------------|---------|-----|
| `MISSING: discord_token convar is not set` | Token fehlt in `server.cfg` | `set discord_token "..."` ergänzen, Server neustarten |
| `401 Unauthorized` | Token falsch oder abgelaufen | Token im Dev-Portal neu generieren, `server.cfg` updaten |
| `403 Forbidden - bot lacks 'Manage Roles' or its role is below the target role` | Zwei mögliche Ursachen — beide prüfen | (a) Bot-Rolle hat keine "Manage Roles" → Schritt 4 (b) Bot-Rolle ist unter der Whitelist-Rolle → Schritt 6 |
| `404 Not Found - guild ID, role ID, or member not found` | Falsche ID in der Config ODER Bot ist nicht im Server ODER Spieler ist nicht im Discord-Server | `GuildId`, `WhitelistedRoleId` prüfen. Bot-Invite (Schritt 5) wiederholen. |
| `0 No response - check internet connection or 'Server Members Intent'` | SERVER MEMBERS INTENT ist aus | Schritt 3 |
| `429 Rate Limited` | Zu viele Requests in kurzer Zeit | Kurz warten; sollte sich von selbst regeln |

Wenn gar nichts erscheint: `Config.Debug = true` setzen für ausführliche Logs.

---

## Wie funktioniert der Rollen-Check technisch?

Der Bot nutzt Discords REST-API direkt via FXServers `PerformHttpRequest`:

**Rollen-Check:**
```
GET https://discord.com/api/v10/guilds/{guild_id}/members/{discord_id}
Authorization: Bot {token}
```
Liefert das Member-Objekt inklusive `roles`-Array. Das Script prüft, ob `WhitelistedRoleId` darin enthalten ist.

**Rolle vergeben:**
```
PUT https://discord.com/api/v10/guilds/{guild_id}/members/{discord_id}/roles/{role_id}
Authorization: Bot {token}
```
Liefert HTTP 204 bei Erfolg.

**Rolle entfernen:**
```
DELETE https://discord.com/api/v10/guilds/{guild_id}/members/{discord_id}/roles/{role_id}
Authorization: Bot {token}
```

Die Discord-ID wird aus den Spieler-Identifiern extrahiert (der `discord:...`-Eintrag, den FiveM/RedM bereitstellt, wenn der Spieler Discord verlinkt hat).

> **Wichtig:** Spieler müssen Discord laufen haben und mit ihrem RedM/FiveM-Client verlinkt haben, wenn sie joinen. Sonst ist kein `discord:`-Identifier vorhanden und Rollen-Check / -Vergabe wird stillschweigend übersprungen.
