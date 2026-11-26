-- XP per hour: a small readout above the experience bar ("12.4k xp/hr  TTL 1h 12m").
-- ScarletUI has no XP bar of its own, so it anchors to the end of Blizzard's
-- XP StatusBar (inside StatusTrackingBarManager), or inside the bar's end when
-- the text would run off screen. The clock pauses while the player is AFK. The rate is the session average (XP gained since
-- login or the last reset, over the time since then), not a rolling window:
-- XP arrives in kill-sized lumps, and a window would jump with every kill and
-- drop to nothing during any pause, while the average moves smoothly. The
-- divisor never goes below MIN_ELAPSED, so a kill a few seconds after login
-- doesn't read as millions per hour. Hidden at max level, with XP turned off,
-- and until the first XP of the session. Hover for the details; right-click
-- resets the session. All state is in locals; no Blizzard frame is touched.
local IsSecret = issecretvalue or function() return false end
local MIN_ELAPSED = 60
local REFRESH = 1
local GAP = 6

local function FormatXP(n)
    if n >= 1e6 then return string.format("%.1fm", n / 1e6) end
    if n >= 1e4 then return string.format("%.1fk", n / 1e3) end
    return string.format("%d", math.floor(n + 0.5))
end

local function FormatDuration(seconds)
    seconds = math.floor(seconds)
    local h, m = math.floor(seconds / 3600), math.floor(seconds % 3600 / 60)
    if h > 0 then return string.format("%dh %dm", h, m) end
    if m > 0 then return string.format("%dm", m) end
    return string.format("%ds", seconds)
end

local function XPDisabled()
    if IsXPUserDisabled and IsXPUserDisabled() then return true end
    if IsPlayerAtEffectiveMaxLevel then return IsPlayerAtEffectiveMaxLevel() end
    local max = GetMaxPlayerLevel and GetMaxPlayerLevel()
    return max and UnitLevel("player") >= max or false
end
ScarletUI.XPDisabled = XPDisabled -- also the character viewer's max level (BankCache.lua)

