local _, Gentl = ...

local DataStore = {}
Gentl.DataStore = DataStore

local saved

function DataStore:Init()
    if not GentlSavedPlayers then
        GentlSavedPlayers = {}
    end
    saved = GentlSavedPlayers
end

function DataStore:SavePlayer(name, realm, class, race, level)
    local key = name .. "-" .. (realm or GetRealmName())
    local timestamp = date("%Y-%m-%d %H:%M:%S")
    local isNew = false

    if not saved[key] then
        saved[key] = {
            name = name,
            realm = realm,
            class = class,
            race = race,
            level = level,
            joinedAt = timestamp
        }
        isNew = true
    else
        local player = saved[key]
        player.class = class
        player.race = race
        player.level = level
        player.joinedAt = timestamp
    end

    return isNew
end

function DataStore:GetAll()
    return saved
end
