-- Shares the bag sort settings across characters. They are per-character game
-- settings, not CVars. Era, TBC, and Mists only have the insert setting.
local settings = {
    sortBagsRightToLeft = "SortBagsRightToLeft",
    insertItemsLeftToRight = "InsertItemsLeftToRight",
}

function ScarletUI:IsBagSortSupported(key)
    return C_Container and C_Container["Set" .. settings[key]] ~= nil
end

function ScarletUI:GetBagSort(key)
    return C_Container["Get" .. settings[key]]() and true or false
end

function ScarletUI:SetBagSort(key, value)
    C_Container["Set" .. settings[key]](value)
end

function ScarletUI:SetupBagSort()
    local module = self.db.global.bagSortModule
    if not module.enabled or self.bagSortApplied then
        return
    end

    for key in pairs(settings) do
        if self:IsBagSortSupported(key) and module[key] ~= nil then
            self:SetBagSort(key, module[key])
        end
    end
    self.bagSortApplied = true

    if not self.bagSortShutdownRegistered then
        self.bagSortShutdownRegistered = true
        -- AceDB strips default-only tables on PLAYER_LOGOUT; this fires first.
        self.db.RegisterCallback("ScarletUI-BagSort", "OnDatabaseShutdown", function()
            local current = ScarletUI.db.global.bagSortModule
            if not current.enabled or not ScarletUI.bagSortApplied then return end
            for key in pairs(settings) do
                if ScarletUI:IsBagSortSupported(key) then
                    current[key] = ScarletUI:GetBagSort(key)
                end
            end
        end)
    end
end
