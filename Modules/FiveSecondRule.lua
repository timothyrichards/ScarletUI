-- Five second rule: spending mana pauses spirit-based mana regeneration for
-- 5 seconds. After the player casts a spell that costs mana, a line crosses
-- the player frame's mana bar over that time and disappears when regeneration
-- resumes. Only Classic Era and Forever set this up. Forever gives addons mana
-- values as secrets, so casts come from the player's own
-- UNIT_SPELLCAST_SUCCEEDED (not secret for the player) and the spell's cost.
-- The line is our own texture on the bar; no Blizzard function or script is
-- replaced.
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
local IsSecret = issecretvalue or function() return false end
local GetSpellPowerCost = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost
local DURATION = 5

-- ponytail: a free cast (Clearcasting) still starts the line; no readable
-- signal says the cost was waived.
local function CostsMana(spellID)
    local costs = spellID and not IsSecret(spellID) and GetSpellPowerCost(spellID)
    for _, cost in ipairs(costs or {}) do
        if cost.type == MANA and not IsSecret(cost.cost) and cost.cost > 0 then
            return true
        end
    end
end

function ScarletUI:SetupFiveSecondRule()
    local client = self:GetWoWVersion()
    if self.fiveSecondRuleFrame or (client ~= "VANILLA" and client ~= "FOREVER") then
        return
    end
    -- Mainline UI frames (Forever) have no global name for the player mana bar.
    local bar = PlayerFrame_GetManaBar and PlayerFrame_GetManaBar() or PlayerFrameManaBar
    if not bar then return end

    local spark = bar:CreateTexture(nil, "OVERLAY")
    spark:SetColorTexture(1, 1, 1, 0.9)
    spark:SetWidth(2)
    spark:Hide()

    local frame = CreateFrame("Frame")
    self.fiveSecondRuleFrame = frame
    local endTime = 0
    -- OnUpdate only runs while the frame is shown, i.e. during the 5 seconds.
    frame:SetScript("OnUpdate", function()
        local remaining = endTime - GetTime()
        if remaining <= 0 then
            spark:Hide()
            frame:Hide()
            return
        end
        -- Druid forms swap the bar to rage or energy while mana still follows the rule.
        spark:SetShown(self.db.global.fiveSecondRule and UnitPowerType("player") == MANA)
        local x = bar:GetWidth() * (1 - remaining / DURATION)
        spark:SetPoint("TOP", bar, "TOPLEFT", x, 2)
        spark:SetPoint("BOTTOM", bar, "BOTTOMLEFT", x, -2)
    end)
    frame:Hide()
    -- Hidden frames still receive events.
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    frame:SetScript("OnEvent", function(_, _, _, _, spellID)
        if CostsMana(spellID) then
            endTime = GetTime() + DURATION
            frame:Show()
        end
    end)
end
