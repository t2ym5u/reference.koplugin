-- Specs for the pure-logic modules of reference.koplugin (no KOReader needed).
local DIR = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") or "./"
package.path = DIR .. "?.lua;" .. package.path

local Elements = dofile(DIR .. "elements.lua")
local Morse    = dofile(DIR .. "morse.lua")
local Ruler    = dofile(DIR .. "ruler.lua")
local Lists    = dofile(DIR .. "lists.lua")

describe("Elements", function()
    it("has 118 contiguous elements", function()
        assert.are.equal(118, #Elements.list)
        for z, e in ipairs(Elements.list) do assert.are.equal(z, e.z) end
    end)

    it("has unique, well-formed symbols", function()
        local seen = {}
        for _, e in ipairs(Elements.list) do
            assert.is_truthy(e.symbol:match("^%u%l?$"), e.symbol)
            assert.is_nil(seen[e.symbol], e.symbol)
            seen[e.symbol] = true
        end
    end)

    it("has English and French names", function()
        for _, e in ipairs(Elements.list) do
            assert.is_true(#e.name_en > 0 and #e.name_fr > 0, tostring(e.z))
        end
    end)

    it("has valid groups, periods and categories", function()
        local cats = {}
        for _, c in ipairs(Elements.CATEGORIES) do cats[c] = true end
        for _, e in ipairs(Elements.list) do
            assert.is_true(e.period >= 1 and e.period <= 7, e.symbol)
            assert.is_true(e.group >= 0 and e.group <= 18, e.symbol)
            assert.is_true(cats[e.category], e.symbol)
            assert.is_truthy(Elements.CATEGORY_LABELS[e.category])
            if e.group == 0 then
                assert.is_true((e.z >= 57 and e.z <= 71) or (e.z >= 89 and e.z <= 103), e.symbol)
            end
        end
    end)

    it("matches the period lengths 2, 8, 8, 18, 18, 32, 32", function()
        local count = {}
        for _, e in ipairs(Elements.list) do count[e.period] = (count[e.period] or 0) + 1 end
        assert.are.same({ 2, 8, 8, 18, 18, 32, 32 }, count)
    end)

    it("has masses that mostly increase", function()
        local prev = 0
        for _, e in ipairs(Elements.list) do
            local m = Elements.massValue(e)
            assert.is_number(m, e.symbol)
            -- Ar/K, Co/Ni, Te/I, Th/Pa, U/Np... dip by about one unit at most.
            assert.is_true(m > prev - 1.5, e.symbol)
            assert.is_true(m > e.z, e.symbol)  -- heavier than its protons alone (H aside)
            prev = m
        end
    end)

    it("spot-checks known elements", function()
        local fe = Elements.get(26)
        assert.are.same({ "Fe", "Iron", "Fer", "55.845", 8, 4, "transition" },
            { fe.symbol, fe.name_en, fe.name_fr, fe.mass, fe.group, fe.period, fe.category })
        assert.are.equal("Og", Elements.get(118).symbol)
        assert.are.equal("noble", Elements.get(2).category)
        assert.are.equal("Azote", Elements.get(7).name_fr)
        assert.are.equal("Tungstène", Elements.get(74).name_fr)
        assert.is_true(Elements.isRadioactiveOnly(Elements.get(43)))
        assert.is_false(Elements.isRadioactiveOnly(Elements.get(83)))
        assert.are.equal("55,845", Elements.formatMass(fe, "fr"))
        assert.are.equal("d", Elements.block(fe))
        assert.are.equal("s", Elements.block(Elements.get(2)))
        assert.are.equal("f", Elements.block(Elements.get(92)))
        assert.are.equal("p", Elements.block(Elements.get(82)))
    end)

    it("places every element on its own table cell", function()
        local used = {}
        for _, e in ipairs(Elements.list) do
            local c, r = Elements.position(e)
            assert.is_true(c >= 1 and c <= 18 and r >= 1 and r <= 10 and r ~= 8, e.symbol)
            local k = r * 100 + c
            assert.is_nil(used[k], e.symbol)
            used[k] = true
            assert.are.equal(e, Elements.at(c, r))
        end
        assert.are.equal("Lu", Elements.at(17, 9).symbol)
        assert.are.equal("Lr", Elements.at(17, 10).symbol)
        assert.is_nil(Elements.at(3, 6))   -- the "57-71" placeholder
    end)
end)

describe("Morse", function()
    it("encodes SOS and words", function()
        assert.are.equal("... --- ...", Morse.encode("SOS"))
        assert.are.equal("... --- ...", Morse.encode("sos"))
        assert.are.equal(".... .. / -- --- --", Morse.encode("Hi  mom"))
        assert.are.equal("..--..", Morse.encode("?"))
    end)

    it("folds accented letters", function()
        assert.are.equal(Morse.encode("ETE"), Morse.encode("été"))
        assert.are.equal(Morse.encode("COEUR"), Morse.encode("cœur"))
        assert.are.equal(Morse.encode("CA"), Morse.encode("ÇA"))
    end)

    it("skips characters it cannot encode and counts them", function()
        local m, skipped = Morse.encode("A#B")
        assert.are.equal(".- -...", m)
        assert.are.equal(1, skipped)
    end)

    it("round-trips every table character", function()
        local all = table.concat(Morse.ORDER) .. table.concat(Morse.PUNCTUATION)
        local text, unknown = Morse.decode(Morse.encode(all))
        assert.are.equal(all, text)
        assert.are.equal(0, unknown)
        assert.are.equal("HELLO WORLD 2026", Morse.decode(Morse.encode("Hello world 2026")))
    end)

    it("decodes look-alike dots and dashes and wide gaps", function()
        assert.are.equal("SOS", Morse.decode("··· −−− ···"))
        assert.are.equal("E T", Morse.decode(".   -"))
        assert.are.equal("E T", Morse.decode(". / -"))
    end)

    it("marks unknown groups", function()
        local text, unknown = Morse.decode("...... .-")
        assert.are.equal(Morse.UNKNOWN .. "A", text)
        assert.are.equal(1, unknown)
        assert.are.equal("", (Morse.decode("")))
    end)

    it("keys Morse in on screen", function()
        local s = ""
        for _, op in ipairs({ ".", ".", ".", "letter", "letter", "-", "-", "-", "word", "word", ".", "-" }) do
            s = Morse.key(s, op)
        end
        assert.are.equal("... --- / .-", s)
        assert.are.equal("SO A", Morse.decode(s))
        s = Morse.key(Morse.key(s, "back"), "back")
        assert.are.equal("... --- / ", s)
        assert.are.equal("... ---", Morse.key(s, "back"))
        assert.are.equal("", Morse.key(s, "clear"))
        assert.are.equal("", Morse.key("", "word"))
        assert.are.equal("... --- ... ", Morse.appendCode("... ---", "..."))
    end)

    it("has distinct codes", function()
        local seen = {}
        for ch, code in pairs(Morse.CODES) do
            assert.is_nil(seen[code], ch)
            seen[code] = ch
        end
    end)
end)

describe("Ruler", function()
    it("converts the DPI to pixels per millimetre", function()
        assert.is_true(math.abs(Ruler.pxPerMm(254, 1) - 10) < 1e-9)
        assert.is_true(math.abs(Ruler.pxPerMm(212, 1) - 8.3465) < 1e-3)
        assert.is_true(math.abs(Ruler.pxPerMm(254, 1.1) - 11) < 1e-9)
    end)

    it("clamps the calibration factor", function()
        assert.are.equal(Ruler.MAX_SCALE, Ruler.clampScale(3))
        assert.are.equal(Ruler.MIN_SCALE, Ruler.clampScale(0.1))
        assert.are.equal(1, Ruler.clampScale("junk"))
        assert.are.equal(1, Ruler.clampScale(0 / 0))
    end)

    it("adjusts in fine steps without drift", function()
        local s = 1
        for _ = 1, 10 do s = Ruler.adjust(s, 1) end
        assert.are.equal(1.02, s)
        for _ = 1, 10 do s = Ruler.adjust(s, -1) end
        assert.are.equal(1, s)
    end)

    it("calibrates from a measurement", function()
        -- 100 mm drawn measured as 98 mm: the drawing must grow by 100/98.
        local s = Ruler.calibrate(1, 100, 98)
        assert.is_true(math.abs(s - 0.98) < 1e-4)
        -- then 100 mm really is 100 mm
        assert.is_true(math.abs(100 * Ruler.pxPerMm(212, 1) * 0.98 / Ruler.pxPerMm(212, s) - 100) < 0.01)
        assert.are.equal(1.1, Ruler.calibrate(1.1, 100, 0))
    end)

    it("lays out centimetre ticks", function()
        local t = Ruler.cmTicks(100, 10)  -- 10 px/mm, 10 mm
        assert.are.equal(11, #t)
        assert.are.same({ pos = 0, kind = "cm", label = "0" }, t[1])
        assert.are.equal("half", t[6].kind)
        assert.are.same({ pos = 100, kind = "cm", label = "1" }, t[11])
    end)

    it("lays out inch ticks, dropping sixteenths when too dense", function()
        local ppmm = 254 / 25.4 -- 254 px per inch
        local t = Ruler.inchTicks(254, ppmm)
        assert.are.equal(17, #t)
        assert.are.equal("half", t[9].kind)
        assert.are.equal("1", t[17].label)
        local coarse = Ruler.inchTicks(40, 40 / 25.4, 3) -- 40 ppi: 1/16 = 2.5 px
        assert.are.equal(9, #coarse)
    end)
end)

describe("Lists", function()
    it("has the full alphabets", function()
        assert.are.equal(26, #Lists.NATO)
        assert.are.equal(24, #Lists.GREEK)
        assert.are.equal(24, #Lists.SI)
        assert.are.equal("Juliett", Lists.NATO[10][2])
    end)

    it("spells a word", function()
        assert.are.same({ "Echo", "Tango", "Echo", "/", "Two" }, Lists.spell("été 2"))
    end)

    it("formats powers and numbers", function()
        assert.are.equal("10⁻¹²", Lists.powerOfTen(-12))
        assert.are.equal("10³⁰", Lists.powerOfTen(30))
        assert.are.equal("1,048,576", Lists.groupDigits(1048576, "en"))
        assert.are.equal("1\194\160048\194\160576", Lists.groupDigits(1048576, "fr"))
        assert.are.equal("100", Lists.groupDigits(100, "en"))
        assert.are.equal("0,001", Lists.decimalForm(-3, "fr"))
        assert.are.equal("1,000", Lists.decimalForm(3, "en"))
        assert.is_nil(Lists.decimalForm(6, "en"))
        assert.are.same({ 12, 144, 1728, 4096 }, Lists.powers(12)[12])
    end)
end)
