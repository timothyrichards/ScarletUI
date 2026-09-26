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

function ScarletUI:OnInitialize()
    -- Startup evidence for settings that appear to reset across reloads.
    local saved = ScarletUIDB
    self.savedVariablesAtInitialize = {
        present = type(saved) == "table",
        suppressPrompts = saved and saved.global and saved.global.editMode and saved.global.editMode.suppressPrompts,
        databaseAlreadyCreated = self.db ~= nil,
    }
    -- Set up the database
    self:PrepareCVarSettings()
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

    -- Seed the default mouseover casting override on clients that support it.
    local CVarModule = self.db.global.CVarModule
    if CVarModule.enabled and CVarModule.overrides.enableMouseoverCast == nil
        and not CVarModule.hiddenCVars.enableMouseoverCast
        and GetCVar('enableMouseoverCast') ~= nil then
        CVarModule.overrides.enableMouseoverCast = '1'
    end

    -- Seed the default damage meter override on clients that support it.
    if CVarModule.enabled and CVarModule.overrides.damageMeterEnabled == nil
        and not CVarModule.hiddenCVars.damageMeterEnabled
        and GetCVar('damageMeterEnabled') ~= nil then
        CVarModule.overrides.damageMeterEnabled = '1'
    end

    -- Register the chat commands
    self:RegisterChatCommand("sui", "SlashCommand")

    -- Register the options table
    AceConfigDialog:SetDefaultSize("ScarletUI", 800, 525)
    AceConfig:RegisterOptionsTable("ScarletUI", function() return self:Options() end)
    AceConfigDialog:AddToBlizOptions("ScarletUI")

    -- Initialize state properties
    self.lightWeightMode = false;
    self.retail = false;
    self.editMode = false;
    self.inCombat = false;
end

function ScarletUI:OnEnable()
    -- Check if lightWeightMode should be enabled
    local client = self:GetWoWVersion()
    -- Forever uses Mainline frames and bags despite its Classic version number.
    if client == "RETAIL" or client == "FOREVER" then
        self.retail = true;
        self.lightWeightMode = true;
    elseif self:IsAddOnLoaded("ElvUI") then
        self.lightWeightMode = true;
    end

    self:InitializeEditMode()

    self:Setup()

    self:Print("Scarlet UI setup successful, use the command /sui to open the options panel.")
end

function ScarletUI:Setup()
    -- Set up debug frame
    self:SetupDebugFrame()

    -- Setup frames
    self:SetupActionBarToggles()
    self:SetupChat()
    self:SetupCVars()
    self:SetupItemLevels()
    self:SetupTidyIcons()
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

    self.debugContainer:Hide()
end

function ScarletUI:SlashCommand(msg)
    if msg == "" then
        AceConfigDialog:Open("ScarletUI")
    elseif msg == "move" then
        self:OpenEditMode()
    elseif msg == "debug" then
        self.debugContainer:SetShown(not self.debugContainer:IsShown())
    elseif msg == "help" then
        self:Print("Available commands:")
        self:Print("- /sui: Open the options panel.")
        self:Print("- /sui move: Open Blizzard Edit Mode.")
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
    SUI_CombatPropertyText:SetText("- inCombat: " .. tostring(ScarletUI.inCombat))
    AceConfigRegistry:NotifyChange("ScarletUI")
end

ScarletUI:RegisterEventHandler("PLAYER_REGEN_DISABLED", OnCombatChanged)
ScarletUI:RegisterEventHandler("PLAYER_REGEN_ENABLED", OnCombatChanged)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
