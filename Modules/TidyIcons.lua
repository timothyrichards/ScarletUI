local function toggleTrim(icon)
    if ScarletUI.db.global.tidyIconsEnabled then
        icon:SetTexCoord(.08, .92, .08, .92)
    else
        icon:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
    end
end

function ScarletUI:SetupTidyIcons()
    -- Ensure MacroPopupFrame frame is loaded first, so we don't get an error
    if not IsAddOnLoaded("Blizzard_MacroUI") then
        LoadAddOn("Blizzard_MacroUI")
    end
    MacroFrame:HookScript("OnShow", function()
        self:TidyIcons_Update()
    end)

    self:TidyIcons_Update()
end

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

    -- Tidy macro window icons
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