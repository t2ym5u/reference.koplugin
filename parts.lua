-- parts.lua -- building blocks the views add to the canvas: a row of
-- sub-tabs and a row of buttons.

local _dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
local function lrequire(name)
    local key = _dir .. name
    if not package.loaded[key] then
        package.loaded[key] = assert(loadfile(_dir .. name .. ".lua"))()
    end
    return package.loaded[key]
end

local Draw = lrequire("draw")

local Parts = {}

-- A row of equal buttons across the view at height y.
-- buttons = { { label =, on =, tap = }, ... }; returns the y under the row.
function Parts.buttonRow(ctx, y, buttons, opts)
    opts = opts or {}
    local n = #buttons
    local x0, w = opts.x or ctx.x, opts.w or ctx.w
    local h = opts.h or ctx.button_h
    local gap = opts.gap or 0
    local bw = math.floor((w - gap * (n - 1)) / n)
    -- One font for the whole row, sized on its longest label, so the
    -- buttons don't each come out at a different size.
    local face
    if opts.uniform ~= false then
        local px = opts.px or math.floor(h * 0.42)
        for _i, b in ipairs(buttons) do
            local _f, p = Draw.fit(b.label, px, bw - 10, true)
            px = math.min(px, p)
        end
        face = Draw.face(px, true)
    end
    for i, b in ipairs(buttons) do
        local bx = x0 + (i - 1) * (bw + gap)
        local this_w = (i == n) and (x0 + w - bx) or bw
        ctx.add{
            x = bx, y = y, w = this_w, h = h,
            paint = (b.label ~= "" or b.draw) and function(bb, x, yy, ww, hh)
                Draw.button(bb, b.label, x, yy, ww, hh, { on = b.on, face = face })
                if b.draw then b.draw(bb, x, yy, ww, hh) end
            end or nil,
            tap = b.tap,
        }
    end
    return y + h
end

-- Sub-tabs at the top of the view. options = { { id =, label = }, ... };
-- the selection is kept in ctx.state[state_key]. Returns the selected id
-- and the y under the row.
function Parts.subTabs(ctx, options, state_key)
    local cur = ctx.state[state_key]
    local valid = false
    for _i, o in ipairs(options) do if o.id == cur then valid = true end end
    if not valid then cur = options[1].id end
    local buttons = {}
    for i, o in ipairs(options) do
        local id = o.id
        buttons[i] = {
            label = o.label, on = id == cur,
            tap = function()
                ctx.state[state_key] = id
                ctx.screen:saveViewState()
                ctx.screen:redraw()
            end,
        }
    end
    local y = Parts.buttonRow(ctx, ctx.y, buttons, { h = math.floor(ctx.button_h * 0.85) })
    return cur, y + ctx.gap
end

-- Splits `n` items into `cols` columns (column-major) inside a box and
-- returns each item's cell: { x, y, w, h }.
function Parts.cells(n, cols, x, y, w, h)
    local rows = math.ceil(n / cols)
    local cw, ch = math.floor(w / cols), math.floor(h / rows)
    local out = {}
    for i = 1, n do
        local c = math.floor((i - 1) / rows)
        local r = (i - 1) % rows
        out[i] = { x = x + c * cw, y = y + r * ch, w = cw, h = ch }
    end
    return out, cw, ch
end

return Parts
