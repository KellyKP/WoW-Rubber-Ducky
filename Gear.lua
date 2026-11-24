-- Rubber Ducky: pole swap. The "Ducky Pole" character macro runs
-- "/ducky swap", which equips your pole or the last weapons you held.

local _, ns = ...
local Gear = {}
ns.Gear = Gear

local MH, OH = 16, 17
local MACRO, MACRO_BODY = "Ducky Pole", "/ducky swap"
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

-- remembered gear is per character: { pole = id, weapons = { mh, oh } }
function Gear.Mine()
    local key = (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
    ns.db.gear = ns.db.gear or {}
    ns.db.gear[key] = ns.db.gear[key] or {}
    return ns.db.gear[key]
end

local function Equipped(slot) return ns.Safe(GetInventoryItemID, "player", slot) end
function Gear.PoleEquipped() return IsPole(Equipped(MH)) end

local function InBags(id)
    if not id then return false end
    return (ns.Safe(function() return C_Item.GetItemCount(id) end) or 0) > 0
end

-- Broken: in your bags, but worn down to nothing (0 durability). The game
-- still lets you hold it, it just does nothing until it's repaired.
local function Broken(id)
    if not id then return false end
    local broken, whole = false, false
    ns.Safe(function()
        for bag = 0, (NUM_BAG_SLOTS or 4) do
            for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
                if C_Container.GetContainerItemID(bag, slot) == id then
                    local cur, max = C_Container.GetContainerItemDurability(bag, slot)
                    if max and max > 0 and cur == 0 then broken = true else whole = true end
                end
            end
        end
    end)
    return broken and not whole
end
Gear.Broken = Broken

-- last pole used if you still have it, else the first in your bags
local function FindPole()
    local last = Gear.Mine().pole
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
-- The swap splash follows what actually changed, not what was asked for, so a
-- manual swap in between can't make it show the wrong one.
local swapAt = 0      -- when /ducky swap last equipped something
local wasPole         -- main hand held a pole at the last look (nil before login)

local function CheckSwapSplash()
    local mh = Equipped(MH)
    if not mh then return end
    local isPole = IsPole(mh)
    if wasPole ~= nil and isPole ~= wasPole and GetTime() - swapAt < 3 and ns.Splash then
        swapAt = 0
        ns.Safe(ns.Splash.ShowSwap, ns.Splash, isPole and "pole" or "weapon")
    end
    wasPole = isPole
end

function Gear:Remember()
    local mh, oh = Equipped(MH), Equipped(OH)
    if mh and IsPole(mh) then
        Gear.Mine().pole = mh
    elseif mh then
        Gear.Mine().weapons = { mh = mh, oh = oh }
    end
end

-- icon: what the next press puts on
function Gear:NextIcon()
    if Gear.PoleEquipped() then
        local w = Gear.Mine().weapons
        return (w and w.mh and Info(w.mh)) or POLE_ICON
    end
    local pole = FindPole()
    return (pole and Info(pole)) or POLE_ICON
end

local function MacroIndex()
    local i = ns.Safe(GetMacroIndexByName, MACRO)
    return (i and i > 0) and i or nil
end

local pending, lastIcon, waiting = false, nil, false

-- EditMacro while the Macros window is open can throw away an edit in
-- progress, so wait for it to close
local function MacroWindowOpen() return MacroFrame and MacroFrame:IsShown() end

function Gear:Update(create)
    if InCombatLockdown() then pending = true; return end
    pending = false
    local index = MacroIndex()
    local icon = self:NextIcon()
    if index then
        if icon ~= lastIcon then
            if MacroWindowOpen() then
                if not waiting then
                    waiting = true
                    C_Timer.After(1, function() waiting = false; Gear:Update() end)
                end
                return index
            end
            ns.Safe(EditMacro, index, MACRO, icon, MACRO_BODY)
            lastIcon = icon
        end
    elseif create then
        local ok, i = pcall(CreateMacro, MACRO, icon, MACRO_BODY, true) -- per character
        if not ok or not i then
            ns.Print("pole swap: couldn't create the macro (%s)", tostring(i or "your character macros may be full"))
            return
        end
        index = i
        lastIcon = icon
    end
    if Gear.onChange then Gear.onChange() end
    return index
end

function Gear:Pickup()
    if InCombatLockdown() then return end
    local index = self:Update(true)
    if index then ns.Safe(PickupMacro, index) end
end

-- you pressed something, so problems go to chat
local Say = function(msg) ns.Chat(msg) end

-- target: "pole", "weapon", or nil to toggle
function Gear:Swap(target)
    if InCombatLockdown() then Say("Whoa, not in the middle of a fight! Swap once combat's over."); return false end
    if GetTime() - swapAt < 1 then return false end -- previous swap still going through
    local toPole
    if target == "pole" then toPole = true
    elseif target == "weapon" then toPole = false
    else toPole = not Gear.PoleEquipped() end
    local equip = (C_Item and C_Item.EquipItemByName) or EquipItemByName
    if toPole then
        if Gear.PoleEquipped() then return false end
        local pole = FindPole()
        if not pole then Say("Oops! Can't find your fishing pole. Did you misplace it?"); return false end
        if Broken(pole) then Say("Heads up: your fishing pole's broken! It won't catch a thing until it's repaired.") end
        swapAt = GetTime()
        ns.Safe(equip, pole, MH)
    else
        if not Gear.PoleEquipped() and target == "weapon" then return false end
        local w = Gear.Mine().weapons
        if not (w and w.mh) then Say("I don't know your weapon yet! Equip it once and I'll remember it."); return false end
        if not InBags(w.mh) and Equipped(MH) ~= w.mh then
            Say("Oops! Can't find your weapon. Did you misplace it?"); return false
        end
        if Broken(w.mh) or Broken(w.oh) then
            Say("Heads up: your weapon's broken! It won't do much until it's repaired.")
        end
        swapAt = GetTime()
        ns.Safe(equip, w.mh, MH)
        if w.oh then ns.Safe(equip, w.oh, OH) end
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
        if event == "PLAYER_LOGIN" then wasPole = nil end
        if slot == MH or event == "PLAYER_LOGIN" then CheckSwapSplash() end
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
