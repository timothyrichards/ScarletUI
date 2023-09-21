local screenWidth = GetScreenWidth()
local screenHeight = GetScreenHeight()

function ScarletUI:Options()
    local database = ScarletUI.db.global;
    local defaults = ScarletUI.defaults.global;

    return {
        name = "Scarlet UI",
        handler = self,
        type = "group",
        childGroups = "tab",
        args = {
            moduleSettings = self:GetModuleSettingsPage(database, 0),
            chatModuleSettings = self:GetChatModuleSettingsPage(database.chatModule, defaults.chatModule, 1),
            actionbarsModuleSettings = self:GetActionbarsModuleSettingsPage(database.actionbarsModule, defaults.actionbarsModule, 2),
            unitFramesModuleSettings = self:GetUnitFramesModuleSettingsPage(database.unitFramesModule, defaults.unitFramesModule, 3),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(database.raidFramesModule, defaults.raidFramesModule, 4),
            cVarModuleSettings = self:GetCVarModuleSettingsPage(database.cVarModule, defaults.cVarModule, 5),
            defaultSettings = {
                name = "Restore Defaults",
                type = "execute",
                disabled = function() return self.inCombat end,
                order = 6,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                end,
            },
        },
    }
end

function ScarletUI:GetModuleSettingsPage(database, order)
    return {
        name = "General Settings",
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
                        width = 1,
                        order = 0,
                        get = function(_) return database.tidyIconsEnabled end,
                        set = function(_, val)
                            database.tidyIconsEnabled = val
                            self:TidyIcons_Update()
                        end,
                    },
                    itemLevel = {
                        name = "Item Level",
                        desc = "Display item level for items in your character window, and inspect frame.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return database.itemLevel end,
                        set = function(_, val)
                            database.itemLevel = val
                            if val then
                                self:SetupItemLevels()
                            else
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            end
                        end,
                    },
                    scrollSpellBook = {
                        name = "Scroll Spellbook",
                        desc = "Allows you to use the scroll wheel to change pages in your spellbook.",
                        type = "toggle",
                        hidden = function(_) return self.lightWeightMode end,
                        width = 1,
                        order = 2,
                        get = function(_) return database.scrollSpellBook end,
                        set = function(_, val)
                            database.scrollSpellBook = val
                            self:SpellBookPageScrolling()
                        end,
                    },
                },
            },
            weakAuras = {
                name = "WeakAuras",
                type = "group",
                disabled = function() return self.inCombat end,
                hidden = true,
                inline = true,
                order = 1,
                args = {
                    defaultSettings = {
                        name = "Install Nameplate WA",
                        type = "execute",
                        disabled = function() return self.inCombat end,
                        order = 0,
                        width = 1,
                        func = function()
                            self:ImportWeakAuras(self.threatNameplatesWA)
                        end,
                    },
                },
            },
        }
    }
end

