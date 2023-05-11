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

function ScarletUI:Setup()
    if IsAddOnLoaded("ElvUI") then
        self:Print("ElvUI detected, aborting setup.")
        return
    end

    self:SetupUnitFrames()
    self:SetupActionbars()
    self:SetupChat()
    self:SetupCVars()
    self:SetupRaidProfiles()

    self:Print("UI setup successful.")
end

local function OnEvent(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        ScarletUI:Setup()
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        ScarletUI:UpdateMainBar()
    elseif event == "GROUP_ROSTER_UPDATE" then
        local activeRaidProfile = GetActiveRaidProfile()
        if IsInRaid() and activeRaidProfile ~= 'Raid' then
            ScarletUI:Print("Setting Raid Profile to 'Raid'.")
            CompactUnitFrameProfiles_ActivateRaidProfile('Raid')
        elseif activeRaidProfile ~= 'Party' then
            ScarletUI:Print("Setting Raid Profile to 'Party'.")
            CompactUnitFrameProfiles_ActivateRaidProfile('Party')
        end
    end
end

ScarletUI.Frame = CreateFrame("Frame")
ScarletUI.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
ScarletUI.Frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
ScarletUI.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
ScarletUI.Frame:SetScript("OnEvent", OnEvent)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
