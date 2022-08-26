ScarletUI = LibStub("AceAddon-3.0"):NewAddon("ScarletUI")
sui_AceDB = LibStub("AceDB-3.0")
sui_AceDBOptions = LibStub("AceDBOptions-3.0")
sui_AceConsole = LibStub("AceConsole-3.0")
sui_AceGUI = LibStub("AceGUI-3.0")
sui_AceConfig = LibStub("AceConfig-3.0")
sui_AceConfigDialog = LibStub("AceConfigDialog-3.0")
sui_AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ScarletUI:OnInitialize()
    -- Add the ace modules to the ScarletUI object
    sui_AceConsole:Embed(self)
    self.config = sui_AceConfig
    self.configDialog = sui_AceConfigDialog
    self.gui = sui_AceGUI
    self.dbOptions = sui_AceDBOptions

    -- Set up the database
    self.db = sui_AceDB:New("ScarletUIDB")
end

function ScarletUI:OnEnable()
    ScarletUI:Setup()
end

function ScarletUI:Setup()
    if not IsAddOnLoaded("ElvUI") then
        SetCVar('useUiScale', 1)
        SetCVar('UIScale', 0.75)

        self:SetupUnitFrames()
        self:SetupActionbars()
        self:SetupRepair()
    end
    self:SetupChat()
    self:Print("UI setup successful.")
end

local function OnEvent(self, event, addon, isReload)
    if event == "ADDON_LOADED" and addon == "ScarletUI" then
        ScarletUI:SetupChat()
        ScarletUI:TidyIcons_Update()
    end
end

ScarletUI.Frame = CreateFrame("Frame")
ScarletUI.Frame:RegisterEvent("ADDON_LOADED")
ScarletUI.Frame:SetScript("OnEvent", OnEvent)