dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
GetAddOnMetadata=function(a,k) return k=="Version" and "0.15.2" or nil end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local n0=#printed
RubberDuckyDB={seenWelcome=true}
ev._scripts.OnEvent(ev,"ADDON_LOADED","RubberDucky"); ev._scripts.OnEvent(ev,"PLAYER_LOGIN")
assert(#printed==n0+1 and printed[#printed]:find("v0.15.2") and printed[#printed]:find("/ducky"), printed[#printed])
RubberDuckyDB.welcome=false; ev._scripts.OnEvent(ev,"PLAYER_LOGIN"); assert(#printed==n0+1, "off = silent")
print("ALL OK")
