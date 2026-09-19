local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

ScarletUI.defaults = {
    global = {
        installationComplete = false,
        tidyIconsEnabled = true,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        itemLevelColorOverride = false,
        itemLevelColor = { r = 1, g = 1, b = 1 },
        expandCharacterInfo = true,
        editMode = {
            installed = {},
            suppressPrompts = false,
        },
        chatModule = {
            enabled = true,
            fontSize = 14,
            tabs = {
                loot = true,
                trade = true,
                lfg = true
            },
        },
        CVarModule = {
            enabled = true,
            overrides = {
                raidOptionDisplayMainTankAndAssist = '0',
                raidFramesHealthText = 'perc',
                raidFramesDisplayOnlyDispellableDebuffs = '1',
                raidFramesDisplayDebuffs = '1',
                raidFramesDisplayPowerBars = '1',
                damageMeterEnabled = '1',
                enableMouseoverCast = '1',
                raidFramesDisplayClassColor = '1',
            },
            hiddenCVars = {},
            originalValues = {},
        }
    },
    char = {
        cvarOriginalValues = {},
        editMode = {
            promptedVersions = {},
            declinedVersions = {},
            activationPromptedVersions = {},
            lastDisplayVariant = nil,
        },
    }
}

ScarletUI.originalUIDefaults = {
    global = {
        installationComplete = false,
        tidyIconsEnabled = false,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        itemLevelColorOverride = false,
        itemLevelColor = { r = 1, g = 1, b = 1 },
        expandCharacterInfo = false,
        chatModule = {
            enabled = true,
            fontSize = 14,
            tabs = {
                loot = true,
                trade = true,
                lfg = true
            },
        },
        CVarModule = {
            enabled = true,
            overrides = {
                raidOptionDisplayMainTankAndAssist = '0',
                raidFramesHealthText = 'perc',
                raidFramesDisplayOnlyDispellableDebuffs = '1',
                raidFramesDisplayDebuffs = '1',
                raidFramesDisplayPowerBars = '1',
                damageMeterEnabled = '1',
                enableMouseoverCast = '1',
                raidFramesDisplayClassColor = '1',
            },
            hiddenCVars = {},
            originalValues = {},
        }
    },
    char = {
        cvarOriginalValues = {},
    }
}

function ScarletUI:ResetDefaults()
    if self:InCombat() then return end
    -- Reset preferences without losing backups for this or other characters.
    local sharedOriginals = self.db.global.CVarModule.originalValues
    local originals = {}
    for key, character in pairs(self.db.sv and self.db.sv.char or {}) do
        originals[key] = character.cvarOriginalValues
    end
    self.db:ResetDB()
    self.db.global.CVarModule.originalValues = sharedOriginals
    for key, values in pairs(originals) do
        self.db.sv.char = self.db.sv.char or {}
        self.db.sv.char[key] = self.db.sv.char[key] or {}
        self.db.sv.char[key].cvarOriginalValues = values
    end
    self:Setup()
    self:Print("Settings have been reset to default.")
    AceConfigRegistry:NotifyChange("ScarletUI")
end
