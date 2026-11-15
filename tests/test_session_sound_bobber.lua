dofile(TESTS .. "harness.lua")
-- anchor mock: plate SetPoint target works; GetCenter would error like Forever
PLATE.GetCenter=function() error("Can't measure restricted regions") end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local fader; for _,f in ipairs(frames) do if f._scripts.OnUpdate and not fader then fader=f end end
local function tick(sec) for i=1,math.floor(sec/0.02) do NOW=NOW+0.02; if fader._shown then fader._scripts.OnUpdate(fader,0.02) end; runTimers() end end
RubberDuckyDB={}
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
assert(ns.db.lingerSeconds==nil and ns.db.fadeIn==1 and ns.db.fadeOut==2.5)
RubberDuckyDB.soundReturnOnLoot=false -- this test checks the linger path
RubberDuckyDB.probeEnabled=true
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731)
tick(0.5)
local mid=tonumber(cvars.Sound_MusicVolume); print("music mid fade-in", mid)
assert(mid<0.4 and mid>0.06, "should be mid-fade")
tick(0.6); assert(cvars.Sound_MusicVolume=="0.060", cvars.Sound_MusicVolume); assert(cvars.Sound_SFXVolume=="1.000")
-- glow anchoring
BOBGUID="GameObject-0-6827-0-4-35591-B53698C19B"
fire("PLAYER_SOFT_INTERACT_CHANGED", nil, BOBGUID); fire("NAME_PLATE_UNIT_ADDED","nameplate1")
assert(RubberDuckyBobberSparkle._shown, "glow should show"); assert(RubberDuckyBobberMarker._shown, "marker should show")
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); assert(not RubberDuckyBobberSparkle._shown and not RubberDuckyBobberMarker._shown)
tick(4)  -- linger 5s not yet over
assert(cvars.Sound_MusicVolume=="0.060")
tick(2.0) -- linger ends -> fade out starts
local m2=tonumber(cvars.Sound_MusicVolume); print("music mid fade-out", m2); assert(m2>0.06 and m2<0.4)
-- recast mid fade-out: turns around, keeps originals
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(1.2)
assert(cvars.Sound_MusicVolume=="0.060", cvars.Sound_MusicVolume)
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); tick(5+3)
assert(cvars.Sound_MusicVolume=="0.4" and cvars.Sound_SFXVolume=="0.5" and cvars.Sound_EnableEmoteSounds=="1", cvars.Sound_MusicVolume)
assert(RubberDuckyDB.savedSound==nil)
-- logout mid-session is instant
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(1.2)
fire("PLAYER_LOGOUT"); assert(cvars.Sound_MusicVolume=="0.4" and RubberDuckyDB.savedSound==nil)
-- combat quick fade
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(1.2)
fire("PLAYER_REGEN_DISABLED"); tick(0.6); assert(cvars.Sound_MusicVolume=="0.4")
for _,c in ipairs({"","test","marker","marker","icons","icons","vibrate","restore"}) do SlashCmdList.RUBBERDUCKY(c) end
print("ALL OK")
-- /ducky debug only toggles debug mode (no stray welcome line)
local n=#printed; SlashCmdList.RUBBERDUCKY("debug"); assert(#printed==n, "debug prints nothing in chat")
print("DEBUG OK")
