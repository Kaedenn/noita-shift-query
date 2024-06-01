--[[ Standalone reimplementation of GameTextGet ]]

I18N = {
    entries = {},
    by_key = {},
    lang_id = 1,
    lang_name = "en",
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

    local lang = "en"
    local lang_name = GameTextGet("$current_language")
    for colidx, entry in ipairs(by_key["current_language"]) do
        if entry == lang_name then
            self.lang_id = colidx
            self.lang_name = by_key[""][colidx]
            break
        end
    end

    self.entries = lines
    self.by_key = by_key

    local curr_lang = self:get("current_language")
    assert(curr_lang == self.lang_name, ("current_language %q not %q"):format(curr_lang, self.lang_name))
end

function I18N:get(key, default)
    local row = self.by_key[key]
    if not row or #row < self.lang_id then
        return default
    end
    return row[self.lang_id]
end

return I18N

-- vim: set ts=4 sts=4 sw=4:
