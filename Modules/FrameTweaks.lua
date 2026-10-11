-- Small visibility tweaks for Blizzard frames. Showing and hiding textures and
-- unprotected frames is stored by the client, so it does not taint.

function ScarletUI:SetupMicroMenuArt()
    local menu = MicroMenu
    if not (menu and menu.BackgroundArt and menu.BorderArt) then return end
    local shown = not self.db.global.hideMicroMenuArt
    menu.BackgroundArt:SetShown(shown)
    menu.BorderArt:SetShown(shown)
end

-- Temporary fix for Forever: GamepadBagBar only hides its bag buttons when
-- Gamepad UI is on, so they appear on the combined backpack when it is off.
-- Blizzard never shows or hides the bar itself, so it is safe to own.
local function UpdateGamepadBagBar()
    GamepadBagBar:SetShown(InputUtil.IsGamepadUIEnabled())
end

function ScarletUI:SetupFrameTweaks()
    self:SetupMicroMenuArt()
    if self.gamepadBagBarHooked or not (GamepadBagBar and InputUtil and ContainerFrameCombinedBags) then return end
    self.gamepadBagBarHooked = true
    UpdateGamepadBagBar()
    -- No event fires when Gamepad UI is toggled, so check whenever the bags open.
    ContainerFrameCombinedBags:HookScript("OnShow", UpdateGamepadBagBar)
end
