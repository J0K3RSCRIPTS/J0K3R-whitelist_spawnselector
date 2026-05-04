# Discord Webhook Logs

The script can send log embeds to Discord channels for three events:

- 🟢 **Player spawned** (after passing whitelist)
- 🔴 **Quiz failed** (player got kicked or banned)
- ⛔ **Player banned** (quiz failure with `EnableTempBanOnFail`)

> **Webhooks do NOT need a Discord bot.** They use plain webhook URLs. If you want the bot features (role check / role assignment), see [discord-setup.md](discord-setup.md).

---

## Step 1: Create a webhook URL in Discord

1. In Discord, go to the **channel** you want logs to be posted in
2. Click the gear icon next to the channel name → **Edit Channel**
3. **Integrations** → **Webhooks** → **New Webhook**
4. Give it a name (e.g. `Whitelist Logs`) and an avatar (optional)
5. Click **Copy Webhook URL**

You'll get something like:
```
https://discord.com/api/webhooks/1234567890/abcdefghijklmn-OPQRSTUVWXYZ_1234567890abcdefghijklmnopqrstuv
```

---

## Step 2: Configure the resource

In `config.lua`:

```lua
Config.Webhooks = {
    EnableSpawnLog = true,
    EnableQuizLog  = true,
    EnableBanLog   = true,

    SpawnLogUrl = "https://discord.com/api/webhooks/.../spawn",
    QuizLogUrl  = "",   -- empty -> falls back to SpawnLogUrl
    BanLogUrl   = "",   -- empty -> falls back to SpawnLogUrl

    Username  = "J0K3R Whitelist",
    AvatarUrl = "",
    Colors = {
        Spawn      = 0x3e7c47,   -- green
        QuizFailed = 0x8b1a1a,   -- dark red
        Ban        = 0x8b1a1a,   -- dark red
    },
    Fields = {
        Identifiers = true,
        Character   = true,
        Spawn       = true,
        Rewards     = true,
    },
}
```

You can put **all three log types into the same channel** (just leave `QuizLogUrl` and `BanLogUrl` empty), or have **three separate channels**:

```lua
SpawnLogUrl = "https://.../spawns-channel-webhook",
QuizLogUrl  = "https://.../quiz-failures-webhook",
BanLogUrl   = "https://.../bans-webhook",
```

---

## Reference: all settings

### Toggles

| Option | Default | Description |
|--------|---------|-------------|
| `EnableSpawnLog` | `false` | Log every successful spawn |
| `EnableQuizLog` | `false` | Log every failed quiz attempt (regardless of ban or kick) |
| `EnableBanLog` | `false` | Log every ban applied by this resource |

### URLs

| Option | Description |
|--------|-------------|
| `SpawnLogUrl` | Webhook URL for spawn logs |
| `QuizLogUrl` | Webhook URL for quiz failures (falls back to `SpawnLogUrl` if empty) |
| `BanLogUrl` | Webhook URL for bans (falls back to `SpawnLogUrl` if empty) |

### Visual customization

| Option | Description |
|--------|-------------|
| `Username` | Bot name displayed next to each message |
| `AvatarUrl` | Optional avatar for the webhook (Discord default if empty) |
| `Colors.Spawn` | Embed color for spawn events. Decimal (e.g. `4099399`) or hex (`0x3e7c47`) |
| `Colors.QuizFailed` | Embed color for quiz failures |
| `Colors.Ban` | Embed color for bans |

> 💡 Discord embed colors are 24-bit RGB. Use a color picker like https://htmlcolorcodes.com/ to find the right hex value.

### Field toggles

Each field in the **spawn log** can be turned off individually:

| Toggle | Hides |
|--------|-------|
| `Fields.Identifiers = false` | Steam, License, Discord ID rows |
| `Fields.Character = false` | Character name, char ID, sex, age |
| `Fields.Spawn = false` | Spawn title, description, coordinates |
| `Fields.Rewards = false` | Items, currency, job assignment status |

This lets you build a slim "minimal" log channel and a detailed "verbose" channel using the same script (just two sets of webhook URLs and two configs — though the script only has one config, so pick one mode).

---

## What does each log look like?

### 🟢 Spawn log

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

### 🔴 Quiz failed log

```
🔴 Quiz failed
Player failed the quiz and was temp-banned for 30 minutes.

Player        `John_Doe` (ID: 7)
Steam         `steam:1100...`     Discord  <@123456789>
Character     John Marston
Result        **2 / 5** correct

[timestamp] ...
```

### ⛔ Ban log

```
⛔ Player banned
You failed the whitelist test. You can try again in 30 minutes.

Identifier    `license:abc...`
Player        `John_Doe` (ID: 7)
Duration      30 min                Until    2026-01-15 19:12:11

[timestamp] ...
```

---

## Troubleshooting

| Problem | Likely cause |
|---------|--------------|
| No log appears in Discord | Check `Config.Webhooks.EnableSpawnLog = true` and the URL is filled in. Check server console for `[J0K3R-whitelist][webhook]` errors with the HTTP status code. |
| HTTP 401 / 404 | Webhook URL is wrong, deleted, or you copied only part of it |
| HTTP 429 | Discord rate-limited you (too many spawns in short time). Auto-recovers. |
| Embed shows fields with `n/a` | Player has no Steam/Discord linked, or character has no name set. Disable fields you don't need via `Fields.*`. |
| Embed timestamps are wrong | Discord shows them in the viewer's local timezone — that's normal. Server logs use UTC ISO format internally. |

To enable verbose logging set `Config.Debug = true`. Then any non-200/204 webhook response will be printed to the server console.

---

## Privacy considerations

The spawn log includes the player's **Steam ID, license, and Discord ID**. These are technical identifiers, not personal info per se, but you should still:

- Restrict access to the log channel to staff/admins only
- Not share screenshots of logs publicly
- Comply with your local privacy laws (GDPR / CCPA / etc.) when storing this info

You can disable the `Identifiers` field group entirely:

```lua
Config.Webhooks.Fields.Identifiers = false
```

This will leave only the in-game player name + character info in the log.
