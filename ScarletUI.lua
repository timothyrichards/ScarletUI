ScarletUI = LibStub("AceAddon-3.0"):NewAddon("ScarletUI")
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
    -- Add the ace modules to the addon object
    if not self.settings then
        self.settings = self:NewModule("Settings", "AceConsole-3.0")
    end

    -- Initialize state properties
    self.lightWeightMode = false;
    self.retail = false;
    self.inCombat = false;

    -- Check if lightWeightMode should be enabled
    local _, _, _, interfaceVersion = GetBuildInfo()
    if tonumber(interfaceVersion) >= 100205 then
        self.retail = true;
    elseif IsAddOnLoaded("ElvUI") then
        self.lightWeightMode = true;
    end

    if not self.loaded then
        -- Set up the database
        self.db = self.db or AceDB:New("ScarletUIDB", self.defaults, true)

        -- Set up frame
        self:SetupFrame()

        -- Register the chat commands
        AceConfigDialog:SetDefaultSize("ScarletUI", 780, 550)
        self.settings:RegisterChatCommand("sui", function() AceConfigDialog:Open("ScarletUI") end)

        -- Register the options table
        AceConfig:RegisterOptionsTable("ScarletUI", function() return ScarletUI:Options() end)
        AceConfigDialog:AddToBlizOptions("ScarletUI")

        -- Declare the addon loaded
        self.loaded = true;
    end

    if self.db.global.blueShamans then
        self:BlueShamans()
    end

    self:SetupChat()
    self:SetupCVars()
    self:SetupItemLevels()
    self:SetupActionbars()
    self:SetupUnitFrames()
    self:SetupRaidProfiles()
    self:SetupTidyIcons()
    self:SetupNameplates()

    if isLogin then
        self.settings:Print("Scarlet UI setup successful, use the command /sui to open the options panel.")
    end
end

function ScarletUI:BlueShamans()
    RAID_CLASS_COLORS["SHAMAN"] = CreateColor(0.0, 0.44, 0.87);
    RAID_CLASS_COLORS["SHAMAN"].colorStr = RAID_CLASS_COLORS["SHAMAN"]:GenerateHexColor();
end

function ScarletUI:SetupFrame()
    self.frame:SetSize(200, 100)
    self.frame:SetPoint("TOP", UIParent, "TOP", 0, -250)

    self.frame:CreateFontString("SUI_FrameTitle", "OVERLAY", "GameFontWhite")
    SUI_FrameTitle:SetPoint("BOTTOM", self.frame, "TOP")
    SUI_FrameTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    SUI_FrameTitle:SetText("ScarletUI Frame")

    self.frame:CreateFontString("SUI_RetailPropertyText", "OVERLAY", "GameFontWhite")
    SUI_RetailPropertyText:SetPoint("TOPLEFT", self.frame, "TOPLEFT")
    SUI_RetailPropertyText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    SUI_RetailPropertyText:SetText("- retail: " .. tostring(self.retail))

    self.frame:CreateFontString("SUI_LightWeightPropertyText", "OVERLAY", "GameFontWhite")
    SUI_LightWeightPropertyText:SetPoint("TOPLEFT", SUI_RetailPropertyText, "BOTTOMLEFT")
    SUI_LightWeightPropertyText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    SUI_LightWeightPropertyText:SetText("- lightWeightMode: " .. tostring(self.lightWeightMode))

    self.frame:CreateFontString("SUI_CombatPropertyText", "OVERLAY", "GameFontWhite")
    SUI_CombatPropertyText:SetPoint("TOPLEFT", SUI_LightWeightPropertyText, "BOTTOMLEFT")
    SUI_CombatPropertyText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    SUI_CombatPropertyText:SetText("- inCombat: false")

    self.frame:Hide()
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

        if ScarletUI.inCombat and ScarletUI.moversEnabled then
            ScarletUI:ToggleMovers()
        end

        SUI_CombatPropertyText:SetText("- inCombat: " .. tostring(ScarletUI.inCombat))
        AceConfigRegistry:NotifyChange("ScarletUI")
    end
end)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
