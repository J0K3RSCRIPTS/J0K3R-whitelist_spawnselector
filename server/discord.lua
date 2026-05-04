--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║   J0K3R-whitelist_spawnselector - DISCORD                        ║
    ║   Author: J0K3R-SCRIPTS                                          ║
    ║                                                                  ║
    ║   Discord API integration:                                       ║
    ║     - Check role  (Discord_HasWhitelistRole)                     ║
    ║     - Assign role (Discord_AssignWhitelistRole)                  ║
    ║                                                                  ║
    ║   Bot token is read from a server convar:                        ║
    ║       set discord_token "..."                                    ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

local DISCORD_API = "https://discord.com/api/v10"

local function getToken()
    return GetConvar(Config.Discord.TokenConvarName or "discord_token", "")
end

local function getDiscordId(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == "discord:" then
            return id:sub(9)
        end
    end
    return nil
end

local function explainStatus(status, response)
    if status == 200 or status == 204 then
        return "OK"
    elseif status == 401 then
        return "401 Unauthorized - bot token is missing or invalid"
    elseif status == 403 then
        return "403 Forbidden - bot lacks 'Manage Roles' or its role is below the target role in the hierarchy"
    elseif status == 404 then
        return "404 Not Found - guild ID, role ID, or member not found (player not in the Discord server?)"
    elseif status == 429 then
        return "429 Rate Limited - too many requests, Discord is throttling us"
    elseif status == 0 then
        return "0 No response - check internet connection or 'Server Members Intent' in Discord Dev Portal"
    else
        local snippet = (response or ""):sub(1, 200)
        return ("HTTP %s - %s"):format(tostring(status), snippet)
    end
end

local function discordRequest(method, endpoint, body, cb)
    local token = getToken()
    if token == "" then
        print("^1[J0K3R-whitelist][discord] MISSING: discord_token convar is not set in server.cfg.^7")
        cb(0, "no_token"); return
    end

    PerformHttpRequest(DISCORD_API .. endpoint, function(status, responseText, headers)
        cb(status or 0, responseText or "")
    end, method, body and json.encode(body) or "", {
        ["Content-Type"]  = "application/json",
        ["Authorization"] = "Bot " .. token,
    })
end

function Discord_HasWhitelistRole(src, cb)
    local discordId = getDiscordId(src)
    if not discordId then
        if Config.Debug then print("[J0K3R-whitelist][discord] Player has no discord: identifier") end
        cb(false); return
    end

    local guildId = Config.Discord.GuildId
    local roleId  = Config.Discord.WhitelistedRoleId
    if not guildId or guildId == "" or not roleId or roleId == "" then
        if Config.Debug then print("[J0K3R-whitelist][discord] GuildId or WhitelistedRoleId not configured") end
        cb(false); return
    end

    local endpoint = ("/guilds/%s/members/%s"):format(guildId, discordId)
    discordRequest("GET", endpoint, nil, function(status, response)
        if status ~= 200 then
            print(("^3[J0K3R-whitelist][discord] HasRole check failed: %s^7"):format(explainStatus(status, response)))
            cb(false); return
        end
        local ok, data = pcall(json.decode, response)
        if not ok or type(data) ~= "table" or type(data.roles) ~= "table" then
            cb(false); return
        end
        for _, r in ipairs(data.roles) do
            if r == roleId then
                if Config.Debug then print(("[J0K3R-whitelist][discord] Player %s has whitelist role"):format(discordId)) end
                cb(true); return
            end
        end
        if Config.Debug then print(("[J0K3R-whitelist][discord] Player %s does NOT have whitelist role"):format(discordId)) end
        cb(false)
    end)
end

function Discord_AssignWhitelistRole(src)
    local discordId = getDiscordId(src)
    if not discordId then
        print(("^3[J0K3R-whitelist][discord] Cannot assign role: player %s has no discord: identifier^7"):format(src))
        return
    end

    local guildId  = Config.Discord.GuildId
    local addRole  = Config.Discord.AssignRoleAfterPass
    local rmRole   = Config.Discord.RemoveRoleAfterPass

    if not guildId or guildId == "" then
        print("^3[J0K3R-whitelist][discord] Cannot assign role: GuildId not configured^7")
        return
    end

    if addRole and addRole ~= "" then
        local ep = ("/guilds/%s/members/%s/roles/%s"):format(guildId, discordId, addRole)
        discordRequest("PUT", ep, nil, function(status, response)
            if status == 204 then
                print(("^2[J0K3R-whitelist][discord] ✅ Role assigned to %s (role=%s)^7"):format(discordId, addRole))
            else
                print(("^1[J0K3R-whitelist][discord] ❌ FAILED to assign role: %s^7"):format(explainStatus(status, response)))
                print(("^1[J0K3R-whitelist][discord]    -> guild=%s, member=%s, role=%s^7"):format(guildId, discordId, addRole))
            end
        end)
    end

    if rmRole and rmRole ~= "" then
        local ep = ("/guilds/%s/members/%s/roles/%s"):format(guildId, discordId, rmRole)
        discordRequest("DELETE", ep, nil, function(status, response)
            if status == 204 then
                print(("^2[J0K3R-whitelist][discord] ✅ Role removed from %s (role=%s)^7"):format(discordId, rmRole))
            else
                print(("^3[J0K3R-whitelist][discord] WARN: could not remove role: %s^7"):format(explainStatus(status, response)))
            end
        end)
    end
end
