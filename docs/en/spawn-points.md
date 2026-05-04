# Spawn Points

Each entry in `Config.Spawns` produces one card in the spawn-selector UI. The list is fully dynamic — the NUI loops through whatever you put in `Config.Spawns`, so you can have as many or as few spawns as you want.

## Anatomy of a spawn entry

```lua
["VALENTINE"] = {                                                  -- unique key (UPPERCASE recommended)
    image       = "img/valentinespawn.webp",                       -- card image
    title       = "Valentine",                                     -- card heading
    description = "A bustling town in the heart of New Hanover.",  -- card subtitle
    coords      = vector4(-174.7543, 622.2214, 114.0320, 236.24),  -- x, y, z, heading
    items = {
        { name = "bread", label = "Bread", amount = 5 },
        { name = "water", label = "Water", amount = 3 },
    },
    currency = {
        money = 500,
        gold  = 0,
        rol   = 0,
    },
    job        = { name = "citizen", grade = 0, label = "Citizen" },
    enableJob  = nil,
},
```

### Required fields

| Field | Type | Description |
|-------|------|-------------|
| `image` | string | Path relative to `ui/`. Place the file in `ui/img/`. |
| `title` | string | Heading shown on the card (max ~25 chars looks best). |
| `description` | string | Subtitle text under the title (max ~120 chars looks best). |
| `coords` | vector4 | `x, y, z, heading`. The heading determines which way the player faces after spawning. |

### Optional fields

| Field | Type | Description |
|-------|------|-------------|
| `items` | table | List of items granted on spawn. Each item: `{ name = "db_name", label = "Display Name", amount = 5 }` |
| `currency` | table | `{ money = N, gold = N, rol = N }`. Set to `0` or omit to skip. |
| `job` | table | `{ name = "...", grade = 0, label = "..." }`. Only used if job assignment is on (see [configuration.md](configuration.md#job-assignment)). |
| `enableJob` | bool/nil | Per-spawn override of the global `Config.EnableJobAssignment`. `true` = force-assign, `false` = force-skip, `nil` = follow the global setting. |

---

## Adding a new spawn

There's a ready-to-uncomment **TEMPLATE** block at the bottom of `Config.Spawns` in `config.lua`. Just copy any existing block, rename the key, and change the values.

### Step-by-step example: adding "Blackwater"

**1. Get the coordinates in-game**

Connect to your server, walk to the spot where you want players to spawn, face the direction they should look, then run an admin command that prints your coords. Example with vorp_admin:

```
/coords
```

You'll get something like:
```
{-794.0, -1278.0, 43.4, 270.0}
```

**2. Place a card image**

Drop a 4:3 webp/jpg/png file into `ui/img/`, e.g. `blackwaterspawn.webp`. Recommended size: 600×400 pixels or larger.

**3. Add the entry to `config.lua`**

```lua
Config.Spawns = {
    ["VALENTINE"]    = { ... },
    ["SAINT_DENIS"]  = { ... },
    -- ... existing entries ...

    ["BLACKWATER"] = {
        image       = "img/blackwaterspawn.webp",
        title       = "Blackwater",
        description = "A modernizing town on the edge of West Elizabeth. Banking, telegraphs, and trouble.",
        coords      = vector4(-794.0, -1278.0, 43.4, 270.0),
        items = {
            { name = "bread", label = "Bread", amount = 5 },
            { name = "water", label = "Water", amount = 3 },
        },
        currency = {
            money = 500,
            gold  = 0,
            rol   = 0,
        },
        job        = { name = "citizen", grade = 0, label = "Citizen" },
        enableJob  = nil,   -- follow the global flag
    },
}
```

**4. Restart the resource**

```
restart J0K3R-whitelist_spawnselector
```

**5. Test**

To see the UI again on a character that already passed:

```sql
DELETE FROM j0k3r_whitelist WHERE identifier = 'license:DEINE_LICENSE';
```

Reconnect → the card grid should now show your new spawn.

---

## Items: `name` vs `label`

The `name` field is the **database identifier** that VORP uses to add the item to the inventory. It must match an existing entry in your `items` table.

The `label` field is **what's shown to the player** in the NUI. It's purely cosmetic.

| `name` (DB) | `label` (NUI) | Display |
|-------------|----------------|---------|
| `bread` | `"Bread"` | Bread × 5 |
| `bread` | `"Frisches Brot"` | Frisches Brot × 5 |
| `bread` | omitted | bread × 5 (falls back to name) |

To find valid item names:

```sql
SELECT item, label FROM items ORDER BY label;
```

---

## Currency map

```lua
currency = {
    money = 500,   -- Dollars     ($)
    gold  = 5,     -- Gold bars
    rol   = 100,   -- Roll (XP)
}
```

These map directly to VORP's internal currency types (`0 = money`, `1 = gold`, `2 = rol`). Any value that's `0`, `nil`, or omitted is skipped.

---

## Image guidelines

- **Format:** webp (smallest), jpg, or png
- **Aspect ratio:** roughly 4:3 looks best on the cards
- **Size:** 600×400 or larger; the NUI scales them down via CSS
- **Style tip:** RDR2 painterly look or in-game screenshots work best. Avoid neon / modern UI screenshots — they clash with the western theme.

The card height is responsive (clamp from 140px on 1080p to 280px on 4K), so all images need to look good at multiple sizes.

---

## How many spawns can I add?

There is **no hard limit**. The grid is `flex-wrap`, so cards just continue on the next row.

| Number of cards | Looks like |
|-----------------|-----------|
| 2-4 | Single row, very prominent |
| 5-8 | 2 rows, still readable |
| 9-12 | 3 rows, scrolling kicks in on smaller screens |
| 12+ | Multiple rows, vertical scroll on most screens |

If you have many spawns, consider making the descriptions short (one line) so the cards don't get tall.

---

## Per-spawn job override (full table)

| Global `EnableJobAssignment` | Spawn `enableJob` | Has `job` block | Result |
|:----------------------------:|:-----------------:|:---------------:|:-------|
| `false` | `nil` | yes | ❌ skipped (follows global) |
| `false` | `nil` | no | ❌ skipped |
| `false` | `true` | yes | ✅ assigned (override wins) |
| `false` | `false` | yes | ❌ skipped (override wins) |
| `true` | `nil` | yes | ✅ assigned (follows global) |
| `true` | `nil` | no | ❌ skipped (no job to assign) |
| `true` | `true` | yes | ✅ assigned |
| `true` | `false` | yes | ❌ skipped (override wins) |

**Rule of thumb:** If you set `enableJob`, it always wins over the global flag. If you leave it `nil`, the global flag decides.
