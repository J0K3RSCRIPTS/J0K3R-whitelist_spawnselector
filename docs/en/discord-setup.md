# Discord Bot Setup

This guide walks you through setting up a Discord bot for two optional features:

1. **Role check** — skip the quiz for players who already have a whitelist role on Discord
2. **Role assignment** — automatically grant a role after passing the quiz (and optionally remove a "guest" role)

> **Webhook logs do NOT need a bot.** They use simple webhook URLs. If you only want logs, skip this guide and read [webhooks.md](webhooks.md) instead.

---

## Step 1: Create the Discord application

1. Go to https://discord.com/developers/applications
2. Click **"New Application"** (top right)
3. Give it a name — e.g. `J0K3R Whitelist Bot`
4. Accept the ToS, click **Create**

---

## Step 2: Create the bot user & get the token

1. In the left sidebar, click **"Bot"**
2. (If asked) click **"Add Bot"** → confirm
3. Under **Token**, click **"Reset Token"** → copy the token
   - ⚠️ **The token is only shown once.** If you lose it, you have to reset it again.
4. Add it to your `server.cfg`:
   ```cfg
   set discord_token "MTAxxxxxxxxxxxxxxxxxxxxxxxx.G..."
   ```
   - **Never put the token in `config.lua`** — it could leak through escrow or git.

---

## Step 3: ⭐ Enable Privileged Gateway Intents

This is **the most commonly missed step.** Without it, the bot can't read member roles.

Still in the **Bot** tab, scroll down to **"Privileged Gateway Intents"**:

| Intent | Required? | Why |
|--------|-----------|-----|
| ✅ **SERVER MEMBERS INTENT** | **YES — REQUIRED** | Allows the bot to query member info via `GET /guilds/{id}/members/{id}` |
| ❌ Presence Intent | No | We don't care about online/offline status |
| ❌ Message Content Intent | No | We don't read messages |

Toggle **SERVER MEMBERS INTENT** on → click **Save Changes**.

---

## Step 4: Generate an invite URL

1. In the left sidebar, click **"OAuth2"** → **"URL Generator"**
2. Under **Scopes**, check:
   - ✅ `bot`
   - ✅ `applications.commands` (optional but harmless)
3. Under **Bot Permissions**, check:
   - ✅ **Manage Roles** ← **REQUIRED**
   - ✅ View Channels (default)
   - ✅ Read Message History (optional)

4. At the bottom of the page you'll see the **Generated URL** — copy it.

> 💡 For testing, you can also tick `Administrator` to give the bot all permissions. For production, prefer minimum permissions.

---

## Step 5: Invite the bot to your Discord server

