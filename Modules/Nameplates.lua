-- Classic UI clients only: listed in the Vanilla, TBC, and Mists manifests, so
-- Retail and Forever never load it.
ScarletUI.defaults.global.nameplatesModule = {
    enabled = true,
    classColored = true,
    threatColored = true,
    specialUnitsColored = true,
    dropdownMenuButton = true,
    buffTracker = {
        track = true,
        iconSize = 30,
        spacing = 2,
        verticalOffset = 20,
    },
    debuffTracker = {
        track = true,
        iconSize = 30,
        spacing = 2,
        verticalOffset = 20,
    },
    targetIndicator = {
        show = true,
        indicatorSize = 30,
        indicatorDistance = -5,
        indicatorHeight = -7
    },
    healthBarText = {
        show = true,
        fontSize = 10
    },
    threatAmountText = {
        show = true,
        fontSize = 18,
        anchor = 1, -- LEFT
    },
    castBarText = {
        show = true,
        fontSize = 10
    },
    nonTankThreatColors = {
        noThreat = { 0.0824, 1, 0, 1 },
        lowThreat = { 1, 0.9176, 0, 1 },
        threat = { 1, 0.0353, 0, 1 },
        pet = { 0, 0.95, 1, 1 },
        tank = { 0, 0.7020, 1, 1 }
    },
    tankThreatColors = {
        noThreat = { 1, 0.0353, 0, 1 },
        lowThreat = { 1, 0.9176, 0, 1 },
        threat = { 0.0824, 1, 0, 1 },
        pet = { 0, 0.95, 1, 1 },
        tank = { 0, 0.7020, 1, 1 }
    },
    tankNames = "",
    specialUnitColor = { 1, 0, 1, 1 },
    specialUnitNames = ""
}
ScarletUI.originalUIDefaults.global.nameplatesModule = {
    enabled = true,
    classColored = true,
    threatColored = true,
    specialUnitsColored = true,
    buffTracker = {
        track = true,
        iconSize = 30,
        spacing = 2,
        verticalOffset = 20,
    },
    debuffTracker = {
        track = true,
        iconSize = 30,
        spacing = 2,
        verticalOffset = 20,
    },
    targetIndicator = {
        show = true,
        indicatorSize = 30,
        indicatorDistance = -5,
        indicatorHeight = -7
    },
    healthBarText = {
        show = true,
        fontSize = 10
    },
    castBarText = {
        show = true,
        fontSize = 10
    },
    nonTankThreatColors = {
        noThreat = { 0.0824, 1, 0, 1 },
        lowThreat = { 1, 0.9176, 0, 1 },
        threat = { 1, 0.0353, 0, 1 },
        pet = { 0, 0.95, 1, 1 },
        tank = { 0, 0.7020, 1, 1 }
    },
    tankThreatColors = {
        noThreat = { 1, 0.0353, 0, 1 },
        lowThreat = { 1, 0.9176, 0, 1 },
        threat = { 0.0824, 1, 0, 1 },
        pet = { 0, 0.95, 1, 1 },
        tank = { 0, 0.7020, 1, 1 }
    },
    tankNames = "",
    specialUnitColor = { 1, 0, 1, 1 },
    specialUnitNames = ""
}
ScarletUI.defaults.char.priorityDebuffs = ""
ScarletUI.originalUIDefaults.char.priorityDebuffs = ""

local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local lastNameplate

-- Threat throttle: batch UNIT_THREAT_LIST_UPDATE into 0.1s intervals
local dirtyThreatUnits = {}
local threatThrottleFrame = CreateFrame("Frame")
local threatThrottleTicker = 0
threatThrottleFrame:SetScript("OnUpdate", function(_, dt)
    threatThrottleTicker = threatThrottleTicker + dt
    if threatThrottleTicker < 0.1 then return end
    threatThrottleTicker = 0

    local hasDirty = false
    for unitId in pairs(dirtyThreatUnits) do
        hasDirty = true
        ScarletUI:UpdateNameplate(unitId)
    end
    if hasDirty then
        wipe(dirtyThreatUnits)
    end
end)

-- Pre-computed pet unit strings, rebuilt periodically
local petUnitStrings = {}
local lastPetRebuild = 0
local function RebuildPetUnitStrings()
    local now = GetTime()
    if now - lastPetRebuild < 1 then return end
    lastPetRebuild = now
    wipe(petUnitStrings)
    petUnitStrings["player"] = "playerpet"
    for i = 1, 40 do
        petUnitStrings["party" .. i] = "party" .. i .. "pet"
        petUnitStrings["raid" .. i] = "raid" .. i .. "pet"
    end
end

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function split(input)
    input = input or ""
    local ret = {}

    for element in input:gmatch("[^,]+") do
        element = trim(element)
        if element ~= "" then
            ret[element] = true
        end
    end

    return ret
end

-- Cache for group information to prevent excessive API calls
local groupInfoCache = { max = 1, prefix = "party", lastUpdate = 0 }
local GROUP_INFO_CACHE_DURATION = 1 -- Cache for 1 second

