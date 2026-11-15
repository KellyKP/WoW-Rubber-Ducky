dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
ZOOM=12
function GetCameraZoom() return ZOOM end
function CameraZoomIn(n) ZOOM=ZOOM-n end
function CameraZoomOut(n) ZOOM=ZOOM+n end
LOOT={} ; TAKEN={}
function GetNumLootItems() return #LOOT end
function LootSlot(i) TAKEN[#TAKEN+1]=LOOT[i] end
FISHLOOT=true; function IsFishingLoot() return FISHLOOT end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local fader; for _,f in ipairs(frames) do if f._scripts.OnUpdate and not fader then fader=f end end
local function tick(sec) for i=1,math.floor(sec/0.02) do NOW=NOW+0.02; if fader._shown then fader._scripts.OnUpdate(fader,0.02) end; runTimers() end end
RubberDuckyDB={seenWelcome=true}
cvars.autoLootDefault="0"
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
-- first catch, reeled in with a trigger: game doesn't auto loot (false) -> we take it
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(1.2)
assert(cvars.autoLootDefault=="0", "game setting untouched")
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); LOOT={"Raw Brilliant Smallfish"}
fire("LOOT_READY", false); fire("LOOT_READY", false)
assert(#TAKEN==1 and TAKEN[1]=="Raw Brilliant Smallfish", "took the catch once: "..#TAKEN)
assert(ZOOM==12, "camera back on loot ready")
tick(0.5); assert(tonumber(cvars.Sound_MusicVolume)>0.06, "sound fading back")
fire("LOOT_OPENED", false) -- no double fade restart problems
-- game already auto-looting: leave it
TAKEN={}; NOW=NOW+5
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); fire("UNIT_SPELLCAST_CHANNEL_STOP","player")
fire("LOOT_READY", true); assert(#TAKEN==0)
-- not fishing loot (a mob), not right after a cast: untouched
TAKEN={}; NOW=NOW+30; FISHLOOT=false; fire("LOOT_READY", false); assert(#TAKEN==0, "mob loot untouched")
-- switched off
FISHLOOT=true; RubberDuckyDB.autoLootFishing=false; NOW=NOW+5; fire("LOOT_READY", false); assert(#TAKEN==0)
-- leftover game setting from the old version gets restored at login
print("ALL OK")
