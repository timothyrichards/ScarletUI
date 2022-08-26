function ScarletUI:SetupChat()
    SetCVar('chatStyle', 'classic')
    SetCVar('whisperMode', 'inline')
    SetCVar('colorChatNamesByClass', 1)
    SetCVar('chatClassColorOverride', 0)
    SetCVar('speechToText', 0)
    SetCVar('textToSpeech', 0)
    -- Process normal and existing chat frames
    for i = 1, 50 do
        if _G["ChatFrame" .. i] then
            _G["ChatFrame" .. i]:SetFading(false)
        end
    end
    -- Process temporary frames
    hooksecurefunc("FCF_OpenTemporaryWindow", function()
        local cf = FCF_GetCurrentChatFrame():GetName() or nil
        if cf then
            _G[cf]:SetFading(false)
        end
    end)

    -- Reset chat to Blizzard defaults
    FCF_ResetChatWindows()

    -- Open 3 new tabs
    FCF_OpenNewWindow()
    FCF_OpenNewWindow()
    FCF_OpenNewWindow()

    -- Rename and color all tabs
    for _, name in ipairs(_G.CHAT_FRAMES) do
        local frame = _G[name]
        local id = frame:GetID()

        -- Set chat font size
        if IsAddOnLoaded("ElvUI") then
            FCF_SetChatWindowFontSize(nil, frame, 12)
        else
            FCF_SetChatWindowFontSize(nil, frame, 14)
        end

        if id == 1 then
            FCF_SetWindowName(frame, 'General')
        elseif id == 2 then
            FCF_SetWindowName(frame, 'Log')
        elseif (id == 3) then
            VoiceTranscriptionFrame_UpdateVisibility(frame)
            VoiceTranscriptionFrame_UpdateVoiceTab(frame)
            VoiceTranscriptionFrame_UpdateEditBox(frame)
        elseif (id == 4) then
            FCF_SetWindowName(frame, 'Loot')
        elseif (id == 5) then
            FCF_SetWindowName(frame, 'LFG')
        elseif (id == 6) then
            FCF_SetWindowName(frame, 'Trade')
        end
    end

    -- Setup Loot tab
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame4)
    AddChatWindowMessages(4, 'SKILL')
    AddChatWindowMessages(4, 'LOOT')
    AddChatWindowMessages(4, 'MONEY')

    -- Setup LFG tab
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame5)
    ChatFrame_AddChannel(_G.ChatFrame5, 'LookingForGroup')

    -- Setup Trade tab
    ChatFrame_RemoveAllMessageGroups(_G.ChatFrame6)
    ChatFrame_AddChannel(_G.ChatFrame6, 'Trade')

    -- Jump back to main tab
    FCFDock_SelectWindow(_G.GENERAL_CHAT_DOCK, _G.ChatFrame1)

    -- Remove unwanted channels from main tab
    RemoveChatWindowMessages(1, 'SKILL')
    RemoveChatWindowMessages(1, 'LOOT')
    RemoveChatWindowMessages(1, 'MONEY')
    ChatFrame_RemoveChannel(_G.ChatFrame1, 'Trade')
    ChatFrame_RemoveChannel(_G.ChatFrame1, 'LookingForGroup')
    ChatFrame_RemoveMessageGroup(_G.ChatFrame1, 'IGNORED')

    if not IsAddOnLoaded("ElvUI") then
        ChatFrame1:SetMovable(true)
        ChatFrame1:SetUserPlaced(true)
        ChatFrame1:SetHeight(200)
        ChatFrame1:ClearAllPoints()
        ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    end
end