dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
-- first OpenToCategory of the session opens the window but selects nothing
-- (its list isn't built yet); after that it selects. SelectCategory must
-- never be called by the addon (that's what got blocked in game).
local OURCAT
local group = {GetParentCategory=function() return nil end, SetExpanded=function(s,v) s.expanded=v end}
CURRENT=nil
SettingsPanel = {shown=false, tabsGroup={Select=function(s,t) SettingsPanel.tab=t end}, AddOnsTab="addons"}
function SettingsPanel:IsShown() return self.shown end
function SettingsPanel:GetCurrentCategory() return CURRENT end
function SettingsPanel:SelectCategory(c) error("addon must not call SelectCategory") end
BUILT=false; OPENS=0
Settings = setmetatable({VarType={}}, {__index=function(t,k)
  if k=="RegisterCanvasLayoutCategory" then return function() OURCAT={GetID=function() return 77 end, GetParentCategory=function() return group end, SetExpanded=function() end}; return OURCAT end end
  if k=="RegisterCanvasLayoutSubcategory" then return function() return {GetParentCategory=function() return OURCAT end} end end
  if k=="OpenToCategory" then return function(id) assert(id==77); OPENS=OPENS+1; SettingsPanel.shown=true
    if BUILT then CURRENT=OURCAT end; BUILT=true end end
  return function() end end})
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
RubberDuckyDB={seenWelcome=true}
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
assert(OURCAT, "category built")
SlashCmdList.RUBBERDUCKY("")
assert(SettingsPanel.shown and CURRENT==nil, "first open: nothing selected yet")
NOW=NOW+0.06; runTimers()
assert(CURRENT==OURCAT and OPENS==2, "second OpenToCategory selects our page")
-- next time it selects at once: no second call
SettingsPanel.shown=false; CURRENT=nil
SlashCmdList.RUBBERDUCKY(""); NOW=NOW+0.06; runTimers()
assert(CURRENT==OURCAT and OPENS==3, "one call when the list is built")
-- blocked action blamed on us goes to the console
ns.eventFrame._scripts.OnEvent(ns.eventFrame, "ADDON_ACTION_BLOCKED", "RubberDucky", "Foo()")
assert(ns.consoleLines[#ns.consoleLines]:find("Foo"), "logged")
ns.eventFrame._scripts.OnEvent(ns.eventFrame, "ADDON_ACTION_BLOCKED", "OtherAddon", "Bar()")
assert(ns.consoleLines[#ns.consoleLines]:find("OtherAddon"), "others logged too")
print("BLOCK OK")
