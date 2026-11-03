-- view_tables.lua -- multiplication tables, squares/cubes/powers of 2 and
-- SI prefixes.

local _ = require("i18n")
local T = require("ffi/util").template

local VIEW = {}

-- A plain table: header row then rows, every other row shaded. widths are
-- fractions of w; aligns per column ("left"/"right"/"center").
local function addTable(ctx, Draw, x, y, w, h, headers, rows, widths, aligns)
    local n = #rows + 1
    local rh = math.floor(h / n)
    local px = math.floor(math.min(rh * 0.55, 34))
    -- Fit the widest cell of each column.
    local colw = {}
    for c, f in ipairs(widths) do colw[c] = math.floor(w * f) end
    local all = { headers }
    for _i, row in ipairs(rows) do all[#all + 1] = row end
    for _i, row in ipairs(all) do
        for c, v in ipairs(row) do
            local _f, p = Draw.fit(tostring(v), px, colw[c] - 14, false)
            px = math.min(px, p)
        end
    end
    local face, hface = Draw.face(px, false), Draw.face(px, true)
    ctx.add{
        x = x, y = y, w = w, h = rh * n,
        paint = function(bb, ax, ay)
            local function line(vals, yy, f, bold)
                local cx = ax
                for c, v in ipairs(vals) do
                    Draw.text(bb, tostring(v), f, cx + 7, yy, colw[c] - 14, rh,
                        { align = aligns[c] or "left", bold = bold })
                    cx = cx + colw[c]
                end
            end
            line(headers, ay, hface, true)
            bb:paintRect(ax, ay + rh - 2, w, 2, Draw.BLACK)
            for i, row in ipairs(rows) do
                local yy = ay + i * rh
                if i % 2 == 0 then bb:paintRect(ax, yy, w, rh, Draw.LIGHT) end
                line(row, yy, face, false)
            end
        end,
    }
end

-- Multiplication ------------------------------------------------------------

local function buildMultiplication(ctx, Draw, Parts, y)
    local st = ctx.state
    local sel = tonumber(st.n)
    local bottom = ctx.y + ctx.h
    local bh = math.floor(ctx.button_h * 0.9)
    local function pick(n)
        return function()
            st.n = (st.n == n) and nil or n
            ctx.screen:saveViewState()
            ctx.screen:redraw()
        end
    end
    local per_row = ctx.landscape and 13 or 7
    local row = {}
    for n = 1, 12 do row[#row + 1] = { label = tostring(n), on = sel == n, tap = pick(n) } end
    row[#row + 1] = { label = "12×12", on = sel == nil, tap = function()
        st.n = nil; ctx.screen:saveViewState(); ctx.screen:redraw()
    end }
    local i = 1
    while i <= #row do
        local chunk = {}
        for j = i, math.min(#row, i + per_row - 1) do chunk[#chunk + 1] = row[j] end
        while #chunk < per_row do chunk[#chunk + 1] = { label = "" } end
        y = Parts.buttonRow(ctx, y, chunk, { h = bh, px = math.floor(bh * 0.45) }) + 4
        i = i + per_row
    end
    y = y + ctx.gap
    local h = bottom - y

    if sel then
        -- n × 1 … n × 12 in large type.
        local cols = ctx.landscape and 2 or 1
        local rows = math.ceil(12 / cols)
        local rh = math.floor(h / rows)
        local cw = math.floor(ctx.w / cols)
        local face = Draw.face(math.floor(math.min(rh * 0.6, 46)), false)
        local bface = Draw.face(math.floor(math.min(rh * 0.6, 46)), true)
        ctx.add{
            x = ctx.x, y = y, w = ctx.w, h = h,
            paint = function(bb, ax, ay)
                for k = 1, 12 do
                    local c = math.floor((k - 1) / rows)
                    local r = (k - 1) % rows
                    local cx, cy = ax + c * cw, ay + r * rh
                    if r % 2 == 1 then bb:paintRect(cx + 4, cy, cw - 8, rh, Draw.LIGHT) end
                    local half = math.floor(cw * 0.55)
                    Draw.text(bb, T("%1 × %2 =", sel, k), face, cx, cy, half, rh, { align = "right" })
                    Draw.text(bb, tostring(sel * k), bface, cx + half + 14, cy, cw - half - 14, rh,
                        { align = "left", bold = true })
                end
            end,
        }
        return
    end

    -- The 12 × 12 grid with its row and column headers.
    local n = 13
    local cell = math.floor(math.min(ctx.w / n, h / n))
    local gw = cell * n
    local gx = ctx.x + math.floor((ctx.w - gw) / 2)
    local face = Draw.fit("144", math.floor(cell * 0.5), cell - 6, false)
    local bface = Draw.fit("144", math.floor(cell * 0.5), cell - 6, true)
    ctx.add{
        x = gx, y = y, w = gw, h = gw,
        paint = function(bb, ax, ay)
            for r = 0, 12 do
                for c = 0, 12 do
                    local cx, cy = ax + c * cell, ay + r * cell
                    local header = r == 0 or c == 0
                    if header and not (r == 0 and c == 0) then
                        bb:paintRect(cx, cy, cell, cell, Draw.GREY)
                    elseif r == c then
                        bb:paintRect(cx, cy, cell, cell, Draw.LIGHT)
                    end
                    local v = (r == 0 and c == 0) and "×" or tostring(math.max(r, 1) * math.max(c, 1))
                    if r == 0 and c > 0 then v = tostring(c) end
                    if c == 0 and r > 0 then v = tostring(r) end
                    Draw.text(bb, v, header and bface or face, cx, cy, cell, cell, { bold = header })
                end
            end
            for k = 0, n do
                local t = (k == 1 or k == 0 or k == n) and 2 or 1
                bb:paintRect(ax + k * cell, ay, t, gw, Draw.BLACK)
                bb:paintRect(ax, ay + k * cell, gw, t, Draw.BLACK)
            end
        end,
    }
    -- Tap a header to open that number's table.
    for k = 1, 12 do
        ctx.add{ x = gx + k * cell, y = y, w = cell, h = cell, tap = pick(k) }
        ctx.add{ x = gx, y = y + k * cell, w = cell, h = cell, tap = pick(k) }
    end
end

-- Powers --------------------------------------------------------------------

local function buildPowers(ctx, Draw, Lists, y)
    local lang = ctx.lang
    local rows = {}
    for _i, p in ipairs(Lists.powers(20)) do
        rows[#rows + 1] = { p[1], Lists.groupDigits(p[2], lang), Lists.groupDigits(p[3], lang),
                            Lists.groupDigits(p[4], lang) }
    end
    local headers = { "n", "n²", "n³", "2ⁿ" }
    local widths = { 0.14, 0.22, 0.30, 0.34 }
    local aligns = { "right", "right", "right", "right" }
    local h = ctx.y + ctx.h - y
    if ctx.landscape then
        local half = math.floor((ctx.w - ctx.gap * 2) / 2)
        local a, b = {}, {}
        for i = 1, 10 do a[i] = rows[i]; b[i] = rows[i + 10] end
        addTable(ctx, Draw, ctx.x, y, half, h, headers, a, widths, aligns)
        addTable(ctx, Draw, ctx.x + half + ctx.gap * 2, y, half, h, headers, b, widths, aligns)
    else
        addTable(ctx, Draw, ctx.x, y, ctx.w, h, headers, rows, widths, aligns)
    end
end

-- SI prefixes -----------------------------------------------------------------

local function buildSI(ctx, Draw, Lists, y)
    local fr = ctx.lang == "fr"
    local rows = {}
    for _i, p in ipairs(Lists.SI) do
        rows[#rows + 1] = { p[1], fr and p[3] or p[2], Lists.powerOfTen(p[4]),
                            Lists.decimalForm(p[4], ctx.lang) or "" }
    end
    local headers = { _("Symbol"), _("Prefix"), _("Factor"), "" }
    local widths = { 0.2, 0.3, 0.25, 0.25 }
    local aligns = { "center", "left", "left", "right" }
    local h = ctx.y + ctx.h - y
    if ctx.landscape then
        local half = math.floor((ctx.w - ctx.gap * 2) / 2)
        local a, b = {}, {}
        for i = 1, 12 do a[i] = rows[i]; b[i] = rows[i + 12] end
        addTable(ctx, Draw, ctx.x, y, half, h, headers, a, widths, aligns)
        addTable(ctx, Draw, ctx.x + half + ctx.gap * 2, y, half, h, headers, b, widths, aligns)
    else
        addTable(ctx, Draw, ctx.x, y, ctx.w, h, headers, rows, widths, aligns)
    end
end

function VIEW.build(ctx)
    local Draw, Parts, Lists = ctx.load("draw"), ctx.load("parts"), ctx.load("lists")
    local tab, y = Parts.subTabs(ctx, {
        { id = "mult",   label = _("Multiplication") },
        { id = "powers", label = _("Powers") },
        { id = "si",     label = _("SI prefixes") },
    }, "tab")
    if tab == "mult" then
        buildMultiplication(ctx, Draw, Parts, y)
    elseif tab == "powers" then
        buildPowers(ctx, Draw, Lists, y)
    else
        buildSI(ctx, Draw, Lists, y)
    end
end

return VIEW
