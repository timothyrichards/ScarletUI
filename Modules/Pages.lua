function ScarletUI:Options()
    return {
        name = "Scarlet UI",
        handler = self,
        type = "group",
        childGroups = "tab",
        args = {
            moduleSettings = self:GetModuleSettingsPage(0),
            chatModuleSettings = self:GetChatModuleSettingsPage(1),
            actionbarsModuleSettings = self:GetActionbarsModuleSettingsPage(2),
            unitFramesModuleSettings = self:GetUnitFramesModuleSettingsPage(3),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(4),
            defaultSettings = {
                name = "Restore Defaults",
                type = "execute",
                disabled = function() return self.inCombat end,
                order = 5,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                end,
            },
        },
    }
end

function ScarletUI:GetModuleSettingsPage(order)
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
                        get = function(_) return self.db.global.tidyIconsEnabled end,
                        set = function(_, val)
                            self.db.global.tidyIconsEnabled = val
                            self:TidyIcons_Update()
                        end,
                    },
                    itemLevel = {
                        name = "Item Level",
                        desc = "Display item level for items in your character window, and inspect frame.",
                        type = "toggle",
                        width = 1,
                        order = 1,
                        get = function(_) return self.db.global.itemLevel end,
                        set = function(_, val)
                            self.db.global.itemLevel = val
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
                        get = function(_) return self.db.global.scrollSpellBook end,
                        set = function(_, val)
                            self.db.global.scrollSpellBook = val
                            self:SpellBookPageScrolling()
                        end,
                    },
                },
            },
        }
    }
end

function ScarletUI:GetChatModuleSettingsPage(order)
    local chatModule = self.db.global.chatModule;
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
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
                        get = function(_) return chatModule.enabled end,
                        set = function(_, val)
                            chatModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupChat()
                            end
                        end,
                    },
                    fontSize = {
                        name = "Chat Font Size",
                        desc = "Desired font size for chat windows.\n(Default " .. self.defaults.global.chatModule.fontSize .. ")",
                        type = "range",
                        min = 6,
                        max = 20,
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return chatModule.fontSize end,
                        set = function(_, val)
                            chatModule.fontSize = val
                            self:SetupChat()
                        end,
                    },
                },
            },
            chatFrame = {
                name = "Chat Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(chatModule.enabled) end,
                hidden = function(_) return self.lightWeightMode end,
                inline = true,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return chatModule.chatFrame.move end,
                        set = function(_, val)
                            chatModule.chatFrame.move = val
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[self.defaults.global.chatModule.chatFrame.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return chatModule.chatFrame.frameAnchor end,
                        set = function(_, val)
                            chatModule.chatFrame.frameAnchor = val
                            self:SetupChat()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[self.defaults.global.chatModule.chatFrame.screenAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return chatModule.chatFrame.screenAnchor end,
                        set = function(_, val)
                            chatModule.chatFrame.screenAnchor = val
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.chatModule.chatFrame.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return chatModule.chatFrame.x end,
                        set = function(_, val)
                            chatModule.chatFrame.x = val
                            self:SetupChat()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.chatModule.chatFrame.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return chatModule.chatFrame.y end,
                        set = function(_, val)
                            chatModule.chatFrame.y = val
                            self:SetupChat()
                        end,
                    }
                }
            },
        }
    }
end

function ScarletUI:GetActionbarsModuleSettingsPage(order)
    local actionbarsModule = self.db.global.actionbarsModule;
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
                        get = function(_) return actionbarsModule.enabled end,
                        set = function(_, val)
                            actionbarsModule.enabled = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupActionbars()
                            end
                        end,
                    },

                },
            },
            actionbars = {
                name = "Actionbars",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(actionbarsModule.enabled) end,
                inline = true,
                order = 1,
                args = {
                    stackActionbars = {
                        name = "Stack Actionbars",
                        desc = "Stack your main, bottom left, and bottom right actionbars.",
                        type = "toggle",
                        width = 1.5,
                        order = 0,
                        get = function(_) return actionbarsModule.stackActionbars end,
                        set = function(_, val)
                            actionbarsModule.stackActionbars = val
                            if not val then
                                StaticPopup_Show('SCARLET_UI_RELOAD_DIALOG')
                            else
                                self:SetupActionbars()
                            end
                        end,
                    },
                    stackSidebars = {
                        name = "Stack Sidebars",
                        desc = "Stack your sidebars with your other three bars.",
                        type = "toggle",
                        disabled = function() return ScarletUI:SettingDisabled(actionbarsModule.enabled and actionbarsModule.stackActionbars) end,
                        width = 1.5,
                        order = 0,
                        get = function(_) return actionbarsModule.stackSidebars end,
                        set = function(_, val)
                            actionbarsModule.stackSidebars = val
                            if not val then
                                self:RevertSidebars()
                                self:SetupActionbars()
                            else
                                self:SetupActionbars()
                            end
                        end,
                    },
                }
            }
        }
    }
