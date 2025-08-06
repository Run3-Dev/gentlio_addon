local _, Gentl = ...
local DataStore = Gentl.DataStore
local ExternalRatings = _G.GentlExternalRatings or {}
local AvailableTags = _G.GentlAvailableTags or {}
GentlPendingRatings = GentlPendingRatings or {}

local I18N = GentlI18N or { T = function(k) return k end }

local defaultLocale = "enUS"
local currentLocale = GetLocale() or defaultLocale

local locales = {
  ["enUS"] = "Locales/enUS.lua",
  ["deDE"] = "Locales/deDE.lua",
}

local function ensureList(value)
    if type(value) == "table" and (#value > 0 or next(value) == nil) then
        return value
    end
    return {}
end

local function SortByRecent(a, b)
    return a.joinedAt > b.joinedAt
end

local function FilterRecent(entries)
    local result = {}
    local now = time()
    for _, player in pairs(entries) do
        local t = date("*t", now)
        local cutoff = time({year=t.year, month=t.month, day=t.day}) - 2 * 86400
        local ts = time({year=tonumber(player.joinedAt:sub(1,4)), month=tonumber(player.joinedAt:sub(6,7)), day=tonumber(player.joinedAt:sub(9,10))})
        if ts >= cutoff then
            if not player.name:match("%[%d+%]$") and not player.name:match("^%d+$") then -- Filter für NPCs
                table.insert(result, player)
            end
        end
    end
    table.sort(result, SortByRecent)
    return result
end

local frame = CreateFrame("Frame", "GentlUI", UIParent, "BackdropTemplate")
frame:SetSize(600, 500)
frame:SetPoint("CENTER")
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.9)
frame:Hide()
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
scrollFrame:SetSize(250, 460)

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 6)
title:SetText(GentlI18N.T("Last Groupmembers"))
title:SetTextColor(1, 1, 1)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(250, 460)
scrollFrame:SetScrollChild(content)

local buttons = {}
local selectedPlayer = nil
local selectedButton = nil

local detail = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detail:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 35, -10)
detail:SetJustifyH("LEFT")
detail:SetWidth(300)
detail:SetTextColor(1, 1, 1)
detail:SetText(GentlI18N.T("Choose a Groupmember") .. "...")

local addRatingButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
addRatingButton:SetSize(160, 24)
addRatingButton:SetPoint("BOTTOMRIGHT", frame, -20, 15)
addRatingButton:SetText(GentlI18N.T("Add Rating"))
addRatingButton:Hide()

local ratingForm = CreateFrame("Frame", nil, frame, "BackdropTemplate")
ratingForm:SetSize(400, 300)
ratingForm:SetPoint("CENTER")
ratingForm:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
ratingForm:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
ratingForm:SetFrameStrata("DIALOG")
ratingForm:SetFrameLevel(100)
ratingForm:Hide()

local formTitle = ratingForm:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
formTitle:SetPoint("TOP", ratingForm, "TOP", 0, -10)
formTitle:SetText(GentlI18N.T("New Rating"))

local tagCheckboxes = {}

local function createTagSection(tags, label, xOffset, yOffset)
    local title = ratingForm:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", ratingForm, "TOPLEFT", xOffset, yOffset)
    title:SetText(label)

    for i, tag in ipairs(tags) do
        local cb = CreateFrame("CheckButton", nil, ratingForm, "UICheckButtonTemplate")
        cb:SetSize(20, 20)
        cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -((i - 1) * 22))
        cb.text = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cb.text:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        cb.text:SetText(tag.label)
        cb.tagData = tag
        table.insert(tagCheckboxes, cb)
    end
end

createTagSection(AvailableTags.positive or {}, "Positive Tags", 20, -40)
createTagSection(AvailableTags.negative or {}, "Negative Tags", 200, -40)

local saveButton = CreateFrame("Button", nil, ratingForm, "UIPanelButtonTemplate")
saveButton:SetSize(100, 22)
saveButton:SetPoint("BOTTOMRIGHT", ratingForm, -20, 10)
saveButton:SetText(GentlI18N.T("Save"))

