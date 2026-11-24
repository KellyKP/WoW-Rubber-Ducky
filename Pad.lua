-- Rubber Ducky: controller support for our windows (settings, Welcome, Ducky's
-- Challenges), and the controls bar they share with the journal.
--
-- Nothing has to sign up for it: the D-pad moves between whatever on the page
-- can be clicked, by where it sits on screen, so a new toggle or button just
-- works. A presses it, left and right nudge a slider, the shoulders turn pages
-- where a window has them, and B closes.

local ADDON, ns = ...
local Pad = {}
ns.Pad = Pad

-------------------------------------------------------------------------------
-- The controls bar: the game's controller hints, in tooltip style, under a window.
-- items: { { "PAD1", "Select" }, { "PADLSHOULDER", "PADRSHOULDER", "Pages" }, ... }
-------------------------------------------------------------------------------

function Pad.NewBar(strata)
    local bar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    bar:SetFrameStrata(strata or "HIGH")
    bar:SetHeight(40)
    bar:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    pcall(bar.SetBackdropColor, bar, 0.06, 0.05, 0.04, 0.92)
    pcall(bar.SetBackdropBorderColor, bar, 0.75, 0.6, 0.35, 1)
    bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bar.text:SetPoint("CENTER", 0, 0)
    local function Glyph(btn)
        local g = ns.OneKey.Glyph(btn, 24)
        if g:sub(1, 1) == "[" then g = "|cffffffff" .. g:sub(2, -2) .. "|r" end -- no picture: just the name
        return g
    end
    function bar:SetItems(items)
        local list = {}
        for _, it in ipairs(items) do
            local s = Glyph(it[1])
            if #it == 3 then s = s .. Glyph(it[2]) .. " " .. it[3] else s = s .. " " .. it[2] end
            list[#list + 1] = s
        end
        self.items = items
        self.text:SetText(table.concat(list, "      "))
        self:SetWidth((self.text:GetStringWidth() or 600) + 36)
    end
    bar:Hide()
    return bar
end

-------------------------------------------------------------------------------
-- Finding what can be pressed, and moving between it
-------------------------------------------------------------------------------

local function Pressable(f)
    local t = f:GetObjectType()
    if t == "Slider" then return f.padAdjust and true or false end
    if t ~= "Button" and t ~= "CheckButton" then return false end
    if f.IsEnabled and not f:IsEnabled() then return false end
    return f:GetScript("OnClick") ~= nil
end

-- everything pressable that's showing under these frames (scroll bars aside)
function Pad.Collect(roots)
    local out = {}
    local function Walk(frame)
        for _, c in ipairs({ frame:GetChildren() }) do
            if c:IsVisible() and not c.padSkip then
                if Pressable(c) then out[#out + 1] = c end
                if c:GetObjectType() ~= "Slider" then Walk(c) end
            end
        end
    end
    for _, r in ipairs(roots) do if r and r:IsVisible() then Walk(r) end end
    return out
end

-- a frame's middle and size, in screen pixels
local function Where(f)
    local l, b, w, h = f:GetRect()
    if not l then return nil end
    local s = f:GetEffectiveScale() or 1
    return (l + w / 2) * s, (b + h / 2) * s, w * s, h * s
end

local function Nearest(items, cur, dir)
    local cx, cy, cw, ch = Where(cur)
    if not cx then return nil end
    local best, bestScore
    for _, c in ipairs(items) do
        if c ~= cur then
            local x, y, w, h = Where(c)
            if x then
                local dx, dy = x - cx, y - cy
                local score
                if dir == "up" and dy > 4 then score = dy + math.abs(dx) * 0.4
                elseif dir == "down" and dy < -4 then score = -dy + math.abs(dx) * 0.4
                elseif dir == "left" and dx < -4 and math.abs(dy) < (ch + h) / 2 then score = -dx + math.abs(dy) * 2
                elseif dir == "right" and dx > 4 and math.abs(dy) < (ch + h) / 2 then score = dx + math.abs(dy) * 2 end
                if score and (not bestScore or score < bestScore) then best, bestScore = c, score end
            end
        end
    end
    return best
end

local function First(items)
    local best, bx, by
    for _, c in ipairs(items) do
        local x, y = Where(c)
        if x and (not best or y > by + 4 or (math.abs(y - by) <= 4 and x < bx)) then best, bx, by = c, x, y end
    end
    return best or items[1]
end

local function ScrollParent(f)
    local p = f:GetParent()
    while p do
        if p:GetObjectType() == "ScrollFrame" then return p end
        p = p:GetParent()
    end
end

-- scroll a frame's list so it's in view
local function IntoView(f)
    local scroll = ScrollParent(f)
    if not scroll then return end
    local top, bottom = scroll:GetTop(), scroll:GetBottom()
    local ft, fb = f:GetTop(), f:GetBottom()
    if not (top and bottom and ft and fb) then return end
    local ss, fs = scroll:GetEffectiveScale() or 1, f:GetEffectiveScale() or 1
    ft, fb = ft * fs / ss, fb * fs / ss
    local v, range = scroll:GetVerticalScroll() or 0, scroll:GetVerticalScrollRange() or 0
    local m = 8
    if ft > top - m then v = v - (ft - top + m)
    elseif fb < bottom + m then v = v + (bottom + m - fb) end
    v = math.max(0, math.min(range, v))
    local bar = rawget(scroll, "ScrollBar")
    if type(bar) == "table" and bar.SetValue then bar:SetValue(v) else scroll:SetVerticalScroll(v) end
end
Pad.IntoView = IntoView

-- the gold box around whatever the controller's on
local glow
local function Glow()
    if glow then return glow end
    glow = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    glow:SetFrameStrata("TOOLTIP")
    glow:SetFrameLevel(100)
    glow:EnableMouse(false)
    glow:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    pcall(glow.SetBackdropColor, glow, 1, 0.82, 0, 0.08)
    pcall(glow.SetBackdropBorderColor, glow, 1, 0.82, 0, 0.95)
    glow:Hide()
    return glow
end

-------------------------------------------------------------------------------
-- Attach(win, o): controller support for one window.
--   o.roots()         frames whose buttons the D-pad moves between
--   o.pages(dir)      the shoulders: turn a page (optional)
--   o.pagesLabel      what the shoulders are called on the bar
--   o.scroll()        with nothing to press, up and down scroll this instead
--   o.close()         B (defaults to hiding the window)
--   o.strata          the bar's strata
-------------------------------------------------------------------------------

function Pad.Attach(win, o)
    o = o or {}
    local nav = { win = win }
    local bar = Pad.NewBar(o.strata or win:GetFrameStrata())
    bar:SetPoint("TOP", win, "BOTTOM", 0, 14)
    nav.bar = bar

    local function Popup() return RubberDuckyPopup and RubberDuckyPopup:IsShown() and RubberDuckyPopup end
    local function Items()
        local pop = Popup()
        if pop then return Pad.Collect({ pop }) end
        return Pad.Collect(o.roots and o.roots() or { win })
    end
    local function Tip(f, on)
        local s = f and f:GetScript(on and "OnEnter" or "OnLeave")
        if s then pcall(s, f) end
    end

    function nav:Paint()
        if not bar:IsShown() then return end
        local list = {}
        local items = Items()
        if #items > 0 then list[#list + 1] = { "DPAD", "Move" }
        elseif o.scroll then list[#list + 1] = { "DPAD", "Scroll" } end
        if o.pages then list[#list + 1] = { "PADLSHOULDER", "PADRSHOULDER", o.pagesLabel or "Pages" } end
        local cur = nav.cur
        if cur and cur:IsVisible() then
            if cur:GetObjectType() == "Slider" then list[#list + 1] = { "PADDLEFT", "PADDRIGHT", "Adjust" }
            else list[#list + 1] = { "PAD1", cur:GetObjectType() == "CheckButton" and "Toggle" or "Select" } end
        end
        list[#list + 1] = { "PAD2", Popup() and "Back" or "Close" }
        bar:SetItems(list)
    end

    function nav:Focus(f)
        if nav.cur and nav.cur ~= f then Tip(nav.cur, false) end
        nav.cur = f
        local g = Glow()
        if not f then g:Hide(); nav:Paint(); return end
        IntoView(f)
        g:ClearAllPoints()
        g:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
        g:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
        g:Show()
        Tip(f, true)
        nav:Paint()
    end
    function nav:Clear()
        if nav.cur then Tip(nav.cur, false) end
        nav.cur = nil
        if glow then glow:Hide() end
    end

    function nav:Move(dir)
        local items = Items()
        if #items == 0 then
            local scroll = o.scroll and o.scroll()
            if scroll and (dir == "up" or dir == "down") then
                local v = (scroll:GetVerticalScroll() or 0) + (dir == "down" and 80 or -80)
                v = math.max(0, math.min(scroll:GetVerticalScrollRange() or 0, v))
                local sb = rawget(scroll, "ScrollBar")
                if type(sb) == "table" and sb.SetValue then sb:SetValue(v) else scroll:SetVerticalScroll(v) end
                ns.UI.Sound("tick")
            end
            return
        end
        local cur = nav.cur
        local here = false
        for _, c in ipairs(items) do if c == cur then here = true end end
        if not here then nav:Focus(First(items)); ns.UI.Sound("tick"); return end
        if cur:GetObjectType() == "Slider" and (dir == "left" or dir == "right") then
            local lo, hi = cur:GetMinMaxValues()
            local step = cur:GetValueStep() or 1
            local v = (cur:GetValue() or lo) + (dir == "right" and step or -step)
            cur:SetValue(math.max(lo, math.min(hi, v)))
            local up = cur:GetScript("OnMouseUp")
            if up then pcall(up, cur) end
            ns.UI.Sound("tick")
            return
        end
        local nxt = Nearest(items, cur, dir)
        if nxt then nav:Focus(nxt); ns.UI.Sound("tick") end
    end

    function nav:Press()
        local cur = nav.cur
        if not (cur and cur:IsVisible()) then nav:Move("down"); return end
        if cur:GetObjectType() == "Slider" then return end
        cur:Click()
        -- the page may have changed under us
        ns.UI.Later(function()
            if not (nav.cur and nav.cur:IsVisible()) then nav:Clear() end
            nav:Paint()
        end)
    end

    function nav:Back()
        local pop = Popup()
        if pop then pop:Hide(); nav:Clear(); nav:Paint(); return end
        if o.close then o.close() else win:Hide() end
    end

    nav.PAD = {
        PADDUP = function() nav:Move("up") end, PADDDOWN = function() nav:Move("down") end,
        PADDLEFT = function() nav:Move("left") end, PADDRIGHT = function() nav:Move("right") end,
        PAD1 = function() nav:Press() end,
        PAD2 = function() nav:Back() end,
    }
    if o.pages then
        nav.PAD.PADLSHOULDER = function() nav:Clear(); o.pages(-1); nav:Paint() end
        nav.PAD.PADRSHOULDER = function() nav:Clear(); o.pages(1); nav:Paint() end
    end

    -- buttons we use stay with the window, the rest go on to the game
    local function Pass(on) if not InCombatLockdown() then pcall(win.SetPropagateKeyboardInput, win, on) end end
    pcall(win.EnableGamePadButton, win, true)
    win:HookScript("OnShow", function()
        Pass(true)
        nav:Clear()
        if ns.OneKey and ns.OneKey.GamepadUIOn() then bar:Show(); nav:Paint() else bar:Hide() end
    end)
    win:HookScript("OnHide", function() nav:Clear(); bar:Hide() end)
    pcall(win.SetScript, win, "OnGamePadButtonDown", function(_, button)
        local f = nav.PAD[button]
        if f then Pass(false); f() else Pass(true) end
    end)
    return nav
end
