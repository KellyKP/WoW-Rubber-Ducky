-- Rubber Ducky: copy and paste settings as readable text.

local _, ns = ...
local Share = {}
ns.Share = Share

-- not shared: developer switches
local SKIP = { debugMode = true, probeEnabled = true, shareDebug = true }
local DEBUG_MARK = "-- debug info (ignored when pasted) --"

local function Version()
    local v = ns.Safe(function() return C_AddOns.GetAddOnMetadata("RubberDucky", "Version") end)
    return v or "?"
end

local function Keys()
    local keys = {}
    for k in pairs(ns.defaults) do
        if not SKIP[k] then keys[#keys + 1] = k end
    end
    table.sort(keys)
    return keys
end

local function DebugLines()
    local out = { DEBUG_MARK }
    ns.Safe(function()
        local version, build, _, interface = GetBuildInfo()
        out[#out + 1] = ("Game: %s (%s), interface %s, %s"):format(tostring(version), tostring(build),
            tostring(interface), tostring(GetLocale()))
    end)
    ns.Safe(function()
        local get = C_CVar and C_CVar.GetCVar or GetCVar
        out[#out + 1] = ("Controller: %s, type %s, cast on key down %s"):format(
            get("GamePadEnable") == "1" and "on" or "off",
            ns.OneKey and ns.OneKey.PadType and ns.OneKey.PadType() or "?",
            tostring(get("ActionButtonUseKeyDown")))
    end)
    ns.Safe(function()
        local names = {}
        for i = 1, C_AddOns.GetNumAddOns() do
            local name = C_AddOns.GetAddOnInfo(i)
            if name and name ~= "RubberDucky" and C_AddOns.IsAddOnLoaded(i) then names[#names + 1] = name end
        end
        table.sort(names)
        out[#out + 1] = "Other addons: " .. (#names > 0 and table.concat(names, ", ") or "none")
    end)
    return out
end

function Share.Export()
    local lines = { "Rubber Ducky " .. Version() .. " settings" }
    local row = {}
    for _, k in ipairs(Keys()) do
        row[#row + 1] = k .. "=" .. tostring(ns.db[k])
        if #row == 5 then lines[#lines + 1] = table.concat(row, " "); row = {} end
    end
    if #row > 0 then lines[#lines + 1] = table.concat(row, " ") end
    if ns.db.shareDebug then
        for _, l in ipairs(DebugLines()) do lines[#lines + 1] = l end
    end
    return table.concat(lines, "\n")
end

-- returns how many settings were applied
function Share.Import(text)
    text = (text or ""):gsub("|", "")
    local cut = text:find(DEBUG_MARK, 1, true)
    if cut then text = text:sub(1, cut - 1) end
    local n = 0
    for k, v in text:gmatch("([%a][%w]*)=(%S+)") do
        local default = ns.defaults[k]
        if default ~= nil and not SKIP[k] then
            local value
            if type(default) == "boolean" then
                if v == "true" then value = true elseif v == "false" then value = false end
            elseif type(default) == "number" then
                value = tonumber(v)
            else
                value = v
            end
            if value ~= nil then ns.db[k] = value; n = n + 1 end
        end
    end
    if n > 0 then Share.AfterImport() end
    return n
end

function Share.AfterImport()
    if ns.sessionActive then
        if ns.Sound then ns.Safe(ns.Sound.Apply, ns.Sound) end
        if ns.Camera and ns.Camera.Reapply then ns.Safe(ns.Camera.Reapply, ns.Camera) end
    end
    if ns.Bobber then
        if ns.Bobber.RefreshMarker then ns.Safe(ns.Bobber.RefreshMarker, ns.Bobber) end
        if ns.Bobber.RefreshSparkle then ns.Safe(ns.Bobber.RefreshSparkle, ns.Bobber) end
    end
    if ns.OneKey then ns.Safe(ns.OneKey.Update, ns.OneKey) end
    if ns.Console then ns.Safe(ns.Console.Apply, ns.Console) end
    if ns.Options and ns.Options.RefreshOverview then ns.Safe(ns.Options.RefreshOverview) end
end

-------------------------------------------------------------------------------
-- Window: one text box, used for both copy and paste
-------------------------------------------------------------------------------
local win

local function Build()
    -- our navy frame; its plaque says whether it's copying or pasting
    win = ns.SettingsWindow.Chrome("RubberDuckyShare", nil, { title = "Copy my settings", frame = 0.55,
        width = 540, height = 370, scale = 1, strata = "DIALOG" })
    local L, T, R, B = unpack(win.inner)
    win.title = win.titleText
    win.note = win:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    win.note:SetPoint("TOP", win, "TOP", 0, -T)

    -- the text sits on a darker well
    local well = win:CreateTexture(nil, "BORDER")
    well:SetColorTexture(0, 0, 0, 0.35)
    well:SetPoint("TOPLEFT", L, -(T + 20)); well:SetPoint("BOTTOMRIGHT", -R, B + 48)
    local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", L + 6, -(T + 26))
    scroll:SetPoint("BOTTOMRIGHT", -(R + 6 + ns.UI.SCROLL_ROOM), B + 54)
    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    -- inside the scrolling box, clear of the scroll bar beside it
    edit:SetWidth(540 - L - R - 12 - ns.UI.SCROLL_ROOM - 8)
    edit:SetScript("OnEscapePressed", function() win:Hide() end)
    scroll:SetScrollChild(edit)
    ns.UI.SlimScrollBar(scroll, win) -- the same rope-and-glass bar as everywhere else
    win.edit = edit

    win.apply = ns.UI.Button(win, "Apply", 140, function() end, { height = 42 })
    win.apply:SetPoint("BOTTOM", 0, B - 4)
    win.apply:SetScript("OnClick", function()
        ns.UI.Sound("button")
        local n = Share.Import(win.edit:GetText())
        if n > 0 then
            win.note:SetText(("|cff80ff80%d settings applied.|r"):format(n))
        else
            win.note:SetText("|cffff8080No Rubber Ducky settings found in that text.|r")
        end
    end)

    -- on a controller: A on Apply, the D-pad scrolls the text, B closes
    if ns.Pad and ns.Pad.Attach then
        Share.pad = ns.Pad.Attach(win, { roots = function() return win.apply:IsShown() and { win.apply } or {} end,
            scroll = function() return scroll end,
            badges = function(nav) if win.close then nav:Badge(win.close, "PAD2", "TOPLEFT", 2, -2, 22) end end })
    end
end

function Share:ShowCopy()
    if not win then Build() end
    ns.SettingsWindow.SetTitle(win, "Copy my settings")
    win.note:SetText(ns.db.shareDebug and "|cffffd100Includes debug info: game details and your list of addons.|r"
        or "Press Ctrl+C to copy.")
    win.apply:Hide()
    win.edit:SetText(Share.Export())
    win:Show()
    win.edit:SetFocus()
    win.edit:HighlightText()
end

function Share:ShowPaste()
    if not win then Build() end
    ns.SettingsWindow.SetTitle(win, "Paste settings")
    win.note:SetText("Paste with Ctrl+V, then press Apply.")
    win.apply:Show()
    win.edit:SetText("")
    win:Show()
    win.edit:SetFocus()
end
