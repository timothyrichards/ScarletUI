function ScarletUI:SetupChat()
    local chatModule = self.db.global.chatModule;
    if not chatModule.enabled then
        return
    end

    self:FixChatBug()
    self:SetupChatTabs()
    self:GuardChatEditBoxes()

    if not self.chatEventRegistered then
        self.chatEventRegistered = true
        self:RegisterEventHandler("UPDATE_FLOATING_CHAT_WINDOWS", function()
            ScarletUI:SetupChat()
        end)
        self:RegisterEventHandler("UPDATE_CHAT_COLOR_NAME_BY_CLASS", function(_, chatType, set)
            if not set then SetChatColorNameByClass(chatType, true) end
        end)
    end
end

function ScarletUI:SetupChatTabs()
    local module = self.db.global.chatModule;
    local tabs = module.tabs
    if not module.enabled then
        return
    end

    -- Open new tabs if they dont exist
    local opened = false
    if tabs.loot and not self:ChatTabExists(_G.CHAT_FRAMES, "Loot") then
        FCF_OpenNewWindow("Loot")
        opened = true
    end
    if tabs.trade and not self:ChatTabExists(_G.CHAT_FRAMES, "Trade") then
        FCF_OpenNewWindow("Trade")
        opened = true
    end
    if tabs.lfg and not self.lightWeightMode then
        if not self:ChatTabExists(_G.CHAT_FRAMES, "LFG") then
            FCF_OpenNewWindow("LFG")
            opened = true
        end
    end

    -- Rename and color all tabs
    for _, name in ipairs(_G.CHAT_FRAMES) do
        local frame = _G[name]
        local id = frame:GetID()

        -- Set chat font size
        FCF_SetChatWindowFontSize(nil, frame, module.fontSize)

        if frame.name == 'General' then
            if tabs.loot then
                ChatFrame_RemoveMessageGroup(frame, "LOOT")
            end
            if tabs.trade then
                if ChatFrame_RemoveChannel then
                    ChatFrame_RemoveChannel(frame, 'Trade')
                    ChatFrame_RemoveChannel(frame, 'Services')
                elseif RemoveChatWindowChannel then
                    RemoveChatWindowChannel(id, 'Trade')
                    RemoveChatWindowChannel(id, 'Services')
                end
            end
            if tabs.lfg then
                if ChatFrame_RemoveChannel then
                    ChatFrame_RemoveChannel(frame, 'LookingForGroup')
                elseif RemoveChatWindowChannel then
                    RemoveChatWindowChannel(id, 'LookingForGroup')
                end
            end
            ChatFrame_RemoveMessageGroup(frame, 'IGNORED')
        elseif frame.name == 'Loot' then
            ChatFrame_RemoveAllMessageGroups(frame)
            C_Timer.NewTimer(0.1, function()
                ChatFrame_AddMessageGroup(frame, "LOOT")
            end)
        elseif frame.name == 'Trade' then
            ChatFrame_RemoveAllMessageGroups(frame)
            C_Timer.NewTimer(0.1, function()
                if ChatFrame_AddChannel then
                    ChatFrame_AddChannel(frame, 'Trade')
                elseif AddChatWindowChannel then
                    AddChatWindowChannel(id, 'Trade')
                end
                if ChatFrame_AddChannel then
                    ChatFrame_AddChannel(frame, 'Services')
                elseif AddChatWindowChannel then
                    AddChatWindowChannel(id, 'Services')
                end
            end)
        elseif frame.name == 'LFG' then
            ChatFrame_RemoveAllMessageGroups(frame)
            C_Timer.NewTimer(0.1, function()
                if ChatFrame_AddChannel then
                    ChatFrame_AddChannel(frame, 'LookingForGroup')
                elseif AddChatWindowChannel then
                    AddChatWindowChannel(id, 'LookingForGroup')
                end
            end)
        end
    end

    -- Opening a tab selects it, so jump back to the main tab only then. Selecting
    -- from addon code taints the dock; tab clicks spread that to the chat edit box,
    -- and Shift-clicking a map pin then can't call CopyToClipboard.
    if opened then
        FCFDock_SelectWindow(_G.GENERAL_CHAT_DOCK, _G.ChatFrame1)
    end
end

function ScarletUI:ChatTabExists(table, value)
    for k, _ in ipairs(table) do
        local name, _ = GetChatWindowInfo(k);
        if name == value then
            return true
        end
    end

    return false
end

local SENDABLE = {
    SAY = true, YELL = true, PARTY = true, RAID = true, INSTANCE_CHAT = true, GUILD = true,
    OFFICER = true, WHISPER = true, BN_WHISPER = true, CHANNEL = true, EMOTE = true,
}

-- Blizzard's UpdateDefaultChatTarget makes a tab with a single message group (our Loot
-- tab) default its edit box to that group, so chatType becomes "LOOT" and every send
-- fails. Reset it when the box opens or gains focus. Only HookScript and SetAttribute:
-- no Blizzard function is replaced, so secure chat sending stays untainted.
function ScarletUI:GuardChatEditBoxes()
    for i = 1, _G.NUM_CHAT_WINDOWS or 10 do
        local box = _G["ChatFrame" .. i .. "EditBox"]
        if box and not box.scarletChatGuard then
            box.scarletChatGuard = true
            local function fix()
                if not SENDABLE[box:GetAttribute("chatType")] then
                    local sticky = box:GetAttribute("stickyType")
                    if not SENDABLE[sticky] then
                        sticky = "SAY"
                        box:SetAttribute("stickyType", sticky)
                    end
                    box:SetAttribute("chatType", sticky)
                    if box.UpdateHeader then box:UpdateHeader() end
                end
            end
            box:HookScript("OnShow", fix)
            box:HookScript("OnEditFocusGained", fix)
        end
    end
end