local function UpdateGroupInfoCache()
    local currentTime = GetTime()
    if currentTime - groupInfoCache.lastUpdate > GROUP_INFO_CACHE_DURATION then
        local inRaid = IsInRaid()
        local inGroup = IsInGroup()

        groupInfoCache.max = inRaid and GetNumGroupMembers() or inGroup and GetNumGroupMembers() or 1
        groupInfoCache.prefix = inRaid and "raid" or "party"
        groupInfoCache.lastUpdate = currentTime
    end
end

local function IterateGroupMembers()
    UpdateGroupInfoCache()
    local i = 0
    local max = groupInfoCache.max
    local prefix = groupInfoCache.prefix

    -- Raid units include the player; party units do not.
    if prefix == "raid" then
        return function()
            i = i + 1
            if i <= max then
                return prefix .. i
            end
        end
    end

    return function()
        i = i + 1
        if i == 1 then
            return "player"
        elseif i < max + 1 then
            return prefix .. (i - 1)
        end
    end
end

local function ThreatFunc(unit)
    RebuildPetUnitStrings()

    local firstUnit, secondUnit
    local firstThreat, secondThreat = -1, -1  -- Initialize with values less than zero
    local threat, pet

    for member in IterateGroupMembers() do
        threat = select(5, UnitDetailedThreatSituation(member, unit))

        if threat then
            if threat > firstThreat then
                secondUnit = firstUnit
                secondThreat = firstThreat
                firstUnit = member
                firstThreat = threat
            elseif threat > secondThreat then
                secondUnit = member
                secondThreat = threat
            end
        end

        pet = petUnitStrings[member] or (member .. "pet")
        if UnitExists(pet) then
            threat = select(5, UnitDetailedThreatSituation(pet, unit))

            if threat then
                if threat > firstThreat then
                    secondUnit = firstUnit
                    secondThreat = firstThreat
                    firstUnit = pet
                    firstThreat = threat
                elseif threat > secondThreat then
                    secondUnit = pet
                    secondThreat = threat
                end
            end
        end
    end

    return firstUnit, firstThreat, secondUnit, secondThreat
end

local function IsPet(unitId)
    if UnitIsUnit(unitId, "pet") then
        return true
    end

    for i = 1, 4 do
        if UnitIsUnit(unitId, "partypet" .. i) then
            return true
        end
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            if UnitIsUnit(unitId, "raidpet" .. i) then
                return true
            end
        end
    end

    return false
end

-- Cache for party assignments to prevent excessive API calls
local partyAssignmentCache = {}
local lastPartyAssignmentCheck = 0
local PARTY_ASSIGNMENT_CACHE_DURATION = 1 -- Cache for 1 second

local function IsTank(playerName)
    local currentTime = GetTime()

    -- Only check each player's party assignments once per second to prevent spam
    if currentTime - lastPartyAssignmentCheck > PARTY_ASSIGNMENT_CACHE_DURATION then
        partyAssignmentCache = {}
        lastPartyAssignmentCheck = currentTime
    end

    if partyAssignmentCache[playerName] == nil then
        -- Only make the API calls if we're actually in a group
        if IsInGroup() then
            local mainTank = GetPartyAssignment("MAINTANK", playerName)
            local mainAssist = GetPartyAssignment("MAINASSIST", playerName)
            partyAssignmentCache[playerName] = (mainTank or mainAssist) and true or false
        else
            partyAssignmentCache[playerName] = false
        end
    end

    -- Check cached party assignment first
    if partyAssignmentCache[playerName] then
        return true
    end

    if UnitGroupRolesAssigned then
        local role = UnitGroupRolesAssigned(playerName)
        if role == "TANK" then
            return true
        end
    end

    -- If not in WotLK Classic or no roles assigned, check if the player's name is in the otherTanks list
    return ScarletUI.tanks[playerName]
end

local function HideTargetArrows()
    if lastNameplate and lastNameplate.leftArrow and lastNameplate.rightArrow then
        lastNameplate.leftArrow:Hide()
        lastNameplate.rightArrow:Hide()
    end
end

