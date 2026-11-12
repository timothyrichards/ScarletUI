-- Shares the bag sort settings across characters. They are per-character game
-- settings, not CVars. Era, TBC, and Mists only have the insert setting.
local settings = {
    sortBagsRightToLeft = "SortBagsRightToLeft",
    insertItemsLeftToRight = "InsertItemsLeftToRight",
}

function ScarletUI:IsBagSortSupported(key)
    return C_Container and C_Container["Set" .. settings[key]] ~= nil
end

-- Get keeps returning the old value for a moment after Set, which made the
-- toggles snap back; report the requested value until the client catches up.
local requested = {}

function ScarletUI:GetBagSort(key)
    local value = C_Container["Get" .. settings[key]]() and true or false
    if requested[key] == value then requested[key] = nil end
    if requested[key] == nil then return value end
    return requested[key]
end

function ScarletUI:SetBagSort(key, value)
    requested[key] = value
    C_Container["Set" .. settings[key]](value)
end

-- A change made anywhere (/sui, the bag menu, another addon) becomes the shared
-- value, but only once this character has received the shared values, so what
-- it had before is not taken for a change. Get is never read back: at logout it
-- could return a stale "off" that the next login applied again.
for key, name in pairs(settings) do
    if C_Container and C_Container["Set" .. name] then
        hooksecurefunc(C_Container, "Set" .. name, function(value)
            local module = ScarletUI.db.global.bagSortModule
            if module.enabled and ScarletUI.bagSortApplied then module[key] = value and true or false end
        end)
    end
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
end