local cancelButton = CreateFrame("Button", nil, ratingForm, "UIPanelButtonTemplate")
cancelButton:SetSize(100, 22)
cancelButton:SetPoint("BOTTOMLEFT", ratingForm, 20, 10)
cancelButton:SetText(GentlI18N.T("Abort"))

cancelButton:SetScript("OnClick", function()
    ratingForm:Hide()
end)

saveButton:SetScript("OnClick", function()
    if not selectedPlayer then return end
    local realm = selectedPlayer.realm or GetRealmName()
    local fullName = selectedPlayer.name .. "-" .. realm

    local tags = {}
    local total = 0
    local count = 0
    for _, cb in ipairs(tagCheckboxes) do
        if cb:GetChecked() then
            table.insert(tags, cb.tagData.label)
            total = total + cb.tagData.weight
            count = count + 1
        end
    end

    if count == 0 then
        print("|cffff4444[Gentl.io]|r " .. GentlI18N.T("Choose at least one tag"))
        return
    end

    local score = total / count
    GentlPendingRatings[fullName] = GentlPendingRatings[fullName] or {}
    table.insert(GentlPendingRatings[fullName], {
        score = score,
        tags = tags,
        timestamp = date("%Y-%m-%d %H:%M:%S")
    })

    print("|cff00ccff[Gentl.io]|r " .. GentlI18N.T("Rating saved for") .. ":", fullName)
    for _, cb in ipairs(tagCheckboxes) do
        cb:SetChecked(false)
    end
    ratingForm:Hide()
end)

local function UpdateDetails(player)
    if not player then return end
    local realm = player.realm or GetRealmName()
    local fullName = player.name .. "-" .. realm

    local lines = {}
    table.insert(lines, string.format(GentlI18N.T("Name") .. ": %s", player.name))
    table.insert(lines, string.format(GentlI18N.T("Realm") .. ": %s", realm))
    table.insert(lines, string.format(GentlI18N.T("Class") .. ": %s", player.class or "?"))
    table.insert(lines, string.format(GentlI18N.T("Level") .. ": %s", player.level or "?"))
    table.insert(lines, string.format(GentlI18N.T("Last time seen") .. ": %s", player.joinedAt or "?"))

    local ratingsExternal = ensureList(ExternalRatings[fullName])
    local ratingsLocal = ensureList(GentlPendingRatings[fullName])

    local allRatings = {}
    for _, r in ipairs(ratingsExternal) do table.insert(allRatings, r) end
    for _, r in ipairs(ratingsLocal) do table.insert(allRatings, r) end

    table.sort(allRatings, function(a, b)
        return (a.timestamp or "") > (b.timestamp or "")
    end)

    if #allRatings > 0 then
        table.insert(lines, "")
        table.insert(lines, GentlI18N.T("Ratings") .. ":")

        local labels = {
            [0] = { text = GentlI18N.T("Negative experience"), color = "|cff9d9d9d" },
            [1] = { text = GentlI18N.T("Unpleasant experience"), color = "|cffffffff" },
            [2] = { text = GentlI18N.T("Regular experience"), color = "|cff1eff00" },
            [3] = { text = GentlI18N.T("Positive experience"), color = "|cff0070dd" },
            [4] = { text = GentlI18N.T("Very positive experience"), color = "|cffa335ee" },
            [5] = { text = GentlI18N.T("One of a kind"), color = "|cffff8000" }
        }

        for _, entry in ipairs(allRatings) do
            local score = math.floor(entry.score + 0.5)
            local label = labels[score] or { text = GentlI18N.T("No Ratings"), color = "|cffffffff" }
            table.insert(lines, string.format("  %s%s|r  (%s)", label.color, label.text, entry.timestamp or GentlI18N.T("Unknown")))
            if entry.tags then
                table.insert(lines, "    " .. table.concat(entry.tags, ", "))
            end
            table.insert(lines, "")
        end
    end

    detail:SetText(table.concat(lines, "\n"))
    addRatingButton:Show()
end

addRatingButton:SetScript("OnClick", function()
    ratingForm:Show()
end)

