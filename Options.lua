local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()

function ScarletUI:Options()
    local database = ScarletUI.db.global;
    local defaults = ScarletUI.defaults.global;

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
                disabled = function() return self.inCombat end,
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
                disabled = function() return self.inCombat end,
                order = 1,
                width = 1,
                func = function()
                    self:ResetPositions()
                end,
            },
            defaultSettings = {
                name = "Restore Defaults",
                desc = "Restores all settings back to default settings.",
                type = "execute",
                disabled = function() return self.inCombat end,
                order = 2,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                end,
            },
            moduleSettings = self:GetModuleSettingsPage(database, 3),
            chatModuleSettings = self:GetChatModuleSettingsPage(database.chatModule, defaults.chatModule, 4),
            actionbarsModuleSettings = self:GetActionbarsModuleSettingsPage(database.actionbarsModule, defaults.actionbarsModule, 5),
            unitFramesModuleSettings = self:GetUnitFramesModuleSettingsPage(database.unitFramesModule, defaults.unitFramesModule, 6),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(database.raidFramesModule, defaults.raidFramesModule, 7),
            nameplatesModuleSettings = self:GetNameplatesModuleSettingsPage(database.nameplatesModule, defaults.nameplatesModule, 8),
            CVarModuleSettings = self:GetCVarModuleSettingsPage(database.CVarModule, 9),
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
            settings = {
                name = "Settings",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 0,
                args = {
                    tidyIcons = {
                        name = "Bigger Icons",
                        desc = "Make icons bigger to fill their actionbar slots.",
                        type = "toggle",
                        disabled = function() return self.lightWeightMode end,
                        width = 1,
                        order = 0,
                        get = function(_) return database.tidyIconsEnabled end,
                        set = function(_, val)
                            database.tidyIconsEnabled = val
                            self:TidyIcons_Update()
                        end,
                    },
                },
            },
            itemLevel = {
                name = "Item Level",
                type = "group",
                disabled = function() return self.inCombat end,
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
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
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
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
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
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            end
                        end,
                    },
                },
            },
            modules = {
                name = "Enabled Modules",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 2,
                args = {
                    chatModuleEnabled = {
                        name = "Chat",
                        desc = "Manage the settings and position of your chat window.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return database.chatModule.enabled end,
                        set = function(_, val)
                            database.chatModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupChat()
                            end
                        end,
                    },
                    actionbarsModuleEnabled = {
                        name = "Actionbars",
                        desc = "Manage the position of your actionbars.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.actionbarsModule.enabled end,
                        set = function(_, val)
                            database.actionbarsModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupActionbars()
                            end
                        end,
                    },
                    unitFramesModuleEnabled = {
                        name = "Unit Frames",
                        desc = "Manage the position of your unit frames.",
                        type = "toggle",
                        disabled = function() return self.inCombat end,
                        width = 1,
                        order = 2,
                        get = function(_) return database.unitFramesModule.enabled end,
                        set = function(_, val)
                            database.unitFramesModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupUnitFrames()
                            end
                        end,
                    },
                    raidFramesModuleEnabled = {
                        name = "Raid Frames",
                        desc = "Manage the settings and position of your raid frames.",
                        type = "toggle",
                        width = 1,
                        order = 3,
                        get = function(_) return database.raidFramesModule.enabled end,
                        set = function(_, val)
                            database.raidFramesModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupRaidProfiles()
                            end
                        end,
                    },
                    nameplatesModuleEnabled = {
                        name = "Nameplates",
                        desc = "Manage your Nameplates and threat colors.",
                        type = "toggle",
                        width = 1,
                        order = 4,
                        get = function(_) return database.nameplatesModule.enabled end,
                        set = function(_, val)
                            database.nameplatesModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                ScarletUI:SetupNameplates()
                            end
                        end,
                    },
                    cVarModuleEnabled = {
                        name = "CVars",
                        desc = "Manage your cVars. (WORK IN PROGRESS)",
                        type = "toggle",
                        width = 1,
                        order = 5,
                        get = function(_) return database.CVarModule.enabled end,
                        set = function(_, val)
                            database.CVarModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                ScarletUI:SetupCVars()
                            end
                        end,
                    },
                },
            },
        }
    }
end

