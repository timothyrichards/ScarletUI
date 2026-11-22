-- Run from the addon root: lua tests/chat-edit-box.lua
ScarletUI = {}
dofile("Modules/Chat.lua")
local function newBox()
    local attrs, hooks = { chatType = "LOOT", stickyType = "LOOT" }, {}
    local box = { updated = 0 }
    function box:GetAttribute(k) return attrs[k] end
    function box:SetAttribute(k, v) attrs[k] = v end
    function box:HookScript(name, fn) hooks[name] = fn end
    function box:UpdateHeader() self.updated = self.updated + 1 end
    return box, attrs, hooks
end
local box, attrs, hooks = newBox()
NUM_CHAT_WINDOWS = 1
ChatFrame1EditBox = box
ScarletUI:GuardChatEditBoxes()
ScarletUI:GuardChatEditBoxes() -- idempotent
hooks.OnShow()
assert(attrs.chatType == "SAY" and attrs.stickyType == "SAY" and box.updated == 1)
-- a valid sticky type is restored instead of SAY
attrs.chatType, attrs.stickyType = "MONEY", "GUILD"
hooks.OnEditFocusGained()
assert(attrs.chatType == "GUILD" and attrs.stickyType == "GUILD")
-- sendable types are left alone
attrs.chatType = "PARTY"
hooks.OnShow()
assert(attrs.chatType == "PARTY")
print("chat-edit-box ok")