end

function ScarletUI:GetUnitFramesModuleSettingsPage(order)
    local unitFramesModule = self.db.global.unitFramesModule;
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
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
                        get = function(_) return unitFramesModule.enabled end,
                        set = function(_, val)
                            unitFramesModule.enabled = val
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
                disabled = function() return ScarletUI:SettingDisabled(unitFramesModule.enabled) end,
                inline = true,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return unitFramesModule.playerFrame.move end,
                        set = function(_, val)
                            unitFramesModule.playerFrame.move = val
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[self.defaults.global.unitFramesModule.playerFrame.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return unitFramesModule.playerFrame.frameAnchor end,
                        set = function(_, val)
                            unitFramesModule.playerFrame.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[self.defaults.global.unitFramesModule.playerFrame.screenAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return unitFramesModule.playerFrame.screenAnchor end,
                        set = function(_, val)
                            unitFramesModule.playerFrame.screenAnchor = val
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.playerFrame.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return unitFramesModule.playerFrame.x end,
                        set = function(_, val)
                            unitFramesModule.playerFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.playerFrame.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return unitFramesModule.playerFrame.y end,
                        set = function(_, val)
                            unitFramesModule.playerFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    }
                }
            },
            targetFrame = {
                name = "Target Frame",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(unitFramesModule.enabled) end,
                inline = true,
                order = 2,
                args = {
                    mirrorPlayerFrame = {
                        name = "Mirror Player Frame",
                        desc = "Mirrors the X and Y position of the player frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return unitFramesModule.targetFrame.mirrorPlayerFrame end,
                        set = function(_, val)
                            unitFramesModule.targetFrame.mirrorPlayerFrame = val
                            self:SetupUnitFrames()
                        end,
                    },
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        disabled = function() return ScarletUI:SettingDisabled(not unitFramesModule.targetFrame.mirrorPlayerFrame) end,
                        width = 1,
                        order = 0,
                        get = function(_) return unitFramesModule.targetFrame.move end,
                        set = function(_, val)
                            unitFramesModule.targetFrame.move = val
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[self.defaults.global.unitFramesModule.targetFrame.frameAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(not unitFramesModule.targetFrame.mirrorPlayerFrame) end,
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return unitFramesModule.targetFrame.frameAnchor end,
                        set = function(_, val)
                            unitFramesModule.targetFrame.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[self.defaults.global.unitFramesModule.targetFrame.screenAnchor] .. ")",
                        type = "select",
                        disabled = function() return ScarletUI:SettingDisabled(not unitFramesModule.targetFrame.mirrorPlayerFrame) end,
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return unitFramesModule.targetFrame.screenAnchor end,
                        set = function(_, val)
                            unitFramesModule.targetFrame.screenAnchor = val
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.targetFrame.x .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(not unitFramesModule.targetFrame.mirrorPlayerFrame) end,
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return unitFramesModule.targetFrame.x end,
                        set = function(_, val)
                            unitFramesModule.targetFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.targetFrame.y .. ")",
                        type = "range",
                        disabled = function() return ScarletUI:SettingDisabled(not unitFramesModule.targetFrame.mirrorPlayerFrame) end,
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return unitFramesModule.targetFrame.y end,
                        set = function(_, val)
                            unitFramesModule.targetFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    },
                }
            },
            focusFrame = {
                name = "Focus Frame",
                type = "group",
                hidden = function() return not FocusFrame end,
                disabled = function() return ScarletUI:SettingDisabled(unitFramesModule.enabled) end,
                inline = true,
                order = 3,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_) return unitFramesModule.focusFrame.move end,
                        set = function(_, val)
                            unitFramesModule.focusFrame.move = val
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
                        desc = "Anchor point of the frame.\n(Default " .. self.frameAnchors[self.defaults.global.unitFramesModule.focusFrame.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 2,
                        values = function() return self.frameAnchors end,
                        get = function(_) return unitFramesModule.focusFrame.frameAnchor end,
                        set = function(_, val)
                            unitFramesModule.focusFrame.frameAnchor = val
                            self:SetupUnitFrames()
                        end,
                    },
                    screenAnchor = {
                        name = "Screen Anchor",
                        desc = "Anchor point of the frame relative to the screen.\n(Default " .. self.frameAnchors[self.defaults.global.unitFramesModule.focusFrame.frameAnchor] .. ")",
                        type = "select",
                        width = 1,
                        order = 3,
                        values = function() return self.frameAnchors end,
                        get = function(_) return unitFramesModule.focusFrame.screenAnchor end,
                        set = function(_, val)
                            unitFramesModule.focusFrame.screenAnchor = val
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
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.focusFrame.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 5,
                        get = function(_) return unitFramesModule.focusFrame.x end,
                        set = function(_, val)
                            unitFramesModule.focusFrame.x = val
                            self:SetupUnitFrames()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.focusFrame.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 6,
                        get = function(_) return unitFramesModule.focusFrame.y end,
                        set = function(_, val)
                            unitFramesModule.focusFrame.y = val
                            self:SetupUnitFrames()
                        end,
                    },
                }
            },
        }
    }
