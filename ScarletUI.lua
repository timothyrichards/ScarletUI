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

-- Dialog to confirm purchasing a bank bag slot
StaticPopupDialogs['SCARLET_PURCHASE_BANK_SLOT'] = {
    text = '<Scarlet UI>\n\nPurchase this bank bag slot?\n\nCost: %s',
    button1 = 'Purchase',
    button2 = 'Cancel',
    OnAccept = function()
        PurchaseSlot()
    end,
    timeout = 0,
    whileDead = false,
    hideOnEscape = true,
    preferredIndex = 3,
}

function ScarletUI:OnInitialize()
    -- Set up the database
    self.db = self.db or AceDB:New("ScarletUIDB", self.defaults, true)
    self.db:SetProfile("Default")

    -- Migrate old CVarModule.CVars to new overrides format
    if self.db.global.CVarModule.CVars then
        if not self.db.global.CVarModule.overrides then
            self.db.global.CVarModule.overrides = {}
        end

        for k, v in pairs(self.db.global.CVarModule.CVars) do
            self.db.global.CVarModule.overrides[k] = v
        end

        self.db.global.CVarModule.CVars = nil
    end

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
    self.editMode = false;
    self.inCombat = false;
    self.moversEnabled = false;
    self.selectedMover = nil;
end

function ScarletUI:OnEnable()
    -- Check if lightWeightMode should be enabled
    if self:GetWoWVersion() == "RETAIL" then
        self.retail = true;
        self.lightWeightMode = true;
    elseif self:IsAddOnLoaded("ElvUI") then
        self.lightWeightMode = true;
    end

    self:InitializeEditMode()

    self:Setup()

    self.hideFrameContainer = _G["HideFrameContainer"] or CreateFrame("FRAME", "HideFrameContainer", UIParent)
    self.hideFrameContainer:Hide()

    self:Print("Scarlet UI setup successful, use the command /sui to open the options panel.")
end

function ScarletUI:Setup()
    -- Set up debug frame
    self:SetupDebugFrame()

    -- The legacy grid is only needed on clients without Blizzard Edit Mode.
    if not self.editMode then
        self:CreateMoverGrid(25)
    end

    -- Setup frames
    self:SetupChat()
    self:SetupCVars()
    self:SetupBags()
    self:SetupBank()
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

    local editModeText = self.debugContainer:CreateFontString("SUI_EditModePropertyText", "OVERLAY", "GameFontWhite")
    editModeText:SetPoint("TOPLEFT", retailText, "BOTTOMLEFT")
    editModeText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    editModeText:SetText("- editMode: " .. tostring(self.editMode))

    local lightWeightText = self.debugContainer:CreateFontString("SUI_LightWeightPropertyText", "OVERLAY", "GameFontWhite")
    lightWeightText:SetPoint("TOPLEFT", editModeText, "BOTTOMLEFT")
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

        if self.editMode then
            self:OpenEditMode()
            return
        elseif self.lightWeightMode then
            self:Print("Movers are not available while another UI manages frame positions.")
            return
        end

        self:ToggleMovers()
    elseif msg == "debug" then
        self.debugContainer:SetShown(not self.debugContainer:IsShown())
    elseif msg == "help" then
        self:Print("Available commands:")
        self:Print("- /sui: Open the options panel.")
        self:Print("- /sui move: Open Edit Mode or toggle legacy movers.")
        self:Print("- /sui debug: Toggle the debug frame.")
        self:Print("- /sui help: Display this message.")
    else
        self:Print("Invalid chat command, use /sui help for a list of commands.")
    end
end

ScarletUI.frame = CreateFrame("Frame", "SUI_Frame", UIParent)
ScarletUI.eventHandlers = {}

function ScarletUI:RegisterEventHandler(event, handler)
    if not self.eventHandlers[event] then
        self.eventHandlers[event] = {}
        self.frame:RegisterEvent(event)
    end
    table.insert(self.eventHandlers[event], handler)
end

ScarletUI.frame:SetScript("OnEvent", function(_, event, ...)
    local handlers = ScarletUI.eventHandlers[event]
    if handlers then
        for _, handler in ipairs(handlers) do
            handler(event, ...)
        end
    end
end)

-- Core event handlers
ScarletUI:RegisterEventHandler("PLAYER_ENTERING_WORLD", function()
    ScarletUI.pauseEvents = false
end)

ScarletUI:RegisterEventHandler("PLAYER_LEAVING_WORLD", function()
    ScarletUI.pauseEvents = true
end)

local function OnCombatChanged(event)
    ScarletUI.inCombat = event == "PLAYER_REGEN_DISABLED"
    if ScarletUI:InCombat() and ScarletUI.moversEnabled then
        ScarletUI:ToggleMovers()
    end
    SUI_CombatPropertyText:SetText("- inCombat: " .. tostring(ScarletUI.inCombat))
    AceConfigRegistry:NotifyChange("ScarletUI")
end

ScarletUI:RegisterEventHandler("PLAYER_REGEN_DISABLED", OnCombatChanged)
ScarletUI:RegisterEventHandler("PLAYER_REGEN_ENABLED", OnCombatChanged)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
