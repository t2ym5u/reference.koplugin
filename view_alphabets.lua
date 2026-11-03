-- view_alphabets.lua -- NATO/ICAO spelling alphabet and Greek alphabet.

local _ = require("i18n")
local T = require("ffi/util").template

local VIEW = {}

local function spellWord(ctx)
    local Lists = ctx.load("lists")
    ctx.screen:askText(_("Spell a word"), _("Word or name"), ctx.state.last_word, function(text)
        text = text:gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then return end
        ctx.state.last_word = text
        ctx.screen:saveViewState()
        local words = Lists.spell(text)
        local spelled = table.concat(words, " "):gsub(" / ", "\n")
        ctx.screen:showInfo(T("%1\n\n%2", text, spelled))
    end)
end

-- Letter + word cells.
local function addCells(ctx, Draw, Parts, list, cols, x, y, w, h, opts)
    local cells, cw, ch = Parts.cells(#list, cols, x, y, w, h)
    local big_px = math.floor(math.min(ch * 0.55, cw * 0.22))
    -- One size for the words, fitted to the longest.
    local word_px = math.floor(ch * 0.42)
    local word_w = cw - math.floor(cw * opts.key_frac) - 18
    for _i, it in ipairs(list) do
        local _f, p = Draw.fit(opts.word(it), word_px, word_w, false)
        word_px = math.min(word_px, p)
    end
    local key_w = math.floor(cw * opts.key_frac) - 8
    for _i, it in ipairs(list) do
        local _f, p = Draw.fit(opts.key(it), big_px, key_w, true)
        big_px = math.min(big_px, p)
    end
    local big = Draw.face(big_px, true)
    local small = Draw.face(word_px, false)
    for i, it in ipairs(list) do
        local c = cells[i]
        ctx.add{
            x = c.x, y = c.y, w = c.w, h = c.h,
            paint = function(bb, px, py, pw, ph)
                bb:paintRect(px, py + ph - 1, pw - 8, 1, Draw.GREY)
                local kw = math.floor(pw * opts.key_frac)
                Draw.text(bb, opts.key(it), big, px + 4, py, kw, ph, { bold = true, align = "left" })
                Draw.text(bb, opts.word(it), small, px + kw + 6, py, pw - kw - 8, ph, { align = "left" })
            end,
        }
    end
end

function VIEW.build(ctx)
    local Draw, Parts, Lists = ctx.load("draw"), ctx.load("parts"), ctx.load("lists")
    local tab, y = Parts.subTabs(ctx, {
        { id = "nato",  label = _("NATO alphabet") },
        { id = "greek", label = _("Greek alphabet") },
    }, "tab")
    local bottom = ctx.y + ctx.h
    local cols

    if tab == "nato" then
        local by = bottom - ctx.button_h
        Parts.buttonRow(ctx, by, { { label = _("Spell a word…"), tap = function() spellWord(ctx) end } })
        bottom = by - ctx.gap
        local list = {}
        for _i, p in ipairs(Lists.NATO) do list[#list + 1] = p end
        for _i, p in ipairs(Lists.NATO_DIGITS) do list[#list + 1] = p end
        cols = ctx.landscape and 4 or 3
        addCells(ctx, Draw, Parts, list, cols, ctx.x, y, ctx.w, bottom - y, {
            key_frac = 0.22,
            key  = function(p) return p[1] end,
            word = function(p) return p[2] end,
        })
    else
        local fr = ctx.lang == "fr"
        cols = ctx.landscape and 4 or 3
        addCells(ctx, Draw, Parts, Lists.GREEK, cols, ctx.x, y, ctx.w, bottom - y, {
            key_frac = 0.42,
            key  = function(g) return g[1] .. " " .. g[2] end,
            word = function(g) return fr and g[4] or g[3] end,
        })
    end
end

return VIEW
