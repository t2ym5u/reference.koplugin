-- morse.lua -- International (ITU) Morse code: table, text -> Morse and
-- Morse -> text. Pure Lua, no KOReader dependency.
--
-- Morse strings use "." and "-", one space between letters and " / "
-- between words. Accented Latin letters are folded to their base letter
-- (é -> E, ç -> C, œ -> OE) before encoding, as a radio operator would;
-- any other character has no Morse code and is skipped (and counted).

local Morse = {}

Morse.CODES = {
    A = ".-",    B = "-...",  C = "-.-.",  D = "-..",   E = ".",     F = "..-.",
    G = "--.",   H = "....",  I = "..",    J = ".---",  K = "-.-",   L = ".-..",
    M = "--",    N = "-.",    O = "---",   P = ".--.",  Q = "--.-",  R = ".-.",
    S = "...",   T = "-",     U = "..-",   V = "...-",  W = ".--",   X = "-..-",
    Y = "-.--",  Z = "--..",
    ["0"] = "-----", ["1"] = ".----", ["2"] = "..---", ["3"] = "...--",
    ["4"] = "....-", ["5"] = ".....", ["6"] = "-....", ["7"] = "--...",
    ["8"] = "---..", ["9"] = "----.",
    ["."] = ".-.-.-", [","] = "--..--", ["?"] = "..--..", ["'"] = ".----.",
    ["!"] = "-.-.--", ["/"] = "-..-.",  ["("] = "-.--.",  [")"] = "-.--.-",
    ["&"] = ".-...",  [":"] = "---...", [";"] = "-.-.-.", ["="] = "-...-",
    ["+"] = ".-.-.",  ["-"] = "-....-", ["_"] = "..--.-", ['"'] = ".-..-.",
    ["$"] = "...-..-", ["@"] = ".--.-.",
}

-- Display order of the reference table.
Morse.ORDER = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
    "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
}
Morse.PUNCTUATION = { ".", ",", "?", "'", "!", "/", "(", ")", "&", ":", ";", "=", "+", "-", "\"", "@" }

-- Shown in place of a Morse group that is no letter at all.
Morse.UNKNOWN = "*"

local DECODE = {}
for ch, code in pairs(Morse.CODES) do DECODE[code] = ch end

-- UTF-8 accented letters -> plain upper-case letters.
local FOLD = {}
for plain, accented in pairs({
    A = "àáâãäåÀÁÂÃÄÅ", C = "çÇ", E = "èéêëÈÉÊË", I = "ìíîïÌÍÎÏ", N = "ñÑ",
    O = "òóôõöøÒÓÔÕÖØ", U = "ùúûüÙÚÛÜ", Y = "ýÿÝ",
}) do
    for ch in accented:gmatch("[\xC0-\xDF][\x80-\xBF]") do FOLD[ch] = plain end
end
FOLD["œ"], FOLD["Œ"], FOLD["æ"], FOLD["Æ"], FOLD["ß"] = "OE", "OE", "AE", "AE", "SS"
-- Typographic quotes and dashes a keyboard may produce.
FOLD["’"], FOLD["‘"], FOLD["“"], FOLD["”"], FOLD["«"], FOLD["»"] = "'", "'", '"', '"', '"', '"'
FOLD["–"], FOLD["—"] = "-", "-"

local function utf8chars(s)
    return s:gmatch("[%z\1-\127\194-\244][\128-\191]*")
end

-- Text -> Morse. Returns the Morse string and the number of characters
-- that had no code and were skipped.
function Morse.encode(text)
    local words, skipped = {}, 0
    local word = {}
    local function flush()
        if #word > 0 then words[#words + 1] = table.concat(word, " ") end
        word = {}
    end
    for ch in utf8chars(text or "") do
        if ch:match("^%s$") then
            flush()
        else
            local folded = FOLD[ch] or ch:upper()
            for c in folded:gmatch(".") do
                local code = Morse.CODES[c]
                if code then word[#word + 1] = code else skipped = skipped + 1 end
            end
        end
    end
    flush()
    return table.concat(words, " / "), skipped
end

-- Normalises the dot/dash look-alikes people type or paste.
function Morse.normalize(s)
    s = s or ""
    s = s:gsub("·", "."):gsub("•", "."):gsub("∙", ".")
         :gsub("−", "-"):gsub("–", "-"):gsub("—", "-"):gsub("_", "-")
    return s
end

-- Morse -> text. Letters are separated by spaces, words by "/" (or three
-- or more spaces). Unknown groups decode to Morse.UNKNOWN; the second
-- return value counts them.
function Morse.decode(morse)
    local s = Morse.normalize(morse)
    s = s:gsub("%s%s%s+", " / ")
    local out, unknown = {}, 0
    for word in (s .. "/"):gmatch("([^/]*)/") do
        local letters = {}
        for code in word:gmatch("%S+") do
            local ch = DECODE[code]
            if not ch then
                ch = Morse.UNKNOWN
                unknown = unknown + 1
            end
            letters[#letters + 1] = ch
        end
        if #letters > 0 then out[#out + 1] = table.concat(letters) end
    end
    return table.concat(out, " "), unknown
end

-- On-screen keying: applies one key to the Morse being typed and returns
-- the new string. op: "." / "-" (a signal), "letter" (end of letter),
-- "word" (end of word), "back" (undo the last key), "clear".
function Morse.key(input, op)
    input = input or ""
    if op == "." or op == "-" then
        return input .. op
    elseif op == "letter" then
        if input == "" or input:sub(-1) == " " then return input end
        return input .. " "
    elseif op == "word" then
        local s = input:gsub("%s+$", "")
        if s == "" or s:sub(-1) == "/" then return s == "" and "" or s .. " " end
        return s .. " / "
    elseif op == "back" then
        if input:sub(-3) == " / " then return input:sub(1, -4) end
        return input:sub(1, -2)
    elseif op == "clear" then
        return ""
    end
    return input
end

-- Appends a whole letter's code (a tap on the table) as a finished letter.
function Morse.appendCode(input, code)
    input = input or ""
    if input ~= "" and input:sub(-1) ~= " " then input = input .. " " end
    return input .. code .. " "
end

function Morse.lookup(code)
    return DECODE[code]
end

return Morse
