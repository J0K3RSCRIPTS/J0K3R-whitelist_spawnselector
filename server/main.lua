--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║   J0K3R-whitelist_spawnselector - SERVER                         ║
    ║   Author: J0K3R-SCRIPTS                                          ║
    ╚══════════════════════════════════════════════════════════════════╝

    Server-side responsibilities:
        - Check whitelist status from DB (respects CharacterPolicy)
        - Pick the quiz questions server-side (correct answers stay here!)
        - Validate the submitted quiz (anti-cheat)
        - Hand out items / currency / job
        - Check / assign Discord roles (see discord.lua)
        - Send spawn / ban / quiz logs to Discord webhooks
]]

local VORPCore      = exports.vorp_core:GetCore()
local VORPInventory = exports.vorp_inventory:vorp_inventoryApi()

local pendingQuiz = {}

local function dbg(...)
    if Config.Debug then
        print("[J0K3R-whitelist][server] " .. table.concat({...}, " "))
    end
end

local function getPrimaryIdentifier(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == "license:" then
            return id
        end
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 6) == "steam:" then
            return id
        end
    end
    return GetPlayerIdentifier(src, 0)
end

local function getIdentifierByPrefix(src, prefix)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, #prefix) == prefix then
            return id:sub(#prefix + 1)
        end
    end
    return nil
end

local function collectIdentifiers(src)
    return {
        steam   = getIdentifierByPrefix(src, "steam:"),
        license = getIdentifierByPrefix(src, "license:"),
        discord = getIdentifierByPrefix(src, "discord:"),
        ip      = getIdentifierByPrefix(src, "ip:"),
    }
end

local function postWebhook(url, payload)
    if not url or url == "" then return end
    PerformHttpRequest(url, function(status, body, headers)
        if Config.Debug and status ~= 200 and status ~= 204 then
            print(("[J0K3R-whitelist][webhook] HTTP %s -> %s"):format(tostring(status), tostring(body)))
        end
    end, "POST", json.encode(payload), { ["Content-Type"] = "application/json" })
end

local function fmtItems(items)
    if type(items) ~= "table" or #items == 0 then return "—" end
    local parts = {}
    for _, it in ipairs(items) do
        parts[#parts + 1] = ("`%s` × %d"):format(it.name, it.amount)
    end
    return table.concat(parts, ", ")
end

local function fmtCurrency(currency)
    if type(currency) ~= "table" then return "—" end
    local parts = {}
    if currency.money and currency.money > 0 then parts[#parts + 1] = ("$%s"):format(currency.money)      end
    if currency.gold  and currency.gold  > 0 then parts[#parts + 1] = ("%s Gold"):format(currency.gold)   end
    if currency.rol   and currency.rol   > 0 then parts[#parts + 1] = ("%s RoL"):format(currency.rol)     end
    if #parts == 0 then return "—" end
    return table.concat(parts, " · ")
end

local function logSpawnEvent(src, character, spawnKey)
    if not Config.Webhooks or not Config.Webhooks.EnableSpawnLog then return end
    local url = Config.Webhooks.SpawnLogUrl
    if not url or url == "" then return end

    local spawn = Config.Spawns[spawnKey] or {}
    local ids   = collectIdentifiers(src)
    local cfg   = Config.Webhooks
    local color = (cfg.Colors and cfg.Colors.Spawn) or 0x3e7c47

    local fields = {}
    fields[#fields + 1] = { name = "Player",       value = ("`%s` (ID: %d)"):format(GetPlayerName(src) or "?", src), inline = false }

    if cfg.Fields == nil or cfg.Fields.Identifiers ~= false then
        fields[#fields + 1] = { name = "Steam",    value = "`" .. (ids.steam   or "n/a") .. "`", inline = true }
        fields[#fields + 1] = { name = "License",  value = "`" .. (ids.license or "n/a") .. "`", inline = true }
        fields[#fields + 1] = { name = "Discord",  value = ids.discord and ("<@" .. ids.discord .. ">") or "n/a", inline = true }
    end

    if cfg.Fields == nil or cfg.Fields.Character ~= false then
        local charName = ((character.firstname or "") .. " " .. (character.lastname or "")):gsub("^%s+", ""):gsub("%s+$", "")
        if charName == "" then charName = "(no name)" end
        fields[#fields + 1] = { name = "Character",      value = charName,                                    inline = true }
        fields[#fields + 1] = { name = "Char ID",        value = tostring(character.charIdentifier or "?"),   inline = true }
        fields[#fields + 1] = { name = "Sex / Age",      value = ("%s / %s"):format(tostring(character.sex or character.gender or "?"), tostring(character.age or "?")), inline = true }
    end

    if cfg.Fields == nil or cfg.Fields.Spawn ~= false then
        fields[#fields + 1] = { name = "Spawn",      value = ("**%s**\n%s"):format(spawn.title or spawnKey, spawn.description or ""),  inline = false }
        if spawn.coords then
            fields[#fields + 1] = { name = "Coords", value = ("`%.2f, %.2f, %.2f` (h %.1f)"):format(spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.coords.w), inline = false }
        end
    end

    if cfg.Fields == nil or cfg.Fields.Rewards ~= false then
        fields[#fields + 1] = { name = "Items",    value = fmtItems(spawn.items),       inline = false }
        fields[#fields + 1] = { name = "Currency", value = fmtCurrency(spawn.currency), inline = false }
        if spawn.job then
            local assigned = (spawn.enableJob == true) or (spawn.enableJob == nil and Config.EnableJobAssignment == true)
            fields[#fields + 1] = { name = "Job", value = ("%s (grade %s) %s"):format(
                spawn.job.name or "?",
                tostring(spawn.job.grade or 0),
                assigned and "✅ assigned" or "⏭️ skipped"), inline = false }
        end
    end

    postWebhook(url, {
        username   = cfg.Username    or "J0K3R Whitelist",
        avatar_url = cfg.AvatarUrl   or nil,
        embeds = {{
            title       = "🟢 Player spawned",
            description = "A player has completed the whitelist process and spawned.",
            color       = color,
            fields      = fields,
            timestamp   = os.date("!%Y-%m-%dT%H:%M:%S", os.time()) .. "Z",
            footer      = { text = "J0K3R-whitelist_spawnselector" },
        }},
    })
end

local function logQuizFailed(src, character, mistakes, total, timeUp, banned, banMinutes)
    if not Config.Webhooks or not Config.Webhooks.EnableQuizLog then return end
    local url = Config.Webhooks.QuizLogUrl or Config.Webhooks.SpawnLogUrl
    if not url or url == "" then return end

    local cfg   = Config.Webhooks
    local color = (cfg.Colors and cfg.Colors.QuizFailed) or 0x8b1a1a
    local ids   = collectIdentifiers(src)

    local desc
    if timeUp then
        desc = "Quiz time expired."
    elseif banned then
        desc = ("Player failed the quiz and was temp-banned for **%d minutes**."):format(banMinutes or 0)
    else
        desc = "Player failed the quiz (no ban applied)."
    end

    postWebhook(url, {
        username   = cfg.Username  or "J0K3R Whitelist",
        avatar_url = cfg.AvatarUrl or nil,
        embeds = {{
            title       = "🔴 Quiz failed",
            description = desc,
            color       = color,
            fields = {
                { name = "Player",     value = ("`%s` (ID: %d)"):format(GetPlayerName(src) or "?", src),    inline = false },
                { name = "Steam",      value = "`" .. (ids.steam or "n/a") .. "`",                         inline = true  },
                { name = "Discord",    value = ids.discord and ("<@" .. ids.discord .. ">") or "n/a",      inline = true  },
                { name = "Character",  value = (((character.firstname or "") .. " " .. (character.lastname or "")):gsub("^%s+", ""):gsub("%s+$", "")), inline = true },
                { name = "Result",     value = ("**%d / %d** correct"):format(total - mistakes, total),    inline = false },
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S", os.time()) .. "Z",
            footer    = { text = "J0K3R-whitelist_spawnselector" },
        }},
    })
end

local function logBanEvent(src, identifier, reason, durationMinutes, untilTs)
    local url = (Config.Webhooks and Config.Webhooks.BanLogUrl) or Config.BanWebhook
    if not url or url == "" then return end

    local cfg   = Config.Webhooks or {}
    local color = (cfg.Colors and cfg.Colors.Ban) or 0x8b1a1a

    postWebhook(url, {
        username   = cfg.Username  or "J0K3R Whitelist",
        avatar_url = cfg.AvatarUrl or nil,
        embeds = {{
            title       = "⛔ Player banned",
            description = reason,
            color       = color,
            fields = {
                { name = "Identifier", value = "`" .. tostring(identifier) .. "`",        inline = false },
                { name = "Player",     value = ("`%s` (ID: %d)"):format(GetPlayerName(src) or "?", src), inline = true },
                { name = "Duration",   value = ("%d min"):format(durationMinutes),        inline = true  },
                { name = "Until",      value = os.date("%Y-%m-%d %H:%M:%S", untilTs),     inline = true  },
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S", os.time()) .. "Z",
            footer    = { text = "J0K3R-whitelist_spawnselector" },
        }},
    })
end

local function isWhitelisted(src, charIdentifier)
    local identifier = getPrimaryIdentifier(src)
    local row

    if Config.CharacterPolicy == "perchar" then
        row = MySQL.single.await(
            "SELECT passed, chosen_spawn FROM j0k3r_whitelist WHERE identifier = ? AND charidentifier = ? AND passed = 1 LIMIT 1",
            { identifier, charIdentifier }
        )
    else
        row = MySQL.single.await(
            "SELECT passed, chosen_spawn FROM j0k3r_whitelist WHERE identifier = ? AND passed = 1 LIMIT 1",
            { identifier }
        )
    end

    if row and row.passed == 1 then
        return true, row.chosen_spawn
    end
    return false, nil
end

local function markWhitelisted(src, charIdentifier, spawnKey)
    local identifier = getPrimaryIdentifier(src)
    local charId = (Config.CharacterPolicy == "perchar") and charIdentifier or 0

    MySQL.insert.await([[
        INSERT INTO j0k3r_whitelist (identifier, charidentifier, passed, chosen_spawn, passed_at)
        VALUES (?, ?, 1, ?, NOW())
        ON DUPLICATE KEY UPDATE passed = 1, chosen_spawn = VALUES(chosen_spawn), passed_at = NOW()
    ]], { identifier, charId, spawnKey })
end

local function shouldAssignJob(spawn)
    if not spawn.job then return false end
    if spawn.enableJob ~= nil then
        return spawn.enableJob == true
    end
    return Config.EnableJobAssignment == true
end

local function giveSpawnRewards(src, spawnKey)
    local spawn = Config.Spawns[spawnKey]
    if not spawn then return false end

    local user = VORPCore.getUser(src)
    if not user then return false end
    local character = user.getUsedCharacter
    if not character then return false end

    if type(spawn.items) == "table" then
        for _, it in ipairs(spawn.items) do
            local can = true
            if VORPInventory.canCarryItem then
                can = VORPInventory.canCarryItem(src, it.name, it.amount)
            end
            if can then
                VORPInventory.addItem(src, it.name, it.amount)
            else
                dbg(("Player %s cannot carry item %s x%d"):format(src, it.name, it.amount))
            end
        end
    end

    if type(spawn.currency) == "table" then
        local map = { money = 0, gold = 1, rol = 2 }
        for cur, amount in pairs(spawn.currency) do
            if map[cur] and amount and amount > 0 then
                character.addCurrency(map[cur], amount)
            end
        end
    end

    if shouldAssignJob(spawn) then
        if spawn.job.name  then character.setJob(spawn.job.name)         end
        if spawn.job.grade then character.setJobGrade(spawn.job.grade)   end
        if spawn.job.label then character.setJobLabel(spawn.job.label)   end
        dbg(("Job assigned: %s (grade %s) to player %s"):format(
            spawn.job.name or "?", tostring(spawn.job.grade), src))
    else
        dbg(("Job assignment skipped for player %s (spawn=%s)"):format(src, spawnKey))
    end

    if Config.SaveSpawnAsDefaultSpawn then
        local ok, err = pcall(function()
            if character.updateCharPos then
                character.updateCharPos({
                    x = spawn.coords.x,
                    y = spawn.coords.y,
                    z = spawn.coords.z,
                    heading = spawn.coords.w,
                })
            end
        end)
        if not ok then
            dbg("updateCharPos failed: " .. tostring(err))
        end
    end

    logSpawnEvent(src, character, spawnKey)

    return true
end

local function applyTempBan(src, identifier, reason, durationMinutes)
    local untilTs = os.time() + (durationMinutes * 60)

    if Config.BanProvider ~= "vorp_admin" then
        logBanEvent(src, identifier, reason, durationMinutes, untilTs)
        DropPlayer(src, reason)
        return
    end

    local affected = MySQL.update.await(
        "UPDATE users SET banned = 1, banneduntil = ? WHERE identifier = ?",
        { untilTs, identifier }
    )

    if (not affected) or affected == 0 then
        print(("^3[J0K3R-whitelist] WARN: Could not update users table (identifier=%s). Falling back to drop only.^7"):format(identifier))
    elseif Config.Debug then
        print(("[J0K3R-whitelist] Ban applied: %s until %s (%d min)"):format(identifier, os.date("%c", untilTs), durationMinutes))
    end

    logBanEvent(src, identifier, reason, durationMinutes, untilTs)

    DropPlayer(src, reason)
end

local function kickAsRevalidationFail(src, reason)
    local msg = Config.RevalidationKickMessage or "You are no longer whitelisted on this server."
    print(("^3[J0K3R-whitelist] Player %s revalidation failed (%s) -> kicking^7"):format(src, reason))
    DropPlayer(src, msg)
end

RegisterServerEvent("J0K3R-whitelist:RequestStatus", function(isNewChar)
    local src = source
    local user = VORPCore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end

    local passed = isWhitelisted(src, character.charIdentifier)

    if Config.EnableDiscordRoleCheck then
        Discord_HasWhitelistRole(src, function(hasRole)
            if hasRole then
                if not passed then
                    dbg(("Player %s has whitelist role - marking as passed"):format(src))
                    markWhitelisted(src, character.charIdentifier, nil)
                    TriggerClientEvent("vorp:NotifyLeft", src,
                        LANG("notify_title"), LANG("notify_discord_role_found"),
                        "generic_textures", "star", 4000)
                else
                    dbg(("Player %s already whitelisted (role + DB) - skipped"):format(src))
                end
                TriggerClientEvent("J0K3R-whitelist:WhitelistOk", src)
                return
            end

            if Config.EnableConnectRevalidation and passed and not isNewChar then
                kickAsRevalidationFail(src, "lost whitelist role")
                return
            end

            if passed then
                dbg(("Player %s whitelisted via DB (no role check enforced) - skipped"):format(src))
                TriggerClientEvent("J0K3R-whitelist:WhitelistOk", src)
                return
            end

            if isNewChar or Config.CharacterPolicy == "perchar" then
                TriggerClientEvent("J0K3R-whitelist:StartProcess", src)
                return
            end

            if Config.EnableConnectRevalidation then
                kickAsRevalidationFail(src, "no DB entry, no role")
                return
            end

            TriggerClientEvent("J0K3R-whitelist:WhitelistOk", src)
        end)
        return
    end

    if passed then
        dbg(("Player %s already whitelisted - process skipped"):format(src))
        TriggerClientEvent("J0K3R-whitelist:WhitelistOk", src)
        return
    end

    if isNewChar or Config.CharacterPolicy == "perchar" then
        TriggerClientEvent("J0K3R-whitelist:StartProcess", src)
        return
    end

    if Config.EnableConnectRevalidation then
        kickAsRevalidationFail(src, "no DB entry (Discord check disabled)")
        return
    end

    TriggerClientEvent("J0K3R-whitelist:WhitelistOk", src)
end)

RegisterServerEvent("J0K3R-whitelist:RequestQuestions", function()
    local src = source

    local picked = PickRandom(Config.Questions, Config.QuizQuestionsPerTest)

    local clientPayload = {}
    local serverState   = {}

    for i, q in ipairs(picked) do
        local order = {}
        for idx = 1, #q.answers do order[idx] = idx end
        if Config.ShuffleAnswers then
            order = ShuffleTable(order)
        end

        local shuffledAnswers = {}
        local newCorrectIdx   = nil
        for newIdx, oldIdx in ipairs(order) do
            shuffledAnswers[newIdx] = q.answers[oldIdx]
            if oldIdx == q.correct then
                newCorrectIdx = newIdx
            end
        end

        clientPayload[i] = { question = q.question, answers = shuffledAnswers }
        serverState[i]   = { correct  = newCorrectIdx }
    end

    pendingQuiz[src] = {
        questions = serverState,
        startTime = os.time(),
    }

    TriggerClientEvent("J0K3R-whitelist:DeliverQuestions", src, clientPayload)
end)

RegisterServerEvent("J0K3R-whitelist:SubmitQuiz", function(payload)
    local src = source
    local state = pendingQuiz[src]
    if not state then return end
    pendingQuiz[src] = nil

    local user = VORPCore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end

    local mistakes = 0
    local total    = #state.questions

    if Config.EnableQuizTimer then
        local elapsed = os.time() - state.startTime
        if elapsed > (Config.QuizTimeSeconds + 5) then
            payload.timeUp = true
        end
    end

    if payload.timeUp then
        mistakes = total
    else
        for i, q in ipairs(state.questions) do
            local given = tonumber(payload.answers[tostring(i)] or payload.answers[i])
            if given ~= q.correct then
                mistakes = mistakes + 1
            end
        end
    end

    local passed = (mistakes <= Config.MaxMistakesAllowed) and not payload.timeUp

    TriggerClientEvent("J0K3R-whitelist:QuizResult", src, {
        passed   = passed,
        mistakes = mistakes,
        total    = total,
        timeUp   = payload.timeUp == true,
    })

    if passed then
        markWhitelisted(src, character.charIdentifier, payload.spawn)
        giveSpawnRewards(src, payload.spawn)
        TriggerClientEvent("J0K3R-whitelist:DoSpawn", src, payload.spawn)

        if Config.EnableDiscordRoleAssignment then
            Discord_AssignWhitelistRole(src)
        end
    else
        if Config.EnableTempBanOnFail then
            local minutes    = Config.TempBanMinutes
            local reason     = LANG("kick_quiz_failed", minutes)
            local identifier = getPrimaryIdentifier(src)
            logQuizFailed(src, character, mistakes, total, payload.timeUp == true, true, minutes)
            applyTempBan(src, identifier, reason, minutes)
        else
            logQuizFailed(src, character, mistakes, total, payload.timeUp == true, false, 0)
            DropPlayer(src, LANG("kick_quiz_failed_no_ban"))
        end
    end
end)

RegisterServerEvent("J0K3R-whitelist:CompleteAll", function(data)
    local src = source
    local user = VORPCore.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end

    if data.spawn then
        giveSpawnRewards(src, data.spawn)
        TriggerClientEvent("J0K3R-whitelist:DoSpawn", src, data.spawn)
    end

    markWhitelisted(src, character.charIdentifier, data.spawn)

    if Config.EnableDiscordRoleAssignment then
        Discord_AssignWhitelistRole(src)
    end
end)

AddEventHandler("playerDropped", function()
    pendingQuiz[source] = nil
end)

local SCRIPT_VERSION  = "1.0.0"
local SCRIPT_NAME     = "J0K3R-whitelist_spawnselector"
local SCRIPT_AUTHOR   = "J0K3R-Scripts"
local DISCORD_INVITE  = "https://discord.gg/DH8tW6vSxV"

local function printStartupBanner()
    print("^3+----------------------------------------------------+^7")
    print("^3|^7   J0K3R-whitelist_spawnselector by J0K3R-Scripts   ^3|^7")
    print(("^3|^7   Discord: %s           ^3|^7"):format(DISCORD_INVITE))
    print("^3|^7   Free script, contributions welcome               ^3|^7")
    print("^3+----------------------------------------------------+^7")
    print(("^2[%s]^7 loaded v%s  ^5•^7  framework: ^6vorp_core^7  ^5•^7  locale: ^6%s^7  ^5•^7  jobs: ^6%s^7  ^5•^7  policy: ^6%s^7"):format(
        SCRIPT_NAME,
        SCRIPT_VERSION,
        Config.Locale or "en",
        tostring(Config.EnableJobAssignment),
        Config.CharacterPolicy or "first"))
end

AddEventHandler("onResourceStart", function(resource)
    if resource ~= GetCurrentResourceName() then return end

    printStartupBanner()

    local check = MySQL.scalar.await(
        "SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'j0k3r_whitelist' LIMIT 1"
    )
    if not check then
        print("^1[J0K3R-whitelist_spawnselector] WARNING: Table 'j0k3r_whitelist' is missing! Please import sql/install.sql.^7")
    end
end)
