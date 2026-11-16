-- Quest XP on the experience bar: the stretch after the filled part that
-- turning in every completed quest in the log would fill is drawn in gold,
-- stopping at the end of the bar when the quests would pass the level.
-- Every client's XP bar is an ExpStatusBarTemplate frame (isExpBar) inside
-- StatusTrackingBarManager's containers. The highlight is our own texture on
-- its StatusBar, anchored to the fill texture so it follows Blizzard's fill
-- animation; our state stays in locals, never on Blizzard's frames.
-- Blizzard's Era and TBC quest log shows no XP reward; where
-- GetQuestLogRewardXP gives 0, nothing is drawn.
local overlays = {} -- XP bar frame -> our texture

local function CompletedQuestXP()
    local total = 0
    if C_QuestLog and C_QuestLog.GetInfo then
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and not info.isHidden and C_QuestLog.IsComplete(info.questID) then
                total = total + (GetQuestLogRewardXP(info.questID) or 0)
            end
        end
    else
        for i = 1, GetNumQuestLogEntries() do
            local _, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
            -- 1 is complete; -1 is failed.
            if not isHeader and isComplete == 1 then
                total = total + (GetQuestLogRewardXP(questID) or 0)
            end
        end
    end
    return total
end

-- ponytail: widths are set on quest and XP events only; after resizing the bar
-- in Edit Mode the highlight is off until the next one. Hook the bar's
-- OnSizeChanged if that shows.
function ScarletUI:UpdateQuestXPBar()
    if not self.questXPBarFrame then return end
    local xp, maxXP = UnitXP("player"), UnitXPMax("player")
    local questXP = self.db.global.questXPBar and maxXP > 0 and CompletedQuestXP() or 0
    local share = questXP > 0 and math.min(questXP, maxXP - xp) / maxXP or 0
    for _, container in ipairs(StatusTrackingBarManager.barContainers or {}) do
        for _, bar in pairs(container.bars or {}) do
            local overlay = overlays[bar]
            if bar.isExpBar and bar.StatusBar and (overlay or share > 0) then
                if not overlay then
                    local fill = bar.StatusBar:GetStatusBarTexture()
                    overlay = bar.StatusBar:CreateTexture(nil, "ARTWORK", nil, 1)
                    overlay:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
                    overlay:SetVertexColor(1, 0.82, 0, 0.7)
                    overlay:SetPoint("TOPLEFT", fill, "TOPRIGHT")
                    overlay:SetPoint("BOTTOMLEFT", fill, "BOTTOMRIGHT")
                    overlays[bar] = overlay
                end
                overlay:SetShown(share > 0)
                if share > 0 then
                    overlay:SetWidth(bar.StatusBar:GetWidth() * share)
                end
            end
        end
    end
end

function ScarletUI:SetupQuestXPBar()
    if self.questXPBarFrame or not GetQuestLogRewardXP or not StatusTrackingBarManager then
        return
    end
    local frame = CreateFrame("Frame")
    self.questXPBarFrame = frame
    frame:RegisterEvent("QUEST_LOG_UPDATE")
    frame:RegisterEvent("PLAYER_XP_UPDATE")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function() self:UpdateQuestXPBar() end)
    self:UpdateQuestXPBar()
end
