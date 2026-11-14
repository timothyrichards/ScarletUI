-- Gear set per talent specialization, Forever only. The talent window's
-- Primary and Secondary tabs get a dropdown of the character's Equipment
-- Manager sets; the set picked for a tab is equipped when that specialization
-- is activated. The client's own C_EquipmentSet.AssignSpecToEquipmentSet is
-- for Retail's talent-tree specializations, not the dual-spec group these tabs
-- switch, and nothing in the Forever UI equips it.
-- Sets are stored by name in db.char.specGearSets[spec group]: set IDs are
-- reused after a delete, and a renamed or deleted set should fall back to no
-- set rather than equip a different one.
local NO_SET = "No Gear Set"

function ScarletUI:SetupSpecGearSets()
    if self.specGearSetEvents or self:GetWoWVersion() ~= "FOREVER"
        or not (C_EquipmentSet and C_SpecializationInfo and C_SpecializationInfo.GetActiveSpecGroup) then
        return
    end

    -- The saved table is read on every use: a settings reset replaces it.
    local function SetName(specGroup)
        local name = self.db.char.specGearSets[specGroup]
        return name and C_EquipmentSet.GetEquipmentSetID(name) and name or nil
    end

    -- Gear cannot be swapped in combat, so a set owed then waits for it to end.
    local events = CreateFrame("Frame")
    self.specGearSetEvents = events
    events:SetScript("OnEvent", function(_, event, current, previous)
        if event == "PLAYER_REGEN_ENABLED" then
            events:UnregisterEvent(event)
        elseif current == previous then
            return
        end
        local name = SetName(C_SpecializationInfo.GetActiveSpecGroup())
        if not name then return end
        if InCombatLockdown() then
            events:RegisterEvent("PLAYER_REGEN_ENABLED")
        else
            C_EquipmentSet.UseEquipmentSet(C_EquipmentSet.GetEquipmentSetID(name))
        end
    end)
    events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

    EventUtil.ContinueOnAddOnLoaded("Blizzard_PlayerSpells", function()
        local talents = PlayerSpellsFrame and PlayerSpellsFrame.TalentsFrame
        local activeSpec = talents and talents.ActiveSpec
        if not (activeSpec and talents.GetTab and talents.BackgroundBorder) then return end

        -- A child of the Active label / Activate button, which Blizzard shows
        -- only with dual specialization unlocked and hides while inspecting.
        -- Left end of that header row, level with the button.
        local dropdown = CreateFrame("DropdownButton", "ScarletUISpecGearSet", activeSpec, "WowStyle1DropdownTemplate")
        dropdown:SetWidth(150)
        dropdown:SetPoint("LEFT", talents.BackgroundBorder, "TOPLEFT", 28, -32)
        dropdown:SetDefaultText(NO_SET)
        -- The tab IDs are the spec groups, as in Blizzard's SetTab.
        local function IsPicked(name) return SetName(talents:GetTab()) == name end
        local function Pick(name) self.db.char.specGearSets[talents:GetTab()] = name end
        dropdown:SetupMenu(function(_, root)
            root:CreateRadio(NO_SET, IsPicked, Pick)
            for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
                local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
                root:CreateRadio(name, IsPicked, Pick, name)
            end
        end)
        dropdown:HookScript("OnEnter", function()
            GameTooltip:SetOwner(dropdown, "ANCHOR_RIGHT")
            GameTooltip:SetText("Gear Set")
            GameTooltip:AddLine("Equipped when this specialization is activated. Sets are made in the Equipment Manager on the character window.",
                1, 1, 1, true)
            GameTooltip:Show()
        end)
        dropdown:HookScript("OnLeave", function() GameTooltip:Hide() end)
        -- Runs when the label shows and on every tab switch. Blizzard's tab
        -- callback is a closure over SetTab, so a hook on SetTab misses clicks.
        hooksecurefunc(activeSpec, "Refresh", function() dropdown:GenerateMenu() end)
        self.specGearSetDropdown = dropdown
    end)
end
