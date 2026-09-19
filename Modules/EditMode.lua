local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

local EDIT_MODE_ADDON = "Blizzard_EditMode"
local PROFILE_PREFIX = "ScarletUI - "

local function GetEditModeLibrary()
    return LibStub("LibEditModeOverride-1.0", true)
end

local function ResolveEnum(value)
    if type(value) ~= "table" or not value.enumTable then
        return value
    end

    local enumTable = Enum and Enum[value.enumTable]
    return enumTable and enumTable[value.key]
end

local function NotifyOptions()
    AceConfigRegistry:NotifyChange("ScarletUI")
end

StaticPopupDialogs.SCARLET_EDIT_MODE_INSTALL = {
    text = "<Scarlet UI - Edit Mode>\n\nSet up ScarletUI's %s preset in Blizzard Edit Mode?\n\nThis arranges your frame positions and layout for your display.",
    button1 = "Set Up Preset",
    button2 = "Not Now",
    OnAccept = function(_, data)
        if data then ScarletUI:InstallEditModeProfile(data.variant) end
    end,
    OnCancel = function(_, data)
        if data then ScarletUI:DismissEditModePrompt(data.variant) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs.SCARLET_EDIT_MODE_SWITCH = {
    text = "<Scarlet UI - Edit Mode>\n\nSwitch your Blizzard Edit Mode layout to ScarletUI's %s preset?\n\nThis changes your frame positions and layout.",
    button1 = "Use Preset",
    button2 = "Keep Current",
    OnAccept = function(_, data)
        if data then
            ScarletUI:MarkEditModeActivationPrompted(data.variant)
            ScarletUI:SwitchEditModeProfile(data.variant)
        end
    end,
    OnCancel = function(_, data, reason)
        if reason == "clicked" then
            ScarletUI.db.global.editMode.suppressPrompts = true
        end
        if data then ScarletUI:MarkEditModeActivationPrompted(data.variant) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs.SCARLET_EDIT_MODE_RESTORE = {
    text = '<Scarlet UI>\n\nRestore "%s" to the ScarletUI defaults? Changes made to that Edit Mode profile will be replaced.',
    button1 = "Restore",
    button2 = "Cancel",
    OnAccept = function(_, data)
        if data then ScarletUI:InstallEditModeProfile(data.variant, true) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ScarletUI:IsEditModeSupported()
    return C_EditMode ~= nil
        and Enum ~= nil
        and Enum.EditModeLayoutType ~= nil
        and (Enum.EditModeLayoutType.Account ~= nil or Enum.EditModeLayoutType.Character ~= nil)
end

function ScarletUI:GetEditModeVariant()
    local width = UIParent and UIParent:GetWidth() or GetScreenWidth()
    local height = UIParent and UIParent:GetHeight() or GetScreenHeight()

    if not width or not height or height == 0 then
        return "STANDARD"
    end

    local aspect = width / height
    if aspect >= 2.1 then
        return "ULTRAWIDE"
    elseif width <= 1500 then
        return "COMPACT"
    end

    return "STANDARD"
end

function ScarletUI:GetEditModeVariantLabel(variant)
    local layout = self.editModeLayouts and self.editModeLayouts[variant]
    return layout and layout.label or "Standard"
end

function ScarletUI:GetEditModeProfileName(variant)
    return PROFILE_PREFIX .. self:GetEditModeVariantLabel(variant or self:GetEditModeVariant())
end

function ScarletUI:GetEditModePromptKey(variant)
    local client = self:GetWoWVersion()
    return string.format("%s:%s", client, variant)
end

function ScarletUI:DismissEditModePrompt(variant)
    local key = self:GetEditModePromptKey(variant)
    self.db.char.editMode.declinedVersions[key] = self.editModeLayoutSchemaVersion
end

function ScarletUI:MarkEditModeActivationPrompted(variant)
    local key = self:GetEditModePromptKey(variant)
    self.db.char.editMode.activationPromptedVersions[key] = self.editModeLayoutSchemaVersion
end

function ScarletUI:FindEditModeFrame(settingsKey)
    local candidates = self.editModeFrameCandidates[settingsKey] or {}
    local library = GetEditModeLibrary()

    for _, frameName in ipairs(candidates) do
        local frame = _G[frameName]
        if frame then
            local managed = false
            if library then
                local ok, result = pcall(library.HasEditModeSettings, library, frame)
                managed = ok and result
            end
            if managed then
                return frame
            end
        end
    end

    return nil
end

function ScarletUI:ApplyEditModeLayout(variant)
    local library = GetEditModeLibrary()
    if not library then
        return false, "LibEditModeOverride-1.0 is unavailable"
    end

    local frames = self:GetEditModeLayoutDefinition(variant)
    self.editModeSkippedSystems = {}

    for settingsKey, definition in pairs(frames) do
        local frame = self:FindEditModeFrame(settingsKey)
        if frame then
            if definition.point then
                local ok, reason = pcall(
                    library.ReanchorFrame,
                    library,
                    frame,
                    definition.point,
                    UIParent,
                    definition.relativePoint or definition.point,
                    definition.x or 0,
                    definition.y or 0
                )
                if not ok then
                    table.insert(self.editModeSkippedSystems, settingsKey .. " anchor: " .. tostring(reason))
                end
            end

            for _, settingInfo in ipairs(definition.settings or {}) do
                local setting = ResolveEnum(settingInfo.setting)
                local value = ResolveEnum(settingInfo.value)
                if setting ~= nil and value ~= nil then
                    local ok, reason = pcall(library.SetFrameSetting, library, frame, setting, value)
                    if not ok then
                        table.insert(self.editModeSkippedSystems, settingsKey .. " setting: " .. tostring(reason))
                    end
                end
            end
        else
            table.insert(self.editModeSkippedSystems, settingsKey .. ": unsupported by this client")
        end
    end

    return true
end

function ScarletUI:LoadEditModeLayouts()
    local library = GetEditModeLibrary()
    if not library or not library:IsReady() then
        return false
    end

    local ok, reason = pcall(library.LoadLayouts, library)
    if not ok then
        self.editModeLastError = tostring(reason)
        return false
    end

    self.editModeReady = true
    self.editModeLastError = nil
    return true
end

function ScarletUI:DoesEditModeProfileExist(variant)
    local library = GetEditModeLibrary()
    if not self.editModeReady or not library then
        return false
    end

    local ok, result = pcall(library.DoesLayoutExist, library, self:GetEditModeProfileName(variant))
    return ok and result
end

function ScarletUI:GetActiveEditModeProfile()
    local library = GetEditModeLibrary()
    if not self.editModeReady or not library then
        return nil
    end

    local ok, result = pcall(library.GetActiveLayout, library)
    return ok and result or nil
end

function ScarletUI:InstallEditModeProfile(variant, replace)
    variant = variant or self:GetEditModeVariant()

    if self:InCombat() then
        self.pendingEditModeAction = { action = "install", variant = variant, replace = replace }
        self:Print("The Edit Mode profile will be installed or updated when combat ends.")
        return
    end

    if not self:LoadEditModeLayouts() then
        self:Print("Edit Mode is not ready yet. Please try again in a moment.")
        return
    end

    local library = GetEditModeLibrary()
    local profileName = self:GetEditModeProfileName(variant)
    local exists = self:DoesEditModeProfileExist(variant)
    local operation = exists and "update" or "install"

    local ok, reason = pcall(function()
        if not exists then
            local layoutType = Enum.EditModeLayoutType.Account or Enum.EditModeLayoutType.Character
            library:AddLayout(layoutType, profileName)
        else
            -- Update the existing layout in place. Deleting an active layout
            -- makes Blizzard immediately select a preset, which can redirect
            -- the following edits into that preset instead of ScarletUI's.
            library:SetActiveLayout(profileName)
        end

        local applied, applyReason = self:ApplyEditModeLayout(variant)
        if not applied then
            error(applyReason)
        end

        library:ApplyChanges()
    end)

    if not ok then
        self.editModeLastError = tostring(reason)
        self:Print("Unable to " .. operation .. " the Edit Mode profile: " .. tostring(reason))
        NotifyOptions()
        return
    end

    local key = self:GetEditModePromptKey(variant)
    self.db.global.editMode.installed[key] = {
        name = profileName,
        version = self.editModeLayoutSchemaVersion,
    }
    self.db.char.editMode.promptedVersions[key] = self.editModeLayoutSchemaVersion
    self.db.char.editMode.declinedVersions[key] = nil
    self.db.char.editMode.activationPromptedVersions[key] = self.editModeLayoutSchemaVersion
    self.db.char.editMode.lastDisplayVariant = variant
    self.editModeLastError = nil

    self:Print(profileName .. (exists and " updated and activated." or " installed and activated."))
    NotifyOptions()
end

function ScarletUI:SwitchEditModeProfile(variant)
    variant = variant or self:GetEditModeVariant()
    if self:InCombat() then
        self.pendingEditModeAction = { action = "switch", variant = variant }
        self:Print("The Edit Mode profile will be switched when combat ends.")
        return
    end

    if not self:LoadEditModeLayouts() or not self:DoesEditModeProfileExist(variant) then
        self:InstallEditModeProfile(variant)
        return
    end

    local library = GetEditModeLibrary()
    local ok, reason = pcall(function()
        library:SetActiveLayout(self:GetEditModeProfileName(variant))
        library:ApplyChanges()
    end)

    if not ok then
        self.editModeLastError = tostring(reason)
        self:Print("Unable to switch Edit Mode profiles: " .. tostring(reason))
        return
    end

    self.db.char.editMode.lastDisplayVariant = variant
    self:MarkEditModeActivationPrompted(variant)
    self:Print(self:GetEditModeProfileName(variant) .. " activated.")
    NotifyOptions()
end

function ScarletUI:RestoreEditModeProfile()
    local variant = self:GetEditModeVariant()
    StaticPopup_Show(
        "SCARLET_EDIT_MODE_RESTORE",
        self:GetEditModeProfileName(variant),
        nil,
        { variant = variant }
    )
end

function ScarletUI:OpenEditMode()
    if self:InCombat() then
        self:Print("Cannot open Edit Mode while in combat.")
        return
    end

    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, EDIT_MODE_ADDON)
    elseif LoadAddOn then
        pcall(LoadAddOn, EDIT_MODE_ADDON)
    end

    if EditModeManagerFrame then
        ShowUIPanel(EditModeManagerFrame)
    else
        self:Print("Blizzard Edit Mode is unavailable on this client.")
    end
end

function ScarletUI:EvaluateEditModeProfilePrompt()
    if self.db.global.editMode.suppressPrompts or not self.editModeReady then
        return
    end

    local variant = self:GetEditModeVariant()
    local profileName = self:GetEditModeProfileName(variant)
    local key = self:GetEditModePromptKey(variant)
    local exists = self:DoesEditModeProfileExist(variant)
    local active = self:GetActiveEditModeProfile()

    if not exists then
        if self.db.char.editMode.declinedVersions[key] ~= self.editModeLayoutSchemaVersion then
            StaticPopup_Show(
                "SCARLET_EDIT_MODE_INSTALL",
                self:GetEditModeVariantLabel(variant),
                nil,
                { variant = variant }
            )
        end
    elseif active ~= profileName
        and self.db.char.editMode.activationPromptedVersions[key] == nil then
        StaticPopup_Show(
            "SCARLET_EDIT_MODE_SWITCH",
            self:GetEditModeVariantLabel(variant),
            nil,
            { variant = variant }
        )
    end

    self.db.char.editMode.lastDisplayVariant = variant
    NotifyOptions()
end

function ScarletUI:HandleEditModeDisplayChanged()
    C_Timer.After(1, function()
        if not ScarletUI.editModeReady then
            return
        end

        ScarletUI:EvaluateEditModeProfilePrompt()
    end)
end

function ScarletUI:TryInitializeEditModeProfile()
    if not self.editMode or not self:LoadEditModeLayouts() then
        return
    end

    self:EvaluateEditModeProfilePrompt()
end

function ScarletUI:InitializeEditMode()
    if C_AddOns and C_AddOns.LoadAddOn then
        pcall(C_AddOns.LoadAddOn, EDIT_MODE_ADDON)
    elseif LoadAddOn then
        pcall(LoadAddOn, EDIT_MODE_ADDON)
    end

    self.editMode = self:IsEditModeSupported()
    if not self.editMode or self.editModeEventsRegistered then
        return
    end

    self.editModeEventsRegistered = true
    self:RegisterEventHandler("EDIT_MODE_LAYOUTS_UPDATED", function()
        ScarletUI:TryInitializeEditModeProfile()
    end)
    self:RegisterEventHandler("DISPLAY_SIZE_CHANGED", function()
        ScarletUI:HandleEditModeDisplayChanged()
    end)
    self:RegisterEventHandler("UI_SCALE_CHANGED", function()
        ScarletUI:HandleEditModeDisplayChanged()
    end)
    self:RegisterEventHandler("PLAYER_REGEN_ENABLED", function()
        local pending = ScarletUI.pendingEditModeAction
        ScarletUI.pendingEditModeAction = nil
        if pending then
            if pending.action == "switch" then
                ScarletUI:SwitchEditModeProfile(pending.variant)
            else
                ScarletUI:InstallEditModeProfile(pending.variant, pending.replace)
            end
        end
    end)

    C_Timer.After(0, function()
        ScarletUI:TryInitializeEditModeProfile()
    end)
end

function ScarletUI:GetEditModeStatusText()
    if not self.editMode then
        return "Blizzard Edit Mode is unavailable on this client."
    elseif not GetEditModeLibrary() then
        return "Edit Mode support is missing LibEditModeOverride-1.0."
    elseif not self.editModeReady then
        return "Waiting for Blizzard Edit Mode to finish loading."
    end

    local variant = self:GetEditModeVariant()
    local profileName = self:GetEditModeProfileName(variant)
    local installed = self:DoesEditModeProfileExist(variant)
    local active = self:GetActiveEditModeProfile()
    local state = installed and "Installed" or "Not installed"
    local installedMetadata = self.db.global.editMode.installed[self:GetEditModePromptKey(variant)]
    if installed and active == profileName then
        state = state .. " and active"
    end
    if installed and (not installedMetadata or installedMetadata.version ~= self.editModeLayoutSchemaVersion) then
        state = state .. "; update available"
    end

    return string.format(
        "Detected layout: %s\nExpected profile: %s\nStatus: %s",
        self:GetEditModeVariantLabel(variant),
        profileName,
        state
    )
end

function ScarletUI:GetEditModeSettingsPage(order)
    return {
        name = "Edit Mode Profile",
        desc = "Install and manage ScarletUI's Blizzard Edit Mode profile.",
        type = "group",
        hidden = function() return not self.editMode end,
        order = order,
        args = {
            status = {
                name = function() return self:GetEditModeStatusText() end,
                type = "description",
                fontSize = "medium",
                order = 1,
            },
            install = {
                name = function()
                    return self:DoesEditModeProfileExist(self:GetEditModeVariant())
                        and "Update Profile"
                        or "Install Profile"
                end,
                desc = function()
                    if self:DoesEditModeProfileExist(self:GetEditModeVariant()) then
                        return "Replace the installed ScarletUI profile with the current defaults and activate it."
                    end
                    return "Install and activate the ScarletUI profile optimized for the current display."
                end,
                type = "execute",
                disabled = function()
                    return self:InCombat() or not self.editModeReady
                end,
                func = function() self:InstallEditModeProfile(self:GetEditModeVariant()) end,
                order = 2,
            },
            switch = {
                name = "Switch Profile",
                desc = "Activate the installed ScarletUI profile for this display.",
                type = "execute",
                disabled = function()
                    local variant = self:GetEditModeVariant()
                    return self:InCombat()
                        or not self.editModeReady
                        or not self:DoesEditModeProfileExist(variant)
                        or self:GetActiveEditModeProfile() == self:GetEditModeProfileName(variant)
                end,
                func = function() self:SwitchEditModeProfile(self:GetEditModeVariant()) end,
                order = 3,
            },
            restore = {
                name = "Restore Profile",
                desc = "Replace the current display's ScarletUI profile with its defaults.",
                type = "execute",
                disabled = function()
                    return self:InCombat() or not self.editModeReady or not self:DoesEditModeProfileExist(self:GetEditModeVariant())
                end,
                func = function() self:RestoreEditModeProfile() end,
                order = 4,
            },
            open = {
                name = "Open Edit Mode",
                desc = "Open Blizzard Edit Mode to customize the active profile.",
                type = "execute",
                disabled = function() return self:InCombat() end,
                func = function() self:OpenEditMode() end,
                order = 5,
            },
        },
    }
end
