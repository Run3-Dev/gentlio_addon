-- TooltipOverlay.lua – Retail-kompatibel mit sicherem Hook über Frame Event

local _, Gentl = ...
local ExternalRatings = _G.GentlExternalRatings or {}
local PendingRatings = _G.GentlPendingRatings or {}

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
        [0] = "Negatives Erlebnis",
        [1] = "Unzufrieden",
        [2] = "Durchschnittlich",
        [3] = "Zufrieden",
        [4] = "Sehr gut",
        [5] = "Herausragend"
    }

    return labels[rounded] or "Unbewertet", #ratings
end

-- Sicherstellen, dass der Hook erst nach vollständigem UI-Setup erfolgt
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function()
    if GameTooltip:HasScript("OnTooltipSetUnit") then
        GameTooltip:HookScript("OnTooltipSetUnit", function(self)
            local name, unit = self:GetUnit()
            if not unit or not UnitIsPlayer(unit) then return end

            local rawName, realm = UnitName(unit)
            if not rawName then return end
            realm = realm or GetRealmName()
            local fullName = rawName .. "-" .. realm

            local summary, count = GetRatingSummary(fullName)
            if not summary then return end

            self:AddLine(" ")
            self:AddLine("|cffffff00Gentl.IO|r")
            self:AddLine(string.format("Bewertung: |cffffffff%s|r", summary))
            self:AddLine(string.format("%d Bewertungen", count))
            self:Show()
        end)
    end
end)
