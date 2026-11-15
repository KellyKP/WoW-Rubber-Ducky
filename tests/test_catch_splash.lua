dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
function GetCameraZoom() return 12 end
function CameraZoomIn() end function CameraZoomOut() end
LOOT={} ; TAKEN={}
function GetNumLootItems() return #LOOT end
function GetLootSlotInfo(i) local l=LOOT[i]; return l[2], l[1], l[3], nil, l[4] end
function GetLootSlotType(i) return LOOT[i][5] and 2 or 1 end
function LootSlot(i) TAKEN[#TAKEN+1]=LOOT[i][1] end
function IsFishingLoot() return true end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
RubberDuckyDB={seenWelcome=true}
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
assert(ns.Options.pages.onebutton and not ns.Options.pages.splash, "splash on one-button page")
local S=_G.RubberDuckySplash
assert(S==nil or not S._shown)
-- our auto loot: splash with the items, read before looting
LOOT={{"Raw Brilliant Smallfish",1,3,1},{"7 Copper",2,0,nil,true}}
fire("LOOT_READY", false)
S=_G.RubberDuckySplash
assert(S and S._shown, "splash shown")
assert(#TAKEN==2, "looted")
local items=ns.Splash.ReadLoot(); assert(items[1].count==3 and items[2].count==0)
-- animate to the end: hides
for i=1,250 do NOW=NOW+0.02; S._scripts.OnUpdate(S,0.02) end
assert(not S._shown, "splash gone")
-- game auto loot: we don't loot but still splash
TAKEN={}; NOW=NOW+1
fire("LOOT_READY", true)
assert(#TAKEN==0 and S._shown, "game autolooted -> splash only")
for i=1,250 do NOW=NOW+0.02; S._scripts.OnUpdate(S,0.02) end
-- manual looting (both off): no splash
ns.db.autoLootFishing=false; NOW=NOW+1
fire("LOOT_READY", false); assert(not S._shown, "loot window -> no splash")
-- splash off
ns.db.autoLootFishing=true; ns.db.splashEnabled=false; NOW=NOW+1
fire("LOOT_READY", false); assert(not S._shown and #TAKEN==2, "off but still loots")
ns.db.splashEnabled=true
-- fixed banner + preview
ns.db.splashBanner=4; ns.Splash:Preview(); assert(S._shown)
print("ALL OK")
PLAYED=0
ns.db.splashCatchSound=true; ns.Splash:Preview(); assert(PLAYED==1, "fanfare played")
ns.db.splashCatchSound=false; ns.Splash:Preview(); assert(PLAYED==1)
print("SOUND OK")
