--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║   J0K3R-whitelist_spawnselector - CONFIG                         ║
    ║   Author: J0K3R-SCRIPTS                                          ║
    ║                                                                  ║
    ║   Every feature can be toggled on/off individually.              ║
    ║   Adding new spawn points is as simple as copying a block in     ║
    ║   Config.Spawns - see the TEMPLATE example at the bottom of     ║
    ║   the spawn list.                                                ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

Config = {}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                       GENERAL SETTINGS                           │
-- └──────────────────────────────────────────────────────────────────┘
Config.Debug                       = true   -- Debug mode (enables /spawnselector command + console logs)
Config.Locale                      = "en"   -- UI language: "en" or "de" (see locale.lua to add more)

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        FEATURE TOGGLES                           │
-- │   Set any of these to false to disable that feature entirely.    │
-- └──────────────────────────────────────────────────────────────────┘
Config.EnableSpawnSelector         = true   -- Visual spawn selector (NUI cards)
Config.EnableRules                 = true   -- Show server rules with accept-button
Config.EnableQuiz                  = false   -- Run the whitelist quiz
Config.EnableQuizTimer             = false   -- Countdown timer during the quiz
Config.EnableTempBanOnFail         = false  -- Apply a temporary ban when the quiz is failed
Config.EnableDiscordRoleCheck      = true   -- Check Discord role to skip the quiz for already-whitelisted players
Config.EnableDiscordRoleAssignment = true   -- After passing, assign/remove configured Discord roles

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                  RE-VALIDATION ON CONNECT                        │
-- │                                                                  │
-- │   When TRUE, the script re-validates EVERY player on every       │
-- │   connect - not just on first character creation:                │
-- │                                                                  │
-- │   - Checks if the player is in the DB as passed=1                │
-- │   - If EnableDiscordRoleCheck is also on: requires the role too  │
-- │   - If neither -> player is kicked from the server               │
-- │                                                                  │
-- │   Useful for:                                                    │
-- │     - Catching players whose Discord role was removed            │
-- │     - Banning Discord-server-evaders automatically               │
-- │     - Enforcing whitelist integrity over time                    │
-- │                                                                  │
-- │   When FALSE (default), only new character creations trigger     │
-- │   the whitelist check - a backwards-compatible behavior.         │
-- └──────────────────────────────────────────────────────────────────┘
Config.EnableConnectRevalidation   = false
Config.RevalidationKickMessage     = "You are no longer whitelisted on this server. Please contact staff."

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                    JOB / GROUP ASSIGNMENT                        │
-- │                                                                  │
-- │   Globally controls whether VORP `job`/`jobgrade`/`joblabel`     │
-- │   are written when the player spawns.                            │
-- │                                                                  │
-- │   Set to FALSE if you have a separate job system (vorp_jobs,     │
-- │   custom job menus, etc.) and don't want this script to touch    │
-- │   the player's job at all.                                       │
-- │                                                                  │
-- │   Per-spawn override: each spawn entry below can set             │
-- │   `enableJob = true|false` to override this global value for     │
-- │   that one spawn (see TEMPLATE example).                         │
-- └──────────────────────────────────────────────────────────────────┘
Config.EnableJobAssignment         = false  -- false = NEVER assign jobs, even if a `job` block exists in a spawn

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     SPAWN COORDINATE SAVING                      │
-- │                                                                  │
-- │   When true, the chosen spawn is saved as the character's        │
-- │   default spawn coordinates. On future logins the player will    │
-- │   spawn there instead of the VORP default location.              │
-- │   (Wrapped in pcall so it won't break if the VORP version        │
-- │    doesn't expose updateCharPos.)                                │
-- └──────────────────────────────────────────────────────────────────┘
Config.SaveSpawnAsDefaultSpawn     = true

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                      CHARACTER POLICY                            │
-- │                                                                  │
-- │   "first"     -> Run the whitelist process ONCE per account.     │
-- │                  Once any character has passed, the whole        │
-- │                  account is considered whitelisted.              │
-- │   "perchar"   -> Each new character has to pick a spawn and      │
-- │                  (optionally) take the quiz again.               │
-- │   "perplayer" -> Same effect as "first" - kept for clarity.      │
-- └──────────────────────────────────────────────────────────────────┘
Config.CharacterPolicy             = "first"

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                        QUIZ SETTINGS                             │
-- └──────────────────────────────────────────────────────────────────┘
Config.QuizQuestionsPerTest        = 5      -- How many questions are randomly drawn from the pool
Config.MaxMistakesAllowed          = 1      -- Allowed wrong answers (0 = strict, 2 = lenient)
Config.QuizTimeSeconds             = 180    -- Total countdown in seconds
Config.TempBanMinutes              = 30     -- Ban duration in minutes when quiz is failed
Config.ShuffleAnswers              = true   -- Randomize the order of answers per question

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                       BAN PROVIDER                               │
-- │                                                                  │
-- │   "vorp_admin"  -> Updates `users.banned` and `users.banneduntil`│
-- │                    (compatible with vorp_admin & VORP Core).     │
-- │   "drop_only"   -> Just DropPlayer, no DB entry (good for tests  │
-- │                    or when using a custom ban manager).          │
-- │                                                                  │
-- │   Any unknown value falls back to "drop_only" for safety.        │
-- └──────────────────────────────────────────────────────────────────┘
Config.BanProvider                 = "drop_only"

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                     DISCORD WEBHOOK LOGS                         │
-- │                                                                  │
-- │   Send Discord embeds for various events. Each log type can be   │
-- │   enabled/disabled individually and uses its own webhook URL.    │
-- │   You can also point all of them at the same webhook URL if you  │
-- │   want a single log channel.                                     │
-- │                                                                  │
-- │   How to get a webhook URL:                                      │
-- │     Discord -> Channel Settings -> Integrations -> Webhooks ->   │
-- │     New Webhook -> Copy URL                                      │
-- └──────────────────────────────────────────────────────────────────┘
Config.Webhooks = {
    EnableSpawnLog     = false,   -- Log every successful spawn (Steam, character, location, items, money)
    EnableQuizLog      = false,   -- Log every failed quiz attempt
    EnableBanLog       = false,   -- Log every ban that this resource issues

    SpawnLogUrl        = "",      -- Webhook URL for spawn logs
    QuizLogUrl         = "",      -- Webhook URL for quiz failures (falls back to SpawnLogUrl if empty)
    BanLogUrl          = "",      -- Webhook URL for bans (falls back to SpawnLogUrl if empty)

    -- Visual customization for the embeds
    Username           = "J0K3R Whitelist",   -- Bot name shown next to the message
    AvatarUrl          = "",                   -- Optional avatar image URL ("" = Discord default)
    Colors = {
        Spawn      = 0x3e7c47,   -- green
        QuizFailed = 0x8b1a1a,   -- dark red
        Ban        = 0x8b1a1a,   -- dark red
    },

    -- Per-field toggles for the spawn log embed (set any to false to omit)
    Fields = {
        Identifiers = true,   -- Steam / License / Discord
        Character   = true,   -- Char name, char ID, sex, age
        Spawn       = true,   -- Spawn title, description, coords
        Rewards     = true,   -- Items, currency, job
    },
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                       DISCORD SETTINGS                           │
-- │   IMPORTANT: Set the bot token in your server.cfg, never here!   │
-- │       set discord_token "YOUR_BOT_TOKEN"                         │
-- └──────────────────────────────────────────────────────────────────┘
Config.Discord = {
    GuildId               = "YOUR_GUILD_ID_HERE",
    -- Role a player has when they're already whitelisted (skips the quiz when EnableDiscordRoleCheck = true)
    WhitelistedRoleId     = "YOUR_WHITELIST_ROLE_ID",
    -- Role to assign after passing (when EnableDiscordRoleAssignment = true)
    AssignRoleAfterPass   = "YOUR_WHITELIST_ROLE_ID",
    -- Role to remove after passing (e.g. a "Guest" role). Leave as "" to skip.
    RemoveRoleAfterPass   = "",
    -- Token is read from the convar with this name: GetConvar("discord_token", "")
    TokenConvarName       = "discord_token",
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                      DESIGN / NUI LOOK                           │
-- │   These values are sent to the NUI as CSS variables.             │
-- └──────────────────────────────────────────────────────────────────┘
Config.Design = {
    PrimaryColor      = "#c9a559",   -- Gold tone (accent color, buttons, highlights)
    SecondaryColor    = "#8b1a1a",   -- Dark red (errors, warnings)
    SuccessColor      = "#3e7c47",   -- Green (correct answer, passed)
    BackgroundColor   = "#1a0f08",   -- Dark wood-brown
    TextColor         = "#f4e8d0",   -- Parchment cream
    Opacity           = 0.92,        -- Background opacity (0.0 - 1.0)
    BorderColor       = "#c9a559",
    -- Fonts (loaded locally from ui/fonts/)
    FontHeader        = "RDR Lino",
    FontBody          = "HapnaSlabSerif",
    -- Background image path (relative to ui/)
    BackgroundImage   = "img/background.webp",
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                          SPAWN POINTS                            │
-- │                                                                  │
-- │   Every entry = one card in the NUI. To add a new spawn, just    │
-- │   copy one of the existing blocks and adjust the values.         │
-- │                                                                  │
-- │   Required fields:                                               │
-- │     image       - path relative to ui/ (e.g. "img/myspawn.webp") │
-- │     title       - card heading                                   │
-- │     description - card subtitle text                             │
-- │     coords      - vector4(x, y, z, heading)                      │
-- │                                                                  │
-- │   Optional fields:                                               │
-- │     items       - list of items granted on spawn                 │
-- │     currency    - money/gold/rol granted on spawn                │
-- │     job         - VORP job to assign (only used if job           │
-- │                   assignment is enabled, see EnableJobAssignment)│
-- │     enableJob   - per-spawn override of EnableJobAssignment      │
-- │                   (true = force assign, false = force skip,     │
-- │                    nil = use the global setting)                 │
-- └──────────────────────────────────────────────────────────────────┘
Config.Spawns = {

    ["VALENTINE"] = {
        image       = "img/valentinespawn.webp",
        title       = "Valentine",
        description = "A bustling town in the heart of New Hanover. Perfect for honest citizens and traders.",
        coords      = vector4(-174.7543, 622.2214, 114.0320, 236.2449),
        items = {
            { name = "lumberjack_axe", label = "Holzfäller-Axt", amount = 5 },
            { name = "lumberjack_shovel", label = "Schaufel", amount = 2 },
        },
        currency = {
            money = 500,   -- Dollars
            gold  = 0,     -- Gold bars
            rol   = 0,     -- Roll (XP)
        },
        -- Job is optional. If EnableJobAssignment = false (global), this is ignored.
        job = { name = "citizen", grade = 0, label = "Citizen" },
    },

    ["SAINT_DENIS"] = {
        image       = "img/stdenisspawn.webp",
        title       = "Saint Denis",
        description = "The grand city in the south. Industry, trade and high society - but also dark alleyways.",
        coords      = vector4(2717.4844, -1435.7614, 46.1713, 26.0210),
        items = {
            { name = "bread", label = "Bread", amount = 3 },
            { name = "cigar", label = "Cigar", amount = 2 },
        },
        currency = {
            money = 500,
            gold  = 0,
            rol   = 0,
        },
        job = { name = "citizen", grade = 0, label = "Citizen" },
    },

    ["NATIVE"] = {
        image       = "img/nativespawn.webp",
        title       = "Wapiti Reservation",
        description = "Live in harmony with nature. Hunt, gather and preserve the heritage of your ancestors.",
        coords      = vector4(444.3624, 2227.8206, 248.0215, 306.3837),
        items = {
            { name = "bread", label = "Bread",  amount = 3 },
            { name = "bow",   label = "Bow",    amount = 1 },
            { name = "arrow", label = "Arrows", amount = 20 },
        },
        currency = {
            money = 500,
            gold  = 0,
            rol   = 0,
        },
        job = { name = "native", grade = 0, label = "Native" },
    },

    ["CRIMINAL"] = {
        image       = "img/crimespawn.webp",
        title       = "Outlaw / Criminal",
        description = "Live the life outside the law. High risk, high reward - the frontier rewards the bold.",
        coords      = vector4(-3840.4954, -3013.6477, -7.0355, 227.5337),
        items = {
            { name = "bread",    label = "Bread",    amount = 2 },
            { name = "lockpick", label = "Lockpick", amount = 1 },
        },
        currency = {
            money = 500,
            gold  = 0,
            rol   = 0,
        },
        job = { name = "criminal", grade = 0, label = "Outlaw" },
    },

    -- ╔══════════════════════════════════════════════════════════════╗
    -- ║   TEMPLATE - copy this block and rename the key to add a    ║
    -- ║   new spawn. Remove the leading "--[[" and trailing "]]" to ║
    -- ║   activate it.                                               ║
    -- ╚══════════════════════════════════════════════════════════════╝
    --[[
    ["MY_NEW_SPAWN"] = {                              -- unique key (UPPERCASE recommended)
        image       = "img/myspawn.webp",             -- place file in ui/img/
        title       = "My New Spawn",
        description = "Short text shown on the spawn card.",
        coords      = vector4(0.0, 0.0, 0.0, 0.0),    -- x, y, z, heading
        items = {
            { name = "bread", label = "Bread", amount = 5 },   -- name = DB id, label = pretty name shown in NUI
        },
        currency = {
            money = 100,
            gold  = 0,
            rol   = 0,
        },
        -- Optional: job assignment for THIS spawn only.
        -- Remove this whole `job` block if you don't want a job assigned.
        job        = { name = "myjob", grade = 0, label = "My Job" },
        -- Optional: override Config.EnableJobAssignment for this spawn.
        -- true  = always assign job here, even if global flag is false
        -- false = never assign job here, even if global flag is true
        -- nil   = use the global Config.EnableJobAssignment value
        enableJob  = nil,
    },
    ]]
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                          SERVER RULES                            │
-- │   Shown when EnableRules = true. Add or remove blocks freely.    │
-- └──────────────────────────────────────────────────────────────────┘
Config.Rules = {
    {
        title = "§1 - General Conduct",
        text  = "Treat all players with respect. Insults, racism and sexism lead to an immediate ban.",
    },
    {
        title = "§2 - Roleplay Obligation",
        text  = "Stay in character at all times. Out-of-character communication belongs in the appropriate channel.",
    },
    {
        title = "§3 - Combat Logout / RDM / VDM",
        text  = "Random Deathmatch (RDM) and Vehicle Deathmatch (VDM) are forbidden. Combat logout results in a ban.",
    },
    {
        title = "§4 - Powergaming & Metagaming",
        text  = "Power-gaming (unrealistic actions) and metagaming (using OOC info IC) are strictly forbidden.",
    },
    {
        title = "§5 - Bug-Using & Exploits",
        text  = "Any bug must be reported to an admin immediately. Actively exploiting bugs leads to a permanent ban.",
    },
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                         QUIZ QUESTIONS                           │
-- │                                                                  │
-- │   `correct` is the 1-based index of the correct answer.          │
-- │   The list of `answers` will be shuffled at runtime if           │
-- │   Config.ShuffleAnswers = true (the server keeps track of the    │
-- │   actual correct index per request).                             │
-- │                                                                  │
-- │   Out of this pool, Config.QuizQuestionsPerTest questions are    │
-- │   drawn randomly per quiz attempt. The pool can be as large as   │
-- │   you want.                                                      │
-- └──────────────────────────────────────────────────────────────────┘
Config.Questions = {
    {
        question = "What does RDM stand for?",
        answers  = {
            "Random Deathmatch",        -- correct
            "Real Death Mode",
            "Roleplay Death Match",
            "Random Drop Mode",
        },
        correct  = 1,
    },
    {
        question = "What is powergaming?",
        answers  = {
            "Being very active in the game",
            "Unrealistic actions that disadvantage other players", -- correct
            "Playing with high FPS",
            "Founding your own gang",
        },
        correct  = 2,
    },
    {
        question = "How do you behave when you find a bug?",
        answers  = {
            "I exploit it before it gets patched",
            "I share it with friends",
            "I report it to an admin immediately",  -- correct
            "I just ignore it",
        },
        correct  = 3,
    },
    {
        question = "What does staying 'in character' (IC) mean?",
        answers  = {
            "I can break character at any time",
            "I always speak as my character, never as the player", -- correct
            "I always stay logged in",
            "I stay inside a specific area",
        },
        correct  = 2,
    },
    {
        question = "Are you allowed to use information from Discord or streams in-game?",
        answers  = {
            "Yes, always",
            "Only if the other player allows it",
            "No, that would be metagaming",  -- correct
            "Only during major events",
        },
        correct  = 3,
    },
    {
        question = "What do you do if your character is in a life-threatening RP situation?",
        answers  = {
            "Log out immediately to avoid dying",
            "My character reacts appropriately to the threat", -- correct
            "Activate cheats",
            "Insult the other player",
        },
        correct  = 2,
    },
    {
        question = "Combat logout means:",
        answers  = {
            "Logging out during/right after combat to avoid consequences", -- correct
            "Dying in a fight",
            "Logging out of a combat game",
            "Leaving because the server is unstable",
        },
        correct  = 1,
    },
    {
        question = "How should your first character be designed?",
        answers  = {
            "Like a famous movie villain",
            "Original, with their own background and realistic behavior", -- correct
            "Exactly like a friend's character",
            "Doesn't matter, as long as they have lots of items",
        },
        correct  = 2,
    },
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │   AUTHOR:   J0K3R-SCRIPTS                                        │
-- └──────────────────────────────────────────────────────────────────┘
