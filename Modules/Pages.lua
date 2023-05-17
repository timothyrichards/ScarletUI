function ScarletUI:Options()
    return {
        name = "Scarlet UI",
        handler = self,
        type = "group",
        childGroups = "tab",
        args = {
            defaultSettings = {
                name = "Restore Defaults",
                type = "execute",
                disabled = function() return InCombatLockdown() end,
                order = 0,
                width = 1,
                func = function()
                    StaticPopup_Show('SCARLET_RESTORE_DEFAULTS_DIALOG')
                end,
            },
            moduleSettings = self:GetModuleSettingsPage(1),
            unitFramesModuleSettings = self:GetUnitFramesModuleSettingsPage(2),
            actionbarsModuleSettings = self:GetActionbarsModuleSettingsPage(3),
            chatModuleSettings = self:GetChatModuleSettingsPage(4),
            raidFramesModuleSettings = self:GetRaidFramesModuleSettingsPage(5),
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
                disabled = function() return InCombatLockdown() end,
                inline = true,
                order = 0,
                args = {
                    tidyIcons = {
                        name = "Bigger Icons",
                        desc = "Make icons bigger to fill their actionbar slots.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_)
                            return self.db.global.tidyIconsEnabled
                        end,
                        set = function(_, val)
                            self.db.global.tidyIconsEnabled = val
                            self:TidyIcons_Update()
                        end,
                    },
                    scrollSpellBook = {
                        name = "Scroll Spellbook",
                        desc = "Allows you to use the scroll wheel to change pages in your spellbook.",
                        type = "toggle",
                        width = 1,
                        order = 0,
                        get = function(_)
                            return self.db.global.scrollSpellBook
                        end,
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

function ScarletUI:GetUnitFramesModuleSettingsPage(order)
    local unitFramesModule = self.db.global.unitFramesModule;
    local screenWidth = GetScreenWidth()
    local screenHeight = GetScreenHeight()
    return {
        name = "Unit Frame Module",
        type = "group",
        order = order,
        args = {
            unitFramesModule = {
                name = "Unit Frames Module",
                type = "group",
                disabled = function() return InCombatLockdown() end,
                inline = true,
                order = 0,
                args = {
                    enabled = {
                        name = "Enabled",
                        desc = "Manage the position of your unit frames.",
                        type = "toggle",
                        disabled = function() return InCombatLockdown() end,
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
                            x = {
                                name = "Frame X",
                                desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.playerFrame.x .. ")",
                                type = "range",
                                min = math.floor(screenWidth) * -1,
                                max = math.floor(screenWidth),
                                step = 1,
                                width = 1,
                                order = 1,
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
                                order = 2,
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
                            x = {
                                name = "Frame X",
                                desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.targetFrame.x .. ")",
                                type = "range",
                                disabled = function() return ScarletUI:SettingDisabled(not unitFramesModule.targetFrame.mirrorPlayerFrame) end,
                                min = math.floor(screenWidth) * -1,
                                max = math.floor(screenWidth),
                                step = 1,
                                width = 1,
                                order = 1,
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
                                order = 2,
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
                            x = {
                                name = "Frame X",
                                desc = "Must be a number, this is the X position of the frame relative to the center of the screen.\n(Default " .. self.defaults.global.unitFramesModule.focusFrame.x .. ")",
                                type = "range",
                                min = math.floor(screenWidth) * -1,
                                max = math.floor(screenWidth),
                                step = 1,
                                width = 1,
                                order = 1,
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
                                order = 2,
                                get = function(_) return unitFramesModule.focusFrame.y end,
                                set = function(_, val)
                                    unitFramesModule.focusFrame.y = val
                                    self:SetupUnitFrames()
                                end,
                            },
                        }
                    },
                },
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
        args = {
            actionbarModule = {
                name = "Actionbar Module",
                type = "group",
                disabled = function() return InCombatLockdown() end,
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
                },
            },
        }
    }
end

function ScarletUI:GetChatModuleSettingsPage(order)
    local chatModule = self.db.global.chatModule;
    return {
        name = "Chat Module",
        type = "group",
        order = order,
        args = {
            chatModule = {
                name = "Chat Module",
                type = "group",
                disabled = function() return InCombatLockdown() end,
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
                    }
                },
            },
        }
    }
end

function ScarletUI:GetRaidFramesModuleSettingsPage(order)
    local raidFramesModule = self.db.global.raidFramesModule;
    return {
        name = "Raid Frames Module",
        type = "group",
        order = order,
        args = {
            raidFramesModule = {
                name = "Raid Frames Module",
                type = "group",
                disabled = function() return InCombatLockdown() end,
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
                    }
                },
            },
        }
    }
end