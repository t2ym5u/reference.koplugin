-- view_ruler.lua -- centimetre and inch rulers drawn from the screen DPI,
-- with a remembered calibration factor.
--
-- Portrait: vertical scales down the left (cm) and right (in) edges.
-- Landscape: horizontal scales along the top (cm) and bottom (in).

local Device = require("device")
local _      = require("i18n")
local T      = require("ffi/util").template

local Screen = Device.screen

local VIEW = {}

local CM_LEN   = { cm = 0.55, half = 0.38, mm = 0.22 }
local INCH_LEN = { ["in"] = 0.55, half = 0.42, quarter = 0.32, eighth = 0.22, sixteenth = 0.14 }

local function getScale(ctx, Ruler)
    return Ruler.clampScale(ctx.screen.plugin:getSetting("ruler_scale", 1))
end

local function setScale(ctx, Ruler, s)
    ctx.screen.plugin:saveSetting("ruler_scale", Ruler.clampScale(s))
    ctx.screen:redraw()
end

-- Paints one scale. vertical: ticks grow from the edge at `edge`
-- ("left"/"right"/"top"/"bottom") into the strip (x, y, w, h).
local function paintScale(Draw, bb, ticks, lens, x, y, w, h, edge, face, unit_label)
    local vertical = edge == "left" or edge == "right"
    local depth = vertical and w or h
    bb:paintRect(x, y, w, h, Draw.WHITE)
    for _i, t in ipairs(ticks) do
        local len = math.floor(depth * lens[t.kind])
        local thick = (t.kind == "cm" or t.kind == "in") and 2 or 1
        if vertical then
            local ty = y + t.pos
            local tx = edge == "left" and x or (x + w - len)
            bb:paintRect(tx, ty, len, thick, Draw.BLACK)
            if t.label and t.pos < h - 60 then
                local lw = math.floor(depth * 0.4)
                local lx = edge == "left" and (x + len + 4) or (x + w - len - 4 - lw)
                Draw.text(bb, t.label, face, lx, ty - 20, lw, 40,
                    { bold = true, align = edge == "left" and "left" or "right" })
            end
        else
            local tx = x + t.pos
            local ty = edge == "top" and y or (y + h - len)
            bb:paintRect(tx, ty, thick, len, Draw.BLACK)
            if t.label and t.pos < w - 60 then
                local lh = math.floor(depth * 0.4)
                local ly = edge == "top" and (y + len + 2) or (y + h - len - 2 - lh)
                Draw.text(bb, t.label, face, tx - 30, ly, 60, lh, { bold = true })
            end
        end
    end
    -- Unit name at the far end.
    local uf = face
    if vertical then
        Draw.text(bb, unit_label, uf, x, y + h - 40, w, 40,
            { align = edge == "left" and "right" or "left", color = Draw.DARK })
    else
        Draw.text(bb, unit_label, uf, x + w - 70, edge == "top" and (y + h - 36) or y, 66, 36,
            { align = "right", color = Draw.DARK })
    end
end

