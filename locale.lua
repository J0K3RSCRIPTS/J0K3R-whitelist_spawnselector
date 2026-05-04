--[[
    locale.lua - translation system
    Author: J0K3R-SCRIPTS

    The active language is set in config.lua via Config.Locale ("en" / "de").
    Add additional languages by adding a new Locales[<code>] block below.
    Every string can be customized 1:1.
]]

Locales = {}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                              ENGLISH                             │
-- └──────────────────────────────────────────────────────────────────┘
Locales["en"] = {
    -- General
    notify_title              = "Whitelist System",

    -- Spawn selector
    spawn_select_title        = "Choose your spawn",
    spawn_select_subtitle     = "Where shall your new life begin?",
    spawn_select_btn          = "Select",
    spawn_starting_money      = "Starting money",
    spawn_starting_items      = "Starting items",

    -- Rules
    rules_title               = "Server Rules",
    rules_subtitle            = "Please read the rules carefully.",
    rules_accept_btn          = "I have read and accept the rules",
    rules_must_scroll         = "Please scroll to the bottom to accept.",

    -- Quiz
    quiz_title                = "Whitelist Test",
    quiz_subtitle             = "Answer the following questions to gain server access.",
    quiz_question_progress    = "Question %s of %s",
    quiz_mistakes_left        = "Mistakes allowed: %s",
    quiz_time_left            = "Time left: %s",
    quiz_next_btn             = "Next question",
    quiz_submit_btn           = "Finish test",

    quiz_passed_title         = "Passed!",
    quiz_passed_subtitle      = "Welcome to the server! You will be spawned now.",
    quiz_failed_title         = "Failed",
    quiz_failed_subtitle      = "You did not pass the test. Read the rules and try again.",
    quiz_time_up              = "Time's up! Test failed.",

    -- Notifications
    notify_received_items     = "You received your starting items and money.",
    notify_already_completed  = "You have already completed the whitelist test.",
    notify_discord_role_found = "Existing whitelist role detected - skipping quiz.",

    -- Kick / Ban
    kick_quiz_failed          = "You failed the whitelist test. You can try again in %s minutes.",
    kick_quiz_failed_no_ban   = "You failed the whitelist test. Please re-read the rules.",
    kick_no_discord           = "Discord must be connected to join this server.",

    -- Loading screen
    loading_title             = "RedM Roleplay",
    loading_subtitle          = "Spawning...",
    loading_description       = "Join our Discord: discord.gg/your-server",
}

-- ┌──────────────────────────────────────────────────────────────────┐
-- │                              GERMAN                              │
-- └──────────────────────────────────────────────────────────────────┘
Locales["de"] = {
    notify_title              = "Whitelist System",

    spawn_select_title        = "Wähle deinen Spawn",
    spawn_select_subtitle     = "Wo soll dein neues Leben beginnen?",
    spawn_select_btn          = "Auswählen",
    spawn_starting_money      = "Startgeld",
    spawn_starting_items      = "Start-Items",

    rules_title               = "Server-Regelwerk",
    rules_subtitle            = "Bitte lies die Regeln aufmerksam durch.",
    rules_accept_btn          = "Ich habe die Regeln gelesen und akzeptiere sie",
    rules_must_scroll         = "Bitte scrolle bis zum Ende, um zu akzeptieren.",

    quiz_title                = "Whitelist-Prüfung",
    quiz_subtitle             = "Beantworte die folgenden Fragen, um Zugang zum Server zu erhalten.",
    quiz_question_progress    = "Frage %s von %s",
    quiz_mistakes_left        = "Erlaubte Fehler: %s",
    quiz_time_left            = "Verbleibende Zeit: %s",
    quiz_next_btn             = "Nächste Frage",
    quiz_submit_btn           = "Test abschließen",

    quiz_passed_title         = "Bestanden!",
    quiz_passed_subtitle      = "Willkommen auf dem Server! Du wirst jetzt gespawnt.",
    quiz_failed_title         = "Nicht bestanden",
    quiz_failed_subtitle      = "Du hast den Test leider nicht bestanden. Lies die Regeln nochmal und versuche es erneut.",
    quiz_time_up              = "Zeit abgelaufen! Test fehlgeschlagen.",

    notify_received_items     = "Du hast deine Start-Items und dein Startgeld erhalten.",
    notify_already_completed  = "Du hast die Whitelist-Prüfung bereits absolviert.",
    notify_discord_role_found = "Bestehende Whitelist-Rolle erkannt - Quiz wird übersprungen.",

    kick_quiz_failed          = "Du hast die Whitelist-Prüfung nicht bestanden. Du kannst es in %s Minuten erneut versuchen.",
    kick_quiz_failed_no_ban   = "Du hast die Whitelist-Prüfung nicht bestanden. Bitte lies die Regeln nochmal.",
    kick_no_discord           = "Discord muss aktiv verbunden sein, um diesen Server zu betreten.",

    loading_title             = "RedM Roleplay",
    loading_subtitle          = "Spawnen...",
    loading_description       = "Tritt unserem Discord bei: discord.gg/dein-server",
}
