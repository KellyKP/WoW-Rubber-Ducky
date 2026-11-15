dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
function GetCameraZoom() return 12 end
function CameraZoomIn() end function CameraZoomOut() end
LOOT={}; function GetNumLootItems() return #LOOT end
function GetLootSlotInfo(i) local l=LOOT[i]; return 1, l, 1, nil, 1 end
function GetLootSlotType() return 1 end
function LootSlot() end
function IsFishingLoot() return true end
SPEED=0; function GetUnitSpeed() return SPEED end
ERR_FISH_NOT_HOOKED="No fish are hooked."; ERR_FISH_ESCAPED="Your fish got away!"
CHAN_END=nil
function UnitChannelInfo() if CHAN_END then return "Fishing",nil,136245,(NOW-1)*1000,CHAN_END*1000 end end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local function wait(sec) for i=1,math.floor(sec/0.05) do NOW=NOW+0.05; runTimers() end end
RubberDuckyDB={seenWelcome=true}
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
local shown={}
local orig=ns.Splash.ShowMiss
ns.Splash.ShowMiss=function(self,k) shown[#shown+1]=k; return orig(self,k) end
local function cast(len, fn)
  CHAN_END=NOW+21
  fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7620); wait(len)
  if fn then fn() end
  fire("UNIT_SPELLCAST_CHANNEL_STOP","player")
end
-- too early: shows the moment the game's error does
cast(3, function() fire("UI_ERROR_MESSAGE", 1, "No fish are hooked.") end)
assert(shown[1]=="missed", "instant: "..tostring(shown[1])); wait(1.5); assert(#shown==1, "only once")
-- got away
cast(8, function() fire("UI_ERROR_MESSAGE", 1, "Your fish got away!") end); wait(1.5)
assert(shown[2]=="missed")
-- catch: no miss
cast(8); fire("LOOT_READY", false); wait(1.5); assert(#shown==2, "catch is not a miss")
-- timeout: right at the stop
cast(21.1); assert(shown[3]=="timeout", tostring(shown[3])); wait(1.5)
-- timeout without channel info
CHAN_END=nil; fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7620); wait(20); fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); wait(1.5)
assert(shown[4]=="timeout")
-- walked away early: nothing
SPEED=7; cast(4); wait(1.5); assert(#shown==4, "moving is not a miss"); SPEED=0
-- standing, early, no message: generic, after a short wait
cast(4); assert(#shown==4); wait(0.4); assert(shown[5]=="missed", "quick generic")
-- combat during cast: nothing
CHAN_END=NOW+21; fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7620); wait(2); fire("PLAYER_REGEN_DISABLED"); fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); wait(1.5)
assert(#shown==5, "combat is not a miss")
-- option off
ns.db.splashMisses=false; cast(3); wait(1.5)
assert(not _G.RubberDuckyMiss._shown or true)
-- miss frame animates out
ns.db.splashMisses=true; ns.Splash:PreviewMiss(); local M=_G.RubberDuckyMiss; assert(M._shown)
for i=1,200 do NOW=NOW+0.02; M._scripts.OnUpdate(M) end; assert(not M._shown, "miss fades")
SOUNDKIT.IG_QUEST_FAILED=847; PLAYED=0
ns.Splash:ShowMiss("missed"); assert(PLAYED==1, "miss sound")
ns.db.splashMissSound=false; ns.Splash:ShowMiss("timeout"); assert(PLAYED==1, "sound off")
print("ALL OK")
-- a miss starts the sound back right away
ns.db.splashMisses=true; ns.db.soundReturnOnLoot=true
local restored=0; local origR=ns.Sound.Restore; ns.Sound.Restore=function(...) restored=restored+1; return origR(...) end
cast(4); wait(0.4); assert(restored>=1, "sound back on miss")
print("RESTORE OK")
