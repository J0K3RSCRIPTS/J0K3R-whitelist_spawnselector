# Spawn-Punkte

Jeder Eintrag in `Config.Spawns` erzeugt eine Karte im Spawn-Selector. Die Liste ist komplett dynamisch — das NUI iteriert über alles in `Config.Spawns`, du kannst also so viele oder wenige Spawns haben wie du willst.

## Aufbau eines Spawn-Eintrags

```lua
["VALENTINE"] = {                                                     -- eindeutiger Schlüssel (UPPERCASE empfohlen)
    image       = "img/valentinespawn.webp",                          -- Karten-Bild
    title       = "Valentine",                                        -- Karten-Überschrift
    description = "Eine geschäftige Stadt im Herzen New Hanovers.",   -- Karten-Untertitel
    coords      = vector4(-174.7543, 622.2214, 114.0320, 236.24),     -- x, y, z, heading
    items = {
        { name = "bread", label = "Brot",   amount = 5 },
        { name = "water", label = "Wasser", amount = 3 },
    },
    currency = {
        money = 500,
        gold  = 0,
        rol   = 0,
    },
    job        = { name = "citizen", grade = 0, label = "Bürger" },
    enableJob  = nil,
},
```

### Pflichtfelder

| Feld | Typ | Beschreibung |
|------|-----|--------------|
| `image` | string | Pfad relativ zu `ui/`. Datei in `ui/img/` ablegen. |
| `title` | string | Auf der Karte angezeigte Überschrift (~25 Zeichen sehen am besten aus). |
| `description` | string | Untertitel-Text unter dem Titel (~120 Zeichen sehen am besten aus). |
| `coords` | vector4 | `x, y, z, heading`. Heading bestimmt Blickrichtung nach Spawn. |

### Optionale Felder

