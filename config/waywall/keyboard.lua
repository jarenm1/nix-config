local waywall = require("waywall")

local status_text = nil
local hotkeys_enabled = true

local M = {}

M.do_keybinds = function()
    return hotkeys_enabled
end

M.toggle_layout = function()
    hotkeys_enabled = not hotkeys_enabled

    if status_text then
        status_text:close()
        status_text = nil
    end

    if not hotkeys_enabled then
        status_text = waywall.text("typing", {
            x = 10,
            y = 960,
            color = "#ee4444",
            size = 5,
        })
    end
end

return M
