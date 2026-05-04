--[[
    Resource:   J0K3R-whitelist_spawnselector
    Author:     J0K3R-SCRIPTS
    Framework:  VORP Core (RedM)
    Version:    1.0.0
    Description:
        Modular whitelist + spawn selector + rules + quiz system.
        Triggered ONCE on first character creation.
]]

game            "rdr3"
fx_version      "adamant"
rdr3_warning    "I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships."
lua54           "yes"

author          "J0K3R-SCRIPTS"
description     "Whitelist + Spawn Selector + Rules + Quiz (VORP Core)"
version         "1.0.0"

ui_page "ui/index.html"

files {
    "ui/index.html",
    "ui/style.css",
    "ui/script.js",
    "ui/img/*",
    "ui/fonts/*",
}

shared_scripts {
    "config.lua",
    "locale.lua",
    "shared.lua",
}

client_scripts {
    "client/main.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "server/main.lua",
    "server/discord.lua",
}

dependencies {
    "vorp_core",
    "vorp_inventory",
    "oxmysql",
}

escrow_ignore {
    "config.lua",
    "locale.lua",
}
