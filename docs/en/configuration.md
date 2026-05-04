# Configuration

All settings live in **`config.lua`** in the resource root. This document explains every option.

## Table of contents

- [General](#general)
- [Feature toggles](#feature-toggles)
- [Job assignment](#job-assignment)
- [Spawn coordinate saving](#spawn-coordinate-saving)
- [Character policy](#character-policy)
- [Quiz settings](#quiz-settings)
- [Ban provider](#ban-provider)
- [Discord settings](#discord-settings)
- [Webhook logs](#webhook-logs)
- [Design / NUI look](#design--nui-look)

---

## General

```lua
Config.Debug   = true   -- Debug mode (enables /spawnselector + console logs)
Config.Locale  = "en"   -- UI language: "en" or "de" (see locale.lua)
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `Debug` | bool | `true` | When `true`, prints debug info to the console and registers the `/spawnselector` command for manual testing. **Turn this off in production.** |
| `Locale` | string | `"en"` | UI language. Currently shipped: `"en"` and `"de"`. To add another language, see [locale.lua](#adding-a-new-language). |

---

## Feature toggles

Each major component can be enabled / disabled individually.

```lua
Config.EnableSpawnSelector         = true
Config.EnableRules                 = true
Config.EnableQuiz                  = true
Config.EnableQuizTimer             = true
Config.EnableTempBanOnFail         = false
Config.EnableDiscordRoleCheck      = true
Config.EnableDiscordRoleAssignment = true
```

| Option | Effect when `true` |
|--------|---------------------|
| `EnableSpawnSelector` | Show the visual spawn-selector cards as the first stage |
| `EnableRules` | Show the server rules with a scroll-to-bottom requirement before continuing |
| `EnableQuiz` | Run the whitelist quiz with random questions |
| `EnableQuizTimer` | Show a countdown timer during the quiz; if it expires, the quiz is auto-failed |
| `EnableTempBanOnFail` | Apply a temporary ban when the quiz is failed (instead of just kicking) |
| `EnableDiscordRoleCheck` | Check the player's Discord roles on connect; skip the whole process if they already have the whitelist role |
| `EnableDiscordRoleAssignment` | After passing the quiz, automatically assign / remove configured Discord roles |

You can mix and match freely — e.g. `EnableSpawnSelector + EnableQuiz` (no rules), or `EnableRules + EnableQuiz` (no spawn picker), etc.

---

## Connect re-validation

```lua
Config.EnableConnectRevalidation = false
Config.RevalidationKickMessage   = "You are no longer whitelisted on this server. Please contact staff."
```

**What it does:** When `true`, the script re-validates **every** player on **every** connect — not just on first character creation. If they no longer have the Discord whitelist role (or no DB entry), they get kicked from the server immediately.

**Use cases:**
- 🔒 **Catching role-removal:** If a player gets banned from your Discord (and the role is removed), they can't sneak back into the RedM server.
- 🛡️ **Anti-evasion:** A user who leaves your Discord server loses the role automatically (Discord behavior) — and is therefore kicked.
- 🧹 **Whitelist cleanup:** Removing someone from the DB manually (`DELETE FROM j0k3r_whitelist...`) is enough to kick them on next connect.

**Validation matrix:**

| DB entry | Discord role | `EnableConnectRevalidation = false` | `EnableConnectRevalidation = true` |
|:--------:|:------------:|-------------------------------------|------------------------------------|
| ✅ | ✅ | ✅ Pass through | ✅ Pass through |
| ✅ | ❌ | ✅ Pass through ⚠️ | ❌ **Kick** (role lost) |
| ❌ | ✅ | ✅ Auto-mark + pass through | ✅ Auto-mark + pass through |
| ❌ | ❌ (new char) | ➡️ Run process | ➡️ Run process |
| ❌ | ❌ (existing char) | ✅ Pass through ⚠️ | ❌ **Kick** |

> ⚠️ The default `false` is backwards-compatible — once a player is whitelisted in the DB, they stay whitelisted forever. Turn this on for stricter enforcement.

> **Tip:** For maximum security, combine `EnableConnectRevalidation = true` with `EnableDiscordRoleCheck = true`. This way the Discord role becomes the single source of truth — and removing it is the same as kicking the player from the server.

---

## Job assignment

```lua
Config.EnableJobAssignment = false
```

Globally controls whether VORP `job` / `jobgrade` / `joblabel` are written when the player spawns.

**Set to `false`** if you have a separate job system (vorp_jobs, custom job menus, etc.) and don't want this script to touch the player's job at all.

**Set to `true`** to let the script assign jobs based on the `job` block in each spawn entry.

### Per-spawn override

Each entry in `Config.Spawns` can override the global flag:

```lua
["MY_SPAWN"] = {
    -- ...
    job        = { name = "myjob", grade = 0, label = "My Job" },
    enableJob  = true,   -- always assign the job here, even if global is false
    -- enableJob = false -> never assign here, even if global is true
    -- enableJob = nil   -> follow the global Config.EnableJobAssignment
},
```

See [spawn-points.md](spawn-points.md) for full details.

---

## Spawn coordinate saving

```lua
Config.SaveSpawnAsDefaultSpawn = true
```

When `true`, the chosen spawn is saved as the character's default spawn coordinates. On future logins the player will spawn at their picked location instead of the VORP default.

The call is wrapped in `pcall` so it won't break if your VORP version doesn't expose `updateCharPos`.

---

## Character policy

```lua
Config.CharacterPolicy = "first"
```

Determines how often the whitelist process runs.

| Value | Behavior |
|-------|----------|
| `"first"` | **(default, recommended)** Run the process **once per account**. Once any character has passed, the whole account is considered whitelisted. |
| `"perchar"` | Each new character has to pick a spawn and (optionally) take the quiz again. |
| `"perplayer"` | Same as `"first"` — kept as an alias for clarity. |

> **Note about the DB:** With `"first"` or `"perplayer"`, the `charidentifier` column in `j0k3r_whitelist` is stored as `0` (NULL), because the whitelist is account-wide. Only `"perchar"` writes the actual character ID. This is intentional.

---

## Quiz settings

```lua
Config.QuizQuestionsPerTest = 5
Config.MaxMistakesAllowed   = 1
Config.QuizTimeSeconds      = 180
Config.TempBanMinutes       = 30
Config.ShuffleAnswers       = true
```

| Option | Default | Description |
|--------|---------|-------------|
| `QuizQuestionsPerTest` | `5` | How many questions are randomly drawn from the pool in `Config.Questions` |
| `MaxMistakesAllowed` | `1` | Max wrong answers tolerated. `0` = strict, `2` = lenient |
| `QuizTimeSeconds` | `180` | Total countdown in seconds. The server validates this server-side as anti-cheat. |
| `TempBanMinutes` | `30` | Ban duration when the quiz is failed (only used if `EnableTempBanOnFail = true` and `BanProvider = "vorp_admin"`) |
| `ShuffleAnswers` | `true` | Randomize the order of answers per question (the server keeps track of the actual correct index) |

To edit the question pool, see the `Config.Questions` block in `config.lua`. You can have as many questions in the pool as you want — `QuizQuestionsPerTest` of them are picked randomly per attempt.

---

## Ban provider

```lua
Config.BanProvider = "drop_only"
```

| Value | Behavior |
|-------|----------|
| `"vorp_admin"` | Updates the `users.banned` + `users.banneduntil` columns. **VORP Core blocks the player automatically on next connect** — fully compatible with vorp_admin. |
| `"drop_only"` | Just `DropPlayer(...)`, no DB entry. Useful for tests or when using a custom ban manager. |

Any other value falls back to `"drop_only"` for safety.

---

## Discord settings

```lua
Config.Discord = {
    GuildId               = "YOUR_GUILD_ID_HERE",
    WhitelistedRoleId     = "YOUR_WHITELIST_ROLE_ID",
    AssignRoleAfterPass   = "YOUR_WHITELIST_ROLE_ID",
    RemoveRoleAfterPass   = "",
    TokenConvarName       = "discord_token",
}
```

| Option | Description |
|--------|-------------|
| `GuildId` | Your Discord server (guild) ID |
| `WhitelistedRoleId` | The role a player has when they're already whitelisted. Used by `EnableDiscordRoleCheck` |
| `AssignRoleAfterPass` | Role to give the player after they pass the quiz |
| `RemoveRoleAfterPass` | Role to take away after passing (e.g. a "Guest" role). Leave as `""` to skip |
| `TokenConvarName` | Name of the convar that holds the bot token. Default: `discord_token` (set via `set discord_token "..."` in `server.cfg`) |

> **Never put the bot token in `config.lua`!** Always use the convar in `server.cfg`. See [discord-setup.md](discord-setup.md) for the full bot setup.

---

## Webhook logs

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

See [webhooks.md](webhooks.md) for the full documentation.

---

## Design / NUI look

```lua
Config.Design = {
    PrimaryColor      = "#c9a559",   -- gold accent
    SecondaryColor    = "#8b1a1a",   -- dark red (errors)
    SuccessColor      = "#3e7c47",   -- green (passed)
    BackgroundColor   = "#1a0f08",   -- dark wood-brown
    TextColor         = "#f4e8d0",   -- parchment cream
    Opacity           = 0.92,        -- background opacity
    BorderColor       = "#c9a559",
    FontHeader        = "RDR Lino",
    FontBody          = "HapnaSlabSerif",
    BackgroundImage   = "img/background.webp",
}
```

These values are pushed to the NUI as CSS variables. You can change them on the fly without touching CSS.

| Option | Description |
|--------|-------------|
| `PrimaryColor` | Used for buttons, card titles, accent text. Hex format. |
| `SecondaryColor` | Used for error states (failed quiz, ban warnings). |
| `SuccessColor` | Used for "passed!" screens and confirmation. |
| `BackgroundColor` | Behind the cards/panels. The semi-transparent overlay color. |
| `TextColor` | Default body text color. |
| `Opacity` | How dark the background overlay is. `1.0` = fully opaque, `0.5` = half-transparent. |
| `BorderColor` | Card and panel borders. |
| `FontHeader` | Used for headings, buttons, card titles. Must match a `@font-face` declaration in `style.css`. |
| `FontBody` | Used for body text and answers. |
| `BackgroundImage` | Path relative to `ui/` (e.g. `img/background.webp`). |

To replace fonts or add new ones, drop the `.ttf` / `.woff2` file into `ui/fonts/` and update the `@font-face` block in `style.css`.

---

## Adding a new language

In `locale.lua`, add a new block:

```lua
Locales["fr"] = {
    notify_title           = "Système de Liste Blanche",
    spawn_select_title     = "Choisissez votre spawn",
    -- ... copy all keys from Locales["en"] and translate
}
```

Then set `Config.Locale = "fr"`.

If a key is missing from your language pack, the script falls back to English automatically (and prints `[MISSING_LOCALE:key]` if the key doesn't exist there either).
