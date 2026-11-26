-- Run from the addon root: lua tests/toc-version.lua
-- Every TOC must carry the same MAJOR.MINOR.PATCH version.
local tocs = { "Mainline", "Camelot", "Vanilla", "TBC", "Mists" }
local first
for _, name in ipairs(tocs) do
    local file = assert(io.open("ScarletUI-" .. name .. ".toc"))
    local text = file:read("*a")
    file:close()
    local v = text:match("\n## Version:%s*([^\r\n]-)%s*[\r\n]") or text:match("^## Version:%s*([^\r\n]-)%s*[\r\n]")
    assert(v, name .. " TOC has no Version")
    assert(v:match("^%d+%.%d+%.%d+$"), name .. " TOC version is not MAJOR.MINOR.PATCH: " .. v)
    first = first or v
    assert(v == first, name .. " TOC version " .. v .. " differs from " .. first)
end
print("toc-version ok", first)
