-- Craft Profit: lists the recipes that make a profit, or break even while
-- still giving a skill-up, from Auctionator prices. Forever only. It shows as
-- a side tab on the profession window and as a pop-up window (/cp). Recipe
-- data only exists while a profession window is open, so each scan is cached
-- per character in db.char.craftProfit.

local CraftProfit = {}
ScarletUI.CraftProfit = CraftProfit

-- Pricing rules with no WoW API calls, so the tests can run them.
CraftProfit.AH_CUT = 0.95
-- ponytail: flat tolerance. A skill-up recipe counts as break-even when it
-- loses less than this share of its reagent cost.
CraftProfit.BREAK_EVEN = 0.10

-- buy(itemID) and sell(itemID) return copper per unit; buy returns nil when unknown.
-- Returns cost, value, profit; cost and profit are nil when a reagent has no price.
function CraftProfit.Evaluate(recipe, buy, sell)
    local cost, missing = 0, nil
    for _, reagent in ipairs(recipe.reagents) do
        local price = buy(reagent.id)
        if price then
            cost = cost + price * reagent.count
        else
            missing = missing or reagent.id
        end
    end
    local value = math.floor((recipe.output and sell(recipe.output) or 0) * recipe.yield)
    if missing then
        return nil, value, nil, missing
    end
    return cost, value, value - cost
end

-- A profit, or break-even while still giving a skill-up.
function CraftProfit.Keep(profit, cost, skillUp)
    if not profit then
        return false
    end
    return profit > 0 or (skillUp and profit >= -cost * CraftProfit.BREAK_EVEN) or false
end

function CraftProfit.Money(copper)
    if not copper then
        return "?"
    end
    local sign = copper < 0 and "-" or ""
    copper = math.floor(math.abs(copper) + 0.5)
    local gold, silver, rest = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
    if gold > 0 then
        return string.format("%s%d|cffffd700g|r %d|cffc7c7cfs|r", sign, gold, silver)
    elseif silver > 0 then
        return string.format("%s%d|cffc7c7cfs|r %d|cffeda55fc|r", sign, silver, rest)
    end
    return string.format("%s%d|cffeda55fc|r", sign, rest)
end

local CALLER = "ScarletUI"
local ICON = "Interface\\Icons\\INV_Misc_Coin_01"
local ROW_H = 18
local COLUMNS = { -144, -74, -4 } -- right edges of Cost, Value, Profit, from the row's right edge
local COLORS = {
    optimal = { 1, 0.5, 0.25 },
    medium = { 1, 1, 0 },
    easy = { 0.25, 0.75, 0.25 },
    trivial = { 0.5, 0.5, 0.5 },
}
local API, T, DIFFICULTY -- set in SetupCraftProfit
local window, requestSync
local lists = {} -- the pop-up window's list and the profession page's list

-- Read through ScarletUI.db each time: a settings reset replaces the tables.
local function Settings() return ScarletUI.db.global.craftProfit end
local function Cache() return ScarletUI.db.char.craftProfit end

-- Vendor price first (Auctionator caches it when you open a merchant), as Auctionator does.
local function Buy(id)
    return API.GetVendorPriceByItemID(CALLER, id) or API.GetAuctionPriceByItemID(CALLER, id)
end

-- The better of the auction price after the cut and the vendor sell price.
local function Sell(id)
    local vendor = select(11, C_Item.GetItemInfo(id)) or 0
    return math.max((API.GetAuctionPriceByItemID(CALLER, id) or 0) * CraftProfit.AH_CUT, vendor)
end

local function ItemName(id)
    return C_Item.GetItemInfo(id) or ("item " .. id)
end

local function Debounce(delay, fn)
    local queued
    return function()
        if queued then return end
        queued = true
        C_Timer.After(delay, function()
            queued = false
            fn()
        end)
    end
end

