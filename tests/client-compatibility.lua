-- Run from the addon root: lua tests/client-compatibility.lua
local function noop() end
LibStub = function()
    return { NewAddon = function() return {} end }
end
C_AddOns = { IsAddOnLoaded = function() return false end }
StaticPopupDialogs = {}
CreateFrame = function()
    return { RegisterEvent = noop, SetScript = noop, Hide = noop }
end

for _, case in ipairs({
    { 11509, "VANILLA", false },
    { 16000, "FOREVER", true },
    { 16001, "FOREVER", true },
    { 20506, "TBC", false },
    { 30403, "WOTLK", false },
    { 40402, "CATA", false },
    { 50504, "MOP", false },
    { 120100, "RETAIL", true },
}) do
    GetBuildInfo = function() return nil, nil, nil, tostring(case[1]) end
    dofile("ScarletUI.lua")
    dofile("Modules/Helpers.lua")
    local client, interface = ScarletUI:GetWoWVersion()
    assert(client == case[2] and interface == case[1], "Incorrect client detection")
    GetBuildInfo = function() error("Client detection should be cached") end
    assert(ScarletUI:GetWoWVersion() == client)

    ScarletUI.retail, ScarletUI.lightWeightMode = false, false
    local initialized, setup = false, false
    ScarletUI.InitializeEditMode = function(self)
        assert(self.retail == case[3] and self.lightWeightMode == case[3],
            "Incorrect UI path for " .. client)
        initialized = true
    end
    ScarletUI.Setup = function() setup = true end
    ScarletUI.Print = noop
    ScarletUI:OnEnable()
    assert(initialized and setup, "Client setup did not run")

    -- ElvUI still selects lightweight mode on legacy clients.
    ScarletUI.retail, ScarletUI.lightWeightMode = false, false
    ScarletUI.IsAddOnLoaded = function(_, name) return name == "ElvUI" end
    ScarletUI.InitializeEditMode = noop
    ScarletUI:OnEnable()
    assert(ScarletUI.lightWeightMode and ScarletUI.retail == case[3])
end

local function manifestFiles(path)
    local files = {}
    for line in io.lines(path) do
        if line:match("^%w") then
            table.insert(files, line)
            local file = assert(io.open((line:gsub("\\", "/")), "r"), line .. " is missing")
            file:close()
        end
    end
    return table.concat(files, "\n")
end
-- Restore SavedVariables before addon scripts can initialize AceDB.
for _, client in ipairs({ "Mainline", "Camelot", "Vanilla", "TBC", "Mists" }) do
    local file = assert(io.open("ScarletUI-" .. client .. ".toc", "r"))
    local contents = file:read("*a")
    file:close()
    assert(contents:match("## LoadSavedVariablesFirst: 1[\r\n]"), client .. " must load saved settings first")
end
-- Era, TBC, and Mists append the Classic-UI-only modules so Retail and Forever never load them.
local modern = manifestFiles("ScarletUI-Mainline.toc")
local classic = modern .. "\nModules\\Bag.lua\nModules\\Nameplates.lua"
for client, expected in pairs({ Camelot = { 16001, modern }, Vanilla = { 11509, classic }, TBC = { 20506, classic },
    Mists = { 50504, classic } }) do
    local path = "ScarletUI-" .. client .. ".toc"
    local manifest = assert(io.open(path, "r"))
    assert(manifest:read("*l") == "## Interface: " .. expected[1], path .. " has the wrong interface")
    manifest:close()
    assert(manifestFiles(path) == expected[2], client .. " must load the expected modules in order")
end
print("PASS: client detection, modern UI selection, ElvUI compatibility, and client manifests")
