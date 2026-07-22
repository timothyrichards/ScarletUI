local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

function ScarletUI:Options()
    local database = self.db.global;
    local defaults = self.db.defaults.global;

    return {
        name = "Scarlet UI",
        handler = self,
        type = "group",
        childGroups = "tree",
        args = {
            toggleMovers = {
                name = "Unlock Frames",
                desc = "Enables mover frames so you can drag UI elements to a new position.",
                type = "execute",
                disabled = function() return self:InCombat() end,
                hidden = function() return self.editMode or self.lightWeightMode end,
                order = 0,
                width = 1,
                func = function()
                    self:ToggleMovers()
                end,
            },
            resetPositions = {
                type = "execute",
                name = "Reset Positions",
                desc = "Reset all frame positions to their default settings.",
                hidden = function() return self.editMode or self.lightWeightMode end,
                func = function() StaticPopup_Show('SCARLET_RESTORE_POSITIONS_DIALOG') end,
                order = 1,
            },
            defaultSettings = {
                name = "Restore Defaults",
                desc = "Restores all settings back to default settings.",
                type = "execute",
                disabled = function() return self:InCombat() end,
                order = 2,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                end,
            },
            generalSettings = self:GetGeneralSettingsPage(database, 2),
            editModeSettings = self:GetEditModeSettingsPage(3),
            actionBarSettings = self:GetActionBarSettingsPage(database, 4),
            bagModuleSettings = self:GetBagModuleSettingsPage(database, defaults.bagModule, 5),
            chatModuleSettings = self:GetChatModuleSettingsPage(database, defaults.chatModule, 6),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database, 7),
            nameplatesModuleSettings = self:GetNameplatesModuleSettingsPage(database, defaults.nameplatesModule, 8),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(database, 9),
        }
    }
end

