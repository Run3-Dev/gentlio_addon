-- Gibt eine Farbe passend zum Score zurück
local function GetScoreColor(score)
    if score >= 5 then return "|cffff8000"  -- legendär
    elseif score >= 4 then return "|cffa335ee"  -- episch
    elseif score >= 3.5 then return "|cff0070dd"  -- selten
    elseif score >= 2.5 then return "|cff1eff00"  -- ungewöhnlich
    else return "|cff9d9d9d"  -- grau
    end
end

-- Tooltip-Zeile einfügen
local function AddGentlScore(tooltip, name, realm)
    if not name then return end
    if not realm or realm == "" then realm = GetRealmName() end
    realm = realm:gsub("%s+", "")
    local fullName = name .. "-" .. realm
    local score = GentlScoreDB and GentlScoreDB[fullName]
    local valueText = score and tostring(score) or "-"
    local valueColor = score and GetScoreColor(score) or "|cff9d9d9d"

    tooltip:AddDoubleLine(
        "|cffffff00Gentl.io Score:|r",
        valueColor .. valueText .. "|r"
    )
end

local function GetStars(rating)
    local fullStars = math.floor(rating + 0.5)  -- rundet sauber
    local stars = ""
    for i = 1, 5 do
        if i <= fullStars then
            stars = stars .. "|cffff8000*|r "  -- legendär (orange)
        else
            stars = stars .. "|cff9d9d9d*|r "  -- grau
        end
    end
    return stars
end


-- Bewertungsfenster
local gentlFrame = CreateFrame("Frame", "GentlIOFrame", UIParent, "BasicFrameTemplateWithInset")
gentlFrame:SetSize(400, 240)
gentlFrame:SetPoint("CENTER")
gentlFrame:SetMovable(true)
gentlFrame:EnableMouse(true)
gentlFrame:RegisterForDrag("LeftButton")
gentlFrame:SetScript("OnDragStart", gentlFrame.StartMoving)
gentlFrame:SetScript("OnDragStop", gentlFrame.StopMovingOrSizing)
table.insert(UISpecialFrames, "GentlIOFrame")

gentlFrame.title = gentlFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
gentlFrame.title:SetPoint("TOP", 0, -10)
gentlFrame.title:SetText("Gentl.io Bewertung")

gentlFrame.content = gentlFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
gentlFrame.content:SetPoint("TOPLEFT", 10, -30)
gentlFrame.content:SetPoint("BOTTOMRIGHT", -10, 10)
gentlFrame.content:SetJustifyH("LEFT")
gentlFrame.content:SetJustifyV("TOP")
gentlFrame.content:SetWordWrap(true)

--gentlFrame.closeButton = CreateFrame("Button", nil, gentlFrame, "UIPanelCloseButton")
--gentlFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)
--gentlFrame.closeButton:SetScript("OnClick", function() gentlFrame:Hide() end)

-- Anzeige-Funktion
function GentlIO_ShowFrame(name, realm)
    if not realm or realm == "" then realm = GetRealmName() end
    local fullName = name .. "-" .. realm:gsub("%s+", "")
    local entries = GentlCommentDB and GentlCommentDB[fullName]

    if entries then
        local lines = {}
        for _, entry in ipairs(entries) do
            local line = string.format(
                "|cffff8000Bewertung vom %s|r\n%s (%s von 5) \n|cffffffff\"%s\"|r\n",
                date("%d.%m.%Y", entry.createdAt),
                GetStars(entry.score),
                entry.score,
                entry.comment
            )
            table.insert(lines, line)
        end
        gentlFrame.content:SetText(fullName .. "\n\n" .. table.concat(lines, "\n\n"))
    else
        gentlFrame.content:SetText(fullName .. "\n\nKeine Bewertung")
    end

    gentlFrame:Show()
end

-- Tooltip-Hook
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    local guid = data.guid
    if guid and guid:match("^Player") then
        local unit = tooltip:GetUnit()
        if not unit then return end
        local name = UnitName(unit)
        local realm = select(2, UnitName(unit)) or GetRealmName()
        AddGentlScore(tooltip, name, realm)
    end
end)

-- Slash-Befehl zum Anzeigen für das Target
SLASH_GENTLIO1 = "/gentl"
SlashCmdList["GENTLIO"] = function()
    local unit = "target"
    if UnitExists(unit) and UnitIsPlayer(unit) then
        local name = UnitName(unit)
        local realm = select(2, UnitName(unit)) or GetRealmName()
        GentlIO_ShowFrame(name, realm)
    else
        print("Gentl.io: Kein Spieler im Ziel.")
    end
end