local function SetupNameplate(nameplate)
    local module = ScarletUI.db.global.nameplatesModule

    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if module.healthBarText.show then
        if healthBar then
            if not healthBar.healthBarText then
                healthBar.healthBarText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
                healthBar.healthBarText:SetPoint("CENTER")
                healthBar.healthBarText:SetFont("Fonts\\FRIZQT__.TTF", module.healthBarText.fontSize, "OUTLINE")
            else
                healthBar.healthBarText:SetFont("Fonts\\FRIZQT__.TTF", module.healthBarText.fontSize, "OUTLINE")
            end
            ScarletUI:UpdateHealthText(healthBar)

            -- Hook into the OnValueChanged script to update the text during casting
            if not healthBar.healthBarTextHooked then
                healthBar:HookScript("OnValueChanged", function(self)
                    ScarletUI:UpdateHealthText(self)
                end)
                healthBar.healthBarTextHooked = true
            end
        end
    elseif healthBar and healthBar.healthBarText then
        healthBar.healthBarText:Hide()
    end

    if module.threatAmountText.show and healthBar then
        if not nameplate.threatAmountText then
            nameplate.threatAmountText = nameplate:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            nameplate.threatAmountText:SetPoint("RIGHT", healthBar, "LEFT", -30, 0)
            nameplate.threatAmountText:SetFont("Fonts\\FRIZQT__.TTF", module.threatAmountText.fontSize, "OUTLINE")
        else
            nameplate.threatAmountText:SetFont("Fonts\\FRIZQT__.TTF", module.threatAmountText.fontSize, "OUTLINE")
        end
    elseif nameplate.threatAmountText then
        nameplate.threatAmountText:Hide()
    end

    local castBar = nameplate.UnitFrame and (nameplate.UnitFrame.CastBar or nameplate.UnitFrame.castBar)
    if module.castBarText.show then
        if castBar then
            -- Create a font string if it doesn't exist
            if not castBar.castBarText then
                castBar.castBarText = castBar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
                castBar.castBarText:SetPoint("CENTER")
                castBar.castBarText:SetFont("Fonts\\FRIZQT__.TTF", module.castBarText.fontSize, "OUTLINE")
            else
                castBar.castBarText:SetFont("Fonts\\FRIZQT__.TTF", module.castBarText.fontSize, "OUTLINE")
            end
            ScarletUI:UpdateCastText(castBar)

            -- Hook into the OnValueChanged script to update the text during casting
            if not castBar.castBarTextHooked then
                castBar:HookScript("OnValueChanged", function(self)
                    ScarletUI:UpdateCastText(self)
                end)
                castBar.castBarTextHooked = true
            end
        end
    elseif castBar and castBar.castBarText then
        castBar.castBarText:Hide()
    end

    -- Clear expired debuff icons
    if nameplate.myDebuffIcons then
        local currentTime = GetTime()
        for debuffName, debuffData in pairs(nameplate.myDebuffIcons) do
            if debuffData.expireTime < currentTime then
                debuffData.icon:Hide()
                nameplate.myDebuffIcons[debuffName] = nil
            end
        end
    end
end

function ScarletUI:UpdateCastText(castBar)
    if castBar then
        local textRegion = castBar.Text or castBar.text
        local abilityName = textRegion and textRegion:GetText()
        if castBar.castBarText then
            castBar.castBarText:SetText(abilityName)
            castBar.castBarText:Show()
        end
    end
end

function ScarletUI:UpdateHealthText(healthBar)
    if not healthBar then return end

    local unitFrame = healthBar:GetParent()
    local nameplate = unitFrame and unitFrame:GetParent()
    local unitID = (unitFrame and unitFrame.unit)
        or (nameplate and (nameplate.namePlateUnitToken or nameplate.unit or nameplate.displayedUnit))

    local maxHealth = unitID and UnitHealthMax(unitID) or 0
    if maxHealth <= 0 then
        if healthBar.healthBarText then healthBar.healthBarText:Hide() end
        return
    end

    local healthPercent = (UnitHealth(unitID) / maxHealth) * 100;
    if healthBar.healthBarText then
        healthBar.healthBarText:SetText(string.format("%.0f%%", healthPercent))
        healthBar.healthBarText:Show()
    end
end

function ScarletUI:ReapplyTextSettingsToNameplates()
    local activeNameplates = C_NamePlate.GetNamePlates()

    for _, nameplate in ipairs(activeNameplates) do
        SetupNameplate(nameplate)
    end
end

function ScarletUI:UpdateNameplate(unitId)
    local nameplatesModule = self.db.global.nameplatesModule
    if not unitId or not UnitExists(unitId) then
        return
    end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
    if not nameplate then
        return
    end
    local unitName, _ = UnitName(unitId)

    if nameplatesModule.specialUnitsColored and self.specialUnits[unitName] and nameplate.UnitFrame then
        nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(nameplatesModule.specialUnitColor))
        return
    end

    if not nameplatesModule.threatColored then
        return
    end

    local isTanking, threatStatus, _, _, threatValue = UnitDetailedThreatSituation("player", unitId)
    local firstUnit, firstThreat, _, secondThreat = ThreatFunc(unitId)

    local displayValue

    local threatColorGroup = nameplatesModule.nonTankThreatColors
    if IsTank(UnitName("Player")) then
        threatColorGroup = nameplatesModule.tankThreatColors
    end

    if firstUnit and IsPet(firstUnit) then
        threatStatus = 4
    end

    if firstUnit and IsTank(UnitName(firstUnit)) and not UnitIsUnit(firstUnit, "Player") then
        threatStatus = 5
    end

    if nameplate.UnitFrame then
        if UnitIsPlayer(unitId) and nameplatesModule.classColored then
            local _, class = UnitClass(unitId)
            local color = RAID_CLASS_COLORS[class]
            nameplate.UnitFrame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
        elseif UnitIsTapDenied(unitId) then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
        elseif threatStatus == nil then
            local red, green, blue, alpha = UnitSelectionColor(unitId, true)
            nameplate.UnitFrame.healthBar:SetStatusBarColor(red, green, blue, alpha)
        elseif threatStatus == 0 or threatStatus == 1 then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.noThreat))
        elseif threatStatus == 2 then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.lowThreat))
        elseif threatStatus == 3 then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.threat))
        elseif threatStatus == 4 then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.pet))
        elseif threatStatus == 5 then
            nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.tank))
        end
    end

    if not threatValue then
        if nameplate.threatAmountText then
            nameplate.threatAmountText:Hide()
        end

        return
    end

    if isTanking then
        displayValue = threatValue - secondThreat
    else
        displayValue = threatValue - firstThreat

        if firstUnit and not UnitIsUnit(firstUnit, "Player") and self.tanks[UnitName(firstUnit)] then
            threatStatus = 4
        end
    end

    -- Update the threat amount text
    if nameplate.UnitFrame and nameplate.threatAmountText then
        if threatValue and threatValue > 0 then
            local r, g, b = nameplate.UnitFrame.healthBar:GetStatusBarColor()
            nameplate.threatAmountText:SetTextColor(r, g, b)

            local text = AbbreviateNumbers(Round(math.abs(displayValue) / 100))
            nameplate.threatAmountText:SetText(text)
            nameplate.threatAmountText:Show()
        else
            nameplate.threatAmountText:Hide()
        end
    end

    return true
