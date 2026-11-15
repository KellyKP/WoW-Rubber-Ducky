dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
ZOOM=12
function GetCameraZoom() return ZOOM end
function CameraZoomIn(n) ZOOM=ZOOM-n end
function CameraZoomOut(n) ZOOM=ZOOM+n end
C_CVar={GetCVar=GetCVar, SetCVar=SetCVar, SetTempCVar=function() end, RemoveTempCVar=function() end, GetCVarBool=function() return false end}
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local fader; for _,f in ipairs(frames) do if f._scripts.OnUpdate and not fader then fader=f end end
local function tick(sec) for i=1,math.floor(sec/0.02) do NOW=NOW+0.02; if fader._shown then fader._scripts.OnUpdate(fader,0.02) end; runTimers() end end
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(1.2)
assert(cvars.Sound_MusicVolume=="0.060" and ZOOM==4)
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); tick(0.25); fire("LOOT_OPENED")
assert(ZOOM==12, "camera back on loot")
tick(0.5); local m=tonumber(cvars.Sound_MusicVolume); print("music 0.5s after loot", m)
assert(m>0.06 and m<0.4, "sound fading back with the camera")
-- recast mid fade-back: sound turns around, camera zooms in
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(ZOOM==4)
tick(1.2); assert(cvars.Sound_MusicVolume=="0.060", cvars.Sound_MusicVolume)
-- catch, let fade finish, recast within linger: sound re-applies from clean baseline
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); tick(0.25); fire("LOOT_OPENED"); tick(3)
assert(cvars.Sound_MusicVolume=="0.4" and RubberDuckyDB.savedSound==nil, cvars.Sound_MusicVolume)
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(1.2)
assert(cvars.Sound_MusicVolume=="0.060", "re-applied after full fade-back: "..cvars.Sound_MusicVolume)
-- option off: sound waits for linger
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); RubberDuckyDB.soundReturnOnLoot=false; tick(0.25); fire("LOOT_OPENED"); tick(1)
assert(cvars.Sound_MusicVolume=="0.060", "waits for linger when off")
tick(8); assert(cvars.Sound_MusicVolume=="0.4")
-- console copy text strips colours
ns.Print("hello |cffff0000red|r world")
ns.Console.ShowCopy(); local txt = RubberDuckyConsoleCopy.edit
print("ALL OK")
