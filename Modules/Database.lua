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
            overrides = {},
            hiddenCVars = {},
        }
    },
    char = {
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
            overrides = {},
            hiddenCVars = {},
        }
    },
    char = {
    }
}

function ScarletUI:ResetDefaults()
    self.db:ResetDB()
    self:Setup()
    self:Print("Settings have been reset to default.")
    AceConfigRegistry:NotifyChange("ScarletUI")
end
