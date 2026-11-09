local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")

-- Each feature's on/off switch lives on the page for that feature; there is no
-- central list of modules.
function ScarletUI:Options()
    local database = self.db.global;
    local defaults = self.db.defaults.global;

    return {
        name = "Scarlet UI",
        handler = self,
        type = "group",
        childGroups = "tree",
        args = {
            generalSettings = self:GetGeneralSettingsPage(database, 1),
            editModeSettings = self:GetEditModeSettingsPage(2),
            actionBarTogglesSettings = self:GetActionBarTogglesSettingsPage(database, 3),
            bagModuleSettings = self:GetBagSettingsPage(database, defaults, 4),
            chatModuleSettings = self:GetChatModuleSettingsPage(database, defaults.chatModule, 5),
            -- Nameplates only load on Era, TBC, and Mists.
            nameplatesModuleSettings = self.GetNameplatesModuleSettingsPage and self:GetNameplatesModuleSettingsPage(database, defaults.nameplatesModule, 6),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database, 7),
        }
    }
end

function ScarletUI:GetGeneralSettingsPage(database, order)
    return {
        name = "General",
        desc = "Interface tweaks, item levels, tracking, and shortcuts.",
        type = "group",
        order = order,
        args = {
            interface = {
                name = "Interface",
                type = "group",
                inline = true,
                order = 0,
                args = {
                    tidyIcons = {
                        name = "Bigger Icons",
                        desc = "Make icons bigger to fill their actionbar slots.",
                        type = "toggle",
                        hidden = function() return self.lightWeightMode end,
                        width = 1.5,
                        order = 0,
                        get = function(_) return database.tidyIconsEnabled end,
                        set = function(_, val)
                            database.tidyIconsEnabled = val
                            self:SetupTidyIcons()
                        end,
                    },
                    hideMicroMenuArt = {
                        name = "Hide Micro Menu Background",
                        desc = "Hide the frame and background art behind the micro menu buttons.",
                        type = "toggle",
                        hidden = function() return not (MicroMenu and MicroMenu.BackgroundArt) end,
                        width = 1.5,
                        order = 1,
                        get = function(_) return database.hideMicroMenuArt end,
                        set = function(_, val)
                            database.hideMicroMenuArt = val
                            self:SetupMicroMenuArt()
                        end,
                    },
                    fiveSecondRule = {
                        name = "Five Second Rule",
                        desc = "After you spend mana, a line crosses your player frame mana bar over the 5 seconds until spirit-based mana regeneration resumes.",
                        type = "toggle",
                        hidden = function() return not self.fiveSecondRuleFrame end,
                        width = 1.5,
                        order = 2,
                        get = function(_) return database.fiveSecondRule end,
                        set = function(_, val) database.fiveSecondRule = val end,
                    },
                    spellCostPercent = {
                        name = "Mana Cost in Tooltips",
                        desc = "Show a spell's mana cost as a percent of your maximum mana, e.g. \"105 Mana (8%)\", and healing or absorb per mana for heals and shields (English clients).",
                        type = "toggle",
                        width = 1.5,
                        order = 3,
                        get = function(_) return database.spellCostPercent end,
                        set = function(_, val) database.spellCostPercent = val end,
                    },
                    zoneLevels = {
                        name = "Zone Levels on World Map",
                        desc = "Show a zone's level range, colored by difficulty, when hovering it on the world map, as Retail does.",
                        type = "toggle",
                        hidden = function() return not self.zoneLevelsHooked end,
                        width = 1.5,
                        order = 4,
                        get = function(_) return database.zoneLevels end,
                        set = function(_, val) database.zoneLevels = val end,
                    },
                    expandCharacterInfo = {
                        name = "Auto Expand Character Info",
                        desc = "Automatically opens the side panel in the character window showing your stats, titles, and equipment manager.",
                        type = "toggle",
                        hidden = function() return self.lightWeightMode or self:GetWoWVersion() ~= "CATA" end,
                        width = 1.5,
                        order = 5,
                        get = function(_) return database.expandCharacterInfo end,
                        set = function(_, val)
                            database.expandCharacterInfo = val
                            self:SetupExpandCharacterInfo()
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
                        name = "Custom Color",
                        desc = "Use one color for item level text instead of item quality colors.",
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
                        name = "Color",
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
            tracking = {
                name = "Minimap Tracking",
                type = "group",
                inline = true,
                order = 2,
                args = {
                    enabled = {
                        name = "Share Across Characters",
                        desc = "Share the minimap tracking menu checkboxes across characters. Saved on logout and applied on login; characters only receive entries they have.",
                        type = "toggle",
                        disabled = function() return self:InCombat() end,
                        width = 1,
                        order = 0,
                        get = function(_) return database.trackingModule.enabled end,
                        set = function(_, val)
                            database.trackingModule.enabled = val
                            self:SetupTracking()
                        end,
                    },
                    findMinerals = {
                        name = "Always Find Minerals",
                        desc = "Turn on Find Minerals at login and after you resurrect, on characters that know it.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.trackingModule.alwaysOn[2580] end,
                        set = function(_, val)
                            database.trackingModule.alwaysOn[2580] = val
                            self:ApplyAlwaysOnTracking()
                        end,
                    },
                    findHerbs = {
                        name = "Always Find Herbs",
                        desc = "Turn on Find Herbs at login and after you resurrect, on characters that know it.",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return database.trackingModule.alwaysOn[2383] end,
                        set = function(_, val)
                            database.trackingModule.alwaysOn[2383] = val
                            self:ApplyAlwaysOnTracking()
                        end,
                    },
                },
            },
            shortcuts = {
                name = "Shortcuts",
                type = "group",
                inline = true,
                order = 3,
                args = {
                    minimapIcon = {
                        name = "Minimap Icon",
                        desc = "Show the ScarletUI button on the minimap. Left-click opens settings; right-click opens Edit Mode.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return not database.minimapIcon.hide end,
                        set = function(_, val)
                            database.minimapIcon.hide = not val
                            self:SetupMinimapIcon()
                        end,
                    },
                    sui = {
                        name = "Escape Menu Button",
                        desc = "Show a button below the escape menu that opens these settings.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.gameMenuButtons.sui end,
                        set = function(_, val) database.gameMenuButtons.sui = val end,
                    },
                    cooldownManager = {
                        name = "Cooldown Manager Button",
                        desc = "Show a button below the escape menu that opens Blizzard's Advanced Cooldown Settings.",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        hidden = function() return not CooldownViewerSettings end,
                        get = function(_) return database.gameMenuButtons.cooldownManager end,
                        set = function(_, val) database.gameMenuButtons.cooldownManager = val end,
                    },
                },
            },
            reset = {
                name = "Reset",
                type = "group",
                disabled = function() return self:InCombat() end,
                inline = true,
                order = 4,
                args = {
                    defaultSettings = {
                        name = "Restore Defaults",
                        desc = "Restores all ScarletUI settings back to their defaults.",
                        type = "execute",
                        width = 1,
                        order = 0,
                        func = function()
                            StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                        end,
                    },
                    resetToBlizzard = {
                        name = "Reset to Blizzard UI",
                        desc = "Reset all settings to a configuration that mimics the default Blizzard UI. (this will /reload your game)",
                        type = "execute",
                        hidden = function() return self.editMode or self.lightWeightMode or select(2, self:GetWoWVersion()) > 40000 end,
                        width = 1,
                        order = 1,
                        func = function()
                            self:MergeTables(self.db, self.originalUIDefaults)
                            ReloadUI()
                        end,
                    },
                }
            },
        }
    }
end

function ScarletUI:GetActionBarTogglesSettingsPage(database, order)
    local module = database.actionBarToggles
    local bars = {
        description = {
            name = "Unchecked bars keep each character's own setting.\n",
            type = "description",
            width = "full",
            order = 0,
        },
    }
    -- Retail and Forever report bars 2-8; Era, TBC, and Mists report bars 2-5.
    for i = 1, GetActionBarToggles and select("#", GetActionBarToggles()) or 0 do
        bars["bar" .. i] = {
            name = "Action Bar " .. (i + 1),
            desc = "Share whether Action Bar " .. (i + 1) .. " is shown.",
            type = "toggle",
            width = 1,
            order = i,
            get = function(_) return not module.ignored[i] end,
            set = function(_, val) module.ignored[i] = not val or nil end,
        }
    end

    return {
        name = "Action Bars",
        desc = "Share which action bars are shown across characters.",
        type = "group",
        order = order,
        args = {
            enabled = {
                name = "Share Across Characters",
                desc = "Share the Action Bars 2-8 checkboxes from Blizzard's settings across characters. Saved on logout and applied on login.",
                type = "toggle",
                disabled = function() return self:InCombat() end,
                width = "full",
                order = 0,
                get = function(_) return module.enabled end,
                set = function(_, val)
                    module.enabled = val
                    self:SetupActionBarToggles()
                end,
            },
            bars = {
                name = "Shared Bars",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 1,
                args = bars,
            },
        },
    }
end

function ScarletUI:GetBagSettingsPage(database, defaults, order)
    -- Bag.lua (Era, TBC, and Mists) owns the page there; Retail and Forever only sort.
    local page = self.GetBagModuleSettingsPage and self:GetBagModuleSettingsPage(database, defaults.bagModule, order)
        or { name = "Bags", desc = "Bag sorting and highlights.", type = "group", order = order, args = {} }

    local function SortToggle(key, name, desc, toggleOrder)
        return {
            name = name,
            desc = desc,
            type = "toggle",
            width = 1.5,
            order = toggleOrder,
            hidden = function() return not self:IsBagSortSupported(key) end,
            get = function(_) return self:GetBagSort(key) end,
            set = function(_, val) self:SetBagSort(key, val) end,
        }
    end

    page.args.sortSettings = {
        name = "Sorting",
        type = "group",
        inline = true,
        order = 10,
        args = {
            sortBagsRightToLeft = SortToggle("sortBagsRightToLeft", "Sort Bags Right to Left",
                "Clean Up fills your bags starting from the rightmost bag instead of the backpack.", 0),
            insertItemsLeftToRight = SortToggle("insertItemsLeftToRight", "Insert Items Left to Right",
                "New items go into your leftmost bag first instead of the backpack.", 1),
            enabled = {
                name = "Share Across Characters",
                desc = "Share the sorting settings above across characters. Saved on logout and applied on login.",
                type = "toggle",
                disabled = function() return self:InCombat() end,
                width = "full",
                order = 2,
                get = function(_) return database.bagSortModule.enabled end,
                set = function(_, val)
                    database.bagSortModule.enabled = val
                    self:SetupBagSort()
                end,
            },
        },
    }
    page.args.highlightSettings = {
        name = "Highlights",
        type = "group",
        inline = true,
        order = 11,
        args = {
            highlightCheapestItem = {
                name = "Highlight Cheapest Item",
                desc = "Outline the item or stack in your bags with the lowest total vendor value, so you know what to sell or destroy when your bags are full. Unsellable items, consumables, quest items, profession tools, and items in equipment sets are ignored.",
                type = "toggle",
                width = 1.5,
                order = 0,
                get = function(_) return database.highlightCheapestItem end,
                set = function(_, val)
                    database.highlightCheapestItem = val
                    self:UpdateCheapestItem()
                end,
            },
        },
    }
    return page
end

function ScarletUI:GetChatModuleSettingsPage(database, defaults, order)
    local module = database.chatModule;

    local function Tab(key, name, tabOrder, hidden)
        return {
            name = name .. " Tab",
            desc = "Create a chat tab for " .. name:lower() .. ".",
            type = "toggle",
            hidden = hidden,
            width = 1,
            order = tabOrder,
            get = function(_) return module.tabs[key] end,
            set = function(_, val)
                module.tabs[key] = val
                self:SetupChatTabs()
            end,
        }
    end

    return {
        name = "Chat",
        desc = "Chat font size and tabs.",
        type = "group",
        order = order,
        args = {
            enabled = {
                name = "Manage Chat",
                desc = "Let ScarletUI set the chat font size and create chat tabs. Turning this off reloads the UI.",
                type = "toggle",
                disabled = function() return self:InCombat() end,
                width = "full",
                order = 0,
                get = function(_) return module.enabled end,
                set = function(_, val)
                    module.enabled = val
                    if not val then
                        self:ShowReloadDialog()
                    else
                        self:SetupChat()
                    end
                end,
            },
            fontSize = {
                name = "Font Size",
                desc = "Font size for chat windows.\n(Default " .. defaults.fontSize .. ")",
                type = "range",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                min = 6,
                max = 20,
                step = 1,
                width = 1,
                order = 1,
                get = function(_) return module.fontSize end,
                set = function(_, val)
                    module.fontSize = val
                    self:SetupChat()
                end,
            },
            tabs = {
                name = "Tabs",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled, true) end,
                inline = true,
                order = 2,
                args = {
                    loot = Tab("loot", "Loot", 0),
                    trade = Tab("trade", "Trade", 1),
                    lfg = Tab("lfg", "LFG", 2, function() return self.lightWeightMode end),
                    description = {
                        name = "\nIf a tab is not created, right click any chat tab, click Settings, then click Chat Defaults.",
                        type = "description",
                        width = "full",
                        order = 3,
                    },
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
            enabled = {
                name = "Enable CVar Overrides",
                desc = "Apply the overrides below on every character (meant for advanced users). Turning this off restores your original values and keeps the overrides for later.",
                type = "toggle",
                disabled = function() return ScarletUI:InCombat() end,
                width = "full",
                order = 0,
                get = function(_) return module.enabled end,
                set = function(_, val)
                    if ScarletUI:InCombat() then return end
                    if val then
                        ScarletUI:RequestCVarModuleEnable()
                    else
                        ScarletUI:FinishCVarSetup(false)
                    end
                end,
            },
            description = {
                name = "Clear a value or press Remove to restore a CVar's saved original. Default applies the WoW default.\n",
                type = "description",
                width = "full",
                order = 0.5,
            },
            addCustom = {
                name = "Add a CVar by Name",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                type = "group",
                inline = true,
                order = 1,
                args = {
                    link = {
                        name = "CVar Reference",
                        desc = "Copy this address for a list of console variables.",
                        type = "input",
                        order = 1,
                        width = 1.5,
                        get = function() return "https://warcraft.wiki.gg/wiki/Console_variables" end,
                    },
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
                name = "Search",
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
