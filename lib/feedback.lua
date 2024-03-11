--[[
-- ImGui "Feedback" widget
--
-- Example usage:
--    local fb = Feedback:init(imgui)
--    fb:add("this is a string")
--    fb:addf("this is a %s", "string")
--    fb:prependf("below are %d lines", fb:count())
--    fb:draw()
--
-- API:
--    fb = Feedback:init(imgui)
--        Instantiate and initialize an instance
--    fb:clear()
--        Clear all lines from the box
--    fb:add(line)
--        Add a line below existing lines
--    fb:addf(format_string, format_args...)
--        Add a formatted line below existing lines
--    fb:prepend(line)
--        Insert a line above existing lines
--    fb:prependf(format_string, format_args...)
--        Insert a formatted line above existing lines
--    count = fb:count()
--        Get the number of lines inside the box
--    fb:draw_button()
--        Draw the "Clear" button
--    fb:draw_box()
--        Draw the text box with all of its contents
--    fb:draw()
--        Calls self:draw_button() and self:draw_box()
--]]

Feedback = {

    -- The lines table, public for convenience
    lines = {},

    -- Create and return a new instance
    init = function(self, imgui)
        self._imgui = imgui
        return self
    end,

    -- Clear all existing lines
    clear = function(self)
        self.lines = {}
    end,

    -- Add a line at the end
    add = function(self, line)
        table.insert(self.lines, line)
    end,

    -- Add a formatted line at the end
    addf = function(self, line, ...)
        self:add(line:format(...))
    end,

    -- Insert a line at the beginning
    prepend = function(self, line)
        table.insert(self.lines, 1, line)
    end,

    -- Insert a formatted line at the beginning
    prependf = function(self, line, ...)
        self:prepend(line:format(...))
    end,

    -- Return the number of lines
    count = function(self)
        return #self.lines
    end,

    -- Draw the "Clear" button
    draw_button = function(self)
        if self._imgui.Button("Clear") then
            self:clear()
        end
    end,

    -- Draw the box of text
    draw_box = function(self)
        for _, line in ipairs(self.lines) do
            if type(line) == "string" then
                self._imgui.Text(line)
            elseif type(line) == "table" then
                self._imgui.Text(line[1]) -- TODO: font
            end
        end
    end,

    -- Draw both the button and the box
    draw = function(self)
        self:draw_button()
        self:draw_box()
    end
}

return Feedback

-- vim: set ts=4 sts=4 sw=4:
