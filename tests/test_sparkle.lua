dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
fire("UNIT_SPELLCAST_CHANNEL_START","player","g",7731)
BOBGUID="GameObject-0-1-2-3-35591-AAA"
fire("PLAYER_SOFT_INTERACT_CHANGED", nil, BOBGUID); fire("NAME_PLATE_UNIT_ADDED","nameplate1")
assert(RubberDuckyBobberSparkle._shown, "sparkle shows on bobber")
-- the anim groups: mocks created by CreateAnimationGroup with an OnFinished script
local finished=0
for i=1,30 do NOW=NOW+0.1; runTimers() end
fire("UNIT_SPELLCAST_CHANNEL_STOP","player"); assert(not RubberDuckyBobberSparkle._shown)
SlashCmdList.RUBBERDUCKY("sparkle"); assert(RubberDuckyDB.sparkleEnabled==false)
SlashCmdList.RUBBERDUCKY("test")
print("ALL OK")
