# Installation

## Requirements

| Dependency      | Version | Notes                                     |
|-----------------|---------|-------------------------------------------|
| **RedM Server** | latest  | FXServer with `rdr3_warning` accepted     |
| **VORP Core**   | latest  | https://github.com/VORPCORE/vorp_core-lua |
| **VORP Inventory** | latest | https://github.com/VORPCORE/vorp_inventory-lua |
| **oxmysql**     | latest  | https://github.com/overextended/oxmysql   |
| **MariaDB / MySQL** | 5.7+ | for storing the whitelist state           |

A Discord bot is **optional** — only required if you want to:
- skip the quiz for players who already have a whitelist role
- automatically assign a Discord role after passing the quiz
- send log webhooks (those work without a bot, just with a webhook URL)

---

## 1. Drop the resource into your server

Copy the entire `J0K3R-whitelist_spawnselector/` folder into your `resources/` directory.

```
your-server/
├── resources/
│   ├── [vorp]/
│   │   ├── vorp_core/
│   │   ├── vorp_inventory/
│   │   └── ...
│   ├── J0K3R-whitelist_spawnselector/   ← here
│   └── ...
└── server.cfg
```

---

## 2. Import the SQL

The resource creates its own table `j0k3r_whitelist`. Run the install script once on your VORP database:

```sql
SOURCE J0K3R-whitelist_spawnselector/sql/install.sql;
```

Or via terminal:

```bash
mysql -u USER -p DATABASE < resources/J0K3R-whitelist_spawnselector/sql/install.sql
```

Verify the table exists:

```sql
SHOW TABLES LIKE 'j0k3r_whitelist';
DESCRIBE j0k3r_whitelist;
```

You should see five columns: `id`, `identifier`, `charidentifier`, `passed`, `chosen_spawn`, `passed_at`.

> **Note:** The ban mechanic does **not** need an extra table. VORP stores bans directly in the existing `users` table (`banned` + `banneduntil` columns) which VORP Core creates automatically.

---

## 3. Start the resource in `server.cfg`

```cfg
ensure J0K3R-whitelist_spawnselector
```

Make sure it loads **after** `vorp_core`, `vorp_inventory` and `oxmysql`.

If you want to use the Discord bot features, also add:

```cfg
set discord_token "YOUR_BOT_TOKEN_HERE"
```

(See [discord-setup.md](discord-setup.md) for how to get a token.)

---

## 4. Verify the startup banner

Start your server. In the console you should see:

```
+----------------------------------------------------+
|   J0K3R-whitelist_spawnselector by J0K3R-Scripts   |
|   Discord: https://discord.gg/DH8tW6vSxV           |
|   Free script, contributions welcome               |
+----------------------------------------------------+
[J0K3R-whitelist_spawnselector] loaded v1.0.0  •  framework: vorp_core  •  locale: en  •  jobs: false  •  policy: first
```

If you instead see this in red:

```
[J0K3R-whitelist_spawnselector] WARNING: Table 'j0k3r_whitelist' is missing!
```

→ go back to step 2.

---

## 5. First test

Connect to your server and create a brand-new character. The whitelist UI should pop up automatically right after character creation.

If nothing happens:
- Set `Config.Debug = true` and check your server console for `[J0K3R-whitelist]` log lines
- You can also use the debug command `/spawnselector` (only works when Debug is on)

→ Continue to [configuration.md](configuration.md) to tweak the script to your needs.

---

## File structure overview

```
J0K3R-whitelist_spawnselector/
├── fxmanifest.lua
├── config.lua          ← all settings live here
├── locale.lua          ← UI translations (en + de)
├── shared.lua          ← LANG / Shuffle helpers
├── client/main.lua     ← NUI control, character hooks
├── server/
│   ├── main.lua        ← logic, DB, rewards, webhooks
│   └── discord.lua     ← Discord API integration
├── sql/install.sql
├── ui/
│   ├── index.html
│   ├── style.css       ← responsive (1080p/1440p/4K)
│   ├── script.js
│   ├── img/            ← spawn cards & background
│   └── fonts/
└── docs/
    ├── en/             ← these docs
    └── de/             ← German translations
```
