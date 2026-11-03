-- view_morse.lua -- Morse table, on-screen keyer (Morse -> text) and
-- text -> Morse.
--
-- Dots and dashes are drawn as shapes rather than glyphs: "." and "-"
-- in a text font are too small to read at arm's length.

local _ = require("i18n")
local T = require("ffi/util").template

local VIEW = {}

-- Signal sizes for unit `u`: a dot is a round blob 1.6u wide, a dash a
-- bar 3.4u long, signals 1u apart.
local function dotW(u) return math.floor(u * 1.6 + 0.5) end
local function dashW(u) return math.floor(u * 3.4 + 0.5) end

-- Width in px of one code drawn with signal unit `u`.
local function codeWidth(code, u)
    local w = 0
    for i = 1, #code do
        w = w + (code:sub(i, i) == "-" and dashW(u) or dotW(u))
        if i < #code then w = w + u end
    end
    return w
end

local function paintCode(Draw, bb, code, x, cy, u)
    local dw, lw = dotW(u), dashW(u)
    for i = 1, #code do
        if code:sub(i, i) == "-" then
            bb:paintRect(x, cy - math.floor(u / 2), lw, u, Draw.BLACK)
            x = x + lw
        else
            bb:paintCircle(x + math.floor(dw / 2), cy, math.floor(dw / 2), Draw.BLACK)
            x = x + dw
        end
        x = x + u
    end
end

