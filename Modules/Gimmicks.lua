-- Gimmicks: shows for lucky procs, just for fun. Each is off by default with
-- its own toggle on the Gimmicks settings page; their sounds share one toggle.
--   Seal Slots  Forever, Retribution Paladin with Unsealed Wrath: a slot
--               machine for the seal stacks a twist spends. It was the
--               standalone SealSlots addon.
--   Windfury    every client: "WINDFURY!" slams onto the screen when a
--               Windfury proc gives extra attacks, with what they hit for.
-- Plain frames with no secure children, so they show and hide in combat.

local Gimmicks = {}
ScarletUI.Gimmicks = Gimmicks

local IsSecret = issecretvalue or function() return false end
-- Sounds\*.ogg, built by tools\make-sounds.py. The game only finds new sound
-- files after a full restart.
local SOUNDS = "Interface\\AddOns\\ScarletUI\\Sounds\\"
local GOLD, CRIT, GRAY = { 1, 0.82, 0 }, { 1, 0.3, 0.1 }, { 0.6, 0.6, 0.6 }

local function Settings() return ScarletUI.db.global.gimmicks end
local function Slots() return Settings().sealSlots end

local played = {} -- name = when it last played: things landing together make one sound
local function Sound(name)
    local now = GetTime()
    if not Settings().sound or played[name] == now then return end
    played[name] = now
    local _, handle = PlaySoundFile(SOUNDS .. name .. ".ogg", "SFX")
    return handle
end

-- One-shot animation on a region; alpha returns to 0 unless `stay`.
local function Animate(region, stay)
    local group = region:CreateAnimationGroup()
    group:SetToFinalAlpha(not stay)
    return group
end

local function Scale(group, from, to, duration, order)
    local scale = group:CreateAnimation("Scale")
    scale:SetScaleFrom(from, from)
    scale:SetScaleTo(to, to)
    scale:SetDuration(duration)
    scale:SetOrder(order or 1)
    return scale
end

local function Fade(group, from, to, duration)
    local alpha = group:CreateAnimation("Alpha")
    alpha:SetFromAlpha(from)
    alpha:SetToAlpha(to)
    alpha:SetDuration(duration)
end

-- Sideways shake: `size` pixels out, back across, and home.
local function Shake(frame, size, steps)
    local group = frame:CreateAnimationGroup()
    for i = 1, steps do
        local move = group:CreateAnimation("Translation")
        local reach = (i == 1 or i == steps) and size or 2 * size
        move:SetOffset(i % 2 == 1 and reach or -reach, 0)
        move:SetDuration(0.04)
        move:SetOrder(i)
    end
    return group
end

-- A starburst that spins out and fades, centred on `parent`.
local function Burst(parent, size, r, g, b)
    local burst = parent:CreateTexture(nil, "OVERLAY")
    burst:SetTexture("Interface\\Cooldown\\star4")
    burst:SetBlendMode("ADD")
    burst:SetVertexColor(r, g, b)
    burst:SetSize(size, size)
    burst:SetPoint("CENTER")
    burst:SetAlpha(0)
    local group = Animate(burst)
    Scale(group, 0.3, 1.5, 0.7)
    Fade(group, 1, 0, 0.7)
    local turn = group:CreateAnimation("Rotation")
    turn:SetDegrees(-200)
    turn:SetDuration(0.7)
    return group
end

-- Text that slams in: it sits on a 1x1 holder whose scale drops from SLAM to 1
-- (Slam, then Slammed from OnUpdate). A Scale animation on text left it bigger
-- every time.
local SLAM = 3
local function Slam(holder)
    holder:SetScale(SLAM)
    holder.slamAt = GetTime()
end

local function Slammed(holder, now)
    if not holder.slamAt then return end
    local left = 1 - (now - holder.slamAt) / 0.15
    if left <= 0 then left, holder.slamAt = 0, nil end
    holder:SetScale(1 + (SLAM - 1) * left)
end

---------------------------------------------------------------------------
-- Seal Slots: when an Unsealed Wrath twist spends its stored seals, spin the
-- machine and land each reel on what that stack did.
--
-- What Forever shows an addon in combat, from a logged fight (the combat log
-- is closed, and the "Echo of <seal>" buffs holding the stacks are hidden):
--   UNIT_SPELLCAST_SUCCEEDED  seal casts, and Seal of Command's proc
--   PLAYER_SWING              each auto attack as it is made, hit or not
--   UNIT_COMBAT on the target every hit and miss, with no source or spell.
--                             A seal's procs come with the swing; the swing's
--                             own hit or miss shows 0.5 to 1.5 seconds later.
-- So the stacks are counted from seal casts and swings. With a twist waiting,
-- the reels start a second before the next swing is due (PLAYER_SWING gives
-- the swing time) and all stop together on what came with that swing: its
-- holy hits and misses. Out of combat the Echo buffs are readable and put the
-- count back in step.
---------------------------------------------------------------------------

-- The rules. No WoW API here, so the tests can run them.
local ns = {}
Gimmicks.SealSlots = ns

ns.MAX_STACKS = 3
ns.STACK_TIME = 15    -- seconds a stored seal lasts
ns.HIT_WINDOW = 0.15  -- seconds after a swing in which its seal procs land

-- Unsealed Wrath, followed from what the client still shows in combat (the
-- Echo buff itself is hidden there): the last seal cast and each auto attack
-- that lands. `seal` is the last seal cast; with none known yet nothing is
-- stored or spent.

-- The seal and stack count a swing landing with `seal` would spend, if any.
function ns.Twist(state, seal, now)
    local stacks = state.stacks or 0
    if seal and stacks > 0 and now < state.expires and state.seal ~= seal then
        return state.seal, stacks
    end
end

-- Time to twist: a full set of stacks is stored and `seal` is still the one up.
function ns.Ready(state, seal, now)
    return (state.stacks or 0) >= ns.MAX_STACKS and now < state.expires and state.seal == seal
end

-- A swing landed. Returns what it spent, as Twist does.
function ns.Swing(state, seal, now)
    if not seal then return end
    local spentSeal, spent = ns.Twist(state, seal, now)
    local stacks = state.stacks or 0
    if spent or (stacks > 0 and now >= state.expires) then stacks = 0 end
    state.seal, state.stacks = seal, math.min(ns.MAX_STACKS, stacks + 1)
    state.expires = now + ns.STACK_TIME
    return spentSeal, spent
end