| Feld | Typ | Beschreibung |
|------|-----|--------------|
| `items` | table | Liste der Start-Items. Jedes Item: `{ name = "db_name", label = "Anzeigename", amount = 5 }` |
| `currency` | table | `{ money = N, gold = N, rol = N }`. `0` oder weglassen = überspringen. |
| `job` | table | `{ name = "...", grade = 0, label = "..." }`. Nur genutzt wenn Job-Vergabe aktiv ist (siehe [configuration.md](configuration.md#job-vergabe)). |
| `enableJob` | bool/nil | Pro-Spawn-Override des globalen `Config.EnableJobAssignment`. `true` = erzwingen, `false` = blockieren, `nil` = global folgen. |

---

## Neuen Spawn hinzufügen

Am Ende von `Config.Spawns` in der `config.lua` gibt es einen ready-to-uncomment **TEMPLATE**-Block. Einfach einen bestehenden Block kopieren, den Schlüssel umbenennen und Werte anpassen.

### Schritt-für-Schritt-Beispiel: "Blackwater" hinzufügen

**1. Koordinaten in-game holen**

Verbinde dich mit deinem Server, gehe zur gewünschten Position, drehe dich in die gewünschte Blickrichtung, und nutze einen Admin-Befehl der die Coords ausgibt. Beispiel mit vorp_admin:

```
/coords
```

Du bekommst etwas wie:
```
{-794.0, -1278.0, 43.4, 270.0}
```

**2. Karten-Bild ablegen**

Eine 4:3-Datei im webp/jpg/png-Format in `ui/img/` legen, z.B. `blackwaterspawn.webp`. Empfohlene Größe: 600×400 Pixel oder größer.

**3. Eintrag in `config.lua` hinzufügen**

```lua
Config.Spawns = {
    ["VALENTINE"]    = { ... },
    ["SAINT_DENIS"]  = { ... },
    -- ... bestehende Einträge ...

    ["BLACKWATER"] = {
        image       = "img/blackwaterspawn.webp",
        title       = "Blackwater",
        description = "Eine moderne Stadt am Rande von West Elizabeth. Banken, Telegramme und Ärger.",
        coords      = vector4(-794.0, -1278.0, 43.4, 270.0),
        items = {
            { name = "bread", label = "Brot",   amount = 5 },
            { name = "water", label = "Wasser", amount = 3 },
        },
        currency = {
            money = 500,
            gold  = 0,
            rol   = 0,
        },
        job        = { name = "citizen", grade = 0, label = "Bürger" },
        enableJob  = nil,   -- globaler Flag
    },
}
```

**4. Resource neustarten**

```
restart J0K3R-whitelist_spawnselector
```

**5. Testen**

Um die UI auf einem bereits whitelisten Char wieder zu sehen:

```sql
DELETE FROM j0k3r_whitelist WHERE identifier = 'license:DEINE_LICENSE';
```

Reconnecten → das Karten-Grid sollte jetzt deinen neuen Spawn zeigen.

---

## Items: `name` vs `label`

Das `name`-Feld ist der **Datenbank-Identifier**, den VORP verwendet, um das Item ins Inventar zu legen. Es muss exakt einem Eintrag in deiner `items`-Tabelle entsprechen.

Das `label`-Feld ist **das, was dem Spieler im NUI angezeigt wird**. Reine Kosmetik.

| `name` (DB) | `label` (NUI) | Anzeige |
|-------------|----------------|---------|
| `bread` | `"Brot"` | Brot × 5 |
| `bread` | `"Frisches Brot"` | Frisches Brot × 5 |
| `bread` | weggelassen | bread × 5 (Fallback auf name) |

Gültige Item-Namen finden:

```sql
SELECT item, label FROM items ORDER BY label;
```

---

## Currency-Map

```lua
currency = {
    money = 500,   -- Dollar      ($)
    gold  = 5,     -- Goldbarren
    rol   = 100,   -- Roll (XP)
}
```

Diese mappen direkt auf VORPs interne Währungstypen (`0 = money`, `1 = gold`, `2 = rol`). Werte die `0`, `nil` oder weggelassen sind, werden übersprungen.

---

## Bilder-Richtlinien

- **Format:** webp (kleinste), jpg oder png
- **Seitenverhältnis:** ~4:3 sieht auf den Karten am besten aus
- **Größe:** 600×400 oder größer; das NUI skaliert via CSS herunter
- **Stil-Tipp:** RDR2-Painterly-Look oder In-Game-Screenshots passen am besten. Vermeide Neon / moderne UI-Screenshots — kollidiert mit dem Western-Theme.

Die Karten-Höhe ist responsive (clamp von 140px auf 1080p bis 280px auf 4K), die Bilder müssen also bei mehreren Größen gut aussehen.

---

## Wie viele Spawns sind möglich?

Es gibt **kein hartes Limit**. Das Grid ist `flex-wrap`, Karten umbrechen einfach in die nächste Zeile.

| Anzahl Karten | Aussehen |
|---------------|----------|
| 2-4 | Eine Reihe, sehr prominent |
| 5-8 | 2 Reihen, gut lesbar |
| 9-12 | 3 Reihen, vertikales Scrollen auf kleineren Screens |
| 12+ | Mehrere Reihen, vertikales Scrollen auf den meisten Screens |

Bei vielen Spawns die Beschreibungen kurz halten (eine Zeile), damit die Karten nicht zu hoch werden.

---

## Pro-Spawn Job-Override (volle Tabelle)

| Global `EnableJobAssignment` | Spawn `enableJob` | Hat `job`-Block | Resultat |
|:----------------------------:|:-----------------:|:---------------:|:---------|
| `false` | `nil` | ja | ❌ übersprungen (folgt global) |
| `false` | `nil` | nein | ❌ übersprungen |
| `false` | `true` | ja | ✅ vergeben (Override gewinnt) |
| `false` | `false` | ja | ❌ übersprungen (Override gewinnt) |
| `true` | `nil` | ja | ✅ vergeben (folgt global) |
| `true` | `nil` | nein | ❌ übersprungen (kein Job) |
| `true` | `true` | ja | ✅ vergeben |
| `true` | `false` | ja | ❌ übersprungen (Override gewinnt) |

**Faustregel:** Wenn du `enableJob` setzt, gewinnt das immer über den globalen Flag. Wenn du es `nil` lässt, entscheidet der globale Flag.
