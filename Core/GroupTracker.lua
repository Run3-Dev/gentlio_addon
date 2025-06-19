local _, Gentl = ...
local DataStore

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("GROUP_ROSTER_UPDATE")

local initialized = false

local function UpdateGroupMembers()
    if not initialized then return end
    local members = GetNumGroupMembers()
    for i = 1, members do
        local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)

        if UnitExists(unit) and UnitIsPlayer(unit) then
            local name, realm = UnitName(unit)
            local _, class = UnitClass(unit)
            local race = UnitRace(unit)
            local level = UnitLevel(unit)
            if name then
                local isNew = DataStore:SavePlayer(name, realm, class, race, level)
                if isNew then
                    local fullName = name .. "-" .. (realm or GetRealmName())
                    print("|cff00ccff[Gentl.io]|r Neuer Gruppenmitglied gespeichert:", fullName, "(Klasse:", class, "Level:", level .. ")")
                end
            end
        end
    end
end

f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "GentlIO" then
        DataStore = Gentl.DataStore
        DataStore:Init()
        initialized = true
        print("|cff00ccff[Gentl.io]|r Addon geladen")
    elseif event == "GROUP_ROSTER_UPDATE" then
        UpdateGroupMembers()
    end
end)

SLASH_GENTL1 = "/gentl"
SlashCmdList["GENTL"] = function()
    if GentlUI and GentlUI:IsShown() then
        GentlUI:Hide()
    else
        GentlUI:Show()
    end
end