end

function ScarletUI:GetRaidFramesModuleSettingsPage(order)
    local raidFramesModule = self.db.global.raidFramesModule;
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
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
                        get = function(_) return raidFramesModule.enabled end,
                        set = function(_, val)
                            raidFramesModule.enabled = val
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
                disabled = function() return ScarletUI:SettingDisabled(raidFramesModule.enabled) end,
                inline = true,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return raidFramesModule.partyFrames.move end,
                        set = function(_, val)
                            raidFramesModule.partyFrames.move = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.raidFramesModule.partyFrames.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return raidFramesModule.partyFrames.x end,
                        set = function(_, val)
                            raidFramesModule.partyFrames.x = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.raidFramesModule.partyFrames.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return raidFramesModule.partyFrames.y end,
                        set = function(_, val)
                            raidFramesModule.partyFrames.y = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    height = {
                        name = "Height",
                        desc = "Must be a number, this is the height of the raid frames.\n(Default " .. self.defaults.global.raidFramesModule.partyFrames.height .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return raidFramesModule.partyFrames.height end,
                        set = function(_, val)
                            raidFramesModule.partyFrames.height = val
                            self:SetupRaidProfiles()
                        end,
                    }
                }
            },
            raidFrames = {
                name = "Raid Frames",
                type = "group",
                disabled = function() return ScarletUI:SettingDisabled(raidFramesModule.enabled) end,
                inline = true,
                order = 1,
                args = {
                    moveFrame = {
                        name = "Move Frame",
                        desc = "Allows you to choose the X and Y position of the frame.",
                        type = "toggle",
                        width = "full",
                        order = 0,
                        get = function(_) return raidFramesModule.raidFrames.move end,
                        set = function(_, val)
                            raidFramesModule.raidFrames.move = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    x = {
                        name = "Frame X",
                        desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.raidFramesModule.raidFrames.x .. ")",
                        type = "range",
                        min = math.floor(screenWidth) * -1,
                        max = math.floor(screenWidth),
                        step = 1,
                        width = 1,
                        order = 1,
                        get = function(_) return raidFramesModule.raidFrames.x end,
                        set = function(_, val)
                            raidFramesModule.raidFrames.x = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    y = {
                        name = "Frame Y",
                        desc = "Must be a number, this is the Y position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.raidFramesModule.raidFrames.y .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 2,
                        get = function(_) return raidFramesModule.raidFrames.y end,
                        set = function(_, val)
                            raidFramesModule.raidFrames.y = val
                            self:SetupRaidProfiles()
                        end,
                    },
                    height = {
                        name = "Height",
                        desc = "Must be a number, this is the height of the raid frames.\n(Default " .. self.defaults.global.raidFramesModule.raidFrames.height .. ")",
                        type = "range",
                        min = math.floor(screenHeight) * -1,
                        max = math.floor(screenHeight),
                        step = 1,
                        width = 1,
                        order = 3,
                        get = function(_) return raidFramesModule.raidFrames.height end,
                        set = function(_, val)
                            raidFramesModule.raidFrames.height = val
                            self:SetupRaidProfiles()
                        end,
                    }
                }
            },
        }
    }
end