function ScarletUI:GetChatModuleSettingsPage(module, defaults, order)
    return {
        name = "Chat Module",
        type = "group",
        order = order,
        args = {
            chatModule = {
                name = "Chat Module",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 0,
                args = {
                    enabled = {
                        name = "Enabled",
                        desc = "Manage the settings and position of your chat window.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return module.enabled end,
                        set = function(_, val)
                            module.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupChat()
                            end
                        end,
                    },
                },
            },
            generalSettings = {
                name = "General Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    fontSize = {
                        name = "Chat Font Size",
                        desc = "Desired font size for chat windows.\n(Default " .. defaults.fontSize .. ")",
                        type = "range",
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
                }
            },
            chatFrame = {
                name = "Chat Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                hidden = function(_) return self.lightWeightMode end,
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.chatFrame.x .. ")",
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
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.chatFrame.y .. ")",
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
        name = "Actionbar Module",
        type = "group",
        order = order,
        disabled = function() return self.lightWeightMode end,
        args = {
            actionbarModule = {
                name = "Actionbar Module",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 0,
                args = {
                    enabled = {
                        name = "Enabled",
                        desc = "Manage the position of your actionbars.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return module.enabled end,
                        set = function(_, val)
                            module.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupActionbars()
                            end
                        end,
                    },

                },
            },
            generalSettings = {
                name = "General Settings",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    stackActionbars = {
                        name = "Stack Actionbars",
                        desc = "Stack your main, bottom left, and bottom right actionbars.",
                        type = "toggle",
                        width = 1.5,
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
                }
            },
            microBar = {
                name = "Micro Bar",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                hidden = function(_) return self.lightWeightMode end,
                order = 2,
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.microBar.x .. ")",
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
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.microBar.y .. ")",
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
                hidden = function(_) return self.lightWeightMode end,
                order = 3,
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.bagBar.x .. ")",
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
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.bagBar.y .. ")",
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
        name = "Unit Frame Module",
        type = "group",
        order = order,
        disabled = function() return self.lightWeightMode end,
        args = {
            unitFramesModule = {
                name = "Unit Frames Module",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 0,
                args = {
                    enabled = {
                        name = "Enabled",
                        desc = "Manage the position of your unit frames.",
                        type = "toggle",
                        disabled = function() return self.inCombat end,
                        width = "full",
                        order = 0,
                        get = function(_) return module.enabled end,
                        set = function(_, val)
                            module.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupUnitFrames()
                            end
                        end,
                    },
                },
            },
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.playerFrame.x .. ")",
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
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.playerFrame.y .. ")",
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
                order = 2,
                args = {
                    mirrorPlayerFrame = {
                        name = "Mirror Player Frame",
                        desc = "Mirrors the X and Y position of the player frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.targetFrame.mirrorPlayerFrame end,
                        set = function(_, val)
                            module.targetFrame.mirrorPlayerFrame = val
                            self:SetupUnitFrames()
                        end,
                    },
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
                        width = 1,
                        order = 0,
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
                        order = 1,
                    },
                    frameAnchor = {
                        name = "Frame Anchor",
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[defaults.targetFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
                        width = 1,
                        order = 2,
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
                        order = 3,
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
                        order = 4,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.targetFrame.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return module.targetFrame.x end,
                        set = function(_, val)
                            module.targetFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.targetFrame.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(not module.targetFrame.mirrorPlayerFrame) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.focusFrame.x .. ")",
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
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.focusFrame.y .. ")",
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
        name = "Raid Frames Module",
        type = "group",
        order = order,
        disabled = function() return self.lightWeightMode end,
        args = {
            raidFramesModule = {
                name = "Raid Frames Module",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 0,
                args = {
                    enabled = {
                        name = "Enabled",
                        desc = "Manage the settings and position of your raid frames.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return module.enabled end,
                        set = function(_, val)
                            module.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupRaidProfiles()
                            end
                        end,
                    },
                },
            },
            partyFrames = {
                name = "Party Frames",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(module.enabled) end,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.partyFrames.move end,
                        set = function(_, val)
                            module.partyFrames.move = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.partyFrames.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.partyFrames.x end,
                        set = function(_, val)
                            module.partyFrames.x = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.partyFrames.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.partyFrames.y end,
                        set = function(_, val)
                            module.partyFrames.y = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    height = {
                        name = "Height",
                        desc = "Must be a number, this is the height of the party frames container.\n(Default " .. defaults.partyFrames.height .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.partyFrames.height end,
                        set = function(_, val)
                            module.partyFrames.height = val
                            self:SetupRaidProfiles()
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
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return module.raidFrames.move end,
                        set = function(_, val)
                            module.raidFrames.move = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. defaults.raidFrames.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return module.raidFrames.x end,
                        set = function(_, val)
                            module.raidFrames.x = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. defaults.raidFrames.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return module.raidFrames.y end,
                        set = function(_, val)
                            module.raidFrames.y = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    height = {
                        name = "Height",
                        desc = "Must be a number, this is the height of the raid frames container.\n(Default " .. defaults.raidFrames.height .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return module.raidFrames.height end,
                        set = function(_, val)
                            module.raidFrames.height = val
                            self:SetupRaidProfiles()
                        end,
                    }
                }
            },
        }
    }
end

function ScarletUI:GetCVarModuleSettingsPage(module, defaults, order)
    return {
        name = "CVar Settings Module",
        type = "group",
        order = order,
        args = {
            cVarModule = {
                name = "CVar Settings Module",
                type = "group",
                disabled = function() return self.inCombat end,
                inline = true,
                order = 0,
                args = {
                    enabled = {
                        name = "Enabled",
                        desc = "Manage your cVars.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return module.enabled end,
                        set = function(_, val)
                            module.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                ScarletUI:SetupCVars()
                            end
                        end,
                    },
                },
            },
            --cVars = {
            --    name = "CVar Settings",
            --    type = "group",
            --    disabled = function() return self.inCombat end,
            --    inline = true,
            --    order = 1,
            --    args = {
            --        useUiScale = {
            --            name = "",
            --            desc = "",
            --            type = "toggle",
            --            width = 1.5,
            --            order = 1,
            --            get = function(_) return module.useUiScale end,
            --            set = function(_, val)
            --                ScarletUI:SetupCVars()
            --            end,
            --        },
            --    },
            --},
        }
    }
end