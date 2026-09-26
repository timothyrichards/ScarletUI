-- Appends the percent of maximum mana to a spell tooltip's cost line, e.g.
-- "105 Mana (8%)". A post-hook that only edits existing GameTooltip text; no
-- Blizzard function or secure frame is replaced, so it adds no action taint.
local GetSpellPowerCost = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
local IsSecret = issecretvalue or function() return false end
local MANA_TYPE = Enum and Enum.PowerType and Enum.PowerType.Mana or 0

local function AddManaPercent(tooltip, data)
    if tooltip ~= GameTooltip or not ScarletUI.db.global.spellCostPercent or tooltip:IsForbidden() then
        return
    end
    local spellID = data and data.id or select(2, tooltip:GetSpell())
    local costs = spellID and GetSpellPowerCost and GetSpellPowerCost(spellID)
    local maxMana = UnitPowerMax("player", MANA_TYPE)
    if not costs or IsSecret(maxMana) or not maxMana or maxMana <= 0 then
        return
    end

    for _, cost in ipairs(costs) do
        if cost.type == MANA_TYPE and not IsSecret(cost.cost) and cost.cost > 0 then
            local amount = BreakUpLargeNumbers and BreakUpLargeNumbers(cost.cost) or tostring(cost.cost)
            for i = 2, tooltip:NumLines() do
                local line = _G["GameTooltipTextLeft" .. i]
                local text = line and line:GetText()
                if text and not IsSecret(text) and text:find(amount, 1, true) and text:find(MANA, 1, true)
                    and not text:find("%)$") then
                    line:SetText(text .. " (" .. math.floor(cost.cost / maxMana * 100 + 0.5) .. "%)")
                    tooltip:Show() -- resize for the longer line
                    return
                end
            end
        end
    end
end

function ScarletUI:SetupSpellCostPercent()
    if self.spellCostHooked or not GameTooltip then
        return
    end
    self.spellCostHooked = true
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, AddManaPercent)
    else
        GameTooltip:HookScript("OnTooltipSetSpell", AddManaPercent)
    end
end
