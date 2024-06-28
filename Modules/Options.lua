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
                hidden = function() return self.retail end,
                order = 0,
                width = 1,
                func = function()
                    self:ToggleMovers()
                end,
            },
            defaultSettings = {
                name = "Restore Defaults",
                desc = "Restores all settings back to default settings.",
                type = "execute",
                disabled = function() return self:InCombat() end,
                order = 1,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                end,
            },
            generalSettings = self:GetGeneralSettingsPage(database, 2),
            --bagModuleSettings = self:GetBagModuleSettingsPage(database, defaults.bagModule, 2),
            chatModuleSettings = self:GetChatModuleSettingsPage(database, defaults.chatModule, 3),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database, 4),
            nameplatesModuleSettings = self:GetNameplatesModuleSettingsPage(database, defaults.nameplatesModule, 5),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(database, defaults.raidFramesModule, 6),
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
                hidden = function() return self:GetWoWVersion() ~= "CATA" end,
                inline = true,
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
                        disabled = function() return self.lightWeightMode end,
                        width = 1,
                        order = 1,
                        get = function(_) return database.tidyIconsEnabled end,
                        set = function(_, val)
                            database.tidyIconsEnabled = val
                            self:SetupTidyIcons()
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
                        name = "Actionbars",
                        desc = "Manage the position of your actionbars.",
                        type = "toggle",
                        hidden = function() return self.retail end,
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
                    --bagModuleEnabled = {
                    --    name = "Bags",
                    --    desc = "Manage the settings and position of your bags.",
                    --    type = "toggle",
                    --    width = 1,
                    --    order = 1,
                    --    get = function(_) return database.bagModule.enabled end,
                    --    set = function(_, val)
                    --        database.bagModule.enabled = val
                    --        if not val then
                    --            self:ShowReloadPopup()
                    --        else
                    --            ScarletUI:SetupBags()
                    --        end
                    --    end,
                    --},
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
                            if not val then
                                database.CVarModule.enabled = val
                                ScarletUI:RestoreCVarsDefaults()
                            else
                                StaticPopup_Show('SCARLET_ENABLE_CVARS_DIALOG')
                            end
                        end,
                    },
                    nameplatesModuleEnabled = {
                        name = "Nameplates",
                        desc = "Manage your Nameplates and threat colors.",
                        type = "toggle",
                        hidden = function() return self.retail end,
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
                        hidden = function() return self.retail end,
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
                        hidden = function() return self.retail end,
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

function ScarletUI:GetBagModuleSettingsPage(database, defaults, order)
    local module = database.bagModule;

    return {
        name = "Bag",
        desc = "Bag Module settings.",
        type = "group",
        order = order,
        disabled = function() return self.lightWeightMode end,
        hidden = function() return self.retail end,
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
                            self:SetupBags()
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
                            self:SetupBags()
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
                            self:SetupBags()
                        end,
                    }
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
                name = "General Settings",
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
                    height = {
                        name = "Chat Height",
                        desc = "Desired height for the chat window.\n(Default " .. defaults.height .. ")",
                        type = "range",
                        min = 0,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.height end,
                        set = function(_, val)
                            module.height = val
                            self:SetupChat()
                        end,
                    },
                    width = {
                        name = "Chat Width",
                        desc = "Desired width for the chat window.\n(Default " .. defaults.width .. ")",
                        type = "range",
                        min = 0,
                        max = math.floor(GetScreenWidth()),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.width end,
                        set = function(_, val)
                            module.width = val
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
                        hidden = function() return self.retail end,
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
    local CVars = module.CVars

    local options = {
        name = "CVars",
        desc = "CVars Module for advanced users to change console variables and have them automatically synchronize between characters.",
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
                        name = "You can copy the Wowpedia link below for a reference to all console variables and what they do.\n\nIf you have any requests for new CVars to be added, please leave a comment on CurseForge page for ScarletUI.",
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
                        get = function() return "https://wowpedia.fandom.com/wiki/Console_variables" end,
                    }
                }
            },
            search = {
                name = "Search",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 1,
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

    local function ShouldOptionBeHidden(optionKey)
        -- If searchQuery is empty, show all options
        if searchQuery == "" then
            return false
        end
        -- Convert both strings to lower case for case-insensitive comparison
        return not string.find(string.lower(optionKey), string.lower(searchQuery), 1, true)
    end

    -- Create a table of keys
    local keys = {}
    for k in pairs(CVars) do
        table.insert(keys, k)
    end

    -- Sort the keys in a case-insensitive manner
    table.sort(keys, function(a, b)
        return string.lower(a) < string.lower(b)
    end)

    local orderCounter = 0
    for _, k in pairs(keys) do
        orderCounter = orderCounter + 1
        local labelName = "label" .. orderCounter
        local spacerName = "spacer" .. orderCounter

        options.args.search.args[labelName] = {
            name = k,
            type = "description",
            width = 1.25,
            order = orderCounter * 3 - 2,
            hidden = function() return ShouldOptionBeHidden(k) end,
        }

        options.args.search.args[k] = {
            name = "",
            desc = "",
            type = "input",
            width = 0.5,
            order = orderCounter * 3 - 1,
            get = function(_) return CVars[k] end,
            set = function(_, val)
                CVars[k] = val
                ScarletUI:SetupCVars()
            end,
            hidden = function() return ShouldOptionBeHidden(k) end,
        }

        options.args.search.args[spacerName] = {
            name = "",
            type = "description",
            width = "full",
            order = orderCounter * 3,
            hidden = function() return ShouldOptionBeHidden(k) end,
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
        disabled = function() return self.lightWeightMode end,
        hidden = function() return self.retail end,
        args = {
            generalSettings = {
                name = "General Settings",
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
                name = "Debuff Tracker",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                order = 1,
                args = {
                    track = {
                        name = "Track Debuffs",
                        desc = "Show debuffs and their durations on the nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.debuffTracker.track end,
                        set = function(_, val)
                            module.debuffTracker.track = val
                            self:ReapplySettingsToDebuffIcons()
                        end,
                    },
                    iconSize = {
                        name = "Icon Size",
                        desc = "Must be a number, this is the size of the debuff icons.\n(Default " .. defaults.debuffTracker.iconSize .. ")",
                        type = "range",
                        min = 1,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.debuffTracker.iconSize end,
                        set = function(_, val)
                            module.debuffTracker.iconSize = val
                            self:ReapplySettingsToDebuffIcons()
                        end,
                    },
                    spacing = {
                        name = "Icon Spacing",
                        desc = "Must be a number, this is the space between the debuff icons.\n(Default " .. defaults.debuffTracker.spacing .. ")",
                        type = "range",
                        min = 0,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.debuffTracker.spacing end,
                        set = function(_, val)
                            module.debuffTracker.spacing = val
                            self:ReapplySettingsToDebuffIcons()
                        end,
                    },
                    verticalOffset = {
                        name = "Vertical Offset",
                        desc = "Must be a number, this is the vertical offset of the debuff row from the nameplate.\n(Default " .. defaults.debuffTracker.verticalOffset .. ")",
                        type = "range",
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 4,
                        get = function(_) return module.debuffTracker.verticalOffset end,
                        set = function(_, val)
                            module.debuffTracker.verticalOffset = val
                            self:ReapplySettingsToDebuffIcons()
                        end,
                    },
                    priorityDebuffs = {
                        name = "Priority Debuffs",
                        type = "input",
                        desc = "Add a comma seperated list of debuff spell names you wish to always track even if they're applied by another player, for example: Sunder Armor,Expose Armor,Hammer of Justice\n(This setting is saved per character)",
                        width = "full",
                        order = 5,
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
                    castBarText = {
                        name = "Cast Bar Text",
                        type = "group",
                        inline = true,
                        order = 1,
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
                        desc = "Adds a button to the right click dropdown to add or remove tanks from the tank names list.",
                        type = "toggle",
                        width = "full",
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
                    otherTankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 5,
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
                        order = 5.1,
                    },
                    description2 = {
                        name = "|cffffd100These are the colors you see as a |cff00b3ffTank|r.|r",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 6,
                    },
                    noThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 7,
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
                        order = 8,
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
                        order = 9,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.threat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.threat = {r, g, b, a}
                        end,
                    },
                    tankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 10,
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
                        order = 11,
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

function ScarletUI:GetRaidFramesModuleSettingsPage(database, defaults, order)
    local module = database.raidFramesModule;

    return {
        name = "Raid Frames",
        desc = "Raid Frames Module settings.",
        type = "group",
        order = order,
        disabled = function() return self.lightWeightMode end,
        hidden = function() return self.retail end,
        args = {
            information = {
                name = "Info",
                type = "group",
                inline = true,
                order = 0,
                args = {
                    description = {
                        name = "Please note that any changes made on this page will require a /reload to be reflected visually.",
                        type = "description",
                        width = "full",
                        fontSize = "medium"
                    },
                }
            },
            partyFrames = {
                name = "Party Frames",
                type = "group",
                inline = true,
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Party Frames",
                        desc = "Allows you to choose the position of the party frames.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.profiles.Party.move end,
                        set = function(_, val)
                            module.profiles.Party.move = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    left = {
                        name = "Frame Left",
                        desc = "Must be a number, this is the distance of the raid frame container from the left side of the screen.\n(Default " .. defaults.profiles.Party.savedPosition.leftOffset .. ")",
                        type = "range",
                        min = math.floor(GetScreenWidth()) * -1,
                        max = math.floor(GetScreenWidth()),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.profiles.Party.savedPosition.leftOffset end,
                        set = function(_, val)
                            module.profiles.Party.savedPosition.leftOffset = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    top = {
                        name = "Frame Top",
                        desc = "Must be a number, this is the distance of the raid frame container from the top of the screen.\n(Default " .. defaults.profiles.Party.savedPosition.topOffset .. ")",
                        type = "range",
                        min = math.floor(GetScreenHeight()) * -1,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.profiles.Party.savedPosition.topOffset end,
                        set = function(_, val)
                            module.profiles.Party.savedPosition.topOffset = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    bottom = {
                        name = "Frame Bottom",
                        desc = "Must be a number, this is the distance of the raid frame container from the bottom of the screen.\n(Default " .. defaults.profiles.Party.savedPosition.bottomOffset .. ")",
                        type = "range",
                        min = math.floor(GetScreenHeight()) * -1,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.profiles.Party.savedPosition.bottomOffset end,
                        set = function(_, val)
                            module.profiles.Party.savedPosition.bottomOffset = val
                            self:UpdateProfilePositions()
                        end,
                    }
                }
            },
            raidFrames = {
                name = "Raid Frames",
                type = "group",
                inline = true,
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Raid Frames",
                        desc = "Allows you to choose the position of the raid frames.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.profiles.Raid.move end,
                        set = function(_, val)
                            module.profiles.Raid.move = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    left = {
                        name = "Frame Left",
                        desc = "Must be a number, this is the distance of the raid frame container from the left side of the screen.\n(Default " .. defaults.profiles.Raid.savedPosition.leftOffset .. ")",
                        type = "range",
                        min = math.floor(GetScreenWidth()) * -1,
                        max = math.floor(GetScreenWidth()),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.profiles.Raid.savedPosition.leftOffset end,
                        set = function(_, val)
                            module.profiles.Raid.savedPosition.leftOffset = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    top = {
                        name = "Frame Top",
                        desc = "Must be a number, this is the distance of the raid frame container from the top of the screen.\n(Default " .. defaults.profiles.Raid.savedPosition.topOffset .. ")",
                        type = "range",
                        min = math.floor(GetScreenHeight()) * -1,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.profiles.Raid.savedPosition.topOffset end,
                        set = function(_, val)
                            module.profiles.Raid.savedPosition.topOffset = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    bottom = {
                        name = "Frame Bottom",
                        desc = "Must be a number, this is the distance of the raid frame container from the bottom of the screen.\n(Default " .. defaults.profiles.Raid.savedPosition.bottomOffset .. ")",
                        type = "range",
                        min = math.floor(GetScreenHeight()) * -1,
                        max = math.floor(GetScreenHeight()),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.profiles.Raid.savedPosition.bottomOffset end,
                        set = function(_, val)
                            module.profiles.Raid.savedPosition.bottomOffset = val
                            self:UpdateProfilePositions()
                        end,
                    }
                }
            }
        }
    }
end
