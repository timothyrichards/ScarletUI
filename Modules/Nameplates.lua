local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local allStates = {}
local specialUnits = {}
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

local function SetupNameplate(nameplate)
    local module = ScarletUI.db.global.nameplatesModule

    local castBar = nameplate.UnitFrame and nameplate.UnitFrame.CastBar
    if module.castBarText.show then
        if castBar then
            -- Create a font string if it doesn't exist
            if not castBar.castBarText then
                castBar.castBarText = castBar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
                castBar.castBarText:SetPoint("CENTER")
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

    local healthBar = nameplate.UnitFrame and nameplate.UnitFrame.healthBar
    if module.healthBarText.show then
        if healthBar then
            if not healthBar.healthBarText then
                healthBar.healthBarText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontWhite")
                healthBar.healthBarText:SetPoint("CENTER")
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
end

function ScarletUI:UpdateTargetArrows()
    local module = ScarletUI.db.global.nameplatesModule
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
    specialUnits = split(module.specialUnitNames)
end

function ScarletUI:SetupDropdownButton(module)
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
            for key, value in pairs(ScarletUI.tanks) do
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

        local text = "Add Tank"
        local value = "Add_Tank"
        local func = function()
            local name, _ = UnitName(unit)
            ScarletUI.tanks[name] = true
            updateTankNames()
        end;

        for tank, _ in pairs(ScarletUI.tanks) do
            local name, _ = UnitName(unit)
            if name == tank then
                text = "Remove Tank"
                value = "Remove_Tank"
                func = function()
                    ScarletUI.tanks[tank] = nil
                    updateTankNames()
                end;
            end
        end

        -- add the "Add/Remove Tank" button to the context menu
        local button = UIDropDownMenu_CreateInfo();
        button.notCheckable = true
        button.text = text
        button.value = value
        button.owner = which
        button.func = func
        button.colorCode = "|cff00b3ff"
        UIDropDownMenu_AddButton(button)
    end)
end

function ScarletUI:SetupNameplates()
    local nameplatesModule = self.db.global.nameplatesModule
    if not nameplatesModule.enabled or self.inCombat then
        return
    end

    self:SetupTanks(nameplatesModule)
    self:SetupSpecialUnits(nameplatesModule)
    self:SetupDropdownButton(nameplatesModule)
    self.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    self.frame:RegisterEvent("UNIT_AURA")
    self.frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self.frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    self.frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    self.frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    self.frame:HookScript("OnEvent", function(_, event, unitId)
        if event == "UNIT_AURA" or event == "NAME_PLATE_UNIT_ADDED" or event == "NAME_PLATE_UNIT_REMOVED" then
            ScarletUI:CheckUnitDebuffs(unitId, nameplatesModule.debuffTracker)
        end

        if event == "PLAYER_TARGET_CHANGED" then
            ScarletUI:UpdateTargetArrows()
        else
            if not unitId or not UnitExists(unitId) then
                return
            end

            local nameplate = C_NamePlate.GetNamePlateForUnit(unitId)
            local unitName, _ = UnitName(unitId)
            if event == "NAME_PLATE_UNIT_ADDED" then
                ScarletUI:UpdateTargetArrows()
                if nameplate then
                    SetupNameplate(nameplate)
                end
            end

            if nameplatesModule.specialUnitsColored and specialUnits[unitName] and nameplate.UnitFrame then
                nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(nameplatesModule.specialUnitColor))
                return
            end

            if not nameplatesModule.threatColored then
                return
            end

            if event == "NAME_PLATE_UNIT_REMOVED" then
                local state = allStates[unitId]
                if state then
                    state.show = false
                    state.changed = true
                    return true
                end
            else
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

                if firstUnit and IsTank(UnitName(firstUnit)) and not UnitIsUnit(firstUnit, "Player") then
                    threatStatus = 4
                end

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
                    nameplate.UnitFrame.healthBar:SetStatusBarColor(unpack(threatColorGroup.tank))
                end

                if not threatValue then
                    return
                end

                if isTanking then
                    displayValue = threatValue - secondThreat
                else
                    displayValue = threatValue - firstThreat
                    if firstUnit and not UnitIsUnit(firstUnit, "Player") and ScarletUI.tanks[UnitName(firstUnit)] then
                        threatStatus = 4
                    end
                end

                allStates[unitId] = allStates[unitId] or { unit = unitId}
                local state = allStates[unitId]
                state.changed = true
                if string.find(unitId, "nameplate") then
                    state.show = true
                else
                    state.show = false
                end
                state.status = threatStatus < 1 and 1 or threatStatus
                state.value = Round(math.abs(displayValue) / 100)

                return true
            end
        end
    end)
