-- Gibt eine Farbe passend zum Score zurück
local function GetScoreColor(score)
    if score >= 5 then
        return "|cffff8000"  -- legendär (orange)
    elseif score >= 4 then
        return "|cffa335ee"  -- episch (lila)
    elseif score >= 3.5 then
        return "|cff0070dd"  -- selten (blau)
    elseif score >= 2.5 then
        return "|cff1eff00"  -- ungewöhnlich (grün)
    else
        return "|cff9d9d9d"  -- schlecht (grau)
    end
end

-- Fügt den Tooltip-Eintrag hinzu
local function AddGentlScore(tooltip, name, realm)
    if not name then return end
    if not realm or realm == "" then
        realm = GetRealmName()
    end

    realm = realm:gsub("%s+", "")  -- Leerzeichen entfernen
    local fullName = name .. "-" .. realm

    local score = GentlScoreDB[fullName]
    local valueText, valueColor

    if score then
        valueColor = GetScoreColor(score)
        valueText = tostring(score)
    else
        valueColor = "|cff9d9d9d"  -- grau
        valueText = "-"
    end

    tooltip:AddDoubleLine(
        "|cffffff00Gentl.io Score:|r",
        valueColor .. valueText .. "|r"
    )
end



-- Tooltip Hook: funktioniert für Retail (Dragonflight & aufwärts)
TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, function(tooltip, data)
    local guid = data.guid
    if guid and guid:match("^Player") then
        local unit = tooltip:GetUnit()
        if not unit then return end

        local name = UnitName(unit)
        local realm = select(2, UnitName(unit))

        if not name then return end
        if not realm or realm == "" then
            realm = GetRealmName()
        end

        AddGentlScore(tooltip, name, realm)
    end
end)
