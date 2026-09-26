-- Appends the percent of maximum mana to a spell tooltip's cost line, e.g.
-- "105 Mana (8%)", colors the word Mana, and adds healing per mana. Post-hooks
-- only edit GameTooltip text; no Blizzard function or secure frame is replaced,
-- so they add no action taint.
local GetSpellPowerCost = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
local IsSecret = issecretvalue or function() return false end
local MANA_TYPE = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
local MANA_COLOR = "|cff40a0ff" -- lighter than PowerBarColor's pure blue, readable on tooltips
local GetSpellDescription = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription

-- Heal or absorb amount parsed from an English description: the average of the
-- first "X to Y" plus a "N ... over T" heal over time, else "absorbing N".
-- ponytail: English only and misses fixed single-value heals; no API exposes
-- heal amounts.
local function HealAmount(description)
    local text = description and not IsSecret(description) and description:gsub("(%d),(%d%d%d)", "%1%2")
    if not text then
        return
    end
    local healText = text:match("[Hh]eal.*") or ""
    local low, high = healText:match("(%d+) to (%d+)")
    local overTime = healText:match("(%d+)%D-over %d")
    if low or overTime then
        return (low and (low + high) / 2 or 0) + (overTime or 0), "healing"
    end
    local absorb = text:match("[Aa]bsorb%a* (%d+)") or text:match("[Aa]bsorb%a* up to (%d+)")
    if absorb then
        return tonumber(absorb), "absorb"
    end
end

-- While a spell is on cooldown every line is a secret value that addons
-- cannot read; those tooltips are left untouched.
local function FindCostLine(tooltip, amount)
    for i = 2, tooltip:NumLines() do
        local text = _G["GameTooltipTextLeft" .. i]:GetText()
        if not IsSecret(text) and text and text:find(amount, 1, true) and text:find(MANA, 1, true) then
            if text:find(MANA_COLOR, 1, true) then
                return -- already decorated
            end
            local right = _G["GameTooltipTextRight" .. i]
            local rightText = right:IsShown() and right:GetText()
            if IsSecret(rightText) or rightText == "" then
                rightText = nil
            end
            return i, text, rightText
        end
    end
end

local function AddManaPercent(tooltip, spellID)
    if tooltip ~= GameTooltip or IsSecret(spellID) or not spellID or not ScarletUI.db.global.spellCostPercent
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
            local i, text, rightText = FindCostLine(tooltip, amount)
            if not i then
                return
            end
            local manaStart, manaEnd = text:find(MANA, 1, true)
            text = text:sub(1, manaStart - 1) .. MANA_COLOR .. MANA .. "|r" .. text:sub(manaEnd + 1)
                .. " (" .. math.floor(cost.cost / maxMana * 100 + 0.5) .. "%)"
            -- The description includes spell power scaling, matching the tooltip.
            local heal, kind
            if GetLocale():sub(1, 2) == "en" and GetSpellDescription then
                heal, kind = HealAmount(GetSpellDescription(spellID))
            end
            if heal then
                -- Tooltips only append lines, so add a second row to the cost line.
                text = text .. "\n" .. MANA_COLOR
                    .. string.format("%.2f %s per mana", heal / cost.cost, kind) .. "|r"
                -- Pad the range text to two rows so it stays level with the cost.
                if rightText then
                    _G["GameTooltipTextRight" .. i]:SetText(rightText .. "\n ")
                end
            end
            -- Blizzard shows (and resizes) the tooltip after post-calls run.
            _G["GameTooltipTextLeft" .. i]:SetText(text)
            return
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
            tooltip:Show() -- resize; this older path has no Show after hooks
        end)
    end
end
