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
            chatModuleSettings = self:GetChatModuleSettingsPage(database, defaults.chatModule, 6),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database, 7),
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
            tooltips = {
                name = "Tooltips",
                type = "group",
                inline = true,
                order = 1.5,
                args = {
                    spellCostPercent = {
                        name = "Mana Cost Details",
                        desc = "Show a spell's mana cost as a percent of your maximum mana, e.g. \"105 Mana (8%)\", and healing or absorb per mana for heals and shields (English clients).",
                        type = "toggle",
                        width = 1.5,
                        get = function(_) return database.spellCostPercent end,
                        set = function(_, val) database.spellCostPercent = val end,
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
                    actionBarTogglesEnabled = {
                        name = "Action Bars",
                        desc = "Share the Action Bars 2-8 checkboxes from Blizzard's settings across characters. Saved on logout and applied on login.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.actionBarToggles.enabled end,
                        set = function(_, val)
                            database.actionBarToggles.enabled = val
                            self:SetupActionBarToggles()
                        end,
                    },
                    trackingModuleEnabled = {
                        name = "Minimap Tracking",
                        desc = "Share the minimap tracking menu checkboxes across characters. Saved on logout and applied on login; characters only receive entries they have.",
                        type = "toggle",
                        width = 1,
                        order = 1.5,
                        get = function(_) return database.trackingModule.enabled end,
                        set = function(_, val)
                            database.trackingModule.enabled = val
                            self:SetupTracking()
                        end,
                    },
                    chatModuleEnabled = {
                        name = "Chat",
                        desc = "Configure chat tabs and font size.",
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
                            if ScarletUI:InCombat() then return end
                            if val then
                                ScarletUI:RequestCVarModuleEnable()
                            else
                                ScarletUI:FinishCVarSetup(false)
                            end
                        end,
                    },
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
        desc = "Set CVar overrides that sync across characters. Disabling restores saved original values.",
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
                        name = "Browse available CVars below. Clear a value or remove a CVar to restore its saved original. Default applies the WoW default. Disabling restores originals and keeps your overrides for later.\n\nYou can also add custom CVars by name using the field below.",
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
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
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
                            if val == "" or not module.enabled or ScarletUI:InCombat() then return end

                            if GetCVar(val) == nil then
                                ScarletUI:Print("|cffff4444" .. val .. "|r is not a valid CVar.")
                                return
                            end
                            ScarletUI:SnapshotCVar(val)

                            -- Un-hide if previously hidden
                            if module.hiddenCVars[val] then
                                module.hiddenCVars[val] = nil
                                module.overrides[val] = tostring(GetCVar(val))
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

                            table.insert(ScarletUI.knownCVars, val)
                            table.sort(ScarletUI.knownCVars, function(a, b)
                                return string.lower(a) < string.lower(b)
                            end)

                            -- Persist custom names even when their current value is the default.
                            module.overrides[val] = tostring(GetCVar(val))
                            ScarletUI:Print("Added CVar: |cff00ff00" .. val .. "|r")

                            AceConfigRegistry:NotifyChange("ScarletUI")
                        end,
                    },
                }
            },
            search = {
                name = "CVars",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
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
        local hasOverride = module.overrides[cvarName] ~= nil and module.overrides[cvarName] ~= false

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
                return isValid and tostring(GetCVar(cvarName)) or ""
            end,
            set = function(_, val)
                if not module.enabled or ScarletUI:InCombat() then return end
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
            desc = "Apply the WoW default; keep the original value available for restoration",
            type = "execute",
            width = 0.5,
            order = orderCounter * 5 - 2,
            func = function()
                ScarletUI:SetCVarDefault(cvarName)
                AceConfigRegistry:NotifyChange("ScarletUI")
            end,
            disabled = function() return not isValid end,
            hidden = function() return ShouldOptionBeHidden(cvarName) end,
        }

        -- Remove button
        local removeKey = "remove" .. orderCounter
        options.args.search.args[removeKey] = {
            name = "Remove",
            desc = "Restore the saved original and remove this CVar from the list (re-add via the custom CVar field)",
            type = "execute",
            width = 0.5,
            order = orderCounter * 5 - 1,
            func = function()
                if ScarletUI:InCombat() then return end
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