function ScarletUI:GetGeneralSettingsPage(database, order)
    return {
        name = "General Settings",
        desc = "Miscellaneous ScarletUI settings.",
        type = "group",
        order = order,
        args = {
            general = {
                name = "General",
                type = "group",
                inline = true,
                hidden = function() return self.lightWeightMode end,
                order = 0,
                args = {
                    expandCharacterInfo = {
                        name = "Auto Expand Character Info",
                        desc = "Automatically opens the side panel in the character window showing your stats, titles, and equipment manager.",
                        type = "toggle",
                        hidden = function() return self:GetWoWVersion() ~= "CATA" end,
                        width = 1.5,
                        order = 0,
                        get = function(_) return database.expandCharacterInfo end,
                        set = function(_, val)
                            database.expandCharacterInfo = val
                            self:SetupExpandCharacterInfo()
                        end,
                    },
                    tidyIcons = {
                        name = "Bigger Icons",
                        desc = "Make icons bigger to fill their actionbar slots.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.tidyIconsEnabled end,
                        set = function(_, val)
                            database.tidyIconsEnabled = val
                            self:SetupTidyIcons()
                        end,
                    },
                    clampMovers = {
                        name = "Clamp Movers",
                        desc = "Determines whether movers should be kept within the screens bounds or should be movable outside of them.",
                        type = "toggle",
                        hidden = function() return self.editMode end,
                        width = 1,
                        order = 2,
                        get = function(_) return database.clampMovers end,
                        set = function(_, val)
                            database.clampMovers = val
                            self:ShowReloadDialog()
                        end,
                    }
                }
            },
            itemLevel = {
                name = "Item Level",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    itemLevelCharacter = {
                        name = "Character Window",
                        desc = "Display item level for items in your character window.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return database.itemLevelCharacter end,
                        set = function(_, val)
                            database.itemLevelCharacter = val
                            self:CharacterFrameItemLevel()
                        end,
                    },
                    itemLevelInspect = {
                        name = "Inspect Window",
                        desc = "Display item level for items in the inspect window.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.itemLevelInspect end,
                        set = function(_, val)
                            database.itemLevelInspect = val
                            self:InspectFrameItemLevel()
                        end,
                    },
                    itemLevelBag = {
                        name = "Bags",
                        desc = "Display item level for items in your bags.",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return database.itemLevelBag end,
                        set = function(_, val)
                            database.itemLevelBag = val
                            self:BagItemLevel()
                        end,
                    },
                    itemLevelColorOverride = {
                        name = "Override Color",
                        desc = "Use a custom color for item level text instead of item quality colors.",
                        type = "toggle",
                        width = 1,
                        order = 3,
                        get = function(_) return database.itemLevelColorOverride end,
                        set = function(_, val)
                            database.itemLevelColorOverride = val
                            self:CharacterFrameItemLevel()
                            self:BagItemLevel()
                        end,
                    },
                    itemLevelColor = {
                        name = "Item Level Color",
                        desc = "Custom color for item level text.",
                        type = "color",
                        width = 1,
                        order = 4,
                        disabled = function() return not database.itemLevelColorOverride end,
                        get = function(_)
                            local c = database.itemLevelColor
                            return c.r, c.g, c.b
                        end,
                        set = function(_, r, g, b)
                            database.itemLevelColor = { r = r, g = g, b = b }
                            self:CharacterFrameItemLevel()
                            self:BagItemLevel()
                        end,
                    },
                },
            },
            modules = {
                name = "Enabled Modules",
                type = "group",
                disabled = function() return self:InCombat() end,
                inline = true,
                order = 2,
                args = {
                    actionbarsModuleEnabled = {
                        name = "Action Bars",
                        desc = "Apply ScarletUI-specific action bar preferences.",
                        type = "toggle",
                        hidden = function() return self.lightWeightMode and not self.editMode end,
                        width = 1,
                        order = 0,
                        get = function(_) return database.actionbarsModule.enabled end,
                        set = function(_, val)
                            database.actionbarsModule.enabled = val
                            if not val then
                                self:ShowReloadDialog()
                            else
                                self:SetupActionBars()
                            end
                        end,
                    },
                    bagModuleEnabled = {
                        name = "Bags",
                        desc = "Manage the settings and position of your bags.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.bagModule.enabled end,
                        set = function(_, val)
                            database.bagModule.enabled = val
                            if not val then
                                self:ShowReloadDialog()
                            else
                                ScarletUI:SetupBags()
                            end
                        end,
                    },
                    chatModuleEnabled = {
                        name = "Chat",
                        desc = "Manage the settings and position of your chat window.",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return database.chatModule.enabled end,
                        set = function(_, val)
                            database.chatModule.enabled = val
                            if not val then
                                self:ShowReloadDialog()
                            else
                                self:SetupChat()
                            end
                        end,
                    },
                    cVarModuleEnabled = {
                        name = "CVars",
                        desc = "Manage your CVars (meant for advanced users).",
                        type = "toggle",
                        width = 1,
                        order = 3,
                        get = function(_) return database.CVarModule.enabled end,
                        set = function(_, val)
                            database.CVarModule.enabled = val
                            if val then
                                ScarletUI:SetupCVars()
                            else
                                ScarletUI:RestoreCVarsDefaults()
                            end
                        end,
                    },
                    nameplatesModuleEnabled = {
                        name = "Nameplates",
                        desc = "Manage your Nameplates and threat colors.",
                        type = "toggle",
                        hidden = function() return self.lightWeightMode end,
                        width = 1,
                        order = 4,
                        get = function(_) return database.nameplatesModule.enabled end,
                        set = function(_, val)
                            database.nameplatesModule.enabled = val
                            if not val then
                                self:ShowReloadDialog()
                            else
                                self:SetupNameplates()
                            end
                        end,
                    },
                    raidFramesModuleEnabled = {
                        name = "Raid Frames",
                        desc = "Manage the settings and position of your raid frames.",
                        type = "toggle",
                        hidden = function() return self.editMode or self.lightWeightMode end,
                        width = 1,
                        order = 5,
                        get = function(_) return database.raidFramesModule.enabled end,
                        set = function(_, val)
                            database.raidFramesModule.enabled = val
                            if not val then
                                self:ShowReloadDialog()
                            else
                                self:SetupRaidProfiles()
                            end
                        end,
                    },
                    unitFramesModuleEnabled = {
                        name = "Unit Frames",
                        desc = "Manage the position of your unit frames.",
                        type = "toggle",
                        disabled = function() return self:InCombat() end,
                        hidden = function() return self.editMode or self.lightWeightMode end,
                        width = 1,
                        order = 6,
                        get = function(_) return database.unitFramesModule.enabled end,
                        set = function(_, val)
                            database.unitFramesModule.enabled = val
                            if not val then
                                self:ShowReloadDialog()
                            else
                                self:SetupUnitFrames()
                            end
                        end,
                    }
                }
            },
            extras = {
                name = "Extras",
                type = "group",
                hidden = function() return self.editMode or self.lightWeightMode or select(2, self:GetWoWVersion()) > 40000 end,
                inline = true,
                order = 3,
                args = {
                    description = {
                        name = "If you would like to use a profile that more similarly matches the default Blizzard UI, you can press the button below to reset your settings to a configuration that mimics the Blizzard UI settings.\n",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 0
                    },
                    resetToBlizzard = {
                        name = "Reset to Blizzard UI",
                        desc = "Reset all settings to a configuration that mimics Blizzard UI. (this will /reload your game)",
                        type = "execute",
                        disabled = function() return self:InCombat() end,
                        width = 1,
                        order = 1,
                        func = function()
                            self:MergeTables(self.db, self.originalUIDefaults)
                            ReloadUI()
                        end,
                    }
                }
            }
        }
    }
end

