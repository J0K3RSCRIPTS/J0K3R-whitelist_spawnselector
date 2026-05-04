--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║   J0K3R-whitelist_spawnselector - CLIENT                         ║
    ║   Author: J0K3R-SCRIPTS                                          ║
    ╚══════════════════════════════════════════════════════════════════╝
]]

local VORPCore = exports.vorp_core:GetCore()

local LIMBO_X, LIMBO_Y, LIMBO_Z = 0.0, 0.0, 5000.0

local isUiOpen        = false
local pendingNewChar  = false
local localPlayerData = {}

local playerLocked    = false
local savedCoords     = nil
local savedHeading    = 0.0

local function dbg(...)
    if Config.Debug then
        print("[J0K3R-whitelist] " .. table.concat({...}, " "))
    end
end

local function notify(text)
    if VORPCore and VORPCore.NotifyRightTip then
        VORPCore.NotifyRightTip(text, 4000)
    else
        TriggerEvent("vorp:NotifyLeft", LANG("notify_title"), text, "generic_textures", "star", 4000)
    end
end

local function lockPlayerInPlace()
    if playerLocked then return end
    playerLocked = true
    DoScreenFadeOut(0)

    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        local pos = GetEntityCoords(ped)
        if pos and pos.x ~= 0.0 then
            savedCoords  = { x = pos.x, y = pos.y, z = pos.z }
            savedHeading = GetEntityHeading(ped) or 0.0
        end

        FreezeEntityPosition(ped, true)
        SetEntityVisible(ped, false, false)
        SetEntityCollision(ped, false, false)

        SetEntityCoords(ped, LIMBO_X, LIMBO_Y, LIMBO_Z, false, false, false, false)
    end

    Citizen.CreateThread(function()
        while playerLocked do
            local ped = PlayerPedId()
            if ped and ped ~= 0 then
                FreezeEntityPosition(ped, true)
                SetEntityVisible(ped, false, false)
                SetEntityCollision(ped, false, false)
                SetEntityInvincible(ped, true)
                SetEveryoneIgnorePlayer(PlayerId(), true)
                SetPlayerInvincible(PlayerId(), true)
            end
            Citizen.Wait(500)
        end
    end)
end

local function unlockPlayer()
    if not playerLocked then return end
    playerLocked = false
    local ped = PlayerPedId()
    if ped and ped ~= 0 then
        FreezeEntityPosition(ped, false)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)
        SetEveryoneIgnorePlayer(PlayerId(), false)
        SetPlayerInvincible(PlayerId(), false)
    end
end

local function teleportPlayerTo(x, y, z, heading)
    local ped = PlayerPedId()
    if not ped or ped == 0 then return end
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    SetEntityHeading(ped, heading or 0.0)
    Wait(500)
    local tries = 0
    while not HasCollisionLoadedAroundEntity(ped) and tries < 100 do
        Wait(50)
        tries = tries + 1
    end
end

local function openUi(stage)
    isUiOpen = true
    lockPlayerInPlace()
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "open",
        stage  = stage,
        config = {
            Design = Config.Design,
            Spawns = Config.Spawns,
            Rules  = Config.Rules,
            Locale = Locales[Config.Locale] or Locales["en"],
            Toggles = {
                EnableSpawnSelector = Config.EnableSpawnSelector,
                EnableRules         = Config.EnableRules,
                EnableQuiz          = Config.EnableQuiz,
                EnableQuizTimer     = Config.EnableQuizTimer,
            },
            Quiz = {
                TimeSeconds        = Config.QuizTimeSeconds,
                MaxMistakesAllowed = Config.MaxMistakesAllowed,
                QuestionsPerTest   = Config.QuizQuestionsPerTest,
            },
        },
    })
end

local function closeUi()
    isUiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

AddEventHandler("vorp:initNewCharacter", function()
    dbg("vorp:initNewCharacter triggered")
    pendingNewChar = true
end)

RegisterNetEvent("vorp:SelectedCharacter", function(charid)
    dbg("vorp:SelectedCharacter triggered, charid=", tostring(charid), "pendingNewChar=", tostring(pendingNewChar))

    if pendingNewChar or Config.CharacterPolicy == "perchar" then
        lockPlayerInPlace()
    end

    TriggerServerEvent("J0K3R-whitelist:RequestStatus", pendingNewChar)
    pendingNewChar = false
end)

