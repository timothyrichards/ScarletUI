local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()

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
                name = "Toggle Movers",
                desc = "Enables mover frames so you can drag various UI elements to a new position.",
                type = "execute",
                disabled = function() return self:InCombat() end,
                hidden = function() return self.retail end,
                order = 0,
                width = 1,
                func = function()
                    self:ToggleMovers()
                end,
            },
            restoreFramePositions = {
                name = "Restore Positions",
                desc = "Restores frame positions back to default positions.",
                type = "execute",
                disabled = function() return self:InCombat() end,
                hidden = function() return self.retail end,
                order = 1,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_POSITIONS_DIALOG')
                end,
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
            moduleSettings = self:GetModuleSettingsPage(database, 3),
            actionbarsModuleSettings = self:GetActionbarsModuleSettingsPage(database, defaults.actionbarsModule, 4),
            --bagModuleSettings = self:GetBagModuleSettingsPage(database, defaults.bagModule, 5),
            chatModuleSettings = self:GetChatModuleSettingsPage(database, defaults.chatModule, 6),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database, 7),
            nameplatesModuleSettings = self:GetNameplatesModuleSettingsPage(database, defaults.nameplatesModule, 8),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(database, defaults.raidFramesModule, 9),
            unitFramesModuleSettings = self:GetUnitFramesModuleSettingsPage(database, defaults.unitFramesModule, 10),
        },
    }
end

function ScarletUI:GetModuleSettingsPage(database, order)
    return {
        name = "General Settings",
        desc = "Miscellaneous ScarletUI settings.",
        type = "group",
        order = order,
        args = {
            general = {
                name = "General",
                type = "group",
                disabled = function() return self:InCombat() end,
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
                            if val then
                                self:SetupExpandCharacterInfo()
                            else
                                self:ShowReloadDialog()
                            end
                        end,
                    },
                }
            },
            itemLevel = {
                name = "Item Level",
                type = "group",
                disabled = function() return self:InCombat() end,
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
                            if val then
                                self:SetupItemLevels()
                            else
                                self:ShowReloadDialog()
                            end
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
                            if val then
                                self:SetupItemLevels()
                            else
                                self:ShowReloadDialog()
                            end
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
                            if val then
                                self:SetupItemLevels()
                            else
                                self:ShowReloadDialog()
                            end
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
                            database.CVarModule.enabled = val
                            if not val then
                                ScarletUI:RestoreCVarsDefaults()
                            else
                                ScarletUI:SetupCVars()
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
                                ScarletUI:SetupNameplates()
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
                    },
                },
            },
        }
    }
end