end

function ScarletUI:UpdateTargetArrows()
    local module = self.db.global.nameplatesModule
    if not module.targetIndicator.show then
        HideTargetArrows()
        return
    end

    -- Hide arrows on the previous nameplate
    HideTargetArrows()

    local nameplate = C_NamePlate.GetNamePlateForUnit("target")
    if nameplate then
        -- Get the name text region of the nameplate.
        local healthBarRegion = nameplate.UnitFrame
        local size = module.targetIndicator.indicatorSize
        local spacer = module.targetIndicator.indicatorDistance * -1
        local height = module.targetIndicator.indicatorHeight

        if healthBarRegion then
            -- Create a dedicated overlay frame so arrows draw above all nameplate children
            if not nameplate.arrowFrame then
                nameplate.arrowFrame = CreateFrame("Frame", nil, nameplate.UnitFrame)
                nameplate.arrowFrame:SetAllPoints()
                nameplate.arrowFrame:SetFrameLevel(nameplate.UnitFrame:GetFrameLevel() + 10)
            end

            -- Left texture (create once, reuse)
            if not nameplate.leftArrow then
                nameplate.leftArrow = nameplate.arrowFrame:CreateTexture(nil, "OVERLAY")
                nameplate.leftArrow:SetTexture("interface/minimap/minimaparrow.blp")
                nameplate.leftArrow:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
            end
            nameplate.leftArrow:ClearAllPoints()
            nameplate.leftArrow:SetSize(size, size)
            nameplate.leftArrow:SetPoint("RIGHT", healthBarRegion, "LEFT", spacer, height)
            nameplate.leftArrow:Show()

            -- Right texture (create once, reuse)
            if not nameplate.rightArrow then
                nameplate.rightArrow = nameplate.arrowFrame:CreateTexture(nil, "OVERLAY")
                nameplate.rightArrow:SetTexture("interface/minimap/minimaparrow.blp")
                nameplate.rightArrow:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
            end
            nameplate.rightArrow:ClearAllPoints()
            nameplate.rightArrow:SetSize(size, size)
            nameplate.rightArrow:SetPoint("LEFT", healthBarRegion, "RIGHT", spacer * -1, height)
            nameplate.rightArrow:Show()
        end

        lastNameplate = nameplate
    end
end

function ScarletUI:SetupTanks(module)
    self.tanks = split(module.tankNames)
end

function ScarletUI:SetupSpecialUnits(module)
    self.specialUnits = split(module.specialUnitNames)
end

function ScarletUI:SetupPriorityDebuffs()
    local database = self.db.char
    self.priorityDebuffs = split(database.priorityDebuffs)
end

function ScarletUI:SetupDropdownButton(module)
    local nameplatesModule = self.db.global.nameplatesModule
    if self.dropdownEventRegistered then
        return
    end

    self.dropdownEventRegistered = true
    hooksecurefunc("UnitPopup_ShowMenu", function(_, which, unit, ...)
        if not module.dropdownMenuButton then
            return
        end

        -- if the menu is already open or the unit can't cooperate with the player then return
        if UIDROPDOWNMENU_MENU_LEVEL > 1 or not UnitIsPlayer(unit) or (not UnitCanCooperate("player", unit) and not UnitIsPlayer(unit)) then
            return
        end

        -- add separator to dropdown
        UIDropDownMenu_AddSeparator()

        -- add ScarletUI title to dropdown
        local title = UIDropDownMenu_CreateInfo();
        title.text = "ScarletUI"
        title.notCheckable = true
        title.isTitle = true
        UIDropDownMenu_AddButton(title)

        local tankNames = {}
        local function updateTankNames()
            local count = 0;
            for key, value in pairs(self.tanks) do
                if value then
                    table.insert(tankNames, key)
                    nameplatesModule.tankNames = table.concat(tankNames, ",");
                end

                count = count + 1
            end

            if count == 0 then
                nameplatesModule.tankNames = ""
            end

            AceConfigRegistry:NotifyChange("ScarletUI")
        end

        -- add the "Add/Remove Tank" button to the context menu
        local button = UIDropDownMenu_CreateInfo();
        button.notCheckable = true
        button.owner = which
        button.colorCode = "|cff00b3ff"
        button.text = "Add Tank"
        button.value = "Add_Tank"
        button.func = function()
            local name, _ = UnitName(unit)
            self.tanks[name] = true
            updateTankNames()
        end;

        for tank, _ in pairs(self.tanks) do
            local name, _ = UnitName(unit)
            if name == tank then
                button.text = "Remove Tank"
                button.value = "Remove_Tank"
                button.func = function()
                    self.tanks[tank] = nil
                    updateTankNames()
                end;

                break
            end
        end

        UIDropDownMenu_AddButton(button)
    end)