RegisterNetEvent("J0K3R-whitelist:StartProcess", function(savedSpawn)
    dbg("StartProcess received, savedSpawn=", tostring(savedSpawn))
    local startStage = "spawn"
    if not Config.EnableSpawnSelector then
        startStage = Config.EnableRules and "rules" or (Config.EnableQuiz and "quiz" or nil)
    end

    if not startStage then
        TriggerServerEvent("J0K3R-whitelist:CompleteAll", { spawn = nil })
        return
    end

    openUi(startStage)
end)

RegisterNetEvent("J0K3R-whitelist:WhitelistOk", function()
    dbg("WhitelistOk received - releasing lock")
    if savedCoords then
        teleportPlayerTo(savedCoords.x, savedCoords.y, savedCoords.z, savedHeading)
        savedCoords = nil
    end
    unlockPlayer()
    DoScreenFadeIn(800)
end)

RegisterNetEvent("J0K3R-whitelist:DoSpawn", function(spawnKey)
    local spawn = Config.Spawns[spawnKey]
    if not spawn then return end

    DisplayLoadingScreens(0, 0, 0,
        LANG("loading_title"), LANG("loading_subtitle"), LANG("loading_description"))

    teleportPlayerTo(spawn.coords.x, spawn.coords.y, spawn.coords.z, spawn.coords.w)
    savedCoords = nil

    unlockPlayer()
    ShutdownLoadingScreen()
    Wait(300)
    DoScreenFadeIn(1000)

    notify(LANG("notify_received_items"))
end)

RegisterNetEvent("J0K3R-whitelist:ForceKick", function(reason)
    if isUiOpen then closeUi() end
end)

RegisterNUICallback("ui:ready", function(_, cb)
    cb({ ok = true })
end)

RegisterNUICallback("spawn:select", function(data, cb)
    local key = tostring(data.spawn or ""):upper()
    if not Config.Spawns[key] then
        cb({ ok = false }); return
    end
    localPlayerData.spawn = key

    if Config.EnableRules then
        cb({ ok = true, nextStage = "rules" })
    elseif Config.EnableQuiz then
        cb({ ok = true, nextStage = "quiz" })
    else
        cb({ ok = true, nextStage = "done" })
        TriggerServerEvent("J0K3R-whitelist:CompleteAll", { spawn = key })
        closeUi()
    end
end)

RegisterNUICallback("rules:accept", function(_, cb)
    if Config.EnableQuiz then
        TriggerServerEvent("J0K3R-whitelist:RequestQuestions")
        cb({ ok = true, nextStage = "quiz" })
    else
        cb({ ok = true, nextStage = "done" })
        TriggerServerEvent("J0K3R-whitelist:CompleteAll", { spawn = localPlayerData.spawn })
        closeUi()
    end
end)

RegisterNUICallback("quiz:request", function(_, cb)
    TriggerServerEvent("J0K3R-whitelist:RequestQuestions")
    cb({ ok = true })
end)

RegisterNetEvent("J0K3R-whitelist:DeliverQuestions", function(questions)
    SendNUIMessage({
        action    = "quiz:start",
        questions = questions,
    })
end)

RegisterNUICallback("quiz:submit", function(data, cb)
    TriggerServerEvent("J0K3R-whitelist:SubmitQuiz", {
        answers = data.answers or {},
        timeUp  = data.timeUp == true,
        spawn   = localPlayerData.spawn,
    })
    cb({ ok = true })
end)

RegisterNetEvent("J0K3R-whitelist:QuizResult", function(result)
    SendNUIMessage({
        action = "quiz:result",
        result = result,
    })

    if result.passed then
        Citizen.SetTimeout(2500, function()
            closeUi()
        end)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if isUiOpen then
            DisableControlAction(0, 0xD9D0E1C0, true)
        end
    end
end)

if Config.Debug then
    RegisterCommand("spawnselector", function()
        if isUiOpen then
            closeUi()
            if savedCoords then
                teleportPlayerTo(savedCoords.x, savedCoords.y, savedCoords.z, savedHeading)
                savedCoords = nil
            end
            unlockPlayer()
            DoScreenFadeIn(500)
        else
            local startStage = "spawn"
            if not Config.EnableSpawnSelector then
                startStage = Config.EnableRules and "rules" or (Config.EnableQuiz and "quiz" or "spawn")
            end
            openUi(startStage)
        end
    end, false)
    print("[J0K3R-whitelist] Debug command '/spawnselector' registered")
end
