function ScarletUI:InCombat()
    return InCombatLockdown() or self.inCombat
end

function ScarletUI:GetWoWVersion()
    local _, _, _, interfaceVersion = GetBuildInfo()
    interfaceVersion = tonumber(interfaceVersion)

    if interfaceVersion >= 100000 then
        return "RETAIL"
    elseif interfaceVersion >= 90000 then
        return "SL"
    elseif interfaceVersion >= 80000 then
        return "BFA"
    elseif interfaceVersion >= 70000 then
        return "LEGION"
    elseif interfaceVersion >= 60000 then
        return "WOD"
    elseif interfaceVersion >= 50000 then
        return "MOP"
    elseif interfaceVersion >= 40000 then
        return "CATA"
    elseif interfaceVersion >= 30000 then
        return "WOTLK"
    elseif interfaceVersion >= 20000 then
        return "TBC"
    elseif interfaceVersion >= 10000 then
        return "VANILLA"
    else
        print("ScarletUI was unable to determine what version of WoW this is: " .. interfaceVersion)
        return "UNKNOWN"
    end
end

function ScarletUI:SetupExpandCharacterInfo()
    if not self.db.global.expandCharacterInfo or self:GetWoWVersion() ~= "CATA" then
        return
    end

    hooksecurefunc(CharacterFrame, "Show", function()
        if CharacterFrame.Expanded then
            return
        end

        CharacterFrameExpandButton:Click()
    end)
end

function ScarletUI:SwapActionbar(sourceBar, destinationBar)
    for i = 1, 12 do
        local sourceButton = _G[sourceBar.."Button"..i].action
        local destinationButton = _G[destinationBar.."Button"..i].action

        PickupAction(sourceButton)
        if GetCursorInfo() ~= nil then
            PlaceAction(destinationButton)
            PlaceAction(sourceButton)
        else
            PickupAction(destinationButton)
            PlaceAction(sourceButton)
            PlaceAction(destinationButton)
        end
    end
end

function ScarletUI:ConvertBarToHorizontal(bar)
    local children = { bar:GetChildren() }
    local previousChild;
    for _, child in ipairs(children) do
        child:ClearAllPoints()

        if previousChild then
            child:SetPoint("LEFT", previousChild, "RIGHT", 6, 0)
        else
            child:SetPoint("LEFT", bar, "LEFT", 0, 0)
        end

        previousChild = child
    end
end

function ScarletUI:OppositeFrameAnchor(index)
    local anchor = self.frameAnchors[index]
    if anchor == "BOTTOM" then
        return "BOTTOM"
    elseif anchor == "BOTTOMLEFT" then
        return "BOTTOMRIGHT"
    elseif anchor == "BOTTOMRIGHT" then
        return "BOTTOMLEFT"
    elseif anchor == "CENTER" then
        return "CENTER"
    elseif anchor == "LEFT" then
        return "RIGHT"
    elseif anchor == "RIGHT" then
        return "LEFT"
    elseif anchor == "TOP" then
        return "TOP"
    elseif anchor == "TOPLEFT" then
        return "TOPRIGHT"
    elseif anchor == "TOPRIGHT" then
        return "TOPLEFT"
    end
end

function ScarletUI:SettingDisabled(moduleEnabled, checkCombat)
    if ScarletUI:InCombat() and checkCombat then
        return true
    else
        return not moduleEnabled
    end
end

function ScarletUI:FixChatBug()
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G['ChatFrame'..i]
        cf.oldAlpha = cf.oldAlpha or 0 -- Fix 'max-bug' in FCF.lua
        local cfname, _, _, _, _, _, _, _, _, _ = GetChatWindowInfo(i)
        if(cfname == iname) then
            ifound = true
            break
        end
    end
end

function ScarletUI:DumpTable(table, indent)
    indent = indent or ""
    for key, value in pairs(table) do
        if type(value) == "table" then
            print(indent .. tostring(key) .. " = {")
            self:DumpTable(value, indent .. "    ")
            print(indent .. "}")
        else
            print(indent .. tostring(key) .. " = " .. tostring(value))
        end
    end
end

function ScarletUI:ArrayHasValue(array, value)
    for _, v in ipairs(array) do
        if tostring(v) == tostring(value) then
            return true
        end
    end

    return false
end

function ScarletUI:GetArrayIndex(value)
    for index, v in ipairs(ScarletUI.frameAnchors) do
        if v == value then
            return index
        end
    end

    return nil
end