function ScarletUI:GetActionBarSettingsPage(database, order)
    local module = database.actionbarsModule

    return {
        name = "Action Bars",
        desc = "ScarletUI-specific action bar preferences. Position and Blizzard appearance settings are managed in Edit Mode.",
        type = "group",
        hidden = function() return self.lightWeightMode and not self.editMode end,
        order = order,
        args = {
            preferences = {
                name = "ScarletUI Preferences",
                type = "group",
                inline = true,
                disabled = function() return self:SettingDisabled(module.enabled) end,
                order = 0,
                args = {
                    microBag = {
                        name = "Micro Bag",
                        desc = "Hide all equipped-bag buttons except the backpack.",
                        type = "toggle",
                        hidden = function() return not MainMenuBarBackpackButton end,
                        width = 1,
                        order = 1,
                        get = function() return module.microBag end,
                        set = function(_, value)
                            module.microBag = value
                            self:SetupActionBarPreferences()
                        end,
                    },
                    extraActionBackground = {
                        name = "Extra Action Background",
                        desc = "Show the background artwork behind the extra action button.",
                        type = "toggle",
                        hidden = function()
                            local _, interfaceVersion = self:GetWoWVersion()
                            return interfaceVersion < 50000 or not ExtraActionButton1
                        end,
                        width = 1.25,
                        order = 2,
                        get = function() return module.extraActionBar.showBackground end,
                        set = function(_, value)
                            module.extraActionBar.showBackground = value
                            self:SetupActionBarPreferences()
                        end,
                    },
                    shortExperienceBar = {
                        name = "Short Experience Bar",
                        desc = "Shorten the experience bar without changing its Edit Mode scale.",
                        type = "toggle",
                        hidden = function()
                            return not MainMenuExpBar and not MainStatusTrackingBarContainer
                        end,
                        width = 1.25,
                        order = 3,
                        get = function() return module.experienceBar.short end,
                        set = function(_, value)
                            module.experienceBar.short = value
                            if value then
                                self:SetupActionBarPreferences()
                            else
                                self:ShowReloadDialog()
                            end
                        end,
                    },
                    shortReputationBar = {
                        name = "Short Reputation Bar",
                        desc = "Shorten the reputation bar without changing its Edit Mode scale.",
                        type = "toggle",
                        hidden = function()
                            return not ReputationWatchBar and not SecondaryStatusTrackingBarContainer
                        end,
                        width = 1.25,
                        order = 4,
                        get = function() return module.reputationBar.short end,
                        set = function(_, value)
                            module.reputationBar.short = value
                            if value then
                                self:SetupActionBarPreferences()
                            else
                                self:ShowReloadDialog()
                            end
                        end,
                    },
                },
            },
        },
    }
end

function ScarletUI:GetBagModuleSettingsPage(database, defaults, order)
    local module = database.bagModule;

    return {
        name = "Bag",
        desc = "Bag Module settings.",
        type = "group",
        order = order,
        hidden = function() return self.lightWeightMode end,
        args = {
            generalSettings = {
                name = "General Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 0,
                args = {
                    slotsPerRow = {
                        name = "Bag Slots Per Row",
                        desc = "Must be a number, this is the number of bag slots per row.\n(Default " .. defaults.slotsPerRow .. ")",
                        type = "range",
                        min = 1,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 0,
                        get = function(_) return module.slotsPerRow end,
                        set = function(_, val)
                            module.slotsPerRow = val
                            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                        end,
                    },
                    slotSize = {
                        name = "Bag Slot Size",
                        desc = "Must be a number, this is the size of the bag slots.\n(Default " .. defaults.slotSize .. ")",
                        type = "range",
                        min = 16,
                        max = 64,
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.slotSize end,
                        set = function(_, val)
                            module.slotSize = val
                            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                        end,
                    },
                    slotSpacing = {
                        name = "Bag Slot Spacing",
                        desc = "Must be a number, this is the space between the bag slots.\n(Default " .. defaults.slotSpacing .. ")",
                        type = "range",
                        min = 0,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.slotSpacing end,
                        set = function(_, val)
                            module.slotSpacing = val
                            StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                        end,
                    }
                }
            },
            playerBagSettings = {
                name = "Player Bags",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 1,
                args = {
                    bagLocked = {
                        name = "Lock Position",
                        desc = "When checked, the bag frame cannot be dragged.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.bagLocked end,
                        set = function(_, val)
                            module.bagLocked = val
                        end,
                    },
                    bagAlpha = {
                        name = "Background Opacity",
                        desc = "Controls the background transparency of the bag frame.\n(Default " .. defaults.bagAlpha .. ")",
                        type = "range",
                        min = 0,
                        max = 1,
                        step = 0.05,
                        width = 1,
                        order = 1,
                        get = function(_) return module.bagAlpha end,
                        set = function(_, val)
                            module.bagAlpha = val
                            if self.bagFrame then
                                self.bagFrame:SetBackdropColor(0, 0, 0, val)
                            end
                        end,
                    },
                    resetBagPosition = {
                        name = "Reset Position",
                        desc = "Reset the bag frame to its default position.",
                        type = "execute",
                        width = 1,
                        order = 2,
                        func = function()
                            if self.bagFrame then
                                self.bagFrame:ClearAllPoints()
                                self.bagFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -1, 40)
                            end
                        end,
                    },
                }
            },
            bankSettings = {
                name = "Bank",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 2,
                args = {
                    bankLocked = {
                        name = "Lock Position",
                        desc = "When checked, the bank frame cannot be dragged.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.bankLocked end,
                        set = function(_, val)
                            module.bankLocked = val
                        end,
                    },
                    bankAlpha = {
                        name = "Background Opacity",
                        desc = "Controls the background transparency of the bank frame.\n(Default " .. defaults.bankAlpha .. ")",
                        type = "range",
                        min = 0,
                        max = 1,
                        step = 0.05,
                        width = 1,
                        order = 1,
                        get = function(_) return module.bankAlpha end,
                        set = function(_, val)
                            module.bankAlpha = val
                            if self.bankFrame then
                                self.bankFrame:SetBackdropColor(0, 0, 0, val)
                            end
                        end,
                    },
                    resetBankPosition = {
                        name = "Reset Position",
                        desc = "Reset the bank frame to its default position.",
                        type = "execute",
                        width = 1,
                        order = 2,
                        func = function()
                            if self.bankFrame then
                                self.bankFrame:ClearAllPoints()
                                self.bankFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 1, 40)
                            end
                        end,
                    },
                }
            }
        }
    }
