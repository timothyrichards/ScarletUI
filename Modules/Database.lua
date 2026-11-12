local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

ScarletUI.defaults = {
    global = {
        installationComplete = false,
        tidyIconsEnabled = true,
        spellCostPercent = true,
        crateFillCosts = true,
        zoneLevels = true,
        fiveSecondRule = true,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        itemLevelColorOverride = false,
        itemLevelColor = { r = 1, g = 1, b = 1 },
        highlightCheapestItem = true,
        expandCharacterInfo = true,
        hideMicroMenuArt = true,
        collapseInactiveBuffs = "OFF",
        minimapIcon = {
            hide = false,
        },
        editMode = {
            installed = {},
            suppressPrompts = false,
        },
        actionBarToggles = {
            enabled = true,
            ignored = {},
        },
        bagSortModule = {
            enabled = true,
            sortBagsRightToLeft = true,
        },
        -- Off by default: /sui and the minimap icon are the usual ways in.
        gameMenuButtons = {
            sui = false,
            cooldownManager = false,
        },
        trackingModule = {
            enabled = true,
            -- Spell IDs: Find Minerals, Find Herbs.
            alwaysOn = { [2580] = true, [2383] = true },
            -- Seconds between swaps when a character knows both.
            switchInterval = 3,
        },
        fishingModule = {
            enabled = true,
            key = "SPACE",
            autoLure = true,
        },
        xpFoodModule = {
            enabled = true,
        },
        statDisplay = {
            enabled = false,
            layout = "COMBINED",
            orientation = "VERTICAL",
            -- Saved positions of the separate panels, keyed by role.
            positions = {},
        },
        craftProfit = {
            enabled = true,
            showAll = false,
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
            enabled = false,
            overrides = {
                raidOptionDisplayMainTankAndAssist = '0',
                raidFramesHealthText = 'perc',
                raidFramesDisplayOnlyDispellableDebuffs = '1',
                raidFramesDisplayDebuffs = '1',
                raidFramesDisplayPowerBars = '1',
                damageMeterEnabled = '1',
                enableMouseoverCast = '1',
                raidFramesDisplayClassColor = '1',
                threatShowNumeric = '1',
            },
            hiddenCVars = {},
            originalValues = {},
        }
    },
    char = {
        cvarOriginalValues = {},
        -- Recipes scanned from each profession window, keyed by profession name.
        craftProfit = {
            professions = {},
        },
        -- The stat display roles this character has switched on or off.
        statDisplay = {
            roles = {},
        },
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
        spellCostPercent = false,
        crateFillCosts = false,
        craftProfit = {
            enabled = false,
            showAll = false,
        },
        zoneLevels = false,
        fiveSecondRule = false,
        itemLevelCharacter = true,
        itemLevelInspect = true,
        itemLevelBag = true,
        itemLevelColorOverride = false,
        itemLevelColor = { r = 1, g = 1, b = 1 },
        highlightCheapestItem = false,
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
            enabled = false,
            overrides = {
                raidOptionDisplayMainTankAndAssist = '0',
                raidFramesHealthText = 'perc',
                raidFramesDisplayOnlyDispellableDebuffs = '1',
                raidFramesDisplayDebuffs = '1',
                raidFramesDisplayPowerBars = '1',
                damageMeterEnabled = '1',
                enableMouseoverCast = '1',
                raidFramesDisplayClassColor = '1',
                threatShowNumeric = '1',
            },
            hiddenCVars = {},
            originalValues = {},
        }
    },
    char = {
        cvarOriginalValues = {},
        craftProfit = {
            professions = {},
        },
    }
}

-- Run before AceDB fills defaults: older versions omitted enabled=true on logout.
function ScarletUI:PrepareCVarSettings()
    local saved = self.db and self.db.sv or ScarletUIDB
    local existing = type(saved) == "table" and next(saved) ~= nil
    if type(saved) ~= "table" then
        saved = {}
        ScarletUIDB = saved
    end
    saved.global = saved.global or {}
    saved.global.CVarModule = saved.global.CVarModule or {}
    local module = saved.global.CVarModule
    if module.onboarding == nil then
        module.onboarding = existing and "done" or "offer"
        if module.enabled == nil then module.enabled = existing end
    end
end

function ScarletUI:ResetDefaults()
    if self:InCombat() then return end
    -- Reset preferences without losing backups for this or other characters.
    local sharedOriginals = self.db.global.CVarModule.originalValues
    local originals = {}
    for key, character in pairs(self.db.sv and self.db.sv.char or {}) do
        originals[key] = character.cvarOriginalValues
    end
    self.db:ResetDB()
    self.db.global.CVarModule.onboarding = "done"
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
