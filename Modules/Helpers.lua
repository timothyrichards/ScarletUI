function ScarletUI:IsAddOnLoaded(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif IsAddOnLoaded then
        return IsAddOnLoaded(name)
    end
    return false
end

function ScarletUI:InCombat()
    return InCombatLockdown() or self.inCombat
end

function ScarletUI:ShowReloadDialog()
    --if not self.db.global.installationComplete then
    --    return
    --end

    StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
end

function ScarletUI:ShowRaidFrameDialog()
    StaticPopup_Show('SCARLET_UI_RAID_FRAME_DIALOG')
end

local cachedVersionText, cachedInterfaceVersion

function ScarletUI:GetWoWVersion()
    if cachedVersionText then
        return cachedVersionText, cachedInterfaceVersion
    end

    local _, _, _, interfaceVersion = GetBuildInfo()
    interfaceVersion = tonumber(interfaceVersion)

    local versionText
    if interfaceVersion >= 110000 then
        versionText = "RETAIL"
    elseif interfaceVersion >= 100000 then
        versionText = "DF"
    elseif interfaceVersion >= 90000 then
        versionText = "SL"
    elseif interfaceVersion >= 80000 then
        versionText = "BFA"
    elseif interfaceVersion >= 70000 then
        versionText = "LEGION"
    elseif interfaceVersion >= 60000 then
        versionText = "WOD"
    elseif interfaceVersion >= 50000 then
        versionText = "MOP"
    elseif interfaceVersion >= 40000 then
        versionText = "CATA"
    elseif interfaceVersion >= 30000 then
        versionText = "WOTLK"
    elseif interfaceVersion >= 20000 then
        versionText = "TBC"
    elseif interfaceVersion >= 16000 then
        versionText = "FOREVER"
    elseif interfaceVersion >= 10000 then
        versionText = "VANILLA"
    else
        versionText = "UNKNOWN"
        self:Print("Unable to determine what version of WoW this is: " .. interfaceVersion)
    end

    cachedVersionText = versionText
    cachedInterfaceVersion = interfaceVersion
    return versionText, interfaceVersion
end

function ScarletUI:SetupExpandCharacterInfo()
    local versionText, interfaceVersion = self:GetWoWVersion()
    if not self.db.global.expandCharacterInfo or versionText ~= "CATA" then
        return
    end

    if not self.characterFrameExpandedEventRegistered then
        self.characterFrameExpandedEventRegistered = true
        hooksecurefunc(CharacterFrameExpandButton, "Show", function()
            if not self.db.global.expandCharacterInfo or CharacterFrame.Expanded then
                return
            end

            CharacterFrameExpandButton:Click()
        end)
    end
end

function ScarletUI:SettingDisabled(moduleEnabled, ignoreCombat)
    if self:InCombat() and not ignoreCombat then
        return true
    else
        return not moduleEnabled
    end
end

function ScarletUI:FixChatBug()
    for i = 1, NUM_CHAT_WINDOWS do
        local cf = _G['ChatFrame'..i]
        cf.oldAlpha = cf.oldAlpha or 0 -- Fix 'max-bug' in FCF.lua
    end
end

function ScarletUI:MergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            self:MergeTables(t1[k], v)
        else
            t1[k] = v
        end
    end

    return t1
end

function ScarletUI:DumpTable(table, indent)
    indent = indent or ""
    local isEmpty = true

    for key, value in pairs(table) do
        isEmpty = false
        if type(value) == "table" then
            print(indent .. tostring(key) .. " = {")
            self:DumpTable(value, indent .. "    ")
            print(indent .. "}")
        else
            print(indent .. tostring(key) .. " = " .. tostring(value))
        end
    end

    if isEmpty then
        print(indent .. "{}")
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

function ScarletUI:ConvertToPascalCase(string)
    if string == nil then
        return ""
    end

    return string:gsub("(%w)(%w*)", function(first, rest)
        return first:upper()..rest
    end)
end
