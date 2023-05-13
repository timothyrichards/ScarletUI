local function trimIcon(icon)
    icon:SetTexCoord(.08, .92, .08, .92)
end

local function untrimIcon(icon)
    icon:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
end

local function toggleTrim(icon)
    if ScarletUI.db.global.tidyIconsEnabled then
        trimIcon(icon)
    else
        untrimIcon(icon)
    end
end

function ScarletUI:TidyIcons_MacroFrame_Update()
    if (MacroFrame:IsShown()) then
        for i = 1, 120 do
            local button = _G["MacroButton" .. i]
            if button then
                local name = button:GetName()
                local icon = _G[name .. "Icon"]

                toggleTrim(icon)
            end
        end
    end
end

-- Ensure MacroPopupFrame frame is loaded first, so we don't get an error
if not IsAddOnLoaded("Blizzard_MacroUI") then
    LoadAddOn("Blizzard_MacroUI")
end
MacroFrame:HookScript("OnShow", function()
    ScarletUI:TidyIcons_MacroFrame_Update()
end)

function ScarletUI:TidyIcons_Update()
    -- Tidy action bar icons
    for i = 1, NUM_ACTIONBAR_BUTTONS do
        for _, v in pairs({
            "ActionButton",
            "MultiBarBottomLeftButton",
            "MultiBarBottomRightButton",
            "MultiBarRightButton",
            "MultiBarLeftButton"
        }) do
            local button = _G[v .. i]
            local name = button:GetName()
            local icon = _G[name .. "Icon"]

            toggleTrim(icon)
        end
    end

    self:TidyIcons_MacroFrame_Update()
end