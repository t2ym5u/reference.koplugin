-- elements.lua -- the 118 chemical elements. Pure data, no KOReader dependency;
-- loaded only when the periodic table is first opened.
--
-- Each row: { Z, symbol, English name, French name, mass, group, period, category }
--   mass     -- standard atomic weight (IUPAC conventional value) as a string;
--               "[n]" is the mass number of the longest-lived isotope of an
--               element with no stable isotope.
--   group    -- 1..18, or 0 for the f-block (lanthanides La-Lu, actinides Ac-Lr),
--               which sits in the two separate rows under the table.
--   category -- one of Elements.CATEGORIES.

local Elements = {}

Elements.CATEGORIES = {
    "alkali", "alkaline", "transition", "post_transition", "metalloid",
    "nonmetal", "noble", "lanthanide", "actinide", "unknown",
}

-- English labels (translated by the caller through i18n).
Elements.CATEGORY_LABELS = {
    alkali          = "Alkali metal",
    alkaline        = "Alkaline earth metal",
    transition      = "Transition metal",
    post_transition = "Post-transition metal",
    metalloid       = "Metalloid",
    nonmetal        = "Reactive nonmetal",
    noble           = "Noble gas",
    lanthanide      = "Lanthanide",
    actinide        = "Actinide",
    unknown         = "Unknown properties",
}

local A, AE, T, P, M, N, G, L, AC, U =
    "alkali", "alkaline", "transition", "post_transition", "metalloid",
    "nonmetal", "noble", "lanthanide", "actinide", "unknown"