-- Splits a Morse string into lines of at most `w` px, breaking between
-- letters. Word gaps are drawn as a thin slash.
local function layoutLines(morse, w, u)
    local tokens = {}
    for tok in morse:gmatch("%S+") do tokens[#tokens + 1] = tok end
    local letter_gap, word_gap = 3 * u, 5 * u
    local lines, line, lw = {}, {}, 0
    for _i, tok in ipairs(tokens) do
        local tw = tok == "/" and word_gap or codeWidth(tok, u)
        if lw > 0 and lw + letter_gap + tw > w then
            lines[#lines + 1] = line
            line, lw = {}, 0
        end
        line[#line + 1] = tok
        lw = lw + (lw > 0 and letter_gap or 0) + tw
    end
    if #line > 0 then lines[#lines + 1] = line end
    return lines
end

-- Paints a Morse string; the unit shrinks (down to 3 px) until it all fits
-- in the box, and past that the end is kept.
local function paintMorseLines(Draw, bb, morse, x, y, w, h, u)
    local lines, lh, max_lines
    repeat
        lines = layoutLines(morse, w, u)
        lh = math.floor(u * 4.5)
        max_lines = math.max(1, math.floor(h / lh))
        if #lines <= max_lines or u <= 3 then break end
        u = u - 1
    until false
    local letter_gap, word_gap = 3 * u, 5 * u
    local first = math.max(1, #lines - max_lines + 1)
    for li = first, #lines do
        local cy = y + (li - first) * lh + math.floor(lh / 2)
        local cx = x
        for ti, tok in ipairs(lines[li]) do
            if ti > 1 then cx = cx + letter_gap end
            if tok == "/" then
                local mid = cx + math.floor(word_gap / 2)
                bb:paintRect(mid - 1, cy - u * 2, 2, u * 4, Draw.MID)
                cx = cx + word_gap
            else
                paintCode(Draw, bb, tok, cx, cy, u)
                cx = cx + codeWidth(tok, u)
            end
        end
    end
end

local function setInput(ctx, value, mode)
    ctx.state.input = value
    ctx.state.mode = mode or "key"
    ctx.screen:saveViewState()
end

function VIEW.build(ctx)
    local Draw, Parts, Morse = ctx.load("draw"), ctx.load("parts"), ctx.load("morse")
    local st = ctx.state
    local mode = st.mode == "text" and "text" or "key"
    local input = st.input or ""
    local x, y, w = ctx.x, ctx.y, ctx.w
    local bh = ctx.button_h

    -- Result box: text on top, its Morse under it.
    local box_h = math.floor(bh * 2.6)
    local box = { x = x, y = y, w = w, h = box_h }
    local text_line, morse_line
    if mode == "text" then
        text_line, morse_line = st.text or "", input
    else
        text_line, morse_line = (Morse.decode(input)), input
    end
    local tface = Draw.face(math.floor(bh * 0.5), true)
    local hint = _("Key in Morse with the dot and dash keys, or translate a text.")
    ctx.add{
        x = box.x, y = box.y, w = box.w, h = box.h,
        paint = function(bb, px, py, pw, ph)
            Draw.frame(bb, px, py, pw, ph, 2)
            local pad = 12
            if text_line == "" and morse_line == "" then
                local f = Draw.face(math.floor(bh * 0.36), false)
                local lines = Draw.wrap(hint, f, pw - 2 * pad)
                local lh = math.floor(ph / math.max(2, #lines + 1))
                for i, l in ipairs(lines) do
                    Draw.text(bb, l, f, px + pad, py + math.floor(lh / 2) + (i - 1) * lh, pw - 2 * pad, lh,
                        { color = Draw.DARK })
                end
                return
            end
            -- Text: one line, the end kept visible.
            local shown = text_line
            local tw = pw - 2 * pad
            while #shown > 0 and Draw.width(tface, shown, true) > tw do
                shown = shown:gsub("^[%z\1-\127\194-\244][\128-\191]*", "")
                if shown ~= text_line and Draw.width(tface, "…" .. shown, true) <= tw then
                    shown = "…" .. shown
                    break
                end
            end
            local text_h = math.floor(ph * 0.42)
            Draw.text(bb, shown, tface, px + pad, py + 4, tw, text_h, { bold = true, align = "left" })
            bb:paintRect(px + pad, py + text_h + 4, pw - 2 * pad, 1, Draw.GREY)
            local u = math.max(4, math.floor(bh / 9))
            paintMorseLines(Draw, bb, morse_line, px + pad, py + text_h + 8, pw - 2 * pad,
                ph - text_h - 10, u)
        end,
    }
    y = y + box_h + ctx.gap

    local function key(op)
        return function()
            local cur = (st.mode == "text") and "" or (st.input or "")
            setInput(ctx, Morse.key(cur, op), "key")
            -- Only the result box changed: a fast refresh of just that.
            ctx.screen:redraw("fast", box)
        end
    end
    y = Parts.buttonRow(ctx, y, {
        { label = "", tap = key("."), draw = function(bb, bx, by, bw, bh2)
            local r = math.floor(bh2 * 0.14)
            bb:paintCircle(bx + math.floor(bw / 2), by + math.floor(bh2 / 2), r, Draw.BLACK)
        end },
        { label = "", tap = key("-"), draw = function(bb, bx, by, bw, bh2)
            local u = math.floor(bh2 * 0.17)
            local lw = math.floor(bh2 * 0.9)
            bb:paintRect(bx + math.floor((bw - lw) / 2), by + math.floor((bh2 - u) / 2), lw, u, Draw.BLACK)
        end },
        { label = _("Letter"),    tap = key("letter") },
        { label = _("Word"),      tap = key("word") },
        { label = "⌫",            tap = key("back") },
    }, { px = math.floor(bh * 0.42) })
    y = Parts.buttonRow(ctx, y + 4, {
        { label = _("Text → Morse…"), tap = function()
            ctx.screen:askText(_("Text → Morse"), _("Text to translate"), st.text, function(text)
                local m, skipped = Morse.encode(text)
                st.text = text
                setInput(ctx, m, "text")
                ctx.screen:redraw()
                if skipped > 0 then
                    ctx.screen:showMessage(T(_("%1 character(s) have no Morse code and were left out."), skipped), 3)
                end
            end)
        end },
        { label = _("Clear"), tap = function()
            st.text = nil
            setInput(ctx, "", "key")
            ctx.screen:redraw("ui", box)
        end },
    }) + ctx.gap

    -- The table: letters and digits; a tap adds that letter.
    local list = Morse.ORDER
    local cols = ctx.landscape and 6 or 4
    local cells, cw, ch = Parts.cells(#list, cols, x, y, w, ctx.y + ctx.h - y)
    local u = math.max(3, math.min(math.floor(ch / 6), math.floor((cw * 0.66) / 21)))
    local lf = Draw.face(math.floor(math.min(ch * 0.6, cw * 0.2)), true)
    for i, ch_ in ipairs(list) do
        local c = cells[i]
        local code = Morse.CODES[ch_]
        ctx.add{
            x = c.x, y = c.y, w = c.w, h = c.h,
            paint = function(bb, px, py, pw, ph)
                bb:paintRect(px + 2, py + ph - 1, pw - 8, 1, Draw.GREY)
                local kw = math.floor(pw * 0.26)
                Draw.text(bb, ch_, lf, px + 2, py, kw, ph, { bold = true })
                paintCode(Draw, bb, code, px + kw + 6, py + math.floor(ph / 2), u)
            end,
            tap = function()
                local cur = (st.mode == "text") and "" or (st.input or "")
                setInput(ctx, Morse.appendCode(cur, code), "key")
                ctx.screen:redraw("fast", box)
            end,
        }
    end
end

return VIEW
