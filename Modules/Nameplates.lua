local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local lastNameplate

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

local function IterateGroupMembers()
    local i = 0
    local max = IsInRaid() and GetNumGroupMembers() or IsInGroup() and GetNumGroupMembers() or 1
    local prefix = IsInRaid() and "raid" or "party"

    return function()
        i = i + 1
        if i == 1 then
            return "player"
        elseif i <= max + 1 then
            return prefix .. (i - 1)
        end
    end
end

local function ThreatFunc(unit)
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

        pet = member.."pet"
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

    return false
end

local function IsTank(playerName)
    local mainTank = GetPartyAssignment("MAINTANK", playerName)
    local mainAssist = GetPartyAssignment("MAINASSIST", playerName)

    -- Check if the player has the tank role
    if mainTank or mainAssist then
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
    elseif healthBar.healthBarText then
        healthBar.healthBarText:Hide()
    end

    if module.threatAmountText.show then
        if not nameplate.threatAmountText then
            nameplate.threatAmountText = nameplate:CreateFontString(nil, "OVERLAY", "GameFontWhite")
            nameplate.threatAmountText:SetPoint("RIGHT", nameplate.UnitFrame.healthBar, "LEFT", -30, 0)
            nameplate.threatAmountText:SetFont("Fonts\\FRIZQT__.TTF", module.threatAmountText.fontSize, "OUTLINE")
        else
            nameplate.threatAmountText:SetFont("Fonts\\FRIZQT__.TTF", module.threatAmountText.fontSize, "OUTLINE")
        end
    elseif nameplate.threatAmountText then
        nameplate.threatAmountText:Hide()
    end

    local castBar = nameplate.UnitFrame and nameplate.UnitFrame.CastBar
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
    elseif castBar.castBarText then
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
        local abilityName = castBar.Text and castBar.Text:GetText()
        if castBar.castBarText then
            castBar.castBarText:SetText(abilityName)
            castBar.castBarText:Show()
        end
    end
end

function ScarletUI:UpdateHealthText(healthBar)
    if healthBar then
        local unitID = healthBar:GetParent().unit or healthBar.unit
        local healthPercent = (UnitHealth(unitID) / UnitHealthMax(unitID)) * 100;
        if healthBar.healthBarText then
            healthBar.healthBarText:SetText(string.format("%.0f%%", healthPercent))
            healthBar.healthBarText:Show()
        end
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

    if not nameplate then
        return
    end

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
        local healthBarRegion = nameplate and nameplate.UnitFrame and nameplate.UnitFrame.healthBar.border
        local size = module.targetIndicator.indicatorSize
        local spacer = module.targetIndicator.indicatorDistance * -1
        local height = module.targetIndicator.indicatorHeight

        if healthBarRegion then
            -- Left texture
            local leftTexture = nameplate:CreateTexture(nil, "OVERLAY")
            leftTexture:SetTexture("interface/minimap/minimaparrow.blp")
            leftTexture:SetSize(size, size)
            leftTexture:SetPoint("RIGHT", healthBarRegion, "LEFT", spacer, height)
            leftTexture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
            nameplate.leftArrow = leftTexture

            -- Right texture
            local rightTexture = nameplate:CreateTexture(nil, "OVERLAY")
            rightTexture:SetTexture("interface/minimap/minimaparrow.blp")
            rightTexture:SetSize(size, size)
            rightTexture:SetPoint("LEFT", healthBarRegion, "RIGHT", spacer * -1, height)
            rightTexture:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)
            nameplate.rightArrow = rightTexture
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
    if not nameplatesModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    self:SetupTanks(nameplatesModule)
    self:SetupSpecialUnits(nameplatesModule)
    self:SetupPriorityDebuffs()
    --self:SetupDropdownButton(nameplatesModule)

    if not self.nameplateEventsRegistered then
        self.nameplateEventsRegistered = true
        self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
        self.frame:RegisterEvent("UNIT_AURA")
        self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
        self.frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
        self.frame:HookScript("OnEvent", function(_, event, unitId, ...)
            if ScarletUI.pauseEvents then
                return
            end

            if event == "PLAYER_TARGET_CHANGED" then
                ScarletUI:UpdateTargetArrows()
            end

            if event == "UNIT_AURA" then
                ScarletUI:CheckUnitAuras(unitId)
            end

            if event == "NAME_PLATE_UNIT_ADDED" then
                ScarletUI:CheckUnitAuras(unitId)
                ScarletUI:UpdateNameplate(unitId)
                ScarletUI:UpdateTargetArrows()

                local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
                if nameplate then
                    SetupNameplate(nameplate)
                end
            end

            if event == "NAME_PLATE_UNIT_REMOVED" then
                ScarletUI:CheckUnitAuras(unitId)
                ScarletUI:UpdateNameplate(unitId)
            end

            if event == "UNIT_THREAT_LIST_UPDATE" then
                ScarletUI:UpdateNameplate(unitId)
            end
        end)
    end
end

function ScarletUI:CheckUnitAuras(unitId)
    self:CheckUnitDebuffs(unitId)
    self:CheckUnitBuffs(unitId)
end

function ScarletUI:CheckUnitDebuffs(unitId)
    local settings = self.db.global.nameplatesModule.debuffTracker
    if not settings.track or not unitId then
        return
    end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
    if not nameplate then
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
    if not settings.track or not unitId then
        return
    end

    local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
    if not nameplate then
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
        self:CheckUnitAuras(nameplate.UnitFrame.unit)
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