function ScarletUI:GetChatModuleSettingsPage(module, defaults, order)
    return {
        name = "Chat",
        desc = "Chat Module settings.",
        type = "group",
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
                        width = 1,
                        order = 1,
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
                inline = true,
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

function ScarletUI:GetActionbarsModuleSettingsPage(module, defaults, order)
    return {
        name = "Actionbars",
        desc = "Actionbars Module settings.",
        type = "group",
        childGroups = "tree",
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
                    stackActionbars = {
                        name = "Stack Actionbars",
                        desc = "Stack your main, bottom left, and bottom right actionbars.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.stackActionbars end,
                        set = function(_, val)
                            module.stackActionbars = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupActionbars()
                            end
                        end,
                    },
                    showGryphons = {
                        name = "Show Gryphons",
                        desc = "Show the gryphon graphics on the sides of your main bar.",
                        type = "toggle",
                        disabled = function() return not module.stackActionbars end;
                        width = 1,
                        order = 1,
                        get = function(_) return module.showGryphons end,
                        set = function(_, val)
                            module.showGryphons = val
                            self:SetupActionbars()
                        end,
                    },
                    microBag = {
                        name = "Micro Bag",
                        desc = "Hide all non backpack bag icons.",
                        type = "toggle",
                        disabled = function() return not module.stackActionbars end;
                        width = 1,
                        order = 2,
                        get = function(_) return module.microBag end,
                        set = function(_, val)
                            module.microBag = val
                            if val then
                                self:SetupActionbars()
                            else
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            end
                        end,
                    },
                }
            },
            mainBar = {
                name = "Main Bar",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 2,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.mainBar.move end,
                        set = function(_, val)
                            module.mainBar.move = val
                            self:SetupActionbars()
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.mainBar.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.mainBar.frameAnchor end,
                        set = function(_, val)
                            module.mainBar.frameAnchor = val
                            self:SetupActionbars()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.mainBar.screenAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.mainBar.screenAnchor end,
                        set = function(_, val)
                            module.mainBar.screenAnchor = val
                            self:SetupActionbars()
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
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.mainBar.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.mainBar.x end,
                        set = function(_, val)
                            module.mainBar.x = val
                            self:SetupActionbars()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.mainBar.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.mainBar.y end,
                        set = function(_, val)
                            module.mainBar.y = val
                            self:SetupActionbars()
                        end,
                    }
                }
            },
            stanceBar = {
                name = "Stance Bar",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 3,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.stanceBar.move end,
                        set = function(_, val)
                            module.stanceBar.move = val
                            self:SetupActionbars()
                        end,
                    },
                    hide = {
                        name = "Hide Frame",
                        desc = "Allows you to hide the stance bar frame.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return module.stanceBar.hide end,
                        set = function(_, val)
                            module.stanceBar.hide = val
                            if val then
                                self:SetupActionbars()
                            else
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.stanceBar.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.stanceBar.frameAnchor end,
                        set = function(_, val)
                            module.stanceBar.frameAnchor = val
                            self:SetupActionbars()
                        end,
                    },
                    parentAnchor = {
                        name = "Parent Anchor",
                        desc = "Anchor point of the frame relative to its parent frame.\n(Default " .. self.frameAnchors[defaults.stanceBar.screenAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 4,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.stanceBar.screenAnchor end,
                        set = function(_, val)
                            module.stanceBar.screenAnchor = val
                            self:SetupActionbars()
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
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.stanceBar.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.stanceBar.x end,
                        set = function(_, val)
                            module.stanceBar.x = val
                            self:SetupActionbars()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.stanceBar.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 7,
                        get = function(_) return module.stanceBar.y end,
                        set = function(_, val)
                            module.stanceBar.y = val
                            self:SetupActionbars()
                        end,
                    }
                }
            },
            microBar = {
                name = "Micro Bar",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 4,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.microBar.move end,
                        set = function(_, val)
                            module.microBar.move = val
                            self:SetupActionbars()
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.microBar.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.microBar.frameAnchor end,
                        set = function(_, val)
                            module.microBar.frameAnchor = val
                            self:SetupActionbars()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.microBar.screenAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.microBar.screenAnchor end,
                        set = function(_, val)
                            module.microBar.screenAnchor = val
                            self:SetupActionbars()
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
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.microBar.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.microBar.x end,
                        set = function(_, val)
                            module.microBar.x = val
                            self:SetupActionbars()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.microBar.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.microBar.y end,
                        set = function(_, val)
                            module.microBar.y = val
                            self:SetupActionbars()
                        end,
                    }
                }
            },
            bagBar = {
                name = "Bag Bar",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 5,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return module.bagBar.move end,
                        set = function(_, val)
                            module.bagBar.move = val
                            self:SetupActionbars()
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.bagBar.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.bagBar.frameAnchor end,
                        set = function(_, val)
                            module.bagBar.frameAnchor = val
                            self:SetupActionbars()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[defaults.bagBar.screenAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return module.bagBar.screenAnchor end,
                        set = function(_, val)
                            module.bagBar.screenAnchor = val
                            self:SetupActionbars()
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
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.bagBar.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.bagBar.x end,
                        set = function(_, val)
                            module.bagBar.x = val
                            self:SetupActionbars()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.bagBar.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.bagBar.y end,
                        set = function(_, val)
                            module.bagBar.y = val
                            self:SetupActionbars()
                        end,
                    }
                }
            },
        }
    }
