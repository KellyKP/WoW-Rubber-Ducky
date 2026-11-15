dofile(TESTS .. "harness.lua")
GameTooltip=setmetatable({},{__index=function() return function() end end})
ZOOM=12
function GetCameraZoom() return ZOOM end
function CameraZoomIn(n) ZOOM=ZOOM-n end
function CameraZoomOut(n) ZOOM=ZOOM+n end
-- sliders/checkboxes need a little state
local realCF = CreateFrame
function CreateFrame(t, n, p, tmpl)
  local f = realCF(t, n, p, tmpl)
  if t=="Slider" then local v=0; f.SetValue=function(self,x) v=x; if self._scripts.OnValueChanged then self._scripts.OnValueChanged(self,x) end end; f.GetValue=function() return v end end
  if t=="CheckButton" then local c=false; f.SetChecked=function(_,x) c=x and true or false end; f.GetChecked=function() return c end end
  return f
end
local ns = {}
for _, f in ipairs({"Core","Console","Sound","Bobber","Camera","OneKey","Gear","Probe","Picker","Splash","UI","Options","Welcome"}) do
  assert(loadfile(ADDON..f..".lua"))("RubberDucky", ns)
end
local ev = ns.eventFrame
local function fire(e, ...) ev._scripts.OnEvent(ev, e, ...) end
local function flush() for i=1,5 do NOW=NOW+0.01; runTimers() end end
fire("ADDON_LOADED","RubberDucky"); fire("PLAYER_LOGIN")
local P = ns.Options.pages
for _, name in ipairs({"overview","sound","bobber","camera","onebutton","developer"}) do
  assert(P[name], "page missing: "..name)
  P[name].frame._scripts.OnShow(P[name].frame)   -- opening the page refreshes it
end
-- click every choice button on every page, check no errors and values land
local clicks = 0
for name, page in pairs(P) do
  for _, ctl in ipairs(page.controls) do
    if ctl.buttons then
      for _, b in ipairs(ctl.buttons) do b._scripts.OnClick(b); flush(); clicks = clicks + 1 end
    end
  end
end
-- presets landed
assert(RubberDuckyDB.fadeIn==2.0 and RubberDuckyDB.fadeOut==5.0, "last fade preset = slow")
assert(RubberDuckyDB.markerSize==80 and RubberDuckyDB.sparkleAmount==3 and RubberDuckyDB.sparkleSpread==130)
assert(RubberDuckyDB.cameraZoom==7 and RubberDuckyDB.cameraTilt==0.3 and RubberDuckyDB.cameraShoulder==1.5)
assert(RubberDuckyDB.oneKeyButton==5 and RubberDuckyDB.padType=="switch")
-- trigger labels follow controller type
P.onebutton:Refresh()
local labels = {}
for _, ctl in ipairs(P.onebutton.controls) do if ctl.buttons and #ctl.buttons==3 then for i,b in ipairs(ctl.buttons) do labels[i]=b.text._t end end end
-- header toggles
for name, page in pairs(P) do page:Refresh() end
-- random bobber checkbox path + picker refresh
ns.db.markerStyle = 7; P.bobber:Refresh(); ns.Options.RefreshOverview()
print("ALL OK  choice clicks:", clicks)
