# J0K3R-whitelist_spawnselector

**Author:** J0K3R-Scripts
**Framework:** VORP Core (RedM)
**Version:** 1.0.0

A modular RedM resource that combines **three stages** in one NUI:
1. **Spawn Selector** (visual cards)
2. **Server Rules** (must be accepted)
3. **Whitelist Quiz** (random questions, timer, mistake tolerance, Discord role)

The whole process runs **only once** on first connect / character creation — never again on later logins, thanks to DB tracking. Optional features include automatic Discord role assignment, webhook logging, ban-on-fail, and per-spawn job assignment.

---

## 📚 Documentation

Full documentation is in the [`docs/`](docs/) folder:

### 🇬🇧 English

- 📦 [Installation](docs/en/installation.md) — requirements, install, first start
- ⚙️ [Configuration](docs/en/configuration.md) — every option explained
- 📍 [Spawn Points](docs/en/spawn-points.md) — add / customize spawns
- 🤖 [Discord Setup](docs/en/discord-setup.md) — bot for role check / assignment
- 📨 [Webhooks](docs/en/webhooks.md) — log channels
- 🔧 [Troubleshooting](docs/en/troubleshooting.md) — common issues and fixes

### 🇩🇪 Deutsch

- 📦 [Installation](docs/de/installation.md) — Voraussetzungen, Install, erster Start
- ⚙️ [Konfiguration](docs/de/configuration.md) — jede Option erklärt
- 📍 [Spawn-Punkte](docs/de/spawn-points.md) — Spawns hinzufügen / anpassen
- 🤖 [Discord-Setup](docs/de/discord-setup.md) — Bot für Rollen-Check / -Vergabe
- 📨 [Webhooks](docs/de/webhooks.md) — Log-Channels
- 🔧 [Fehlerdiagnose](docs/de/troubleshooting.md) — häufige Probleme und Lösungen

---

## 🚀 Quick Start

```cfg
# In server.cfg
ensure J0K3R-whitelist_spawnselector
set discord_token "YOUR_BOT_TOKEN"   # only required for Discord features
```

```sql
-- In your VORP database
SOURCE J0K3R-whitelist_spawnselector/sql/install.sql;
```

Tweak `config.lua` to taste, restart, done. Full guide → [docs/en/installation.md](docs/en/installation.md)

---

## ✨ Features

| Feature | Toggle | Description |
|---------|--------|-------------|
| 🎴 Visual spawn selector | `Config.EnableSpawnSelector` | Card-based UI for picking starting location |
| 📜 Server rules | `Config.EnableRules` | Scroll-to-bottom acceptance flow |
| 📝 Whitelist quiz | `Config.EnableQuiz` | Random questions from a configurable pool |
| ⏱️ Quiz timer | `Config.EnableQuizTimer` | Countdown with anti-cheat server-side validation |
| 🚫 Temp-ban on fail | `Config.EnableTempBanOnFail` | vorp_admin-compatible ban via `users` table |
| 🤖 Discord role check | `Config.EnableDiscordRoleCheck` | Skip quiz for already-whitelisted players |
| 🎖️ Auto role assignment | `Config.EnableDiscordRoleAssignment` | Grant role after passing |
| 💼 Job assignment | `Config.EnableJobAssignment` | Optional, with per-spawn override |
| 📨 Webhook logs | `Config.Webhooks.*` | Spawn / quiz / ban logs to Discord |
| 🌍 Localization | `Config.Locale` | English + German included, easy to add more |
| 📐 Responsive UI | (built-in) | Scales fluently from 1080p to 4K |

---

## 📁 File Structure

```
J0K3R-whitelist_spawnselector/
├── fxmanifest.lua
├── config.lua          ← all settings
├── locale.lua          ← UI translations
├── shared.lua          ← helpers
├── client/main.lua     ← NUI control, character hooks
├── server/
│   ├── main.lua        ← logic, DB, rewards, webhooks
│   └── discord.lua     ← Discord API
├── sql/install.sql
├── ui/
│   ├── index.html
│   ├── style.css       ← responsive (1080p/1440p/4K)
│   ├── script.js
│   ├── img/            ← spawn cards & background
│   └── fonts/
└── docs/
    ├── en/             ← English docs
    └── de/             ← German docs
```

---

