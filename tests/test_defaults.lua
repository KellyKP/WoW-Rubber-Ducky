dofile(TESTS .. "harness.lua")
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
RubberDuckyDB={seenWelcome=true}
ns.eventFrame._scripts.OnEvent(ns.eventFrame,"ADDON_LOADED","RubberDucky")
assert(ns.db.splashCatchSound==true and #ns.Splash.BANNERS==4)
print("ALL OK")
