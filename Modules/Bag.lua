local GetContainerNumSlots = C_Container.GetContainerNumSlots or GetContainerNumSlots
local GetContainerItemInfo = C_Container.GetContainerItemInfo or GetContainerItemInfo
local PickupContainerItem = C_Container.PickupContainerItem or PickupContainerItem
local UseContainerItem = C_Container.UseContainerItem or UseContainerItem
local GetContainerItemCooldown = C_Container.GetContainerItemCooldown or GetContainerItemCooldown

local bagSlots = {}
local lastPickedUpButton

local function updateCurrencyDisplay()
    local currencyFooter = ScarletUI.bagFrame.currencyFooter;

    -- Iterate over each currency
    local trackedIndex = 1
    for i = 1, GetCurrencyListSize() do
        if trackedIndex <= 3 then
            local _, isHeader, _, _, isWatched, count, icon = GetCurrencyListInfo(i)
            if not isHeader and isWatched then
                -- Get the existing FontString or create a new one
                local fs = currencyFooter.currencies[trackedIndex]
                fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
                fs:SetText(count)

                -- Get the existing Texture or create a new one
                local iconTexture = fs.iconTexture
                iconTexture:SetTexture(icon)
                iconTexture:SetSize(16, 16)

                -- Position the FontString and the Texture
                if trackedIndex == 1 then
                    fs:SetPoint("LEFT", currencyFooter, "LEFT", 0, 0)
                    iconTexture:SetPoint("LEFT", fs, "RIGHT", 5, 0)
                else
                    fs:SetPoint("LEFT", currencyFooter.currencies[trackedIndex - 1], "RIGHT", 30, 0)
                    iconTexture:SetPoint("LEFT", fs, "RIGHT", 5, 0)
                end

                -- Show the FontString and the Texture
                fs:Show()
                iconTexture:Show()

                trackedIndex = trackedIndex + 1
            end
        end
    end

    -- Hide unused currency displays
    for i = trackedIndex, 3 do
        if currencyFooter.currencies[i] then
            currencyFooter.currencies[i]:Hide()
            if currencyFooter.currencies[i].iconTexture then
                currencyFooter.currencies[i].iconTexture:Hide()
            end
        end
    end
end

local function UpdateCurrencyFooter()
    local currencyFooter = ScarletUI.bagFrame.currencyFooter;
    local gold = math.floor(GetMoney() / (COPPER_PER_SILVER * SILVER_PER_GOLD))
    local silver = math.floor((GetMoney() - (gold * COPPER_PER_SILVER * SILVER_PER_GOLD)) / COPPER_PER_SILVER)
    local bronze = math.floor(GetMoney() % COPPER_PER_SILVER)

    currencyFooter.goldText:SetText(gold)
    currencyFooter.silverText:SetText(silver)
    currencyFooter.bronzeText:SetText(bronze)
end

local function UpdateCount(bag, slot)
    local index = bag * GetContainerNumSlots(bag) + slot
    local button = bagSlots[index]
    local containerInfo = GetContainerItemInfo(bag, slot)
    if containerInfo and containerInfo.stackCount then
        button.Count:SetText(containerInfo.stackCount > 1 and containerInfo.stackCount or "")
    else
        button.Count:SetText("")
    end
end

local function UpdateBag()
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local index = bag * GetContainerNumSlots(bag) + slot
            local button = bagSlots[index]
            local containerInfo = GetContainerItemInfo(bag, slot)
            if containerInfo and containerInfo.iconFileID then
                button.icon:SetTexture(containerInfo.iconFileID)

                -- Get the item's rarity
                local itemQuality = containerInfo.quality

                -- If the item is not junk or common, add a border
                if itemQuality and itemQuality > 1 then
                    local r, g, b = GetItemQualityColor(itemQuality)
                    button.border:SetVertexColor(r, g, b)
                    button.border:Show()
                else
                    button.border:Hide()
                end

                -- Update the cooldown
                local start, duration = GetContainerItemCooldown(bag, slot)
                if start > 0 and duration > 0 then
                    button.Cooldown:SetCooldown(start, duration)
                    button.Cooldown:Show()
                else
                    button.Cooldown:Hide()
                end
            else
                button.icon:SetTexture(nil)
                button.border:Hide()
                button.Cooldown:Hide()
            end
            UpdateCount(bag, slot)
        end
    end

    ScarletUI:BagItemLevel()
    UpdateCurrencyFooter()
