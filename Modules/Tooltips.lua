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
-- first "X to Y" after the word heal (or "X to Y healing", as Holy Shock puts
-- it) plus a "N ... over T" heal over time, else "absorbing N".
-- ponytail: English only and misses fixed single-value heals; no API exposes
-- heal amounts.
local function HealAmount(description)
    local text = description and not IsSecret(description) and description:gsub("(%d),(%d%d%d)", "%1%2")
    if not text then
        return
    end
    local healText = text:match("[Hh]eal.*") or ""
    local low, high = text:match("(%d+) to (%d+) healing")
    if not low then
        low, high = healText:match("(%d+) to (%d+)")
    end
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

-- Max mana can be a secret value in combat; the last readable one stands in.
-- ponytail: a max mana change mid-combat (level up, buff) shows a stale percent
-- until combat ends.
local lastMaxMana
local function MaxMana()
    local maxMana = UnitPowerMax("player", MANA_TYPE)
    if IsSecret(maxMana) then
        return lastMaxMana
    end
    lastMaxMana = maxMana
    return maxMana
end

local function AddManaPercent(tooltip, spellID)
    if tooltip ~= GameTooltip or IsSecret(spellID) or not spellID or not ScarletUI.db.global.spellCostPercent
        or tooltip:IsForbidden() then
        return
    end
    local costs = GetSpellPowerCost and GetSpellPowerCost(spellID)
    local maxMana = MaxMana()
    if not costs or not maxMana or maxMana <= 0 then
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

-- Supply crates (Waylaid Crate) list the bundles that fill them as "- 20 Vision
-- Dust" rows. Each row gets its total cost from Auctionator (vendor price
-- first, as Auctionator does) and the cheapest row turns green.
-- Auctionator has no price-by-name API and the client only resolves names of
-- items the character has handled, so names are indexed from the item IDs in
-- Auctionator's price database (an internal table, hence the guards). Names
-- the client has not loaded yet are requested and picked up on a later hover.
-- ponytail: one pass over the whole price database on the first crate hover,
-- then only over IDs still unnamed; spread it over frames if it ever hitches.
local GetItemName = C_Item and C_Item.GetItemNameByID or GetItemInfo
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo -- no global on Mainline
local CHEAPEST_COLOR = "|cff20ff20"
local itemIDByName, unnamed = {}, nil

