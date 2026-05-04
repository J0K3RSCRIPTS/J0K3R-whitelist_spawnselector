# Fehlerdiagnose

Häufige Probleme und Lösungen, sortiert nach Kategorie.

---

## Resource startet nicht

### `WARNING: Table 'j0k3r_whitelist' is missing!`

Du hast vergessen, das SQL zu importieren.

**Fix:** `sql/install.sql` auf der VORP-Datenbank ausführen. Siehe [installation.md](installation.md#2-sql-importieren).

### `attempt to index a nil value (global 'exports')`

VORP ist noch nicht geladen oder die Resource startet **vor** vorp_core / vorp_inventory.

**Fix:** In `server.cfg` sicherstellen, dass `ensure J0K3R-whitelist_spawnselector` **nach** den VORP-Resources kommt.

### `module 'oxmysql' not found`

oxmysql ist nicht installiert oder nicht gestartet.

**Fix:** oxmysql von https://github.com/overextended/oxmysql installieren und sicherstellen, dass es vor dieser Resource startet.

---

## NUI öffnet nicht

### Nichts passiert wenn neuer Char erstellt wird

Häufigste Ursache: `vorp:initNewCharacter` feuert nicht.

**Fix:**
1. `Config.Debug = true` in `config.lua` setzen
2. Resource neustarten und neuen Char erstellen
3. In der **Client-Konsole (F8)** nach diesen Zeilen suchen:
   ```
   [J0K3R-whitelist] vorp:initNewCharacter triggered
   [J0K3R-whitelist] vorp:initCharacter triggered, pendingNewChar=true
   ```
4. Falls die erste Zeile fehlt, könnte deine VORP-Version dieses Event nicht feuern. Nutze stattdessen den `/spawnselector`-Befehl manuell oder kontaktiere J0K3R-Scripts.

### UI öffnet aber ist leer / nichts zu sehen

CSS oder JS konnten nicht geladen werden.

**Fix:**
1. In der In-Game-F8-Konsole NUI-Dev-Tools öffnen:
   ```
   nui_devtools J0K3R-whitelist_spawnselector
   ```
2. **Console**-Tab nach JS-Errors absuchen, **Network**-Tab nach fehlgeschlagenen Datei-Loads.
3. Sicherstellen, dass alle Dateien aus `ui/` in der `fxmanifest.lua` unter `files {}` aufgelistet sind.

### UI öffnet aber Karten haben keine Bilder

Die Bild-Pfade matchen nicht zu Dateien in `ui/img/`.

**Fix:**
1. Prüfen ob `ui/img/` tatsächlich die in `Config.Spawns[*].image` referenzierten Dateien enthält
2. Datei-Namen sind auf Linux-Servern **case-sensitive** (FXServer läuft typischerweise auf Linux)
3. NUI-Refresh durch Reconnect erzwingen

---

## Items / Geld nicht erhalten

### Spieler bekommt keine Items nach Spawn

Der Item-`name` matcht nicht zu einem Eintrag in der `items`-DB-Tabelle.

**Fix:**
```sql
SELECT item, label FROM items WHERE item LIKE '%bread%';
```
Den exakten `item`-Wert (nicht das Label) als `name` in `Config.Spawns[*].items` verwenden.

### `[J0K3R-whitelist][server] Player X cannot carry item bread x5`

Inventar des Spielers ist voll oder Item hat ein Gewichts-Limit.

**Fix:** Nur informativ — das Item wird einfach übersprungen. Spieler kann Staff fragen oder du reduzierst die Start-Mengen.

### Geld erscheint nicht im Wallet

VORP cached das Charakter-Objekt. Das Geld wurde hinzugefügt, aber die UI zeigt den gecachten Wert.

**Fix:** Spieler einmal disconnecten und reconnecten. Der neue Wert wird aus der DB geladen.

---

## Quiz-Probleme

### Quiz startet nie nach den Regeln

Das `RequestQuestions`-Event erreicht den Server nicht.

**Fix:**
1. Server- und Client-Konsole auf Errors prüfen
2. Sicherstellen, dass `Config.QuizQuestionsPerTest <= #Config.Questions` — du kannst nicht mehr Fragen ziehen als im Pool sind
3. `Config.EnableQuiz = true` sicherstellen

### "Time's up" erscheint sofort

Der Quiz-Timer feuert zu früh.

**Fix:** `Config.QuizTimeSeconds` prüfen — sollte ein vernünftiger Wert sein (60+ Sekunden).

### Spieler besteht aber wird nicht gespawnt

Das `DoSpawn`-Event triggert, aber die Welt lädt nicht schnell genug.

**Fix:** Meist einmaliges Problem; ein Re-Test funktioniert. Falls dauerhaft, die Wartezeit in `client/main.lua` im `DoSpawn`-Handler erhöhen:
```lua
while not HasCollisionLoadedAroundEntity(playerPed) and tries < 100 do
    Wait(50)
    tries = tries + 1
end
```
`tries < 100` auf `tries < 200` erhöhen für langsamere Server.

---

## Discord-Probleme

Volle Fehler-Code-Tabelle in [discord-setup.md](discord-setup.md#fehlerdiagnose). Kurz:

| Fehler | Fix |
|--------|-----|
| `403 Forbidden` | Bot-Rolle zu niedrig in der Hierarchie ODER keine "Manage Roles"-Permission |
| `404 Not Found` | Falsche Guild-ID / Rollen-ID, oder Bot nicht im Server |
| `401 Unauthorized` | Token ungültig / abgelaufen |
| `0 No response` | SERVER MEMBERS INTENT nicht aktiviert |

---

## Webhook-Probleme

### Kein Log in Discord-Channel

1. `Config.Webhooks.EnableSpawnLog = true` (oder relevanter Toggle) muss aktiv sein
2. URL muss gefüllt sein
3. Server-Konsole nach `[J0K3R-whitelist][webhook] HTTP ...`-Errors absuchen
4. URL manuell testen:
   ```bash
   curl -X POST "DEINE_WEBHOOK_URL" -H "Content-Type: application/json" -d '{"content":"test"}'
   ```
   Sollte HTTP 204 zurückgeben ohne Body.

### Embed hat falsche Farben

Discord nutzt 24-Bit-RGB. Die Werte in `Config.Webhooks.Colors` müssen **Integer** sein, keine Strings:

```lua
Spawn = 0x3e7c47,        -- korrekt (hex)
Spawn = 4099399,         -- korrekt (dezimal)
Spawn = "#3e7c47",       -- FALSCH (string)
```

### Embed-Felder zeigen überall `n/a`

Spieler hat kein Steam / Discord mit seinem FiveM/RedM-Client verlinkt, oder Charakter hat keinen Vor-/Nachnamen.

**Fix:** Spieler müssen Steam und Discord laufen haben und mit ihrem RedM-Client verlinken. Sonst sind die Identifier nicht serverseitig verfügbar. Felder lassen sich deaktivieren:

```lua
Config.Webhooks.Fields.Identifiers = false
```

---

## Bann / Re-Test-Probleme

### "Ich hänge im Bann-Screen fest"

Du hast dich beim Testen selbst gebannt. Manueller Unban:

```sql
UPDATE users SET banned = 0, banneduntil = 0 WHERE identifier = 'license:DEINE_LICENSE';
```

### "Ich will den Whitelist-Flow auf meinem eigenen Account erneut testen"

DB-Eintrag zurücksetzen:

```sql
DELETE FROM j0k3r_whitelist WHERE identifier = 'license:DEINE_LICENSE';
```

Beim nächsten neuen Char (oder bei `Config.CharacterPolicy = "perchar"` beim nächsten Char) läuft der Flow wieder.

Alle Tester auf einmal zurücksetzen:

```sql
TRUNCATE TABLE j0k3r_whitelist;
```

---

## NUI-Skalierung / Display

### UI sieht auf 4K winzig aus

Die `clamp()`-Werte in der `style.css` sind bereits 4K-tauglich. Wenn du noch größer willst:

1. `ui/style.css` editieren
2. Im `:root`-Block den **dritten** Wert jedes `clamp(min, vw, max)` erhöhen:
   ```css
   --fs-header: clamp(28px, 2.8vw, 64px);  /* z.B. 64px auf 80px erhöhen */
   ```

### UI überfließt auf 1080p

Manche Karten passen nicht. Prüfen:

1. Anzahl Spawns × Karten-Breite muss in den Viewport passen (4 × 280px ≈ 1120px + Padding)
2. Bei 5+ Spawns wickeln sie automatisch in die 2. Reihe um — aber wenn Beschreibungen zu lang sind, werden Karten zu hoch und überfließen vertikal
3. Beschreibungen auf eine Zeile kürzen für kompakte Layouts

### Schriften laden nicht

Browser-Cache prüfen (DevTools → Network → Disable cache). Wenn weiterhin fehlen:

1. Verifizieren dass `ui/fonts/rdrlino-regular.ttf` und `ui/fonts/hapnaslabserif-demibold.ttf` existieren
2. Prüfen dass `fxmanifest.lua` `"ui/fonts/*"` in der Files-Liste hat
3. `@font-face`-Deklarationen in `style.css` matchen die echten Datei-Namen

---

## Performance

### Quiz lädt lange auf langsamen Verbindungen

Der gesamte `Config.Questions`-Pool wird nicht gesendet — nur `Config.QuizQuestionsPerTest` werden gestreamt. Bottleneck ist meist der initiale NUI-Render.

**Fix:** Anzahl `Config.Spawns` reduzieren (weniger Karten = schnellerer Initial-Render) oder Karten-Bilder kleiner machen.

### Server-CPU spiked bei vielen gleichzeitigen Connects

Jeder Spieler triggert eine `isWhitelisted`-Query und (falls Discord aktiv) einen `Discord_HasWhitelistRole`-HTTP-Request.

**Fix:** Normal. Die DB-Query ist `O(1)` dank Unique-Key, und die Discord-API ist rate-limited aber nicht schwergewichtig. Bei Stress-Tests kannst du `EnableDiscordRoleCheck` deaktivieren und nur auf den DB-Cache vertrauen.

---

## Wenn nichts mehr hilft

1. `Config.Debug = true`
2. Problem reproduzieren
3. Beide Konsolen-Outputs öffnen:
   - **Server-Konsole** — komplette Ausgabe
   - **Client-F8-Konsole** — `[J0K3R-whitelist]`-Zeilen
4. NUI-DevTools öffnen: `nui_devtools J0K3R-whitelist_spawnselector` in F8
5. Bug-Report im Discord (https://discord.gg/DH8tW6vSxV) mit:
   - Was du gemacht hast
   - Was du erwartet hast
   - Was passiert ist
   - Konsolen-Outputs
   - Deine `config.lua` (mit Token / Webhook-URLs zensiert!)
