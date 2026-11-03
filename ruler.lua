-- ruler.lua -- on-screen ruler maths. Pure Lua, no KOReader dependency.
--
-- The screen's DPI gives the nominal pixel pitch; a calibration factor
-- (`scale`, 1.0 = trust the DPI) corrects devices whose reported DPI is a
-- little off, or a DPI the user overrode in KOReader's settings.

local Ruler = {}

Ruler.MM_PER_INCH = 25.4
Ruler.MIN_SCALE   = 0.80
Ruler.MAX_SCALE   = 1.25
Ruler.STEP        = 0.002   -- one "fine" calibration step (0.2 %)

local function round(x, digits)
    local m = 10 ^ (digits or 0)
    return math.floor(x * m + 0.5) / m
end

function Ruler.clampScale(scale)
    scale = tonumber(scale) or 1
    if scale ~= scale then scale = 1 end -- NaN
    return math.max(Ruler.MIN_SCALE, math.min(Ruler.MAX_SCALE, scale))
end

function Ruler.pxPerMm(dpi, scale)
    return (tonumber(dpi) or 160) / Ruler.MM_PER_INCH * Ruler.clampScale(scale or 1)
end

-- scale after `steps` fine steps (negative = shorter), rounded to 4 digits
-- so repeated taps do not accumulate float noise.
function Ruler.adjust(scale, steps)
    return Ruler.clampScale(round(Ruler.clampScale(scale) + steps * Ruler.STEP, 4))
end

-- The user measured, with a real ruler, `measured_mm` for a span the screen
-- drew as `drawn_mm`: the factor that makes them agree.
function Ruler.calibrate(scale, drawn_mm, measured_mm)
    drawn_mm, measured_mm = tonumber(drawn_mm), tonumber(measured_mm)
    if not drawn_mm or not measured_mm or drawn_mm <= 0 or measured_mm <= 0 then
        return Ruler.clampScale(scale)
    end
    return Ruler.clampScale(round(Ruler.clampScale(scale) * measured_mm / drawn_mm, 4))
end

-- Millimetre ticks along `length_px`: { pos = px from 0, kind = "cm"|"half"|"mm",
-- label = cm number for "cm" ticks }.
function Ruler.cmTicks(length_px, ppmm)
    local ticks = {}
    local n = math.floor(length_px / ppmm + 1e-9)
    for mm = 0, n do
        local kind = (mm % 10 == 0) and "cm" or (mm % 5 == 0 and "half" or "mm")
        ticks[#ticks + 1] = {
            pos   = math.floor(mm * ppmm + 0.5),
            kind  = kind,
            label = kind == "cm" and tostring(math.floor(mm / 10)) or nil,
        }
    end
    return ticks
end

-- Inch ticks down to 1/16 inch (1/8 when 1/16 would be closer than
-- `min_gap` px): kind "in"|"half"|"quarter"|"eighth"|"sixteenth".
function Ruler.inchTicks(length_px, ppmm, min_gap)
    local ppi = ppmm * Ruler.MM_PER_INCH
    local div = (ppi / 16 >= (min_gap or 3)) and 16 or 8
    local ticks = {}
    local n = math.floor(length_px / ppi * div + 1e-9)
    for i = 0, n do
        local kind
        if i % div == 0 then kind = "in"
        elseif i % (div / 2) == 0 then kind = "half"
        elseif i % (div / 4) == 0 then kind = "quarter"
        elseif i % (div / 8) == 0 then kind = "eighth"
        else kind = "sixteenth" end
        ticks[#ticks + 1] = {
            pos   = math.floor(i * ppi / div + 0.5),
            kind  = kind,
            label = kind == "in" and tostring(math.floor(i / div)) or nil,
        }
    end
    return ticks
end

return Ruler
