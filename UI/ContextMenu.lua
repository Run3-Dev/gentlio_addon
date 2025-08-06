-- ContextMenu.lua – Erweiterung des Tooltips um Gentl.IO-Bewertungen

local _, Gentl = ...
local ExternalRatings = _G.GentlExternalRatings or {}
local PendingRatings = _G.GentlPendingRatings or {}

local I18N = GentlI18N or { T = function(k) return k end }

local defaultLocale = "enUS"
local currentLocale = GetLocale() or defaultLocale

local locales = {
  ["enUS"] = "Locales/enUS.lua",
  ["deDE"] = "Locales/deDE.lua",
}

local function ensureList(value)
    if type(value) == "table" then
        return value
    end
    return {}
end

local function GetCombinedRatings(fullName)
    local external = ensureList(ExternalRatings[fullName])
    local localRatings = ensureList(PendingRatings[fullName])

    local all = {}
    for _, r in ipairs(external) do table.insert(all, r) end
    for _, r in ipairs(localRatings) do table.insert(all, r) end

    return all
end

local function GetRatingSummary(fullName)
    local ratings = GetCombinedRatings(fullName)
    if #ratings == 0 then return nil, 0 end

    local total = 0
    for _, r in ipairs(ratings) do
        total = total + (r.score or 0)
    end
    local avg = total / #ratings

    local rounded = math.floor(avg + 0.5)

    local labels = {
        [0] = GentlI18N.T("Negative experience"),
        [1] = GentlI18N.T("Unpleasant experience"),
        [2] = GentlI18N.T("Regular experience"),
        [3] = GentlI18N.T("Positive experience"),
        [4] = GentlI18N.T("Very positive experience"),
        [5] = GentlI18N.T("One of a kind")
    }

    return labels[rounded] or GentlI18N.T("No Ratings"), #ratings
end

-- Tooltip erweitern mit Bewertung
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    local name, unit = tooltip:GetUnit()
    if not unit or not UnitIsPlayer(unit) then return end

    local rawName, realm = UnitName(unit)
    if not rawName then return end
    realm = realm or GetRealmName()
    local fullName = rawName .. "-" .. realm

    local summary, count = GetRatingSummary(fullName)

    tooltip:AddLine(" ")
    tooltip:AddLine("|cffffff00Gentl.IO|r")

    if summary then
        tooltip:AddDoubleLine(GentlI18N.T("Rating") .. ":", string.format("|cffffffff%s|r", summary))
        tooltip:AddLine(string.format("%d " .. GentlI18N.T("Ratings"), count))
    else
        tooltip:AddLine("|cffffaaaa" .. GentlI18N.T("No Ratings") .. "|r")
    end
    
    tooltip:AddLine(" ")
end)