function ScarletUI:GenerateBarConfig(name, _order)
    local module = self.db.global.actionbarsModule;
    local defaults = self.db.defaults.global.actionbarsModule;

    if defaults[name] == nil then
        self:Print("Database defaults are missing for " .. name)
        return
    end

    return {
        name = (name:gsub("(%a)(%u)", "%1 %2"):gsub("^%l", string.upper)),
        type = "group",
        disabled = function() return self:SettingDisabled(module.enabled) end,
        order = _order,
        args = {
            moveFrame = {
                name = "Move Frame",
                desc = "Allows you to choose the X and Y position of the frame.",
                type = "toggle",
                width = 1,
                order = 0,
                get = function(_) return module[name].move end,
                set = function(_, val)
                    module[name].move = val
                    self:SetupActionBars()
                end,
            },
            hide = {
                name = "Hide Frame",
                desc = "Allows you to hide the frame.",
                type = "toggle",
                width = 1,
                order = 1,
                get = function(_) return module[name].hide end,
                set = function(_, val)
                    module[name].hide = val
                    self:SetupActionBars()

                    if not val then
                        self:ShowReloadDialog()
                    end
                end,
            },
            spacer1 = {
                name = "",
                type = "description",
                width = "full",
                order = 2,
            },
            frameAnchor = {
                name = "Frame Anchor",
                desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults[name].frameAnchor] .. ")",
                type = "select",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                width = 1,
                order = 3,
                values = function() return self.frameAnchors end,
                get = function(_) return module[name].frameAnchor end,
                set = function(_, val)
                    module[name].frameAnchor = val
                    self:SetupActionBars()
                end,
            },
            screenAnchor = {
                name = "Screen Anchor",
                desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults[name].screenAnchor] .. ")",
                type = "select",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                width = 1,
                order = 4,
                values = function() return self.frameAnchors end,
                get = function(_) return module[name].screenAnchor end,
                set = function(_, val)
                    module[name].screenAnchor = val
                    self:SetupActionBars()
                end,
            },
            spacer2 = {
                name = "",
                type = "description",
                width = "full",
                order = 5,
            },
            x = {
                name = "Frame X",
                desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults[name].x .. ")",
                type = "range",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                min = math.floor(screenWidth) * -1,
                max = math.floor(screenWidth),
                step = 1,
                width = 1,
                order = 6,
                get = function(_) return module[name].x end,
                set = function(_, val)
                    module[name].x = val
                    self:SetupActionBars()
                end,
            },
            y = {
                name = "Frame Y",
                desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults[name].y .. ")",
                type = "range",
                disabled = function() return self:SettingDisabled(module[name].move) end,
                min = math.floor(screenHeight) * -1,
                max = math.floor(screenHeight),
                step = 1,
                width = 1,
                order = 7,
                get = function(_) return module[name].y end,
                set = function(_, val)
                    module[name].y = val
                    self:SetupActionBars()
                end,
            }
        }
    }
end

function ScarletUI:GetActionBarConfigs()
    local module = ScarletUI.db.global.actionbarsModule;
    local bars = {
        "mainMenuBar",
        "vehicleLeaveButton",
        "multiBarBottomLeft",
        "multiBarBottomRight",
        "multiBarLeft",
        "multiBarRight",
        "stanceBar",
        "petBar",
        "multiCastBar",
        "experienceBar",
        "reputationBar",
        "microBar",
        "bagBar",
    }
    local configs = {}

    for i, barName in ipairs(bars) do
        configs[barName] = self:GenerateBarConfig(barName, i + 1)

        if barName == "bagBar" then
            configs[barName].args.microBag = {
                name = "Micro Bag",
                desc = "Hide all non backpack bag icons.",
                type = "toggle",
                width = 1,
                order = 1.5,
                get = function(_) return module.microBag end,
                set = function(_, val)
                    module.microBag = val
                    if val then
                        self:SetupActionBars()
                    else
                        self:ShowReloadDialog()
                    end
                end,
            }
        end

        if barName == "multiCastBar" then
            local version = self:GetWoWVersion();
            configs[barName].hidden = function() return version ~= "WRATH" and version ~= "CATA" end
        end
    end

    return configs
end

function ScarletUI:GetActionbarsModuleSettingsPage(database, defaults, order)
    local module = database.actionbarsModule;

    local options = {
        name = "Actionbars",
        desc = "Actionbars Module settings.",
        type = "group",
        childGroups = "tab",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
        hidden = function() return self.retail end,
        args = {
            generalSettings = {
                name = "General Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 1,
                args = {
                    showPagingNumbers = {
                        name = "Show Paging Numbers",
                        desc = "Show the actionbar paging numbers and buttons.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return module.showPagingNumbers end,
                        set = function(_, val)
                            module.showPagingNumbers = val
                            self:SetupActionBars()
                        end,
                    },
                    showGryphons = {
                        name = "Show Gryphons",
                        desc = "Show the gryphon graphics on the sides of your main bar.",
                        type = "toggle",
                        width = 1,
                        order = 2,
                        get = function(_) return module.showGryphons end,
                        set = function(_, val)
                            module.showGryphons = val
                            self:SetupActionBars()
                        end,
                    },
                    tidyIcons = {
                        name = "Bigger Icons",
                        desc = "Make icons bigger to fill their actionbar slots.",
                        type = "toggle",
                        disabled = function() return self.lightWeightMode end,
                        width = 1,
                        order = 3,
                        get = function(_) return database.tidyIconsEnabled end,
                        set = function(_, val)
                            database.tidyIconsEnabled = val
                            self:SetupTidyIcons()
                        end,
                    },
                }
            },
        }
    }

    for k, v in pairs(self:GetActionBarConfigs()) do
        options.args[k] = v
    end

    return options
