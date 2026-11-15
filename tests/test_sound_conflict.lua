dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
-- the watcher is the frame that registered CVAR_UPDATE
local watcher; for _,f in ipairs(frames) do local e=rawget(f,"_events"); if e and e.CVAR_UPDATE then watcher=f end end
local fader; for _,f in ipairs(frames) do if f._scripts.OnUpdate and not fader then fader=f end end
local function tick(sec) for i=1,math.floor(sec/0.02) do NOW=NOW+0.02; if fader._shown then fader._scripts.OnUpdate(fader,0.02) end; runTimers() end end
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); tick(0.5)
local L=ns.consoleLines; local n0=#L
-- our own writes echo back: no warning
watcher._scripts.OnEvent(watcher,"CVAR_UPDATE","Sound_MusicVolume", cvars.Sound_MusicVolume)
assert(#L==n0, "false warning on our own write")
-- another addon writes 0.30
watcher._scripts.OnEvent(watcher,"CVAR_UPDATE","Sound_MusicVolume","0.30")
assert(#L==n0+1 and L[#L]:find("another addon"), tostring(L[#L]))
watcher._scripts.OnEvent(watcher,"CVAR_UPDATE","Sound_AmbienceVolume","0.30")
assert(#L==n0+1, "warns only once")
print("ALL OK")
