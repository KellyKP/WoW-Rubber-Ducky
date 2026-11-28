-- Rubber Ducky: the Ducky's Challenges window. Kelly's challenge frame around
-- the same pieces as our settings window: the groups as a row of tabs along
-- the top, the plates in a scrolling list under them. Opens from the journal's
-- Records page.

local ADDON, ns = ...
local CW = {}
ns.ChallengesWindow = CW

local RING = 84                     -- every medallion's ring, the same size on every plate
local GAP = 8                       -- room between plates
local WIDTH = 1069                  -- the window: the settings window's, plus room for the rewards
local REWARD_W = 132                -- the reward tile beside each plate
local TILE_GAP = 8
-- the Show filter: all, the ones you're nearest to finishing, finished, still to do
local SHOWS = { { "all", "All" }, { "close", "Close" }, { "done", "Done" }, { "todo", "To do" } }
local EMPTY = {
    all = "Nothing here yet.",
    close = "Nothing started here yet. Go get your line wet!",
    done = "None of these done yet. Ducky believes in you.",
    todo = "All done here. Ducky's impressed!",
}

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
    -- beside the plate: a parchment tile with what it pays and finds
    r.tile = CreateFrame("Frame", nil, r)
    r.tile.art = ns.UI.Stretch(r.tile, "tile_parch", "BACKGROUND", 0.42)
    r.reward = r.tile:CreateTexture(nil, "ARTWORK") -- the flair it finds you
    r.motto = r.tile:CreateFontString(nil, "ARTWORK", ns.UI.FONT.small) -- or the motto
    r.motto:SetJustifyH("CENTER"); r.motto:SetWordWrap(true)
    r.bones = r.tile:CreateFontString(nil, "ARTWORK", ns.UI.FONT.bold) -- the Fishbones it pays
    r.bones:SetJustifyH("CENTER")
    -- what it pays and finds, on hover
    r:EnableMouse(true)
    r.tile:EnableMouse(true)
    local function Tip(self)
        self = self.c and self or self:GetParent()
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
        if not c.done then
            local CH = ns.Challenges
            local on = CH.Saved().track == c.def.id
            GameTooltip:AddLine(on and "Click to stop tracking it." or "Click to track it on your fishing log.", 0.5, 0.8, 1)
        end
        GameTooltip:Show()
    end
    -- click to track it on the fishing log (again to stop)
    local function Click(self)
        self = self.c and self or self:GetParent()
        local c, CH = self.c, ns.Challenges
        if not c or c.done or c.def.hidden then return end
        local on = CH.Saved().track == c.def.id
        CH.Track(not on and c.def.id or nil)
        ns.UI.Sound(on and "off" or "on")
        if self:IsMouseOver() then Tip(self) end
    end
    r:SetScript("OnMouseUp", Click)
    r.tile:SetScript("OnMouseUp", Click)
    -- the tracked one wears a little compass on its corner
    r.trackMark = r:CreateTexture(nil, "OVERLAY", nil, 3)
    r.trackMark:SetTexture(ns.MEDIA .. "UI\\tracked")
    r.trackMark:SetSize(36, 36)
    r.trackMark:Hide()
    r:SetScript("OnEnter", Tip)
    r.tile:SetScript("OnEnter", Tip)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    r.tile:SetScript("OnLeave", function() GameTooltip:Hide() end)
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
    r:SetSize(w - REWARD_W - TILE_GAP, h) -- the tile goes beside it
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
    -- the tile: what it finds you, dim until it's yours, and the Fishbones it pays
    local F = ns.Flair
    local pay = F and F.REWARD[d.id]
    local prize, motto
    for _, it in ipairs(F and F.Prizes(d.id) or {}) do
        if it.kind == "motto" then motto = motto or it
        elseif not prize then prize = it end
    end
    local tw, th = REWARD_W, h - 14
    r.tile:SetSize(tw, th)
    r.tile:ClearAllPoints()
    r.tile:SetPoint("LEFT", r, "RIGHT", TILE_GAP, 0)
    r.tile:Show()
    local bonesH = pay and 22 or 0
    local roomH = th - 16 - bonesH -- above the Fishbones, inside the parchment
    r.reward:Hide(); r.motto:Hide()
    if secret then
        pay, prize, motto = nil, nil, nil
    elseif prize then
        r.reward:SetTexture(prize.art)
        if prize.kind == "board" then
            -- small enough to leave the Fishbones their room
            local bw = math.min(tw * 0.66, roomH * 2)
            r.reward:SetSize(bw, bw / 2)
            r.reward:SetTexCoord(0, 1, 0, 1)
        else
            local sz = math.min(40, roomH)
            r.reward:SetSize(sz, sz)
            r.reward:SetTexCoord(0, 1, 0, 1)
        end
        r.reward:SetDesaturated(not c.done)
        r.reward:SetAlpha(c.done and 1 or 0.6)
        r.reward:ClearAllPoints()
        r.reward:SetPoint("CENTER", r.tile, "TOP", 0, -(8 + roomH / 2))
        r.reward:Show()
    elseif motto then
        r.motto:SetWidth(tw - 24)
        r.motto:SetText("\"" .. motto.name .. "\"")
        r.motto:SetTextColor(UI.INK[1], UI.INK[2], UI.INK[3], c.done and 1 or 0.6)
        r.motto:ClearAllPoints()
        r.motto:SetPoint("CENTER", r.tile, "TOP", 0, -(8 + roomH / 2))
        r.motto:Show()
    end
    r.bones:SetText(pay and ("+" .. F.Bones(pay, 18)) or "")
    -- bold, the journal's way: drawn twice, a pixel apart
    r.bones:SetShadowColor(UI.INK[1], UI.INK[2], UI.INK[3], 1)
    r.bones:SetShadowOffset(1, 0)
    r.bones:ClearAllPoints()
    if prize or motto then r.bones:SetPoint("BOTTOM", r.tile, "BOTTOM", 0, 8)
    else r.bones:SetPoint("CENTER", r.tile, "CENTER", 0, 0) end
    r.bones:SetTextColor(UI.INK[1], UI.INK[2], UI.INK[3])
    r.c = c
    local tracked = not c.done and ns.Challenges.Saved().track == d.id
    r.trackMark:SetShown(tracked)
    local going = not c.done and not secret and c.need > 1 and c.have > 0
    local ty = y0 + math.max(2, ((y1 - y0) - (going and 36 or 30)) / 2)
    -- just past the count, at the plate's right end
    r.trackMark:ClearAllPoints()
    r.trackMark:SetPoint("CENTER", r, "TOPLEFT", x1 + 24, -(ty + 8))
    r.name:ClearAllPoints(); r.name:SetPoint("TOPLEFT", r, "TOPLEFT", x0, -ty)
    r.name:SetWidth(math.max(40, x1 - x0 - rw))
    r.goal:ClearAllPoints(); r.goal:SetPoint("TOPLEFT", r, "TOPLEFT", x0, -(ty + 16))
    r.goal:SetWidth(math.max(40, x1 - x0))
    r.right:ClearAllPoints(); r.right:SetPoint("TOPRIGHT", r, "TOPLEFT", x1, -(ty + 1))
    r.name:SetText(secret and "???" or d.name)
    r.goal:SetText(secret and "Keep fishing to reveal this challenge." or d.goal)
    local tone = not c.done and { 0.9, 0.9, 0.9 } or nil
    for _, fs in ipairs({ r.name, r.goal, r.right }) do
        if tone then fs:SetTextColor(tone[1], tone[2], tone[3])
        else local k = fs == r.goal and UI.INK_SOFT or UI.INK; fs:SetTextColor(k[1], k[2], k[3]) end
    end
    -- the name in bold, the journal's way: drawn twice, a pixel apart, in its own colour
    local nc = tone or UI.INK
    r.name:SetShadowColor(nc[1], nc[2], nc[3], 1)
    r.name:SetShadowOffset(1, 0)
    -- on the way: a thin bar under the words, filling from the left
    if going then
        local bx0, bx1 = x0, x1 - rw
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
    CW.tabs:Select(current)
    for _, g in ipairs(CH.GROUPS) do
        if g[1] == current then
            win.title:SetText(g[2]); win.line:SetText(g[3])
            local n, all = CH:Count(g[1])
            win.count:SetText(n .. " / " .. all)
        end
    end
    -- the Show filter
    local show = ns.db.challengesShow or "all"
    for _, b in ipairs(CW.chips or {}) do b:Paint(b.key == show) end
    local list = {}
    for n, c in ipairs(CH:State()) do
        local secret = c.def.hidden and not c.done
        local ok = show == "all"
            or (show == "done" and c.done)
            or (show == "todo" and not c.done)
            or (show == "close" and not c.done and not secret and c.need > 1 and (c.have or 0) > 0)
        if ok then c.order = n; list[#list + 1] = c end
    end
    if show == "close" then
        -- nearest to done first
        table.sort(list, function(a, b)
            local fa, fb = a.have / a.need, b.have / b.need
            if fa ~= fb then return fa > fb end
            return a.order < b.order
        end)
    elseif show == "done" then
        -- newest first (ones from before challenges last)
        table.sort(list, function(a, b)
            local ta, tb = a.done[1] or 0, b.done[1] or 0
            if ta ~= tb then return ta > tb end
            return a.order < b.order
        end)
    end
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
    win.empty:SetText(EMPTY[show] or EMPTY.all)
    win.empty:SetShown(i == 0)
    child:SetHeight(math.max(1, y))
    CW.shown = i
end

local function Build()
    local SW = ns.SettingsWindow
    win = SW.Chrome("RubberDuckyChallenges", nil, { sign = "challenges", height = 620, width = WIDTH,
        signWidth = math.floor(909 * 0.74) })
    local k = SW.TEXT_SCALE
    local L, T, R, B = unpack(win.inner)
    local W = win:GetWidth() or WIDTH

    -- the groups: a row of tabs along the top, the one you're on standing
    -- taller; LB and RB badges sit at either end of the row
    local items = {}
    for i, g in ipairs(ns.Challenges.GROUPS) do items[i] = { g[1], g[2] } end
    CW.tabs = ns.UI.TabRow(win, items, function(key)
        if current ~= key then ns.UI.Sound("page") end
        CW:ShowGroup(key)
    end, { inset = 30 })
    CW.tabs:Place(L, T + 2, W - L - R)
    navButtons = CW.tabs.buttons
    local top = T + 2 + ns.UI.TAB_ROW_H + 10 -- the page starts under the tabs

    -- the page: a title, Ducky's line, and the plates
    local page = CreateFrame("Frame", nil, win)
    -- scaled up a touch, so its offsets are in its own (scaled) units
    page:SetScale(k)
    page:SetPoint("TOPLEFT", win, "TOPLEFT", L / k, -top / k)
    page:SetPoint("BOTTOMRIGHT", win, "BOTTOMRIGHT", -R / k, B / k)
    page:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 4, -2)
    local line = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    -- how many of this group you've done, beside its name
    local count = page:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    count:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 10, 1)
    win.title, win.line, win.count = title, line, count
    local empty = page:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    empty:SetPoint("TOP", 0, -90)
    empty:Hide()
    win.empty = empty

    -- Show: all, close, done, to do. Up on the window, not the page, so the
    -- D-pad still scrolls the list (X cycles it on a controller)
    local bar = CreateFrame("Frame", nil, win)
    bar:SetScale(k)
    bar:SetSize(300, 26)
    bar:SetPoint("TOPRIGHT", win, "TOPRIGHT", -(R + 16) / k, -(top + 8) / k)
    bar:SetFrameLevel((win:GetFrameLevel() or 1) + 6)
    CW.chips = {}
    local x = 0
    for n = #SHOWS, 1, -1 do -- right to left
        local key, label = SHOWS[n][1], SHOWS[n][2]
        local b = CreateFrame("Button", nil, bar)
        b.key = key
        b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        b.text:SetPoint("CENTER", 0, 1)
        b.text:SetText(label)
        local bw = (b.text:GetStringWidth() or 40) + 34
        b:SetSize(bw, 26)
        b:SetPoint("RIGHT", bar, "RIGHT", -x, 0)
        x = x + bw + 2
        b.bg = CreateFrame("Frame", nil, b) -- the parchment, only behind the one you're on
        b.bg:SetAllPoints()
        b.bg:SetFrameLevel(b:GetFrameLevel())
        ns.UI.Stretch(b.bg, "strip_parch", "BACKGROUND")
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 10, -4); hl:SetPoint("BOTTOMRIGHT", -10, 4); hl:SetColorTexture(1, 1, 1, 0.08)
        function b:Paint(on)
            self.bg:SetShown(on)
            self.text:SetFontObject(on and ns.UI.FONT.bold or "GameFontHighlight")
        end
        b:SetScript("OnClick", function() CW:SetShow(key) end)
        CW.chips[n] = b
    end
    local lbl = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    lbl:SetPoint("RIGHT", bar, "RIGHT", -x - 4, 0)
    lbl:SetText("Sort:")

    scroll = CreateFrame("ScrollFrame", "RubberDuckyChallengesScroll", page, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, -46)
    scroll:SetPoint("BOTTOMRIGHT", -ns.UI.SCROLL_ROOM, 0)
    child = CreateFrame("Frame", nil, scroll)
    -- the plates are as wide as the list, never wider: clear of the scroll bar
    child:SetSize(((W - L - R) / k) - ns.UI.SCROLL_ROOM, 10)
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
    CW.sortBar = bar
    -- a controller: up and down scroll, the shoulders change group, X sorts,
    -- B closes; each with a badge on what it works
    CW.pad = ns.Pad.Attach(win, {
        roots = function() return { page } end,
        scroll = function() return scroll end,
        badges = function(nav)
            nav:Badge(navButtons[1], "PADLSHOULDER", "LEFT", -18, -4, 28)
            nav:Badge(navButtons[#navButtons], "PADRSHOULDER", "RIGHT", 18, -4, 28)
            nav:Badge(lbl, "PAD3", "LEFT", -16, 0, 24)
            nav:Badge(win.close, "PAD2", "TOPLEFT", 2, -2, 22)
        end,
        extra = { button = "PAD3", fn = function()
            local cur = ns.db.challengesShow or "all"
            for n, sh in ipairs(SHOWS) do
                if sh[1] == cur then CW:SetShow(SHOWS[n % #SHOWS + 1][1]); return end
            end
            CW:SetShow("all")
        end },
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

function CW:SetShow(key)
    if (ns.db.challengesShow or "all") ~= key then ns.UI.Sound("page") end
    ns.db.challengesShow = key
    if scroll then scroll:SetVerticalScroll(0) end
    self:Refresh()
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