1. Open the generated URL in your browser
2. Select your Discord server from the dropdown
3. Click **Authorize** → solve the captcha if asked
4. The bot is now in your server (as offline — that's normal, see Step 7)

---

## Step 6: ⭐ Fix the role hierarchy

This is **the second most commonly missed step.** Discord forbids a bot from modifying roles that are **above** its own role in the hierarchy.

1. In your Discord server → **Server Settings** → **Roles**
2. You'll see a list of roles. The bot's role (named after your bot) is usually somewhere at the bottom.
3. **Drag the bot's role UP** so it sits **above** the whitelist role.

**Correct hierarchy** (top = highest):
```
├── @Owner / Admin
├── 🤖 J0K3R Whitelist Bot      ← bot role must be HERE or HIGHER
├── ✅ Whitelisted               ← the role the bot will assign
├── 👤 Guest
└── @everyone
```

**Wrong** (will produce HTTP 403):
```
├── ✅ Whitelisted               ← above the bot
├── 🤖 J0K3R Whitelist Bot      ← can't modify the role above it
└── @everyone
```

---

## Step 7: Configure the resource

In `config.lua`:

```lua
Config.Discord = {
    GuildId               = "123456789012345678",        -- right-click your server icon -> Copy Server ID
    WhitelistedRoleId     = "987654321098765432",        -- right-click the role -> Copy Role ID
    AssignRoleAfterPass   = "987654321098765432",        -- usually same as above
    RemoveRoleAfterPass   = "",                            -- empty = no removal
    TokenConvarName       = "discord_token",
}

Config.EnableDiscordRoleCheck      = true
Config.EnableDiscordRoleAssignment = true
```

> **How to copy IDs in Discord:**
> 1. Discord → Settings → Advanced → enable **Developer Mode**
> 2. Right-click any server / role / channel → **"Copy ... ID"**

---

## Step 8: Restart and verify

```
restart J0K3R-whitelist_spawnselector
```

> ⚠️ Note: the bot uses Discord's **REST API**, not the Gateway. So the bot will appear as **OFFLINE** in the member list even when everything works correctly. Don't trust the online indicator — trust the console logs.

### Test scenario A: player WITH the role

1. Make sure your test account has the `Whitelisted` role in Discord
2. Reset the DB: `DELETE FROM j0k3r_whitelist WHERE identifier = 'license:YOUR_LICENSE';`
3. Connect to the RedM server and create a new character
4. The whitelist UI should **NOT** open
5. You should get an in-game notification: *"Existing whitelist role detected - skipping quiz."*
6. The DB should now have an entry with `passed = 1`

### Test scenario B: player WITHOUT the role

1. Remove the `Whitelisted` role from your test account on Discord
2. Reset the DB again
3. Connect → quiz appears → pass it
4. **Server console should show:**
   ```
   ^2[J0K3R-whitelist][discord] ✅ Role assigned to 123456789 (role=987654321098765432)^7
   ```
5. **Discord:** the test account now has the `Whitelisted` role ✅

---

## Troubleshooting

The new logging in `discord.lua` tells you exactly what's wrong. Map the error to the fix:

| Console output | Cause | Fix |
|----------------|-------|-----|
| `MISSING: discord_token convar is not set` | Token missing in `server.cfg` | Add `set discord_token "..."` and restart |
| `401 Unauthorized` | Token is wrong or expired | Reset token in Dev Portal, update `server.cfg` |
| `403 Forbidden - bot lacks 'Manage Roles' or its role is below the target role` | Two possible causes — check both | (a) Bot role doesn't have "Manage Roles" → step 4 (b) Bot role is below the whitelist role → step 6 |
| `404 Not Found - guild ID, role ID, or member not found` | Wrong ID in config OR bot isn't in the server OR player isn't in the Discord server | Check `GuildId`, `WhitelistedRoleId`. Verify the bot was actually invited (step 5). |
| `0 No response - check internet connection or 'Server Members Intent'` | SERVER MEMBERS INTENT is off | Step 3 |
| `429 Rate Limited` | Too many requests in a short window | Wait a moment; should auto-recover |

If nothing shows up at all: set `Config.Debug = true` in `config.lua` to see verbose logging.

---

## How does the role check work technically?

The bot uses Discord's REST API directly via FXServer's `PerformHttpRequest`:

**Role check:**
```
GET https://discord.com/api/v10/guilds/{guild_id}/members/{discord_id}
Authorization: Bot {token}
```
Returns the member object including their `roles` array. The script checks if `WhitelistedRoleId` is in that array.

**Role assign:**
```
PUT https://discord.com/api/v10/guilds/{guild_id}/members/{discord_id}/roles/{role_id}
Authorization: Bot {token}
```
Returns HTTP 204 on success.

**Role remove:**
```
DELETE https://discord.com/api/v10/guilds/{guild_id}/members/{discord_id}/roles/{role_id}
Authorization: Bot {token}
```

The Discord ID is extracted from the player's identifier list (the `discord:...` entry that FiveM/RedM provides when the player has Discord linked to their account).

> **Important:** Players must have Discord running and connected to their RedM/FiveM client when they connect. Otherwise no `discord:` identifier is present and the role check / assignment is silently skipped.