local function UpdateList()
    local players = FilterRecent(DataStore:GetAll())
    for i, button in ipairs(buttons) do button:Hide() end

    local rowIndex = 1

    -- Eigener Charakter oben
    local name, realm = UnitName("player")
    local _, class = UnitClass("player")
    local race = UnitRace("player")
    local level = UnitLevel("player")

    local selfPlayer = {
        name = name,
        realm = realm,
        class = class,
        race = race,
        level = level,
        joinedAt = date("%Y-%m-%d %H:%M:%S")
    }

    local function createOrUpdateButton(i, player, isSelf)
        local btn = buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, content, "BackdropTemplate")
            btn:SetSize(240, 20)
            btn:SetPoint("TOPLEFT", content, "TOPLEFT", 5, -((i - 1) * 22))

            btn:SetBackdrop({
                bgFile = "Interface/Buttons/WHITE8x8",
                edgeFile = nil,
                tile = false, tileSize = 0, edgeSize = 0,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
            })

            btn.factionIcon = btn:CreateTexture(nil, "ARTWORK")
            btn.factionIcon:SetSize(14, 14)
            btn.factionIcon:SetPoint("LEFT", btn, "LEFT", 4, 0)

            btn.classIcon = btn:CreateTexture(nil, "ARTWORK")
            btn.classIcon:SetSize(14, 14)
            btn.classIcon:SetPoint("LEFT", btn.factionIcon, "RIGHT", 2, 0)

            btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.text:SetPoint("LEFT", btn.classIcon, "RIGHT", 4, 0)
            btn.text:SetJustifyH("LEFT")
            btn.text:SetTextColor(1, 1, 1)

            buttons[i] = btn
        end

        local label = player.name .. "-" .. (player.realm or GetRealmName())
        btn.text:SetText(isSelf and ("|cff00ff00" .. label .. "|r") or label)

        -- Icons
        local classUpper = string.upper(player.class or "")
        btn.classIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes")
        local classIcons = {
            WARRIOR = {0, 0.25, 0, 0.25},
            MAGE = {0.25, 0.5, 0, 0.25},
            ROGUE = {0.5, 0.75, 0, 0.25},
            DRUID = {0.75, 1, 0, 0.25},
            HUNTER = {0, 0.25, 0.25, 0.5},
            SHAMAN = {0.25, 0.5, 0.25, 0.5},
            PRIEST = {0.5, 0.75, 0.25, 0.5},
            WARLOCK = {0.75, 1, 0.25, 0.5},
            PALADIN = {0, 0.25, 0.5, 0.75},
            DEATHKNIGHT = {0.25, 0.5, 0.5, 0.75},
            MONK = {0.5, 0.75, 0.5, 0.75},
            DEMONHUNTER = {0.75, 1, 0.5, 0.75}
        }
        if classIcons[classUpper] then
            btn.classIcon:SetTexCoord(unpack(classIcons[classUpper]))
        else
            btn.classIcon:SetTexCoord(0, 1, 0, 1)
        end

        local factionTexture = UnitFactionGroup("player") == "Horde"
            and "Interface\\Icons\\Achievement_Character_Orc_Male"
            or "Interface\\Icons\\Achievement_Character_Human_Male"
        btn.factionIcon:SetTexture(factionTexture)

        btn:Show()
        btn:SetBackdropColor(isSelf and 0.3 or 0.2, isSelf and 0.3 or 0.2, isSelf and 0.3 or 0.2, 1)

        btn:SetScript("OnClick", function()
            selectedPlayer = player
            selectedButton = btn
            UpdateDetails(player)

            for _, b in ipairs(buttons) do
                b:SetBackdropColor(0.2, 0.2, 0.2, 1)
            end
            btn:SetBackdropColor(0.6, 0.6, 0.6, 1)
        end)
    end

    -- Erst du selbst
    createOrUpdateButton(rowIndex, selfPlayer, true)
    rowIndex = rowIndex + 1

    -- Dann alle anderen
    for _, player in ipairs(players) do
        createOrUpdateButton(rowIndex, player, false)
        rowIndex = rowIndex + 1
    end
end

frame:SetScript("OnShow", function()
    UpdateList()
end)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
closeButton:SetScript("OnClick", function()
    frame:Hide()
end)

-- 🧠 Fix für nil-Fehler:
Gentl.UI = Gentl.UI or {}
Gentl.UI.MainWindow = frame
