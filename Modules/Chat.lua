local function chatTabExists(table, value)
    for k, _ in ipairs(table) do
        local name, _ = GetChatWindowInfo(k);
        if name == value then
            return true
        end
    end
    return false
end

function ScarletUI:SetupChat()
    local chatModule = self.db.global.chatModule;
    local tabs = chatModule.tabs
    if not chatModule.enabled then
        return
    end

    -- Reset chat to Blizzard defaults
    --FCF_ResetChatWindows()

    -- Open new tabs if they dont exist
    if tabs.loot and not chatTabExists(_G.CHAT_FRAMES, "Loot") then
        FCF_OpenNewWindow("Loot")
    end
    if tabs.trade and not chatTabExists(_G.CHAT_FRAMES, "Trade") then
        FCF_OpenNewWindow("Trade")
    end
    if tabs.lfg and not self.retail then
        if not chatTabExists(_G.CHAT_FRAMES, "LFG") then
            FCF_OpenNewWindow("LFG")
        end
    end

    -- Rename and color all tabs
    for _, name in ipairs(_G.CHAT_FRAMES) do
        local frame = _G[name]
        local id = frame:GetID()

        -- Set chat font size
        FCF_SetChatWindowFontSize(nil, frame, chatModule.fontSize)

        if frame.name == 'General' then
            ChatFrame_RemoveChannel(frame, 'Trade')
            ChatFrame_RemoveChannel(frame, 'LookingForGroup')
            ChatFrame_RemoveMessageGroup(frame, 'IGNORED')
        elseif frame.name == 'Voice' then
            VoiceTranscriptionFrame_UpdateVisibility(frame)
            VoiceTranscriptionFrame_UpdateVoiceTab(frame)
            VoiceTranscriptionFrame_UpdateEditBox(frame)
        elseif frame.name == 'Loot' then
            ChatFrame_RemoveAllMessageGroups(frame)
            ChatFrame_AddMessageGroup(frame, "LOOT")
        elseif frame.name == 'LFG' then
            ChatFrame_RemoveAllMessageGroups(frame)
            JoinChannelByName('LookingForGroup', nil, id, 0)
            ChatFrame_AddChannel(frame, 'LookingForGroup')
        elseif frame.name == 'Trade' then
            ChatFrame_RemoveAllMessageGroups(frame)
            ChatFrame_AddChannel(frame, 'Trade')
        end
    end

    -- Jump back to main tab
    FCFDock_SelectWindow(_G.GENERAL_CHAT_DOCK, _G.ChatFrame1)

    if not self.chatEventRegistered then
        self.chatEventRegistered = true
        local frame = CreateFrame("Frame", "SUI_ChatFrame", SUI_Frame)
        frame:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS")
        frame:SetScript("OnEvent", function(_, event, type, set, ...)
            if event == "UPDATE_CHAT_COLOR_NAME_BY_CLASS" then
                if not set then SetChatColorNameByClass(type,true); end
            end
        end)
    end

    local chatFrame = chatModule.chatFrame
    if not chatFrame.move or self.lightWeightMode or self.retail then
        return
    end

    self:CreateMover(ChatFrame1, chatFrame)
    ChatFrame1:SetMovable(true)
    ChatFrame1:SetUserPlaced(true)
    ChatFrame1:SetHeight(chatModule.height)
    ChatFrame1:SetWidth(chatModule.width)
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint(
            self.frameAnchors[chatFrame.frameAnchor],
            UIParent,
            self.frameAnchors[chatFrame.screenAnchor],
            chatFrame.x,
            chatFrame.y
    )
end
