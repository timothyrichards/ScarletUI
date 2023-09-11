local function chatTabExists(table, value)
    for k, v in ipairs(table) do
        local name, _ = GetChatWindowInfo(k);
        if name == value then
            return true
        end
    end
    return false
end

function ScarletUI:SetupChat()
    local chatModule = self.db.global.chatModule;
    if not chatModule.enabled then
        return
    end

    -- Reset chat to Blizzard defaults
    --FCF_ResetChatWindows()

    -- Open new tabs if they dont exist
    if not chatTabExists(_G.CHAT_FRAMES, "Trade") then
        FCF_OpenNewWindow("Trade")
    end
    if not self.retail then
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
        elseif frame.name == 'LFG' then
            ChatFrame_RemoveAllMessageGroups(frame)
            JoinChannelByName('LookingForGroup', nil, id, 0)
            ChatFrame_AddChannel(frame, 'LookingForGroup')
            if IsAddOnLoaded("Hardcore") then
                JoinChannelByName('hclfg', nil, id, 0)
                ChatFrame_AddChannel(frame, 'hclfg')
            end
        elseif frame.name == 'Trade' then
            ChatFrame_RemoveAllMessageGroups(frame)
            ChatFrame_AddChannel(frame, 'Trade')
        end
    end

    -- Jump back to main tab
    FCFDock_SelectWindow(_G.GENERAL_CHAT_DOCK, _G.ChatFrame1)

    if not self.chatEventRegistered then
        self.chatEventRegistered = true
        self.Frame:RegisterEvent("UPDATE_CHAT_COLOR_NAME_BY_CLASS")
        self.Frame:HookScript("OnEvent", function(_, event, type, set, ...)
            if event == "UPDATE_CHAT_COLOR_NAME_BY_CLASS" then
                if not set then SetChatColorNameByClass(type,true); end
            end
        end)
    end

    if self.lightWeightMode then
        return
    end

    ChatFrame1:SetMovable(true)
    ChatFrame1:SetUserPlaced(true)
    ChatFrame1:SetHeight(150)
    ChatFrame1:SetWidth(400)
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 75)
end
