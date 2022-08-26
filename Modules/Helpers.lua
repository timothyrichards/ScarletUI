local _G = _G
local ipairs = ipairs
local ChatFrame_AddMessageGroup = ChatFrame_AddMessageGroup
local ChatFrame_RemoveAllMessageGroups = ChatFrame_RemoveAllMessageGroups
local ChatFrame_RemoveMessageGroup = ChatFrame_RemoveMessageGroup
local FCF_OpenNewWindow = FCF_OpenNewWindow
local FCF_ResetChatWindows = FCF_ResetChatWindows
local FCF_SetChatWindowFontSize = FCF_SetChatWindowFontSize
local FCF_SetWindowName = FCF_SetWindowName
local FCFDock_SelectWindow = FCFDock_SelectWindow
local SetCVar = SetCVar
local VoiceTranscriptionFrame_UpdateEditBox = VoiceTranscriptionFrame_UpdateEditBox
local VoiceTranscriptionFrame_UpdateVisibility = VoiceTranscriptionFrame_UpdateVisibility
local VoiceTranscriptionFrame_UpdateVoiceTab = VoiceTranscriptionFrame_UpdateVoiceTab

local function OnEvent(self, event, ...)
    if (event == "CVAR_UPDATE") then
        print(event, ...)
    elseif (event == "ARENA_OPPONENT_UPDATE") then
        --ArenaPrepFrame1:Hide()
        --ArenaPrepFrame2:Hide()
        --ArenaPrepFrame3:Hide()
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("CVAR_UPDATE")
f:RegisterEvent("ARENA_OPPONENT_UPDATE")
f:SetScript("OnEvent", OnEvent)