local function IndexItemNames()
    local database = Auctionator.Database and Auctionator.Database.db
    if not unnamed and type(database) == "table" then
        unnamed = {}
        for key in pairs(database) do
            unnamed[#unnamed + 1] = tonumber(key) -- other keys (pets, item levels) are not plain IDs
        end
    end
    for i = unnamed and #unnamed or 0, 1, -1 do
        local name = GetItemName(unnamed[i])
        if name then
            itemIDByName[name] = unnamed[i]
            unnamed[i] = unnamed[#unnamed]
            unnamed[#unnamed] = nil
        end
    end
end

-- Vendor price first, as Auctionator does.
local function Price(itemID)
    local API = Auctionator.API.v1
    return itemID and (API.GetVendorPriceByItemID("ScarletUI", itemID)
        or API.GetAuctionPriceByItemID("ScarletUI", itemID))
end

local function AddCrateCosts(tooltip)
    if tooltip ~= GameTooltip or not ScarletUI.db.global.crateFillCosts or tooltip:IsForbidden()
        or not (Auctionator and Auctionator.API and Auctionator.API.v1) then
        return
    end
    -- The list may be one row per tooltip line or one line with line breaks.
    local bundles, indexed = {}, false
    for i = 2, tooltip:NumLines() do
        local text = _G["GameTooltipTextLeft" .. i]:GetText()
        if text and not IsSecret(text) then
            if text:find(CHEAPEST_COLOR, 1, true) then
                return -- already decorated
            end
            for row in text:gmatch("[^\r\n]+") do
                local count, name = row:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%- (%d+) (.-)%s*$")
                if name then
                    if not itemIDByName[name] and not indexed then
                        indexed = true
                        IndexItemNames()
                    end
                    bundles[row] = { count = count, itemID = itemIDByName[name] }
                end
            end
        end
    end
    local costs, cheapest = {}, nil
    for row, bundle in pairs(bundles) do
        local price = Price(bundle.itemID)
        if price then
            costs[row] = price * bundle.count
            cheapest = math.min(cheapest or costs[row], costs[row])
        end
    end
    if not cheapest then
        return
    end
    for i = 2, tooltip:NumLines() do
        local line = _G["GameTooltipTextLeft" .. i]
        local text = line:GetText()
        if text and not IsSecret(text) then
            line:SetText((text:gsub("[^\r\n]+", function(row)
                local cost = costs[row]
                if cost then
                    return (cost == cheapest and CHEAPEST_COLOR .. row .. "|r" or row)
                        .. "\n    |cffffffff" .. GetMoneyString(cost, true) .. "|r"
                end
            end)))
        end
    end
    return true
end

-- Craftsman's Writs (Forever): the reputation a writ gives, what its requested
-- items cost now, to compare writs. The requested items come from
-- Modules/Writs.lua.
local WRIT_FACTIONS = { Alliance = "Azeroth Commerce Authority", Horde = "Durotar Supply and Logistics" }
local HUMAN_RACE_ID = 1

local function AddWritInfo(tooltip, itemID)
    local writ = itemID and ScarletUI.WRITS[itemID]
    if not writ or tooltip ~= GameTooltip or not ScarletUI.db.global.writInfo or tooltip:IsForbidden() then
        return
    end
    local name, count = writ[2], writ[3] or 1
    local reputation = ScarletUI.WRIT_REPUTATION[writ[1]]
    -- ponytail: Human Diplomacy (+10%) assumed to apply to writs and round down,
    -- unchecked in game; Forever's Diplomat legacy talent is not counted.
    if select(3, UnitRace("player")) == HUMAN_RACE_ID then
        reputation = math.floor(reputation * 1.1)
    end
    -- Blizzard's reputation-gain chat color; light blue if the client lacks it.
    local rep = ChatTypeInfo and ChatTypeInfo.COMBAT_FACTION_CHANGE or { r = 0.5, g = 0.5, b = 1 }
    tooltip:AddDoubleLine(WRIT_FACTIONS[UnitFactionGroup("player")] or "Reputation", "+" .. reputation,
        rep.r, rep.g, rep.b, rep.r, rep.g, rep.b)
    if not itemIDByName[name] then
        IndexItemNames()
    end
    local itemID = itemIDByName[name]
    -- Quality color once the item is cached; white until a later hover finds it, as with names.
    local quality = itemID and select(3, GetItemInfo(itemID))
    local color = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality] or { r = 1, g = 1, b = 1 }
    local price = Price(itemID)
    tooltip:AddDoubleLine((count > 1 and count .. " " or "") .. name,
        price and GetMoneyString(price * count, true) or "No price", color.r, color.g, color.b, 1, 1, 1)
    return true
end

local function AddItemPrices(tooltip, itemID)
    local crate = AddCrateCosts(tooltip)
    return AddWritInfo(tooltip, itemID) or crate
end

function ScarletUI:SetupSpellCostPercent()
    if self.spellCostHooked or not GameTooltip then
        return
    end
    self.spellCostHooked = true
    MaxMana() -- seed the cache in case no spell is hovered before combat
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
        -- Setup runs at login, after every addon has loaded.
        if Auctionator then
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
                AddItemPrices(tooltip, data and data.id)
            end)
        end
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
        if Auctionator then
            GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
                local _, link = tooltip:GetItem()
                if AddItemPrices(tooltip, link and tonumber(link:match("item:(%d+)"))) then
                    tooltip:Show()
                end
            end)
        end
    end
end