local ROWS = {
    {   1, "H",  "Hydrogen",      "Hydrogène",     "1.008",    1, 1, N },
    {   2, "He", "Helium",        "Hélium",        "4.0026",  18, 1, G },
    {   3, "Li", "Lithium",       "Lithium",       "6.94",     1, 2, A },
    {   4, "Be", "Beryllium",     "Béryllium",     "9.0122",   2, 2, AE },
    {   5, "B",  "Boron",         "Bore",          "10.81",   13, 2, M },
    {   6, "C",  "Carbon",        "Carbone",       "12.011",  14, 2, N },
    {   7, "N",  "Nitrogen",      "Azote",         "14.007",  15, 2, N },
    {   8, "O",  "Oxygen",        "Oxygène",       "15.999",  16, 2, N },
    {   9, "F",  "Fluorine",      "Fluor",         "18.998",  17, 2, N },
    {  10, "Ne", "Neon",          "Néon",          "20.180",  18, 2, G },
    {  11, "Na", "Sodium",        "Sodium",        "22.990",   1, 3, A },
    {  12, "Mg", "Magnesium",     "Magnésium",     "24.305",   2, 3, AE },
    {  13, "Al", "Aluminium",     "Aluminium",     "26.982",  13, 3, P },
    {  14, "Si", "Silicon",       "Silicium",      "28.085",  14, 3, M },
    {  15, "P",  "Phosphorus",    "Phosphore",     "30.974",  15, 3, N },
    {  16, "S",  "Sulfur",        "Soufre",        "32.06",   16, 3, N },
    {  17, "Cl", "Chlorine",      "Chlore",        "35.45",   17, 3, N },
    {  18, "Ar", "Argon",         "Argon",         "39.95",   18, 3, G },
    {  19, "K",  "Potassium",     "Potassium",     "39.098",   1, 4, A },
    {  20, "Ca", "Calcium",       "Calcium",       "40.078",   2, 4, AE },
    {  21, "Sc", "Scandium",      "Scandium",      "44.956",   3, 4, T },
    {  22, "Ti", "Titanium",      "Titane",        "47.867",   4, 4, T },
    {  23, "V",  "Vanadium",      "Vanadium",      "50.942",   5, 4, T },
    {  24, "Cr", "Chromium",      "Chrome",        "51.996",   6, 4, T },
    {  25, "Mn", "Manganese",     "Manganèse",     "54.938",   7, 4, T },
    {  26, "Fe", "Iron",          "Fer",           "55.845",   8, 4, T },
    {  27, "Co", "Cobalt",        "Cobalt",        "58.933",   9, 4, T },
    {  28, "Ni", "Nickel",        "Nickel",        "58.693",  10, 4, T },
    {  29, "Cu", "Copper",        "Cuivre",        "63.546",  11, 4, T },
    {  30, "Zn", "Zinc",          "Zinc",          "65.38",   12, 4, T },
    {  31, "Ga", "Gallium",       "Gallium",       "69.723",  13, 4, P },
    {  32, "Ge", "Germanium",     "Germanium",     "72.630",  14, 4, M },
    {  33, "As", "Arsenic",       "Arsenic",       "74.922",  15, 4, M },
    {  34, "Se", "Selenium",      "Sélénium",      "78.971",  16, 4, N },
    {  35, "Br", "Bromine",       "Brome",         "79.904",  17, 4, N },
    {  36, "Kr", "Krypton",       "Krypton",       "83.798",  18, 4, G },
    {  37, "Rb", "Rubidium",      "Rubidium",      "85.468",   1, 5, A },
    {  38, "Sr", "Strontium",     "Strontium",     "87.62",    2, 5, AE },
    {  39, "Y",  "Yttrium",       "Yttrium",       "88.906",   3, 5, T },
    {  40, "Zr", "Zirconium",     "Zirconium",     "91.224",   4, 5, T },
    {  41, "Nb", "Niobium",       "Niobium",       "92.906",   5, 5, T },
    {  42, "Mo", "Molybdenum",    "Molybdène",     "95.95",    6, 5, T },
    {  43, "Tc", "Technetium",    "Technétium",    "[98]",     7, 5, T },
    {  44, "Ru", "Ruthenium",     "Ruthénium",     "101.07",   8, 5, T },
    {  45, "Rh", "Rhodium",       "Rhodium",       "102.91",   9, 5, T },
    {  46, "Pd", "Palladium",     "Palladium",     "106.42",  10, 5, T },
    {  47, "Ag", "Silver",        "Argent",        "107.87",  11, 5, T },
    {  48, "Cd", "Cadmium",       "Cadmium",       "112.41",  12, 5, T },
    {  49, "In", "Indium",        "Indium",        "114.82",  13, 5, P },
    {  50, "Sn", "Tin",           "Étain",         "118.71",  14, 5, P },
    {  51, "Sb", "Antimony",      "Antimoine",     "121.76",  15, 5, M },
    {  52, "Te", "Tellurium",     "Tellure",       "127.60",  16, 5, M },
    {  53, "I",  "Iodine",        "Iode",          "126.90",  17, 5, N },
    {  54, "Xe", "Xenon",         "Xénon",         "131.29",  18, 5, G },
    {  55, "Cs", "Caesium",       "Césium",        "132.91",   1, 6, A },
    {  56, "Ba", "Barium",        "Baryum",        "137.33",   2, 6, AE },
    {  57, "La", "Lanthanum",     "Lanthane",      "138.91",   0, 6, L },
    {  58, "Ce", "Cerium",        "Cérium",        "140.12",   0, 6, L },
    {  59, "Pr", "Praseodymium",  "Praséodyme",    "140.91",   0, 6, L },
    {  60, "Nd", "Neodymium",     "Néodyme",       "144.24",   0, 6, L },
    {  61, "Pm", "Promethium",    "Prométhium",    "[145]",    0, 6, L },
    {  62, "Sm", "Samarium",      "Samarium",      "150.36",   0, 6, L },
    {  63, "Eu", "Europium",      "Europium",      "151.96",   0, 6, L },
    {  64, "Gd", "Gadolinium",    "Gadolinium",    "157.25",   0, 6, L },
    {  65, "Tb", "Terbium",       "Terbium",       "158.93",   0, 6, L },
    {  66, "Dy", "Dysprosium",    "Dysprosium",    "162.50",   0, 6, L },
    {  67, "Ho", "Holmium",       "Holmium",       "164.93",   0, 6, L },
    {  68, "Er", "Erbium",        "Erbium",        "167.26",   0, 6, L },
    {  69, "Tm", "Thulium",       "Thulium",       "168.93",   0, 6, L },
    {  70, "Yb", "Ytterbium",     "Ytterbium",     "173.05",   0, 6, L },
    {  71, "Lu", "Lutetium",      "Lutécium",      "174.97",   0, 6, L },
    {  72, "Hf", "Hafnium",       "Hafnium",       "178.49",   4, 6, T },
    {  73, "Ta", "Tantalum",      "Tantale",       "180.95",   5, 6, T },
    {  74, "W",  "Tungsten",      "Tungstène",     "183.84",   6, 6, T },
    {  75, "Re", "Rhenium",       "Rhénium",       "186.21",   7, 6, T },
    {  76, "Os", "Osmium",        "Osmium",        "190.23",   8, 6, T },
    {  77, "Ir", "Iridium",       "Iridium",       "192.22",   9, 6, T },
    {  78, "Pt", "Platinum",      "Platine",       "195.08",  10, 6, T },
    {  79, "Au", "Gold",          "Or",            "196.97",  11, 6, T },
    {  80, "Hg", "Mercury",       "Mercure",       "200.59",  12, 6, T },
    {  81, "Tl", "Thallium",      "Thallium",      "204.38",  13, 6, P },
    {  82, "Pb", "Lead",          "Plomb",         "207.2",   14, 6, P },
    {  83, "Bi", "Bismuth",       "Bismuth",       "208.98",  15, 6, P },
    {  84, "Po", "Polonium",      "Polonium",      "[209]",   16, 6, P },
    {  85, "At", "Astatine",      "Astate",        "[210]",   17, 6, M },
    {  86, "Rn", "Radon",         "Radon",         "[222]",   18, 6, G },
    {  87, "Fr", "Francium",      "Francium",      "[223]",    1, 7, A },
    {  88, "Ra", "Radium",        "Radium",        "[226]",    2, 7, AE },
    {  89, "Ac", "Actinium",      "Actinium",      "[227]",    0, 7, AC },
    {  90, "Th", "Thorium",       "Thorium",       "232.04",   0, 7, AC },
    {  91, "Pa", "Protactinium",  "Protactinium",  "231.04",   0, 7, AC },
    {  92, "U",  "Uranium",       "Uranium",       "238.03",   0, 7, AC },
    {  93, "Np", "Neptunium",     "Neptunium",     "[237]",    0, 7, AC },
    {  94, "Pu", "Plutonium",     "Plutonium",     "[244]",    0, 7, AC },
    {  95, "Am", "Americium",     "Américium",     "[243]",    0, 7, AC },
    {  96, "Cm", "Curium",        "Curium",        "[247]",    0, 7, AC },
    {  97, "Bk", "Berkelium",     "Berkélium",     "[247]",    0, 7, AC },
    {  98, "Cf", "Californium",   "Californium",   "[251]",    0, 7, AC },
    {  99, "Es", "Einsteinium",   "Einsteinium",   "[252]",    0, 7, AC },
    { 100, "Fm", "Fermium",       "Fermium",       "[257]",    0, 7, AC },
    { 101, "Md", "Mendelevium",   "Mendélévium",   "[258]",    0, 7, AC },
    { 102, "No", "Nobelium",      "Nobélium",      "[259]",    0, 7, AC },
    { 103, "Lr", "Lawrencium",    "Lawrencium",    "[266]",    0, 7, AC },
    { 104, "Rf", "Rutherfordium", "Rutherfordium", "[267]",    4, 7, T },
    { 105, "Db", "Dubnium",       "Dubnium",       "[268]",    5, 7, T },
    { 106, "Sg", "Seaborgium",    "Seaborgium",    "[269]",    6, 7, T },
    { 107, "Bh", "Bohrium",       "Bohrium",       "[270]",    7, 7, T },
    { 108, "Hs", "Hassium",       "Hassium",       "[269]",    8, 7, T },
    { 109, "Mt", "Meitnerium",    "Meitnérium",    "[278]",    9, 7, U },
    { 110, "Ds", "Darmstadtium",  "Darmstadtium",  "[281]",   10, 7, U },
    { 111, "Rg", "Roentgenium",   "Roentgenium",   "[282]",   11, 7, U },
    { 112, "Cn", "Copernicium",   "Copernicium",   "[285]",   12, 7, U },
    { 113, "Nh", "Nihonium",      "Nihonium",      "[286]",   13, 7, U },
    { 114, "Fl", "Flerovium",     "Flérovium",     "[289]",   14, 7, U },
    { 115, "Mc", "Moscovium",     "Moscovium",     "[290]",   15, 7, U },
    { 116, "Lv", "Livermorium",   "Livermorium",   "[293]",   16, 7, U },
    { 117, "Ts", "Tennessine",    "Tennesse",      "[294]",   17, 7, U },
    { 118, "Og", "Oganesson",     "Oganesson",     "[294]",   18, 7, U },
}

