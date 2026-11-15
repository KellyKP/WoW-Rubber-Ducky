dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
GetAddOnMetadata=function(a,k) return k=="Version" and "0.16.0" or nil end
local realCF = CreateFrame
function CreateFrame(t, n, p, tmpl)
  local f = realCF(t, n, p, tmpl)
  if t=="CheckButton" then local c=false; f.SetChecked=function(_,x) c=x and true or false end; f.GetChecked=function() return c end end
  return f
end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function tick(s) for i=1,math.floor(s/0.1) do NOW=NOW+0.1; runTimers() end end
local n0=#printed
ev._scripts.OnEvent(ev,"ADDON_LOADED","RubberDucky"); ev._scripts.OnEvent(ev,"PLAYER_LOGIN")
assert(#printed==n0, "first login: no chat line")
assert(not (RubberDuckyWelcome and RubberDuckyWelcome._shown))
tick(3.5)
assert(RubberDuckyWelcome and RubberDuckyWelcome._shown, "welcome shows after the loading screen")
-- quick setup: one-button choice works
local page
for _,f in ipairs(frames) do end
-- click "Let's fish!": the last UIPanelButton created on the dialog with OnClick that closes
RubberDuckyWelcome._scripts.OnHide(RubberDuckyWelcome)
assert(RubberDuckyDB.seenWelcome==true)
-- second login: chat line, no screen
RubberDuckyWelcome._shown=false
ev._scripts.OnEvent(ev,"PLAYER_LOGIN"); tick(3.5)
assert(#printed==n0+1 and printed[#printed]:find("/ducky"), "chat line on later logins")
assert(not RubberDuckyWelcome._shown, "no welcome again")
-- reopen
SlashCmdList.RUBBERDUCKY("welcome"); assert(RubberDuckyWelcome._shown)
ns.Options.RefreshOverview()
print("ALL OK")
