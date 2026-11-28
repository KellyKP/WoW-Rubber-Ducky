-- Rubber Ducky: our own settings window. The same pages as the entry in the
-- game's Settings (AddOns), in a frame of our own, so we can open straight to a
-- page: Forever's Settings window ignores which page an addon asks for.
-- Ours puts them under six tabs along the top; a tab with more than one page
-- shows them one under another. A page lives in one window at a time; opening
-- one closes the other.

local ADDON, ns = ...
local SW = {}
ns.SettingsWindow = SW

local W, H = 909, 640                 -- the window, in UI px at scale 1
local SCALE = 0.9
local TEXT_SCALE = 1.12 -- the pages and the list, a touch bigger than the game's settings
SW.TEXT_SCALE = TEXT_SCALE

local win, content, tabRow, current, currentTab = nil, nil, nil, nil, nil
local stack, stackScroll -- a tab with more than one page: the pages one under another, scrolling together

-- the tabs along the top, and the pages each one holds. Developer isn't a tab:
-- it opens from a link at the bottom of Overview.
local TABS = {
    { "overview", "Overview", { "overview" } },
    { "casting", "Casting", { "poleswap", "onebutton", "bobber", "tackle" } },
    { "soundcam", "Sound & Camera", { "sound", "camera" } },
    { "catch", "Your Catch", { "catch" } },
    { "records", "Journal & Log", { "journal", "log" } },
    { "social", "Social", { "flair" } },
}
SW.TABS = TABS
local function TabOf(key)
    for _, t in ipairs(TABS) do
        for _, k in ipairs(t[3]) do if k == key then return t end end
    end
    return TABS[1] -- developer: Overview's tab stays lit
end
local function TabByKey(key) for _, t in ipairs(TABS) do if t[1] == key then return t end end end

local function Sound(what) ns.UI.Sound(what) end

-- always in the middle of the screen
local function Place()
    win:ClearAllPoints()
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

