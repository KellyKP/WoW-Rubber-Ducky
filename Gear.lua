-- Rubber Ducky: pole swap. A "Ducky Pole" character macro toggles between your
-- fishing pole and the last weapons you held. Conditions make one press work in
-- combat, when the macro can't be rewritten (equipping is async, so later lines
-- still see the old state):
--   /equipslot [noequipped:Fishing Poles] 16 item:<pole>
--   /equipslot [equipped:Fishing Poles] 16 item:<main hand>
--   /equipslot [equipped:Fishing Poles] 17 item:<off-hand>

local _, ns = ...
local Gear = {}
ns.Gear = Gear

local MH, OH = 16, 17
local MACRO = "Ducky Pole"
local POLE_ICON = "Interface\\Icons\\INV_Fishingpole_02"

local function Info(id)
    if not id then return end
    return ns.Safe(function()
        local _, _, _, _, icon, classID, subclassID = C_Item.GetItemInfoInstant(id)
        return icon, classID, subclassID
    end)
end

local function IsPole(id)
    local _, classID, subclassID = Info(id)
    return classID == 2 and subclassID == 20
end
Gear.IsPole = IsPole

local function Equipped(slot) return ns.Safe(GetInventoryItemID, "player", slot) end
function Gear.PoleEquipped() return IsPole(Equipped(MH)) end

-- localized "Fishing Poles" for the conditions
local function PolesName()
    local name = ns.Safe(function()
        return (C_Item.GetItemSubClassInfo or GetItemSubClassInfo)(2, 20)
    end)
    return name or "Fishing Poles"
end

local function InBags(id)
    if not id then return false end
    return (ns.Safe(function() return C_Item.GetItemCount(id) end) or 0) > 0
end

-- last pole used if you still have it, else the first in your bags
local function FindPole()
    local last = ns.db.lastPole
    if last and (InBags(last) or Equipped(MH) == last) then return last end
    local found
    ns.Safe(function()
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
                local id = C_Container.GetContainerItemID(bag, slot)
                if id and IsPole(id) then found = id; return end
            end
        end
    end)
    return found
end
Gear.FindPole = FindPole

-- called once gear changes settle, so a half-done swap isn't recorded
function Gear:Remember()
    local mh, oh = Equipped(MH), Equipped(OH)
    if mh and IsPole(mh) then
        ns.db.lastPole = mh
    elseif mh then
        ns.db.lastWeapons = { mh = mh, oh = oh }
    end
end

function Gear:Body()
    local poles = PolesName()
    local lines = {}
    local pole = FindPole()
    local w = ns.db.lastWeapons
    if pole then lines[#lines + 1] = ("/equipslot [noequipped:%s] 16 item:%d"):format(poles, pole) end
    if w and w.mh then
        lines[#lines + 1] = ("/equipslot [equipped:%s] 16 item:%d"):format(poles, w.mh)
        if w.oh then lines[#lines + 1] = ("/equipslot [equipped:%s] 17 item:%d"):format(poles, w.oh) end
    end
    if #lines == 0 then lines[1] = "/run print('Rubber Ducky: no fishing pole found yet')" end
    return table.concat(lines, "\n")
end

-- icon: what the next press puts on
function Gear:NextIcon()
    if Gear.PoleEquipped() then
        local w = ns.db.lastWeapons
        return (w and w.mh and Info(w.mh)) or POLE_ICON
    end
    local pole = FindPole()
    return (pole and Info(pole)) or POLE_ICON
end

local function MacroIndex()
    local i = ns.Safe(GetMacroIndexByName, MACRO)
    return (i and i > 0) and i or nil
end

local pending = false
function Gear:Update(create)
    if InCombatLockdown() then pending = true; return end
    pending = false
    local index = MacroIndex()
    local body, icon = self:Body(), self:NextIcon()
    if index then
        ns.Safe(EditMacro, index, MACRO, icon, body)
    elseif create then
        local ok, i = pcall(CreateMacro, MACRO, icon, body, true) -- per character
        if not ok or not i then
            ns.Print("pole swap: couldn't create the macro (%s)", tostring(i or "your character macros may be full"))
            return
        end
        index = i
    end
    if Gear.onChange then Gear.onChange() end
    return index
end

function Gear:Pickup()
    if InCombatLockdown() then return end
    local index = self:Update(true)
    if index then ns.Safe(PickupMacro, index) end
end

-- /ducky pole
function Gear:Swap()
    if InCombatLockdown() then ns.Print("pole swap: use the macro in combat"); return false end
    local equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName
    if Gear.PoleEquipped() then
        local w = ns.db.lastWeapons
        if not (w and w.mh) then ns.Print("pole swap: no weapons remembered yet"); return false end
        ns.Safe(equip, w.mh, MH)
        if w.oh then ns.Safe(equip, w.oh, OH) end
    else
        local pole = FindPole()
        if not pole then ns.Print("pole swap: no fishing pole in your bags"); return false end
        ns.Safe(equip, pole, MH)
    end
    return true
end

-------------------------------------------------------------------------------
local settle = 0
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:SetScript("OnEvent", function(_, event, slot)
    if not ns.db then return end
    if event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_LOGIN" then
        if event == "PLAYER_EQUIPMENT_CHANGED" and slot ~= MH and slot ~= OH then return end
        settle = settle + 1
        local token = settle
        C_Timer.After(0.3, function()
            if token ~= settle then return end
            Gear:Remember()
            Gear:Update()
        end)
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pending then Gear:Update() end
    else
        Gear:Update()
    end
end)
