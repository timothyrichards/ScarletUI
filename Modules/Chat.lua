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

    -- Open 2 new tabs
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
            ChatFrame_RemoveChannel(frame, 'Trade')
            ChatFrame_RemoveChannel(frame, 'LookingForGroup')
            ChatFrame_RemoveMessageGroup(frame, 'IGNORED')
        elseif id == 2 then
            FCF_SetWindowName(frame, 'Log')
        elseif (id == 3) then
            VoiceTranscriptionFrame_UpdateVisibility(frame)
            VoiceTranscriptionFrame_UpdateVoiceTab(frame)
            VoiceTranscriptionFrame_UpdateEditBox(frame)
        elseif (id == 4) then
            ChatFrame_RemoveAllMessageGroups(frame)
            FCF_SetWindowName(frame, 'LFG')
            ChatFrame_AddChannel(frame, 'LookingForGroup')
        elseif (id == 5) then
            ChatFrame_RemoveAllMessageGroups(frame)
            FCF_SetWindowName(frame, 'Trade')
            ChatFrame_AddChannel(frame, 'Trade')
        end
    end

    -- Jump back to main tab
    FCFDock_SelectWindow(_G.GENERAL_CHAT_DOCK, _G.ChatFrame1)

    if not IsAddOnLoaded("ElvUI") then
        ChatFrame1:SetMovable(true)
        ChatFrame1:SetUserPlaced(true)
        ChatFrame1:SetHeight(150)
        ChatFrame1:SetWidth(450)
        ChatFrame1:ClearAllPoints()
        ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 75)
    end
end