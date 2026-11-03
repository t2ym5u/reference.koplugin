-- draw.lua -- painting helpers shared by the reference views: fonts sized in
-- pixels, aligned text, framed buttons, word wrap and the greyscale fill
-- patterns of the periodic table's categories.

local Blitbuffer = require("ffi/blitbuffer")
local Device     = require("device")
local Font       = require("ui/font")
local RenderText = require("ui/rendertext")

local Screen = Device.screen

local Draw = {}

Draw.BLACK = Blitbuffer.COLOR_BLACK
Draw.WHITE = Blitbuffer.COLOR_WHITE
Draw.LIGHT = Blitbuffer.Color8(0xE0)
Draw.GREY  = Blitbuffer.Color8(0xB8)
Draw.MID   = Blitbuffer.Color8(0x88)
Draw.DARK  = Blitbuffer.Color8(0x50)

Draw.REGULAR = "cfont"   -- NotoSans-Regular
Draw.BOLD    = "tfont"   -- NotoSans-Bold

-- A face whose em size is `px` real pixels (Font:getFace scales its size
-- by the screen's DPI, which would make layouts DPI-dependent twice).
local face_cache = {}
function Draw.face(px, bold)
    px = math.max(6, math.floor(px))
    local key = (bold and "b" or "r") .. px
    local f = face_cache[key]
    if not f then
        local unit = Screen:scaleBySize(1000) / 1000
        f = Font:getFace(bold and Draw.BOLD or Draw.REGULAR, px / unit)
        face_cache[key] = f
    end
    return f
end

function Draw.width(face, text, bold)
    return RenderText:sizeUtf8Text(0, Screen:getWidth() * 4, face, text, true, bold).x
end

-- Largest face (<= max_px) for which `text` fits `w` pixels.
function Draw.fit(text, max_px, w, bold, min_px)
    local px = math.floor(max_px)
    min_px = min_px or 8
    while px > min_px do
        local f = Draw.face(px, bold)
        if Draw.width(f, text, bold) <= w then return f, px end
        px = px - 1
    end
    return Draw.face(min_px, bold), min_px
end

-- Draws `text` inside the box (x, y, w, h). align: "center" (default),
-- "left", "right"; valign: "center" (default), "top", "bottom".
function Draw.text(bb, text, face, x, y, w, h, opts)
    opts = opts or {}
    local bold = opts.bold
    local tw = Draw.width(face, text, bold)
    local fh, asc = face.ftsize:getHeightAndAscender()
    local tx
    if opts.align == "left" then tx = x
    elseif opts.align == "right" then tx = x + w - tw
    else tx = x + math.floor((w - tw) / 2) end
    local ty
    if opts.valign == "top" then ty = y + asc
    elseif opts.valign == "bottom" then ty = y + h - (fh - asc)
    else ty = y + math.floor((h - fh) / 2) + asc end
    if opts.backing then
        -- A white plate behind small text drawn over a pattern.
        local bx = math.max(x, tx) - 1
        bb:paintRect(bx, math.floor(ty) - asc + 1, math.min(tw + 2, x + w - bx), fh - 1, Draw.WHITE)
    end
    RenderText:renderUtf8Text(bb, math.max(x, tx), math.floor(ty), face, text, true, bold,
        opts.color or Draw.BLACK, w)
    return tw
end

function Draw.frame(bb, x, y, w, h, thickness, color)
    bb:paintBorder(x, y, w, h, thickness or 1, color or Draw.BLACK)
end

-- A framed button; `on` inverts it (the current tab, a selected number).
function Draw.button(bb, label, x, y, w, h, opts)
    opts = opts or {}
    local on = opts.on
    bb:paintRect(x, y, w, h, on and Draw.BLACK or Draw.WHITE)
    Draw.frame(bb, x, y, w, h, opts.border or 2, Draw.BLACK)
    local face = opts.face or Draw.fit(label, opts.px or math.floor(h * 0.42), w - 8, opts.bold ~= false)
    Draw.text(bb, label, face, x + 2, y, w - 4, h, {
        bold  = opts.bold ~= false,
        color = on and Draw.WHITE or Draw.BLACK,
    })
end

-- Greedy word wrap on spaces. Returns a list of lines.
function Draw.wrap(text, face, w, bold)
    local lines, line = {}, ""
    for word in (text or ""):gmatch("%S+") do
        local cand = line == "" and word or (line .. " " .. word)
        if Draw.width(face, cand, bold) <= w or line == "" then
            line = cand
        else
            lines[#lines + 1] = line
            line = word
        end
    end
    if line ~= "" then lines[#lines + 1] = line end
    return lines
end

-- ---------------------------------------------------------------------------
-- Category fill patterns. Light greys and thin lines only, so a black
-- symbol painted over them stays legible on e-ink.
-- ---------------------------------------------------------------------------

local function hlines(bb, x, y, w, h, step, c)
    for yy = y + math.floor(step / 2), y + h - 1, step do bb:paintRect(x, yy, w, 1, c) end
end
local function vlines(bb, x, y, w, h, step, c)
    for xx = x + math.floor(step / 2), x + w - 1, step do bb:paintRect(xx, y, 1, h, c) end
end
-- Diagonals, one pixel at a time, clipped to the box. dir 1 = "/", -1 = "\".
local function diag(bb, x, y, w, h, step, c, dir)
    for k = -h, w, step do
        for i = 0, h - 1 do
            local xx = dir > 0 and (k + (h - 1 - i)) or (k + i)
            if xx >= 0 and xx < w then bb:paintRect(x + xx, y + i, 1, 1, c) end
        end
    end
end
local function dots(bb, x, y, w, h, step, c)
    for yy = y + 2, y + h - 2, step do
        local shift = (math.floor((yy - y) / step) % 2) * math.floor(step / 2)
        for xx = x + 2 + shift, x + w - 2, step do bb:paintRect(xx, yy, 2, 2, c) end
    end
end

Draw.PATTERNS = {
    alkali          = function(bb, x, y, w, h) bb:paintRect(x, y, w, h, Draw.GREY) end,
    alkaline        = function(bb, x, y, w, h) diag(bb, x, y, w, h, 6, Draw.MID, 1) end,
    transition      = function() end, -- plain white: the largest family
    post_transition = function(bb, x, y, w, h) hlines(bb, x, y, w, h, 5, Draw.MID) end,
    metalloid       = function(bb, x, y, w, h)
        diag(bb, x, y, w, h, 8, Draw.MID, 1); diag(bb, x, y, w, h, 8, Draw.MID, -1)
    end,
    nonmetal        = function(bb, x, y, w, h) dots(bb, x, y, w, h, 6, Draw.MID) end,
    noble           = function(bb, x, y, w, h) bb:paintRect(x, y, w, h, Draw.LIGHT) end,
    lanthanide      = function(bb, x, y, w, h) vlines(bb, x, y, w, h, 5, Draw.MID) end,
    actinide        = function(bb, x, y, w, h) diag(bb, x, y, w, h, 6, Draw.MID, -1) end,
    unknown         = function(bb, x, y, w, h)
        hlines(bb, x, y, w, h, 8, Draw.GREY); vlines(bb, x, y, w, h, 8, Draw.GREY)
    end,
}

-- Paints a category's pattern over (x, y, w, h). Each pattern is drawn once
-- per cell size into a small tile and blitted after that: the diagonals
-- are drawn pixel by pixel, too slow to redo for every cell on each repaint.
local tiles = {}
function Draw.pattern(bb, category, x, y, w, h)
    local p = Draw.PATTERNS[category]
    if not p or category == "transition" then return end
    local key = category .. w .. "x" .. h
    local tile = tiles[key]
    if not tile then
        tile = Blitbuffer.new(w, h, Blitbuffer.TYPE_BB8)
        tile:fill(Draw.WHITE)
        p(tile, 0, 0, w, h)
        tiles[key] = tile
    end
    bb:blitFrom(tile, x, y, 0, 0, w, h)
end

function Draw.freeTiles()
    for k, t in pairs(tiles) do t:free(); tiles[k] = nil end
end

return Draw