end

function ScarletUI:SetupNameplates()
    local nameplatesModule = self.db.global.nameplatesModule
    if not nameplatesModule.enabled or self.lightWeightMode then
        return
    end

    self:SetupTanks(nameplatesModule)
    self:SetupSpecialUnits(nameplatesModule)
    self:SetupPriorityDebuffs()
    --self:SetupDropdownButton(nameplatesModule)

    if not self.nameplateEventsRegistered then
        self.nameplateEventsRegistered = true

        -- Hook Blizzard's health color update so our threat colors aren't overwritten
        if CompactUnitFrame_UpdateHealthColor then
            hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
                if frame and frame.unit and strmatch(frame.unit, "^nameplate") then
                    ScarletUI:UpdateNameplate(frame.unit)
                end
            end)
        end

        self:RegisterEventHandler("PLAYER_TARGET_CHANGED", function()
            if ScarletUI.pauseEvents then return end
            ScarletUI:UpdateTargetArrows()
        end)

        self:RegisterEventHandler("UNIT_AURA", function(_, unitId)
            if ScarletUI.pauseEvents then return end
            ScarletUI:CheckUnitAuras(unitId)
        end)

        self:RegisterEventHandler("NAME_PLATE_UNIT_ADDED", function(_, unitId)
            if ScarletUI.pauseEvents then return end
            ScarletUI:CheckUnitAuras(unitId)
            ScarletUI:UpdateNameplate(unitId)
            ScarletUI:UpdateTargetArrows()

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
            if nameplate then
                SetupNameplate(nameplate)
            end
        end)

        self:RegisterEventHandler("NAME_PLATE_UNIT_REMOVED", function(_, unitId)
            if ScarletUI.pauseEvents then return end
            ScarletUI:CheckUnitAuras(unitId)
            ScarletUI:UpdateNameplate(unitId)
        end)

        self:RegisterEventHandler("UNIT_THREAT_LIST_UPDATE", function(_, unitId)
            if ScarletUI.pauseEvents then return end
            if unitId then
                dirtyThreatUnits[unitId] = true
            end
        end)
    end
end

local function HideAuraIcons(nameplate, key)
    for name, data in pairs(nameplate and nameplate[key] or {}) do
        data.icon:Hide()
        nameplate[key][name] = nil
    end
end

function ScarletUI:CheckUnitAuras(unitId)
    self:CheckUnitDebuffs(unitId)
    self:CheckUnitBuffs(unitId)
end

function ScarletUI:CheckUnitDebuffs(unitId)
    local settings = self.db.global.nameplatesModule.debuffTracker
    local nameplate = unitId and C_NamePlate.GetNamePlateForUnit(unitId)
    if not nameplate then
        return
    elseif not settings.track then
        HideAuraIcons(nameplate, "myDebuffIcons")
        return
    end

    nameplate.myDebuffIcons = nameplate.myDebuffIcons or {}
    nameplate.myDebuffNames = nameplate.myDebuffNames or {}

    local i = 1
    local debuffName, icon, count, _, duration, expireTime, source = UnitDebuff(unitId, i)

    -- store and display debuffs for each unit
    local plateDebuffs = {}
    while debuffName do
        if source == "player" or self.priorityDebuffs[debuffName] then
            plateDebuffs[debuffName] = true
            ScarletUI:DisplayDebuffIcon(settings, nameplate, debuffName, icon, count, duration, expireTime)
        end
        i = i + 1
        debuffName, icon, count, _, duration, expireTime, source = UnitDebuff(unitId, i)
    end

    -- Remove icons for debuffs no longer on the unit
    for name, _icon in pairs(nameplate.myDebuffIcons) do
        if not plateDebuffs[name] then
            _icon.icon:Hide()
            nameplate.myDebuffIcons[name] = nil
        end
    end

    -- Sort and reposition the icons based on remaining duration
    local sortedDebuffs = {}
    for _, debuffData in pairs(nameplate.myDebuffIcons) do
        if debuffData.icon:IsShown() then
            table.insert(sortedDebuffs, debuffData)
        end
    end

    -- Sorting the table in ascending order of expireTime.
    table.sort(sortedDebuffs, function(a, b) return a.expireTime < b.expireTime end)

    -- Reposition and resize icons
    local shownCount = 0
    local totalWidth = #sortedDebuffs * (settings.iconSize + settings.spacing)
    for _, debuffData in ipairs(sortedDebuffs) do
        debuffData.icon:SetSize(settings.iconSize, settings.iconSize)
        debuffData.icon:Hide()

        local xOffset = (shownCount * (settings.iconSize + settings.spacing)) - totalWidth / 2
        debuffData.icon:SetPoint('BOTTOMLEFT', nameplate, 'CENTER' , xOffset, settings.verticalOffset)
        debuffData.icon:Show()
        shownCount = shownCount + 1
    end
end

