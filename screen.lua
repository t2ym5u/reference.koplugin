local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local ButtonDialog   = require("ui/widget/buttondialog")
local Device         = require("device")
local Geom           = require("ui/geometry")
local GestureRange   = require("ui/gesturerange")
local InfoMessage    = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local InputDialog    = require("ui/widget/inputdialog")
local UIManager      = require("ui/uimanager")
local VerticalGroup  = require("ui/widget/verticalgroup")
local _              = require("i18n")

local ScreenBase = require("screen_base")
local Draw       = lrequire("draw")

local DeviceScreen = Device.screen

-- Sections, in tab order. Each view module is loaded the first time its
-- section opens, so the periodic table's data costs nothing until then.
local SECTIONS = {
    { id = "elements",  label = "Elements",  module = "view_elements"  },
    { id = "alphabets", label = "Alphabets", module = "view_alphabets" },
    { id = "morse",     label = "Morse",     module = "view_morse"     },
    { id = "tables",    label = "Tables",    module = "view_tables"    },
    { id = "ruler",     label = "Ruler",     module = "view_ruler"     },
}
local SECTION_BY_ID = {}
for _i, s in ipairs(SECTIONS) do SECTION_BY_ID[s.id] = s end

local MENU_LABELS = {
    elements  = "Periodic table",
    alphabets = "Radio & Greek alphabets",
    morse     = "Morse code",
    tables    = "Tables & SI prefixes",
    ruler     = "Ruler",
}