end

function ScarletUI:GetUnitFramesModuleSettingsPage(module, defaults, order)
    return {
        name = "Unit Frames",
        desc = "Unit Frames Module settings.",
        type = "group",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
        hidden = function() return self.retail end,
        args = {
            playerFrame = {
                name = "Player Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
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
                inline = true,
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
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
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
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
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
                inline = true,
                order = 3,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
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
                        order = 1,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.focusFrame.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
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
                        width = 1,
                        order = 3,
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
                        order = 4,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame anchor relative to the screen anchor.\n(Default " .. defaults.focusFrame.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
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
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return module.focusFrame.y end,
                        set = function(_, val)
                            module.focusFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    },
                }
            },
        }
    }
end

function ScarletUI:GetRaidFramesModuleSettingsPage(module, defaults, order)
    return {
        name = "Raid Frames",
        desc = "Raid Frames Module settings.",
        type = "group",
        order = order,
        disabled = function() return not module.enabled or self.lightWeightMode end,
        hidden = function() return self.retail end,
        args = {
            partyFrames = {
                name = "Party Frames",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Party Frames",
                        desc = "Allows you to choose the position of the party frames.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.partyFrames.move end,
                        set = function(_, val)
                            module.partyFrames.move = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    left = {
                        name = "Frame Left",
                        desc = "Must be a number, this is the distance of the raid frame container from the left side of the screen.\n(Default " .. defaults.partyFrames.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.partyFrames.x end,
                        set = function(_, val)
                            module.partyFrames.x = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    top = {
                        name = "Frame Top",
                        desc = "Must be a number, this is the distance of the raid frame container from the top of the screen.\n(Default " .. defaults.partyFrames.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.partyFrames.y end,
                        set = function(_, val)
                            module.partyFrames.y = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    bottom = {
                        name = "Frame Bottom",
                        desc = "Must be a number, this is the distance of the raid frame container from the bottom of the screen.\n(Default " .. defaults.partyFrames.height .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.partyFrames.height end,
                        set = function(_, val)
                            module.partyFrames.height = val
                            self:UpdateProfilePositions()
                        end,
                    }
                }
            },
            raidFrames = {
                name = "Raid Frames",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                inline = true,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Raid Frames",
                        desc = "Allows you to choose the position of the raid frames.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.raidFrames.move end,
                        set = function(_, val)
                            module.raidFrames.move = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    left = {
                        name = "Frame Left",
                        desc = "Must be a number, this is the distance of the raid frame container from the left side of the screen.\n(Default " .. defaults.raidFrames.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.raidFrames.x end,
                        set = function(_, val)
                            module.raidFrames.x = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    top = {
                        name = "Frame Top",
                        desc = "Must be a number, this is the distance of the raid frame container from the top of the screen.\n(Default " .. defaults.raidFrames.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.raidFrames.y end,
                        set = function(_, val)
                            module.raidFrames.y = val
                            self:UpdateProfilePositions()
                        end,
                    },
                    bottom = {
                        name = "Frame Bottom",
                        desc = "Must be a number, this is the distance of the raid frame container from the bottom of the screen.\n(Default " .. defaults.raidFrames.height .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.raidFrames.height end,
                        set = function(_, val)
                            module.raidFrames.height = val
                            self:UpdateProfilePositions()
                        end,
                    }
                }
            },
        }
    }
end

function ScarletUI:GetNameplatesModuleSettingsPage(module, defaults, order)
    return {
        name = "Nameplates",
        desc = "Nameplates Module settings.",
        type = "group",
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
                    classColored = {
                        name = "Class Colored Nameplates",
                        desc = "Change player nameplates to match their class color.",
                        type = "toggle",
                        width = 1.25,
                        order = 0,
                        get = function(_) return module.classColored end,
                        set = function(_, val)
                            module.classColored = val
                        end,
                    },
                }
            },
            targetIndicator = {
                name = "Target Indicator",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 1,
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
            healthBarText = {
                name = "Health Bar Text",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 2,
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
                            ScarletUI:UpdateHealthText()
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
                            ScarletUI:UpdateHealthText()
                        end,
                    }
                },
            },
            castBarText = {
                name = "Cast Bar Text",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 3,
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
                            ScarletUI:UpdateCustomText()
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
                            ScarletUI:UpdateCustomText()
                        end,
                    }
                },
            },
            nonTankThreatColors = {
                name = "Non-Tank Threat Colors",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 4,
                args = {
                    noThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                        hasAlpha = true,
                        order = 0,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.noThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.noThreat = {r, g, b, a}
                        end,
                    },
                    lowThreat = {
                        name = "Low Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                        hasAlpha = true,
                        order = 1,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.lowThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.lowThreat = {r, g, b, a}
                        end,
                    },
                    threat = {
                        name = "Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 2,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.threat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.threat = {r, g, b, a}
                        end,
                    },
                    tankThreat = {
                        name = "Tank Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 3,
                        get = function(_)
                            local r, g, b, a = unpack(module.nonTankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.nonTankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                },
            },
            tankThreatColors = {
                name = "Tank Threat Colors",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 5,
                args = {
                    noThreat = {
                        name = "No Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                        hasAlpha = true,
                        order = 0,
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
                        disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                        hasAlpha = true,
                        order = 1,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.lowThreat)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.lowThreat = {r, g, b, a}
                        end,
                    },
                    threat = {
                        name = "Threat",
                        type = "color",
                        desc = "Choose a color",
                        width = 0.75,
                        hasAlpha = true,
                        order = 2,
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
                        order = 3,
                        get = function(_)
                            local r, g, b, a = unpack(module.tankThreatColors.tank)
                            return r, g, b, a
                        end,
                        set = function(_, r, g, b, a)
                            module.tankThreatColors.tank = {r, g, b, a}
                        end,
                    },
                },
            },
            tankNames = {
                name = "Tank Names",
                type = "input",
                desc = "Add a comma seperated list of player names you wish to manually designate as tanks, for example: Tank1,Tank2,Tank3",
                multiline = 5,
                width = "full",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 6,
                get = function(_) return module.tankNames end,
                set = function(_, value)
                    module.tankNames = value
                    self:SetupTanks()
                end,
            },
            specialUnits = {
                name = "Special Units",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 7,
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
                }
            },
            specialUnitNames = {
                name = "Special Unit Names",
                type = "input",
                desc = "Add a comma seperated list of enemy unit names you wish to manually designate as special units, for example: Unit1,Unit2,Unit3",
                multiline = 5,
                width = "full",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 8,
                get = function(_) return module.specialUnitNames end,
                set = function(_, value)
                    module.specialUnitNames = value
                    self:SetupSpecialUnits()
                end,
            },
        }
    }
end

function ScarletUI:GetCVarModuleSettingsPage(module, order)
    local CVars = module.CVars
    local options = {
        name = "CVars",
        desc = "(WORK IN PROGRESS) CVars Module for advanced users to change console variables (hidden settings).",
        type = "group",
        order = order,
        disabled = function() return not module.enabled end,
        args = {}
    }
    local orderCounter = 0
    for k, v in pairs(CVars) do
        orderCounter = orderCounter + 1
        local labelName = "label" .. orderCounter
        local spacerName = "spacer" .. orderCounter

        options.args[labelName] = {
            name = k,
            type = "description",
            width = 1.25,
            order = orderCounter * 3 - 2,
        }

        options.args[k] = {
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
        }

        options.args[spacerName] = {
            name = "",
            type = "description",
            width = "full",
            order = orderCounter * 3,
        }
    end

    return options
end
