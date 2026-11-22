-- XP per hour: a small readout above the experience bar ("12.4k xp/hr  TTL 1h 12m").
-- ScarletUI has no XP bar of its own, so it anchors to Blizzard's
-- StatusTrackingBarManager. The rate is the session average (XP gained since
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

function ScarletUI:SetupXPPerHour()
    if self.xpPerHourFrame or not StatusTrackingBarManager then return end

    local frame = CreateFrame("Frame", nil, UIParent)
    self.xpPerHourFrame = frame
    frame:SetFrameStrata("MEDIUM")
    frame:SetPoint("BOTTOMRIGHT", StatusTrackingBarManager, "TOPRIGHT", -4, 2)
    frame:EnableMouse(true)
    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("RIGHT")
    text:SetJustifyH("RIGHT")
    -- The readout sits over the game world, not a panel: outline it.
    local font, size = text:GetFont()
    if font then text:SetFont(font, size, "OUTLINE") end
    frame:Hide()

    local gained, startTime, lastXP, lastMax = 0, GetTime(), nil, nil

    -- Returns rate (XP/hr) and seconds to level; nil until there is something to show.
    local function Stats()
        local elapsed = GetTime() - startTime
        local rate = gained / math.max(elapsed, MIN_ELAPSED) * 3600
        local remaining = lastXP and lastMax and lastMax - lastXP
        return rate, elapsed, remaining and rate > 0 and remaining / rate * 3600 or nil
    end

    local function Refresh()
        if not self.db.global.xpPerHour or gained <= 0 or XPDisabled() then
            frame:Hide()
            return
        end
        local rate, _, ttl = Stats()
        text:SetText(FormatXP(rate) .. " xp/hr" .. (ttl and ("  TTL " .. FormatDuration(ttl)) or ""))
        frame:SetSize(text:GetStringWidth() + 4, text:GetStringHeight() + 4)
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
        Refresh()
    end

    frame:SetScript("OnEnter", function()
        local rate, elapsed, ttl = Stats()
        GameTooltip:SetOwner(frame, "ANCHOR_TOPRIGHT")
        GameTooltip:AddLine("Experience this session")
        GameTooltip:AddDoubleLine("XP gained", FormatXP(gained), nil, nil, nil, 1, 1, 1)
        GameTooltip:AddDoubleLine("Time", FormatDuration(elapsed), nil, nil, nil, 1, 1, 1)
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
    events:RegisterEvent("PLAYER_XP_UPDATE")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", function(_, event, unit)
        if event == "PLAYER_XP_UPDATE" and (unit == nil or unit == "player") then
            OnXP()
        else
            Refresh()
        end
    end)

    -- Baseline: XP at login is not gained XP.
    local xp, max = UnitXP("player"), UnitXPMax("player")
    if not IsSecret(xp) and not IsSecret(max) then lastXP, lastMax = xp, max end

    self.UpdateXPPerHour = Refresh
    self.ResetXPPerHour = Reset
end

function ScarletUI:ToggleXPPerHour()
    local global = self.db.global
    global.xpPerHour = not global.xpPerHour
    if self.UpdateXPPerHour then self.UpdateXPPerHour() end
    self:Print("XP per hour readout " .. (global.xpPerHour and "on." or "off."))
end