function ScarletUI:SetupXPPerHour()
    if self.xpPerHourFrame or not StatusTrackingBarManager then return end

    local frame = CreateFrame("Frame", nil, UIParent)
    self.xpPerHourFrame = frame
    frame:SetFrameStrata("MEDIUM")
    frame:SetPoint("BOTTOMRIGHT", StatusTrackingBarManager, "TOPRIGHT", -4, 2) -- until the XP bar is found
    frame:EnableMouse(true)
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    -- The readout sits over the game world, not a panel: outline it.
    local font, size = text:GetFont()
    if font then text:SetFont(font, size, "OUTLINE") end
    frame:Hide()

    local gained, startTime, lastXP, lastMax = 0, GetTime(), nil, nil
    local pausedAt -- GetTime() when the player went AFK; nil while the clock runs

    -- The visible XP bar: every client's is an isExpBar frame with a StatusBar
    -- in one of the manager's containers (see QuestXPBar.lua).
    local function FindXPBar()
        for _, container in ipairs(StatusTrackingBarManager.barContainers or {}) do
            for _, bar in pairs(container.bars or {}) do
                if bar.isExpBar and bar.StatusBar then return bar.StatusBar end
            end
        end
    end

    -- Anchored to the bar, so it follows the bar through moves and resizes;
    -- only the off-screen check needs the once-a-second refresh.
    local function Place(width)
        local bar = FindXPBar()
        if not bar then return end
        frame:ClearAllPoints()
        local right, screen = bar:GetRight(), UIParent:GetRight()
        if right and screen and right + GAP + width > screen then
            frame:SetPoint("RIGHT", bar, "RIGHT", -GAP, 0)
        else
            frame:SetPoint("LEFT", bar, "RIGHT", GAP, 0)
        end
    end

    -- UnitIsAFK returns a secret boolean on some clients (1.60.1), which can't
    -- be tested. Then AFK comes from the "You are now AFK" system messages.
    local chatAFK = false
    local function AFKPattern(global)
        if type(global) ~= "string" or IsSecret(global) then return end
        return "^" .. global:gsub("%p", "%%%0"):gsub("%%%%s", ".*") .. "$"
    end
    local markedPatterns = { AFKPattern(MARKED_AFK), AFKPattern(MARKED_AFK_MESSAGE) }
    local clearedPattern = AFKPattern(CLEARED_AFK)

    local function OnSystemMessage(msg)
        if type(msg) ~= "string" or IsSecret(msg) then return end
        if clearedPattern and msg:find(clearedPattern) then
            chatAFK = false
        else
            for _, pattern in pairs(markedPatterns) do
                if msg:find(pattern) then chatAFK = true end
            end
        end
    end

    local function SyncAFK()
        local afk = UnitIsAFK and UnitIsAFK("player")
        if IsSecret(afk) then afk = chatAFK end
        if afk and not pausedAt then
            pausedAt = GetTime()
        elseif not afk and pausedAt then
            startTime, pausedAt = startTime + GetTime() - pausedAt, nil
        end
    end

    -- Returns rate (XP/hr) and seconds to level; nil until there is something to show.
    local function Stats()
        local elapsed = (pausedAt or GetTime()) - startTime
        local rate = gained / math.max(elapsed, MIN_ELAPSED) * 3600
        local remaining = lastXP and lastMax and lastMax - lastXP
        return rate, elapsed, remaining and rate > 0 and remaining / rate * 3600 or nil
    end

    local function Refresh()
        SyncAFK()
        if not self.db.global.xpPerHour or gained <= 0 or XPDisabled() then
            frame:Hide()
            return
        end
        local rate, _, ttl = Stats()
        text:SetText(FormatXP(rate) .. " xp/hr" .. (ttl and ("  TTL " .. FormatDuration(ttl)) or "") .. (pausedAt and " (paused)" or ""))
        local width = text:GetStringWidth() + 4
        frame:SetSize(width, text:GetStringHeight() + 4)
        Place(width)
        frame:Show()
    end

    -- ponytail: XP gained across more than one level in a single update is
    -- counted as one level's worth; that needs a quest bigger than a level.
    local function OnXP()
        local xp, max = UnitXP("player"), UnitXPMax("player")
        if IsSecret(xp) or IsSecret(max) then return end -- can't do arithmetic on these
        if lastXP then
            -- On a level-up XP resets to the overflow, and the previous
            -- level's max (what the old bar was filling toward) is added back.
            gained = gained + (xp >= lastXP and xp - lastXP or lastMax - lastXP + xp)
        end
        lastXP, lastMax = xp, max
        Refresh()
    end

    local function Reset()
        gained, startTime = 0, GetTime()
        if pausedAt then pausedAt = startTime end
        Refresh()
    end

    frame:SetScript("OnEnter", function()
        local rate, elapsed, ttl = Stats()
        GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine("Experience this session")
        GameTooltip:AddDoubleLine("XP gained", FormatXP(gained), nil, nil, nil, 1, 1, 1)
        GameTooltip:AddDoubleLine("Time", FormatDuration(elapsed) .. (pausedAt and " (paused)" or ""), nil, nil, nil, 1, 1, 1)
        GameTooltip:AddDoubleLine("XP per hour", FormatXP(rate), nil, nil, nil, 1, 1, 1)
        GameTooltip:AddDoubleLine("Time to level", ttl and FormatDuration(ttl) or "-", nil, nil, nil, 1, 1, 1)
        GameTooltip:AddLine("Right-click to reset the session.", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            Reset()
            if GameTooltip:IsOwned(frame) then frame:GetScript("OnEnter")() end
        end
    end)

    -- Hidden frames don't run OnUpdate, but the rate and TTL change as time
    -- passes, so while shown it refreshes about once a second.
    local sinceRefresh = 0
    frame:SetScript("OnUpdate", function(_, dt)
        sinceRefresh = sinceRefresh + dt
        if sinceRefresh >= REFRESH then
            sinceRefresh = 0
            Refresh()
        end
    end)

    local events = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_XP_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_FLAGS_CHANGED", "CHAT_MSG_SYSTEM",
        "PLAYER_UPDATE_RESTING", "UPDATE_EXHAUSTION", "PLAYER_LEVEL_UP" }) do
        events:RegisterEvent(event)
    end

    -- Rested XP on the bar's left end, mirroring the readout on the right. The
    -- percent is the character viewer's (BankCache.Rested, as if online).
    local restedFrame = CreateFrame("Frame", nil, UIParent)
    restedFrame:SetFrameStrata("MEDIUM")
    local restedText = restedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    restedText:SetPoint("CENTER")
    if font then restedText:SetFont(font, size, "OUTLINE") end
    restedFrame:Hide()
    local function RefreshRested()
        local rested, max = GetXPExhaustion(), UnitXPMax("player")
        local bar = FindXPBar()
        local percent
        if bar and not IsSecret(rested) and not IsSecret(max) then
            percent = self.BankCache.Rested({ rested = rested, xpMax = max, maxLevel = XPDisabled() }, 0, true)
        end
        if not percent or percent < 0.5 then
            restedFrame:Hide()
            return
        end
        restedText:SetText(("Rested %d%%"):format(math.floor(percent + 0.5)))
        local width = restedText:GetStringWidth() + 4
        restedFrame:SetSize(width, restedText:GetStringHeight() + 4)
        restedFrame:ClearAllPoints()
        local left = bar:GetLeft()
        if left and left - GAP - width < 0 then
            restedFrame:SetPoint("LEFT", bar, "LEFT", GAP, 0)
        else
            restedFrame:SetPoint("RIGHT", bar, "LEFT", -GAP, 0)
        end
        restedFrame:Show()
    end

    events:SetScript("OnEvent", function(_, event, unit)
        RefreshRested()
        if event == "CHAT_MSG_SYSTEM" then OnSystemMessage(unit) end
        if event == "PLAYER_XP_UPDATE" and (unit == nil or unit == "player") then
            OnXP()
        else
            Refresh()
        end
    end)

    -- Baseline: XP at login is not gained XP.
    local xp, max = UnitXP("player"), UnitXPMax("player")
    if not IsSecret(xp) and not IsSecret(max) then lastXP, lastMax = xp, max end

    RefreshRested()
    self.UpdateXPPerHour = function() Refresh() RefreshRested() end
    self.ResetXPPerHour = Reset
end

function ScarletUI:ToggleXPPerHour()
    local global = self.db.global
    global.xpPerHour = not global.xpPerHour
    if self.UpdateXPPerHour then self.UpdateXPPerHour() end
    self:Print("XP per hour readout " .. (global.xpPerHour and "on." or "off."))
end
