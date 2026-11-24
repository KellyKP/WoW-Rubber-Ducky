-- Rubber Ducky: fishing log. What you caught this session, on the painted board
-- (Media\Log\board). Positions below are in the art's own pixels (1024 square).

local _, ns = ...
local Log = {}
ns.Log = Log

local ART = 1024
local BASE = 440 -- on-screen size at scale 1
local K = BASE / ART
local ROWS = { { 327, 389 }, { 389, 451 }, { 451, 514 }, { 514, 576 }, { 576, 639 }, { 639, 701 }, { 701, 764 } }
local COL_LOOT, COL_COUNT, COL_NOTE = { 149, 620 }, { 620, 702 }, { 702, 950 }
local TOTAL = { 526, 836 } -- centre of the blue strip (a little low: the font sits high)
local TOTAL_RISE = 0.04 -- the total climbs a little to the right, letter by letter
local TITLE = { 548, 176, 82 } -- "Fishing Log" on the top plank, in the log's own hand: centre, size
local TITLE_TEXT = "Fishing Log"
-- how far each letter sits up (-) or down (+), in art pixels: a little wonky on purpose
local TITLE_BOB = { -4, 7, -5, 3, -7, 5, -3, 0, 6, -6, -9 }
local CLOSE = { 954, 124, 41 } -- painted buttons: centre and radius
local RENEW = { 947, 216, 31 }
-- the rope scrollbar, only there when there's more than fits
local TRACK = { 923, 262, 72, 547 } -- the rope layer (Log\scrolltrack, 128x1024): x, y, w, h
local UP, DOWN, BTN = { 959, 304 }, { 958.5, 765.5 }, 67 -- round buttons (Log\scrollparts)
local THUMB = { 959, 335, 735, 60, 120 } -- x, top and bottom of its travel, w, h
-- the little framed box for your Fishbone luck, shown only while you have some
local BUFF = { 103, 803, 126, 118 } -- Log\buffbox, 128 square
local BUFF_ICON = { 125, 821, 207, 900 } -- the icon fills it to the wood, rivets and all
local CATTAILS = { 138, 711, 70 } -- drawn over the last row (Log\cattails, 128 square)
local NAME_W = COL_LOOT[2] - COL_LOOT[1] - 93 -- room for the name after the icon

local FONT = ns.MEDIA .. "Fonts\\PatrickHand-Regular.ttf"
local NO_LATIN_FONT = { koKR = true, zhCN = true, zhTW = true, ruRU = true }
local INK = { 0.27, 0.16, 0.08 }

