-- view_elements.lua -- the periodic table.
--
-- Landscape: the whole table, with the legend in the gap above the
-- transition metals. Portrait: the whole table in narrow cells with the
-- legend below, or one half (groups 1-9 / 10-18) zoomed in with names.

local _ = require("i18n")
local T = require("ffi/util").template

local VIEW = {}

local GAP_ROW = 0.35  -- height of the spacer above the f-block rows, in cells

local function load(ctx)
    return ctx.load("draw"), ctx.load("parts"), ctx.load("elements")
end

local function rowY(row)
    if row <= 7 then return row - 1 end
    return row - 2 + GAP_ROW   -- rows 9, 10 -> 7.35, 8.35
end

local function elementName(e, lang)
    return lang == "fr" and e.name_fr or e.name_en
end

local function showDetails(ctx, e)
    local E = ctx.load("elements")
    local lang = ctx.lang
    local lines = {}
    lines[#lines + 1] = T("%1  %2 — %3", e.z, e.symbol, elementName(e, lang))
    if lang == "fr" then
        lines[#lines + 1] = T(_("English: %1"), e.name_en)
    else
        lines[#lines + 1] = T(_("French: %1"), e.name_fr)
    end
    lines[#lines + 1] = ""
    local mass = E.formatMass(e, lang)
    if E.isRadioactiveOnly(e) then
        lines[#lines + 1] = T(_("Atomic mass: %1 (most stable isotope)"), mass)
    else
        lines[#lines + 1] = T(_("Atomic mass: %1"), mass)
    end
    if e.group == 0 then
        lines[#lines + 1] = T(_("Period %1 · block f"), e.period)
    else
        lines[#lines + 1] = T(_("Group %1 · period %2 · block %3"), e.group, e.period, E.block(e))
    end
    lines[#lines + 1] = T(_("Family: %1"), _(E.CATEGORY_LABELS[e.category]))
    ctx.screen:showInfo(table.concat(lines, "\n"))
end

-- Paints one element cell.
local function paintCell(Draw, E, e, lang, bb, x, y, w, h, detailed)
    Draw.pattern(bb, e.category, x + 1, y + 1, w - 2, h - 2)
    Draw.frame(bb, x, y, w, h, 1)
    local pad = math.max(2, math.floor(w * 0.06))
    local small = Draw.face(math.max(9, math.floor(math.min(w, h) * 0.2)), false)
    Draw.text(bb, tostring(e.z), small, x + pad, y + 1, w - 2 * pad, math.floor(h * 0.28),
        { align = "left", backing = true })
    local sym_px = math.floor(math.min(w * 0.46, h * (detailed and 0.32 or 0.4)))
    local sym = Draw.face(sym_px, true)
    local sym_top = y + math.floor(h * 0.24)
    local sym_h = math.floor(h * (detailed and 0.34 or 0.44))
    Draw.text(bb, e.symbol, sym, x, sym_top, w, sym_h, { bold = true })
    local bottom_y = sym_top + sym_h
    if detailed then
        local name = lang == "fr" and e.name_fr or e.name_en
        local nf = Draw.fit(name, math.floor(h * 0.15), w - 2 * pad, false, 7)
        Draw.text(bb, name, nf, x + pad, bottom_y, w - 2 * pad, math.floor(h * 0.18), { backing = true })
        bottom_y = bottom_y + math.floor(h * 0.18)
    end
    if w >= 48 then
        local mass = E.formatMass(e, lang)
        local mf = Draw.fit(mass, math.floor(h * 0.16), w - 2 * pad, false, 7)
        Draw.text(bb, mass, mf, x + pad, bottom_y, w - 2 * pad, y + h - 2 - bottom_y, { backing = true })
    end
end

-- The legend: a swatch and a label per family, in `cols` columns.
local function addLegend(ctx, Draw, E, x, y, w, h, cols)
    local cats = E.CATEGORIES
    local rows = math.ceil(#cats / cols)
    local cw, rh = math.floor(w / cols), math.floor(h / rows)
    local sw = math.min(rh - 6, math.floor(cw * 0.25))
    -- One label size for all, fitted to the longest label.
    local px = math.floor(rh * 0.5)
    for _i, c in ipairs(cats) do
        local _f, p = Draw.fit(_(E.CATEGORY_LABELS[c]), px, cw - sw - 14, false)
        px = math.min(px, p)
    end
    local face = Draw.face(px, false)
    ctx.add{
        x = x, y = y, w = w, h = h,
        paint = function(bb, ax, ay)
            for i, c in ipairs(cats) do
                local col = math.floor((i - 1) / rows)
                local row = (i - 1) % rows
                local cx, cy = ax + col * cw, ay + row * rh
                local sy = cy + math.floor((rh - sw) / 2)
                Draw.pattern(bb, c, cx + 1, sy + 1, sw - 2, sw - 2)
                Draw.frame(bb, cx, sy, sw, sw, 1)
                Draw.text(bb, _(E.CATEGORY_LABELS[c]), face, cx + sw + 8, cy, cw - sw - 10, rh,
                    { align = "left" })
            end
        end,
    }
end

function VIEW.build(ctx)
    local Draw, Parts, E = load(ctx)
    local lang = ctx.lang
    local st = ctx.state
    local zoom = ctx.landscape and "all" or (st.zoom or "all")

    local first, last = 1, 18
    if zoom == "left" then first, last = 1, 9
    elseif zoom == "right" then first, last = 10, 18 end
    local ncols = last - first + 1

    local x, y, w, h = ctx.x, ctx.y, ctx.w, ctx.h
    local bottom = y + h
    if not ctx.landscape then
        -- Zoom buttons along the bottom.
        local bh = ctx.button_h
        local by = bottom - bh
        Parts.buttonRow(ctx, by, {
            { label = _("Whole table"), on = zoom == "all",   tap = function() VIEW.setZoom(ctx, "all") end },
            { label = _("Groups 1–9"),  on = zoom == "left",  tap = function() VIEW.setZoom(ctx, "left") end },
            { label = _("Groups 10–18"), on = zoom == "right", tap = function() VIEW.setZoom(ctx, "right") end },
        })
        bottom = by - ctx.gap
    end

    -- Legend under the table in portrait; in landscape it goes in the gap.
    local legend_h = 0
    if not ctx.landscape then
        legend_h = math.floor(math.min(ctx.button_h * 0.62, 36) * 5)
    end
    local table_h = bottom - y - (legend_h > 0 and (legend_h + ctx.gap) or 0)
    local cell_w = math.floor(w / ncols)
    local cell_h = math.min(math.floor(cell_w * (zoom == "all" and 1.5 or 1.1)),
                            math.floor(table_h / (9 + GAP_ROW)))
    local grid_w = cell_w * ncols
    local gx = x + math.floor((w - grid_w) / 2)
    local grid_h = math.floor((9 + GAP_ROW) * cell_h)
    local gy = y
    local detailed = cell_w >= 70

    local function cellRect(col, row)
        return gx + (col - first) * cell_w, gy + math.floor(rowY(row) * cell_h)
    end

    for _i, e in ipairs(E.list) do
        local col, row = E.position(e)
        if col >= first and col <= last then
            local cx, cy = cellRect(col, row)
            ctx.add{
                x = cx, y = cy, w = cell_w + 1, h = cell_h + 1,
                paint = function(bb, px, py, pw, ph)
                    paintCell(Draw, E, e, lang, bb, px, py, pw, ph, detailed)
                end,
                tap = function() showDetails(ctx, e) end,
            }
        end
    end

    -- "57–71" / "89–103" placeholders in group 3.
    if first <= 3 and last >= 3 then
        for _i, ph in ipairs({ { 6, "57–71", "lanthanide" }, { 7, "89–103", "actinide" } }) do
            local cx, cy = cellRect(3, ph[1])
            ctx.add{
                x = cx, y = cy, w = cell_w + 1, h = cell_h + 1,
                paint = function(bb, px, py, pw, phh)
                    Draw.pattern(bb, ph[3], px + 1, py + 1, pw - 2, phh - 2)
                    Draw.frame(bb, px, py, pw, phh, 1)
                    local f = Draw.fit(ph[2], math.floor(phh * 0.24), pw - 4, true, 7)
                    Draw.text(bb, ph[2], f, px, py, pw, phh, { bold = true })
                end,
            }
        end
    end

    -- Period numbers are implicit; label the f-block rows on their left.
    if first <= 2 then
        for _i, r in ipairs({ { 9, "La–Lu" }, { 10, "Ac–Lr" } }) do
            local _cx, cy = cellRect(1, r[1])
            local lw = 2 * cell_w - 6
            local f = Draw.fit(r[2], math.floor(cell_h * 0.3), lw, true, 7)
            ctx.add{
                x = gx, y = cy, w = lw, h = cell_h,
                paint = function(bb, px, py, pw, phh)
                    Draw.text(bb, r[2], f, px, py, pw, phh, { bold = true, align = "right" })
                end,
            }
        end
    end

    if ctx.landscape then
        -- Groups 3-12 of periods 1-3 are empty: the legend fits there.
        local lx, ly = cellRect(3, 1)
        addLegend(ctx, Draw, E, lx + 6, ly + 4, 10 * cell_w - 12, 3 * cell_h - 8, 2)
    else
        addLegend(ctx, Draw, E, x + 4, gy + grid_h + ctx.gap, w - 8, legend_h, 2)
    end
end

function VIEW.setZoom(ctx, zoom)
    ctx.state.zoom = zoom
    ctx.screen:saveViewState()
    ctx.screen:redraw()
end

-- In portrait, a horizontal swipe moves between the two zoomed halves.
function VIEW.swipe(ctx, dir)
    if ctx.landscape then return false end
    local zoom = ctx.state.zoom or "all"
    if zoom == "all" then return false end
    if dir == "west" and zoom == "left" then VIEW.setZoom(ctx, "right"); return true end
    if dir == "east" and zoom == "right" then VIEW.setZoom(ctx, "left"); return true end
    return true
end

return VIEW
