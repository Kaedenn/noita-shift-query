--[[
-- ImGui "Feedback" widget
--
-- Example usage:
--    local fb = Feedback:init(imgui)
--    fb:add("this is a string")
--    fb:addf("this is a %s", "string")
--    fb:add({"this text is red", color="red'})
--    fb:add({"this text has an image", image="data/materials_gfx/fungi.png"})
--    fb:prependf("below are %d lines", fb:count())
--    fb:draw()
--
--    fb:draw_box() -- Draw without the Clear button
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
--    fb:configure("color", true|false)
--        Enable or disable colors (default is enabled)
--    fb:configure("debug", true|false)
--        Enable or disable debugging (default is disabled)
--    fb:configure("images", true|false)
--        Enable or disable display of images (default is enabled)
--
-- Lines are either strings or tables with the following structure
--    line[idx] = string                one or more words
--    line.color = one of
--        Feedback.colors.<name>        predefined color
--        "name"                        name of predefined color
--        {number, number, number}      custom RGB color
--    line.image = string               optional image path
-- Lines can be nested recursively as so
fb:add({
   {"This", color="red"},           -- red
   "line",                          -- white
   {
     "has",                         -- red
     {"multiple", color="green"},   -- green
     "different",                   -- red
     color="red",
   },
   {"colors", color={0.75, 0.75, 1}} -- lightblue
})
--]]

Feedback = {

    colors = {
        -- Pure colors
        red = {1, 0, 0},
        green = {0, 1, 0},
        blue = {0, 0, 1},
        cyan = {0, 1, 1},
        magenta = {1, 0, 1},
        yellow = {1, 1, 0},
        white = {1, 1, 1},
        black = {0, 0, 0},

        -- Blended colors
        red_light = {1, 0.5, 0.5},
        green_light = {0.5, 1, 0.5},
        blue_light = {0.5, 0.5, 1},
        cyan_light = {0.5, 1, 1},
        magenta_light = {1, 0.5, 1},
        yellow_light = {1, 1, 0.5},
        gray = {0.5, 0.5, 0.5},
        lightgray = {0.75, 0.75, 0.75},
    },

    -- The lines table, public for convenience
    lines = {},

    -- The configuration table, private to encourage self:configure
    _config = {
        color = true,
        images = true,
        debug = false,
    },

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

    -- Convert a given color to a real color
    get_color = function(self, color)
        if self._config.colors == false then return nil end
        if color == nil then return nil end
        if type(color) == "string" then
            if self.colors[color] then
                return self.colors[color]
            end
        end
        if type(color) == "table" then
            return {
                color[1] or 0,
                color[2] or 0,
                color[3] or 0
            }
        end
    end,

    -- Draw a single line; public for convenience
    draw_line = function(self, line)
        if type(line) == "string" then
            self._imgui.Text(line)
        elseif type(line) == "table" then
            local color = self:get_color(line.color)
            if color and self._config.color then
                self._imgui.PushStyleColor(self._imgui.Col.Text, unpack(color))
            end
            if line.image and self._config.images then
                local img = self._imgui.LoadImage(line.image)
                if img then
                    self._imgui.Image(img, img.width, img.height)
                    self._imgui.SameLine()
                end
            end
            for idx, part in ipairs(line) do
                if idx > 1 then self._imgui.SameLine() end
                self:draw_line(part)
            end
            if color and self._config.color then
                self._imgui.PopStyleColor()
            end
        elseif line ~= nil then
            self._imgui.Text(tostring(line))
        end
    end,

    -- Draw the box of text
    draw_box = function(self)
        for _, line in ipairs(self.lines) do
            self:draw_line(line)
        end
    end,

    -- Draw both the button and the box
    draw = function(self)
        self:draw_button()
        self:draw_box()
    end,

    -- Apply configuration
    configure = function(self, option, value)
        if self._config[option] ~= nil then
            self._config[option] = value
        end
    end,
}

return Feedback

-- vim: set ts=4 sts=4 sw=4:
