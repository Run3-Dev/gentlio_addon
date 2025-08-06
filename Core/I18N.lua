GentlI18N = {}

local defaultLocale = "enUS"
local currentLocale = GetLocale() or defaultLocale

-- Diese Tabellen werden von den Locale-Dateien global gesetzt
local availableLocales = {
  ["enUS"] = GentlLocale_enUS,
  ["deDE"] = GentlLocale_deDE,
}

-- Fallback auf Englisch, falls Sprache nicht verfügbar
local L = availableLocales[currentLocale] or availableLocales[defaultLocale] or {}

function GentlI18N.T(key)
  return L[key] or key
end