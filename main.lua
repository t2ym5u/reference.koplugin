local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = _dir .. "?.lua;" .. _dir .. "common/?.lua;" .. package.path

local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local PluginBase = require("plugin_base")
local _          = require("i18n")

require("i18n").extend(lrequire("i18n_fr"))
local ReferenceScreen = lrequire("screen")

-- Quick reference: periodic table, alphabets, Morse, number tables and a
-- ruler. Listed directly in the Tools menu (category "tools").
local Reference = PluginBase:extend{
    name      = "reference",
    menu_text = _("Quick reference"),
    menu_hint = "tools",
}

function Reference:createScreen()
    return ReferenceScreen:new{ plugin = self }
end

-- A utility, not a game: its own entry in the Tools menu, as Dashboard,
-- Plugin Manager and Book Drop have, rather than a place under Tools →
-- Games (PluginBase's default).
function Reference:addToMainMenu(menu_items)
    menu_items.reference = {
        text         = self.menu_text,
        sorting_hint = "tools",
        callback     = function() self:showGame() end,
    }
end

return Reference
