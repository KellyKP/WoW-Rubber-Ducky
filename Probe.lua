-- Rubber Ducky: event recorder (developer). Logs every event during a cast.

local _, ns = ...
local Probe = {}
ns.Probe = Probe

local MAX_LINES = 500
local MAX_CASTS = 6

-- Fire constantly and never relate to the bobber.
local NOISY = {
    COMBAT_LOG_EVENT_UNFILTERED = true, UNIT_AURA = true, UNIT_POWER_UPDATE = true,
    UNIT_POWER_FREQUENT = true, UPDATE_MOUSEOVER_UNIT = true, CURSOR_CHANGED = true,
    WORLD_CURSOR_TOOLTIP_UPDATE = true, MODIFIER_STATE_CHANGED = true, UPDATE_UI_WIDGET = true,
    ACTIONBAR_UPDATE_COOLDOWN = true, SPELL_UPDATE_COOLDOWN = true, SPELL_UPDATE_USABLE = true,
    BAG_UPDATE_COOLDOWN = true, UNIT_HEALTH = true, CHAT_MSG_CHANNEL = true,
    CHAT_MSG_ADDON = true, CHAT_MSG_ADDON_LOGGED = true, UNIT_MODEL_CHANGED = true,
    NAME_PLATE_UNIT_ADDED = false, NAME_PLATE_UNIT_REMOVED = false, -- keep these
    CHAT_MSG_TRADESKILLS = true, SPELL_ACTIVATION_OVERLAY_HIDE = true,
    UNIT_DIED = true, CHAT_MSG_SKILL = true, CONSOLE_MESSAGE = true,
}

local rec = CreateFrame("Frame")
local current -- lines for the cast in progress
local t0 = 0
local lastY, lastSample = nil, {}

local function Fmt(v)
    if ns.IsSecret(v) then return "<secret>" end
    local s = ns.Safe(tostring, v) or "?"
    if #s > 40 then s = s:sub(1, 40) .. "…" end
    return s
end

local function Add(line)
    if not current or #current >= MAX_LINES then return end
    current[#current + 1] = string.format("%6.2f  %s", GetTime() - t0, line)
end

rec:SetScript("OnEvent", function(_, event, ...)
    if NOISY[event] then return end
    -- soft-target cvars are re-announced on every target change
    if event == "CVAR_UPDATE" then
        local name = ...
        if type(name) == "string" and name:find("^SoftTarget") then return end
    end
    local n = select("#", ...)
    local parts = {}
    for i = 1, math.min(n, 5) do parts[i] = Fmt((select(i, ...))) end
    Add(event .. (n > 0 and ("  " .. table.concat(parts, ", ")) or ""))
end)

function Probe:OnCastStart()
    if not (ns.db.probeEnabled and ns.db.debugMode) then return end
    current = {}
    t0 = GetTime()
    lastY = nil
    wipe(lastSample)
    Add("---- cast start ----")
    ns.Safe(rec.RegisterAllEvents, rec)
end

function Probe:OnCastStop(reason)
    if not current then return end
    Add("---- cast end (" .. tostring(reason) .. ") ----")
    -- keep recording briefly for loot events
    local lines = current
    C_Timer.After(1.5, function()
        if current == lines then
            current = nil
            ns.Safe(rec.UnregisterAllEvents, rec)
        end
        ns.db.probeLogs = ns.db.probeLogs or {}
        table.insert(ns.db.probeLogs, 1, lines)
        while #ns.db.probeLogs > MAX_CASTS do table.remove(ns.db.probeLogs) end
        ns.Print("recorded cast (%d lines). /ducky log to view.", #lines)
    end)
end

function Probe:Mark(what)
    Add(">>> " .. what)
end

function Probe:Sample(kind, msg)
    if not current or lastSample[kind] == msg then return end
    lastSample[kind] = msg
    Add(kind .. ": " .. msg)
end

function Probe:SampleY(now, x, y)
    if not current then return end
    if not lastY or math.abs(y - lastY) >= 0.5 then
        Add(string.format("bobber y=%.1f (x=%.1f)%s", y, x,
            lastY and string.format("  Δ%.1f", y - lastY) or ""))
        lastY = y
    end
end

-------------------------------------------------------------------------------
-- Copyable log window
-------------------------------------------------------------------------------

local win
local function BuildWindow()
    win = CreateFrame("Frame", "RubberDuckyLogWindow", UIParent, "BackdropTemplate")
    win:SetSize(620, 440)
    win:SetPoint("CENTER")
    win:SetFrameStrata("DIALOG")
    win:SetMovable(true); win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", win.StopMovingOrSizing)
    win:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    tinsert(UISpecialFrames, "RubberDuckyLogWindow")

    local title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -14)
    title:SetText("Rubber Ducky recorder log (Ctrl+A, Ctrl+C to copy)")

    local close = CreateFrame("Button", nil, win, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local clear = CreateFrame("Button", nil, win, "UIPanelButtonTemplate")
    clear:SetSize(90, 22)
    clear:SetPoint("BOTTOMRIGHT", -16, 12)
    clear:SetText("Clear log")
    clear:SetScript("OnClick", function()
        ns.db.probeLogs = {}
        win.edit:SetText("")
    end)

    local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -40)
    scroll:SetPoint("BOTTOMRIGHT", -34, 42)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(560)
    edit:SetScript("OnEscapePressed", function() win:Hide() end)
    scroll:SetScrollChild(edit)
    win.edit = edit
end

function Probe:ShowLog()
    if not win then BuildWindow() end
    local logs = ns.db.probeLogs or {}
    local out = {}
    if #logs == 0 then
        out[1] = "No casts recorded yet. Turn the recorder on with /ducky probe, then fish."
    end
    for i = #logs, 1, -1 do
        out[#out + 1] = string.format("===== cast %d =====", #logs - i + 1)
        for _, line in ipairs(logs[i]) do out[#out + 1] = line end
        out[#out + 1] = ""
    end
    win.edit:SetText(table.concat(out, "\n"))
    win:Show()
    win.edit:SetFocus()
    win.edit:HighlightText()
end
