dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
RubberDuckyDB={}
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
assert(ns.db.markerSize==56 and ns.db.markerStyle==15, "duck is the default bobber")
ns.Picker:Show()
assert(RubberDuckyIconPicker._shown)
-- find a grid button: frames created with OnClick after picker build
local btns={} for _,f in ipairs(frames) do if f._scripts.OnClick and f._scripts.OnEnter then btns[#btns+1]=f end end
assert(#btns==24, #btns)
btns[15]._scripts.OnClick(btns[15]); assert(ns.db.markerStyle==15)
ns.Picker:Toggle(); assert(not RubberDuckyIconPicker._shown)
SlashCmdList.RUBBERDUCKY("icons"); assert(RubberDuckyIconPicker._shown)
-- live marker swaps when picking during fishing
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731)
BOBGUID="GameObject-0-1-2-3-35591-AAA"
fire("PLAYER_SOFT_INTERACT_CHANGED", nil, BOBGUID); fire("NAME_PLATE_UNIT_ADDED","nameplate1")
assert(RubberDuckyBobberMarker._shown)
btns[3]._scripts.OnClick(btns[3]); assert(ns.db.markerStyle==3)
print("ALL OK")