-- The navy frame, its sign (or a title plaque) standing on the top edge, and
-- the close button: shared by every window of ours.
--   opts: width, height, sign ("settings", "welcome", "challenges") or title,
--         frame (the frame art's scale, smaller for small windows), scale, strata,
--         signWidth (to keep the sign its usual size on a wider window)
-- Returns the window and the layer above its page. win.inner is the opening:
-- { left, top, right, bottom } in from the window's edges.
function SW.Chrome(name, _, opts)
    opts = opts or {}
    local UI = ns.UI
    local w, h = opts.width or W, opts.height or H
    local fs = opts.frame or 0.8
    local A = UI.ART.frame
    local win = CreateFrame("Frame", name, UIParent)
    win:SetSize(w, h)
    win:SetPoint("CENTER")
    win:SetScale(opts.scale or SCALE)
    win:SetFrameStrata(opts.strata or "HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:EnableMouse(true) -- it stays where it opens, in the middle of the screen
    win:Hide()
    tinsert(UISpecialFrames, name)
    win.art = UI.Stretch(win, "frame", "BACKGROUND", fs)
    local border = 44 * fs -- the top wood, down to its gold line

    -- above the page: the sign or plaque, and the close button
    local top = CreateFrame("Frame", nil, win)
    top:SetAllPoints()
    top:SetFrameLevel((win:GetFrameLevel() or 1) + 20)
    win.decor = UI.Stretch(top, "frame_top", "BACKGROUND", fs) -- the frame's trim, in front of the page
    if opts.sign then
        local S = UI.ART["sign_" .. opts.sign]
        -- narrow enough to stand clear of the corners, so the corner wood shows
        local sw = opts.signWidth or math.floor(w * 0.74)
        local sh = sw * S.ah / S.aw
        local sign = top:CreateTexture(nil, "ARTWORK")
        sign:SetTexture(ns.MEDIA .. "UI\\sign_" .. opts.sign)
        sign:SetTexCoord(0, S.aw / S.w, 0, S.ah / S.h)
        sign:SetSize(sw, sh)
        -- standing on the top edge: its plaque just covers the border
        sign:SetPoint("BOTTOM", win, "TOP", 0, -(border + 6))
        win.sign = sign
    elseif opts.title then
        local plaque = CreateFrame("Frame", nil, top)
        plaque:SetHeight(50)
        plaque:SetPoint("CENTER", win, "TOP", 0, -border / 2 + 2)
        UI.Stretch(plaque, "button", "BACKGROUND")
        local t = plaque:CreateFontString(nil, "OVERLAY", UI.FONT.large)
        t:SetPoint("CENTER", 4, 1)
        t:SetText(opts.title)
        plaque:SetWidth((t:GetStringWidth() or 160) + 90)
        win.plaque, win.titleText = plaque, t
    end
    local C = A.close
    local close = CreateFrame("Button", nil, top)
    close:SetSize(C[3] * 2 * fs, C[3] * 2 * fs)
    close:SetPoint("CENTER", win, "TOPRIGHT", -(A.aw - C[1]) * fs, -C[2] * fs)
    close:SetScript("OnClick", function() win:Hide() end) -- the close sound comes from OnHide
    close:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText("Close"); GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function() GameTooltip:Hide() end)
    win.close = close
    -- the opening, clear of the wood and the sign
    local side = 46 * fs + 10
    win.inner = { side, border + (opts.sign and 16 or 22), side, 46 * fs + 12 }
    return win, top
end
SW.SIZE = { W, H }

-- a window's plaque says something else
function SW.SetTitle(w, text)
    if not (w and w.titleText) then return end
    w.titleText:SetText(text)
    w.plaque:SetWidth((w.titleText:GetStringWidth() or 160) + 90)
end

local function Build()
    win = SW.Chrome("RubberDuckySettings", nil, { sign = "settings", height = H })
    local L, T, R, B = unpack(win.inner)
    local UI = ns.UI
    local k = TEXT_SCALE

    -- the tabs along the top; LB and RB badges sit at either end
    local items = {}
    for i, t in ipairs(TABS) do items[i] = { t[1], t[2] } end
    tabRow = UI.TabRow(win, items, function(key)
        if key ~= currentTab or current == "developer" then Sound("page") end
        SW:ShowTab(key)
    end, { inset = 30 })
    tabRow:Place(L, T + 2, (win:GetWidth() or W) - L - R)
    local top = T + 2 + UI.TAB_ROW_H + 8

    -- where the pages go
    content = CreateFrame("Frame", nil, win)
    content:SetPoint("TOPLEFT", L / k, -top / k)
    content:SetPoint("BOTTOMRIGHT", -R / k, B / k)
    content:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
    content:SetScale(k) -- the page inherits it; the game's Settings window doesn't

    -- more than one page on a tab: they stack, and scroll as one
    stackScroll = CreateFrame("ScrollFrame", "RubberDuckySettingsStack", content, "UIPanelScrollFrameTemplate")
    stackScroll:SetPoint("TOPLEFT", 0, 0)
    stackScroll:SetPoint("BOTTOMRIGHT", -UI.SCROLL_ROOM, 0)
    stack = CreateFrame("Frame", nil, stackScroll)
    stack:SetSize(600, 10)
    stackScroll:SetScrollChild(stack)
    stackScroll:SetScript("OnSizeChanged", function(_, w) if w and w > 0 then stack:SetWidth(w); SW:Restack() end end)
    stackScroll:EnableMouseWheel(true)
    function SW.Wheel(delta)
        local v = (stackScroll:GetVerticalScroll() or 0) - delta * 60
        stackScroll:SetVerticalScroll(math.max(0, math.min(v, stackScroll:GetVerticalScrollRange() or 0)))
    end
    stackScroll:SetScript("OnMouseWheel", function(_, d) SW.Wheel(d) end)
    UI.SlimScrollBar(stackScroll, content)
    stackScroll:Hide()

    win:SetScript("OnShow", function() Place(); Sound("settingsOpen") end)
    win:SetScript("OnHide", function()
        Sound("settingsClose")
        -- unless the game's Settings window took them back for itself
        if not (SettingsPanel and SettingsPanel:IsShown()) then
            for _, key in ipairs(SW.Shown()) do
                local page = ns.Options.pages[key]
                if page then page.frame:Hide() end
            end
        end
    end)

    -- a controller: the D-pad moves through the page, the shoulders change tab,
    -- B closes (or, on the developer page, goes back to Overview)
    SW.pad = ns.Pad.Attach(win, {
        roots = function()
            local list = {}
            for _, key in ipairs(SW.Shown()) do
                local p = ns.Options.pages[key]
                if p then list[#list + 1] = p.frame end
            end
            return list
        end,
        pages = function(dir)
            local at = 1
            for i, t in ipairs(TABS) do if t[1] == currentTab then at = i end end
            Sound("page")
            SW:ShowTab(TABS[(at - 1 + dir) % #TABS + 1][1])
        end,
        close = function()
            if current == "developer" then Sound("page"); SW:ShowTab("overview") else win:Hide() end
        end,
        badges = function(nav)
            local b = tabRow.buttons
            nav:Badge(b[1], "PADLSHOULDER", "LEFT", -18, -4, 28)
            nav:Badge(b[#b], "PADRSHOULDER", "RIGHT", 18, -4, 28)
            nav:Badge(win.close, "PAD2", "TOPLEFT", 2, -2, 22)
        end,
    })

    -- the game's Settings window and ours never show the same page at once
    if SettingsPanel and SettingsPanel.HookScript then
        SettingsPanel:HookScript("OnShow", function() if win:IsShown() then win:Hide() end end)
    end
    Place()
end

-- the pages showing now: the tab's, or the developer page on its own
local shown = {}
function SW.Shown() return shown end

-- stacked pages: each as tall as its heading and its cards, so only the stack scrolls
local HEAD = 72 + 8 + 6 + 4
function SW:Restack()
    if not (stack and #shown > 1) then return end
    local y = 0
    for _, key in ipairs(shown) do
        local p = ns.Options.pages[key]
        if p then
            local h = HEAD + (p.content:GetHeight() or 200)
            p.frame:ClearAllPoints()
            p.frame:SetPoint("TOPLEFT", stack, "TOPLEFT", 0, -y)
            p.frame:SetPoint("TOPRIGHT", stack, "TOPRIGHT", 0, -y)
            p.frame:SetHeight(h)
            y = y + h + 14
        end
    end
    stack:SetHeight(math.max(1, y))
end

-- a stacked page's own scroll hands the mouse wheel to the stack
local wheeled = {}
local function Stackable(p)
    if wheeled[p] then return end
    wheeled[p] = true
    local own = p.scroll:GetScript("OnMouseWheel")
    p.scroll:SetScript("OnMouseWheel", function(self, d)
        if p.frame:GetParent() == stack and SW.Wheel then SW.Wheel(d) elseif own then own(self, d) end
    end)
    p.content:HookScript("OnSizeChanged", function() if p.frame:GetParent() == stack then SW:Restack() end end)
    -- stacked, a page's own scroll bar never shows, so its cards can run the full width
    local function Room()
        local stacked = p.frame:GetParent() == stack
        p.scroll:SetPoint("BOTTOMRIGHT", stacked and -4 or -ns.UI.SCROLL_ROOM, 6)
    end
    p.frame:HookScript("OnShow", Room)
    Room()
end

local function Show(keys, tab)
    local pages = ns.Options.pages
    for _, key in ipairs(shown) do
        local p = pages[key]
        if p then p.frame:Hide() end
    end
    shown = {}
    for _, key in ipairs(keys) do if pages[key] then shown[#shown + 1] = key end end
    currentTab = tab
    tabRow:Select(tab)
    if #shown > 1 then
        stackScroll:Show()
        stackScroll:SetVerticalScroll(0)
        for _, key in ipairs(shown) do
            local p = pages[key]
            Stackable(p)
            p.frame:SetParent(stack)
            p.frame:Hide(); p.frame:Show() -- shown fresh, so it refreshes
        end
        SW:Restack()
    else
        stackScroll:Hide()
        local p = pages[shown[1]]
        p.frame:SetParent(content)
        p.frame:ClearAllPoints()
        p.frame:SetAllPoints(content)
        p.frame:Hide(); p.frame:Show()
    end
    if SW.pad then SW.pad:Clear(); SW.pad:Paint() end
end

function SW:ShowTab(key)
    local t = TabByKey(key) or TABS[1]
    current = t[3][1]
    Show(t[3], t[1])
end

-- a page: its tab, scrolled to it
function SW:ShowPage(key)
    local pages = ns.Options.pages
    if not pages[key] then key = "overview" end
    if key == "developer" then
        current = key
        Show({ key }, "overview")
        return
    end
    local t = TabOf(key)
    current = key
    Show(t[3], t[1])
    if #shown > 1 then
        local p = pages[key]
        local _, _, _, _, y = p.frame:GetPoint(1)
        if y then stackScroll:SetVerticalScroll(math.max(0, math.min(-y, stackScroll:GetVerticalScrollRange() or 0))) end
    end
end

-- open (to a page, or the last one); returns true when it opened
function SW:Show(key)
    if not (ns.Options and ns.Options.pages and ns.Options.pages.overview) then return false end
    if not win then Build() end
    if SettingsPanel and SettingsPanel:IsShown() and not InCombatLockdown() then pcall(HideUIPanel, SettingsPanel) end
    win:Show()
    self:ShowPage(key or current or "overview")
    return true
end

function SW:Toggle(key)
    if win and win:IsShown() and (not key or key == current) then win:Hide() return end
    self:Show(key)
end

function SW:IsShown() return win ~= nil and win:IsShown() end
function SW:Hide() if win then win:Hide() end end
function SW:Current() return current end
function SW:CurrentTab() return currentTab end