local function IsPurgeClass()
    local _, class = UnitClass("player")
    return class == "PRIEST" or class == "SHAMAN" or class == "MAGE"
end

function ScarletUI:CheckUnitBuffs(unitId)
    local settings = self.db.global.nameplatesModule.buffTracker
    local nameplate = unitId and C_NamePlate.GetNamePlateForUnit(unitId)
    if not nameplate then
        return
    elseif not settings.track then
        HideAuraIcons(nameplate, "myBuffIcons")
        return
    end

    nameplate.myBuffIcons = nameplate.myBuffIcons or {}

    local i = 1
    local buffName, icon, count, debuffType, duration, expireTime, _, _, _, spellId = UnitBuff(unitId, i)

    -- store and display buffs for each unit
    local plateBuffs = {}
    while buffName do
        if UnitIsEnemy("player", unitId) and IsPurgeClass() and debuffType == "Magic" then
            plateBuffs[buffName] = true
            ScarletUI:DisplayBuffIcon(settings, nameplate, buffName, icon, count, duration, expireTime)
        end
        i = i + 1
        buffName, icon, count, debuffType, duration, expireTime, _, _, _, spellId = UnitBuff(unitId, i)
    end

    -- Remove icons for buffs no longer on the unit
    for name, _icon in pairs(nameplate.myBuffIcons) do
        if not plateBuffs[name] then
            _icon.icon:Hide()
            nameplate.myBuffIcons[name] = nil
        end
    end

    -- Sort and reposition the icons based on remaining duration
    local sortedBuffs = {}
    for _, buffData in pairs(nameplate.myBuffIcons) do
        if buffData.icon:IsShown() then
            table.insert(sortedBuffs, buffData)
        end
    end

    -- Sorting the table in ascending order of expireTime.
    table.sort(sortedBuffs, function(a, b) return a.expireTime < b.expireTime end)

    -- Reposition and resize icons
    local shownCount = 0
    local totalWidth = #sortedBuffs * (settings.iconSize + settings.spacing)
    for _, buffData in ipairs(sortedBuffs) do
        buffData.icon:SetSize(settings.iconSize, settings.iconSize)
        buffData.icon:Hide()

        local xOffset = (shownCount * (settings.iconSize + settings.spacing)) - totalWidth / 2
        buffData.icon:SetPoint('BOTTOMLEFT', nameplate, 'CENTER' , xOffset, settings.verticalOffset + settings.iconSize + settings.spacing)
        buffData.icon:Show()
        shownCount = shownCount + 1
    end
end

function ScarletUI:ReapplySettingsToAuraIcons()
    local activeNameplates = C_NamePlate.GetNamePlates()

    for _, nameplate in ipairs(activeNameplates) do
        self:CheckUnitAuras(nameplate.UnitFrame and nameplate.UnitFrame.unit)
    end
end

function ScarletUI:DisplayDebuffIcon(settings, plate, debuffName, icon, count, duration, expireTime)
    -- Initialize the debuff frame pool for the nameplate
    plate.debuffFramePool = plate.debuffFramePool or {}

    if not plate.myDebuffIcons then
        plate.myDebuffIcons = {}
    end

    local debuffIcon
    if not plate.myDebuffIcons[debuffName] then
        -- Check if there's an unused frame in the pool
        for _, frame in ipairs(plate.debuffFramePool) do
            if not frame:IsShown() then
                debuffIcon = frame
                break
            end
        end

        -- If there's no unused frame, create a new one
        if not debuffIcon then
            debuffIcon = CreateFrame("Frame", nil, plate)
            debuffIcon:SetSize(settings.iconSize, settings.iconSize)

            debuffIcon.icon = debuffIcon:CreateTexture(nil)
            debuffIcon.icon:SetAllPoints()

            debuffIcon.cooldown = CreateFrame("Cooldown", nil, debuffIcon, "CooldownFrameTemplate")
            debuffIcon.cooldown:SetAllPoints()
            debuffIcon.cooldown:SetReverse(true)

            debuffIcon.stack = debuffIcon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            debuffIcon.stack:SetPoint("BOTTOMRIGHT", -2, 2)

            local fontName, _, fontFlags = debuffIcon.stack:GetFont()
            debuffIcon.stack:SetFont(fontName, 11, fontFlags)

            -- Add the new frame to the pool
            table.insert(plate.debuffFramePool, debuffIcon)
        end

        plate.myDebuffIcons[debuffName] = { icon = debuffIcon, expireTime = expireTime }
    else
        debuffIcon = plate.myDebuffIcons[debuffName].icon
        plate.myDebuffIcons[debuffName].expireTime = expireTime
    end

    -- Update the debuff icon information
    debuffIcon.icon:SetTexture(icon)
    if count and tonumber(count) >= 1 then
        debuffIcon.stack:SetText(count)
    else
        debuffIcon.stack:SetText("")
    end
    local startTime = expireTime - duration
    debuffIcon.cooldown:SetCooldown(startTime, duration)
    debuffIcon:Show()
end

