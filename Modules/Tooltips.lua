-- Appends the percent of maximum mana to a spell tooltip's cost line, e.g.
-- "105 Mana (8%)", and colors the word Mana. A post-hook that only edits
-- existing GameTooltip text; no Blizzard function or secure frame is replaced,
-- so it adds no action taint.
local GetSpellPowerCost = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
local IsSecret = issecretvalue or function() return false end
local MANA_TYPE = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
local MANA_COLOR = "|cff40a0ff" -- lighter than PowerBarColor's pure blue, readable on tooltips

local function AddManaPercent(tooltip, spellID)
    if tooltip ~= GameTooltip or not spellID or not ScarletUI.db.global.spellCostPercent
        or tooltip:IsForbidden() then
        return
    end
    local costs = GetSpellPowerCost and GetSpellPowerCost(spellID)
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
                local manaStart, manaEnd
                if text and not IsSecret(text) and text:find(amount, 1, true) and not text:find("%)$") then
                    manaStart, manaEnd = text:find(MANA, 1, true)
                end
                if manaStart then
                    line:SetText(text:sub(1, manaStart - 1) .. MANA_COLOR .. MANA .. "|r" .. text:sub(manaEnd + 1)
                        .. " (" .. math.floor(cost.cost / maxMana * 100 + 0.5) .. "%)")
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
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
            AddManaPercent(tooltip, data.id)
        end)
        -- Macro tooltips (#showtooltip) carry the shown spell on their first line.
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Macro, function(tooltip, data)
            local first = data.lines and data.lines[1]
            AddManaPercent(tooltip, first and first.tooltipID)
        end)
    else
        GameTooltip:HookScript("OnTooltipSetSpell", function(tooltip)
            AddManaPercent(tooltip, select(2, tooltip:GetSpell()))
        end)
    end
end