function VIEW.build(ctx)
    local Draw, Parts, Ruler = ctx.load("draw"), ctx.load("parts"), ctx.load("ruler")
    local dpi = Screen:getDPI()
    local scale = getScale(ctx, Ruler)
    local ppmm = Ruler.pxPerMm(dpi, scale)
    local x, y, w, h = ctx.x, ctx.y, ctx.w, ctx.h
    local face = Draw.face(math.floor(ctx.button_h * 0.38), true)
    local strip = math.floor((ctx.landscape and h or w) * (ctx.landscape and 0.24 or 0.2))

    -- The scales start 4 px inside the view so the 0 tick is not lost under
    -- the screen bezel; a real ruler is laid on the 0 tick, not the edge.
    local start = 4
    local length
    local cm_rect, in_rect
    if ctx.landscape then
        length = w - start - 1
        cm_rect = { x = x + start, y = y, w = length, h = strip, edge = "top" }
        in_rect = { x = x + start, y = y + h - strip, w = length, h = strip, edge = "bottom" }
    else
        length = h - start - 1
        cm_rect = { x = x, y = y + start, w = strip, h = length, edge = "left" }
        in_rect = { x = x + w - strip, y = y + start, w = strip, h = length, edge = "right" }
    end
    local cm_ticks = Ruler.cmTicks(length, ppmm)
    local in_ticks = Ruler.inchTicks(length, ppmm, 4)
    for _i, r in ipairs({ { cm_rect, cm_ticks, CM_LEN, "cm" }, { in_rect, in_ticks, INCH_LEN, "in" } }) do
        local rect = r[1]
        ctx.add{
            x = rect.x, y = rect.y, w = rect.w, h = rect.h,
            paint = function(bb, px, py, pw, ph)
                paintScale(Draw, bb, r[2], r[3], px, py, pw, ph, rect.edge, face, r[4])
            end,
        }
    end

    -- Calibration panel between the scales.
    local px_, py_, pw_, ph_
    if ctx.landscape then
        px_, py_, pw_, ph_ = x + 20, y + strip + ctx.gap, w - 40, h - 2 * strip - 2 * ctx.gap
    else
        px_, py_, pw_, ph_ = x + strip + ctx.gap * 2, y + ctx.gap, w - 2 * strip - ctx.gap * 4, h - 2 * ctx.gap
    end
    local whole_cm = math.min(10, math.floor(length / ppmm / 10))
    local pct = string.format("%.1f", scale * 100)
    if ctx.lang == "fr" then pct = pct:gsub("%.", ",") end
    local info = {
        T(_("Screen: %1 dpi"), dpi),
        T(_("Calibration: %1 %"), pct),
    }
    local help = _("Lay a real ruler on the 0 mark and adjust until the marks line up.")
    local bh = ctx.button_h
    local lf = Draw.face(math.floor(bh * 0.38), true)
    local hf = Draw.face(math.floor(bh * 0.32), false)
    local help_lines = Draw.wrap(help, hf, pw_)
    local text_h = math.floor(bh * 0.6) * #info + math.floor(bh * 0.5) * #help_lines + ctx.gap
    local rows = ctx.landscape and 2 or 4  -- button rows below
    local buttons_h = rows * (bh + 6)
    local top = py_ + math.max(0, math.floor((ph_ - text_h - buttons_h - ctx.gap) / 2))
    ctx.add{
        x = px_, y = top, w = pw_, h = text_h,
        paint = function(bb, ax, ay, aw)
            local yy = ay
            for _i, l in ipairs(info) do
                Draw.text(bb, l, lf, ax, yy, aw, math.floor(bh * 0.6), { bold = true })
                yy = yy + math.floor(bh * 0.6)
            end
            yy = yy + ctx.gap
            for _i, l in ipairs(help_lines) do
                Draw.text(bb, l, hf, ax, yy, aw, math.floor(bh * 0.5), { color = Draw.DARK })
                yy = yy + math.floor(bh * 0.5)
            end
        end,
    }
    local by = top + text_h + ctx.gap
    local function step(n) return function() setScale(ctx, Ruler, Ruler.adjust(scale, n)) end end
    local measure = function()
        ctx.screen:askText(T(_("How many mm does the 0–%1 cm span measure?"), whole_cm),
            T(_("For example %1"), whole_cm * 10), nil, function(text)
                local mm = tonumber((text:gsub(",", ".")))
                if not mm or mm <= 0 then return end
                setScale(ctx, Ruler, Ruler.calibrate(scale, whole_cm * 10, mm))
            end, "number")
    end
    local fine = ctx.lang == "fr" and "0,2" or "0.2"
    local b = {
        m1 = { label = "− 1 %", tap = step(-5) },
        p1 = { label = "+ 1 %", tap = step(5) },
        m02 = { label = "− " .. fine .. " %", tap = step(-1) },
        p02 = { label = "+ " .. fine .. " %", tap = step(1) },
        measure = { label = _("Measure…"), tap = measure },
        reset = { label = _("Reset"), tap = function() setScale(ctx, Ruler, 1) end },
    }
    local layout = ctx.landscape
        and { { b.m1, b.m02, b.p02, b.p1 }, { b.measure, b.reset } }
        or  { { b.m1, b.p1 }, { b.m02, b.p02 }, { b.measure }, { b.reset } }
    for _i, row in ipairs(layout) do
        by = Parts.buttonRow(ctx, by, row, { x = px_, w = pw_, gap = 8 }) + 6
    end
end

return VIEW
