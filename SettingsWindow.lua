-- Rubber Ducky: our own settings window. The same pages as the entry in the
-- game's Settings (AddOns), in a frame of our own, so we can open straight to a
-- page: Forever's Settings window ignores which page an addon asks for.
-- A page lives in one window at a time; opening one closes the other.

local ADDON, ns = ...
local SW = {}
ns.SettingsWindow = SW

local W, H = 909, 600                 -- the window, in UI px at scale 1
local NAV_W = 204
local SCALE = 0.9
local TEXT_SCALE = 1.12 -- the pages and the list, a touch bigger than the game's settings
SW.TEXT_SCALE = TEXT_SCALE

local win, content, navButtons, current = nil, nil, {}, nil

local function Sound(what) ns.UI.Sound(what) end

-- always in the middle of the screen
local function Place()
    win:ClearAllPoints()
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

-- The navy frame, its sign (or a title plaque) standing on the top edge, and
-- the close button: shared by every window of ours.
--   opts: width, height, sign ("settings", "welcome", "challenges") or title,
--         frame (the frame art's scale, smaller for small windows), scale, strata
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
    if opts.sign then
        local S = UI.ART["sign_" .. opts.sign]
        -- narrow enough to stand clear of the corners, so the corner wood shows
        local sw = math.floor(w * 0.74)
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
    win = SW.Chrome("RubberDuckySettings", nil, { sign = "settings" })
    local L, T, R, B = unpack(win.inner)
    local UI = ns.UI

    -- where the pages go
    content = CreateFrame("Frame", nil, win)
    content:SetPoint("TOPLEFT", (L + NAV_W + 16) / TEXT_SCALE, -T / TEXT_SCALE)
    content:SetPoint("BOTTOMRIGHT", -R / TEXT_SCALE, B / TEXT_SCALE)
    content:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
    content:SetScale(TEXT_SCALE) -- the page inherits it; the game's Settings window doesn't

    -- the page list: navy plates, parchment for the page you're on
    for i, item in ipairs(ns.Options.ORDER or {}) do
        local b = CreateFrame("Button", nil, win)
        b:SetScale(TEXT_SCALE)
        b:SetSize(NAV_W / TEXT_SCALE, 30)
        b:SetPoint("TOPLEFT", win, "TOPLEFT", L / TEXT_SCALE, -(T + 4 + (i - 1) * 36) / TEXT_SCALE)
        b:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
        b.art = UI.Stretch(b, "strip_navy", "BACKGROUND")
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 12, -5); hl:SetPoint("BOTTOMRIGHT", -12, 5); hl:SetColorTexture(1, 1, 1, 0.08)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", 20, 0)
        fs:SetPoint("RIGHT", -16, 0); fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
        fs:SetText(item[2])
        b.text, b.key = fs, item[1]
        b:SetScript("OnClick", function() if current ~= item[1] then Sound("page") end; SW:ShowPage(item[1]) end)
        navButtons[#navButtons + 1] = b
    end

    win:SetScript("OnShow", function() Place(); Sound("settingsOpen") end)
    win:SetScript("OnHide", function()
        Sound("settingsClose")
        -- unless the game's Settings window took it back for itself
        local page = current and ns.Options.pages[current]
        if page and not (SettingsPanel and SettingsPanel:IsShown()) then page.frame:Hide() end
    end)

    -- a controller: the D-pad moves through the page, the shoulders turn pages
    SW.pad = ns.Pad.Attach(win, {
        roots = function() local p = current and ns.Options.pages[current]; return { p and p.frame } end,
        pages = function(dir)
            local order = ns.Options.ORDER or {}
            for i, item in ipairs(order) do
                if item[1] == current then
                    Sound("page")
                    SW:ShowPage(order[(i - 1 + dir) % #order + 1][1])
                    return
                end
            end
        end,
    })

    -- the game's Settings window and ours never show the same page at once
    if SettingsPanel and SettingsPanel.HookScript then
        SettingsPanel:HookScript("OnShow", function() if win:IsShown() then win:Hide() end end)
    end
    Place()
end

function SW:ShowPage(key)
    local pages = ns.Options.pages
    local page = pages[key] or pages.overview
    if not page then return end
    key = pages[key] and key or "overview"
    local prev = current and pages[current]
    if prev and current ~= key then prev.frame:Hide() end
    current = key
    page.frame:SetParent(content)
    page.frame:ClearAllPoints()
    page.frame:SetAllPoints(content)
    page.frame:Hide(); page.frame:Show() -- shown fresh, so it refreshes
    for _, b in ipairs(navButtons) do
        local on = b.key == key
        b.art:SetArt(on and "strip_parch" or "strip_navy")
        b.text:SetFontObject(on and ns.UI.FONT.bold or "GameFontHighlight")
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