end

-- List all nameplates and check if the specified debuff is present on the unit the nameplate belongs to
function ScarletUI:CheckUnitDebuffs(unitId, settings)
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
    local debuffName, icon, _, _, _, _, source = UnitDebuff(unitId, i)

    -- store and display debuffs for each unit
    local plateDebuffs = {}
    while debuffName do
        if source == "player" then
            plateDebuffs[debuffName] = true
            ScarletUI:DisplayDebuffIcon(settings, nameplate, unitId, debuffName, icon, i)
        end
        i = i + 1
        debuffName, icon, _, _, _, _, source = UnitDebuff(unitId, i)
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

    -- Reposition icons
    local shownCount = 0
    local totalWidth = #sortedDebuffs * (settings.iconSize + settings.spacing)
    for _, debuffData in ipairs(sortedDebuffs) do
        debuffData.icon:Hide()

        local xOffset = (shownCount * (settings.iconSize + settings.spacing)) - totalWidth / 2
        debuffData.icon:SetPoint('BOTTOMLEFT', nameplate, 'CENTER' , xOffset, settings.verticalOffset)
        debuffData.icon:Show()
        shownCount = shownCount + 1
    end
end

-- Display debuff icon on the provided nameplate.
function ScarletUI:DisplayDebuffIcon(settings, plate, unitId, debuffName, icon, debuffIndex)
    if not plate.myDebuffIcons then
        plate.myDebuffIcons = {}
    end

    local debuffIcon
    local _, _, count, _, duration, expireTime = UnitDebuff(unitId, debuffIndex)

    if not plate.myDebuffIcons[debuffName] then
        debuffIcon = CreateFrame("Frame", "_SUI_C_"..debuffName, plate)
        debuffIcon:SetSize(settings.iconSize, settings.iconSize)

        debuffIcon.icon = debuffIcon:CreateTexture("_SUI_I_"..debuffName)
        debuffIcon.icon:SetAllPoints()
        debuffIcon.icon:SetTexture(icon)

        debuffIcon.cooldown = CreateFrame("Cooldown", "_SUI_C_"..debuffName, debuffIcon, "CooldownFrameTemplate")
        debuffIcon.cooldown:SetAllPoints()
        debuffIcon.cooldown:SetReverse(true)

        debuffIcon.stack = debuffIcon:CreateFontString("_SUI_S_"..debuffName, "OVERLAY", "NumberFontNormal")
        debuffIcon.stack:SetPoint("BOTTOMRIGHT", -2, 2)

        local fontName, _, fontFlags = debuffIcon.stack:GetFont()
        debuffIcon.stack:SetFont(fontName, 11, fontFlags)
        plate.myDebuffIcons[debuffName] = { icon = debuffIcon, expireTime = expireTime }
    else
        debuffIcon = plate.myDebuffIcons[debuffName].icon
        plate.myDebuffIcons[debuffName].expireTime = expireTime
    end

    if count and tonumber(count) >= 1 then
        debuffIcon.stack:SetText(count)
    end

    local startTime = expireTime - duration
    debuffIcon.cooldown:SetCooldown(startTime, duration)
    debuffIcon:Show()
end
