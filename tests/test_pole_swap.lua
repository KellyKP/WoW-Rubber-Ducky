dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
-- items: 100 sword (1H), 101 shield, 200 pole, 300 other pole
local ITEMS={[100]={2,7,1001},[101]={4,6,1002},[200]={2,20,2001},[300]={2,20,3001}}
C_Item={GetItemInfoInstant=function(id) local i=ITEMS[id]; if i then return id,nil,nil,nil,i[3],i[1],i[2] end end,
  GetItemSubClassInfo=function(c,s) return "Fishing Poles" end,
  GetItemCount=function(id) for _,v in pairs(BAGS) do if v==id then return 1 end end return 0 end,
  GetItemNameByID=function(id) return "Item"..id end,
  EquipItemByName=function(id,slot) EQUIP_CALLS[#EQUIP_CALLS+1]=slot..":"..id end}
EQUIP_CALLS={}
INV={[16]=100,[17]=101}; BAGS={200}
function GetInventoryItemID(u,s) return INV[s] end
C_Container={GetContainerNumSlots=function(b) return b==0 and #BAGS or 0 end, GetContainerItemID=function(b,s) return BAGS[s] end}
MACROS={}
function GetMacroIndexByName(n) for i,m in pairs(MACROS) do if m.name==n then return i end end return 0 end
function CreateMacro(n,icon,body,per) MACROS[#MACROS+1]={name=n,icon=icon,body=body,per=per}; return #MACROS end
function EditMacro(i,n,icon,body) MACROS[i]={name=n,icon=icon,body=body} end
PICKED=nil; function PickupMacro(i) PICKED=i end
C_Item.GetItemSubClassInfo=nil; function GetItemSubClassInfo() return "Fishing Poles" end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
RubberDuckyDB={seenWelcome=true}
local ev=ns.eventFrame
ev._scripts.OnEvent(ev,"ADDON_LOADED","RubberDucky"); ev._scripts.OnEvent(ev,"PLAYER_LOGIN")
-- the gear frame: find by registered event
local gearF; for _,f in ipairs(frames) do local e=rawget(f,"_events"); if e and e.BAG_UPDATE_DELAYED and e.PLAYER_EQUIPMENT_CHANGED then gearF=f end end
assert(gearF)
local function gev(...) gearF._scripts.OnEvent(gearF,...) end
gev("PLAYER_LOGIN"); NOW=NOW+0.4; runTimers()
assert(ns.db.lastWeapons.mh==100 and ns.db.lastWeapons.oh==101, "remembered weapons")
-- no macro until picked up
assert(#MACROS==0)
ns.Gear:Pickup(); assert(#MACROS==1 and PICKED==1 and MACROS[1].per==true)
local b=MACROS[1].body
assert(b:find("/equipslot %[noequipped:Fishing Poles%] 16 item:200"))
assert(b:find("/equipslot %[equipped:Fishing Poles%] 16 item:100") and b:find("17 item:101"))
assert(MACROS[1].icon==2001, "icon = pole (next press)")
-- equip the pole: OH empties first (half-done), then MH
INV[17]=nil; gev("PLAYER_EQUIPMENT_CHANGED",17); NOW=NOW+0.1; runTimers()
INV[16]=200; BAGS={100,101}; gev("PLAYER_EQUIPMENT_CHANGED",16); NOW=NOW+0.4; runTimers()
assert(ns.db.lastWeapons.oh==101, "half-done swap didn't overwrite")
assert(ns.db.lastPole==200)
assert(MACROS[1].icon==1001, "icon = sword next")
assert(MACROS[1].body:find("item:200"), "pole line kept while equipped")
-- /ducky pole swaps back
SlashCmdList.RUBBERDUCKY("pole"); assert(EQUIP_CALLS[1]=="16:100" and EQUIP_CALLS[2]=="17:101")
-- combat: no rewrite, pending after
InCombatLockdown=function() return true end
INV[16]=100; INV[17]=101; BAGS={200}; gev("PLAYER_EQUIPMENT_CHANGED",16); NOW=NOW+0.4; runTimers()
assert(MACROS[1].icon==1001, "unchanged in combat")
InCombatLockdown=function() return false end
gev("PLAYER_REGEN_ENABLED"); assert(MACROS[1].icon==2001, "updated after combat")
-- settings page paints
ns.Options.pages.overview:Refresh(); ns.Options.pages.onebutton:Refresh()
print("ALL OK")
