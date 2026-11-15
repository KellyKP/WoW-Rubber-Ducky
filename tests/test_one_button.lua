dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
BIND={} ; UPDATES=0
local okFrame
local function announce() UPDATES=UPDATES+1; assert(UPDATES<300, "binding update loop!"); if okFrame then okFrame._scripts.OnEvent(okFrame,"UPDATE_BINDINGS") end end
function ClearOverrideBindings() BIND={}; announce() end
function SetOverrideBinding(o,p,key,action) BIND[key]=action; announce() end
function SetOverrideBindingClick(o,p,key,btn) BIND[key]="CLICK "..btn; announce() end
INTERACT={"F"}
function GetBindingKey(a) if a=="INTERACTTARGET" then return INTERACT[1], INTERACT[2] end end
POLE=true
function GetInventoryItemID(u,s) if s==16 then return POLE and 6256 or 1234 end end
C_Item={GetItemInfoInstant=function(id) if id==6256 then return id,nil,nil,nil,nil,2,20 end return id,nil,nil,nil,nil,2,7 end}
COMBAT=false; function InCombatLockdown() return COMBAT end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
for _,f in ipairs(frames) do local e=rawget(f,"_events"); if e and e.UPDATE_BINDINGS then okFrame=f end end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local function okfire(e, ...) okFrame._scripts.OnEvent(okFrame, e, ...) end
RubberDuckyDB={}
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN"); okfire("PLAYER_ENTERING_WORLD")
assert(RubberDuckyDB.oneKeyButton==4)
local nPrint=#printed
-- interact mode, keyboard
assert(BIND.F=="CLICK RubberDuckyCastButton", "interact casts when idle")
okfire("PLAYER_SOFT_INTERACT_CHANGED", nil, "Creature-0-1-2-3-68-AAAA"); assert(next(BIND)==nil)
okfire("PLAYER_SOFT_INTERACT_CHANGED", "Creature-0-1-2-3-68-AAAA", nil); assert(BIND.F)
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(next(BIND)==nil)
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); assert(BIND.F)
-- controller UI: no interact binding -> right trigger
INTERACT={}; cvars.GamePadEnable="1"; ns.OneKey:Update()
assert(BIND.PADRTRIGGER=="CLICK RubberDuckyCastButton")
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731); assert(BIND.PADRTRIGGER=="INTERACTTARGET")
fire("UNIT_SPELLCAST_CHANNEL_STOP","player")
-- left trigger
RubberDuckyDB.oneKeyButton=6; ns.OneKey:Update(); assert(BIND.PADLTRIGGER and not BIND.PADRTRIGGER)
-- combat / weapon
okfire("PLAYER_REGEN_DISABLED"); assert(next(BIND)==nil)
okfire("PLAYER_REGEN_ENABLED"); assert(BIND.PADLTRIGGER)
POLE=false; okfire("PLAYER_EQUIPMENT_CHANGED",16); assert(next(BIND)==nil); POLE=true; okfire("PLAYER_EQUIPMENT_CHANGED",16)
-- trigger names by controller type
assert(ns.OneKey.TriggerName("left")=="Left Trigger")
RubberDuckyDB.padType="playstation"; assert(ns.OneKey.TriggerName("right")=="R2")
RubberDuckyDB.padType="switch"; assert(ns.OneKey.TriggerName("left")=="ZL")
RubberDuckyDB.padType="auto"; InputDeviceIconSetManager={GetActiveInputDeviceIconSet=function() return "Shapes" end}
assert(ns.OneKey.TriggerName("right")=="R2")
-- nothing went to chat; all to the console buffer
SlashCmdList.RUBBERDUCKY("focus"); SlashCmdList.RUBBERDUCKY("focus"); SlashCmdList.RUBBERDUCKY("button")
for i=1,25 do NOW=NOW+0.1; runTimers() end
assert(#printed==nPrint, "status went to chat: "..tostring(printed[#printed]))
assert(#ns.consoleLines>5, "console buffer")
SlashCmdList.RUBBERDUCKY("debug"); assert(RubberDuckyDB.debugMode==true and RubberDuckyConsole and RubberDuckyConsole._shown)
SlashCmdList.RUBBERDUCKY("console"); assert(not RubberDuckyConsole._shown)
SlashCmdList.RUBBERDUCKY("help"); assert(#printed>nPrint, "help prints in chat")
print("ALL OK, binding updates:", UPDATES, "console lines:", #ns.consoleLines)
