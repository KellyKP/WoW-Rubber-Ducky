dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
ZOOM=12
function GetCameraZoom() return ZOOM end
function CameraZoomIn(n) ZOOM=ZOOM-n end
function CameraZoomOut(n) ZOOM=ZOOM+n end
TEMP={}
C_CVar={GetCVar=GetCVar, SetCVar=SetCVar, SetTempCVar=function(k,v) TEMP[k]=v end, RemoveTempCVar=function(k) TEMP[k]="removed" end, GetCVarBool=function(k) return true end}
cvars.test_cameraDynamicPitch="0"; cvars.test_cameraDynamicPitchBaseFovPad="0.4"; cvars.test_cameraOverShoulder="0"
cvars.test_cameraTargetFocusInteractEnable="0"; cvars.test_cameraTargetFocusInteractStrengthYaw="1"; cvars.test_cameraTargetFocusInteractStrengthPitch="0.75"
cvars.CameraKeepCharacterCentered="1"
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local fader; for _,f in ipairs(frames) do if f._scripts.OnUpdate and not fader then fader=f end end
local function tick(sec) for i=1,math.floor(sec/0.02) do NOW=NOW+0.02; if fader._shown then fader._scripts.OnUpdate(fader,0.02) end; runTimers() end end
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731)
assert(ZOOM==4, ZOOM); assert(cvars.test_cameraDynamicPitch=="1" and cvars.test_cameraDynamicPitchBaseFovPad=="0.15")
assert(cvars.test_cameraTargetFocusInteractEnable=="0", "aim no longer touched")
assert(TEMP.CameraKeepCharacterCentered=="0")
-- toggling aim off mid-session reverts it
RubberDuckyDB.cameraZoom=6; ns.Camera:Reapply(); assert(ZOOM==6)
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); tick(4); assert(ZOOM==6, "still fishing view during linger")
tick(2)
assert(ZOOM==12, ZOOM); assert(cvars.test_cameraDynamicPitch=="0" and cvars.test_cameraDynamicPitchBaseFovPad=="0.4" and cvars.test_cameraTargetFocusInteractEnable=="0")
assert(TEMP.CameraKeepCharacterCentered=="1"); assert(RubberDuckyDB.savedCamera==nil)
-- combat snaps back
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(ZOOM==6)
fire("PLAYER_REGEN_DISABLED"); assert(ZOOM==12 and cvars.test_cameraDynamicPitch=="0")
-- crash recovery
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); ns.sessionActive=false; ns.fishing=false
fire("PLAYER_LOGIN"); assert(ZOOM==12 and RubberDuckyDB.savedCamera==nil and cvars.test_cameraTargetFocusInteractEnable=="0")
-- disabled: no camera change
RubberDuckyDB.cameraEnabled=false; fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(ZOOM==12)
SlashCmdList.RUBBERDUCKY("camera"); assert(RubberDuckyDB.cameraEnabled==true)
print("ALL OK")
-- return-on-loot
RubberDuckyDB.cameraEnabled=true; ns.sessionActive=false; ns.fishing=false; RubberDuckyDB.savedCamera=nil; ZOOM=12
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(ZOOM==6, ZOOM)
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); tick(0.3); fire("LOOT_OPENED")
assert(ZOOM==12 and RubberDuckyDB.savedCamera==nil, "camera back on loot")
assert(ns.sessionActive, "sound focus still lingering")
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(ZOOM==6, "recast zooms in again "..ZOOM)
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); tick(7); assert(ZOOM==12)
-- non-fishing loot (mob) doesn't touch camera mid-session? only after fishing stop window
print("LOOT OK")