-- What the spent stacks did, one entry per stack that showed anything, from
-- what followed the swing on the target, oldest first:
--   { amount =, secret =, crit = }  a holy hit
--   { miss = "DODGE" }              an attack that was avoided
--   { cast = true }                 a cast of the player's whose own hit or miss
--                                   comes next, so that one is not a stack's
-- plainHit: the seal now up (Righteousness) adds a holy hit of its own to the swing.
-- ponytail: the client names no spell on a hit, so which hit is whose is a
-- guess from order; a stray holy tick in the window can fill a reel.
function ns.Procs(events, stacks, plainHit)
    local list, claims = {}, 0
    for _, event in ipairs(events) do
        if event.cast then
            claims = claims + 1
        elseif claims > 0 then
            claims = claims - 1
        else
            list[#list + 1] = event
        end
    end
    if plainHit then
        for i, event in ipairs(list) do
            if not event.miss and not event.crit then
                table.remove(list, i)
                break
            end
        end
    end
    while #list > stacks do table.remove(list) end
    return list
end

-- BUST: nothing hit. JACKPOT: a full set of stacks all hit.
-- MEGA: a jackpot of crits. WIN: anything else.
function ns.Tier(stacks, procs)
    local hits, crits = 0, 0
    for _, proc in ipairs(procs) do
        if not proc.miss then
            hits = hits + 1
            if proc.crit then crits = crits + 1 end
        end
    end
    if hits == 0 then return "BUST" end
    if stacks < ns.MAX_STACKS or hits < stacks then return "WIN" end
    return crits == hits and "MEGA" or "JACKPOT"
end

-- The board. The client hands addons hit amounts as secrets, which can be
-- neither compared nor saved, so spins are ranked by what can be counted:
-- most crits, then most hits, then newest. db.best keeps the BEST best
-- spins ({ crits =, hits =, ... }); db.tally counts every spin by tier.
ns.BEST = 10
function ns.Record(db, entry, tier)
    db.tally = db.tally or {}
    db.tally.spins = (db.tally.spins or 0) + 1
    db.tally[tier] = (db.tally[tier] or 0) + 1
    db.best = db.best or {}
    if entry.hits == 0 then return end
    local at = #db.best + 1
    for i, other in ipairs(db.best) do
        if entry.crits > other.crits or (entry.crits == other.crits and entry.hits >= other.hits) then
            at = i
            break
        end
    end
    table.insert(db.best, at, entry)
    db.best[ns.BEST + 1] = nil
end

-- The slot machine: three reels, one per Unsealed Wrath stack. Built the
-- first time Seal Slots is turned on; BuildMachine defines:
--   ns.Spin(seal, stacks)  starts the reels (seal = spell ID or name of the stored seal)
--   ns.Resolve(procs)      says where they stop: procs[i] = { amount =, crit =,
--                          secret = true when the amount is a secret value }
--                          or { miss = "DODGE" } for an attack that was avoided
--   ns.Miss()              calls the spin off: the swing was avoided, nothing was spent
--   ns.Rest()              back to idle: up and empty, or hidden with show off
--   ns.Off()               hidden, Seal Slots was turned off
--   ns.Stacks(seal, count) the stacks stored so far, shown grayed out between spins
--   ns.Glow(on)            the outline that says a full set of stacks is ready to twist
--   ns.Board()             opens or closes the board of best spins
--   ns.Place()             puts the machine at its saved position
--   ns.Preview(on)         unlocked: stays up to be dragged without Shift
local SIZE, GAP, PAD = 44, 8, 12
local SPEED = 900                  -- reel speed, pixels a second
local MIN_SPIN = 0.7               -- seconds the reels turn at least; they all stop together
local HOLD, FADE = 3, 0.5          -- seconds the result stays, then fades
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull" -- a stack the kill cut off
-- Righteousness, Command, Crusader, Justice, Light, Wisdom, Fury (Forever)
local SEALS = { 21084, 20375, 21082, 20164, 20165, 20166, 1311656 }

local function Icon(spellID)
    return spellID and C_Spell.GetSpellTexture(spellID) or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- A symbol is an icon, lit (the seal procced) or a dark dud (it did not).
local function Show(texture, symbol)
    texture:SetTexture(symbol.icon)
    texture:SetDesaturated(symbol.dud == true)
    local shade = symbol.dud and 0.35 or 1
    texture:SetVertexColor(shade, shade, shade)
end

local function BuildMachine()
    local whirr -- handle of the reels' spinning sound, to cut it when they stop
    local function Quiet()
        if whirr then StopSound(whirr, 80) end
        whirr = nil
    end

    local frame = CreateFrame("Frame", "ScarletUISealSlots", UIParent)
    -- The box is the reels and the same padding on every side; the amounts and
    -- the banner hang below it, as "Crit!" stands above it.
    frame:SetSize(3 * SIZE + 2 * GAP + 2 * PAD, SIZE + 2 * PAD)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.7)

    local banner = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    banner:SetPoint("TOP", frame, "BOTTOM", 0, -24)

    local critShake, jackpotShake = Shake(frame, 3, 4), Shake(frame, 7, 10)

    local bannerPulse = Animate(banner, true)
    bannerPulse:SetLooping("BOUNCE")
    Fade(bannerPulse, 1, 0.35, 0.3) -- a flash, not a Scale: that grows text for good

    local reels = {}
    for i = 1, 3 do
        local reel = CreateFrame("Frame", nil, frame)
        reel:SetSize(SIZE, SIZE)
        reel:SetPoint("TOPLEFT", PAD + (i - 1) * (SIZE + GAP), -PAD)
        reel:SetClipsChildren(true)
        local slot = reel:CreateTexture(nil, "BACKGROUND")
        slot:SetAllPoints()
        slot:SetColorTexture(0.1, 0.1, 0.1, 1)
        -- `a` is the symbol on the line, `b` the one sliding in from above.
        for _, key in ipairs({ "a", "b" }) do
            local texture = reel:CreateTexture(nil, "ARTWORK")
            texture:SetSize(SIZE, SIZE)
            texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            reel[key] = texture
        end

        -- Effects sit outside the reel so its clipping does not cut them.
        local fx = CreateFrame("Frame", nil, frame)
        fx:SetAllPoints(reel)
        fx:SetFrameLevel(reel:GetFrameLevel() + 2)
        reel.fx = fx

        local border = fx:CreateTexture(nil, "ARTWORK")
        border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        border:SetBlendMode("ADD")
        border:SetSize(SIZE * 1.75, SIZE * 1.75)
        border:SetPoint("CENTER")
        reel.border = border
        reel.borderPop = Animate(border, true)
        Scale(reel.borderPop, 1.5, 1, 0.15)

        -- Crit: a spinning starburst behind a "Crit!" stamp that slams in.
        reel.burst = Burst(fx, SIZE * 2.2, 1, 0.7, 0.2)

        -- "Crit!" above the box, over its reel.
        local stamp = CreateFrame("Frame", nil, fx)
        stamp:SetSize(1, 1)
        stamp:SetPoint("CENTER", reel, "TOP", 0, PAD + 11)
        stamp:SetAlpha(0)
        local stampText = stamp:CreateFontString(nil, "OVERLAY")
        stampText:SetFont(STANDARD_TEXT_FONT, 15, "THICKOUTLINE")
        stampText:SetTextColor(unpack(CRIT))
        stampText:SetText("Crit!")
        stampText:SetPoint("CENTER")
        reel.stamp = stamp

        local amount = fx:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        amount:SetPoint("TOP", reel, "BOTTOM", 0, -(PAD + 4))
        reel.amount = amount

        reels[i] = reel
    end

    local pool = {}     -- symbols a spinning reel shows
    local spin          -- the spin in progress: { seal, stacks, landed, procs, hideAt }
    local preview = false

    -- Time to twist: a gold outline pulses around the box. Each side is a line
    -- with a faint wider one behind it, both centred on the box's edge.
    local glow = CreateFrame("Frame", nil, frame)
    glow:SetPoint("TOPLEFT", -2, 2)
    glow:SetPoint("BOTTOMRIGHT", 2, -2)
    glow:Hide()
    for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        for thick, alpha in pairs({ [2] = 1, [10] = 0.2 }) do
            local line = glow:CreateTexture(nil, "OVERLAY")
            line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], alpha)
            line:SetBlendMode("ADD")
            line:SetPoint("TOPLEFT", glow, side[1], -thick / 2, thick / 2)
            line:SetPoint("BOTTOMRIGHT", glow, side[2], thick / 2, -thick / 2)
        end
    end
    local glowPulse = Animate(glow, true)
    glowPulse:SetLooping("BOUNCE")
    Fade(glowPulse, 1, 0.3, 0.5)

    function ns.Glow(on)
        glow:SetShown(on)
        if on then glowPulse:Play() else glowPulse:Stop() end
    end

    -- The board: the best spins on record (ns.Record), opened by a right-click.
    local board = CreateFrame("Frame", "ScarletUISealSlotsBoard", UIParent)
    board:SetFrameStrata("DIALOG")
    board:SetPoint("BOTTOM", frame, "TOP", 0, 10)
    board:SetClampedToScreen(true)
    board:Hide()
    tinsert(UISpecialFrames, "ScarletUISealSlotsBoard") -- Escape closes it
    local boardBg = board:CreateTexture(nil, "BACKGROUND")
    boardBg:SetAllPoints()
    boardBg:SetColorTexture(0, 0, 0, 0.85)
    local boardTitle = board:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boardTitle:SetPoint("TOP", 0, -PAD)
    boardTitle:SetText("Best Spins")
    local boardTally = board:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    boardTally:SetPoint("TOP", boardTitle, "BOTTOM", 0, -4)
    local ROW, HEAD = 14, 40
    local columns, boardWidth = {}, 2 * PAD
    for i, width in ipairs({ 20, 100, 120, 85 }) do -- place, result, seal and stacks, when
        local column = board:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        column:SetJustifyH("LEFT")
        column:SetJustifyV("TOP")
        column:SetWidth(width)
        column:SetSpacing(ROW - 10)
        if i == 1 then
            column:SetPoint("TOPLEFT", PAD, -(PAD + HEAD))
        else
            column:SetPoint("TOPLEFT", columns[i - 1], "TOPRIGHT", 6, 0)
        end
        columns[i] = column
        boardWidth = boardWidth + width + (i > 1 and 6 or 0)
    end
    -- Damage, one cell a row. The client hands addons hit amounts as secrets: they
    -- can be formatted and shown, but not added, compared or saved. So a spin's
    -- amounts are kept as the text to show, for this session only, crits in red.
    local DAMAGE = 130
    local damage = setmetatable({}, { __mode = "k" }) -- entry of best = its text
    local cells = {}
    for i = 1, ns.BEST do
        local cell = board:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell:SetJustifyH("LEFT")
        cell:SetWidth(DAMAGE)
        cell:SetPoint("TOPLEFT", columns[#columns], "TOPRIGHT", 6, -(i - 1) * ROW)
        cells[i] = cell
    end
    boardWidth = boardWidth + 6 + DAMAGE
    local boardNote = board:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    boardNote:SetPoint("BOTTOM", 0, PAD)
    boardNote:SetText("Damage is hidden from addons: shown until you reload, never ranked")

    local function Board()
        local best, tally = Slots().best or {}, Slots().tally or {}
        boardTally:SetText(not tally.spins and "No spins yet"
            or string.format("%d spins    %d holy jackpots    %d jackpots", tally.spins, tally.MEGA or 0, tally.JACKPOT or 0))
        local text = { {}, {}, {}, {} }
        for i, entry in ipairs(best) do
            local plain, result = entry.hits - entry.crits, {}
            if entry.crits > 0 then result[#result + 1] = entry.crits .. (entry.crits == 1 and " crit" or " crits") end
            if plain > 0 then result[#result + 1] = plain .. (plain == 1 and " hit" or " hits") end
            local color = entry.tier == "MEGA" and "|cffff4d1a" or entry.tier == "JACKPOT" and "|cffffd100" or "|cffffffff"
            text[1][i] = i .. "."
            text[2][i] = color .. table.concat(result, ", ") .. "|r"
            text[3][i] = entry.seal .. " x" .. entry.stacks
            text[4][i] = date("%b %d %H:%M", entry.time)
        end
        for i, column in ipairs(columns) do column:SetText(table.concat(text[i], "\n")) end
        for i, cell in ipairs(cells) do
            local shown = best[i] and damage[best[i]]
            if not (shown and pcall(cell.SetText, cell, shown)) then cell:SetText(best[i] and "-" or "") end
        end
        board:SetSize(boardWidth, 2 * PAD + HEAD + #best * ROW + 18)
    end

    function ns.Board()
        board:SetShown(not board:IsShown())
        if board:IsShown() then Board() end
    end

    local function Reset()
        Quiet()
        banner:SetText("")
        bannerPulse:Stop()
        frame:SetAlpha(1)
        for _, reel in ipairs(reels) do
            reel.spinning, reel.final, reel.landing, reel.proc = nil, nil, nil, nil
            reel.a:SetTexture(nil)
            reel.b:SetTexture(nil)
            reel.border:SetAlpha(0)
            reel.stamp:SetAlpha(0)
            reel.stamp:SetScale(1)
            reel.stamp.slamAt = nil
            reel.amount:SetText("")
        end
    end

    -- Between spins each stored stack sits in its slot as its seal, grayed out.
    local stored = {}
    local function Stacked()
        for i, reel in ipairs(reels) do
            reel.a:SetPoint("TOPLEFT", 0, 0)
            reel.a:SetTexture(i <= (stored.count or 0) and Icon(stored.seal) or nil)
            reel.a:SetDesaturated(true)
            reel.a:SetVertexColor(0.7, 0.7, 0.7)
        end
    end

    function ns.Stacks(seal, count)
        stored.seal, stored.count = seal, count
        if not spin then Stacked() end
    end

    function ns.Rest()
        spin = nil
        Reset()
        Stacked()
        if preview then
            banner:SetText("Unlocked")
            banner:SetTextColor(unpack(GRAY))
        end
        frame:SetShown(preview or (Slots().show and ns.Active()))
    end

    function ns.Miss()
        if not spin then return end
        Quiet()
        for _, reel in ipairs(reels) do
            reel.spinning = nil
            reel.a:SetTexture(nil)
            reel.b:SetTexture(nil)
        end
        banner:SetText("Missed")
        banner:SetTextColor(unpack(GRAY))
        spin.hideAt = GetTime() + 1
    end

    local function Finish()
        local tier = ns.Tier(spin.stacks, spin.procs)
        -- Forever hands addons hit amounts as secrets: they can be shown, not added.
        local total, known, hits, crits = 0, true, 0, 0
        for _, proc in ipairs(spin.procs) do
            if not proc.miss then
                hits = hits + 1
                if proc.crit then crits = crits + 1 end
                if proc.secret then known = false else total = total + proc.amount end
            end
        end
        local text = known and tostring(total) or (hits .. " / " .. spin.stacks)
        local color = GOLD
        if tier == "BUST" then
            text, color = "Bust", GRAY
        elseif tier == "JACKPOT" then
            text = "JACKPOT!  " .. (known and total or "")
        elseif tier == "MEGA" then
            text, color = "HOLY JACKPOT!  " .. (known and total or ""), CRIT
        end
        banner:SetText(text)
        banner:SetTextColor(unpack(color))
        if tier == "JACKPOT" or tier == "MEGA" then
            bannerPulse:Play()
            jackpotShake:Play()
            Sound(tier == "MEGA" and "mega" or "jackpot")
        end
        if not spin.staged then
            local seal = type(spin.seal) == "number" and C_Spell.GetSpellName(spin.seal) or spin.seal
            local entry = { crits = crits, hits = hits, stacks = spin.stacks, tier = tier,
                seal = tostring(seal):gsub("^Seal of ", ""), time = time() }
            local formats, amounts = {}, {}
            for _, proc in ipairs(spin.procs) do
                if not proc.miss then
                    formats[#formats + 1] = proc.crit and "|cffff4d1a%.0f|r" or "%.0f"
                    amounts[#amounts + 1] = proc.amount
                end
            end
            local ok, shown = pcall(string.format, table.concat(formats, "  "), unpack(amounts))
            if ok then damage[entry] = shown end
            ns.Record(Slots(), entry, tier)
            if board:IsShown() then Board() end
            if tier == "MEGA" then
                -- A keepsake, once the stamps have landed and the banner's flash is back at full.
                C_Timer.After(0.6, Screenshot)
            end
        end
        spin.hideAt = GetTime() + HOLD
    end

    local function Land(reel)
        reel.spinning = nil
        reel.a:SetPoint("TOPLEFT", 0, 0)
        reel.b:SetTexture(nil)
        Quiet()
        Sound("stop")
        local proc = reel.proc
        if not proc or proc.miss then
            -- A dark reel: the stack did not proc, or its attack was avoided.
            reel.amount:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
            reel.amount:SetTextColor(unpack(GRAY))
            -- "DODGE" from the client reads "Dodge"
            local avoided = proc and proc.miss:sub(1, 1) .. proc.miss:sub(2):lower()
            reel.amount:SetText(avoided or (spin.dead and "Dead" or "Dud"))
        else
            local color = proc.crit and CRIT or GOLD
            reel.border:SetVertexColor(unpack(color))
            reel.border:SetAlpha(1)
            reel.borderPop:Play()
            reel.amount:SetFont(STANDARD_TEXT_FONT, proc.crit and 16 or 12, "OUTLINE")
            reel.amount:SetTextColor(unpack(color))
            if not pcall(reel.amount.SetText, reel.amount, proc.amount) then reel.amount:SetText("") end
            if proc.crit then
                reel.stamp:SetAlpha(1)
                Slam(reel.stamp)
                reel.burst:Play()
                critShake:Play()
            end
            Sound(proc.crit and "crit" or "win")
        end
        spin.landed = spin.landed + 1
        if spin.landed == spin.stacks then Finish() end
    end

    frame:SetScript("OnUpdate", function(_, elapsed)
        if not spin then return end
        local now = GetTime()
        for _, reel in ipairs(reels) do
            Slammed(reel.stamp, now)
            if reel.spinning then
                reel.offset = reel.offset + SPEED * elapsed
                while reel.spinning and reel.offset >= SIZE do
                    reel.offset = reel.offset - SIZE
                    Show(reel.a, reel.next)
                    if reel.landing then
                        Land(reel)
                    else
                        -- Past its stop time the reel keeps turning until the result is in.
                        reel.landing = now >= reel.stopAt and reel.final ~= nil
                        reel.next = reel.landing and reel.final or pool[math.random(#pool)]
                        Show(reel.b, reel.next)
                    end
                end
                if reel.spinning then
                    reel.a:SetPoint("TOPLEFT", 0, -reel.offset)
                    reel.b:SetPoint("TOPLEFT", 0, SIZE - reel.offset)
                end
            end
        end
        if spin.hideAt and now >= spin.hideAt and not preview then
            local left = 1 - (now - spin.hideAt) / FADE
            if left <= 0 or Slots().show then
                ns.Rest()
            else
                frame:SetAlpha(left)
            end
        end
    end)

    function ns.Spin(seal, stacks)
        Reset()
        wipe(pool)
        for _, id in ipairs(SEALS) do
            if C_Spell.GetSpellTexture(id) then pool[#pool + 1] = { icon = Icon(id) } end
        end
        pool[#pool + 1] = { icon = Icon(seal), dud = true }
        pool[#pool + 1] = { icon = Icon(seal) }
        spin = { seal = seal, stacks = stacks, landed = 0, procs = {} }
        local now = GetTime()
        for i = 1, stacks do
            local reel = reels[i]
            reel.spinning, reel.offset = true, 0
            reel.stopAt = now + MIN_SPIN
            reel.next = pool[math.random(#pool)]
            Show(reel.b, reel.next)
        end
        whirr = Sound("spin")
        frame:Show()
    end

    -- dead: the target died, so reels with nothing to show land on a skull and
    -- say "Dead" instead of "Dud".
    -- staged: a /sealslots test spin, which takes no screenshot and is not recorded.
    function ns.Resolve(procs, dead, staged)
        if not spin then return end
        spin.procs, spin.dead, spin.staged = procs, dead, staged
        for i = 1, spin.stacks do
            local proc = procs[i]
            reels[i].proc = proc
            reels[i].final = dead and not proc and { icon = SKULL }
                or { icon = Icon(spin.seal), dud = proc == nil or proc.miss ~= nil }
        end
    end

    function ns.Place()
        local pos = Slots().pos
        frame:ClearAllPoints()
        frame:SetPoint(pos and pos[1] or "CENTER", UIParent, pos and pos[1] or "CENTER", pos and pos[2] or 0, pos and pos[3] or -160)
    end

    -- Out of combat the box takes right-clicks, for the board, and lets left-clicks
    -- through to the world behind it; in combat every click goes through. The
    -- handle over it takes the mouse while Shift is held or it is unlocked
    -- (/sealslots), to drag it. Should the client lack SetPassThroughButtons, only
    -- the handle takes clicks: the board is then a Shift-right-click.
    local handle = CreateFrame("Frame", nil, frame)
    handle:SetAllPoints()
    handle:EnableMouse(false)
    frame:SetMovable(true)
    local dragging, passing = false, false
    local function Mouse(_, event)
        local fighting = event == "PLAYER_REGEN_DISABLED" or InCombatLockdown()
        if fighting then board:Hide() end
        if dragging then return end -- Shift let go mid-drag: wait for the drop
        -- Which buttons pass through cannot be changed in combat, so it is set once.
        if not passing and not fighting and frame.SetPassThroughButtons then
            frame:SetPassThroughButtons("LeftButton")
            passing = true
        end
        handle:EnableMouse(preview or IsShiftKeyDown())
        frame:EnableMouse(passing and not fighting)
    end

    local function Click(_, button)
        if button == "RightButton" then ns.Board() end
    end
    frame:SetScript("OnMouseUp", Click)
    handle:SetScript("OnMouseUp", Click)

    function ns.Preview(on)
        preview = on
        Mouse()
        if on or not spin then
            ns.Rest()
        else
            spin.hideAt = spin.hideAt and GetTime()
        end
    end

    function ns.Off()
        preview = false
        Mouse()
        board:Hide()
        ns.Glow(false)
        ns.Rest()
    end

    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function()
        dragging = true
        frame:StartMoving()
    end)
    handle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        Slots().pos = { point, x, y }
        dragging = false
        Mouse()
    end)
    frame:RegisterEvent("MODIFIER_STATE_CHANGED")
    frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", Mouse)
end

-- Detection: following the stacks and catching the twist.
local PHYSICAL, HOLY = 1, 2
-- Echo buff -> the seal it stores: Fury, Command, Righteousness, Justice, Light, Wisdom
local ECHOES = {
    [1311701] = 1311656, [1311703] = 20375, [1311704] = 21084,
    [1311705] = 20164, [1328198] = 20165, [1328206] = 20166,
}
local SOC_PROC = 20424 -- Seal of Command's proc: named like the seal, but not a seal cast
-- Casts whose own hit or miss on the target follows them.
-- ponytail: the ones in the logged fight; add any that turn up as stray reels.
local CLAIMS = { Judgement = true, ["Holy Strike"] = true }
local AVOIDED = { MISS = true, DODGE = true, PARRY = true }
local RIGHTEOUSNESS = "Seal of Righteousness" -- adds a holy hit of its own to every swing
local WHITE_WAIT = 1.8 -- seconds to wait for a swing's own hit or miss before calling it a hit
-- A swing's own hit or miss shows when its animation connects: 0.39s after
-- PLAYER_SWING at the soonest in the logged fights. With others on the target,
-- a physical hit or miss sooner than this is theirs.
-- ponytail: one of theirs after it still passes for the swing's; following the
-- Echo buff itself (see AuraProbe) would end the guessing.
local OWN_AFTER = 0.35
local LOG_LINES = 3000

local activeSeal   -- name of the last seal cast; every rank shares it
local state = {}   -- the stored seal: { seal =, stacks =, expires = }
local seen = {}    -- the last few seconds on the target, as ns.Procs takes them, each with its time `t`
local swing        -- the last auto attack until its result is known: { t =, seal =, stacks = if it spins }
local nextAt       -- when the next auto attack is due, from the last one's swing time
local rolling      -- reels started ahead of that swing: { seal =, stacks = }
local LEAD = 1      -- seconds before the swing is due that the reels start
local GIVE_UP = 2.5 -- seconds past due before reels with no swing are called off
local lastEchoLine

local function Print(...) print("|cffffd100Seal Slots|r", ...) end

-- ponytail: always-on record of what the client showed while Seal Slots is on,
-- the last LOG_LINES lines in ScarletUIDB (global.gimmicks.sealSlots.log).
-- Remove once detection is confirmed in game.
local function Log(...)
    local log = Slots().log
    if not log then return end
    local parts = { string.format("%.2f", GetTime()) }
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        parts[#parts + 1] = IsSecret(value) and "SECRET" or tostring(value)
    end
    if #log >= LOG_LINES then table.remove(log, 1) end
    log[#log + 1] = table.concat(parts, " ")
end

-- Only a paladin with Unsealed Wrath has anything to spin.
local TALENT = 1310735
local wasActive

-- Points spent on Unsealed Wrath in the active spec's talent tree, the number
-- its tooltip shows as "Rank 0/1". Errors while the talents are not loaded.
local function TalentRank()
    local config = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(C_SpecializationInfo.GetActiveSpecGroup())
    for _, tree in ipairs(C_Traits.GetConfigInfo(config).treeIDs) do
        for _, node in ipairs(C_Traits.GetTreeNodes(tree)) do
            local info = C_Traits.GetNodeInfo(config, node)
            for _, entry in ipairs(info.entryIDs) do
                local definition = C_Traits.GetDefinitionInfo(C_Traits.GetEntryInfo(config, entry).definitionID)
                if definition.spellID == TALENT then return info.ranksPurchased end
            end
        end
    end
end

function ns.Active()
    return wasActive == true
end

-- Talents changed: show or hide the idle machine. The talent tree decides;
-- the spellbook only stands in while the tree cannot be read.
local function Gate()
    local active, rank = false, nil
    if select(2, UnitClass("player")) == "PALADIN" then
        local ok, found = pcall(TalentRank)
        if ok and type(found) == "number" then
            rank, active = found, found > 0
        else
            local known
            ok, known = pcall(C_SpellBook.IsSpellKnown, TALENT)
            active = ok and not IsSecret(known) and known == true
        end
    end
    if active == wasActive then return end
    wasActive = active
    Log("active", active, "rank", rank)
    ns.Rest()
end

local function Note(event)
    event.t = GetTime()
    while seen[1] and event.t - seen[1].t > 3 do table.remove(seen, 1) end
    seen[#seen + 1] = event
end

-- ponytail: in the logged fights a holy hit of some other source lands on the
-- target every PULSE seconds. A hit that far after an earlier holy hit (one
-- that was not a cast's own) is taken for it; a seal proc that happens to
-- land PULSE seconds after a stray holy hit is dropped with it.
local PULSE = 2
local function Pulse(event)
    for i, earlier in ipairs(seen) do
        local before = seen[i - 1]
        if earlier.crit ~= nil and math.abs(event.t - earlier.t - PULSE) <= 0.08
            and not (before and before.cast and before.t == earlier.t) then
            return true
        end
    end
end

-- What showed on the target with that swing, less one pulse. Events of the
-- swing's own frame share its time, whichever side of PLAYER_SWING they arrived on.
local function With(this)
    local list, pulsed = {}, false
    for _, event in ipairs(seen) do
        if event.t >= this.t and event.t - this.t <= ns.HIT_WINDOW then
            if not pulsed and event.crit ~= nil and Pulse(event) then
                pulsed = true
            else
                list[#list + 1] = event
            end
        end
    end
    return list
end

-- The idle machine shows the stacks stored so far, and its outline is lit
-- while a full set waits for a twist. Checked whenever the stacks or the seal
-- may have changed, and when they run out.
local lit, shownSeal, shownCount, watching
local function Ready()
    if not Slots().enabled then return end -- a timer from before it was turned off
    local now = GetTime()
    local count = ns.Active() and state.expires and now < state.expires and state.stacks or 0
    if count > 0 and state.expires ~= watching then
        watching = state.expires
        C_Timer.After(watching - now + 0.05, Ready)
    end
    if count ~= shownCount or state.seal ~= shownSeal then
        shownCount, shownSeal = count, state.seal
        ns.Stacks(state.seal, count)
    end
    local on = count > 0 and ns.Ready(state, activeSeal, now)
    if on == lit then return end
    lit = on
    ns.Glow(on)
end

-- The swing's result is known: it landed (stores a stack, spends on a twist) or not.
local function Settle(landed)
    local this = swing
    swing = nil
    Log("swing", landed and "landed" or "avoided", this.seal, "had", state.seal, state.stacks)
    -- Out of combat the buffs already say what is stored.
    if landed and InCombatLockdown() then
        ns.Swing(state, this.seal, this.t)
        Ready()
    end
    if not this.stacks then return end
    if not landed then
        ns.Miss()
        return
    end
    local procs = ns.Procs(With(this), this.stacks, this.seal == RIGHTEOUSNESS)
    local reels = {}
    for i, proc in ipairs(procs) do reels[i] = proc.miss or (proc.crit and "crit" or "hit") end
    -- A target the swing killed takes no more procs: those stacks did not fail a roll.
    local ok, dead = pcall(function() return not UnitExists("target") or UnitIsDead("target") end)
    dead = ok and not IsSecret(dead) and dead
    Log("reels", table.concat(reels, ","), "dead", dead)
    ns.Resolve(procs, dead)
end

-- The reels start early, so they are already turning when the swing lands: a
-- twist is waiting and the next auto attack is nearly due. Also calls them off
-- when the twist is undone (seal changed back, stacks ran out) before the swing.
local function Anticipate()
    if not Slots().enabled then return end -- a timer from before it was turned off
    local now = GetTime()
    local spent, stacks = ns.Twist(state, activeSeal, now)
    local fighting = InCombatLockdown() -- between pulls no swing is on its way
    if rolling then
        if not spent or not fighting then
            rolling = nil
            ns.Rest()
        end
        return
    end
    if not spent or not fighting or not nextAt or now < nextAt - LEAD - 0.05 or now > nextAt + GIVE_UP or not ns.Active() then
        return
    end
    local this = { seal = spent, stacks = stacks }
    rolling = this
    Log("ROLL", spent, stacks)
    ns.Spin(spent, stacks)
    C_Timer.After(nextAt - now + GIVE_UP, function()
        if rolling == this then -- no swing came (out of range, target gone)
            rolling = nil
            ns.Rest()
        end
    end)
end

local function OnSwing(duration, swingType)
    if not IsSecret(swingType) and swingType == 2 then return end -- ranged
    if not ns.Active() then return end
    if swing then Settle(true) end -- its result never showed (a killing blow)
    local now = GetTime()
    local this = { t = now, seal = activeSeal }
    swing = this
    nextAt = not IsSecret(duration) and type(duration) == "number" and now + duration or nil
    if nextAt then C_Timer.After(math.max(0, duration - LEAD), Anticipate) end
    local spent, stacks = ns.Twist(state, activeSeal, now)
    local early = rolling
    rolling = nil
    if not spent then
        if early then ns.Rest() end
    else
        this.stacks = stacks
        Log("SPIN", spent, stacks)
        -- Without reels already turning for it (the first swing of a fight), they start here.
        if not (early and early.seal == spent and early.stacks == stacks) then ns.Spin(spent, stacks) end
        -- Anything that came with the swing means it landed: no need to wait for its own hit.
        C_Timer.After(ns.HIT_WINDOW + 0.05, function()
            if swing == this and #With(this) > 0 then Settle(true) end
        end)
    end
    C_Timer.After(WHITE_WAIT, function()
        if swing == this then Settle(true) end
    end)
end

local function OnCast(spellID)
    local name = not IsSecret(spellID) and C_Spell.GetSpellName(spellID)
    Log("cast", spellID, name)
    if not name then return end
    -- ponytail: seals are told by their English name, so every rank and any
    -- seal Forever adds counts. Other locales need a spell ID list.
    if spellID ~= SOC_PROC and name:find("^Seal of ") then
        activeSeal = name
        Anticipate()
    elseif spellID == SOC_PROC or CLAIMS[name] then
        Note({ cast = true })
    end
end

local function OnHit(action, indicator, amount, school)
    Log("hit", action, indicator, amount, school)
    -- The amount is a secret on Forever; the rest is readable.
    if IsSecret(action) or IsSecret(indicator) or IsSecret(school) then return end
    if school == HOLY then
        if action == "WOUND" then
            Note({ amount = amount, secret = IsSecret(amount), crit = indicator == "CRITICAL" })
        end
    elseif school == PHYSICAL then
        local now, last = GetTime(), seen[#seen]
        local own = swing and now - swing.t >= OWN_AFTER
        if action == "WOUND" then
            if own then Settle(true) end
        elseif AVOIDED[action] then
            -- A cast's or a proc's miss comes with it; the swing's own comes late.
            local claimed = last and last.cast and now - last.t < 0.05
            if own and not claimed then
                Settle(false)
            else
                Note({ miss = action })
            end
        end
    end
end

-- ponytail: a probe, it only logs. In combat the Echo buff cannot be found by
-- its spell, but it might be followed by the instance ID read out of combat.
-- This records what a fight shows of that; build on it or remove it.
local echoID
local function AuraProbe(info)
    if not InCombatLockdown() then return end
    local parts = {}
    local function add(mark, value) parts[#parts + 1] = mark .. (IsSecret(value) and "SECRET" or tostring(value)) end
    local ok = pcall(function()
        info = info or {}
        add("full ", info.isFullUpdate)
        for _, id in ipairs(info.removedAuraInstanceIDs or {}) do add("-", id) end
        for _, id in ipairs(info.updatedAuraInstanceIDs or {}) do add("~", id) end
        for _, aura in ipairs(info.addedAuras or {}) do add("+", aura.auraInstanceID) add("spell ", aura.spellId) end
        add("echo ", echoID)
        local echo = echoID and C_UnitAuras.GetAuraDataByAuraInstanceID("player", echoID)
        add("stacks ", echo and echo.applications)
    end)
    Log("aura", ok, unpack(parts))
end

-- Out of combat the Echo buffs and the seal are readable: put the count back in step.
local function Resync()
    if InCombatLockdown() then return end
    echoID = nil
    local had = tostring(state.seal) .. " " .. tostring(state.stacks)
    local line = ""
    state.stacks = 0
    for id, seal in pairs(ECHOES) do
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        local name = C_Spell.GetSpellName(seal)
        if ok and aura and name and not IsSecret(aura) and not IsSecret(aura.applications) and not IsSecret(aura.expirationTime) then
            state.seal, state.stacks, state.expires = name, math.max(1, aura.applications or 0), aura.expirationTime
            echoID = aura.auraInstanceID
            line = line .. id .. "x" .. state.stacks .. " "
        end
    end
    for i = 1, 40 do
        local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
        if not ok or not aura then break end
        local name = aura.name
        if name and not IsSecret(name) and name:find("^Seal of ") then activeSeal = name end
    end
    if line ~= lastEchoLine then
        lastEchoLine = line
        Log("echoes", line, "counted", had, "seal", activeSeal)
    end
end

local events -- detection's event frame, made the first time Seal Slots is on
local TALENTS = { SPELLS_CHANGED = true, TRAIT_CONFIG_UPDATED = true, TRAIT_CONFIG_LIST_UPDATED = true, ACTIVE_TALENT_GROUP_CHANGED = true }
local EVENTS = { "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_SWING",
    "SPELLS_CHANGED", "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "ACTIVE_TALENT_GROUP_CHANGED" }

local function OnEvent(_, event, unit, ...)
    if TALENTS[event] then
        Gate()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, spellID = ...
        OnCast(spellID)
    elseif event == "UNIT_COMBAT" then
        OnHit(...)
    elseif event == "UNIT_AURA" then
        Resync()
        AuraProbe(...)
    else
        Log(event, unit, ...)
        if event == "PLAYER_SWING" then
            OnSwing(unit, ...) -- (swingDuration, swingType)
        elseif event == "PLAYER_REGEN_ENABLED" then
            Resync()
            Anticipate() -- the fight ended under reels that were waiting for a swing
        end
    end
    Ready()
end

local moving = false
local function SealSlotsCommand(msg)
    if not Slots().enabled then
        Print("is off. Turn it on in /sui > Gimmicks.")
        return
    end
    msg = msg:lower():match("%S+")
    if msg == "sound" then
        Settings().sound = not Settings().sound
        Print("gimmick sounds", Settings().sound and "on" or "off")
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ScarletUI")
    elseif msg == "show" then
        Slots().show = not Slots().show
        ns.Rest()
        Print(Slots().show and "always shown" or "shown only for a spin")
        LibStub("AceConfigRegistry-3.0"):NotifyChange("ScarletUI")
    elseif msg == "test" then
        local procs = {}
        for _ = 1, 3 do
            local crit = math.random() < 0.3
            if crit or math.random() < 0.6 then
                procs[#procs + 1] = { amount = math.random(80, 160) * (crit and 2 or 1), crit = crit }
            end
        end
        ns.Spin(20375, 3)
        ns.Resolve(procs, nil, true)
    elseif msg == "best" then
        ns.Board()
    elseif msg then
        Print("Hold Shift and drag the machine to move it")
        Print("Right-click it out of combat, or /sealslots best, for your best spins")
        Print("/sealslots - unlock it to drag without Shift, again to lock it")
        Print("/sealslots show - keep it on screen between spins, or only for a spin")
        Print("/sealslots test - spin a made-up result")
        Print("/sealslots sound - gimmick sounds on or off")
    else
        moving = not moving
        ns.Preview(moving)
    end
end

function ScarletUI:SetupSealSlots()
    if self.sealSlotsSupported then
        self:UpdateSealSlots() -- Setup reruns after a settings reset.
        return
    end
    -- Unsealed Wrath is a Forever talent.
    if self:GetWoWVersion() ~= "FOREVER" then return end
    self.sealSlotsSupported = true
    -- While the standalone addon is loaded the machine is left to it; its
    -- position and best spins are taken over once.
    self.sealSlotsStandalone = self:IsAddOnLoaded("SealSlots")
    if self.sealSlotsStandalone then
        local slots, old = Slots(), SealSlotsDB
        if type(old) == "table" and not slots.imported then
            slots.pos, slots.best, slots.tally, slots.imported = old.pos, old.best, old.tally, true
        end
        return
    end
    events = CreateFrame("Frame")
    events:SetScript("OnEvent", OnEvent)
    SLASH_SCARLETUISEALSLOTS1, SLASH_SCARLETUISEALSLOTS2 = "/sealslots", "/slots"
    SlashCmdList.SCARLETUISEALSLOTS = SealSlotsCommand
    self:UpdateSealSlots()
end

-- turnedOn: the player just switched it on, which also switches the
-- standalone addon off from the next reload.
function ScarletUI:UpdateSealSlots(turnedOn)
    if not self.sealSlotsSupported then return end
    if self.sealSlotsStandalone then
        if turnedOn then
            (C_AddOns and C_AddOns.DisableAddOn or DisableAddOn)("SealSlots") -- for every character
            Print("The SealSlots addon is now turned off. /reload to switch to Scarlet UI's slot machine.")
        end
        return
    end
    local slots = Slots()
    if slots.enabled then
        if not ns.Spin then BuildMachine() end
        slots.log = slots.log or {}
        for _, event in ipairs(EVENTS) do pcall(events.RegisterEvent, events, event) end
        events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
        events:RegisterUnitEvent("UNIT_COMBAT", "target")
        events:RegisterUnitEvent("UNIT_AURA", "player")
        ns.Place()
        Gate()
        Resync()
        ns.Rest()
        Ready()
    else
        events:UnregisterAllEvents()
        swing, rolling, wasActive = nil, nil, nil
        if ns.Off then ns.Off() end
        lit, shownSeal, shownCount = nil, nil, nil
    end
end

---------------------------------------------------------------------------
-- Windfury: "WINDFURY!" and the Windfury icon slam onto the screen when a
-- proc gives extra attacks, with what they hit for below. Another proc while
-- it is up counts on ("WINDFURY! x2").
--
-- Era, TBC, and Mists read the combat log. Forever and Retail close it to
-- addons, so there the proc is the player's cast of a Windfury spell they do
-- not know themselves (the proc, not the totem or the weapon imbue), and no
-- damage is shown.
-- ponytail: that cast is unverified on Forever and Retail; if nothing shows,
-- a /run probe of UNIT_SPELLCAST_SUCCEEDED in a fight would tell.
---------------------------------------------------------------------------

-- The combat log rule. No WoW API here, so the tests can run it.
-- A proc is SPELL_EXTRA_ATTACKS from a Windfury spell followed by that many
-- main-hand swings (the totem; the weapon in Era), or the weapon's own
-- Windfury Attack hits (TBC, Mists). Takes one of the player's events as
-- CombatLogGetCurrentEventInfo returns it; `wf` carries the swings still owed
-- between calls. Returns the hit to show if this event is one
-- ({ amount =, crit = } or { miss = "DODGE" }), and whether it starts a proc.
local SAME_PROC = 0.3 -- seconds within which Windfury events are one proc
-- ponytail: an owed swing is the first main-hand swing within this many
-- seconds; a weapon fast enough to swing again sooner would be taken for it.
local SWING_WAIT = 1
function Gimmicks.WindfuryEvent(wf, now, ...)
    local subevent = select(2, ...)
    if subevent == "SWING_DAMAGE" or subevent == "SWING_MISSED" then
        local damage = subevent == "SWING_DAMAGE"
        local offHand = select(damage and 21 or 13, ...)
        if (wf.owed or 0) < 1 or now - wf.last > SWING_WAIT or offHand then return end
        wf.owed = wf.owed - 1
        if damage then return { amount = select(12, ...), crit = select(18, ...) } end
        return { miss = select(12, ...) }
    end
    local spell, hit = select(13, ...), nil
    if type(spell) ~= "string" or not spell:find("Windfury") then return end
    if subevent == "SPELL_DAMAGE" then
        hit = { amount = select(15, ...), crit = select(21, ...) }
    elseif subevent == "SPELL_MISSED" then
        hit = { miss = select(15, ...) }
    elseif subevent ~= "SPELL_EXTRA_ATTACKS" then
        return
    end
    local fresh = not wf.last or now - wf.last > SAME_PROC
    if fresh then wf.owed = 0 end
    wf.last = now
    -- A Windfury hit is one of the extra attacks, if any are owed.
    wf.owed = hit and math.max(0, wf.owed - 1) or wf.owed + (select(15, ...) or 1)
    return hit, fresh
end

local WF_HOLD, WF_FADE, WF_HITS = 2, 0.5, 6 -- seconds up, seconds fading, hits listed
local SKY = { 0.45, 0.8, 1 }
local wfFrame, wfHolder, wfTitle, wfHits, wfBurst, wfShake, wfBg, wfEvents
local wfShownAt, wfCount, wfUnlocked = nil, 0, false
local wfList, wfState, player = {}, {}, nil

local function WindfuryRedraw()
    wfTitle:SetText(wfCount > 1 and ("WINDFURY! x" .. wfCount) or "WINDFURY!")
    local parts = {}
    for _, hit in ipairs(wfList) do
        if hit.miss then
            parts[#parts + 1] = "|cff999999" .. hit.miss:sub(1, 1) .. hit.miss:sub(2):lower() .. "|r"
        else
            parts[#parts + 1] = (hit.crit and "|cffff4d1a" or "|cffffd100") .. tostring(hit.amount) .. (hit.crit and "!" or "") .. "|r"
        end
    end
    wfHits:SetText(table.concat(parts, "   "))
end

local function WindfuryProc()
    local now = GetTime()
    if wfShownAt and now - wfShownAt < WF_HOLD + WF_FADE then
        wfCount = wfCount + 1
    else
        wfCount = 1
        wipe(wfList)
    end
    wfShownAt = now
    wfFrame:SetAlpha(1)
    wfFrame:Show()
    Slam(wfHolder)
    wfBurst:Stop()
    wfBurst:Play()
    Sound("windfury")
    WindfuryRedraw()
end

local function WindfuryHit(hit)
    if not wfShownAt then return end
    wfList[#wfList + 1] = hit
    if #wfList > WF_HITS then table.remove(wfList, 1) end
    if hit.crit then wfShake:Play() end
    wfShownAt = GetTime()
    WindfuryRedraw()
end

local function WindfuryPlace()
    local pos = Settings().windfury.pos
    wfFrame:ClearAllPoints()
    wfFrame:SetPoint(pos and pos[1] or "CENTER", UIParent, pos and pos[1] or "CENTER", pos and pos[2] or 0, pos and pos[3] or 160)
end

-- Unlocked (/windfury), it stays up on a dark box to be dragged.
local function WindfuryUnlock(on)
    wfUnlocked = on
    wfFrame:EnableMouse(on)
    wfBg:SetShown(on)
    if on then
        wfCount, wfShownAt = 1, nil
        wipe(wfList)
        WindfuryRedraw()
        wfHits:SetText("Drag to move; /windfury again to lock")
        wfFrame:SetAlpha(1)
        wfFrame:Show()
    else
        wfShownAt = nil
        wfFrame:Hide()
    end
end

local function BuildWindfury()
    local frame = CreateFrame("Frame", "ScarletUIWindfury", UIParent)
    wfFrame = frame
    frame:SetSize(300, 80)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(false)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint()
        Settings().windfury.pos = { point, x, y }
    end)
    frame:Hide()

    wfBg = frame:CreateTexture(nil, "BACKGROUND")
    wfBg:SetAllPoints()
    wfBg:SetColorTexture(0, 0, 0, 0.5)
    wfBg:Hide()

    -- The icon and "WINDFURY!" slam in together around the spot's centre.
    local spot = CreateFrame("Frame", nil, frame)
    spot:SetSize(1, 1)
    spot:SetPoint("CENTER", 0, 12)
    wfHolder = CreateFrame("Frame", nil, frame)
    wfHolder:SetSize(1, 1)
    wfHolder:SetPoint("CENTER", spot)
    wfTitle = wfHolder:CreateFontString(nil, "OVERLAY")
    wfTitle:SetFont(STANDARD_TEXT_FONT, 26, "THICKOUTLINE")
    wfTitle:SetTextColor(unpack(SKY))
    wfTitle:SetPoint("CENTER", 22, 0)
    local icon = wfHolder:CreateTexture(nil, "ARTWORK")
    icon:SetSize(36, 36)
    icon:SetTexture("Interface\\Icons\\Spell_Nature_Windfury")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    icon:SetPoint("RIGHT", wfTitle, "LEFT", -8, 0)
    local fx = CreateFrame("Frame", nil, wfHolder)
    fx:SetAllPoints(icon)
    wfBurst = Burst(fx, 90, SKY[1], SKY[2], SKY[3])

    wfHits = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    wfHits:SetPoint("TOP", spot, "CENTER", 0, -24)
    wfShake = Shake(frame, 4, 6)

    frame:SetScript("OnUpdate", function()
        local now = GetTime()
        Slammed(wfHolder, now)
        if wfUnlocked or not wfShownAt then return end
        local fade = (now - wfShownAt - WF_HOLD) / WF_FADE
        if fade >= 1 then
            wfShownAt = nil
            frame:Hide()
        elseif fade > 0 then
            frame:SetAlpha(1 - fade)
        end
    end)

    wfEvents = CreateFrame("Frame")
    wfEvents:SetScript("OnEvent", function(_, event, _, _, spellID)
        if event == "COMBAT_LOG_EVENT_UNFILTERED" then
            if select(4, CombatLogGetCurrentEventInfo()) ~= player then return end
            local hit, fresh = Gimmicks.WindfuryEvent(wfState, GetTime(), CombatLogGetCurrentEventInfo())
            if fresh then WindfuryProc() end
            if hit then WindfuryHit(hit) end
        elseif not IsSecret(spellID) then -- UNIT_SPELLCAST_SUCCEEDED, Forever and Retail
            local name = C_Spell.GetSpellName(spellID)
            if name and name:find("Windfury") and not IsPlayerSpell(spellID) then WindfuryProc() end
        end
    end)
end

local function WindfuryCommand(msg)
    if not Settings().windfury.enabled then
        ScarletUI:Print("Windfury is off. Turn it on in /sui > Gimmicks.")
        return
    end
    msg = msg:lower():match("%S+")
    if msg == "test" then
        WindfuryProc()
        for _ = 1, math.random(1, 2) do
            local crit = math.random() < 0.3
            WindfuryHit({ amount = math.random(300, 600) * (crit and 2 or 1), crit = crit })
        end
    elseif msg then
        ScarletUI:Print("/windfury - unlock it to drag, again to lock it")
        ScarletUI:Print("/windfury test - show a made-up proc")
    else
        WindfuryUnlock(not wfUnlocked)
    end
end

function ScarletUI:SetupWindfury()
    if not self.windfurySupported then
        self.windfurySupported = true
        SLASH_SCARLETUIWINDFURY1 = "/windfury"
        SlashCmdList.SCARLETUIWINDFURY = WindfuryCommand
    end
    self:UpdateWindfury()
end

function ScarletUI:UpdateWindfury()
    if not Settings().windfury.enabled then
        if wfEvents then
            wfEvents:UnregisterAllEvents()
            WindfuryUnlock(false)
        end
        return
    end
    if not wfFrame then BuildWindfury() end
    player = UnitGUID("player")
    WindfuryPlace()
    if self.retail then
        wfEvents:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    else
        wfEvents:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    end
end