local HELP_EN = [[
Quick reference — handy tables at hand.

Elements: the periodic table of the 118 elements. Tap an element for its name, atomic mass, group, period and family. Each family has its own grey pattern (legend under or inside the table). In portrait, the buttons at the bottom zoom in on groups 1–9 or 10–18 (swipe left/right to switch).

Alphabets: the NATO/ICAO spelling alphabet, with a "Spell a word" button, and the Greek alphabet.

Morse: tap · and – to key in Morse, "Letter" between letters and "Word" between words; the text appears as you type. Tap a letter of the table to add its code. "Text → Morse" translates typed text.

Tables: multiplication tables (tap a number, or the full 12 × 12 grid), squares, cubes and powers of 2, SI prefixes.

Ruler: centimetres and inches drawn from the screen's DPI. To calibrate, lay a real ruler along the scale and adjust with − and + until the marks match, or measure the 10 cm span and enter it with "Measure". The setting is remembered.]]

local HELP_FR = [[
Aide-mémoire — des tables utiles sous la main.

Éléments : le tableau périodique des 118 éléments. Touchez un élément pour voir son nom, sa masse atomique, son groupe, sa période et sa famille. Chaque famille a son motif gris (légende sous le tableau ou dans le tableau). En portrait, les boutons du bas agrandissent les groupes 1 à 9 ou 10 à 18 (balayez à gauche ou à droite pour passer de l'un à l'autre).

Alphabets : l'alphabet radio OTAN/OACI, avec un bouton « Épeler un mot », et l'alphabet grec.

Morse : touchez · et – pour taper du Morse, « Lettre » entre deux lettres et « Mot » entre deux mots ; le texte s'affiche au fur et à mesure. Touchez une lettre du tableau pour ajouter son code. « Texte → Morse » traduit un texte saisi.

Tables : tables de multiplication (touchez un nombre, ou la grille complète 12 × 12), carrés, cubes et puissances de 2, préfixes SI.

Règle : centimètres et pouces tracés d'après la résolution (DPI) de l'écran. Pour l'étalonner, posez une vraie règle le long de la graduation et ajustez avec − et + jusqu'à ce que les traits coïncident, ou mesurez les 10 cm et saisissez la mesure avec « Mesurer ». Le réglage est mémorisé.]]

-- ---------------------------------------------------------------------------
-- Canvas -- the whole area under the title bar: the section tabs and the
-- current view, painted directly and hit-tested through a list of items.
-- ---------------------------------------------------------------------------

local Canvas = InputContainer:extend{
    width  = nil,
    height = nil,
    screen = nil,
}

function Canvas:init()
    self.dimen = Geom:new{ x = 0, y = 0, w = self.width, h = self.height }
    self.items = {}
    self.ges_events = {
        Tap   = { GestureRange:new{ ges = "tap",   range = function() return self.dimen end } },
        Hold  = { GestureRange:new{ ges = "hold",  range = function() return self.dimen end } },
        Swipe = { GestureRange:new{ ges = "swipe", range = function() return self.dimen end } },
    }
end

function Canvas:getSize()
    return Geom:new{ w = self.width, h = self.height }
end

function Canvas:paintTo(bb, x, y)
    self.dimen.x, self.dimen.y = x, y
    bb:paintRect(x, y, self.width, self.height, Draw.WHITE)
    for _i, it in ipairs(self.items) do
        if it.paint then it.paint(bb, x + it.x, y + it.y, it.w, it.h) end
    end
end

function Canvas:_hit(ges)
    local px, py = ges.pos.x - self.dimen.x, ges.pos.y - self.dimen.y
    for i = #self.items, 1, -1 do
        local it = self.items[i]
        if (it.tap or it.hold) and px >= it.x and px < it.x + it.w and py >= it.y and py < it.y + it.h then
            return it
        end
    end
end

function Canvas:onTap(_arg, ges)
    local it = self:_hit(ges)
    if it and it.tap then it.tap() end
    return true
end

function Canvas:onHold(_arg, ges)
    local it = self:_hit(ges)
    if it and (it.hold or it.tap) then (it.hold or it.tap)() end
    return true
end

function Canvas:onSwipe(_arg, ges)
    local dir = ges.direction
    if dir == "east" or dir == "west" or dir == "north" or dir == "south" then
        self.screen:onViewSwipe(dir)
    end
    return true
end

-- ---------------------------------------------------------------------------
-- ReferenceScreen
-- ---------------------------------------------------------------------------

local ReferenceScreen = ScreenBase:extend{}

function ReferenceScreen:init()
    local saved = self.plugin:getSetting("remember_section", true)
        and self.plugin:getSetting("section", "elements") or "elements"
    self.section = SECTION_BY_ID[saved] and saved or "elements"
    self.view_state = self.plugin:getSetting("view_state", {}) or {}
    self.views = {}
    ScreenBase.init(self)
end

function ReferenceScreen:lang()
    return _.lang()
end

function ReferenceScreen:buildLayout()
    self.dimen.w, self.dimen.h = DeviceScreen:getWidth(), DeviceScreen:getHeight()
    local title_bar = self:buildTitleBar(_("Quick reference"), function()
        local items = {}
        for _i, s in ipairs(SECTIONS) do
            local id = s.id
            items[#items + 1] = { text = (id == self.section and "✓ " or "") .. _(MENU_LABELS[id]),
                callback = function() self:switchSection(id) end }
        end
        items[#items + 1] = { text = _("Help"), callback = function()
            self:showRules(_.lang() == "fr" and HELP_FR or HELP_EN, { title = _("Help") })
        end }
        items[#items + 1] = { text = _("Settings"), callback = function() self:openSettings() end }
        return items
    end)
    self.title_bar = title_bar
    self.canvas = Canvas:new{
        width  = self.dimen.w,
        height = self.dimen.h - title_bar:getSize().h,
        screen = self,
    }
    self.layout = VerticalGroup:new{ align = "left", title_bar, self.canvas }
    self[1] = self.layout
    self:rebuild()
end

-- Height of a row of touch buttons: about 7 mm, never under 44 px.
function ReferenceScreen:buttonHeight()
    local short = math.min(self.dimen.w, self.dimen.h)
    return math.max(44, math.floor(short * 0.078))
end

function ReferenceScreen:getView(id)
    if not self.views[id] then
        self.views[id] = lrequire(SECTION_BY_ID[id].module)
    end
    return self.views[id]
end

function ReferenceScreen:stateOf(id)
    local st = self.view_state[id]
    if type(st) ~= "table" then
        st = {}
        self.view_state[id] = st
    end
    return st
end

function ReferenceScreen:saveViewState()
    self.plugin:saveSetting("view_state", self.view_state)
end

-- Rebuilds the item list of the canvas: tabs, then the current view.
function ReferenceScreen:rebuild()
    local canvas = self.canvas
    local W, H = canvas.width, canvas.height
    local items = {}
    canvas.items = items
    local function add(it) items[#items + 1] = it; return it end

    local gutter = math.floor(self:getGutter() / 2)
    local tab_h = self:buttonHeight()
    local n = #SECTIONS
    local tab_w = math.floor((W - 2 * gutter) / n)
    local tab_y = gutter
    for i, s in ipairs(SECTIONS) do
        local id = s.id
        local label = _(s.label)
        add{
            x = gutter + (i - 1) * tab_w, y = tab_y, w = (i == n) and (W - 2 * gutter - (n - 1) * tab_w) or tab_w, h = tab_h,
            paint = function(bb, x, y, w, h)
                Draw.button(bb, label, x, y, w, h, { on = id == self.section })
            end,
            tap = function() self:switchSection(id) end,
        }
    end

    local top = tab_y + tab_h + gutter
    local ctx = {
        x = gutter, y = top, w = W - 2 * gutter, h = H - top - gutter,
        add       = add,
        screen    = self,
        state     = self:stateOf(self.section),
        lang      = _.lang(),
        landscape = self:isLandscape(),
        button_h  = tab_h,
        gap       = gutter,
        load      = lrequire,
    }
    self.ctx = ctx
    self:getView(self.section).build(ctx)
end

-- Rebuild and repaint. `rect` (canvas-local) limits the e-ink refresh to
-- what changed; mode defaults to "ui".
function ReferenceScreen:redraw(mode, rect)
    self:rebuild()
    local region = self.dimen
    if rect then
        region = Geom:new{
            x = self.canvas.dimen.x + rect.x, y = self.canvas.dimen.y + rect.y,
            w = rect.w, h = rect.h,
        }
    end
    UIManager:setDirty(self, function() return mode or "ui", region end)
end

function ReferenceScreen:switchSection(id)
    if not SECTION_BY_ID[id] then return end
    self.section = id
    self.plugin:saveSetting("section", id)
    self:redraw("ui", Geom:new{ x = 0, y = 0, w = self.canvas.width, h = self.canvas.height })
end

function ReferenceScreen:onViewSwipe(dir)
    local view = self:getView(self.section)
    if view.swipe and view.swipe(self.ctx, dir) then return end
    -- Elsewhere a horizontal swipe moves to the next / previous section.
    if dir == "west" or dir == "east" then
        for i, s in ipairs(SECTIONS) do
            if s.id == self.section then
                local j = dir == "west" and i + 1 or i - 1
                if SECTIONS[j] then self:switchSection(SECTIONS[j].id) end
                return
            end
        end
    end
end

-- Rotation: rebuild for the new size.
function ReferenceScreen:onSetDimensions()
    if DeviceScreen:getWidth() ~= self.dimen.w or DeviceScreen:getHeight() ~= self.dimen.h then
        self:buildLayout()
        UIManager:setDirty(self, "full")
    end
end
ReferenceScreen.onScreenResize = ReferenceScreen.onSetDimensions

function ReferenceScreen:closeScreen()
    Draw.freeTiles()
    ScreenBase.closeScreen(self)
end

-- ---------------------------------------------------------------------------
-- Dialog helpers for the views
-- ---------------------------------------------------------------------------

function ReferenceScreen:showInfo(text)
    UIManager:show(InfoMessage:new{ text = text, show_icon = false })
end

function ReferenceScreen:askText(title, hint, initial, on_ok, input_type)
    local dialog
    dialog = InputDialog:new{
        title      = title,
        input      = initial or "",
        input_hint = hint,
        input_type = input_type,
        buttons = { {
            { text = _("Cancel"), id = "close", callback = function() UIManager:close(dialog) end },
            { text = _("OK"), is_enter_default = true, callback = function()
                local text = dialog:getInputText() or ""
                UIManager:close(dialog)
                on_ok(text)
            end },
        } },
    }
    UIManager:show(dialog)
    dialog:onShowKeyboard()
end

-- ---------------------------------------------------------------------------
-- Settings
-- ---------------------------------------------------------------------------

function ReferenceScreen:openSettings()
    local dlg
    local remember = self.plugin:getSetting("remember_section", true)
    dlg = ButtonDialog:new{
        title = _("Settings"),
        buttons = {
            { { text = (remember and "✓ " or "") .. _("Open on the last section used"), callback = function()
                UIManager:close(dlg)
                self.plugin:saveSetting("remember_section", not remember)
            end } },
            { { text = _("Reset ruler calibration"), callback = function()
                UIManager:close(dlg)
                self.plugin:saveSetting("ruler_scale", 1)
                if self.section == "ruler" then self:redraw() end
                self:showMessage(_("Ruler calibration reset."), 2)
            end } },
        },
    }
    UIManager:show(dlg)
end

return ReferenceScreen
