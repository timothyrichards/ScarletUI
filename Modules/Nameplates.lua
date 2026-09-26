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

    return {
        name = "Nameplates",
        desc = "Nameplates Module settings.",
        type = "group",
        childGroups = "tab",
        order = order,
        hidden = function() return self.lightWeightMode end,
        args = {
            generalSettings = {
                name = "Nameplate Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 0,
                args = {
                    classColored = {
                        name = "Class Colors",
                        desc = "Change player nameplates to match their class color.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.classColored end,
                        set = function(_, val) module.classColored = val end,
                    },
                    threatColored = {
                        name = "Threat Colors",
                        desc = "Change enemy npc nameplates to reflect their threat status as a color (colors and tank names adjusted below).",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return module.threatColored end,
                        set = function(_, val) module.threatColored = val end,
                    },
                    specialUnitsColored = {
                        name = "Special Unit Colors",
                        desc = "Change nameplates the special unit coloring based on name if defined (colors and unit names adjusted below).",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return module.specialUnitsColored end,
                        set = function(_, val) module.specialUnitsColored = val end,
                    },
                }
            },
            debuffTracker = {
                name = "Buff/Debuff Tracker",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 1,
                args = {
                    trackBuffs = {
                        name = "Track Purgable Buffs",
                        desc = "Show purgable buffs and their durations on the nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.buffTracker.track end,
                        set = function(_, val)
                            module.buffTracker.track = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    iconSizeBuffs = {
                        name = "Icon Size",
                        desc = "Must be a number, this is the size of the debuff icons.\n(Default " .. defaults.debuffTracker.iconSize .. ")",
                        type = "range",
                        min = 1,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.buffTracker.iconSize end,
                        set = function(_, val)
                            module.buffTracker.iconSize = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    spacingBuffs = {
                        name = "Icon Spacing",
                        desc = "Must be a number, this is the space between the debuff icons.\n(Default " .. defaults.debuffTracker.spacing .. ")",
                        type = "range",
                        min = 0,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.buffTracker.spacing end,
                        set = function(_, val)
                            module.buffTracker.spacing = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    verticalOffsetBuffs = {
                        name = "Vertical Offset",
                        desc = "Must be a number, this is the vertical offset of the debuff row from the nameplate.\n(Default " .. defaults.debuffTracker.verticalOffset .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.buffTracker.verticalOffset end,
                        set = function(_, val)
                            module.buffTracker.verticalOffset = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    trackDebuffs = {
                        name = "Track Debuffs",
                        desc = "Show debuffs and their durations on the nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 4,
                        get = function(_) return module.debuffTracker.track end,
                        set = function(_, val)
                            module.buffTracker.track = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    iconSizeDebuffs = {
                        name = "Icon Size",
                        desc = "Must be a number, this is the size of the debuff icons.\n(Default " .. defaults.debuffTracker.iconSize .. ")",
                        type = "range",
                        min = 1,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.debuffTracker.iconSize end,
                        set = function(_, val)
                            module.debuffTracker.iconSize = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    spacingDebuffs = {
                        name = "Icon Spacing",
                        desc = "Must be a number, this is the space between the debuff icons.\n(Default " .. defaults.debuffTracker.spacing .. ")",
                        type = "range",
                        min = 0,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.debuffTracker.spacing end,
                        set = function(_, val)
                            module.debuffTracker.spacing = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    verticalOffsetDebuffs = {
                        name = "Vertical Offset",
                        desc = "Must be a number, this is the vertical offset of the debuff row from the nameplate.\n(Default " .. defaults.debuffTracker.verticalOffset .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 7,
                        get = function(_) return module.debuffTracker.verticalOffset end,
                        set = function(_, val)
                            module.debuffTracker.verticalOffset = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    priorityDebuffs = {
                        name = "Priority Debuffs",
                        type = "input",
                        desc = "Add a comma seperated list of debuff spell names you wish to always track even if they're applied by another player, for example: Sunder Armor,Expose Armor,Hammer of Justice\n(This setting is saved per character)",
                        width = "full",
                        order = 8,
                        get = function(_) return characterDatabase.priorityDebuffs end,
                        set = function(_, value)
                            characterDatabase.priorityDebuffs = value
                            self:SetupPriorityDebuffs()
                        end,
                    },
                }
            },
            targetIndicator = {
                name = "Target Indicator",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 2,
                args = {
                    show = {
                        name = "Show",
                        desc = "Add target indicator to nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 1,
                        get = function(_) return module.targetIndicator.show end,
                        set = function(_, val)
                            module.targetIndicator.show = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    },
                    indicatorSize = {
                        name = "Indicator Size",
                        desc = "Must be a number, this is the size of the target arrows around the nameplate.\n(Default " .. defaults.targetIndicator.indicatorSize .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.targetIndicator.indicatorSize end,
                        set = function(_, val)
                            module.targetIndicator.indicatorSize = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    },
                    indicatorDistance = {
                        name = "Indicator Distance",
                        desc = "Must be a number, this is the space of the target arrows around the nameplate.\n(Default " .. defaults.targetIndicator.indicatorDistance .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.targetIndicator.indicatorDistance end,
                        set = function(_, val)
                            module.targetIndicator.indicatorDistance = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    },
                    indicatorHeight = {
                        name = "Indicator Height",
                        desc = "Must be a number, this is the height of the target arrows on the nameplate.\n(Default " .. defaults.targetIndicator.indicatorHeight .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 4,
                        get = function(_) return module.targetIndicator.indicatorHeight end,
                        set = function(_, val)
                            module.targetIndicator.indicatorHeight = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    }
                },
            },
            text = {
                name = "Text",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 3,
                args = {
                    healthBarText = {
                        name = "Health Bar Text",
                        type = "group",
                        inline = true,
                        order = 0,
                        args = {
                            show = {
                                name = "Show",
                                desc = "Add health text to health bar on nameplates.",
                                type = "toggle",
                                width = 0.5,
                                order = 1,
                                get = function(_) return module.healthBarText.show end,
                                set = function(_, val)
                                    module.healthBarText.show = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                desc = "Desired font size for health bar text.\n(Default " .. defaults.healthBarText.fontSize .. ")",
                                type = "range",
                                min = 6,
                                max = 20,
                                step = 1,
                                width = 1,
                                order = 4,
                                get = function(_) return module.healthBarText.fontSize end,
                                set = function(_, val)
                                    module.healthBarText.fontSize = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            }
                        },
                    },
                    threatAmountText = {
                        name = "Threat Text",
                        type = "group",
                        inline = true,
                        order = 1,
                        args = {
                            show = {
                                name = "Show",
                                desc = "Add threat text next to nameplates.",
                                type = "toggle",
                                width = 0.5,
                                order = 1,
                                get = function(_) return module.threatAmountText.show end,
                                set = function(_, val)
                                    module.threatAmountText.show = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                desc = "Desired font size for cast threat text.\n(Default " .. defaults.threatAmountText.fontSize .. ")",
                                type = "range",
                                min = 6,
                                max = 20,
                                step = 1,
                                width = 1,
                                order = 4,
                                get = function(_) return module.threatAmountText.fontSize end,
                                set = function(_, val)
                                    module.threatAmountText.fontSize = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            --anchor = {
                            --    name = "Text Anchor",
                            --    desc = "Anchor point of the frame.\n(Default " .. defaults.threatAmountText.anchor .. ")",
                            --    type = "select",
                            --    width = 1,
                            --    order = 4,
                            --    values = function() return { "LEFT", "RIGHT" } end,
                            --    get = function(_) return module.threatAmountText.anchor end,
                            --    set = function(_, val)
                            --        module.threatAmountText.anchor = val
                            --    end,
                            --},
                        },
                    },
                    castBarText = {
                        name = "Cast Bar Text",
                        type = "group",
                        inline = true,
                        order = 2,
                        args = {
                            show = {
                                name = "Show",
                                desc = "Add cast text to cast bar on nameplates.",
                                type = "toggle",
                                width = 0.5,
                                order = 1,
                                get = function(_) return module.castBarText.show end,
                                set = function(_, val)
                                    module.castBarText.show = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                desc = "Desired font size for cast bar text.\n(Default " .. defaults.castBarText.fontSize .. ")",
                                type = "range",
                                min = 6,
                                max = 20,
                                step = 1,
                                width = 1,
                                order = 4,
                                get = function(_) return module.castBarText.fontSize end,
                                set = function(_, val)
                                    module.castBarText.fontSize = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            }
                        },
                    },
                }
            },
            threatColors = {
                name = "Threat Colors",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 5,
                args = {
                    dropdownMenuButton = {
                        name = "Dropdown Menu Button",
                        desc = "Adds a button to the right click dropdown to add or remove tanks from the tank names list. NOTE",
                        type = "toggle",
                        width = "full",
                        disabled = true,
                        order = 0,
                        get = function(_) return module.dropdownMenuButton end,
                        set = function(_, val) module.dropdownMenuButton = val end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 0.1,
                    },
                    description1 = {
                        name = "|cffffd100These are the colors you see as a |cffff0900DPS|r or |cff15fb00Healer|r.|r",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 1,
                    },
                    otherNoThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 2,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.noThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.noThreat = {r, g, b, a}
                        end,
                    },
                    otherLowThreat = {
                        name = "Low Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 3,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.lowThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.lowThreat = {r, g, b, a}
                        end,
                    },
                    otherThreat = {
                        name = "Have Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 4,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.threat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.threat = {r, g, b, a}
                        end,
                    },
                    otherPetThreat = {
                        name = "Pet Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 5,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.pet)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.pet = {r, g, b, a}
                        end,
                    },
                    otherTankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 6,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 6.1,
                    },
                    description2 = {
                        name = "|cffffd100These are the colors you see as a |cff00b3ffTank|r.|r",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 7,
                    },
                    noThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 8,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.noThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.noThreat = {r, g, b, a}
                        end,
                    },
                    lowThreat = {
                        name = "Low Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 9,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.lowThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.lowThreat = {r, g, b, a}
                        end,
                    },
                    threat = {
                        name = "Have Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 10,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.threat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.threat = {r, g, b, a}
                        end,
                    },
                    petThreat = {
                        name = "Pet Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 11,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.pet)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.pet = {r, g, b, a}
                        end,
                    },
                    tankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 12,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                    tankNames = {
                        name = "Tank Names",
                        type = "input",
                        desc = "Add a comma seperated list of player names you wish to manually designate as tanks, for example: Tank1,Tank2,Tank3\n\nPlayers with the role of tank (in versions of WoW that have roles) and players marked Main Tank or Main Assist in raids, will automatically be designated as tanks by the nameplate colors.",
                        width = "full",
                        order = 13,
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
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 8,
                args = {
                    specialUnitColor = {
                        name = "Special Unit Color",
                        type = "color",
                        desc = "Choose a color",
                        width = 1,
                        hasAlpha = true,
                        order = 0,
                        get = function(_)
                            local r, g, b, a = unpack(module.specialUnitColor)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.specialUnitColor = {r, g, b, a}
                        end,
                    },
                    specialUnitNames = {
                        name = "Special Unit Names",
                        type = "input",
                        desc = "Add a comma seperated list of enemy unit names you wish to manually designate as special units, for example: Unit1,Unit2,Unit3",
                        width = "full",
                        order = 1,
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