end

function ScarletUI:GetChatModuleSettingsPage(database, defaults, order)
    local module = database.chatModule;

    return {
        name = "Chat",
        desc = "Chat Module settings.",
        type = "group",
        childGroups = "tab",
        order = order,
        args = {
            generalSettings = {
                name = "Chat Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 0,
                args = {
                    fontSize = {
                        name = "Chat Font Size",
                        desc = "Desired font size for chat windows.\n(Default " .. defaults.fontSize .. ")",
                        type = "range",
                        min = 6,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 0,
                        get = function(_) return module.fontSize end,
                        set = function(_, val)
                            module.fontSize = val
                            self:SetupChat()
                        end,
                    },
                }
            },
            tabs = {
                name = "Tabs",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 1,
                args = {
                    description = {
                        name = "If you don't see these chat tabs being created, right click any chat tab, click settings, then click 'Chat Defaults'.\n\n",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 0,
                    },
                    loot = {
                        name = "Loot Tab",
                        desc = "Create tab for loot.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return module.tabs.loot end,
                        set = function(_, val)
                            module.tabs.loot = val
                            self:SetupChatTabs()
                        end,
                    },
                    trade = {
                        name = "Trade Tab",
                        desc = "Create tab for trade.",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return module.tabs.trade end,
                        set = function(_, val)
                            module.tabs.trade = val
                            self:SetupChatTabs()
                        end,
                    },
                    lfg = {
                        name = "LFG Tab",
                        desc = "Create tab for lfg.",
                        type = "toggle",
                        hidden = function() return self.lightWeightMode end,
                        width = 1,
                        order = 3,
                        get = function(_) return module.tabs.lfg end,
                        set = function(_, val)
                            module.tabs.lfg = val
                            self:SetupChatTabs()
                        end,
                    }
                }
            }
        }
    }
end