end

function ScarletUI:SetupBags()
    local bagModule = self.db.global.bagModule
    if not bagModule.enabled or self.lightWeightMode or self.retail then
        return
    end

    -- Keep track of the total number of slots
    local totalSlots = 0

    -- Iterate over each bag
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        totalSlots = totalSlots + GetContainerNumSlots(bag)
    end

    -- Calculate the number of rows
    local numRows = math.ceil(totalSlots / bagModule.slotsPerRow)

    -- Calculate the width and height of the bag frame
    local bagFrameWidth = (bagModule.slotSize + bagModule.slotSpacing) * bagModule.slotsPerRow - bagModule.slotSpacing
    local bagFrameHeight = (bagModule.slotSize + bagModule.slotSpacing) * numRows - bagModule.slotSpacing

    -- Add an additional amount to the width and height for the border
    local borderPadding = 10
    bagFrameWidth = bagFrameWidth + borderPadding * 2
    bagFrameHeight = bagFrameHeight + borderPadding * 2

    -- Subtract the height of the currency footer from the bag frame height
    local currencyFooterHeight = 20
    bagFrameHeight = bagFrameHeight + currencyFooterHeight + 10

    -- Create a new frame for the bag
    self.bagFrame = CreateFrame("Frame", "ScarletUI_BagFrame", UIParent, "BackdropTemplate")
    self.bagFrame:SetSize(bagFrameWidth, bagFrameHeight)
    self.bagFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -1, 40)
    self.bagFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.bagFrame:SetBackdropColor(0, 0, 0, 0.5)

    -- Enable mouse events on the bag frame
    self.bagFrame:EnableMouse(true)

    -- Add an OnShow script to the bag frame to play the bag sound
    self.bagFrame:SetScript("OnShow", function()
        PlaySound(117)
    end)

    -- Add an OnHide script to the bag frame to play the bag sound
    self.bagFrame:SetScript("OnHide", function()
        PlaySound(617)
    end)

    -- Calculate the starting point for the buttons
    local startX = borderPadding
    local startY = -borderPadding

    -- Iterate over each bag
    totalSlots = 0
    for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
        -- Iterate over each slot in the bag
        for slot = 1, GetContainerNumSlots(bag) do
            totalSlots = totalSlots + 1

            -- Create a new button for the slot
            local button = CreateFrame("ItemButton", "ScarletUI_Bag" .. bag .. "Slot" .. slot, self.bagFrame, "SecureActionButtonTemplate")
            button:SetAttribute("type", "item")
            button:SetAttribute("item", "bag " .. bag .. " slot " .. slot)
            button:SetSize(bagModule.slotSize, bagModule.slotSize)

            button:EnableMouse(true)

            -- Create a Cooldown frame for the button
            button.Cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
            button.Cooldown:SetAllPoints()
            button.Cooldown:Hide()

            -- Create a texture for the button border
            button.border = button:CreateTexture(nil, "OVERLAY")
            button.border:SetAllPoints()
            button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
            button.border:SetTexCoord(0.2, 0.8, 0.2, 0.8)
            button.border:SetBlendMode("ADD")
            button.border:SetAlpha(0.75)
            button.border:Hide()

            -- Create a texture for the button background
            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")

            -- Position the button in a grid
            local distance = bagModule.slotSize + bagModule.slotSpacing
            button:SetPoint("TOPLEFT", startX + ((totalSlots - 1) % bagModule.slotsPerRow) * distance, startY + math.floor((totalSlots - 1) / bagModule.slotsPerRow) * -distance)

            -- Get the item info
            local containerInfo = GetContainerItemInfo(bag, slot)

            -- Set the button's texture to the item's icon
            if containerInfo and containerInfo.iconFileID then
                button.icon:SetTexture(containerInfo.iconFileID)
            else
                button.icon:SetTexture(nil)
            end

            -- Create a FontString for the count
            button.Count = button:CreateFontString(nil, "OVERLAY")
            button.Count:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
            button.Count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)

            -- Add the button to the bagSlots table
            bagSlots[bag * GetContainerNumSlots(bag) + slot] = button

            -- Enable the button to respond to drag and drop events
            button:RegisterForDrag("LeftButton")

            -- Add scripts to handle drag and drop events
            button:SetScript("OnDragStart", function(self)
                PickupContainerItem(bag, slot)
                self.icon:SetDesaturated(true)
                lastPickedUpButton = self
                UpdateBag()
            end)

            button:SetScript("OnReceiveDrag", function(self)
                PickupContainerItem(bag, slot)
                self.icon:SetDesaturated(false)
                if lastPickedUpButton then
                    lastPickedUpButton.icon:SetDesaturated(false)
                    lastPickedUpButton = nil
                end
                UpdateBag()
            end)

            -- Add scripts to handle mouse events
            button:SetScript("OnClick", function(self, mouseButton)
                if mouseButton == "LeftButton" then
                    PickupContainerItem(bag, slot)
                    self.icon:SetDesaturated(CursorHasItem())
                    if lastPickedUpButton then
                        if CursorHasItem() then
                            lastPickedUpButton = self
                        else
                            lastPickedUpButton.icon:SetDesaturated(false)
                            lastPickedUpButton = nil
                        end
                    end
                    lastPickedUpButton = self
                    UpdateBag()
                elseif mouseButton == "RightButton" then
                    UseContainerItem(bag, slot)
                end
            end)

            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:SetBagItem(bag, slot)
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end

    -- Create a new frame for the currency footer
    self.bagFrame.currencyFooter = CreateFrame("Frame", "ScarletUI_BagFrame_CurrencyFooter", self.bagFrame, "BackdropTemplate")
    self.bagFrame.currencyFooter:SetSize(bagFrameWidth - borderPadding * 2, currencyFooterHeight)
    self.bagFrame.currencyFooter:SetPoint("BOTTOM", self.bagFrame, "BOTTOM", 0, borderPadding)
    self.bagFrame.currencyFooter:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    self.bagFrame.currencyFooter:RegisterEvent("BAG_UPDATE_COOLDOWN")

    -- Initialize the currencies table
    self.bagFrame.currencyFooter.currencies = {}

    for i = 1, 3 do
        local fs = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
        fs:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")

        local iconTexture = ScarletUI.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
        iconTexture:SetSize(16, 16)
        fs.iconTexture = iconTexture

        self.bagFrame.currencyFooter.currencies[i] = fs
    end

    local cooldownFunction = function()
        for bag = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
            for slot = 1, GetContainerNumSlots(bag) do
                local index = bag * GetContainerNumSlots(bag) + slot
                local button = bagSlots[index]
                local start, duration = GetContainerItemCooldown(bag, slot)
                if start > 0 and duration > 0 then
                    button.Cooldown:SetCooldown(start, duration)
                    button.Cooldown:Show()
                else
                    button.Cooldown:Hide()
                end
            end
        end
    end

    updateCurrencyDisplay()
    hooksecurefunc("SetCurrencyBackpack", updateCurrencyDisplay)
    self.bagFrame.currencyFooter:SetScript("OnEvent", function(_, event)
        if event == "CURRENCY_DISPLAY_UPDATE" then
            updateCurrencyDisplay()
        elseif event == "BAG_UPDATE_COOLDOWN" then
            cooldownFunction()
        end
    end)

    cooldownFunction()

    -- Create FontStrings for the gold, silver, and bronze amounts
    self.bagFrame.currencyFooter.bronzeText = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
    self.bagFrame.currencyFooter.bronzeText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.bagFrame.currencyFooter.bronzeText:SetPoint("RIGHT", self.bagFrame.currencyFooter, "RIGHT", -16, 0)

    self.bagFrame.currencyFooter.bronzeIcon = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
    self.bagFrame.currencyFooter.bronzeIcon:SetTexture("Interface\\MoneyFrame\\UI-CopperIcon")
    self.bagFrame.currencyFooter.bronzeIcon:SetSize(16, 16)
    self.bagFrame.currencyFooter.bronzeIcon:SetPoint("LEFT", self.bagFrame.currencyFooter.bronzeText, "RIGHT", 1, 0)

    self.bagFrame.currencyFooter.silverText = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
    self.bagFrame.currencyFooter.silverText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.bagFrame.currencyFooter.silverText:SetPoint("RIGHT", self.bagFrame.currencyFooter.bronzeText, "LEFT", -20, 0)

    self.bagFrame.currencyFooter.silverIcon = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
    self.bagFrame.currencyFooter.silverIcon:SetTexture("Interface\\MoneyFrame\\UI-SilverIcon")
    self.bagFrame.currencyFooter.silverIcon:SetSize(16, 16)
    self.bagFrame.currencyFooter.silverIcon:SetPoint("LEFT", self.bagFrame.currencyFooter.silverText, "RIGHT", 1, 0)

    self.bagFrame.currencyFooter.goldText = self.bagFrame.currencyFooter:CreateFontString(nil, "OVERLAY")
    self.bagFrame.currencyFooter.goldText:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    self.bagFrame.currencyFooter.goldText:SetPoint("RIGHT", self.bagFrame.currencyFooter.silverText, "LEFT", -20, 0)

    self.bagFrame.currencyFooter.goldIcon = self.bagFrame.currencyFooter:CreateTexture(nil, "OVERLAY")
    self.bagFrame.currencyFooter.goldIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
    self.bagFrame.currencyFooter.goldIcon:SetSize(16, 16)
    self.bagFrame.currencyFooter.goldIcon:SetPoint("LEFT", self.bagFrame.currencyFooter.goldText, "RIGHT", 1, 0)

    self.bagFrame.currencyFooter:RegisterEvent("PLAYER_MONEY")
    self.bagFrame.currencyFooter:SetScript("OnEvent", UpdateCurrencyFooter)

    -- Store the bagSlots table in the addon object
    self.bagSlots = bagSlots

    -- Register the BAG_UPDATE event
    self.frame:HookScript("OnEvent", function(_, event)
        if event == "BAG_UPDATE" then
            UpdateBag()
        end
    end)

    -- Update the bag when it is initially loaded
    UpdateBag()

    -- Hide the bag frame by default
    self.bagFrame:Hide()

    -- Override the default bag functions
    OpenAllBags = function() ScarletUI_BagFrame:Show() end
    ToggleAllBags = function() ScarletUI_BagFrame:SetShown(not ScarletUI_BagFrame:IsShown()) end
    OpenBackpack = function() ScarletUI_BagFrame:Show() end
    ToggleBackpack = function() ScarletUI_BagFrame:SetShown(not ScarletUI_BagFrame:IsShown()) end
    OpenBag = function(bagID)
        if bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS then
            ScarletUI_BagFrame:Show()
        end
    end
    ToggleBag = function(bagID)
        if bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS then
            ScarletUI_BagFrame:SetShown(not ScarletUI_BagFrame:IsShown())
        end
    end
    CloseBag = function(bagID)
        if bagID >= BACKPACK_CONTAINER and bagID <= NUM_BAG_SLOTS then
            ScarletUI_BagFrame:Hide()
        end
    end
    CloseBackpack = function() ScarletUI_BagFrame:Hide() end
    CloseAllBags = function() ScarletUI_BagFrame:Hide() end
end
