ScarletUI = LibStub("AceAddon-3.0"):NewAddon("ScarletUI", "AceConsole-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Dialog to reload after addon settings are changed
StaticPopupDialogs['SCARLET_UI_RELOAD_DIALOG'] = {
    text = '<Scarlet UI>\n\nRequires a reload to properly configure.\n\nIF YOU DO NOT RELOAD YOU WILL EXPERIENCE LUA ERRORS.',
    button1 = 'Reload',
    button2 = 'Close',
    OnAccept = function()
        ReloadUI()
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

function ScarletUI:Setup(isLogin)
    if not self.loaded then
        -- Initialize state properties
        self.lightWeightMode = false;
        self.retail = false;
        self.inCombat = false;
        self.moversEnabled = false;
        self.selectedMover = nil;

        -- Set up the database
        self.db = self.db or AceDB:New("ScarletUIDB", self.defaults, true)

        -- Set up frame
        self:SetupFrame()

        -- Register the chat commands
        self:RegisterChatCommand("sui", "SlashCommand")

        -- Register the options table
        AceConfigDialog:SetDefaultSize("ScarletUI", 780, 500)
        AceConfig:RegisterOptionsTable("ScarletUI", function() return self:Options() end)
        AceConfigDialog:SetDefaultSize("ScarletUI_Movers", 400, 325)
        AceConfig:RegisterOptionsTable("ScarletUI_Movers", function() return self:MoversOptions() end)
        AceConfigDialog:AddToBlizOptions("ScarletUI")

        -- Declare the addon loaded
        self.loaded = true;
    end

    -- Check if lightWeightMode should be enabled
    if self:GetWoWVersion() == "RETAIL" then
        self.retail = true;
    elseif IsAddOnLoaded("ElvUI") then
        self.lightWeightMode = true;
    end

    self.hideFrameContainer = _G["HideFrameContainer"] or CreateFrame("FRAME", "HideFrameContainer", UIParent)
    self.hideFrameContainer:Hide()

    self:SetupChat()
    self:SetupCVars()
    self:SetupItemLevels()
    self:SetupActionBars()
    self:SetupUnitFrames()
    self:SetupRaidProfiles()
    self:SetupTidyIcons()
    self:SetupNameplates()
    self:SetupExpandCharacterInfo()
    --self:SetupBags()

    if isLogin then
        self:Print("Scarlet UI setup successful, use the command /sui to open the options panel.")
    end
end

function ScarletUI:SetupFrame()
    self.debugContainer = CreateFrame("Frame", "SUI_DebugContainer", self.frame)
    self.debugContainer:SetSize(200, 100)
    self.debugContainer:SetPoint("TOP", UIParent, "TOP", 0, -250)

    local title = self.debugContainer:CreateFontString("SUI_FrameTitle", "OVERLAY", "GameFontWhite")
    title:SetPoint("BOTTOM", self.debugContainer, "TOP")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetText("ScarletUI Debug Frame")

    local retailText = self.debugContainer:CreateFontString("SUI_RetailPropertyText", "OVERLAY", "GameFontWhite")
    retailText:SetPoint("TOPLEFT", self.debugContainer, "TOPLEFT")
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
        self:Print("Invalid chat command. Use /sui help for a list of commands.")
    end
end

ScarletUI.frame = CreateFrame("Frame", "SUI_Frame", UIParent)
ScarletUI.frame:RegisterEvent("PLAYER_ENTERING_WORLD")
ScarletUI.frame:RegisterEvent("PLAYER_REGEN_DISABLED")
ScarletUI.frame:RegisterEvent("PLAYER_REGEN_ENABLED")
ScarletUI.frame:SetScript("OnEvent", function (_, event, isLogin, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ScarletUI:Setup(isLogin)
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
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
