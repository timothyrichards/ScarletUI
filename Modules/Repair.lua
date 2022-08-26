function ScarletUI:SetupRepair()
    local RepairFrame = CreateFrame("FRAME")
    RepairFrame:RegisterEvent("MERCHANT_SHOW")
    RepairFrame:SetScript("OnEvent", function(self, event)
        if CanMerchantRepair() then -- If merchant is capable of repair
            local RepairCost, CanRepair = GetRepairAllCost()
            if CanRepair then -- If merchant is offering repair
                RepairAllItems()
                ScarletUI:Print("Repaired for " .. GetCoinText(RepairCost) .. ".")
            end
        end
    end)
end