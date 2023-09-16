ScarletUI = LibStub("AceAddon-3.0"):NewAddon("ScarletUI")
local AceDB = LibStub("AceDB-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ScarletUI:Setup()
    -- Add the ace modules to the addon object
    if not self.settings then
        self.settings = self:NewModule("Settings", "AceConsole-3.0")
    end

    -- Check if lightWeightMode should be enabled
    self.lightWeightMode = false;
    local _, _, _, interfaceVersion = GetBuildInfo()
    if tonumber(interfaceVersion) >= 100100 then
        self.lightWeightMode = true;
        self.retail = true;
    elseif IsAddOnLoaded("ElvUI") then
        self.lightWeightMode = true;
    end

    if not self.loaded then
        -- Set up the database
        self.db = self.db or AceDB:New("ScarletUIDB", self.defaults, true)

        -- Register the chat command
        self.settings:RegisterChatCommand("sui", function() AceConfigDialog:Open("ScarletUI") end)

        -- Register the options table
        AceConfig:RegisterOptionsTable("ScarletUI", function() return ScarletUI:Options() end)
        AceConfigDialog:AddToBlizOptions("ScarletUI")

        -- Declare the addon loaded
        self.loaded = true;
    end

    self:SetupChat()
    self:SetupCVars()
    self:SetupItemLevels()
    if not self.lightWeightMode then
        self:SetupActionbars()
        self:SetupUnitFrames()
        self:SetupTidyIcons()
        self:SpellBookPageScrolling()
    end

    self.settings:Print("Scarlet UI setup successful, use the command /sui to open the options panel.")
end

function ScarletUI:ResetDefaults()
    self.db:ResetDB()
    self:Setup()
    AceConfigRegistry:NotifyChange("ScarletUI")
end

local function OnEvent(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ScarletUI:Setup()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        ScarletUI.inCombat = event == "PLAYER_REGEN_DISABLED";
        AceConfigRegistry:NotifyChange("ScarletUI")
    end
end

ScarletUI.Frame = CreateFrame("Frame")
ScarletUI.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
ScarletUI.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
ScarletUI.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
ScarletUI.Frame:SetScript("OnEvent", OnEvent)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
