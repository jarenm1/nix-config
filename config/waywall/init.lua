local waywall = require("waywall")
local helpers = require("waywall.helpers")

local keyboard = require("keyboard")
local mirrors = require("mirrors")
local ninb = require("ninb")
local util = require("util")

local config = {
    input = {
        repeat_rate = 50,
        repeat_delay = 180,

        sensitivity = 4.8,
        confine_pointer = true,
    },
    theme = {
        background = "#2d0707",
        ninb_anchor = "right",
        ninb_opacity = 0.8,
    },
    shaders = {
        ["f3"] = {
            fragment = util.read_file("f3.frag"),
        },
        ["pie_chart"] = {
            fragment = util.read_file("pie_chart.frag"),
        },
    },

    experimental = {
        jit = true,
        tearing = false,
    }
}

local resolutions = { --            width    height  sens    ingame  blockf3
    thin            = util.make_res(320,     900,    0,      true,   true),
    eye             = util.make_res(320,     16384,  0.1,    false,  false),
    tall            = util.make_res(320,     16384,  0,      true,   false),
    wide            = util.make_res(1880,    320,    0,      true,   false),
}

config.actions = {
    -- Resolutions
    ["*-T"]             = resolutions.thin,
    ["*-G"]             = resolutions.eye,
    ["*-Ctrl-G"]        = resolutions.tall,
    ["*-V"]             = resolutions.wide,

    -- Ninjabrain Bot
    ["Ctrl-Shift-N"]    = ninb.exec,
    ["*-H"]             = ninb.toggle,
    ["*-comma"]         = ninb.decrement,
    ["*-less"]          = ninb.decrement,
    ["*-period"]        = ninb.increment,
    ["*-greater"]       = ninb.increment,
}

for key, func in pairs(config.actions) do
    config.actions[key] = function()
        return keyboard.do_keybinds() and func() or false
    end
end

config.actions["*-F11"] = keyboard.toggle_layout

return config
