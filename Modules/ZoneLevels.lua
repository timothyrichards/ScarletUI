-- Appends a zone's level range to the world map hover label, colored by
-- difficulty like Retail. Era, TBC Anniversary, and Forever call
-- C_Map.GetMapLevels for this label but get no data, so levels come from this
-- table of Classic UIMapIDs. A post-hook on the label's SetLabel edits only the
-- stored label text; Blizzard's OnUpdate script is not replaced.
local ZONE_LEVELS = {
    -- Eastern Kingdoms
    [1416] = { 30, 40 }, -- Alterac Mountains
    [1417] = { 30, 40 }, -- Arathi Highlands
    [1418] = { 35, 45 }, -- Badlands
    [1419] = { 45, 55 }, -- Blasted Lands
    [1428] = { 50, 58 }, -- Burning Steppes
    [1430] = { 55, 60 }, -- Deadwind Pass
    [1426] = { 1, 10 }, -- Dun Morogh
    [1431] = { 18, 30 }, -- Duskwood
    [1423] = { 53, 60 }, -- Eastern Plaguelands
    [1429] = { 1, 10 }, -- Elwynn Forest
    [1941] = { 1, 10 }, -- Eversong Woods
    [1942] = { 10, 20 }, -- Ghostlands
    [1424] = { 20, 30 }, -- Hillsbrad Foothills
    [1957] = { 70, 70 }, -- Isle of Quel'Danas
    [1432] = { 10, 20 }, -- Loch Modan
    [1433] = { 15, 25 }, -- Redridge Mountains
    [1427] = { 43, 50 }, -- Searing Gorge
    [1421] = { 10, 20 }, -- Silverpine Forest
    [1434] = { 30, 45 }, -- Stranglethorn Vale
    [1435] = { 35, 45 }, -- Swamp of Sorrows
    [1425] = { 40, 50 }, -- The Hinterlands
    [1420] = { 1, 10 }, -- Tirisfal Glades
    [1436] = { 10, 20 }, -- Westfall
    [1422] = { 51, 58 }, -- Western Plaguelands
    [1437] = { 20, 30 }, -- Wetlands
    -- Kalimdor
    [1440] = { 18, 30 }, -- Ashenvale
    [1447] = { 45, 55 }, -- Azshara
    [1943] = { 1, 10 }, -- Azuremyst Isle
    [1950] = { 10, 20 }, -- Bloodmyst Isle
    [1439] = { 10, 20 }, -- Darkshore
    [1443] = { 30, 40 }, -- Desolace
    [1411] = { 1, 10 }, -- Durotar
    [1445] = { 35, 45 }, -- Dustwallow Marsh
    [1448] = { 48, 55 }, -- Felwood
    [1444] = { 40, 50 }, -- Feralas
    [1412] = { 1, 10 }, -- Mulgore
    [1451] = { 55, 60 }, -- Silithus
    [1442] = { 15, 27 }, -- Stonetalon Mountains
    [1446] = { 40, 50 }, -- Tanaris
    [1438] = { 1, 10 }, -- Teldrassil
    [1413] = { 10, 25 }, -- The Barrens
    [1441] = { 25, 35 }, -- Thousand Needles
    [1449] = { 48, 55 }, -- Un'Goro Crater
    [1452] = { 55, 60 }, -- Winterspring
    -- Outland
    [1949] = { 65, 68 }, -- Blade's Edge Mountains
    [1944] = { 58, 63 }, -- Hellfire Peninsula
    [1951] = { 64, 67 }, -- Nagrand
    [1953] = { 67, 70 }, -- Netherstorm
    [1948] = { 67, 70 }, -- Shadowmoon Valley
    [1952] = { 62, 65 }, -- Terokkar Forest
    [1946] = { 60, 64 }, -- Zangarmarsh
}

-- Blizzard's area label thresholds: zones entirely below you are not yellow.
local function DifficultyColor(minLevel, maxLevel)
    local level = UnitLevel("player")
    local color
    if level < minLevel then
        color = GetQuestDifficultyColor(minLevel)
    elseif level > maxLevel then
        color = GetQuestDifficultyColor(maxLevel - 2)
    else
        color = QuestDifficultyColors.difficult
    end
    return string.format("|cff%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
end

local function AddZoneLevels(label, labelType, name)
    -- A color code means the client or another addon (Leatrix Maps) already added levels.
    if labelType ~= MAP_AREA_LABEL_TYPE.AREA_NAME or not name or name:find("|c", 1, true)
        or not ScarletUI.db.global.zoneLevels then
        return
    end
    local map = label.dataProvider:GetMap()
    local mapID = map:GetMapID()
    local info = C_Map.GetMapInfoAtPosition(mapID, map:GetNormalizedCursorPosition())
    local levels = info and info.mapID ~= mapID and ZONE_LEVELS[info.mapID]
    if levels then
        local minLevel, maxLevel = levels[1], levels[2]
        local range = minLevel == maxLevel and minLevel or minLevel .. "-" .. maxLevel
        label.labelInfoByType[labelType].name = name .. DifficultyColor(minLevel, maxLevel)
            .. " (" .. range .. ")|r"
    end
end

function ScarletUI:SetupZoneLevels()
    -- Retail and Mists show levels natively, and their UIMapIDs differ from this table's.
    local client = self:GetWoWVersion()
    if self.zoneLevelsHooked or not WorldMapFrame
        or (client ~= "VANILLA" and client ~= "TBC" and client ~= "FOREVER") then
        return
    end
    for provider in pairs(WorldMapFrame.dataProviders) do
        if provider.Label and provider.Label.labelInfoByType then
            hooksecurefunc(provider.Label, "SetLabel", AddZoneLevels)
            self.zoneLevelsHooked = true
        end
    end
end
