-- Adds buttons under the escape menu. They are separate frames shown with the
-- menu: calling GameMenuFrame:AddButton or adding children to its layout from
-- addon code would taint the menu's own buttons, such as Edit Mode and Log Out.
local entries = {
    {
        key = "sui",
        text = "Scarlet UI",
        open = function() LibStub("AceConfigDialog-3.0"):Open("ScarletUI") end,
    },
    {
        key = "cooldownManager",
        text = "Cooldown Manager",
        -- A registered UI panel, so ShowUIPanel shows it from Blizzard's secure code.
        open = function() ShowUIPanel(CooldownViewerSettings) end,
        available = function() return CooldownViewerSettings ~= nil end,
    },
}
local buttons = {}

local function ShowButtons()
    local settings = ScarletUI.db.global.gameMenuButtons
    local previous
    for _, entry in ipairs(entries) do
        local shown = settings[entry.key] and (not entry.available or entry.available())
        local button = buttons[entry.key]
        if shown and not button then
            button = CreateFrame("Button", nil, UIParent, GameMenuFrame.buttonTemplate or "UIPanelButtonTemplate")
            button:SetFrameStrata(GameMenuFrame:GetFrameStrata())
            button:SetText(entry.text)
            button:SetScript("OnClick", function()
                -- Showing and hiding UI panels from addon code is blocked in combat.
                if InCombatLockdown() then return end
                PlaySound(SOUNDKIT.IG_MAINMENU_OPTION)
                HideUIPanel(GameMenuFrame)
                entry.open()
            end)
            buttons[entry.key] = button
        end
        if button then
            button:ClearAllPoints()
            if shown then
                button:SetPoint("TOP", previous or GameMenuFrame, "BOTTOM", 0, previous and 0 or -2)
                button:SetEnabled(not InCombatLockdown())
                previous = button
            end
            button:SetShown(shown)
        end
    end
end

function ScarletUI:SetupGameMenuButtons()
    if self.gameMenuButtonsHooked or not GameMenuFrame then
        return
    end
    self.gameMenuButtonsHooked = true
    GameMenuFrame:HookScript("OnShow", ShowButtons)
    GameMenuFrame:HookScript("OnHide", function()
        for _, button in pairs(buttons) do button:Hide() end
    end)
end