end

function ScarletUI:GetBagModuleSettingsPage(database, defaults, order)
    local module = database.bagModule;

    return {
        name = "Bag",
        desc = "Bag Module settings.",
        type = "group",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
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
        disabled = function() return not module.enabled end,
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
                        max = math.floor(screenHeight),
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
                        max = math.floor(screenWidth),
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
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 1,
                args = {
                    loot = {
                        name = "Loot Tab",
                        desc = "Create tab for loot.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.tabs.loot end,
                        set = function(_, val)
                            module.tabs.loot = val
                            self:SetupChat()
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
                            self:SetupChat()
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
                            self:SetupChat()
                        end,
                    },
                }
            },
            chatFrame = {
                name = "Chat Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) or self.lightWeightMode end,
                hidden = function(_) return self.retail end,
                order = 2,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.chatFrame.move end,
                        set = function(_, val)
                            module.chatFrame.move = val
                            self:SetupChat()
                        end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 1,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.chatFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return self:SettingDisabled(module.chatFrame.move) end,
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.chatFrame.frameAnchor end,
                        set = function(_, val)
                            module.chatFrame.frameAnchor = val
                            self:SetupChat()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.chatFrame.screenAnchor] .. ")",
                        type = "select",
                        disabled = function() return self:SettingDisabled(module.chatFrame.move) end,
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.chatFrame.screenAnchor end,
                        set = function(_, val)
                            module.chatFrame.screenAnchor = val
                            self:SetupChat()
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 4,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.chatFrame.x .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.chatFrame.move) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.chatFrame.x end,
                        set = function(_, val)
                            module.chatFrame.x = val
                            self:SetupChat()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.chatFrame.y .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.chatFrame.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.chatFrame.y end,
                        set = function(_, val)
                            module.chatFrame.y = val
                            self:SetupChat()
                        end,
                    }
                }
            },
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
        disabled = function() return not module.enabled end,
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

-- TODO: add priority debuff settings (specific spell names, or types like stun, slow, etc)
--local function GetSpellDropdown()
--    local spells = {}
--    for k, v in pairs(ScarletUI.db.global.nameplatesModule.debuffTracker.prioritySpells) do
--        spells[k] = "\124T" .. icon .. ":16\124t " .. v
--    end
--    return spells
--end

