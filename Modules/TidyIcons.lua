function ScarletUI:SetupTidyIcons()
    if self.lightWeightMode or self.retail then
        return
    end

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

            if self.db.global.tidyIconsEnabled then
                icon:SetTexCoord(.08, .92, .08, .92)
            else
                icon:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)
            end
        end
    end
end
