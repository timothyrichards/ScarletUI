ScarletUI = LibStub("AceAddon-3.0"):NewAddon("ScarletUI", "AceConsole-3.0", "AceTimer-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local IsAddOnLoaded = C_AddOns.IsAddOnLoaded or IsAddOnLoaded

-- Dialog to reload after addon settings are changed
StaticPopupDialogs['SCARLET_UI_RELOAD_DIALOG'] = {
    text = '<Scarlet UI>\n\nRequires a reload to properly configure.\n\n|cffffd100IF YOU DO NOT RELOAD YOU WILL EXPERIENCE LUA ERRORS.|r',
    button1 = 'Reload',
    button2 = 'Lua Errors',
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Dialog to reload after raid frame settings are changed
StaticPopupDialogs['SCARLET_UI_RAID_FRAME_DIALOG'] = {
    text = '<Scarlet UI>\n\nYour raid frame settings have been updated.\n\n|cffff0900IF YOU DO NOT RELOAD YOU WILL NOT BE ABLE TO TARGET PARTY OR RAID MEMBERS.|r',
    button1 = 'Reload',
    button2 = 'Dead Friends',
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Dialog to confirm enabling of CVar module
StaticPopupDialogs['SCARLET_ENABLE_CVARS_DIALOG'] = {
    text = '<Scarlet UI>\n\nEnabling this module will change several CVars, overriding their current values\n\nDo you want to continue?',
    button1 = 'Continue',
    button2 = 'Cancel',
    OnAccept = function()
        ScarletUI.db.global.CVarModule.enabled = true
        ScarletUI:SetupCVars()
        AceConfigRegistry:NotifyChange("ScarletUI")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Dialog to confirm restoration position of frames to default settings
StaticPopupDialogs['SCARLET_RESTORE_POSITIONS_DIALOG'] = {
    text = '<Scarlet UI>\n\nAre you sure you want to restore all frame positions to their default positions?',
    button1 = 'Confirm',
    button2 = 'Cancel',
    OnAccept = function()
        ScarletUI:ResetPositions()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Dialog to confirm restoration of default settings
StaticPopupDialogs['SCARLET_RESTORE_DEFAULTS_DIALOG'] = {
    text = '<Scarlet UI>\n\nAre you sure you want to restore all settings to default settings?',
    button1 = 'Confirm',
    button2 = 'Cancel',
    OnAccept = function()
        ScarletUI:ResetDefaults()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

-- Dialog to prompt if raid frame profile should be deleted
StaticPopupDialogs['SCARLET_DELETE_RAID_PROFILE_DIALOG'] = {
    text = '<Scarlet UI>\n\nWould you also like to delete the "Raid" raid frames profile?',
    button1 = 'Yes',
    button2 = 'No',
    OnAccept = function()
        ScarletUI:DeleteRaidProfile(ScarletUI.raidProfileToDelete)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

function ScarletUI:OnInitialize()
    -- Set up the database
    self.db = self.db or AceDB:New("ScarletUIDB", self.defaults, true)
    self.db:SetProfile("Default")

    -- Register the chat commands
    self:RegisterChatCommand("sui", "SlashCommand")

    -- Register the options table
    AceConfigDialog:SetDefaultSize("ScarletUI", 800, 525)
    AceConfig:RegisterOptionsTable("ScarletUI", function() return self:Options() end)
    AceConfigDialog:SetDefaultSize("ScarletUI_Movers", 400, 375)
    AceConfig:RegisterOptionsTable("ScarletUI_Movers", function() return self:GetMoversOptions() end)
    AceConfigDialog:AddToBlizOptions("ScarletUI")

    -- Initialize state properties
    self.lightWeightMode = false;
    self.retail = false;
    self.inCombat = false;
    self.moversEnabled = false;
    self.selectedMover = nil;
end

function ScarletUI:OnEnable()
    -- Check if lightWeightMode should be enabled
    if self:GetWoWVersion() == "RETAIL" then
        self.retail = true;
    elseif IsAddOnLoaded("ElvUI") then
        self.lightWeightMode = true;
    end

    self:Setup()

    self.hideFrameContainer = _G["HideFrameContainer"] or CreateFrame("FRAME", "HideFrameContainer", UIParent)
    self.hideFrameContainer:Hide()

    self:Print("Scarlet UI setup successful, use the command /sui to open the options panel.")
end

function ScarletUI:Setup()
    -- Set up debug frame
    self:SetupDebugFrame()

    -- Setup mover grid
    self:CreateMoverGrid(25)

    -- Setup frames
    self:SetupChat()
    self:SetupCVars()
    --self:SetupBags()
    self:SetupItemLevels()
    self:SetupActionBars()
    self:SetupUnitFrames()
    self:SetupRaidProfiles()
    self:SetupTidyIcons()
    self:SetupNameplates()
    self:SetupExpandCharacterInfo()
end

function ScarletUI:SetupDebugFrame()
    if SUI_DebugContainer then
        return
    end

    self.debugContainer = CreateFrame("Frame", "SUI_DebugContainer", self.frame)
    self.debugContainer:SetSize(200, 100)
    self.debugContainer:SetPoint("TOP", UIParent, "TOP", 0, -250)

    local title = self.debugContainer:CreateFontString("SUI_FrameTitle", "OVERLAY", "GameFontWhite")
    title:SetPoint("BOTTOM", self.debugContainer, "TOP")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetText("ScarletUI Debug Frame")

    local versionText = self.debugContainer:CreateFontString("SUI_VersionPropertyText", "OVERLAY", "GameFontWhite")
    versionText:SetPoint("TOPLEFT", self.debugContainer, "TOPLEFT")
    versionText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    local _, _, _, interfaceVersion = GetBuildInfo()
    versionText:SetText("- version: " .. tostring(interfaceVersion))

    local retailText = self.debugContainer:CreateFontString("SUI_RetailPropertyText", "OVERLAY", "GameFontWhite")
    retailText:SetPoint("TOPLEFT", versionText, "BOTTOMLEFT")
    retailText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    retailText:SetText("- retail: " .. tostring(self.retail))

    local lightWeightText = self.debugContainer:CreateFontString("SUI_LightWeightPropertyText", "OVERLAY", "GameFontWhite")
    lightWeightText:SetPoint("TOPLEFT", retailText, "BOTTOMLEFT")
    lightWeightText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    lightWeightText:SetText("- lightWeightMode: " .. tostring(self.lightWeightMode))

    local combatText = self.debugContainer:CreateFontString("SUI_CombatPropertyText", "OVERLAY", "GameFontWhite")
    combatText:SetPoint("TOPLEFT", lightWeightText, "BOTTOMLEFT")
    combatText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    combatText:SetText("- inCombat: false")

    local moverText = self.debugContainer:CreateFontString("SUI_MoverPropertyText", "OVERLAY", "GameFontWhite")
    moverText:SetPoint("TOPLEFT", combatText, "BOTTOMLEFT")
    moverText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    moverText:SetText("- moversEnabled: " .. tostring(self.moversEnabled))

    self.debugContainer:Hide()
end

function ScarletUI:SlashCommand(msg)
    if msg == "" then
        AceConfigDialog:Open("ScarletUI")

        if self.moversEnabled then
            self:ToggleMovers()
        end
    elseif msg == "move" then
        if self:InCombat() then
            self:Print("Cannot move frames while in combat.")
            return
        end

        if self.retail then
            self:Print("Movers are not available in retail, please use the WoW UI edit mode.")
            return
        end

        self:ToggleMovers()
    elseif msg == "debug" then
        self.debugContainer:SetShown(not self.debugContainer:IsShown())
    elseif msg == "help" then
        self:Print("Available commands:")
        self:Print("- /sui: Open the options panel.")
        self:Print("- /sui move: Toggle the movers.")
        self:Print("- /sui debug: Toggle the debug frame.")
        self:Print("- /sui help: Display this message.")
    else
        self:Print("Invalid chat command, use /sui help for a list of commands.")
    end
end

ScarletUI.frame = CreateFrame("Frame", "SUI_Frame", UIParent)
ScarletUI.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
ScarletUI.frame:RegisterEvent("PLAYER_LEAVING_WORLD")
ScarletUI.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
ScarletUI.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
ScarletUI.frame:SetScript("OnEvent", function (_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ScarletUI.pauseEvents = false
    end

    if event == "PLAYER_LEAVING_WORLD" then
        ScarletUI.pauseEvents = true
        -- TODO: maybe move code for saving raid/party frame positions to be ran here instead of creating a hook, might be a few other good candidates too
    end

    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        ScarletUI.inCombat = event == "PLAYER_REGEN_DISABLED";

        if ScarletUI:InCombat() and ScarletUI.moversEnabled then
            ScarletUI:ToggleMovers()
        end

        SUI_CombatPropertyText:SetText("- inCombat: " .. tostring(ScarletUI.inCombat))
        AceConfigRegistry:NotifyChange("ScarletUI")
    end
end)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