function ScarletUI:DisplayBuffIcon(settings, plate, buffName, icon, count, duration, expireTime)
    -- Initialize the buff frame pool for the nameplate
    plate.buffFramePool = plate.buffFramePool or {}

    if not plate.myBuffIcons then
        plate.myBuffIcons = {}
    end

    local buffIcon
    if not plate.myBuffIcons[buffName] then
        -- Check if there's an unused frame in the pool
        for _, frame in ipairs(plate.buffFramePool) do
            if not frame:IsShown() then
                buffIcon = frame
                break
            end
        end

        -- If there's no unused frame, create a new one
        if not buffIcon then
            buffIcon = CreateFrame("Frame", nil, plate)
            buffIcon:SetSize(settings.iconSize, settings.iconSize)

            buffIcon.icon = buffIcon:CreateTexture(nil)
            buffIcon.icon:SetAllPoints()

            buffIcon.cooldown = CreateFrame("Cooldown", nil, buffIcon, "CooldownFrameTemplate")
            buffIcon.cooldown:SetAllPoints()
            buffIcon.cooldown:SetReverse(true)

            buffIcon.stack = buffIcon:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
            buffIcon.stack:SetPoint("BOTTOMRIGHT", -2, 2)

            local fontName, _, fontFlags = buffIcon.stack:GetFont()
            buffIcon.stack:SetFont(fontName, 11, fontFlags)

            -- Add the new frame to the pool
            table.insert(plate.buffFramePool, buffIcon)
        end

        plate.myBuffIcons[buffName] = { icon = buffIcon, expireTime = expireTime }
    else
        buffIcon = plate.myBuffIcons[buffName].icon
        plate.myBuffIcons[buffName].expireTime = expireTime
    end

    -- Update the buff icon information
    buffIcon.icon:SetTexture(icon)
    if count and tonumber(count) >= 1 then
        buffIcon.stack:SetText(count)
    else
        buffIcon.stack:SetText("")
    end
    local startTime = expireTime - duration
    buffIcon.cooldown:SetCooldown(startTime, duration)
    buffIcon:Show()
end

