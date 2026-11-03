-- French (plus Spanish and German) strings of reference.koplugin, merged into
-- the shared i18n table by main.lua. "Clear" and "Settings" come from
-- game-common's i18n.lua; the generic keys repeated here (Cancel, OK, Help,
-- Reset, Word) use the exact translations other plugins already give them.
return {
    ["Quick reference"] = { fr = "Aide-mémoire", es = "Referencia rápida", de = "Kurzreferenz" },
    ["Periodic table, radio, Greek and Morse alphabets, multiplication tables, SI prefixes and an on-screen ruler."] = { fr = "Tableau périodique, alphabets radio, grec et Morse, tables de multiplication, préfixes SI et règle à l'écran.", es = "Tabla periódica, alfabetos radiofónico, griego y Morse, tablas de multiplicar, prefijos SI y regla en pantalla.", de = "Periodensystem, Funk-, griechisches und Morsealphabet, Einmaleins, SI-Präfixe und Lineal auf dem Bildschirm." },

    -- Generic (same translations as elsewhere in the fleet)
    ["Cancel"] = { fr = "Annuler", es = "Cancelar", de = "Abbrechen" },
    ["OK"]     = { fr = "OK", es = "OK", de = "OK" },
    ["Help"]   = { fr = "Aide", es = "Ayuda", de = "Hilfe" },
    ["Reset"]  = { fr = "Réinitialiser", es = "Reiniciar", de = "Zurücksetzen" },
    ["Word"]   = { fr = "Mot", es = "Palabra", de = "Wort" },

    -- Sections (tabs) and menu
    ["Elements"]  = { fr = "Éléments", es = "Elementos", de = "Elemente" },
    ["Alphabets"] = { fr = "Alphabets", es = "Alfabetos", de = "Alphabete" },
    ["Morse"]     = { fr = "Morse", es = "Morse", de = "Morse" },
    ["Tables"]    = { fr = "Tables", es = "Tablas", de = "Tabellen" },
    ["Ruler"]     = { fr = "Règle", es = "Regla", de = "Lineal" },
    ["Periodic table"]          = { fr = "Tableau périodique", es = "Tabla periódica", de = "Periodensystem" },
    ["Radio & Greek alphabets"] = { fr = "Alphabets radio et grec", es = "Alfabetos radiofónico y griego", de = "Funk- und griechisches Alphabet" },
    ["Morse code"]              = { fr = "Code Morse", es = "Código Morse", de = "Morsecode" },
    ["Tables & SI prefixes"]    = { fr = "Tables et préfixes SI", es = "Tablas y prefijos SI", de = "Tabellen und SI-Präfixe" },
    ["Open on the last section used"] = { fr = "Rouvrir la dernière rubrique utilisée", es = "Abrir en la última sección usada", de = "Mit dem zuletzt genutzten Bereich öffnen" },
    ["Reset ruler calibration"] = { fr = "Réinitialiser l'étalonnage de la règle", es = "Restablecer la calibración de la regla", de = "Lineal-Kalibrierung zurücksetzen" },
    ["Ruler calibration reset."] = { fr = "Étalonnage de la règle réinitialisé.", es = "Calibración de la regla restablecida.", de = "Lineal-Kalibrierung zurückgesetzt." },

    -- Periodic table
    ["Whole table"]  = { fr = "Tableau entier", es = "Tabla entera", de = "Ganze Tabelle" },
    ["Groups 1–9"]   = { fr = "Groupes 1–9", es = "Grupos 1–9", de = "Gruppen 1–9" },
    ["Groups 10–18"] = { fr = "Groupes 10–18", es = "Grupos 10–18", de = "Gruppen 10–18" },
    ["English: %1"]  = { fr = "Anglais : %1", es = "Inglés: %1", de = "Englisch: %1" },
    ["French: %1"]   = { fr = "Français : %1", es = "Francés: %1", de = "Französisch: %1" },
    ["Atomic mass: %1"] = { fr = "Masse atomique : %1", es = "Masa atómica: %1", de = "Atommasse: %1" },
    ["Atomic mass: %1 (most stable isotope)"] = { fr = "Masse atomique : %1 (isotope le plus stable)", es = "Masa atómica: %1 (isótopo más estable)", de = "Atommasse: %1 (stabilstes Isotop)" },
    ["Group %1 · period %2 · block %3"] = { fr = "Groupe %1 · période %2 · bloc %3", es = "Grupo %1 · periodo %2 · bloque %3", de = "Gruppe %1 · Periode %2 · Block %3" },
    ["Period %1 · block f"] = { fr = "Période %1 · bloc f", es = "Periodo %1 · bloque f", de = "Periode %1 · Block f" },
    ["Family: %1"] = { fr = "Famille : %1", es = "Familia: %1", de = "Familie: %1" },
    ["Alkali metal"]          = { fr = "Métal alcalin", es = "Metal alcalino", de = "Alkalimetall" },
    ["Alkaline earth metal"]  = { fr = "Métal alcalino-terreux", es = "Metal alcalinotérreo", de = "Erdalkalimetall" },
    ["Transition metal"]      = { fr = "Métal de transition", es = "Metal de transición", de = "Übergangsmetall" },
    ["Post-transition metal"] = { fr = "Métal pauvre", es = "Metal del bloque p", de = "Metall (Hauptgruppe)" },
    ["Metalloid"]             = { fr = "Métalloïde", es = "Metaloide", de = "Halbmetall" },
    ["Reactive nonmetal"]     = { fr = "Non-métal", es = "No metal", de = "Nichtmetall" },
    ["Noble gas"]             = { fr = "Gaz noble", es = "Gas noble", de = "Edelgas" },
    ["Lanthanide"]            = { fr = "Lanthanide", es = "Lantánido", de = "Lanthanoid" },
    ["Actinide"]              = { fr = "Actinide", es = "Actínido", de = "Actinoid" },
    ["Unknown properties"]    = { fr = "Propriétés inconnues", es = "Propiedades desconocidas", de = "Unbekannte Eigenschaften" },

    -- Alphabets
    ["NATO alphabet"]  = { fr = "Alphabet OTAN", es = "Alfabeto OTAN", de = "NATO-Alphabet" },
    ["Greek alphabet"] = { fr = "Alphabet grec", es = "Alfabeto griego", de = "Griechisches Alphabet" },
    ["Spell a word"]   = { fr = "Épeler un mot", es = "Deletrear una palabra", de = "Wort buchstabieren" },
    ["Spell a word…"]  = { fr = "Épeler un mot…", es = "Deletrear una palabra…", de = "Wort buchstabieren…" },
    ["Word or name"]   = { fr = "Mot ou nom", es = "Palabra o nombre", de = "Wort oder Name" },

    -- Morse
    ["Letter"] = { fr = "Lettre", es = "Letra", de = "Buchstabe" },
    ["Text → Morse"]  = { fr = "Texte → Morse", es = "Texto → Morse", de = "Text → Morse" },
    ["Text → Morse…"] = { fr = "Texte → Morse…", es = "Texto → Morse…", de = "Text → Morse…" },
    ["Text to translate"] = { fr = "Texte à traduire", es = "Texto a traducir", de = "Zu übersetzender Text" },
    ["Key in Morse with the dot and dash keys, or translate a text."] = { fr = "Tapez du Morse avec les touches point et trait, ou traduisez un texte.", es = "Teclee Morse con las teclas de punto y raya, o traduzca un texto.", de = "Morsen Sie mit den Punkt- und Strich-Tasten oder übersetzen Sie einen Text." },
    ["%1 character(s) have no Morse code and were left out."] = { fr = "%1 caractère(s) sans code Morse ont été ignorés.", es = "%1 carácter(es) sin código Morse se han omitido.", de = "%1 Zeichen ohne Morsecode wurden ausgelassen." },

    -- Tables
    ["Multiplication"] = { fr = "Multiplication", es = "Multiplicación", de = "Einmaleins" },
    ["Powers"]         = { fr = "Puissances", es = "Potencias", de = "Potenzen" },
    ["SI prefixes"]    = { fr = "Préfixes SI", es = "Prefijos SI", de = "SI-Präfixe" },
    ["Symbol"] = { fr = "Symbole", es = "Símbolo", de = "Symbol" },
    ["Prefix"] = { fr = "Préfixe", es = "Prefijo", de = "Präfix" },
    ["Factor"] = { fr = "Facteur", es = "Factor", de = "Faktor" },

    -- Ruler
    ["Screen: %1 dpi"]    = { fr = "Écran : %1 ppp", es = "Pantalla: %1 ppp", de = "Bildschirm: %1 dpi" },
    ["Calibration: %1 %"] = { fr = "Étalonnage : %1 %", es = "Calibración: %1 %", de = "Kalibrierung: %1 %" },
    ["Lay a real ruler on the 0 mark and adjust until the marks line up."] = { fr = "Posez une vraie règle sur le trait 0 et ajustez jusqu'à ce que les graduations coïncident.", es = "Coloque una regla real en la marca 0 y ajuste hasta que coincidan las marcas.", de = "Legen Sie ein echtes Lineal an die 0-Marke und justieren Sie, bis die Striche übereinstimmen." },
    ["Measure…"] = { fr = "Mesurer…", es = "Medir…", de = "Messen…" },
    ["How many mm does the 0–%1 cm span measure?"] = { fr = "Combien de mm mesure l'intervalle 0–%1 cm ?", es = "¿Cuántos mm mide el tramo 0–%1 cm?", de = "Wie viele mm misst die Strecke 0–%1 cm?" },
    ["For example %1"] = { fr = "Par exemple %1", es = "Por ejemplo %1", de = "Zum Beispiel %1" },
}
