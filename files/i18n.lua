--[[
-- Standalone reimplementation of GameTextGet.
--
-- This provides consistent translation lookups even if display strings change,
-- such as with fungal shifts.
--
-- Usage:
--
-- I18N = dofile("mods/mymod/files/i18n.lua")
-- function OnBiomeConfigLoaded()
--      I18N:init()
--      print(I18N:get("animal_lukki"))
-- end
--]]

I18N = {
    entries = {},
    by_key = {},
    lang_id = 1,
    locale = "en",
}

local function split_csv(line)
    local cols = {}
    local start = 1
    local in_quote = false
    for curr = 1, #line do
        local ch = line:sub(curr, curr)
        if ch == '"' then
            in_quote = not in_quote
        elseif ch == ',' and not in_quote then
            table.insert(cols, line:sub(start, curr-1))
            start = curr + 1
        end
    end
    if start <= #line then
        table.insert(cols, line:sub(start))
    else
        table.insert(cols, "")
    end
    return cols
end

--[[ Initialize the language table. Call this in OnBiomeConfigLoaded ]]
function I18N:init()
    local text = ModTextFileGetContent("data/translations/common.csv")
    local lines = {}
    local by_key = {}
    for line in text:gmatch("[^\r\n]+") do
        local cols = split_csv(line)
        if #cols > 0 then
            local copy = {unpack(cols)}
            table.remove(copy, 1)
            table.insert(lines, cols)
            local key = cols[1]
            by_key[key] = copy
        end
        table.insert(lines, split_csv(line))
    end

    local lang_name = GameTextGet and GameTextGet("$current_language") or "English"
    for colidx, entry in ipairs(by_key["current_language"]) do
        if entry == lang_name then
            self.lang_id = colidx
            self.locale = by_key[""][colidx]
            break
        end
    end

    self.entries = lines
    self.by_key = by_key

    local lang_have = self:get("current_language")
    assert(lang_have == lang_name, ("current_language %q not %q"):format(lang_have, lang_name))

    q_write_log(("locale=%q, lang=%q, lang_id=%d"):format(self.locale, lang_have, self.lang_id))
end

--[[
-- Obtain the value of the given key.
--
-- If the key isn't found, then this function returns the default argument, if
-- given. If the default argument isn't specified, then this function falls
-- back to GameTextGet.
--]]
function I18N:get(key, default)
    local row = self.by_key[key:gsub("^%$", "")]
    if not row or #row < self.lang_id then
        if not default then
            return self:get_fallback(key)
        end
        return default
    end
    return row[self.lang_id]
end

--[[ We failed to get the value; try GameTextGet ]]
function I18N:get_fallback(key)
    local term = key
    if not term:find("/^%$/") then
        term = "$" .. term
    end
    return GameTextGet(term)
end

return I18N

-- vim: set ts=4 sts=4 sw=4:
