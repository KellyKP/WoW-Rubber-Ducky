-- Rubber Ducky: one-button fishing. With a pole equipped, the chosen button
-- casts, then interacts with the soft-targeted bobber to reel in. In Interact
-- mode it casts only when nothing is soft-targeted. Released when the pole
-- comes off or combat starts.

local _, ns = ...
local OK = {}
ns.OneKey = OK

local owner = CreateFrame("Frame", "RubberDuckyOneKeyOwner", UIParent)

-- Secure "/cast Fishing" button. Must be shown to take binding clicks, so it
-- sits 1x1 off screen. Acts on one key edge only (ActionButtonUseKeyDown).
local castButton = CreateFrame("Button", "RubberDuckyCastButton", UIParent,
    "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
castButton:SetSize(1, 1)
castButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -20, 20)
castButton:SetAttribute("type", "macro")
castButton:RegisterForClicks("AnyDown", "AnyUp")
if SecureHandlerWrapScript then
    SecureHandlerWrapScript(castButton, "OnClick", castButton, [[
        if not down ~= not self:GetAttribute("rd-down") then return false end
    ]])
end
local clicks = 0
castButton:HookScript("OnClick", function(_, _, down)
    if (not down) == (not castButton:GetAttribute("rd-down")) then clicks = clicks + 1 end
end)

local FISHING_SPELL = 7620
local pending = false
local lastSelfChange = 0
local softTarget -- soft-interact GUID, or nil
local active = false
local announced = false

local function FishingName()
    local name = ns.Safe(function()
        return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(FISHING_SPELL) or (GetSpellInfo(FISHING_SPELL))
    end)
    return name
end

-- weapon class 2, subclass 20 = fishing pole
local function PoleEquipped()
    return ns.Safe(function()
        local id = GetInventoryItemID("player", 16)
        if not id then return false end
        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(id)
        return classID == 2 and subclassID == 20
    end) or false
end

-- false while a controller UI window (bags, map...) has gamepad focus
local function InGameFocus()
    local manager = GamepadSharedUtility and GamepadSharedUtility.InputBindingManager
    if not (manager and manager.IsOnlyCoreBindingSetActive) then return true end
    local ok, only = pcall(manager.IsOnlyCoreBindingSetActive, manager)
    return not ok or only and true or false
end

-- The face buttons and D-pad belong to the crossbar; the triggers are usable.
local PAD_KEYS = { [5] = "PADRTRIGGER", [6] = "PADLTRIGGER" }
OK.PAD_KEYS = PAD_KEYS

local function GamepadOn()
    local ok, v = pcall(C_CVar and C_CVar.GetCVar or GetCVar, "GamePadEnable")
    return ok and v == "1"
end

-- Forever's "Enable Gamepad UI" option (the controller layout), not just a
-- controller being allowed. It's a setting in Options rather than a cvar.
local GAMEPAD_UI = "GAMEPAD_INTERFACE_TOGGLE"
local function GamepadUIOn()
    local setting = Settings and Settings.GetSetting and ns.Safe(Settings.GetSetting, GAMEPAD_UI)
    local v
    if setting and setting.GetValue then v = ns.Safe(setting.GetValue, setting)
    else v = ns.Safe(GetCVar, GAMEPAD_UI) end
    return v == true or v == 1 or v == "1"
end
OK.GamepadUIOn = GamepadUIOn

local fallbackNoted = false

local NAMES = {
    xbox        = { left = "Left Trigger", right = "Right Trigger" },
    playstation = { left = "L2", right = "R2" },
    switch      = { left = "ZL", right = "ZR" },
}
local function DetectedPadType()
    local style
    local manager = InputDeviceIconSetManager
    if manager and manager.GetActiveInputDeviceIconSet then
        local ok, s = pcall(manager.GetActiveInputDeviceIconSet, manager)
        if ok then style = s end
    end
    if not style and C_GamePad and C_GamePad.GetDeviceMappedState then
        local ok, state = pcall(C_GamePad.GetDeviceMappedState,
            C_GamePad.GetActiveDeviceID and C_GamePad.GetActiveDeviceID() or nil)
        if ok and type(state) == "table" then style = state.labelStyle end
    end
    if style == "Shapes" then return "playstation" end
    if style == "Reverse" then return "switch" end
    return "xbox"
end
function OK.PadType()
    local t = ns.db and ns.db.padType or "auto"
    if NAMES[t] then return t end
    return DetectedPadType()
end
function OK.TriggerName(side)
    return NAMES[OK.PadType()][side]
end

-- For the settings: what a button choice is bound to, and whether it can work.
local ICON_STYLE = { xbox = "Ltr", playstation = "Shp", switch = "Rev" }
local function TriggerIcon(side, px)
    local style = ICON_STYLE[OK.PadType()]
    local name = side == "left" and "LTrigger" or "RTrigger"
    if C_Texture and C_Texture.GetAtlasInfo then
        for _, size in ipairs({ "_64", "_32", "" }) do
            local atlas = "Gamepad_" .. style .. "_" .. name .. size
            local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
            if ok and info then return ("|A:%s:%d:%d|a"):format(atlas, px or 18, px or 18) end
        end
    end
    return "[" .. OK.TriggerName(side) .. "]"
end
local function KeyText(key)
    local t = GetBindingText and GetBindingText(key) or key
    return "[" .. (t or key):gsub("Mouse Button ", "Mouse ") .. "]"
end
OK.GamepadOn = GamepadOn
OK.TriggerIcon = TriggerIcon

-- a controller button as a picture (the game's own, if it has one) or a short name
local GLYPH = {
    xbox = { PAD1 = "A", PAD2 = "B", PAD3 = "X", PAD4 = "Y", PADLSHOULDER = "LB", PADRSHOULDER = "RB", PADBACK = "View", DPAD = "D-pad", PADRSTICK = "RS" },
    playstation = { PAD1 = "Cross", PAD2 = "Circle", PAD3 = "Square", PAD4 = "Triangle", PADLSHOULDER = "L1",
        PADRSHOULDER = "R1", PADBACK = "Share", DPAD = "D-pad", PADRSTICK = "R3" },
    switch = { PAD1 = "B", PAD2 = "A", PAD3 = "Y", PAD4 = "X", PADLSHOULDER = "L", PADRSHOULDER = "R", PADBACK = "-", DPAD = "D-pad", PADRSTICK = "RS" },
}
local ATLAS_NAME = { PAD1 = { "A", "Cross", "B" }, PAD2 = { "B", "Circle", "A" }, PAD3 = { "X", "Square", "Y" },
    PAD4 = { "Y", "Triangle", "X" }, PADLSHOULDER = { "LShoulder", "LShoulder", "LShoulder" },
    PADRSHOULDER = { "RShoulder", "RShoulder", "RShoulder" }, PADBACK = { "View", "Share", "Minus" }, DPAD = { "DPad", "DPad", "DPad" },
    PADRSTICK = { "RStickIn", "RStickIn", "RStickIn" } }
local ATLAS_ALT = {}
-- The game's own prompt pictures (white letters on a dark button), named like
-- "Gamepad-Xbox1-ButtonA-Normal", "Gamepad-Xbox1-Trigger-LB-Normal" and
-- "Gamepad-Xbox1-View-Normal" (Forever's Xbox set). Found by trying the likely
-- names once, then remembered.
local PROMPT_DEV = { xbox = { "Xbox1", "XboxSeries", "Xbox" }, playstation = { "PS5", "PS4", "PlayStation" },
    switch = { "Switch", "SwitchPro" } }
local PROMPT_BTN = {
    PAD1 = { { "A" }, { "Cross" }, { "B" } }, PAD2 = { { "B" }, { "Circle" }, { "A" } },
    PAD3 = { { "X" }, { "Square" }, { "Y" } }, PAD4 = { { "Y" }, { "Triangle" }, { "X" } },
    PADLSHOULDER = { { "LB" }, { "L1" }, { "L" } }, PADRSHOULDER = { { "RB" }, { "R1" }, { "R" } },
    PADBACK = { { "View", "Back" }, { "Share", "Create" }, { "Minus" } },
    PADRSTICK = { { "RS", "R3" }, { "R3", "RS" }, { "RS", "R3" } },
    DPAD = { { "DPad", "Dpad" }, { "DPad", "Dpad" }, { "DPad", "Dpad" } },
}
local PROMPT_KIND = { "Face", "Button", "Bumper", "Shoulder", "Trigger", "Menu", "System", "Special", "Stick", "Thumbstick", "DPad", "Dpad" }
local promptFound = {}
local function PromptAtlas(button, t)
    local key = button .. ":" .. t
    if promptFound[key] ~= nil then return promptFound[key] or nil end
    promptFound[key] = false
    local names = PROMPT_BTN[button] and PROMPT_BTN[button][t == "xbox" and 1 or t == "playstation" and 2 or 3]
    if not (names and C_Texture and C_Texture.GetAtlasInfo) then return nil end
    local function Has(n) local ok, info = pcall(C_Texture.GetAtlasInfo, n); return ok and info end
    for _, dev in ipairs(PROMPT_DEV[t] or PROMPT_DEV.xbox) do
        for _, nm in ipairs(names) do
            for _, kind in ipairs(PROMPT_KIND) do
                local atlas = "Gamepad-" .. dev .. "-" .. kind .. "-" .. nm .. "-Normal"
                if Has(atlas) then promptFound[key] = atlas; return atlas end
            end
            -- face buttons: "ButtonA"; View on its own: "View"
            for _, atlas in ipairs({ "Gamepad-" .. dev .. "-Button" .. nm .. "-Normal", "Gamepad-" .. dev .. "-" .. nm .. "-Normal" }) do
                if Has(atlas) then promptFound[key] = atlas; return atlas end
            end
        end
    end
    return nil
end
OK.PromptAtlas = PromptAtlas

function OK.Glyph(button, size)
    local t = OK.PadType()
    local prompt = PromptAtlas(button, t)
    if prompt then
        -- keep its shape (the shoulder buttons are wider than tall)
        local ok, info = pcall(C_Texture.GetAtlasInfo, prompt)
        -- these have a little room round the button, so they're drawn a size up
        local h = math.floor((size or 16) * 1.4 + 0.5)
        local w = (ok and info and info.width and info.height and info.height > 0) and math.floor(h * info.width / info.height + 0.5) or h
        return ("|A:%s:%d:%d|a"):format(prompt, h, w)
    end
    local style = ICON_STYLE[t]
    local n = ATLAS_NAME[button] and ATLAS_NAME[button][t == "xbox" and 1 or t == "playstation" and 2 or 3]
    if n and C_Texture and C_Texture.GetAtlasInfo then
        -- the pad's own picture, or the game's generic one (the sticks only have those)
        for _, nm in ipairs({ n, ATLAS_ALT[button] }) do
            for _, st in ipairs({ style, "Gen" }) do
                for _, sfx in ipairs({ "_64", "_32", "" }) do
                    local atlas = "Gamepad_" .. st .. "_" .. nm .. sfx
                    local ok, info = pcall(C_Texture.GetAtlasInfo, atlas)
                    if ok and info then return ("|A:%s:%d:%d|a"):format(atlas, size or 16, size or 16) end
                end
            end
        end
    end
    return "[" .. ((GLYPH[t] or GLYPH.xbox)[button] or button) .. "]"
end

function OK.Binding(mode)
    if mode == 4 then
        local a, b = GetBindingKey("INTERACTTARGET")
        local parts = {}
        if a and a ~= "" then parts[#parts + 1] = KeyText(a) end
        if b and b ~= "" and b ~= a then parts[#parts + 1] = KeyText(b) end
        if #parts > 0 then return table.concat(parts, " "), true end
        if GamepadOn() then return "uses " .. TriggerIcon("right"), true end
        return "[Not Bound]", false
    end
    local side = mode == 6 and "left" or "right"
    if GamepadOn() then return TriggerIcon(side), true end
    return "[No controller]", false
end

-- returns the keys, and whether they're interact keys (cast only when idle)
local function Keys()
    local mode = ns.db.oneKeyButton or 4
    local keys, seen = {}, {}
    local function add(k) if k and k ~= "" and not seen[k] then seen[k] = true; keys[#keys + 1] = k end end
    if mode == 4 then
        -- read after our overrides are cleared, so these are your own bindings
        local a, b = GetBindingKey("INTERACTTARGET")
        add(a); add(b)
        if #keys > 0 then return keys, true end
        -- controller UI has no Interact binding: use R2
        if GamepadOn() then
            if not fallbackNoted then
                fallbackNoted = true
                ns.Print("one-button: the controller UI has no Interact key binding, using %s instead.", OK.TriggerName("right"))
            end
            add("PADRTRIGGER")
            return keys, false
        end
        return keys, true
    end
    if PAD_KEYS[mode] then add(PAD_KEYS[mode]) end
    return keys, false
end

function OK:Update()
    if InCombatLockdown() then pending = true return end
    pending = false
    lastSelfChange = GetTime()
    ClearOverrideBindings(owner)
    active = false
    local db = ns.db
    if not db or not db.oneKeyEnabled or not PoleEquipped() or not InGameFocus() then return end

    local spell = FishingName()
    if not spell then return end
    local onDown = (C_CVar and C_CVar.GetCVar or GetCVar)("ActionButtonUseKeyDown") ~= "0"
    castButton:SetAttribute("rd-down", onDown)
    castButton:SetAttribute("useOnKeyDown", onDown)
    castButton:SetAttribute("macrotext", "/cast " .. spell)

    local keys, interactMode = Keys()
    if interactMode and #keys == 0 then
        if not announced then
            announced = true
            ns.Print("one-button: no key is bound to Interact (Options > Keybindings), or pick a trigger in Rubber Ducky's settings.")
        end
        return
    end
    for _, key in ipairs(keys) do
        if interactMode then
            if not ns.fishing and not softTarget then
                SetOverrideBindingClick(owner, true, key, "RubberDuckyCastButton", "LeftButton")
            end
        elseif ns.fishing then
            SetOverrideBinding(owner, true, key, "INTERACTTARGET")
        else
            SetOverrideBindingClick(owner, true, key, "RubberDuckyCastButton", "LeftButton")
        end
    end
    active = #keys > 0
    if active and not announced then
        announced = true
        ns.Print("one-button: %s casts and reels in while your pole is equipped.", table.concat(keys, " / "))
    end
end

-- Interact mode: switch between interact and cast as soft targets change
function OK:OnSoftInteract(newGUID)
    local had = softTarget ~= nil
    softTarget = (newGUID and not ns.IsSecret(newGUID)) and newGUID or nil
    if (softTarget ~= nil) ~= had and (ns.db.oneKeyButton or 4) == 4 and ns.db.oneKeyEnabled then
        self:Update()
    end
end

function OK:IsActive() return active end

-- /ducky button
function OK:Status(again)
    local db = ns.db
    if not again then
        -- the chat box holds focus while typing: check again after
        C_Timer.After(2, function() OK:Update(); OK:Status(true) end)
    end
    local P = function(...) ns.Print("   " .. string.format(...)) end
    ns.Print(again and "one-button fishing status (2 s later, chat closed):" or "one-button fishing status:")
    P("enabled: %s   button setting: %s", tostring(db.oneKeyEnabled),
        ({ [4] = "Interact", [5] = OK.TriggerName("right"), [6] = OK.TriggerName("left") })[db.oneKeyButton or 4] or "?")
    P("controller type: %s%s", OK.PadType(), (db.padType or "auto") == "auto" and " (automatic)" or "")
    P("controller on: %s", tostring(GamepadOn()))
    local id = GetInventoryItemID("player", 16)
    local pole = PoleEquipped()
    P("main hand item: %s   fishing pole: %s", tostring(id), tostring(pole))
    P("fishing spell: %s   cast on key down: %s", tostring(FishingName()),
        tostring((C_CVar and C_CVar.GetCVar or GetCVar)("ActionButtonUseKeyDown")))
    P("in combat: %s   controller UI window has focus: %s", tostring(InCombatLockdown()), tostring(not InGameFocus()))
    P("fishing now: %s   soft target: %s", tostring(ns.fishing), tostring(softTarget))
    local a, b = GetBindingKey("INTERACTTARGET")
    P("keys bound to Interact: %s %s", tostring(a), tostring(b or ""))
    for _, key in ipairs(Keys()) do
        local normal = GetBindingAction(key) or ""
        local now = GetBindingAction(key, true) or ""
        local crossbar = normal:match("^GAMEPADACTIONBUTTON") and "  (crossbar slot: the controller UI may handle this button itself)" or ""
        P("%s: normally %s, right now %s%s", key, normal ~= "" and normal or "nothing", now ~= "" and now or "nothing", crossbar)
    end
    P("cast button clicks this session: %d", clicks)
    if not active then P("|cffff8040not active|r: needs enabled, a pole equipped, out of combat, no controller window open, and a key found") end
    if again then P("active: %s", tostring(active)) end
end

-- PLAYER_REGEN_DISABLED is the last moment before lockdown to clear bindings.
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
events:SetScript("OnEvent", function(_, event, slot, ...)
    if not ns.db then return end
    if event == "PLAYER_SOFT_INTERACT_CHANGED" then
        local newGUID = ...
        OK:OnSoftInteract(newGUID)
    elseif event == "PLAYER_REGEN_DISABLED" then
        ClearOverrideBindings(owner)
        active = false
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if slot == 16 then OK:Update() end
    elseif event == "UPDATE_BINDINGS" then
        -- our own overrides fire this too: ignore those
        if GetTime() - lastSelfChange > 1 and not InCombatLockdown() and not ns.fishing then OK:Update() end
    else
        OK:Update()
    end
end)

-- No event for controller UI focus changes: poll 5x a second.
local lastFocus, wait = nil, 0
events:SetScript("OnUpdate", function(_, elapsed)
    wait = wait - elapsed
    if wait > 0 or not ns.db or not ns.db.oneKeyEnabled then return end
    wait = 0.2
    local now = InGameFocus()
    if now ~= lastFocus then
        lastFocus = now
        if not InCombatLockdown() then OK:Update() end
    end
end)
