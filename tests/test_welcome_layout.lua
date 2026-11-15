dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
RubberDuckyDB={seenWelcome=true}
ns.eventFrame._scripts.OnEvent(ns.eventFrame,"ADDON_LOADED","RubberDucky")
ns.eventFrame._scripts.OnEvent(ns.eventFrame,"PLAYER_LOGIN")
-- capture content height
local H
local mt=getmetatable(UIParent)
local P; local orig=ns.UI.NewPage; ns.UI.NewPage=function(o) local p=orig(o); P=p; return p end
ns.Welcome:Show()
local y=P.top; for _,c in ipairs(P.cards) do y=y-c:Height()-10 end
print("welcome content height", -y+12, "room", 680-12-52)
assert(-y+12 <= 680-12-52, "fits")
local W=_G.RubberDuckyWelcome; assert(W._shown)
-- find page content via Welcome internals: recompute by walking cards
local y=0
print("ALL OK")
