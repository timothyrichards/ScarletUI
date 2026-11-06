-- Five second rule: spending mana pauses spirit-based mana regeneration for
-- 5 seconds. A line crosses the player frame's mana bar over that time and
-- disappears when regeneration resumes. Only Classic Era and Forever set this
-- up. The line is our own texture on the bar; no Blizzard function or script
-- is replaced.
local MANA = Enum and Enum.PowerType and Enum.PowerType.Mana or 0
local IsSecret = issecretvalue or function() return false end
local DURATION = 5

local function ReadMana()
    local mana = UnitPower("player", MANA)
    if not IsSecret(mana) then return mana end
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
    -- Seed now: the first cast after login or reload may be the first mana change.
    local lastMana, endTime = ReadMana(), 0
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
    frame:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
    frame:SetScript("OnEvent", function(_, _, _, powerType)
        if powerType ~= "MANA" then return end
        -- Unreadable (secret) mana clears the baseline so a stale value never starts the line.
        local mana = ReadMana()
        -- ponytail: any mana drop counts, including enemy drains; match player
        -- casts (UNIT_SPELLCAST_SUCCEEDED) if false starts become a problem.
        if mana and lastMana and mana < lastMana then
            endTime = GetTime() + DURATION
            frame:Show()
        end
        lastMana = mana
    end)
end