function ScarletUI:GetNameplatesModuleSettingsPage(database, defaults, order)
    local module = database.nameplatesModule;
    local characterDatabase = self.db.char;

    local function ModuleOff() return ScarletUI:SettingDisabled(module.enabled, true) end

    local function Toggle(name, desc, toggleOrder, settings, key, apply, width)
        return {
            name = name,
            desc = desc,
            type = "toggle",
            width = width or "full",
            order = toggleOrder,
            get = function(_) return module[settings][key] end,
            set = function(_, val)
                module[settings][key] = val
                apply()
            end,
        }
    end

    local function Slider(name, desc, min, max, sliderOrder, settings, key, apply)
        return {
            name = name,
            desc = desc .. "\n(Default " .. defaults[settings][key] .. ")",
            type = "range",
            min = min,
            max = max,
            step = 1,
            width = 1,
            order = sliderOrder,
            get = function(_) return module[settings][key] end,
            set = function(_, val)
                module[settings][key] = val
                apply()
            end,
        }
    end

    local function Color(name, colorOrder, settings, key)
        return {
            name = name,
            type = "color",
            width = 0.75,
            hasAlpha = true,
            order = colorOrder,
            get = function(_) return unpack(module[settings][key]) end,
            set = function(_, r, g, b, a) module[settings][key] = { r, g, b, a } end,
        }
    end

    local function ReapplyAuras() self:ReapplySettingsToAuraIcons() end
    local function AuraGroup(name, what, groupOrder, settings)
        return {
            name = name,
            type = "group",
            inline = true,
            order = groupOrder,
            args = {
                track = Toggle("Show", "Show " .. what .. " and their durations on the nameplates.", 0, settings, "track", ReapplyAuras),
                iconSize = Slider("Icon Size", "Size of the icons.", 1, 100, 1, settings, "iconSize", ReapplyAuras),
                spacing = Slider("Icon Spacing", "Space between the icons.", 0, 100, 2, settings, "spacing", ReapplyAuras),
                verticalOffset = Slider("Vertical Offset", "How far above or below the nameplate the icon row sits.", -100, 100, 3, settings, "verticalOffset", ReapplyAuras),
            },
        }
    end

    local function ReapplyText() self:ReapplyTextSettingsToNameplates() end
    local function TextGroup(name, what, groupOrder, settings)
        return {
            name = name,
            type = "group",
            inline = true,
            order = groupOrder,
            args = {
                show = Toggle("Show", "Show " .. what .. " on nameplates.", 0, settings, "show", ReapplyText, 0.5),
                fontSize = Slider("Font Size", "Font size for " .. what .. ".", 6, 20, 1, settings, "fontSize", ReapplyText),
            },
        }
    end

    local function ThreatGroup(name, groupOrder, settings)
        return {
            name = name,
            type = "group",
            inline = true,
            order = groupOrder,
            args = {
                noThreat = Color("No Threat", 0, settings, "noThreat"),
                lowThreat = Color("Low Threat", 1, settings, "lowThreat"),
                threat = Color("Have Threat", 2, settings, "threat"),
                pet = Color("Pet Threat", 3, settings, "pet"),
                tank = Color("Tank Threat", 4, settings, "tank"),
            },
        }
    end

    local function UpdateArrows() ScarletUI:UpdateTargetArrows() end

    local auras = {
        buffs = AuraGroup("Purgeable Buffs", "purgeable buffs", 0, "buffTracker"),
        debuffs = AuraGroup("Debuffs", "debuffs", 1, "debuffTracker"),
    }
    auras.debuffs.args.priorityDebuffs = {
        name = "Priority Debuffs",
        type = "input",
        desc = "Debuffs to always show, even when another player applied them. Separate spell names with commas, for example: Sunder Armor,Expose Armor,Hammer of Justice\n\nSaved per character.",
        width = "full",
        order = 4,
        get = function(_) return characterDatabase.priorityDebuffs end,
        set = function(_, value)
            characterDatabase.priorityDebuffs = value
            self:SetupPriorityDebuffs()
        end,
    }

    return {
        name = "Nameplates",
        desc = "Nameplate threat colors, auras, and text.",
        type = "group",
        childGroups = "tab",
        order = order,
        hidden = function() return self.lightWeightMode end,
        args = {
            enabled = {
                name = "Enable Nameplates",
                desc = "Add threat colors, auras, and text to Blizzard's nameplates. Turning this off reloads the UI.",
                type = "toggle",
                disabled = function() return self:InCombat() end,
                width = 1,
                order = 0,
                get = function(_) return module.enabled end,
                set = function(_, val)
                    module.enabled = val
                    if not val then
                        self:ShowReloadDialog()
                    else
                        self:SetupNameplates()
                    end
                end,
            },
            classColored = {
                name = "Class Colors",
                desc = "Color player nameplates by class.",
                type = "toggle",
                disabled = ModuleOff,
                width = 1,
                order = 1,
                get = function(_) return module.classColored end,
                set = function(_, val) module.classColored = val end,
            },
            auras = {
                name = "Auras",
                type = "group",
                disabled = ModuleOff,
                order = 2,
                args = auras,
            },
            targetIndicator = {
                name = "Target Indicator",
                type = "group",
                disabled = ModuleOff,
                order = 3,
                args = {
                    show = Toggle("Show", "Add arrows around your target's nameplate.", 0, "targetIndicator", "show", UpdateArrows),
                    indicatorSize = Slider("Size", "Size of the target arrows.", -100, 100, 1, "targetIndicator", "indicatorSize", UpdateArrows),
                    indicatorDistance = Slider("Distance", "Space between the target arrows and the nameplate.", -100, 100, 2, "targetIndicator", "indicatorDistance", UpdateArrows),
                    indicatorHeight = Slider("Height", "Vertical position of the target arrows.", -100, 100, 3, "targetIndicator", "indicatorHeight", UpdateArrows),
                },
            },
            text = {
                name = "Text",
                type = "group",
                disabled = ModuleOff,
                order = 4,
                args = {
                    healthBarText = TextGroup("Health Bar Text", "health text", 0, "healthBarText"),
                    threatAmountText = TextGroup("Threat Text", "threat text", 1, "threatAmountText"),
                    castBarText = TextGroup("Cast Bar Text", "cast bar text", 2, "castBarText"),
                },
            },
            threatColors = {
                name = "Threat Colors",
                type = "group",
                disabled = ModuleOff,
                order = 5,
                args = {
                    threatColored = {
                        name = "Color by Threat",
                        desc = "Color enemy NPC nameplates by your threat on them.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.threatColored end,
                        set = function(_, val) module.threatColored = val end,
                    },
                    nonTank = ThreatGroup("As |cffff0900DPS|r or |cff15fb00Healer|r", 1, "nonTankThreatColors"),
                    tank = ThreatGroup("As |cff00b3ffTank|r", 2, "tankThreatColors"),
                    tankNames = {
                        name = "Tank Names",
                        type = "input",
                        desc = "Players to treat as tanks. Separate names with commas, for example: Tank1,Tank2,Tank3\n\nPlayers with the tank role (on clients that have roles) and players marked Main Tank or Main Assist in a raid already count as tanks.",
                        width = "full",
                        order = 3,
                        get = function(_) return module.tankNames end,
                        set = function(_, value)
                            module.tankNames = value
                            self:SetupTanks(module)
                        end,
                    },
                },
            },
            specialUnits = {
                name = "Special Units",
                type = "group",
                disabled = ModuleOff,
                order = 6,
                args = {
                    specialUnitsColored = {
                        name = "Color Special Units",
                        desc = "Color the nameplates of the enemy units named below.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.specialUnitsColored end,
                        set = function(_, val) module.specialUnitsColored = val end,
                    },
                    specialUnitColor = {
                        name = "Color",
                        type = "color",
                        desc = "Nameplate color for special units.",
                        width = 1,
                        hasAlpha = true,
                        order = 1,
                        get = function(_) return unpack(module.specialUnitColor) end,
                        set = function(_, r, g, b, a) module.specialUnitColor = { r, g, b, a } end,
                    },
                    specialUnitNames = {
                        name = "Special Unit Names",
                        type = "input",
                        desc = "Enemy units to color as special units. Separate names with commas, for example: Unit1,Unit2,Unit3",
                        width = "full",
                        order = 2,
                        get = function(_) return module.specialUnitNames end,
                        set = function(_, value)
                            module.specialUnitNames = value
                            self:SetupSpecialUnits(module)
                        end,
                    }
                }
            }
        }
    }
end