-- rarity ink for the name and the note (darker than the game's colours, to read on parchment)
local RARITY = {
    [0] = { 0.43, 0.43, 0.43 },
    [1] = INK,
    [2] = { 0.12, 0.47, 0.08 },
    [3] = { 0.0, 0.31, 0.67 },
    [4] = { 0.47, 0.16, 0.67 },
    [5] = { 0.78, 0.35, 0.0 },
    [6] = { 0.62, 0.48, 0.12 },
    [7] = { 0.0, 0.48, 0.62 },
}

-- short, so they fit the notes box
Log.NOTES = {
    [0] = { "Huh, okay!", "Ah well!", "It's something!", "Oops!", "Meh!", "Close enough!",
        "Keep trying!", "Soggy!", "Smells funny!", "Well, okay!" },
    [1] = { "Nice start!", "So cute! \226\153\165", "Feisty!", "A keeper!", "Dinner!", "Solid catch!",
        "Tasty!", "Good haul!", "Nice one!", "Hooked it!", "Got one!", "Lunch!", "Fresh!",
        "Wiggly!", "Classic!", "Reliable!", "Neat!", "Splashy!" },
    [2] = { "Not bad!", "Ooh, nice!", "Lucky you!", "Look at that!", "Sweet!", "Nice find!",
        "Ooh!", "Handy!", "Lucky cast!", "Good eye!" },
    [3] = { "Great find!", "Rare catch!", "Wow!", "Shiny!", "Sparkly!", "What a find!",
        "Rare one!", "Treasure!", "Dazzling!", "Oh my!" },
    [4] = { "Good one!", "Whoa!", "Epic catch!", "Best yet!", "Wow, wow!", "Huge!",
        "Stunning!", "Big catch!", "Amazing!" },
    [5] = { "Incredible!", "Legendary!", "No way!", "Unreal!", "Mythic!", "Jackpot!", "Wow!!" },
    [6] = { "Truly special!", "Artifact!", "Is it real?", "Ancient!", "Priceless!", "Glowing!", "A relic!" },
    [7] = { "Timeless!", "Heirloom!", "Treasure it!", "A classic!", "Cherished! \226\153\165", "Ageless!",
        "Family pride!" },
}

Log.BONES_NOTES = { "For Mrrl!", "Shiny!", "Ooh, sparkly!", "Mrrgl!", "Pocket it!", "Treat yourself!" }

-- this session's catch, in the order first caught
local session = { order = {}, items = {}, total = 0 }
Log.session = session
local top, lastCast = 0, nil -- top: how many rows are scrolled past

local win, rows, total, scroll, buff

local function P(x, y) return x * K, -y * K end -- art pixels -> frame offsets from TOPLEFT

local function SetFont(fs, size)
    local ok = not NO_LATIN_FONT[GetLocale and GetLocale() or ""] and pcall(fs.SetFont, fs, FONT, size, "")
    if not ok or not fs:GetFont() then fs:SetFont(STANDARD_TEXT_FONT, size * 0.85, "") end
    fs:SetTextColor(INK[1], INK[2], INK[3])
end

-- largest size up to `size` that fits `width`
-- (min: the smallest it may go; past that the line ends in "...")
local function Fit(fs, text, size, width, min)
    fs:SetText(text)
    while size > (min or 8) and (fs:GetStringWidth() or 0) > width do
        size = size - 0.5
        SetFont(fs, size)
    end
end

local function Text(parent, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    SetFont(fs, size)
    fs:SetJustifyH(justify or "CENTER")
    fs:SetWordWrap(false)
    return fs
end

-- It's about the fish, not how it's cooked: "Raw Brilliant Smallfish" -> "Brilliant Smallfish"
-- (the item's tooltip still shows its real name)
function ns.FishName(name)
    if not name then return name end
    return (name:gsub("^Raw ", ""):gsub(" Raw ", " "))
end

-- shared with the journal
Log.Ink = { INK = INK, RARITY = RARITY, SetFont = SetFont, Fit = Fit, Text = Text }

-- Words carved into a wooden sign (the fishing log's title, Mrrl's sign): the
-- log's own hand, dark ink with a light cut edge under it and a faint rim of
-- light all round, bold the journal's way (drawn twice, a pixel apart). One
-- letter at a time, so each can sit a little up or down, like a kid's sign.
local CARVE_INK = { 0.2, 0.1, 0.04 }
local CARVE_EDGE = { 0.94, 0.78, 0.55, 0.65 }
local CARVE_RIM = { 1, 0.89, 0.67, 0.28 }
local RIM = { { -1, 0 }, { 1, 0 }, { 0, 1 }, { 0, -1 }, { -0.7, 0.7 }, { 0.7, 0.7 }, { -0.7, -0.7 }, { 0.7, -0.7 } }
function ns.CarvedText(parent, text, size)
    local function Carve(ch, sub, c)
        local fs = parent:CreateFontString(nil, "OVERLAY")
        fs:SetDrawLayer("OVERLAY", sub)
        SetFont(fs, size)
        fs:SetTextColor(c[1], c[2], c[3], c[4] or 1)
        fs:SetShadowColor(c[1], c[2], c[3], c[4] or 1)
        fs:SetShadowOffset(1, 0)
        fs:SetText(ch)
        return fs
    end
    local o = { letters = {} }
    for i = 1, #text do
        local ch = text:sub(i, i)
        local l = { ch = ch, parts = {} }
        for _, r in ipairs(RIM) do l.parts[#l.parts + 1] = { Carve(ch, 1, CARVE_RIM), r[1], r[2] } end
        l.parts[#l.parts + 1] = { Carve(ch, 2, CARVE_EDGE), 0.7, -1.3 }
        l.ink = Carve(ch, 3, CARVE_INK)
        l.parts[#l.parts + 1] = { l.ink, 0, 0 }
        o.letters[i] = l
    end
    -- centred on (x, y) from anchor's top left; bob: each letter's nudge, + is down;
    -- width: spread the letters out to fill it. Again on show: a font that
    -- hadn't loaded yet measures nothing.
    function o:Place(anchor, x, y, bob, width)
        local widths, sum = {}, 0
        for i, l in ipairs(self.letters) do
            local w = l.ink:GetStringWidth() or 0
            if w == 0 then w = (l.ch == " " and 0.25 or 0.5) * size end
            widths[i] = w; sum = sum + w
        end
        local gap = 0
        if width and width > sum and #self.letters > 1 then gap = (width - sum) / (#self.letters - 1) end
        local left = x - (sum + gap * (#self.letters - 1)) / 2
        for i, l in ipairs(self.letters) do
            local cx, cy = left + widths[i] / 2, y - ((bob and bob[i]) or 0)
            for _, p in ipairs(l.parts) do
                p[1]:ClearAllPoints()
                p[1]:SetPoint("CENTER", anchor, "TOPLEFT", cx + p[2], cy + p[3])
            end
            left = left + widths[i] + gap
        end
    end
    return o
end

local quiet = false
local ICON_SIZE = 50

local function Build()
    win = CreateFrame("Frame", "RubberDuckyLog", UIParent)
    win:SetSize(BASE, BASE)
    win:SetFrameStrata("MEDIUM")
    win:SetClampedToScreen(true)
    win:SetMovable(true); win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, rel, x, y = self:GetPoint()
        ns.db.logPos = { point, rel, x, y }
    end)
    -- the world map's page sounds; quiet when the pole swap opens or closes it
    -- (the swap has its own sound). On the Master channel, like all the log's and
    -- journal's sounds, so the fishing boost on effects doesn't make them loud.
    local function Page(kit)
        if quiet or not SOUNDKIT then return end
        pcall(PlaySound, SOUNDKIT[kit], "Master")
    end
    win:SetScript("OnShow", function() Page("IG_QUEST_LOG_OPEN") end)
    win:SetScript("OnHide", function() Page("IG_QUEST_LOG_CLOSE") end)
    local board = win:CreateTexture(nil, "BACKGROUND")
    board:SetAllPoints()
    board:SetTexture(ns.MEDIA .. "Log\\board")

    local close = CreateFrame("Button", nil, win)
    close:SetSize(CLOSE[3] * 2 * K, CLOSE[3] * 2 * K)
    close:SetPoint("CENTER", win, "TOPLEFT", P(CLOSE[1], CLOSE[2]))
    close:SetScript("OnClick", function() win:Hide() end)
    close:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Close")
        GameTooltip:Show()
    end)
    close:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local hl = close:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight"); hl:SetBlendMode("ADD")

    -- painted "new session" button
    local renew = CreateFrame("Button", nil, win)
    renew:SetSize(RENEW[3] * 2 * K, RENEW[3] * 2 * K)
    renew:SetPoint("CENTER", win, "TOPLEFT", P(RENEW[1], RENEW[2]))
    local rhl = renew:CreateTexture(nil, "HIGHLIGHT")
    rhl:SetAllPoints(); rhl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight"); rhl:SetBlendMode("ADD")
    renew:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Start a new session")
        GameTooltip:Show()
    end)
    renew:SetScript("OnLeave", function() GameTooltip:Hide() end)
    renew:SetScript("OnClick", function()
        if SOUNDKIT then pcall(PlaySound, SOUNDKIT.IG_ABILITY_PAGE_TURN, "Master") end -- a fresh page
        Log:NewSession()
    end)
    Log.renewButton = renew

    rows = {}
    for i, r in ipairs(ROWS) do
        local h = (r[2] - r[1]) * K
        local row = CreateFrame("Frame", nil, win)
        local x0 = COL_LOOT[1] -- row frames start at the left of the table
        row:SetPoint("TOPLEFT", win, "TOPLEFT", P(x0, r[1]))
        row:SetSize((COL_NOTE[2] - x0) * K, h)
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.key == "bones" and ns.Flair then
                ns.Flair.Tooltip(self, "ANCHOR_RIGHT")
            elseif self.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                pcall(GameTooltip.SetItemByID, GameTooltip, self.id)
                if ns.Journal and ns.db.journalEnabled then
                    GameTooltip:AddLine("Click to open it in your journal.", 0.4, 0.8, 1)
                end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        -- click: open this catch in the journal, and it's not new any more
        row:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.key == "bones" and ns.Shop then ns.Shop:Show(); return end
            if button ~= "LeftButton" or not self.id or not ns.Journal then return end
            local e = self.key and session.items[self.key]
            if e then e.new = nil end
            ns.Journal:OpenTo(self.id)
            Log:Refresh()
        end)
        local mid = -(r[2] - r[1]) / 2

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(ICON_SIZE * K, ICON_SIZE * K)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        -- centred, so the stamp animation grows and shrinks around the middle
        local iconX = COL_LOOT[1] - x0 + 15
        row.icon:SetPoint("CENTER", row, "TOPLEFT", (iconX + ICON_SIZE / 2) * K, mid * K)

        row.name = Text(row, 16, "LEFT")
        row.name:SetPoint("LEFT", row, "TOPLEFT", (iconX + ICON_SIZE + 18) * K, mid * K)
        row.name:SetWidth(NAME_W * K)

        row.newTag = row:CreateTexture(nil, "OVERLAY")
        row.newTag:SetTexture(ns.MEDIA .. "Journal\\new")
        row.newTag:SetSize(80 * K, 40 * K)
        -- on the icon's corner, like the journal (fixed, so the stamp animation doesn't drag it)
        row.newTag:SetPoint("TOPLEFT", row, "TOPLEFT", (iconX - 16) * K, (mid + ICON_SIZE / 2 + 16) * K)
        row.newTag:Hide()

        row.count = Text(row, 19)
        row.count:SetPoint("CENTER", row, "TOPLEFT", ((COL_COUNT[1] + COL_COUNT[2]) / 2 - x0) * K, mid * K)

        local nx = ((COL_NOTE[1] + COL_NOTE[2]) / 2 - x0) * K
        row.note = Text(row, 16)
        row.note:SetPoint("CENTER", row, "TOPLEFT", nx, mid * K)
        row:Hide()
        rows[i] = row
    end

    -- one font string per letter, each a little higher than the last:
    -- a tilt without rotating text (the game draws rotated text jagged)
    total = { letters = {} }

    -- on top of the rows: the cattails, the luck box and the scrollbar
    local over = CreateFrame("Frame", nil, win)
    over:SetAllPoints()
    over:SetFrameLevel(win:GetFrameLevel() + 5)
    local reeds = over:CreateTexture(nil, "ARTWORK")
    reeds:SetTexture(ns.MEDIA .. "Log\\cattails")
    reeds:SetTexCoord(0, CATTAILS[3] / 128, 0, CATTAILS[3] / 128)
    reeds:SetSize(CATTAILS[3] * K, CATTAILS[3] * K)
    reeds:SetPoint("TOPLEFT", win, "TOPLEFT", P(CATTAILS[1], CATTAILS[2]))

    Log.carved = ns.CarvedText(over, TITLE_TEXT, TITLE[3] * K)
    Log.title = Log.carved.letters

    buff = CreateFrame("Frame", nil, win)
    buff:SetFrameLevel(win:GetFrameLevel() + 6)
    buff:SetSize(BUFF[3] * K, BUFF[4] * K)
    buff:SetPoint("TOPLEFT", win, "TOPLEFT", P(BUFF[1], BUFF[2]))
    local box = buff:CreateTexture(nil, "ARTWORK")
    box:SetAllPoints()
    box:SetTexture(ns.MEDIA .. "Log\\buffbox")
    box:SetTexCoord(0, BUFF[3] / 128, 0, BUFF[4] / 128)
    buff:Hide()

    scroll = CreateFrame("Frame", nil, win)
    scroll:SetFrameLevel(win:GetFrameLevel() + 6)
    scroll:SetSize(TRACK[3] * K, TRACK[4] * K)
    scroll:SetPoint("TOPLEFT", win, "TOPLEFT", P(TRACK[1], TRACK[2]))
    local rope = scroll:CreateTexture(nil, "BACKGROUND")
    rope:SetAllPoints()
    rope:SetTexture(ns.MEDIA .. "Log\\scrolltrack")
    rope:SetTexCoord(0, TRACK[3] / 128, 0, TRACK[4] / 1024)
    -- the parts sheet: a column per state (normal, lit, pressed, off);
    -- rows: up, down, then the thumb (twice as tall)
    local function Part(f, w, h, row, tall)
        f:SetSize(w * K, h * K)
        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints()
        f.tex:SetTexture(ns.MEDIA .. "Log\\scrollparts")
        function f:Paint()
            local c = self.off and 3 or self.down and 2 or self.over and 1 or 0
            local y0 = row / 4
            self.tex:SetTexCoord(c / 4, (c + 1) / 4, y0, y0 + (tall and 0.5 or 0.25))
        end
        f:SetScript("OnEnter", function(self) self.over = true; self:Paint() end)
        f:SetScript("OnLeave", function(self) self.over = nil; self:Paint() end)
        f:SetScript("OnMouseDown", function(self) if not self.off then self.down = true; self:Paint() end end)
        f:SetScript("OnMouseUp", function(self) self.down = nil; self:Paint() end)
        f:Paint()
        return f
    end
    local function Arrow(at, row, step)
        local b = Part(CreateFrame("Button", nil, scroll), BTN, BTN, row)
        b:SetPoint("CENTER", win, "TOPLEFT", P(at[1], at[2]))
        b:SetScript("OnClick", function(self) if not self.off then Log.Scroll(step) end end)
        return b
    end
    scroll.up = Arrow(UP, 0, -1)
    scroll.down = Arrow(DOWN, 1, 1)
    -- the thumb: drag it along the rope
    local thumb = Part(CreateFrame("Button", nil, scroll), THUMB[4], THUMB[5], 2, true)
    thumb:SetFrameLevel(scroll:GetFrameLevel() + 2)
    thumb:SetScript("OnMouseDown", function(self)
        self.down = true; self:Paint()
        local _, y = GetCursorPosition()
        self.drag = { y = y / win:GetEffectiveScale(), top = top }
    end)
    thumb:SetScript("OnMouseUp", function(self) self.down, self.drag = nil, nil; self:Paint() end)
    thumb:SetScript("OnUpdate", function(self)
        local d = self.drag
        if not d then return end
        if IsMouseButtonDown and not IsMouseButtonDown("LeftButton") then self.drag = nil; self.down = nil; self:Paint(); return end
        local _, y = GetCursorPosition()
        local travel = (THUMB[3] - THUMB[2] - THUMB[5]) * K
        local most = math.max(0, #session.order - #ROWS)
        if travel <= 0 or most == 0 then return end
        local want = d.top + math.floor((d.y - y / win:GetEffectiveScale()) / travel * most + 0.5)
        if want ~= top then top = want; Log:Refresh() end
    end)
    scroll.thumb = thumb
    scroll:Hide()
    Log.scroll = scroll

    win:EnableMouseWheel(true)
    win:SetScript("OnMouseWheel", function(_, delta) Log.Scroll(-delta) end)

    win:Hide()
end

-- lay the title's letters out along the plank (again on show: a font that
-- hadn't loaded yet measures nothing)
local function LayoutTitle()
    if not Log.carved then return end
    local bob = {}
    for i, b in ipairs(TITLE_BOB) do bob[i] = b * K end
    Log.carved:Place(win, TITLE[1] * K, -TITLE[2] * K, bob)
end

local function Place()
    win:SetScale(ns.db.logScale or 1)
    win:ClearAllPoints()
    local pos = ns.db.logPos
    if pos then win:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3], pos[4])
    else win:SetPoint("LEFT", UIParent, "LEFT", 30, 40) end
end

function Log.DrawTotal(text)
    local letters, widths, sum = total.letters, {}, 0
    for i = 1, #text do
        local fs = letters[i]
        if not fs then fs = Text(win, 17); letters[i] = fs end
        fs:SetText(text:sub(i, i))
        widths[i] = fs:GetStringWidth() or 0
        if widths[i] == 0 then widths[i] = 5 end -- a lone space can measure 0
        sum = sum + widths[i]
    end
    for i = #text + 1, #letters do letters[i]:Hide() end
    local x = -sum / 2
    local cx, cy = P(TOTAL[1], TOTAL[2])
    for i = 1, #text do
        local fs = letters[i]
        local mid = x + widths[i] / 2
        fs:ClearAllPoints()
        fs:SetPoint("CENTER", win, "TOPLEFT", cx + mid, cy + mid * TOTAL_RISE)
        fs:Show()
        x = x + widths[i]
    end
end

-- A fresh catch is written in: the icon is stamped down, then the name, the
-- count and the note appear left to right with the quest log's quill sound
-- (the same text fade the quest log uses). More of something just pops its count.
local ICON = ICON_SIZE
local CPS, SOFT = 40, 6 -- letters per second, and how soft the writing edge is
local function Ease(t) t = math.min(math.max(t, 0), 1); return 1 - (1 - t) * (1 - t) end
local function Reveal(fs, done) -- done: letters written so far (nil = all)
    if not fs.SetAlphaGradient then return true end
    return not fs:SetAlphaGradient(done or 1024, SOFT)
end
local function StopAnim(row)
    row.animating = nil
    row:SetScript("OnUpdate", nil)
    row.icon:SetSize(ICON * K, ICON * K)
    row.icon:SetAlpha(1)
    for _, fs in ipairs({ row.name, row.count, row.note }) do fs:SetAlpha(1); Reveal(fs) end
    row.newTag:SetAlpha(1)
    row.newTag:SetSize(80 * K, 40 * K)
    SetFont(row.count, 19)
end
local function Animate(row, kind, e)
    StopAnim(row)
    row.animating, row.glinted = e, nil
    local t = 0
    if kind == "bump" then
        row:SetScript("OnUpdate", function(self, el)
            t = t + el
            local k = t < 0.12 and t / 0.12 or math.max(0, 1 - (t - 0.12) / 0.2)
            SetFont(self.count, 19 + 9 * k)
            if t > 0.32 then StopAnim(self) end
        end)
        return
    end
    -- name, count and note are written one after another
    local parts, at = {}, 0.18
    for _, fs in ipairs({ row.name, row.count, row.note }) do
        local len = #(fs:GetText() or "")
        parts[#parts + 1] = { fs = fs, start = at }
        fs:SetAlpha(0)
        at = at + len / CPS + 0.05
    end
    local tagAt = at
    row.newTag:SetAlpha(0)
    local scratched = false
    row:SetScript("OnUpdate", function(self, el)
        t = t + el
        -- the stamp: big and faint, then down with a little bounce
        local s = t < 0.16 and (1.9 - 0.95 * Ease(t / 0.16)) or (0.95 + 0.05 * Ease((t - 0.16) / 0.08))
        self.icon:SetSize(ICON * K * s, ICON * K * s)
        self.icon:SetAlpha(math.min(1, t / 0.12))
        for _, p in ipairs(parts) do
            if t >= p.start then
                if not scratched then
                    scratched = true
                    ns.WriteSound()
                end
                p.fs:SetAlpha(1)
                Reveal(p.fs, (t - p.start) * CPS)
            end
        end
        if t >= tagAt then
            if not self.glinted then self.glinted = true; if ns.Glint then ns.Glint(self.newTag, 4, 1.2) end end
            local k = Ease((t - tagAt) / 0.2)
            self.newTag:SetAlpha(k)
            self.newTag:SetSize(80 * K * (1.4 - 0.4 * k), 40 * K * (1.4 - 0.4 * k))
        end
        if t > tagAt + 0.25 then StopAnim(self) end
    end)
end

function Log:Refresh()
    if not win then return end
    local n = #session.order
    local most = math.max(0, n - #ROWS)
    top = math.min(math.max(top, 0), most)
    for i, row in ipairs(rows) do
        local e = session.items[session.order[top + i]]
        if e then
            local r = RARITY[e.quality or 1] or RARITY[1]
            row.count:SetText(e.count)
            row.icon:SetTexture(e.icon or 134400)
            row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            SetFont(row.name, 16)
            Fit(row.name, ns.FishName(e.name), 16, NAME_W * K)
            row.name:SetTextColor(r[1], r[2], r[3])
            row.newTag:SetShown(e.new and true or false) -- a first-ever catch
            SetFont(row.note, 16)
            Fit(row.note, e.note, 16, (COL_NOTE[2] - COL_NOTE[1] - 52) * K)
            row.note:SetTextColor(r[1], r[2], r[3])
            row.id = e.id
            row.key = session.order[top + i]
            row:Show()
            -- another redraw while a row is still being written leaves it writing
            -- (it used to cut it short, quill sound and all)
            if e.anim and win:IsShown() then Animate(row, e.anim, e)
            elseif row.animating ~= e then StopAnim(row) end
            e.anim = nil
        else
            row.id = nil
            StopAnim(row)
            row:Hide()
        end
    end
    Log.DrawTotal(("Total: %d fish"):format(session.total))
    -- the scrollbar: only when there's more than fits
    scroll:SetShown(most > 0)
    if most > 0 then
        scroll.up.off = top == 0 or nil; scroll.up:Paint()
        scroll.down.off = top == most or nil; scroll.down:Paint()
        local th = scroll.thumb
        local y = THUMB[2] + (THUMB[3] - THUMB[2] - THUMB[5]) * top / most
        th:ClearAllPoints()
        th:SetPoint("TOP", win, "TOPLEFT", P(THUMB[1], y))
    end
end

-- step: rows to move (the wheel and the arrows)
function Log.Scroll(step)
    local most = math.max(0, #session.order - #ROWS)
    local want = math.min(math.max(top + step, 0), most)
    if want == top then return end
    top = want
    Log:Refresh()
end
function Log.Top() return top end

-- Flair's luck icon goes in the framed box; the box only shows while there's luck
function Log.LuckSlot(b, on)
    if not win then return end
    buff:SetShown(on and true or false)
    b:SetParent(win)
    b:SetFrameLevel(buff:GetFrameLevel() + 1)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", win, "TOPLEFT", P(BUFF_ICON[1], BUFF_ICON[2]))
    b:SetPoint("BOTTOMRIGHT", win, "TOPLEFT", P(BUFF_ICON[3], BUFF_ICON[4]))
    return true
end

-- a note this session hasn't used yet; repeats only once the pool runs out
function Log.PickNote(quality)
    local pool = Log.NOTES[quality or 1] or Log.NOTES[1]
    local used, fresh = {}, {}
    for _, e in pairs(session.items) do used[e.note] = true end
    for _, n in ipairs(pool) do if not used[n] then fresh[#fresh + 1] = n end end
    local from = #fresh > 0 and fresh or pool
    return from[math.random(#from)]
end

-- items from Splash.ReadLoot; once per cast
-- fresh: { [id] = true } for first-ever catches (from the journal)
function Log:Add(items, fresh)
    local cast = ns.castStart or GetTime()
    if lastCast == cast then return end
    lastCast = cast
    local added = false
    for _, it in ipairs(items or {}) do
        if not it.coin and it.name then
            local key = it.id or it.name
            local e = session.items[key]
            if not e then
                e = { id = it.id, name = it.name, icon = it.icon, quality = it.quality, count = 0,
                    note = Log.PickNote(it.quality), new = fresh and it.id and fresh[it.id] or nil }
                session.items[key] = e
                session.order[#session.order + 1] = key
                e.anim = "new"
            else
                e.anim = e.anim or "bump"
            end
            local n = math.max(1, it.count or 1)
            e.count = e.count + n
            session.total = session.total + n
            added = true
        end
    end
    if not added then return end
    -- Shiny Fishbones get their own line; they don't count as fish
    local bones = ns.Flair and ns.Flair.ThisCast()
    if bones then
        local e = session.items.bones
        if not e then
            e = { name = "Shiny Fishbones", icon = ns.Flair.ICON_GAME, quality = 6, count = 0, bones = true,
                note = Log.BONES_NOTES[math.random(#Log.BONES_NOTES)] }
            session.items.bones = e
            session.order[#session.order + 1] = "bones"
            e.anim = "new"
        else
            e.anim = e.anim or "bump"
        end
        e.count = e.count + bones
    end
    if ns.Journal then ns.Journal:NoteSession(session.total) end
    top = math.huge -- show the newest (Refresh scrolls to the end)
    self:Refresh()
end

function Log:Show()
    if not ns.db.logEnabled then return end
    if not win then Build() end
    Place()
    LayoutTitle()
    self:Refresh()
    win:Show()
    if ns.Social then ns.Social:LogBoard() end -- your quarterboard hangs off the top
    if ns.Flair then ns.Safe(ns.Flair.LuckIcon) end -- and your Fishbone luck beside it
end

function Log:Hide() if win then win:Hide() end end
-- loud: you pressed something, so say why nothing opened
function Log:Toggle(loud)
    if win and win:IsShown() then win:Hide() return end
    if not ns.db.logEnabled then
        if loud then ns.Chat("the fishing log is turned off. Turn it on in the settings, on the Fishing log page.") end
        return
    end
    self:Show()
end

-- A per-character macro for an action bar (handy on a controller), made the
-- first time you pick it up; after that it's yours, icon and all.
-- Macros need the icon as a file number: a path makes a blank macro the game
-- won't let you pick up. Known numbers in case the lookup isn't there.
local ICON_IDS = { INV_Misc_Note_01 = 134939, INV_Misc_Book_11 = 133743 }
local function IconID(path)
    if type(path) == "number" then return path end
    local id = GetFileIDFromPath and ns.Safe(GetFileIDFromPath, path)
    if type(id) == "number" and id > 0 then return id end
    return ICON_IDS[(path:match("([^\\]+)$"))] or 134400
end

-- the quest text's own writing sound (the game calls it WRITE_QUEST)
function ns.WriteSound()
    local kit = SOUNDKIT and (SOUNDKIT.WRITE_QUEST or SOUNDKIT.IG_WRITE_QUEST)
    if kit then pcall(PlaySound, kit, "Master") end
end

function ns.PickupMacro(name, icon, body, what)
    if InCombatLockdown() then return end
    icon = IconID(icon)
    local function Grab(i)
        local ok, err = pcall(PickupMacro, i)
        -- nothing on the cursor means the game said no; say why instead of failing quietly
        local held = GetCursorInfo and GetCursorInfo()
        if not ok or (GetCursorInfo and held ~= "macro") then
            ns.Chat("couldn't pick up the " .. what .. " macro" .. (ok and "" or (" (" .. tostring(err) .. ")"))
                .. ". It's in /macro under your character's macros too.")
        end
    end
    local function Later(i)
        C_Timer.After(0.1, function()
            local j = ns.Safe(GetMacroIndexByName, name)
            Grab((j and j > 0) and j or i)
        end)
    end
    local i = ns.Safe(GetMacroIndexByName, name)
    if i and i > 0 then
        -- an older one of ours with a blank icon: give it its icon back first
        local _, has = ns.Safe(GetMacroInfo, i)
        if has ~= icon then
            ns.Safe(EditMacro, i, name, icon, body)
            return Later(i)
        end
        return Grab(i)
    end
    local ok, made = pcall(CreateMacro, name, icon, body, true) -- per character
    if not ok or not made then
        ns.Chat("couldn't make the " .. what .. " macro (" .. tostring(made or "your character macros may be full") .. ").")
        return
    end
    -- a brand-new macro isn't ready to pick up until the game has saved it
    Later(made)
end

Log.MACRO_ICON = "Interface\\Icons\\INV_Misc_Note_01"
function Log:PickupMacro() ns.PickupMacro("Ducky Log", Log.MACRO_ICON, "/ducky log", "log") end

-- An on-screen launcher button: drag it anywhere, right-click to lock it. Off by default.
-- Used for the log and the journal. o = { name, art, title, show, locked, size, pos (db keys),
-- point = { default SetPoint args }, enabled = fn, toggle = fn }
function ns.Launcher(o)
    local L, button = {}, nil
    local function Place()
        button:ClearAllPoints()
        local pos = ns.db[o.pos]
        if pos then button:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
        else button:SetPoint(unpack(o.point)) end
    end
    local function Build()
        button = CreateFrame("Button", o.name, UIParent)
        button:SetFrameStrata("MEDIUM")
        button:SetClampedToScreen(true)
        button:SetMovable(true)
        button:RegisterForDrag("LeftButton")
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        local tex = button:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(o.art)
        local hl = button:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetTexture(o.art); hl:SetBlendMode("ADD"); hl:SetAlpha(0.3)
        -- a little press, like an action button
        button:SetScript("OnMouseDown", function() tex:SetPoint("TOPLEFT", 1, -1); tex:SetPoint("BOTTOMRIGHT", 1, -1) end)
        button:SetScript("OnMouseUp", function() tex:SetAllPoints() end)
        button:SetScript("OnDragStart", function(self)
            if not ns.db[o.locked] then self:StartMoving() end
        end)
        button:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local point, _, rel, x, y = self:GetPoint()
            ns.db[o.pos] = { point, rel, x, y }
        end)
        local function Tip(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(o.title)
            GameTooltip:AddLine("Click to open or close.", 1, 1, 1)
            if ns.db[o.locked] then
                GameTooltip:AddLine("Locked. Right-click to unlock.", 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine("Drag to move. Right-click to lock.", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        end
        button:SetScript("OnClick", function(self, mouse)
            if mouse == "RightButton" then
                ns.db[o.locked] = not ns.db[o.locked]
                if GameTooltip:IsOwned(self) then Tip(self) end
            else
                o.toggle()
            end
        end)
        button:SetScript("OnEnter", Tip)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
        Place()
    end
    function L:Apply()
        if not ns.db then return end
        local want = ns.db[o.show] and o.enabled()
        if want and not button then Build() end
        if button then
            button:SetSize(ns.db[o.size] or 40, ns.db[o.size] or 40)
            if want then button:Show() else button:Hide() end
        end
    end
    function L:Reset()
        ns.db[o.pos] = nil
        if button then Place() end
    end
    return L
end

local logButton = ns.Launcher{ name = "RubberDuckyLogButton", art = ns.MEDIA .. "Log\\button", title = "Fishing log",
    show = "logButton", locked = "logButtonLocked", size = "logButtonSize", pos = "logButtonPos",
    point = { "LEFT", UIParent, "LEFT", 30, 280 },
    enabled = function() return ns.db.logEnabled end, toggle = function() Log:Toggle(true) end }
function Log:ApplyButton() logButton:Apply() end
function Log:ResetButton() logButton:Reset() end

-- Opens when a fishing pole goes on (if that's switched on), and always goes
-- away when the pole comes off. The X closes it until the pole next goes on.
local hadPole
local function PoleCheck()
    if not ns.db or not ns.Gear then return end
    local pole = ns.Gear.PoleEquipped() and true or false
    if pole == hadPole then return end
    hadPole = pole
    quiet = true
    if pole then
        if ns.db.logEnabled and ns.db.logAutoOpen then Log:Show() end
    else
        Log:Hide()
    end
    quiet = false
end
Log.PoleCheck = PoleCheck

local watch = CreateFrame("Frame")
watch:RegisterEvent("PLAYER_LOGIN")
watch:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
watch:SetScript("OnEvent", function(_, event, slot)
    if event == "PLAYER_EQUIPMENT_CHANGED" and slot ~= 16 then return end
    if event == "PLAYER_LOGIN" then Log:ApplyButton() end
    C_Timer.After(event == "PLAYER_LOGIN" and 1 or 0.2, PoleCheck) -- let the swap finish
end)

function Log:ResetPosition()
    ns.db.logPos = nil
    if win then Place() end
end

function Log:NewSession()
    wipe(session.order); wipe(session.items); session.total = 0
    top, lastCast = 0, nil
    self:Refresh()
end

-- settings changed (on/off, size, button)
function Log:Apply()
    self:ApplyButton()
    if not ns.db.logEnabled then self:Hide() return end
    if win and win:IsShown() then Place() end
end
