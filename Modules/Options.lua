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
            fishingSettings = self:GetFishingSettingsPage(database, 6),
            -- Nameplates only load on Era, TBC, and Mists.
            nameplatesModuleSettings = self.GetNameplatesModuleSettingsPage and self:GetNameplatesModuleSettingsPage(database, defaults.nameplatesModule, 7),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database, 8),
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
                order = 1,
                args = {
                    tidyIcons = {
                        name = "Bigger Icons",
                        desc = "Enlarge action bar icons so they fill their slots.",
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
                        desc = "After you spend mana, a marker crosses your mana bar for the 5 seconds until spirit mana regeneration resumes.",
                        type = "toggle",
                        hidden = function() return not self.fiveSecondRuleFrame end,
                        width = 1.5,
                        order = 2,
                        get = function(_) return database.fiveSecondRule end,
                        set = function(_, val) database.fiveSecondRule = val end,
                    },
                    spellCostPercent = {
                        name = "Mana Cost in Tooltips",
                        desc = "Show a spell's mana cost as a percent of your maximum mana, such as \"105 Mana (8%)\". Heals and shields also show healing or absorb per mana (English clients only).",
                        type = "toggle",
                        width = 1.5,
                        order = 3,
                        get = function(_) return database.spellCostPercent end,
                        set = function(_, val) database.spellCostPercent = val end,
                    },
                    zoneLevels = {
                        name = "Zone Levels on World Map",
                        desc = "Show a zone's level range, colored by difficulty, when you hover over it on the world map.",
                        type = "toggle",
                        hidden = function() return not self.zoneLevelsHooked end,
                        width = 1.5,
                        order = 4,
                        get = function(_) return database.zoneLevels end,
                        set = function(_, val) database.zoneLevels = val end,
                    },
                    collapseInactiveBuffs = {
                        name = "Collapse Inactive Buffs",
                        desc = "Close the gaps the Cooldown Manager leaves for inactive tracked buffs by sliding the active ones toward one end.\n\nOnly has an effect when Hide When Inactive is checked for Tracked Buffs in Edit Mode.",
                        type = "select",
                        hidden = function() return not self:IsBuffCollapseSupported() end,
                        width = 1.5,
                        order = 6,
                        values = { OFF = "Off", START = "Left or Top", END = "Right or Bottom" },
                        sorting = { "OFF", "START", "END" },
                        get = function(_) return database.collapseInactiveBuffs end,
                        set = function(_, val)
                            database.collapseInactiveBuffs = val
                            self:SetupBuffCollapse()
                        end,
                    },
                    xpFood = {
                        name = "XP Food Reminder",
                        desc = "Show an icon while you have no Well Fed XP Boost (5% more experience from kills) and your bags hold food that gives it. Right-click the icon to eat; left-click it to choose which food it shows. Hidden in combat and at max level; drag the icon to move it, Ctrl-click it to reset its position.",
                        type = "toggle",
                        hidden = function() return not self.xpFoodFrame end,
                        width = 1.5,
                        order = 7,
                        get = function(_) return database.xpFoodModule.enabled end,
                        set = function(_, val)
                            database.xpFoodModule.enabled = val
                            self:UpdateXPFood()
                        end,
                    },
                    expandCharacterInfo = {
                        name = "Auto Expand Character Info",
                        desc = "Open the character window with its side panel (stats, titles, and equipment manager) already expanded.",
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
                order = 2,
                args = {
                    itemLevelCharacter = {
                        name = "Character Window",
                        desc = "Show item levels on the equipment in your character window.",
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
                        desc = "Show item levels on the equipment of players you inspect.",
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
                        desc = "Show item levels on equipment in your bags and bank.",
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
                        desc = "The color used when Custom Color is on.",
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
                order = 0,
                args = {
                    enabled = {
                        name = "Share Across Characters",
                        desc = "Share what is checked in the minimap tracking menu across characters. Saved on logout and applied on login; a character only receives the entries it has.",
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
                    switchInterval = {
                        name = "Switch Interval",
                        desc = "Seconds between switching Find Minerals and Find Herbs when both are on, on clients that track only one at a time. Switching pauses in combat, in cities, inns, and instances, and while casting, looting, or hovering the minimap. Turn one of the two off to stop switching.",
                        type = "range",
                        min = 2,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return database.trackingModule.switchInterval end,
                        set = function(_, val) database.trackingModule.switchInterval = val end,
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
                        desc = "Show the Scarlet UI button on the minimap. Left-click opens these settings; right-click opens Edit Mode.",
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
                        name = "Esc Menu: Scarlet UI",
                        desc = "Add a Scarlet UI button below the escape menu that opens these settings.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.gameMenuButtons.sui end,
                        set = function(_, val) database.gameMenuButtons.sui = val end,
                    },
                    cooldownManager = {
                        name = "Esc Menu: Cooldown Manager",
                        desc = "Add a Cooldown Manager button below the escape menu that opens Blizzard's Advanced Cooldown Settings.",
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
                        desc = "Restore every Scarlet UI setting to its default.",
                        type = "execute",
                        width = 1,
                        order = 0,
                        func = function()
                            StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                        end,
                    },
                    resetToBlizzard = {
                        name = "Reset to Blizzard UI",
                        desc = "Change every setting to match the default Blizzard UI. This reloads the UI.",
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

function ScarletUI:GetFishingSettingsPage(database, order)
    return {
        name = "Fishing",
        desc = "One key to cast, hook the bobber, and apply lures while a fishing pole is equipped.",
        type = "group",
        hidden = function() return not self.fishingFrame end,
        disabled = function() return self:InCombat() end,
        order = order,
        args = {
            enabled = {
                name = "Fishing Mode",
                desc = "While a fishing pole is equipped, the fishing key casts Fishing, then hooks the bobber during the cast. The key keeps its normal action in combat and while you move.\n\nA small bar shows while the mode is on. Click the lure on it to pick which one is applied; drag the Fishing icon to move it, Ctrl-click it to reset its position.",
                type = "toggle",
                width = 1,
                order = 0,
                get = function(_) return database.fishingModule.enabled end,
                set = function(_, val)
                    database.fishingModule.enabled = val
                    self:UpdateFishing()
                end,
            },
            key = {
                name = "Fishing Key",
                desc = "The key that fishes while a fishing pole is equipped. It keeps its normal action the rest of the time.",
                type = "keybinding",
                width = 1,
                order = 1,
                get = function(_) return database.fishingModule.key end,
                set = function(_, val)
                    database.fishingModule.key = val
                    self:UpdateFishing()
                end,
            },
            autoLure = {
                name = "Auto Apply Lures",
                desc = "When the pole has no lure, the fishing key first applies one from your bags: the lure picked on the fishing bar, or the best one.",
                type = "toggle",
                width = 1,
                order = 2,
                get = function(_) return database.fishingModule.autoLure end,
                set = function(_, val)
                    database.fishingModule.autoLure = val
                    self:UpdateFishing()
                end,
            },
        },
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
            desc = "Share whether Action Bar " .. (i + 1) .. " is shown. Unchecked, each character keeps its own setting.",
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
                desc = "Share which extra action bars are shown (the Action Bar checkboxes in Blizzard's settings) across characters. Saved on logout and applied on login.",
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
                "Clean Up packs items into your backpack (the rightmost bag) first. Unchecked, it starts from your leftmost bag.", 0),
            insertItemsLeftToRight = SortToggle("insertItemsLeftToRight", "Insert Items Left to Right",
                "New items go into your leftmost bag first. Unchecked, they go into your backpack (the rightmost bag) first.", 1),
        },
    }
    -- Module switches lead each page; this one follows Bag.lua's Custom Bag Frames.
    page.args.shareSorting = {
        name = "Share Sorting Across Characters",
        desc = "Share the two Sorting settings below across characters. Saved on logout and applied on login.",
        type = "toggle",
        disabled = function() return self:InCombat() end,
        width = "full",
        order = 0.5,
        get = function(_) return database.bagSortModule.enabled end,
        set = function(_, val)
            database.bagSortModule.enabled = val
            self:SetupBagSort()
        end,
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

    local function Tab(key, name, what, tabOrder, hidden)
        return {
            name = name .. " Tab",
            desc = "Create a chat tab for " .. what .. ".",
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
                desc = "Let Scarlet UI set the chat font size and create chat tabs. Turning this off reloads the UI.",
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
                    loot = Tab("loot", "Loot", "loot messages", 0),
                    trade = Tab("trade", "Trade", "the Trade and Services channels", 1),
                    lfg = Tab("lfg", "LFG", "the Looking For Group channel", 2, function() return self.lightWeightMode end),
                    description = {
                        name = "\nIf a tab does not appear, right-click any chat tab, choose Settings, then click Chat Defaults.",
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
        desc = "Override console variables (CVars) on every character. Turning overrides off restores your original values.",
        type = "group",
        order = order,
        args = {
            enabled = {
                name = "Enable CVar Overrides",
                desc = "Apply the overrides below on every character. Meant for advanced users. Turning this off restores your original values and keeps the overrides for later.",
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
                name = "Clear a value or press Remove to restore a CVar's original value. Default sets it to WoW's default.\n",
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
                        desc = "Copy this address to look up console variables.",
                        type = "input",
                        order = 1,
                        width = 1.5,
                        get = function() return "https://warcraft.wiki.gg/wiki/Console_variables" end,
                    },
                    addField = {
                        order = 0,
                        name = "",
                        desc = "Type a CVar name and press Enter to add it.",
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
            desc = isValid and ("Current: " .. tostring(GetCVar(cvarName))) or "This CVar does not exist on this client.",
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
            desc = "Set this CVar to WoW's default. Your original value stays saved so it can be restored.",
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
            desc = "Restore your original value and remove this CVar from the list. Add it again by name to bring it back.",
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