local function ProfessionNames()
    local names = {}
    for name in pairs(Cache().professions) do names[#names + 1] = name end
    table.sort(names)
    return names
end

-- List panel -------------------------------------------------------------

local function ShowTooltip(row)
    local entry, recipe = row.entry, row.entry.recipe
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(recipe.name)
    for _, reagent in ipairs(recipe.reagents) do
        local price = Buy(reagent.id)
        GameTooltip:AddDoubleLine(("%dx %s"):format(reagent.count, ItemName(reagent.id)),
            price and CraftProfit.Money(price * reagent.count) or "no price", 1, 1, 1, 1, 1, 1)
    end
    if recipe.output then
        GameTooltip:AddDoubleLine(("Makes %gx %s"):format(recipe.yield, ItemName(recipe.output)),
            CraftProfit.Money(entry.value), 0.6, 1, 0.6, 1, 1, 1)
        local age = API.GetAuctionAgeByItemID(CALLER, recipe.output)
        GameTooltip:AddLine(age and ("AH price from %d day(s) ago"):format(age) or "No AH price, using vendor sell price",
            0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine("Click to open the recipe", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local function SortKey(entry)
    return entry.profit or -math.huge
end

-- The selected profession's recipes that pass the filter, best profit first.
local function Entries()
    local prof = Cache().professions[Cache().selected]
    local entries = {}
    if not prof then return nil, entries end
    for _, recipe in ipairs(prof.recipes) do
        local cost, value, profit = CraftProfit.Evaluate(recipe, Buy, Sell)
        local skillUp = recipe.difficulty ~= nil and recipe.difficulty ~= "trivial"
        if Settings().showAll or CraftProfit.Keep(profit, cost, skillUp) then
            entries[#entries + 1] = { recipe = recipe, cost = cost, value = value, profit = profit }
        end
    end
    table.sort(entries, function(a, b)
        local x, y = SortKey(a), SortKey(b)
        if x ~= y then return x > y end
        return a.recipe.name < b.recipe.name
    end)
    return prof, entries
end

local function Row(list, i)
    if list.rows[i] then return list.rows[i] end
    local row = CreateFrame("Button", nil, list.content)
    row:SetHeight(ROW_H)
    row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
    row:SetPoint("RIGHT")
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT", 2, 0)
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", 22, 0)
    row.name:SetPoint("RIGHT", row, "RIGHT", COLUMNS[1] - 70, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.cols = {}
    for c, right in ipairs(COLUMNS) do
        row.cols[c] = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.cols[c]:SetPoint("RIGHT", row, "RIGHT", right, 0)
    end
    row:SetScript("OnEnter", ShowTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnClick", function(self) T.OpenRecipe(self.entry.recipe.id) end)
    list.rows[i] = row
    return row
end

local function RefreshList(list)
    local cache = Cache()
    if not cache.professions[cache.selected] then cache.selected = ProfessionNames()[1] end
    list.dropdown:GenerateMenu()
    list.showAll:SetChecked(Settings().showAll)

    local prof, entries = Entries()
    if prof then
        list.status:SetText(("%d/%d   |cff999999scanned %s ago|r"):format(prof.skill or 0, prof.max or 0,
            SecondsToTime(math.max(time() - prof.time, 1))))
        list.empty:SetText("Nothing profitable or break-even with a skill-up right now.\n"
            .. "Tick Show all to see every recipe by profit, or scan the auction house with Auctionator.")
    else
        list.status:SetText("")
        list.empty:SetText("Open a profession window to scan its recipes.")
    end

    for i, entry in ipairs(entries) do
        local row, recipe = Row(list, i), entry.recipe
        row.entry = entry
        row.icon:SetTexture(recipe.icon)
        row.name:SetText(recipe.name .. ((recipe.skillUps or 0) > 1 and (" (+%d)"):format(recipe.skillUps) or ""))
        row.name:SetTextColor(unpack(COLORS[recipe.difficulty] or { 1, 1, 1 }))
        row.cols[1]:SetText(CraftProfit.Money(entry.cost))
        row.cols[2]:SetText(CraftProfit.Money(entry.value))
        row.cols[3]:SetText(CraftProfit.Money(entry.profit))
        if not entry.profit then
            row.cols[3]:SetTextColor(0.6, 0.6, 0.6)
        elseif entry.profit >= 0 then
            row.cols[3]:SetTextColor(0.3, 1, 0.3)
        else
            row.cols[3]:SetTextColor(1, 0.3, 0.3)
        end
        row:Show()
    end
    for i = #entries + 1, #list.rows do list.rows[i]:Hide() end
    list.content:SetHeight(math.max(#entries * ROW_H, 1))
    list.empty:SetShown(#entries == 0)
end

local function Refresh()
    for _, list in ipairs(lists) do
        if list:IsVisible() then RefreshList(list) end
    end
end

local function CreateList(parent, strata)
    local list = CreateFrame("Frame", nil, parent)
    if strata then list:SetFrameStrata(strata) end
    list.rows = {}

    local dropdown = CreateFrame("DropdownButton", nil, list, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", 12, -6)
    dropdown:SetWidth(160)
    dropdown:SetDefaultText("No professions scanned")
    dropdown:SetupMenu(function(_, root)
        for _, name in ipairs(ProfessionNames()) do
            root:CreateRadio(name, function() return name == Cache().selected end, function()
                Cache().selected = name
                Refresh()
            end)
        end
    end)
    list.dropdown = dropdown

    list.status = list:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    list.status:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)

    list.showAll = CreateFrame("CheckButton", nil, list, "UICheckButtonTemplate")
    list.showAll:SetSize(24, 24)
    list.showAll:SetPoint("TOPRIGHT", -10, -2)
    list.showAll:SetScript("OnClick", function(self)
        Settings().showAll = self:GetChecked()
        Refresh()
    end)
    local label = list:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("RIGHT", list.showAll, "LEFT", -2, 0)
    label:SetText("Show all")

    local scroll = CreateFrame("ScrollFrame", nil, list, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -52)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)
    list.content = CreateFrame("Frame", nil, scroll)
    list.content:SetSize(1, 1)
    scroll:SetScrollChild(list.content)
    scroll:HookScript("OnSizeChanged", function(_, width) list.content:SetWidth(width) end)

    list.empty = scroll:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    list.empty:SetPoint("TOPLEFT", 10, -20)
    list.empty:SetPoint("TOPRIGHT", -10, -20)

    local header = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    header:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 22, 4)
    header:SetText("Recipe")
    for i, text in ipairs({ "Cost", "Value", "Profit" }) do
        local column = list:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        column:SetPoint("BOTTOMRIGHT", scroll, "TOPRIGHT", COLUMNS[i], 4)
        column:SetText(text)
    end

    list:SetScript("OnShow", RefreshList)
    lists[#lists + 1] = list
    return list
end

-- Scanning ---------------------------------------------------------------

local function Scan()
    if not Settings().enabled or (T.IsTradeSkillLinked and T.IsTradeSkillLinked())
        or (T.IsTradeSkillGuild and T.IsTradeSkillGuild()) or (T.IsNPCCrafting and T.IsNPCCrafting()) then
        return
    end
    local prof = T.GetBaseProfessionInfo and T.GetBaseProfessionInfo()
    if not prof or not prof.professionName or prof.professionName == "" then return end
    local child = T.GetChildProfessionInfo and T.GetChildProfessionInfo()
    local skill = (child and (child.skillLevel or 0) > 0) and child or prof

    local recipes = {}
    for _, id in pairs(T.GetAllRecipeIDs()) do -- pairs: Guidelime saw nil gaps on Forever
        local info = T.GetRecipeInfo(id)
        local schematic = info and info.learned ~= false and not info.isDummyRecipe and not info.isRecraft
            and T.GetRecipeSchematic(id, false)
        if schematic then
            local reagents = {}
            for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
                local basic = not Enum.CraftingReagentType or slot.reagentType == Enum.CraftingReagentType.Basic
                local first = slot.reagents and slot.reagents[1]
                if basic and first and first.itemID then
                    reagents[#reagents + 1] = { id = first.itemID, count = slot.quantityRequired }
                end
            end
            local min = schematic.quantityMin or 1
            recipes[#recipes + 1] = {
                id = id,
                name = info.name,
                icon = info.icon,
                difficulty = DIFFICULTY[info.relativeDifficulty],
                skillUps = info.numSkillUps,
                output = schematic.outputItemID,
                yield = (min + (schematic.quantityMax or min)) / 2,
                reagents = reagents,
            }
        end
    end
    if #recipes == 0 then return end -- list not loaded yet

    Cache().professions[prof.professionName] = {
        skill = skill.skillLevel, max = skill.maxSkillLevel, time = time(), recipes = recipes,
    }
    Cache().selected = prof.professionName
    Refresh()
end

-- Profession window page -------------------------------------------------
-- Same approach as WhatsTraining's crafting page on Forever: a side tab that covers the
-- native page, plus a copy of the selected native tab drawn over it to switch back.
-- ponytail: no Gamepad UI handling and the native title/portrait stay as they are.

local function AttachProfessionPage()
    local book = ProfessionsFrame
    if not book.rightProfessionTabs then return end

    local active, selectedTab, queued
    local nativeTabs = { book.ProfessionsOverviewTab }
    for _, tab in ipairs(book.rightProfessionTabs) do tinsert(nativeTabs, tab) end

    local page = CreateFrame("Frame", "ScarletUICraftProfitPage", book)
    page:Hide()
    page:SetPoint("TOPLEFT", 3, -24)
    page:SetPoint("BOTTOMRIGHT", -3, 3)
    page:EnableMouse(true)
    page:EnableMouseWheel(true)
    page:SetScript("OnMouseWheel", function() end)
    -- The page stays below the portrait's level, so addon overlays on the native page
    -- (Auctionator's To Craft box sits at level 520) would draw through; fade that page instead.
    page:SetScript("OnShow", function() book.CraftingPage:SetAlpha(0) end)
    page:SetScript("OnHide", function() book.CraftingPage:SetAlpha(1) end)

    local function Paint(container)
        local canvas = CreateFrame("Frame", nil, container)
        canvas:SetAllPoints(page)
        local backing = canvas:CreateTexture(nil, "BACKGROUND")
        backing:SetAllPoints()
        backing:SetColorTexture(0.06, 0.05, 0.04, 1)
        -- the native atlas's first 54px hold the full header and crease
        local header = CreateFrame("Frame", nil, canvas)
        header:SetPoint("TOPLEFT", book, "TOPLEFT", 3, -21)
        header:SetPoint("TOPRIGHT", book, "TOPRIGHT", -3, -21)
        header:SetHeight(54)
        header:SetClipsChildren(true)
        local headerArt = header:CreateTexture(nil, "ARTWORK")
        headerArt:SetAtlas("Profession-Background-Template2", true)
        headerArt:SetPoint("TOPLEFT")
        headerArt:SetPoint("TOPRIGHT")
        local art = canvas:CreateTexture(nil, "ARTWORK")
        art:SetAtlas("Profession-Background-Overview")
        art:SetAllPoints()
    end
    Paint(page)

    -- Rank bars sit in HIGH strata, so cover just their rectangles with the same art.
    local bars = { book.CraftingPage.RankBar }
    local content = book.BookPage and book.BookPage.ProfessionsContentFrame
    for _, key in ipairs({ "PrimaryProfession1", "PrimaryProfession2", "SecondaryProfession1",
        "SecondaryProfession2", "SecondaryProfession3" }) do
        if content and content[key] then tinsert(bars, content[key].StatusBar) end
    end
    for _, bar in ipairs(bars) do
        local cover = CreateFrame("Frame", nil, page)
        cover:SetPoint("TOPLEFT", bar.Border, "TOPLEFT", -2, 2)
        cover:SetPoint("BOTTOMRIGHT", bar.Border, "BOTTOMRIGHT", 2, -2)
        cover:SetFrameStrata("HIGH")
        cover:SetFrameLevel(bar:GetFrameLevel() + 10)
        cover:SetClipsChildren(true)
        cover:EnableMouse(true)
        Paint(cover)
    end

    local list = CreateList(page, "HIGH")
    list:SetPoint("TOPLEFT", 8, -12)
    list:SetPoint("BOTTOMRIGHT", -8, 4)

    local function MakeTab()
        local tab = CreateFrame("Frame", nil, book, "LargeSideTabButtonTemplate")
        tab:Hide()
        tab:EnableMouse(true)
        tab:SetFillToInterior(true)
        tab:SetChecked(false)
        tab:HookScript("OnHide", function(self)
            local tooltip = GetAppropriateTooltip()
            if tooltip:IsOwned(self) then tooltip:Hide() end
        end)
        return tab
    end
    local launcher = MakeTab()
    launcher.Icon:SetTexture(ICON)
    launcher.tooltipText = "Craft Profit"
    local returnTab = MakeTab()

    local function SelectedNativeTab()
        local selected
        for _, tab in ipairs(nativeTabs) do
            if tab:IsShown() and tab.SelectedTexture:IsShown() then selected = tab end
        end
        return selected
    end

    -- Below the lowest profession tab; the tab count changes with learned professions.
    local function PlaceLauncher()
        local lowest
        for _, tab in ipairs(book.rightProfessionTabs) do
            if tab:IsShown() and tab:GetBottom() and (not lowest or tab:GetBottom() < lowest:GetBottom()) then
                lowest = tab
            end
        end
        launcher:ClearAllPoints()
        launcher:SetPoint("TOPLEFT", lowest or book.ProfessionsOverviewTab, "BOTTOMLEFT", 0, -4)
    end

    local function Sync()
        queued = false
        if not book:IsVisible() or not Settings().enabled then
            active = false
            page:Hide()
            launcher:Hide()
            returnTab:Hide()
            return
        end
        local selected = SelectedNativeTab()
        if selected ~= selectedTab then active = false end

        local level = book.PortraitContainer:GetFrameLevel() - 10
        page:SetFrameLevel(level)
        list:SetFrameLevel(level + 1000)
        launcher:SetFrameLevel(level + 1)
        returnTab:SetFrameLevel(level + 1)
        PlaceLauncher()
        launcher:SetChecked(active)
        launcher:Show()
        page:SetShown(active)

        returnTab:SetShown(active and selected ~= nil)
        if active and selected then
            returnTab:ClearAllPoints()
            returnTab:SetPoint("CENTER", selected)
            returnTab.Icon:SetTexture(selected.Icon:GetTexture())
            returnTab.tooltipText = selected.tooltipText
        end
    end

    local function Request()
        if queued then return end
        queued = true
        RunNextFrame(Sync)
    end
    local function Deactivate()
        active = false
        Request()
    end
    requestSync = Request

    launcher:SetCustomOnMouseUpHandler(function(_, button, upInside)
        if button ~= "LeftButton" or not upInside then return end
        selectedTab = SelectedNativeTab()
        active = not active
        Sync()
    end)
    local function ReturnToNative(_, button, upInside)
        if button ~= "LeftButton" or not upInside then return end
        active = false
        Sync()
    end
    returnTab:SetCustomOnMouseUpHandler(ReturnToNative)
    for _, tab in ipairs(nativeTabs) do tab:HookScript("OnMouseUp", ReturnToNative) end

    EventRegistry:RegisterCallback("ProfessionsFrame.Show", Request, page)
    EventRegistry:RegisterCallback("ProfessionsFrame.Hide", Deactivate, page)
    EventRegistry:RegisterCallback("Professions.ProfessionSelected", Deactivate, page)
    EventRegistry:RegisterCallback("Professions.ShowSelectedCraftingPage", Deactivate, page)
    book:HookScript("OnSizeChanged", Request)
    page:RegisterEvent("TRADE_SKILL_SHOW")
    page:RegisterEvent("UI_SCALE_CHANGED")
    page:SetScript("OnEvent", function(_, event)
        if event == "TRADE_SKILL_SHOW" then Deactivate() else Request() end
    end)
    Request()
end

-- Setup ------------------------------------------------------------------

-- Applies the Craft Profit switch: off closes the window and removes the tab.
function ScarletUI:UpdateCraftProfit()
    if not window then return end
    if not Settings().enabled then window:Hide() end
    if requestSync then requestSync() end
end

function ScarletUI:ToggleCraftProfit()
    if window and Settings().enabled then
        window:SetShown(not window:IsShown())
    end
end

function ScarletUI:SetupCraftProfit()
    -- The standalone Craft Profit addon defines CraftProfit_Toggle; leave it to it.
    if self:GetWoWVersion() ~= "FOREVER" or CraftProfit_Toggle then
        return
    end
    self.craftProfitSupported = true -- shows the setting, grayed out without Auctionator
    if window or not (Auctionator and Auctionator.API and Auctionator.API.v1 and C_TradeSkillUI) then
        return
    end
    API, T = Auctionator.API.v1, C_TradeSkillUI
    local E = Enum.TradeskillRelativeDifficulty or { Optimal = 0, Medium = 1, Easy = 2, Trivial = 3 }
    DIFFICULTY = { [E.Optimal] = "optimal", [E.Medium] = "medium", [E.Easy] = "easy", [E.Trivial] = "trivial" }

    window = CreateFrame("Frame", "ScarletUICraftProfit", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(470, 440)
    window:SetPoint("CENTER")
    window:SetFrameStrata("HIGH")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:Hide()
    tinsert(UISpecialFrames, "ScarletUICraftProfit")
    local title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("Craft Profit")
    local list = CreateList(window)
    list:SetPoint("TOPLEFT", 0, -22)
    list:SetPoint("BOTTOMRIGHT")

    EventUtil.ContinueOnAddOnLoaded("Blizzard_Professions", AttachProfessionPage)

    local QueueScan, QueueRefresh = Debounce(0.5, Scan), Debounce(0.2, Refresh)
    window:RegisterEvent("TRADE_SKILL_SHOW")
    window:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
    window:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    window:SetScript("OnEvent", function(_, event)
        if event == "GET_ITEM_INFO_RECEIVED" then QueueRefresh() else QueueScan() end
    end)

    SLASH_SCARLETUICRAFTPROFIT1, SLASH_SCARLETUICRAFTPROFIT2 = "/craftprofit", "/cp"
    SlashCmdList.SCARLETUICRAFTPROFIT = function() self:ToggleCraftProfit() end
end
