-- lists.lua -- small reference lists: NATO/ICAO spelling alphabet, Greek
-- alphabet, SI prefixes, and number tables. Pure Lua, no KOReader dependency.

local Lists = {}

-- ICAO / NATO radiotelephony alphabet (official ICAO spellings: Alfa, Juliett).
Lists.NATO = {
    { "A", "Alfa" },    { "B", "Bravo" },   { "C", "Charlie" },  { "D", "Delta" },
    { "E", "Echo" },    { "F", "Foxtrot" }, { "G", "Golf" },     { "H", "Hotel" },
    { "I", "India" },   { "J", "Juliett" }, { "K", "Kilo" },     { "L", "Lima" },
    { "M", "Mike" },    { "N", "November" },{ "O", "Oscar" },    { "P", "Papa" },
    { "Q", "Quebec" },  { "R", "Romeo" },   { "S", "Sierra" },   { "T", "Tango" },
    { "U", "Uniform" }, { "V", "Victor" },  { "W", "Whiskey" },  { "X", "X-ray" },
    { "Y", "Yankee" },  { "Z", "Zulu" },
}

-- ICAO pronunciation of the digits.
Lists.NATO_DIGITS = {
    { "0", "Zero" }, { "1", "One" },  { "2", "Two" },   { "3", "Tree" },  { "4", "Fower" },
    { "5", "Fife" }, { "6", "Six" },  { "7", "Seven" }, { "8", "Eight" }, { "9", "Niner" },
}

local NATO_BY_CHAR
-- Code words for each letter/digit of `text` (accents folded, other
-- characters kept as they are). Returns a list of strings.
function Lists.spell(text)
    if not NATO_BY_CHAR then
        NATO_BY_CHAR = {}
        for _, p in ipairs(Lists.NATO) do NATO_BY_CHAR[p[1]] = p[2] end
        for _, p in ipairs(Lists.NATO_DIGITS) do NATO_BY_CHAR[p[1]] = p[2] end
    end
    local FOLD = {
        ["à"]="A",["â"]="A",["ä"]="A",["á"]="A",["ç"]="C",["é"]="E",["è"]="E",["ê"]="E",["ë"]="E",
        ["î"]="I",["ï"]="I",["í"]="I",["ô"]="O",["ö"]="O",["ó"]="O",["ù"]="U",["û"]="U",["ü"]="U",
        ["ú"]="U",["ÿ"]="Y",["ñ"]="N",["À"]="A",["Â"]="A",["Ç"]="C",["É"]="E",["È"]="E",["Ê"]="E",
        ["Î"]="I",["Ô"]="O",["Ù"]="U",["Û"]="U",["Ü"]="U",["Ñ"]="N",
    }
    local out = {}
    for ch in (text or ""):gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        local key = FOLD[ch] or ch:upper()
        if NATO_BY_CHAR[key] then
            out[#out + 1] = NATO_BY_CHAR[key]
        elseif ch:match("^%s$") then
            if #out > 0 and out[#out] ~= "/" then out[#out + 1] = "/" end
        else
            out[#out + 1] = ch
        end
    end
    if out[#out] == "/" then out[#out] = nil end
    return out
end

-- Greek alphabet: upper, lower, English name, French name.
Lists.GREEK = {
    { "Α", "α", "alpha",   "alpha" },   { "Β", "β", "beta",    "bêta" },
    { "Γ", "γ", "gamma",   "gamma" },   { "Δ", "δ", "delta",   "delta" },
    { "Ε", "ε", "epsilon", "epsilon" }, { "Ζ", "ζ", "zeta",    "zêta" },
    { "Η", "η", "eta",     "êta" },     { "Θ", "θ", "theta",   "thêta" },
    { "Ι", "ι", "iota",    "iota" },    { "Κ", "κ", "kappa",   "kappa" },
    { "Λ", "λ", "lambda",  "lambda" },  { "Μ", "μ", "mu",      "mu" },
    { "Ν", "ν", "nu",      "nu" },      { "Ξ", "ξ", "xi",      "xi" },
    { "Ο", "ο", "omicron", "omicron" }, { "Π", "π", "pi",      "pi" },
    { "Ρ", "ρ", "rho",     "rhô" },     { "Σ", "σ", "sigma",   "sigma" },
    { "Τ", "τ", "tau",     "tau" },     { "Υ", "υ", "upsilon", "upsilon" },
    { "Φ", "φ", "phi",     "phi" },     { "Χ", "χ", "chi",     "khi" },
    { "Ψ", "ψ", "psi",     "psi" },     { "Ω", "ω", "omega",   "oméga" },
}

-- SI prefixes (BIPM, incl. ronna/quetta/ronto/quecto of 2022):
-- symbol, English name, French name, power of ten.
Lists.SI = {
    { "Q",  "quetta", "quetta",  30 }, { "R",  "ronna", "ronna",  27 },
    { "Y",  "yotta",  "yotta",   24 }, { "Z",  "zetta", "zetta",  21 },
    { "E",  "exa",    "exa",     18 }, { "P",  "peta",  "péta",   15 },
    { "T",  "tera",   "téra",    12 }, { "G",  "giga",  "giga",    9 },
    { "M",  "mega",   "méga",     6 }, { "k",  "kilo",  "kilo",    3 },
    { "h",  "hecto",  "hecto",    2 }, { "da", "deca",  "déca",    1 },
    { "d",  "deci",   "déci",    -1 }, { "c",  "centi", "centi",  -2 },
    { "m",  "milli",  "milli",   -3 }, { "µ",  "micro", "micro",  -6 },
    { "n",  "nano",   "nano",    -9 }, { "p",  "pico",  "pico",  -12 },
    { "f",  "femto",  "femto",  -15 }, { "a",  "atto",  "atto",  -18 },
    { "z",  "zepto",  "zepto",  -21 }, { "y",  "yocto", "yocto", -24 },
    { "r",  "ronto",  "ronto",  -27 }, { "q",  "quecto","quecto",-30 },
}

local SUPER = { ["0"]="⁰",["1"]="¹",["2"]="²",["3"]="³",["4"]="⁴",["5"]="⁵",
                ["6"]="⁶",["7"]="⁷",["8"]="⁸",["9"]="⁹",["-"]="⁻" }

-- "10³", "10⁻¹²"
function Lists.powerOfTen(n)
    return "10" .. tostring(n):gsub(".", SUPER)
end

-- Plain-number form of 10^n for |n| <= 3 ("1 000", "0,01"), nil beyond.
function Lists.decimalForm(n, lang)
    if n > 3 or n < -3 then return nil end
    local sep = lang == "fr" and "," or "."
    local thousand = lang == "fr" and "\194\160" or ","
    if n >= 0 then
        local s = "1" .. string.rep("0", n)
        if n == 3 then s = "1" .. thousand .. "000" end
        return s
    end
    return "0" .. sep .. string.rep("0", -n - 1) .. "1"
end

-- Groups digits by thousands: 1048576 -> "1 048 576" (fr, no-break space) /
-- "1,048,576" (en).
function Lists.groupDigits(n, lang)
    local s = tostring(math.floor(n))
    local sep = lang == "fr" and "\194\160" or ","
    local out = s:reverse():gsub("(%d%d%d)", "%1" .. sep:reverse()):reverse()
    if out:sub(1, #sep) == sep then out = out:sub(#sep + 1) end
    return out
end

-- Rows of the powers table: { n, n², n³, 2ⁿ } for n = 1..count.
function Lists.powers(count)
    local rows = {}
    for n = 1, count do
        rows[n] = { n, n * n, n * n * n, 2 ^ n }
    end
    return rows
end

return Lists