function ScarletUI:GetNameplatesModuleSettingsPage(database, defaults, order)
    local module = database.nameplatesModule;
    local characterDatabase = self.db.char;

    return {
        name = "Nameplates",
        desc = "Nameplates Module settings.",
        type = "group",
        childGroups = "tab",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
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
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    track = {
                        name = "Track Debuffs",
                        desc = "Show debuffs and their durations on the nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.debuffTracker.track end,
                        set = function(_, val) module.debuffTracker.track = val end,
                    },
                    iconSize = {
                        name = "Icon Size",
                        desc = "Must be a number, this is the size of the debuff icons.\n(Default " .. defaults.debuffTracker.iconSize .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.debuffTracker.track) end,
                        min = 1,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.debuffTracker.iconSize end,
                        set = function(_, val) module.debuffTracker.iconSize = val end,
                    },
                    spacing = {
                        name = "Icon Spacing",
                        desc = "Must be a number, this is the space between the debuff icons.\n(Default " .. defaults.debuffTracker.spacing .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.debuffTracker.track) end,
                        min = 0,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.debuffTracker.spacing end,
                        set = function(_, val) module.debuffTracker.spacing = val end,
                    },
                    verticalOffset = {
                        name = "Vertical Offset",
                        desc = "Must be a number, this is the vertical offset of the debuff row from the nameplate.\n(Default " .. defaults.debuffTracker.verticalOffset .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.debuffTracker.track) end,
                        min = -100,
                        max = 100,
                        step = 1,
                        width = 1,
                        order = 4,
                        get = function(_) return module.debuffTracker.verticalOffset end,
                        set = function(_, val) module.debuffTracker.verticalOffset = val end,
                    },
                    priorityDebuffs = {
                        name = "Priority Debuffs",
                        type = "input",
                        disabled = function() return ScarletUI:SettingDisabled(module.debuffTracker.track) end,
                        desc = "Add a comma seperated list of debuff spell names you wish to always track even if they're applied by another player, for example: Sunder Armor,Expose Armor,Hammer of Justice\n(This setting is saved per character)",
                        multiline = 5,
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
                disabled = function() return self:InCombat() end,
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
                        disabled = function() return self:SettingDisabled(module.targetIndicator.show) end,
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
                        disabled = function() return self:SettingDisabled(module.targetIndicator.show) end,
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
                        disabled = function() return self:SettingDisabled(module.targetIndicator.show) end,
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
            healthBarText = {
                name = "Health Bar Text",
                type = "group",
                disabled = function() return self:InCombat() end,
                order = 3,
                args = {
                    show = {
                        name = "Show",
                        desc = "Add health text to health bar on nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 1,
                        get = function(_) return module.healthBarText.show end,
                        set = function(_, val)
                            module.healthBarText.show = val
                        end,
                    },
                    fontSize = {
                        name = "Font Size",
                        desc = "Desired font size for health bar text.\n(Default " .. defaults.healthBarText.fontSize .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.healthBarText.show) end,
                        min = 6,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 4,
                        get = function(_) return module.healthBarText.fontSize end,
                        set = function(_, val)
                            module.healthBarText.fontSize = val
                        end,
                    }
                },
            },
            castBarText = {
                name = "Cast Bar Text",
                type = "group",
                disabled = function() return self:InCombat() end,
                order = 4,
                args = {
                    show = {
                        name = "Show",
                        desc = "Add cast text to cast bar on nameplates.",
                        type = "toggle",
                        width = "full",
                        order = 1,
                        get = function(_) return module.castBarText.show end,
                        set = function(_, val)
                            module.castBarText.show = val
                        end,
                    },
                    fontSize = {
                        name = "Font Size",
                        desc = "Desired font size for cast bar text.\n(Default " .. defaults.castBarText.fontSize .. ")",
                        type = "range",
                        disabled = function() return self:SettingDisabled(module.castBarText.show) end,
                        min = 6,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 4,
                        get = function(_) return module.castBarText.fontSize end,
                        set = function(_, val)
                            module.castBarText.fontSize = val
                        end,
                    }
                },
            },
            threatColors = {
                name = "Threat Colors",
                type = "group",
                disabled = function() return self:InCombat() or not module.threatColored end,
                order = 5,
                args = {
                    description1 = {
                        name = "|cffffd100These are the colors you see as a |cffff0900DPS|r or |cff15fb00Healer|r.|r",
                        type = "description",
                        width = "full",
                        fontSize = "medium",
                        order = 0,
                    },
                    otherNoThreat = {
                        name = "No Threat",
                        type = "color",
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 1,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 2,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 3,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 4,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 5,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.threatColored) end,
                        desc = "Add a comma seperated list of player names you wish to manually designate as tanks, for example: Tank1,Tank2,Tank3\n\nPlayers with the role of tank (in versions of WoW that have roles) and players marked Main Tank or Main Assist in raids, will automatically be designated as tanks by the nameplate colors.",
                        multiline = 5,
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
                disabled = function() return self:InCombat() or not module.specialUnitsColored end,
                order = 8,
                args = {
                    specialUnitColor = {
                        name = "Special Unit Color",
                        type = "color",
                        disabled = function() return ScarletUI:SettingDisabled(module.specialUnitsColored) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.specialUnitsColored) end,
                        desc = "Add a comma seperated list of enemy unit names you wish to manually designate as special units, for example: Unit1,Unit2,Unit3",
                        multiline = 5,
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
        childGroups = "tab",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
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
                        desc = "Must be a number, this is the distance of the raid frame container from the left side of the screen.\n(Default " .. defaults.profiles.Party.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.profiles.Party.move) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.profiles.Party.x end,
                        set = function(_, val)
                            module.profiles.Party.x = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    top = {
                        name = "Frame Top",
                        desc = "Must be a number, this is the distance of the raid frame container from the top of the screen.\n(Default " .. defaults.profiles.Party.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.profiles.Party.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.profiles.Party.y end,
                        set = function(_, val)
                            module.profiles.Party.y = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    bottom = {
                        name = "Frame Bottom",
                        desc = "Must be a number, this is the distance of the raid frame container from the bottom of the screen.\n(Default " .. defaults.profiles.Party.height .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.profiles.Party.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.profiles.Party.height end,
                        set = function(_, val)
                            module.profiles.Party.height = val
                            self:UpdateProfilePositions()
                        end,
                    }
                }
            },
            raidFrames = {
                name = "Raid Frames",
                type = "group",
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
                        desc = "Must be a number, this is the distance of the raid frame container from the left side of the screen.\n(Default " .. defaults.profiles.Raid.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.profiles.Raid.move) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.profiles.Raid.x end,
                        set = function(_, val)
                            module.profiles.Raid.x = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    top = {
                        name = "Frame Top",
                        desc = "Must be a number, this is the distance of the raid frame container from the top of the screen.\n(Default " .. defaults.profiles.Raid.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.profiles.Raid.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.profiles.Raid.y end,
                        set = function(_, val)
                            module.profiles.Raid.y = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    bottom = {
                        name = "Frame Bottom",
                        desc = "Must be a number, this is the distance of the raid frame container from the bottom of the screen.\n(Default " .. defaults.profiles.Raid.height .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.profiles.Raid.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.profiles.Raid.height end,
                        set = function(_, val)
                            module.profiles.Raid.height = val
                            self:UpdateProfilePositions()
                        end,
                    }
                }
            },
        }
    }
