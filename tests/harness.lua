-- Mock WoW client for the tests: just enough of the game API for Rubber
-- Ducky to load and run. Frames record scripts and shown state; timers run
-- when a test calls runTimers().
-- permissive WoW mock
local log = {}
local function mock(name)
  local o = {_name=name, _scripts={}, _shown=true}
  return setmetatable(o, {__index=function(t,k)
    if k=="SetScript" then return function(self,s,f) self._scripts[s]=f end end
    if k=="GetScript" then return function(self,s) return self._scripts[s] end end
    if k=="Show" then return function(self) self._shown=true end end
    if k=="Hide" then return function(self) self._shown=false end end
    if k=="IsShown" or k=="IsVisible" then return function(self) return self._shown end end
    if k=="GetWidth" then return function() return 1920 end end
    if k=="GetHeight" then return function() return 1080 end end
    if k=="GetEffectiveScale" then return function() return 1 end end
    if k=="RegisterEvent" or k=="RegisterUnitEvent" then return function(self,e) local ev=rawget(self,"_events") or {}; rawset(self,"_events",ev); ev[e]=true end end
    if type(k)=="string" and k:match("^%l") then return nil end  -- fields: real frames only have Capitalized methods
    if k:match("^Create") then return function() return mock(k) end end
    if k=="GetData" then return function() return {} end end
    if k=="GetID" then return function() return 1 end end
    return function() end
  end})
end
frames = {}
function CreateFrame(t, n, p, tmpl) local f = mock("Frame:"..tostring(n)); frames[#frames+1]=f; if n then _G[n]=f end; return f end
UIParent = mock("UIParent")
STANDARD_TEXT_FONT="x"; ChatFontNormal={}; UISpecialFrames={}
function tinsert(t,v) table.insert(t,v) end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
NOW=100
function GetTime() return NOW end
timers={}
C_Timer={After=function(s,f) timers[#timers+1]={NOW+s,f} end}
function runTimers() local keep={} local due={} for _,t in ipairs(timers) do if t[1]<=NOW then due[#due+1]=t else keep[#keep+1]=t end end timers=keep; for _,t in ipairs(due) do t[2]() end end
cvars={Sound_SFXVolume="0.5",Sound_EnableSFX="1",Sound_MusicVolume="0.4",Sound_AmbienceVolume="0.6",Sound_DialogVolume="1",Sound_EnableEmoteSounds="1",Sound_EnablePetSounds="1",Sound_EnableErrorSpeech="1",Sound_EnableSoundWhenGameIsInBG="0",SoftTargetInteract="1",SoftTargetIconGameObject="0",SoftTargetIconInteract="1",SoftTargetNameplateInteract="0",SoftTargetInteractRange="10"}
function GetCVar(c) return cvars[c] end
function SetCVar(c,v) cvars[c]=tostring(v) end
function InCombatLockdown() return false end
C_Spell={GetSpellName=function(id) if id==7620 then return "Fishing" end end,
  GetSpellInfo=function(id) if id==131474 or id==7620 or id==7731 then return {name="Fishing", iconID=136245} end return {name="Fireball", iconID=1} end}
function UnitChannelInfo() return nil end
SOFT=false
function UnitExists(u) return SOFT end

PLATEY=500
PLATE=mock("plate"); PLATE.GetCenter=function() return 960, PLATEY end
C_NamePlate={GetNamePlateForUnit=function(t) if t=="nameplate1" then return PLATE end end}
function UnitGUID(u) if u=="nameplate1" then return BOBGUID end return nil end
VIB={}
C_GamePad={SetVibration=function(k,s) VIB[#VIB+1]=k..":"..s end, StopVibration=function() VIB[#VIB+1]="stop" end, IsEnabled=function() return true end}
SOUNDKIT={RAID_WARNING=8959}; PLAYED=0
function PlaySound() PLAYED=PLAYED+1 end
printed={}
function print(...) local t={} for i=1,select("#",...) do t[#t+1]=tostring((select(i,...))) end printed[#printed+1]=table.concat(t," ") if not QUIET then io.write("[print] ",table.concat(t," "),"\n") end end
SlashCmdList={}
-- Settings mock
local setmock = mock("Settings")
Settings = setmetatable({VarType={}}, {__index=function(t,k)
  if k=="RegisterVerticalLayoutCategory" then return function() return mock("cat"), mock("layout") end end
  return function() return mock(k) end end})
MinimalSliderWithSteppersMixin={Label={Right=1}}
function CreateSettingsListSectionHeaderInitializer() return {} end
issecretvalue=nil
function ClearOverrideBindings() end
function SetOverrideBinding() end
function SetOverrideBindingClick() end
function GetBindingKey() return "SPACE" end
function GetInventoryItemID() return nil end
function GetBindingAction(k, o) return "" end
date = os.date
