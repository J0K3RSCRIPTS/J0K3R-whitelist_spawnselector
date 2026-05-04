# Troubleshooting

Common issues and how to fix them. Sorted by category.

---

## Resource doesn't start

### `WARNING: Table 'j0k3r_whitelist' is missing!`

You forgot to import the SQL.

**Fix:** Run `sql/install.sql` on your VORP database. See [installation.md](installation.md#2-import-the-sql).

### `attempt to index a nil value (global 'exports')`

VORP isn't loaded yet, or the resource was started **before** vorp_core / vorp_inventory.

**Fix:** In `server.cfg`, make sure the `ensure J0K3R-whitelist_spawnselector` line comes **after** the VORP resources.

### `module 'oxmysql' not found`

oxmysql isn't installed or not started.

**Fix:** Install oxmysql from https://github.com/overextended/oxmysql and ensure it's started before this resource.

---

## NUI doesn't open

### Nothing happens when a new character is created

The most common cause: `vorp:initNewCharacter` isn't firing.

**Fix:**
1. Set `Config.Debug = true` in `config.lua`
2. Restart the resource and create a new character
3. In the **client console (F8)** look for:
   ```
   [J0K3R-whitelist] vorp:initNewCharacter triggered
   [J0K3R-whitelist] vorp:initCharacter triggered, pendingNewChar=true
   ```
4. If the first line is missing, your VORP version may not fire that event. Use the manual `/spawnselector` command instead, or contact J0K3R-Scripts.

### UI opens but is blank / nothing visible

The CSS or JS failed to load.

**Fix:**
1. In the in-game F8 console, open NUI dev tools:
   ```
   nui_devtools J0K3R-whitelist_spawnselector
   ```
2. Check the **Console** tab for JS errors and the **Network** tab for failed file loads.
3. Make sure all files in `ui/` are listed in `fxmanifest.lua` under `files {}`.

### UI opens but cards have no images

The image paths don't match files in `ui/img/`.

**Fix:**
1. Check `ui/img/` actually contains the files referenced in `Config.Spawns[*].image`
2. File names are **case-sensitive** on Linux servers (FXServer typically runs on Linux)
3. Force a NUI refresh by reconnecting

---

## Items / money not received

### Player gets no items after spawn

The item `name` doesn't match an entry in your `items` DB table.

**Fix:**
```sql
SELECT item, label FROM items WHERE item LIKE '%bread%';
```
Use the exact `item` value (not the label) as the `name` in `Config.Spawns[*].items`.

### `[J0K3R-whitelist][server] Player X cannot carry item bread x5`

Player's inventory is full or the item has a weight limit.

**Fix:** This is informational only — the item is just skipped. Player can ask a staff member, or you can reduce starting amounts.

### Money doesn't appear in wallet

VORP caches the character object. The currency was added but the UI shows the cached value.

**Fix:** Player disconnects and reconnects once. The new value will be loaded from DB.

---

## Quiz problems

### Quiz never starts after rules

The `RequestQuestions` event isn't reaching the server.

**Fix:**
1. Check both server and client consoles for errors
2. Verify `Config.QuizQuestionsPerTest <= #Config.Questions` — you can't draw more questions than exist in the pool
3. Ensure `Config.EnableQuiz = true`

### "Time's up" appears immediately

The quiz timer is firing too early.

**Fix:** Check `Config.QuizTimeSeconds` — make sure it's a reasonable value (60+ seconds).

### Player passes but doesn't get spawned

The `DoSpawn` event triggers but the world doesn't load fast enough.

**Fix:** This is a one-off; usually a re-test works. If it persists, increase the wait time in `client/main.lua` in the `DoSpawn` handler:
```lua
while not HasCollisionLoadedAroundEntity(playerPed) and tries < 100 do
    Wait(50)
    tries = tries + 1
end
```
Increase `tries < 100` to `tries < 200` for slower servers.

---

## Discord problems

See [discord-setup.md](discord-setup.md#troubleshooting) for the full Discord error code table. Quick summary:

| Error | Fix |
|-------|-----|
| `403 Forbidden` | Bot role too low in hierarchy OR no "Manage Roles" permission |
| `404 Not Found` | Wrong Guild ID / Role ID, or bot not in server |
| `401 Unauthorized` | Token invalid / expired |
| `0 No response` | SERVER MEMBERS INTENT not enabled |

---

## Webhook problems

### No log appears in Discord channel

1. `Config.Webhooks.EnableSpawnLog = true` (or relevant toggle) must be on
2. URL must be filled in
3. Check server console for `[J0K3R-whitelist][webhook] HTTP ...` errors
4. Test the URL manually:
   ```bash
   curl -X POST "YOUR_WEBHOOK_URL" -H "Content-Type: application/json" -d '{"content":"test"}'
   ```
   Should return HTTP 204 with no body.

### Embed has wrong colors

Discord uses 24-bit RGB. The values in `Config.Webhooks.Colors` must be **integers**, not strings:

```lua
Spawn = 0x3e7c47,        -- correct (hex)
Spawn = 4099399,         -- correct (decimal)
Spawn = "#3e7c47",       -- WRONG (string)
```

### Embed fields say `n/a` everywhere

Player has no Steam / Discord linked to their FiveM/RedM client, or the character has no firstname/lastname set.

**Fix:** Players need to have Steam and Discord running and linked to their RedM client. Otherwise the identifiers aren't available to the server. You can disable the fields:

```lua
Config.Webhooks.Fields.Identifiers = false
```

---

## Ban / re-test problems

### "I'm stuck on the ban screen"

You banned yourself during testing. Manual unban:

```sql
UPDATE users SET banned = 0, banneduntil = 0 WHERE identifier = 'license:YOUR_LICENSE';
```

### "I want to re-test the whitelist flow on my own account"

Reset your DB entry:

```sql
DELETE FROM j0k3r_whitelist WHERE identifier = 'license:YOUR_LICENSE';
```

Then on next character creation (or with `Config.CharacterPolicy = "perchar"` on next char), the flow runs again.

To reset **all testers** at once:

```sql
TRUNCATE TABLE j0k3r_whitelist;
```

---

## NUI scaling / display

### UI looks tiny on 4K

The `clamp()` values in `style.css` already cap at 4K-friendly sizes. If you still want bigger:

1. Edit `ui/style.css`
2. In the `:root` block, increase the **third** value of each `clamp(min, vw, max)`:
   ```css
   --fs-header: clamp(28px, 2.8vw, 64px);  /* increase 64px to e.g. 80px */
   ```

### UI overflows on 1080p

Some cards don't fit. Check:

1. Number of spawns × card width fits in viewport (4 × 280px ≈ 1120px + padding)
2. If you have 5+ spawns, they wrap to a 2nd row automatically — but if descriptions are too long, cards get tall and may overflow vertically
3. Reduce description length to one line for compact layouts

### Fonts not loading

Check browser cache (DevTools → Network → Disable cache). If still missing:

1. Verify `ui/fonts/rdrlino-regular.ttf` and `ui/fonts/hapnaslabserif-demibold.ttf` exist
2. Check `fxmanifest.lua` has `"ui/fonts/*"` in the files list
3. Check the `@font-face` declarations in `style.css` match the actual file names

---

## Performance

### Quiz takes a long time to load on slow connections

The whole `Config.Questions` pool isn't sent — only `Config.QuizQuestionsPerTest` are streamed. The bottleneck is usually the NUI initial render.

**Fix:** Reduce the number of `Config.Spawns` (less cards = faster initial UI render) or reduce the size of card images.

### Server CPU spikes when many people connect simultaneously

Each player triggers an `isWhitelisted` query and (if Discord is enabled) a `Discord_HasWhitelistRole` HTTP request.

**Fix:** This is normal. The DB query is `O(1)` thanks to the unique key, and the Discord API is rate-limited but not heavy. If you have a stress-test scenario, consider disabling `EnableDiscordRoleCheck` and relying on the DB cache only.

---

## When all else fails

1. Set `Config.Debug = true`
2. Reproduce the problem
3. Open both console outputs:
   - **Server console** — full output
   - **Client F8 console** — `[J0K3R-whitelist]` lines
4. Open NUI DevTools: `nui_devtools J0K3R-whitelist_spawnselector` in F8
5. Submit a bug report on the Discord (https://discord.gg/DH8tW6vSxV) with:
   - What you did
   - What you expected
   - What happened instead
   - The console outputs
   - Your `Config.lua` (with token / webhook URLs redacted!)