end

function ScarletUI:GetUnitFramesModuleSettingsPage(database, defaults, order)
    local module = database.unitFramesModule;

    return {
        name = "Unit Frames",
        desc = "Unit Frames Module settings.",
        type = "group",
        childGroups = "tab",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
        hidden = function() return self.retail end,
        args = {
            playerFrame = {
                name = "Player Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.playerFrame.move end,
                        set = function(_, val)
                            module.playerFrame.move = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 1,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.playerFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(module.playerFrame.move) end,
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.playerFrame.frameAnchor end,
                        set = function(_, val)
                            module.playerFrame.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.playerFrame.screenAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(module.playerFrame.move) end,
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.playerFrame.screenAnchor end,
                        set = function(_, val)
                            module.playerFrame.screenAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 4,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.playerFrame.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.playerFrame.move) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.playerFrame.x end,
                        set = function(_, val)
                            module.playerFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.playerFrame.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.playerFrame.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.playerFrame.y end,
                        set = function(_, val)
                            module.playerFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    }
                }
            },
            targetFrame = {
                name = "Target Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 2,
                args = {
                    mirrorPlayerFrame = {
                        name = "Mirror Player Frame",
                        desc = "Mirrors the X and Y position of the player frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.targetFrame.mirrorPlayerFrame end,
                        set = function(_, val)
                            module.targetFrame.mirrorPlayerFrame = val
                            self:SetupUnitFrames()
                        end,
                    },
                    buffsOnTop = {
                        name = "Buffs On Top",
                        desc = "Force buffs to show on top of the target frame.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return module.targetFrame.buffsOnTop end,
                        set = function(_, val)
                            module.targetFrame.buffsOnTop = val
                            self:SetupUnitFrames()
                        end,
                    },
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        disabled = function()
                            return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame)
                        end,
                        width = "full",
                        order = 2,
                        get = function(_) return module.targetFrame.move end,
                        set = function(_, val)
                            module.targetFrame.move = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 3,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.targetFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function()
                            return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) or
                                    ScarletUI:SettingDisabled(module.targetFrame.move)
                        end,
                        width = 1,
                        order = 4,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.targetFrame.frameAnchor end,
                        set = function(_, val)
                            module.targetFrame.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.targetFrame.screenAnchor] .. ")",
                        type = "select",
                        disabled = function()
                            return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) or
                                ScarletUI:SettingDisabled(module.targetFrame.move)
                        end,
                        width = 1,
                        order = 5,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.targetFrame.screenAnchor end,
                        set = function(_, val)
                            module.targetFrame.screenAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 6,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.targetFrame.x .. ")",
                        type = "range",
                        disabled = function()
                            return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) or
                                    ScarletUI:SettingDisabled(module.targetFrame.move)
                        end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 7,
                        get = function(_) return module.targetFrame.x end,
                        set = function(_, val)
                            module.targetFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.targetFrame.y .. ")",
                        type = "range",
                        disabled = function()
                            return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) or
                                    ScarletUI:SettingDisabled(module.targetFrame.move)
                        end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 8,
                        get = function(_) return module.targetFrame.y end,
                        set = function(_, val)
                            module.targetFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    },
                }
            },
            focusFrame = {
                name = "Focus Frame",
                type = "group",
                hidden = function() return not FocusFrame end,
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = false,
                order = 3,
                args = {
                    buffsOnTop = {
                        name = "Buffs On Top",
                        desc = "Force buffs to show on top of the focus frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.focusFrame.buffsOnTop end,
                        set = function(_, val)
                            module.focusFrame.buffsOnTop = val
                            self:SetupUnitFrames()
                        end,
                    },
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = "full",
                        order = 1,
                        get = function(_) return module.focusFrame.move end,
                        set = function(_, val)
                            module.focusFrame.move = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 2,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.focusFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(module.focusFrame.move) end,
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.focusFrame.frameAnchor end,
                        set = function(_, val)
                            module.focusFrame.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.focusFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(module.focusFrame.move) end,
                        width = 1,
                        order = 4,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.focusFrame.screenAnchor end,
                        set = function(_, val)
                            module.focusFrame.screenAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 5,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.focusFrame.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.focusFrame.move) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.focusFrame.x end,
                        set = function(_, val)
                            module.focusFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.focusFrame.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.focusFrame.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 7,
                        get = function(_) return module.focusFrame.y end,
                        set = function(_, val)
                            module.focusFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    },
                }
            },
            castBar = {
                name = "Cast Bar",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = false,
                order = 4,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.castBar.move end,
                        set = function(_, val)
                            module.castBar.move = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer1 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 1,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.castBar.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(module.castBar.move) end,
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.castBar.frameAnchor end,
                        set = function(_, val)
                            module.castBar.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.castBar.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(module.castBar.move) end,
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.castBar.screenAnchor end,
                        set = function(_, val)
                            module.castBar.screenAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    spacer2 = {
                        name = "",
                        type = "description",
                        width = "full",
                        order = 4,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.castBar.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.castBar.move) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.castBar.x end,
                        set = function(_, val)
                            module.castBar.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.castBar.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(module.castBar.move) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.castBar.y end,
                        set = function(_, val)
                            module.castBar.y = val
                            self:SetupUnitFrames()
                        end,
                    },
                }
            }
        }
    }
end
