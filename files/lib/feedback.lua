--[[
-- ImGui "Feedback" widget
--
-- Example usage:
--    local fb = Feedback:init(imgui)
--    fb:add("this is a string")
--    fb:addf("this is a %s", "string")
--    fb:add({"this text is red", color="red'})
--    fb:add({"this text is red-ish", color={0.8, 0.2, 0.2}})
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
--        Add a line below existing lines; see below for format
--    fb:addf(format_string, format_args...)
--        Add a formatted line below existing lines
--    fb:prepend(line)
--        Insert a line above existing lines; see below for format
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
--        {r:num, g:num, b:num}         RGB color with values between [0,1]
--        "name"                        name of predefined color
--    line.image = string               optional image path drawn before text
--    line.fallback_image = string      image to draw if line.image fails
--    line.image_width = number         optional; forces width in pixels
--    line.image_height = number        optional; forces height in pixels
--    line.hover_text = string          text displayed if the line is hovered
--    line.hover_wrap = number or 400   text wrap length; defaults to 400
--    line.wrap = number                if given, text will be wrapped
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
        lightred = {1, 0.5, 0.5},
        green_light = {0.5, 1, 0.5},
        lightgreen = {0.5, 1, 0.5},
        blue_light = {0.5, 0.5, 1},
        lightblue = {0.5, 0.5, 1},
        cyan_light = {0.5, 1, 1},
        lightcyan = {0.5, 1, 1},
        magenta_light = {1, 0.5, 1},
        lightmagenta = {1, 0.5, 1},
        yellow_light = {1, 1, 0.5},
        lightyellow = {1, 1, 0.5},
        gray = {0.5, 0.5, 0.5},
        gray_light = {0.75, 0.75, 0.75},
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

    -- Add a debugging line at the end
    debug = function(self, line)
        self:add({debug=true, line})
    end,

    -- Add a formatted debugging line at the end
    debugf = function(self, line, ...)
        self:add({debug=true, line:format(...)})
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
                color[1] or color.r or 0,
                color[2] or color.g or 0,
                color[3] or color.b or 0,
            }
        end
    end,

    -- Draw a single line; public for convenience
    draw_line = function(self, line, parent)
        local imgui = self._imgui
        if type(line) == "string" then
            if parent and parent.wrap then
                imgui.PushTextWrapPos(parent.wrap)
            end
            imgui.Text(line)
            if parent and parent.wrap then
                imgui.PopTextWrapPos()
            end
            if parent and parent.hover_text and imgui.IsItemHovered() then
                local wrap = parent.hover_wrap or 400
                if imgui.BeginTooltip() then
                    imgui.PushTextWrapPos(wrap)
                    if type(parent.hover_text) == "string" then
                        imgui.Text(parent.hover_text)
                    elseif type(parent.hover_text) == "table" then
                        self:draw_line(parent.hover_text, parent)
                    end
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                end
            end
        elseif type(line) == "table" then
            if line.clear then
                imgui.NewLine()
            end
            if not line.debug or self._config.debug then
                local color = self:get_color(line.color)
                if color and self._config.color then
                    imgui.PushStyleColor(imgui.Col.Text, unpack(color))
                end
                if line.image and self._config.images then
                    local img = imgui.LoadImage(line.image)
                    if not img and line.fallback_image then
                        img = imgui.LoadImage(line.fallback_image)
                    end
                    if img then
                        local width = line.image_width or img.width
                        local height = line.image_height or img.height
                        imgui.Image(img, width, height)
                        if line.hover_text and imgui.IsItemHovered() then
                            local wrap = line.hover_wrap or 400
                            if imgui.BeginTooltip() then
                                imgui.PushTextWrapPos(wrap)
                                if type(line.hover_text) == "string" then
                                    imgui.Text(line.hover_text)
                                elseif type(line.hover_text) == "table" then
                                    self:draw_line(line.hover_text, line)
                                end
                                imgui.PopTextWrapPos()
                                imgui.EndTooltip()
                            end
                        end
                        imgui.SameLine()
                    end
                end
                for idx, part in ipairs(line) do
                    if idx > 1 then imgui.SameLine() end
                    self:draw_line(part, line)
                end
                if color and self._config.color then
                    imgui.PopStyleColor()
                end
            end
        elseif line ~= nil then
            imgui.Text(tostring(line))
        end
    end,

    -- Draw the box of text
    draw_box = function(self)
        if self._config.debug then
            self:draw_line({
                {color="red", "Red"},
                {color="green", "Green"},
                {color="blue", "Blue"},
                {
                    image="data/ui_gfx/items/moon.png",
                    hover_text="This is a moon",
                    color="lightblue",
                    "$item_moon",
                }
            })
        end
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