Elements.list = {}
for i, r in ipairs(ROWS) do
    Elements.list[i] = {
        z = r[1], symbol = r[2], name_en = r[3], name_fr = r[4],
        mass = r[5], group = r[6], period = r[7], category = r[8],
    }
end
ROWS = nil

function Elements.get(z)
    return Elements.list[z]
end

-- Numeric value of a mass string ("55.845" -> 55.845, "[98]" -> 98).
function Elements.massValue(e)
    return tonumber((e.mass:gsub("[%[%]]", "")))
end

-- True when the element has no stable isotope (mass given in brackets).
function Elements.isRadioactiveOnly(e)
    return e.mass:sub(1, 1) == "["
end

-- Mass formatted for a language: French uses a decimal comma.
function Elements.formatMass(e, lang)
    if lang == "fr" then return (e.mass:gsub("%.", ",")) end
    return e.mass
end

function Elements.block(e)
    if e.group == 0 then return "f" end
    if e.group <= 2 or e.z == 2 then return "s" end
    if e.group <= 12 then return "d" end
    return "p"
end

-- Position on the displayed table: col 1..18, row 1..7 for the main body,
-- rows 9 and 10 for the lanthanide / actinide rows (row 8 is a spacer).
-- La..Lu fill columns 3..17 of row 9, Ac..Lr of row 10.
function Elements.position(e)
    if e.group ~= 0 then return e.group, e.period end
    if e.period == 6 then return 3 + (e.z - 57), 9 end
    return 3 + (e.z - 89), 10
end

-- Element at a table position, or nil (built lazily).
local by_pos
function Elements.at(col, row)
    if not by_pos then
        by_pos = {}
        for _, e in ipairs(Elements.list) do
            local c, r = Elements.position(e)
            by_pos[r * 100 + c] = e
        end
    end
    return by_pos[row * 100 + col]
end

return Elements
