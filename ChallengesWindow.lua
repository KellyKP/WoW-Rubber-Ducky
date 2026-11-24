-- Rubber Ducky: the Ducky's Challenges window. Kelly's challenge frame around
-- the same pieces as our settings window: groups down the left, the plates in
-- a scrolling list on the right. Opens from the journal's Records page.

local ADDON, ns = ...
local CW = {}
ns.ChallengesWindow = CW

local NAV_W = 204
local RING = 84                     -- every medallion's ring, the same size on every plate
local GAP = 8                       -- room between plates

local win, scroll, child, navButtons, rows, current = nil, nil, nil, {}, {}, "all"

local function Place()
    win:ClearAllPoints()
    win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

-- each plate: its art, how big its ring is in the art, and the bar plate's ring a bit bigger
-- (its parchment is thinner, so it needs the height)
local PLATES = { plate = 1, plate_locked = 1, plate_bar = 1.4 }

local function NewRow()
    local r = CreateFrame("Frame", nil, child)
    r:SetSize(400, 70)
    r.plate = ns.UI.Stretch(r, "plate", "BACKGROUND")
    r.medal = r:CreateTexture(nil, "BORDER")
    r.track = r:CreateTexture(nil, "ARTWORK", nil, 1)
    r.track:SetColorTexture(0.08, 0.09, 0.13, 0.9)
    r.fill = r:CreateTexture(nil, "ARTWORK", nil, 2)
    r.fill:SetTexture(ns.MEDIA .. "UI\\challenge_fill")
    r.name = r:CreateFontString(nil, "OVERLAY", ns.UI.FONT.bold)
    r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r.goal = r:CreateFontString(nil, "OVERLAY", ns.UI.FONT.small)
    r.goal:SetJustifyH("LEFT"); r.goal:SetWordWrap(false)
    r.right = r:CreateFontString(nil, "OVERLAY", ns.UI.FONT.bold)
    r.right:SetJustifyH("RIGHT")
    r.reward = r:CreateTexture(nil, "OVERLAY") -- the flair it finds you
    r.reward:SetSize(30, 30)
    r.bones = r:CreateFontString(nil, "OVERLAY", ns.UI.FONT.small) -- the Fishbones it pays
    r.bones:SetJustifyH("RIGHT")
    -- what it pays and finds, on hover
    r:EnableMouse(true)
    r:SetScript("OnEnter", function(self)
        local c = self.c
        if not c or (c.def.hidden and not c.done) then return end
        local F = ns.Flair
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(c.def.name)
        GameTooltip:AddLine(c.done and "You earned:" or "Earns:", 0.7, 0.7, 0.7)
        local r2 = F and F.REWARD[c.def.id]
        if r2 then GameTooltip:AddLine(F.Bones(r2) .. " Shiny Fishbones", 1, 1, 1) end
        for _, it in ipairs(F and F.Prizes(c.def.id) or {}) do
            GameTooltip:AddLine(it.name .. " " .. F.SINGULAR[it.kind], 1, 0.82, 0)
        end
        GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return r
end

local function When(done)
    if (done[1] or 0) == 0 then return "Before challenges" end
    return date("%b %d, %Y", done[1])
end

-- one plate, by where the challenge stands: done (the starred medallion), going
-- (the bar), not started (the plain duck), or hidden (the "?" on grey)
local function Paint(r, c, w)
    local UI, d = ns.UI, c.def
    local secret = d.hidden and not c.done
    -- grey and locked until it's done; then parchment and the star
    local art, medal = "plate_locked", nil
    if c.done then art, medal = "plate", "done"
    elseif secret then medal = "hidden" end
    local A = UI.ART[art]
    local ring = RING * PLATES[art]
    local s = ring / A.ring[3]
    local h = A.ah * s
    r:SetSize(w, h)
    r.plate.s = s
    r.plate:SetArt(art)
    -- a medallion over the plate's own, for done and hidden
    if medal then
        local size = ring / UI.MEDAL_RING
        UI.Medal(r.medal, medal)
        r.medal:SetSize(size, size)
        r.medal:ClearAllPoints()
        r.medal:SetPoint("CENTER", r, "TOPLEFT", r.plate:X(A.ring[1]), -r.plate:Y(A.ring[2]) - size * 11 / 256)
        r.medal:Show()
    else r.medal:Hide() end
    -- the words stay inside the parchment
    local B = A.body
    local x0, x1 = r.plate:X(B[1]) + 6, r.plate:X(B[3]) - 6
    local y0, y1 = r.plate:Y(B[2]), r.plate:Y(B[4])
    local right
    if c.done then right = When(c.done)
    elseif not secret and c.need > 1 then
        right = BreakUpLargeNumbers and (BreakUpLargeNumbers(c.have) .. " / " .. BreakUpLargeNumbers(c.need)) or (c.have .. " / " .. c.need)
    end
    r.right:SetText(right or "")
    local rw = right and ((r.right:GetStringWidth() or 60) + 12) or 0
    -- the Fishbones it pays, under the date or the count
    local F = ns.Flair
    local pay = F and F.REWARD[d.id]
    r.bones:SetText(pay and not secret and ("+" .. F.Bones(pay, 12)) or "")
    local bw = pay and not secret and ((r.bones:GetStringWidth() or 40) + 12) or 0
    rw = math.max(rw, bw)
    -- a challenge that finds you flair shows it, dim until it's yours
    local prize
    for _, it in ipairs(F and F.Prizes(d.id) or {}) do
        if it.kind ~= "motto" and not prize then prize = it end
    end
    if prize and not secret then
        r.reward:SetTexture(prize.art)
        if prize.kind == "board" then
            r.reward:SetSize(52, 52 * prize.h / prize.w)
            r.reward:SetTexCoord(0, prize.w / 512, 0, prize.h / 256)
        else
            r.reward:SetSize(30, 30)
            r.reward:SetTexCoord(0, 1, 0, 1)
        end
        r.reward:SetDesaturated(not c.done)
        r.reward:SetAlpha(c.done and 1 or 0.6)
        r.reward:ClearAllPoints()
        r.reward:SetPoint("RIGHT", r, "TOPLEFT", x1 - rw + 4, -(y0 + (y1 - y0) / 2))
        r.reward:Show()
        rw = rw + (r.reward:GetWidth() or 30)
    else r.reward:Hide() end
    r.c = c
    local going = not c.done and not secret and c.need > 1 and c.have > 0
    local ty = y0 + math.max(2, ((y1 - y0) - (going and 36 or 30)) / 2)
    r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", r, "TOPLEFT", x0, -ty)
    r.name:SetWidth(math.max(40, x1 - x0 - rw))
    r.goal:ClearAllPoints(); r.goal:SetPoint("TOPLEFT", r, "TOPLEFT", x0, -(ty + 16))
    r.bones:ClearAllPoints(); r.bones:SetPoint("TOPRIGHT", r, "TOPLEFT", x1, -(ty + 17))
    local rwide = r.reward:IsShown() and (r.reward:GetWidth() or 30) + 6 or 0
    r.goal:SetWidth(math.max(40, x1 - x0 - rwide - bw))
    r.right:ClearAllPoints(); r.right:SetPoint("TOPRIGHT", r, "TOPLEFT", x1, -(ty + 1))
    r.name:SetText(secret and "???" or d.name)
    r.goal:SetText(secret and "Keep fishing to reveal this challenge." or d.goal)
    local tone = not c.done and { 0.9, 0.9, 0.9 } or nil
    for _, fs in ipairs({ r.name, r.goal, r.right, r.bones }) do
        if tone then fs:SetTextColor(tone[1], tone[2], tone[3])
        else local k = fs == r.goal and UI.INK_SOFT or UI.INK; fs:SetTextColor(k[1], k[2], k[3]) end
    end
    -- the name in bold, the journal's way: drawn twice, a pixel apart, in its own colour
    local nc = tone or UI.INK
    r.name:SetShadowColor(nc[1], nc[2], nc[3], 1)
    r.name:SetShadowOffset(1, 0)
    -- on the way: a thin bar under the words, filling from the left
    if going then
        local bx0, bx1 = x0, x1 - rwide - bw
        local by = ty + 29
        local frac = math.max(0.02, math.min(1, c.have / c.need))
        r.track:ClearAllPoints()
        r.track:SetPoint("TOPLEFT", r, "TOPLEFT", bx0, -by)
        r.track:SetSize(bx1 - bx0, 6)
        r.track:Show()
        r.fill:ClearAllPoints()
        r.fill:SetPoint("TOPLEFT", r, "TOPLEFT", bx0 + 1, -(by + 1))
        r.fill:SetSize((bx1 - bx0 - 2) * frac, 4)
        r.fill:SetTexCoord(0, frac, 0, 1)
        r.track:Show(); r.fill:Show()
    else r.track:Hide(); r.fill:Hide() end
    return h
end

function CW:Refresh()
    if not win then return end
    local CH = ns.Challenges
    for _, b in ipairs(navButtons) do
        local n, all = CH:Count(b.key)
        b.count:SetText(n .. " / " .. all)
        local on = b.key == current
        b.art:SetArt(on and "strip_parch" or "strip_navy")
        b.text:SetFontObject(on and ns.UI.FONT.bold or "GameFontHighlight")
        b.count:SetFontObject(on and ns.UI.FONT.soft or "GameFontDisableSmall")
    end
    for _, g in ipairs(CH.GROUPS) do
        if g[1] == current then win.title:SetText(g[2]); win.line:SetText(g[3]) end
    end
    local list = CH:State()
    local sw = scroll:GetWidth()
    if not sw or sw < 50 then sw = child:GetWidth() or 500 end
    local w = sw - 2
    local y, i = 0, 0
    for _, c in ipairs(list) do
        if current == "all" or c.def.group == current then
            i = i + 1
            local r = rows[i] or NewRow()
            rows[i] = r
            r:ClearAllPoints()
            r:SetPoint("TOPLEFT", child, "TOPLEFT", 0, -y)
            local h = Paint(r, c, w)
            r:Show()
            y = y + h + GAP
        end
    end
    for k = i + 1, #rows do rows[k]:Hide() end
    child:SetHeight(math.max(1, y))
    CW.shown = i
end

local function Build()
    local SW = ns.SettingsWindow
    win = SW.Chrome("RubberDuckyChallenges", nil, { sign = "challenges", height = 560 })
    local k = SW.TEXT_SCALE
    local L, T, R, B = unpack(win.inner)
    local W = win:GetWidth() or 909

    -- the groups: navy plates, parchment for the one you're on
    for i, g in ipairs(ns.Challenges.GROUPS) do
        local b = CreateFrame("Button", nil, win)
        b:SetScale(k)
        b:SetSize(NAV_W / k, 30)
        b:SetPoint("TOPLEFT", win, "TOPLEFT", L / k, -(T + 4 + (i - 1) * 36) / k)
        b:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
        b.art = ns.UI.Stretch(b, "strip_navy", "BACKGROUND")
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 12, -5); hl:SetPoint("BOTTOMRIGHT", -12, 5); hl:SetColorTexture(1, 1, 1, 0.08)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("LEFT", 20, 0)
        fs:SetText(g[2])
        local n = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        n:SetPoint("RIGHT", -18, 0)
        b.text, b.count, b.key = fs, n, g[1]
        b:SetScript("OnClick", function()
            if current ~= g[1] then ns.UI.Sound("page") end
            CW:ShowGroup(g[1])
        end)
        navButtons[#navButtons + 1] = b
    end

    -- the page: a title, Ducky's line, and the plates
    local page = CreateFrame("Frame", nil, win)
    -- scaled up a touch, so its offsets are in its own (scaled) units
    page:SetScale(k)
    page:SetPoint("TOPLEFT", win, "TOPLEFT", (L + NAV_W + 16) / k, -T / k)
    page:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -R / k, B / k)
    page:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 4, -2)
    local line = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    win.title, win.line = title, line

    scroll = CreateFrame("ScrollFrame", "RubberDuckyChallengesScroll", page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -46)
    scroll:SetPoint("BOTTOMRIGHT", -14, 0)
    child = CreateFrame("Frame", nil, scroll)
    -- the plates are as wide as the list, never wider: clear of the scroll bar
    child:SetSize(((W - L - NAV_W - 16 - R) / k) - 14, 10)
    scroll:SetScript("OnSizeChanged", function(_, w)
        if w and w > 0 then child:SetWidth(w); if win:IsShown() then CW:Refresh() end end
    end)
    scroll:SetScrollChild(child)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local v = (self:GetVerticalScroll() or 0) - delta * 60
        self:SetVerticalScroll(math.max(0, math.min(v, self:GetVerticalScrollRange() or 0)))
    end)
    ns.UI.SlimScrollBar(scroll, page)
    CW.scroll, CW.child = scroll, child

    win:SetScript("OnShow", function() Place(); ns.UI.Sound("challengesOpen") end)
    win:SetScript("OnHide", function() ns.UI.Sound("challengesClose") end)
    -- a controller: up and down scroll, the shoulders change group
    CW.pad = ns.Pad.Attach(win, {
        roots = function() return { page } end,
        scroll = function() return scroll end,
        pagesLabel = "Groups",
        pages = function(dir)
            local G = ns.Challenges.GROUPS
            for i, g in ipairs(G) do
                if g[1] == current then
                    ns.UI.Sound("page")
                    CW:ShowGroup(G[(i - 1 + dir) % #G + 1][1])
                    return
                end
            end
        end,
    })
    Place()
end

function CW:ShowGroup(key)
    current = key or "all"
    if scroll then scroll:SetVerticalScroll(0) end
    self:Refresh()
end

function CW:Show(group)
    if not win then Build() end
    ns.Challenges:Check()
    current = group or current or "all"
    win:Show()
    self:ShowGroup(current)
    return true
end
function CW:Hide() if win then win:Hide() end end
function CW:IsShown() return win ~= nil and win:IsShown() end
function CW:Toggle(group) if self:IsShown() then self:Hide() else self:Show(group) end end
function CW:Group() return current end