local searchQuery = ""
function ScarletUI:GetCVarModuleSettingsPage(database, order)
    local module = database.CVarModule

    local options = {
        name = "CVars",
        desc = "Set CVar overrides that sync across characters. Only CVars you explicitly set will be changed.",
        type = "group",
        order = order,
        args = {
            information = {
                name = "Info",
                type = "group",
                inline = true,
                order = 0,
                args = {
                    description = {
                        name = "Browse available CVars below. Set a value to override it, or clear to restore the WoW default.\n\nYou can also add custom CVars by name using the field below.",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 0,
                    },
                    link = {
                        name = "",
                        type = "input",
                        order = 1,
                        width = 2,
                        get = function() return "https://warcraft.wiki.gg/wiki/Console_variables" end,
                    }
                }
            },
            addCustom = {
                name = "Add Custom CVar",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    addField = {
                        order = 0,
                        name = "",
                        desc = "Type a CVar name and press Enter to add it",
                        type = "input",
                        width = 1.5,
                        get = function() return "" end,
                        set = function(_, val)
                            if val == "" then return end

                            -- Un-hide if previously hidden
                            if module.hiddenCVars[val] then
                                module.hiddenCVars[val] = nil
                                if not ScarletUI:ArrayHasValue(ScarletUI.knownCVars, val) then
                                    table.insert(ScarletUI.knownCVars, val)
                                    table.sort(ScarletUI.knownCVars, function(a, b)
                                        return string.lower(a) < string.lower(b)
                                    end)
                                end
                                ScarletUI:Print("Restored CVar: |cff00ff00" .. val .. "|r")
                                AceConfigRegistry:NotifyChange("ScarletUI")
                                return
                            end

                            -- Check if already in the list
                            if ScarletUI:ArrayHasValue(ScarletUI.knownCVars, val) then
                                ScarletUI:Print("|cffff4444" .. val .. "|r is already in the CVar list.")
                                return
                            end

                            -- Check if it's a valid CVar
                            if GetCVar(val) == nil then
                                ScarletUI:Print("|cffff4444" .. val .. "|r is not a valid CVar.")
                                return
                            end

                            table.insert(ScarletUI.knownCVars, val)
                            table.sort(ScarletUI.knownCVars, function(a, b)
                                return string.lower(a) < string.lower(b)
                            end)

                            -- Auto-override if current value differs from default
                            local currentVal = tostring(GetCVar(val))
                            local defaultVal = tostring(GetCVarDefault(val))
                            if currentVal ~= defaultVal then
                                module.overrides[val] = currentVal
                                ScarletUI:Print("Added CVar: |cff00ff00" .. val .. "|r (override set — current value differs from default)")
                            else
                                ScarletUI:Print("Added CVar: |cff00ff00" .. val .. "|r")
                            end

                            AceConfigRegistry:NotifyChange("ScarletUI")
                        end,
                    },
                }
            },
            search = {
                name = "CVars",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 2,
                args = {
                    searchField = {
                        order = 0,
                        name = "",
                        desc = "Filter CVars",
                        type = "input",
                        get = function() return searchQuery end,
                        set = function(_, val)
                            searchQuery = val
                            AceConfigRegistry:NotifyChange("ScarletUI")
                        end,
                        width = "full",
                    },
                }
            }
        }
    }

    local function ShouldOptionBeHidden(cvarName)
        if searchQuery == "" then
            return false
        end
        return not string.find(string.lower(cvarName), string.lower(searchQuery), 1, true)
    end

    -- Sort the known CVars, excluding hidden ones
    local sortedCVars = {}
    for _, name in ipairs(ScarletUI.knownCVars) do
        if not module.hiddenCVars[name] then
            table.insert(sortedCVars, name)
        end
    end
    -- Also include any overrides that aren't in the known list (custom CVars from previous sessions)
    for name, _ in pairs(module.overrides) do
        if not module.hiddenCVars[name] and not ScarletUI:ArrayHasValue(sortedCVars, name) then
            table.insert(sortedCVars, name)
        end
    end
    table.sort(sortedCVars, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    local orderCounter = 0
    for _, cvarName in ipairs(sortedCVars) do
        orderCounter = orderCounter + 1
        local labelKey = "label" .. orderCounter
        local inputKey = "input" .. orderCounter
        local clearKey = "clear" .. orderCounter
        local spacerKey = "spacer" .. orderCounter

        local isValid = GetCVar(cvarName) ~= nil
        local hasOverride = module.overrides[cvarName] ~= nil

        -- CVar name label — red if invalid, green if overridden
        local labelText
        if not isValid then
            labelText = "|cffff4444" .. cvarName .. " (invalid)|r"
        elseif hasOverride then
            labelText = "|cff00ff00" .. cvarName .. "|r"
        else
            labelText = cvarName
        end

        local labelDesc = ""
        if isValid then
            labelDesc = "Default: " .. tostring(GetCVarDefault(cvarName))
        end

        options.args.search.args[labelKey] = {
            name = labelText,
            desc = labelDesc,
            type = "description",
            width = 1.2,
            order = orderCounter * 5 - 4,
            hidden = function() return ShouldOptionBeHidden(cvarName) end,
        }

        -- Override input field
        options.args.search.args[inputKey] = {
            name = "",
            desc = isValid and ("Current: " .. tostring(GetCVar(cvarName))) or "This CVar does not exist in your WoW version",
            type = "input",
            width = 0.6,
            order = orderCounter * 5 - 3,
            get = function()
                if module.overrides[cvarName] then
                    return module.overrides[cvarName]
                end
                return isValid and tostring(GetCVarDefault(cvarName)) or ""
            end,
            set = function(_, val)
                if val == "" then
                    ScarletUI:ClearCVarOverride(cvarName)
                else
                    module.overrides[cvarName] = val
                    ScarletUI:SetupCVars()
                end
                AceConfigRegistry:NotifyChange("ScarletUI")
            end,
            disabled = function() return not isValid end,
            hidden = function() return ShouldOptionBeHidden(cvarName) end,
        }

        -- Clear button
        options.args.search.args[clearKey] = {
            name = "Default",
            desc = "Clear override and restore WoW default",
            type = "execute",
            width = 0.5,
            order = orderCounter * 5 - 2,
            func = function()
                ScarletUI:ClearCVarOverride(cvarName)
                AceConfigRegistry:NotifyChange("ScarletUI")
            end,
            disabled = function() return not hasOverride end,
            hidden = function() return ShouldOptionBeHidden(cvarName) end,
        }

        -- Remove button
        local removeKey = "remove" .. orderCounter
        options.args.search.args[removeKey] = {
            name = "Remove",
            desc = "Remove this CVar from the list (re-add via the custom CVar field)",
            type = "execute",
            width = 0.5,
            order = orderCounter * 5 - 1,
            func = function()
                ScarletUI:ClearCVarOverride(cvarName)
                module.hiddenCVars[cvarName] = true
                AceConfigRegistry:NotifyChange("ScarletUI")
            end,
            hidden = function() return ShouldOptionBeHidden(cvarName) end,
        }

        -- Spacer
        options.args.search.args[spacerKey] = {
            name = "",
            type = "description",
            width = "full",
            order = orderCounter * 5,
            hidden = function() return ShouldOptionBeHidden(cvarName) end,
        }
    end

    return options
end

function ScarletUI:GetNameplatesModuleSettingsPage(database, defaults, order)
    local module = database.nameplatesModule;
    local characterDatabase = self.db.char;

    return {
        name = "Nameplates",
        desc = "Nameplates Module settings.",
        type = "group",
        childGroups = "tab",
        order = order,
        hidden = function() return self.lightWeightMode end,
        args = {
            generalSettings = {
                name = "Nameplate Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 0,
                args = {
                    classColored = {
                        name = "Class Colors",
                        desc = "Change player nameplates to match their class color.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.classColored end,
                        set = function(_, val) module.classColored = val end,
                    },
                    threatColored = {
                        name = "Threat Colors",
                        desc = "Change enemy npc nameplates to reflect their threat status as a color (colors and tank names adjusted below).",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return module.threatColored end,
                        set = function(_, val) module.threatColored = val end,
                    },
                    specialUnitsColored = {
                        name = "Special Unit Colors",
                        desc = "Change nameplates the special unit coloring based on name if defined (colors and unit names adjusted below).",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return module.specialUnitsColored end,
                        set = function(_, val) module.specialUnitsColored = val end,
                    },
                }
            },
            debuffTracker = {
                name = "Buff/Debuff Tracker",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 1,
                args = {
                    trackBuffs = {
                        name = "Track Purgable Buffs",
                        desc = "Show purgable buffs and their durations on the nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.buffTracker.track end,
                        set = function(_, val)
                            module.buffTracker.track = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    iconSizeBuffs = {
                        name = "Icon Size",
                        desc = "Must be a number, this is the size of the debuff icons.\n(Default " .. defaults.debuffTracker.iconSize .. ")",
                        type = "range",
                        min = 1,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.buffTracker.iconSize end,
                        set = function(_, val)
                            module.buffTracker.iconSize = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    spacingBuffs = {
                        name = "Icon Spacing",
                        desc = "Must be a number, this is the space between the debuff icons.\n(Default " .. defaults.debuffTracker.spacing .. ")",
                        type = "range",
                        min = 0,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.buffTracker.spacing end,
                        set = function(_, val)
                            module.buffTracker.spacing = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    verticalOffsetBuffs = {
                        name = "Vertical Offset",
                        desc = "Must be a number, this is the vertical offset of the debuff row from the nameplate.\n(Default " .. defaults.debuffTracker.verticalOffset .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.buffTracker.verticalOffset end,
                        set = function(_, val)
                            module.buffTracker.verticalOffset = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    trackDebuffs = {
                        name = "Track Debuffs",
                        desc = "Show debuffs and their durations on the nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 4,
                        get = function(_) return module.debuffTracker.track end,
                        set = function(_, val)
                            module.buffTracker.track = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    iconSizeDebuffs = {
                        name = "Icon Size",
                        desc = "Must be a number, this is the size of the debuff icons.\n(Default " .. defaults.debuffTracker.iconSize .. ")",
                        type = "range",
                        min = 1,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.debuffTracker.iconSize end,
                        set = function(_, val)
                            module.debuffTracker.iconSize = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    spacingDebuffs = {
                        name = "Icon Spacing",
                        desc = "Must be a number, this is the space between the debuff icons.\n(Default " .. defaults.debuffTracker.spacing .. ")",
                        type = "range",
                        min = 0,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.debuffTracker.spacing end,
                        set = function(_, val)
                            module.debuffTracker.spacing = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    verticalOffsetDebuffs = {
                        name = "Vertical Offset",
                        desc = "Must be a number, this is the vertical offset of the debuff row from the nameplate.\n(Default " .. defaults.debuffTracker.verticalOffset .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 7,
                        get = function(_) return module.debuffTracker.verticalOffset end,
                        set = function(_, val)
                            module.debuffTracker.verticalOffset = val
                            self:ReapplySettingsToAuraIcons()
                        end,
                    },
                    priorityDebuffs = {
                        name = "Priority Debuffs",
                        type = "input",
                        desc = "Add a comma seperated list of debuff spell names you wish to always track even if they're applied by another player, for example: Sunder Armor,Expose Armor,Hammer of Justice\n(This setting is saved per character)",
                        width = "full",
                        order = 8,
                        get = function(_) return characterDatabase.priorityDebuffs end,
                        set = function(_, value)
                            characterDatabase.priorityDebuffs = value
                            self:SetupPriorityDebuffs()
                        end,
                    },
                }
            },
            targetIndicator = {
                name = "Target Indicator",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 2,
                args = {
                    show = {
                        name = "Show",
                        desc = "Add target indicator to nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 1,
                        get = function(_) return module.targetIndicator.show end,
                        set = function(_, val)
                            module.targetIndicator.show = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    },
                    indicatorSize = {
                        name = "Indicator Size",
                        desc = "Must be a number, this is the size of the target arrows around the nameplate.\n(Default " .. defaults.targetIndicator.indicatorSize .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.targetIndicator.indicatorSize end,
                        set = function(_, val)
                            module.targetIndicator.indicatorSize = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    },
                    indicatorDistance = {
                        name = "Indicator Distance",
                        desc = "Must be a number, this is the space of the target arrows around the nameplate.\n(Default " .. defaults.targetIndicator.indicatorDistance .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.targetIndicator.indicatorDistance end,
                        set = function(_, val)
                            module.targetIndicator.indicatorDistance = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    },
                    indicatorHeight = {
                        name = "Indicator Height",
                        desc = "Must be a number, this is the height of the target arrows on the nameplate.\n(Default " .. defaults.targetIndicator.indicatorHeight .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 4,
                        get = function(_) return module.targetIndicator.indicatorHeight end,
                        set = function(_, val)
                            module.targetIndicator.indicatorHeight = val
                            ScarletUI:UpdateTargetArrows()
                        end,
                    }
                },
            },
            text = {
                name = "Text",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 3,
                args = {
                    healthBarText = {
                        name = "Health Bar Text",
                        type = "group",
                        inline = true,
                        order = 0,
                        args = {
                            show = {
                                name = "Show",
                                desc = "Add health text to health bar on nameplates.",
                                type = "toggle",
                                width = 0.5,
                                order = 1,
                                get = function(_) return module.healthBarText.show end,
                                set = function(_, val)
                                    module.healthBarText.show = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                desc = "Desired font size for health bar text.\n(Default " .. defaults.healthBarText.fontSize .. ")",
                                type = "range",
                                min = 6,
                                max = 20,
                                step = 1,
                                width = 1,
                                order = 4,
                                get = function(_) return module.healthBarText.fontSize end,
                                set = function(_, val)
                                    module.healthBarText.fontSize = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            }
                        },
                    },
                    threatAmountText = {
                        name = "Threat Text",
                        type = "group",
                        inline = true,
                        order = 1,
                        args = {
                            show = {
                                name = "Show",
                                desc = "Add threat text next to nameplates.",
                                type = "toggle",
                                width = 0.5,
                                order = 1,
                                get = function(_) return module.threatAmountText.show end,
                                set = function(_, val)
                                    module.threatAmountText.show = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                desc = "Desired font size for cast threat text.\n(Default " .. defaults.threatAmountText.fontSize .. ")",
                                type = "range",
                                min = 6,
                                max = 20,
                                step = 1,
                                width = 1,
                                order = 4,
                                get = function(_) return module.threatAmountText.fontSize end,
                                set = function(_, val)
                                    module.threatAmountText.fontSize = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            --anchor = {
                            --    name = "Text Anchor",
                            --    desc = "Anchor point of the frame.\n(Default " .. defaults.threatAmountText.anchor .. ")",
                            --    type = "select",
                            --    width = 1,
                            --    order = 4,
                            --    values = function() return { "LEFT", "RIGHT" } end,
                            --    get = function(_) return module.threatAmountText.anchor end,
                            --    set = function(_, val)
                            --        module.threatAmountText.anchor = val
                            --    end,
                            --},
                        },
                    },
                    castBarText = {
                        name = "Cast Bar Text",
                        type = "group",
                        inline = true,
                        order = 2,
                        args = {
                            show = {
                                name = "Show",
                                desc = "Add cast text to cast bar on nameplates.",
                                type = "toggle",
                                width = 0.5,
                                order = 1,
                                get = function(_) return module.castBarText.show end,
                                set = function(_, val)
                                    module.castBarText.show = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            },
                            fontSize = {
                                name = "Font Size",
                                desc = "Desired font size for cast bar text.\n(Default " .. defaults.castBarText.fontSize .. ")",
                                type = "range",
                                min = 6,
                                max = 20,
                                step = 1,
                                width = 1,
                                order = 4,
                                get = function(_) return module.castBarText.fontSize end,
                                set = function(_, val)
                                    module.castBarText.fontSize = val
                                    self:ReapplyTextSettingsToNameplates()
                                end,
                            }
                        },
                    },
                }
            },
            threatColors = {
                name = "Threat Colors",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 5,
                args = {
                    dropdownMenuButton = {
                        name = "Dropdown Menu Button",
                        desc = "Adds a button to the right click dropdown to add or remove tanks from the tank names list. NOTE",
                        type = "toggle",
                        width = "full",
                        disabled = true,
                        order = 0,
                        get = function(_) return module.dropdownMenuButton end,
                        set = function(_, val) module.dropdownMenuButton = val end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 0.1,
                    },
                    description1 = {
                        name = "|cffffd100These are the colors you see as a |cffff0900DPS|r or |cff15fb00Healer|r.|r",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 1,
                    },
                    otherNoThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 2,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.noThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.noThreat = {r, g, b, a}
                        end,
                    },
                    otherLowThreat = {
                        name = "Low Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 3,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.lowThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.lowThreat = {r, g, b, a}
                        end,
                    },
                    otherThreat = {
                        name = "Have Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 4,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.threat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.threat = {r, g, b, a}
                        end,
                    },
                    otherPetThreat = {
                        name = "Pet Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 5,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.pet)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.pet = {r, g, b, a}
                        end,
                    },
                    otherTankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 6,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 6.1,
                    },
                    description2 = {
                        name = "|cffffd100These are the colors you see as a |cff00b3ffTank|r.|r",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 7,
                    },
                    noThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 8,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.noThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.noThreat = {r, g, b, a}
                        end,
                    },
                    lowThreat = {
                        name = "Low Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 9,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.lowThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.lowThreat = {r, g, b, a}
                        end,
                    },
                    threat = {
                        name = "Have Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 10,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.threat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.threat = {r, g, b, a}
                        end,
                    },
                    petThreat = {
                        name = "Pet Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 11,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.pet)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.pet = {r, g, b, a}
                        end,
                    },
                    tankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 12,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                    tankNames = {
                        name = "Tank Names",
                        type = "input",
                        desc = "Add a comma seperated list of player names you wish to manually designate as tanks, for example: Tank1,Tank2,Tank3\n\nPlayers with the role of tank (in versions of WoW that have roles) and players marked Main Tank or Main Assist in raids, will automatically be designated as tanks by the nameplate colors.",
                        width = "full",
                        order = 13,
                        get = function(_) return module.tankNames end,
                        set = function(_, value)
                            module.tankNames = value
                            self:SetupTanks(module)
                        end,
                    },
                },
            },
            specialUnits = {
                name = "Special Units",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 8,
                args = {
                    specialUnitColor = {
                        name = "Special Unit Color",
                        type = "color",
                        desc = "Choose a color",
                        width = 1,
                        hasAlpha = true,
                        order = 0,
                        get = function(_)
                            local r, g, b, a = unpack(module.specialUnitColor)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.specialUnitColor = {r, g, b, a}
                        end,
                    },
                    specialUnitNames = {
                        name = "Special Unit Names",
                        type = "input",
                        desc = "Add a comma seperated list of enemy unit names you wish to manually designate as special units, for example: Unit1,Unit2,Unit3",
                        width = "full",
                        order = 1,
                        get = function(_) return module.specialUnitNames end,
                        set = function(_, value)
                            module.specialUnitNames = value
                            self:SetupSpecialUnits(module)
                        end,
                    }
                }
            }
        }
    }
end

function ScarletUI:GetRaidFramesModuleSettingsPage(database, order)
    local module = database.raidFramesModule;

    return {
        name = "Raid Frames",
        desc = "Raid Frames Module settings.",
        type = "group",
        order = order,
        hidden = function() return self.editMode or self.lightWeightMode end,
        args = {
            partyFrames = {
                name = "Party Frames",
                type = "group",
                inline = true,
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    createProfile = {
                        name = "Create Party Frames Profile",
                        desc = "Creates a raid frames profile for 5 man groups.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return module.profiles.Party.createProfile end,
                        set = function(_, val)
                            module.profiles.Party.createProfile = val

                            if val then
                                self:UpdateProfileOptions()
                            else
                                self.raidProfileToDelete = "Party"
                                StaticPopupDialogs['SCARLET_DELETE_RAID_PROFILE_DIALOG'].text = '<Scarlet UI>\n\nWould you also like to delete the "Party" raid frames profile?'
                                StaticPopup_Show("SCARLET_DELETE_RAID_PROFILE_DIALOG")
                            end
                        end,
                    },
                    moveFrame = {
                        name = "Synchronize Party Frames Profile",
                        desc = "Allows you to synchronize the position of the party frames between characters.",
                        type = "toggle",
                        width = 1.5,
                        disabled = function() return not module.profiles.Party.createProfile end,
                        order = 1,
                        get = function(_) return module.profiles.Party.move end,
                        set = function(_, val)
                            module.profiles.Party.move = val
                            self:UpdateProfilePositions()
                        end,
                    },
                }
            },
            raidFrames = {
                name = "Raid Frames",
                type = "group",
                inline = true,
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    createProfile = {
                        name = "Create Raid Frames Profile",
                        desc = "Creates a raid frames profile for 10+ man groups.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return module.profiles.Raid.createProfile end,
                        set = function(_, val)
                            module.profiles.Raid.createProfile = val

                            if val then
                                self:UpdateProfileOptions()
                            else
                                self.raidProfileToDelete = "Raid"
                                StaticPopupDialogs['SCARLET_DELETE_RAID_PROFILE_DIALOG'].text = '<Scarlet UI>\n\nWould you also like to delete the "Raid" raid frames profile?'
                                StaticPopup_Show("SCARLET_DELETE_RAID_PROFILE_DIALOG")
                            end
                        end,
                    },
                    moveFrame = {
                        name = "Synchronize Raid Frames Profile",
                        desc = "Allows you to synchronize the position of the raid frames between characters.",
                        type = "toggle",
                        width = 1.5,
                        disabled = function() return not module.profiles.Raid.createProfile end,
                        order = 1,
                        get = function(_) return module.profiles.Raid.move end,
                        set = function(_, val)
                            module.profiles.Raid.move = val
                            self:UpdateProfilePositions()
                        end,
                    },
                }
            }
        }
    }
end
