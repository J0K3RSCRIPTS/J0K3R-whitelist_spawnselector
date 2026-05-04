--[[
    shared.lua - helper functions
    Author: J0K3R-SCRIPTS
]]

---Looks up a localized string from locale.lua.
---Supports printf-style formatting: LANG("kick_quiz_failed", 30)
---@param key string
---@vararg any
---@return string
function LANG(key, ...)
    local pack = Locales[Config.Locale] or Locales["en"]
    local str  = pack[key]
    if not str then
        return ("[MISSING_LOCALE:%s]"):format(key)
    end
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then return formatted end
    end
    return str
end

---Shuffles a Lua table in-place style (returns a copy, Fisher-Yates).
---@param t table
---@return table
function ShuffleTable(t)
    local copy = {}
    for i, v in ipairs(t) do copy[i] = v end
    for i = #copy, 2, -1 do
        local j = math.random(i)
        copy[i], copy[j] = copy[j], copy[i]
    end
    return copy
end

---Picks N random entries from a table (returns a new table).
---@param t table
---@param n integer
---@return table
function PickRandom(t, n)
    local shuffled = ShuffleTable(t)
    local out = {}
    for i = 1, math.min(n, #shuffled) do
        out[i] = shuffled[i]
    end
    return out
end
