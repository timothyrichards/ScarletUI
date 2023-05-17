ScarletUI = LibStub("AceAddon-3.0"):NewAddon("ScarletUI")
local AceDB = LibStub("AceDB-3.0")
--local AceDBOptions = LibStub("AceDBOptions-3.0")
--local AceConsole = LibStub("AceConsole-3.0")
--local AceGUI = LibStub("AceGUI-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- for k, v in pairs(ScarletUI.db.global) do print(k, "=", v) end

function ScarletUI:Setup()
    if not self.loaded then
        -- Add the ace modules to the addon object
        self.settings = self:NewModule("Settings", "AceConsole-3.0")

        -- Set up the database
        self.defaults = {
            global = {
                tidyIconsEnabled = true,
                scrollSpellBook = true,
                unitFramesModule = {
                    enabled = true,
                    playerFrame = {
                        move = true,
                        x = -65,
                        y = -190,
                    },
                    targetFrame = {
                        mirrorPlayerFrame = true;
                        move = true,
                        x = 65,
                        y = -190,
                    },
                    focusFrame = {
                        move = true,
                        x = -65,
                        y = -190,
                    },
                },
                actionbarsModule = {
                    enabled = true,
                    stackActionbars = true,
                    stackSidebars = false
                },
                chatModule = {
                    enabled = true
                },
                raidFramesModule = {
                    enabled = true
                },
            }
        }
        self.db = self.db or AceDB:New("ScarletUIDB", self.defaults, true)

        -- Register the chat command
        self.settings:RegisterChatCommand("sui", function() AceConfigDialog:Open("ScarletUI") end)

        -- Register the options table
        AceConfig:RegisterOptionsTable("ScarletUI", function() return ScarletUI:Options() end)
        AceConfigDialog:AddToBlizOptions("ScarletUI")

        -- Declare the addon loaded
        self.loaded = true;
    end

    if IsAddOnLoaded("ElvUI") then
        self.settings:Print("ElvUI detected, aborting setup.")
        return
    end

    if self.db.global.unitFramesModule.enabled then
        self:SetupUnitFrames()
    end
    if self.db.global.actionbarsModule.enabled then
        self:SetupActionbars()
    end
    if self.db.global.chatModule.enabled then
        self:SetupChat()
    end
    if self.db.global.raidFramesModule.enabled then
        self:SetupRaidProfiles()
    end
    self:TidyIcons_Update()
    self:SetupCVars()
    self:SpellBookPageScrolling()

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
    elseif event == "PLAYER_REGEN_DISABLED" then
        ScarletUI.inCombat = true;
        AceConfigRegistry:NotifyChange("ScarletUI")
    elseif event == "PLAYER_REGEN_ENABLED" then
        ScarletUI.inCombat = false;
        AceConfigRegistry:NotifyChange("ScarletUI")
    elseif event == "ACTIONBAR_UPDATE_STATE" then
        ScarletUI:UpdateMainBar()
    elseif event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" or event == "GROUP_ROSTER_UPDATE" then
        ScarletUI:UpdateActiveRaidProfile()
    end
end

ScarletUI.Frame = CreateFrame("Frame")
ScarletUI.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
ScarletUI.Frame:RegisterEvent("PLAYER_REGEN_DISABLED")
ScarletUI.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")
ScarletUI.Frame:RegisterEvent("GROUP_ROSTER_UPDATE")
ScarletUI.Frame:SetScript("OnEvent", OnEvent)

--hooksecurefunc("SetCVar", function(k, v)
--    print("CVar", k, "changed to", v)
--end)
