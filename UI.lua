-- Rubber Ducky: settings page kit, drawn inside Blizzard's settings window.
--
--   local page = UI.NewPage{ title, subtitle, icon, toggleKey, onToggle }
--   local card = page:Card("While your line is out")
--   card:Toggle{ label, key, onChange }
--   card:Slider{ label, key, min, max, step, format, onChange }
--   card:Choice{ label, options = {{value, text}...}, key | get/set, onChange, tall }
--   card:Buttons{ {text, onClick}, ... }
--   card:Text("...")
--   page:Expander("Fine-tune position", card)   -- card shown on demand
--   page:Tool("Reset position", fn)             -- small buttons, top right
--   page:ResetTool{ apply, extra, positions }   -- reset icon: settings / positions menu
--
-- Changes run a frame later (UI.Later), outside Blizzard's code, to avoid taint.

local _, ns = ...
local UI = {}
ns.UI = UI

local GOLD = { 1, 0.82, 0 }
local PAD = 26 -- inside the cards' gold corners
local LABEL_W = 180 -- label column for sliders and choices

function UI.Later(fn) C_Timer.After(0, fn) end

-- The windows' sounds, on the Master channel so the fishing boost on effects
-- doesn't make them loud. One place to change them all.
-- The same sounds Blizzard's own windows make, so ours feel like part of the game:
-- the game menu's open and close for settings, a character-panel open and close
-- for the welcome, the settings panel's tab click for pages, and its checkbox
-- clicks for toggles and choices. Each kit has its ID too, in case the name is missing.
UI.SOUNDS = {
    settingsOpen = "IG_MAINMENU_OPEN", settingsClose = "IG_MAINMENU_CLOSE",
    welcomeOpen = "IG_CHARACTER_INFO_OPEN", welcomeClose = "IG_CHARACTER_INFO_CLOSE",
    page = "IG_CHARACTER_INFO_TAB",
    button = "IG_MAINMENU_OPTION",
    on = "IG_MAINMENU_OPTION_CHECKBOX_ON", off = "IG_MAINMENU_OPTION_CHECKBOX_OFF",
    challenge = "UI_EPICLOOT_TOAST", -- a loot toast, not the achievement sound
    tick = "U_CHAT_SCROLL_BUTTON",    -- the controller moving between things
    challengesOpen = "IG_QUEST_LOG_OPEN", challengesClose = "IG_QUEST_LOG_CLOSE",
    -- Mrrl's: the game's own in-game shop, and a murloc
    shopOpen = "UI_IG_STORE_WINDOW_OPEN_BUTTON", shopClose = "UI_IG_STORE_WINDOW_CLOSE_BUTTON",
    shopPage = "UI_IG_STORE_PAGE_NAV_BUTTON", shopBuy = "UI_IG_STORE_BUY_BUTTON",
    shopBought = "UI_IG_STORE_CONFIRM_PURCHASE_BUTTON", murloc = "MURLOC_AGGRO",
}
local KIT_IDS = {
    IG_MAINMENU_OPEN = 850, IG_MAINMENU_CLOSE = 851, IG_MAINMENU_OPTION = 852,
    IG_CHARACTER_INFO_OPEN = 839, IG_CHARACTER_INFO_CLOSE = 840, IG_CHARACTER_INFO_TAB = 841,
    IG_MAINMENU_OPTION_CHECKBOX_ON = 856, IG_MAINMENU_OPTION_CHECKBOX_OFF = 857,
    IG_QUEST_LOG_OPEN = 844, IG_QUEST_LOG_CLOSE = 845, UI_EPICLOOT_TOAST = 31578,
    U_CHAT_SCROLL_BUTTON = 1115,
    UI_IG_STORE_WINDOW_OPEN_BUTTON = 39512, UI_IG_STORE_WINDOW_CLOSE_BUTTON = 39513,
    UI_IG_STORE_PAGE_NAV_BUTTON = 39511, UI_IG_STORE_BUY_BUTTON = 39515,
    UI_IG_STORE_CONFIRM_PURCHASE_BUTTON = 39516, MURLOC_AGGRO = 416,
}
function UI.Sound(what)
    local name = UI.SOUNDS[what] or what
    local kit = SOUNDKIT and SOUNDKIT[name] or KIT_IDS[name]
    if kit then pcall(PlaySound, kit, "Master") end
end
-- a checkbox's click, by which way it went
function UI.Click(on) UI.Sound(on and "on" or "off") end

-------------------------------------------------------------------------------
-- Art: Kelly's wood, gold, navy and parchment pieces (Media\UI). Each piece
-- stretches only along its plain stretches (xb across, yb down), so leaves,
-- gems, splashes and shells keep their shape at any size. Sizes are in the
-- art's own pixels: aw x ah of a w x h texture.
-------------------------------------------------------------------------------

local ART_DIR = ns.MEDIA .. "UI\\"
UI.ART = {
    frame = { w = 1024, h = 512, aw = 615, ah = 406, xb = { { 185, 500 } }, yb = { { 200, 255 } }, close = { 566, 41, 29 } },
    sign_welcome = { w = 1024, h = 256, aw = 1024, ah = 250 },
    sign_challenges = { w = 1024, h = 256, aw = 1024, ah = 254 },
    sign_settings = { w = 1024, h = 256, aw = 1024, ah = 232 },
    strip_navy = { w = 512, h = 128, aw = 512, ah = 103, xb = { { 119.8, 399.2 } } },
    strip_parch = { w = 512, h = 128, aw = 512, ah = 99, xb = { { 115.5, 385 } } },
    tile_navy = { w = 256, h = 256, aw = 154, ah = 153, xb = { { 45, 110 } }, yb = { { 45, 105 } } },
    tile_parch = { w = 256, h = 256, aw = 154, ah = 150, xb = { { 45, 110 } }, yb = { { 45, 105 } } },
    button = { w = 512, h = 128, aw = 279, ah = 107, xb = { { 90, 190 } } },
    button_grey = { w = 512, h = 128, aw = 286, ah = 104, xb = { { 90, 190 } } },
    slider = { w = 1024, h = 128, aw = 528, ah = 93, xb = { { 150, 420 } }, inside = { 62, 35, 470, 62 } },
    slider_fill = { w = 256, h = 32, aw = 178, ah = 27, xb = { { 16, 160 } } },
    gems = { w = 512, h = 64, aw = 320, ah = 64 },
    medals = { w = 1024, h = 256, aw = 1024, ah = 256 },
    plate = { w = 1024, h = 256, aw = 1002, ah = 193, xb = { { 350, 820 } }, ring = { 135, 95, 175 }, body = { 300, 58, 850, 150 } },
    plate_locked = { w = 1024, h = 256, aw = 1002, ah = 214, xb = { { 350, 820 } }, ring = { 135, 105, 190 }, body = { 300, 62, 880, 160 } },
    plate_bar = { w = 1024, h = 256, aw = 1024, ah = 236, xb = { { 377.7, 797.4 } }, ring = { 146.9, 117.5, 218.2 }, body = { 293.8, 62.1, 864.5, 137.7 }, bar = { 329, 147.7, 831, 171.2 } },
}
local ART = UI.ART

-- the pieces of one axis: { from, to, stretches }
local function Cuts(size, bands)
    local c, x = {}, 0
    for _, b in ipairs(bands or {}) do
        c[#c + 1] = { x, b[1], false }; c[#c + 1] = { b[1], b[2], true }; x = b[2]
    end
    c[#c + 1] = { x, size, false }
    return c
end
-- how long each piece is drawn: ends at scale s, the stretches share the rest.
-- Too short for the ends, and it all squeezes evenly.
local function Spread(cuts, size, target, s)
    local fixed, stretch = 0, 0
    for _, c in ipairs(cuts) do
        if c[3] then stretch = stretch + (c[2] - c[1]) else fixed = fixed + (c[2] - c[1]) end
    end
    local out = {}
    if stretch == 0 or target < fixed * s then
        local k = target / (size * s)
        for i, c in ipairs(cuts) do out[i] = (c[2] - c[1]) * s * k end
    else
        local extra = target - fixed * s
        for i, c in ipairs(cuts) do out[i] = c[3] and (c[2] - c[1]) / stretch * extra or (c[2] - c[1]) * s end
    end
    return out
end
UI.Spread, UI.Cuts = Spread, Cuts

-- Dress a frame in a piece of art, filling it. s: the art's scale; left out,
-- a piece that only stretches across takes the frame's height to set it.
-- Returns the piece: :Layout() after resizing by hand, :X(ax) / :Y(ay) to find
-- a point on the art within the frame, :SetArt(name) to swap to a look-alike.
function UI.Stretch(frame, name, layer, s, level)
    local p = { frame = frame, name = name, s = s, tex = {} }
    function p:Layout()
        local a = ART[self.name]
        local W, H = frame:GetSize()
        if not W or W <= 0 or not H or H <= 0 then return end
        local sx = self.s or H / a.ah
        local cols, rows = Cuts(a.aw, a.xb), Cuts(a.ah, a.yb)
        local ws = Spread(cols, a.aw, W, sx)
        local hs = a.yb and Spread(rows, a.ah, H, sx) or { H }
        local i, y = 0, 0
        self.cols, self.ws, self.rows, self.hs = cols, ws, rows, hs
        for r, row in ipairs(rows) do
            local x = 0
            for c, col in ipairs(cols) do
                i = i + 1
                local t = self.tex[i]
                if not t then
                    t = frame:CreateTexture(nil, layer or "BACKGROUND", nil, level)
                    self.tex[i] = t
                end
                t:SetTexture(ART_DIR .. self.name)
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
                t:SetSize(math.max(0.01, ws[c]), math.max(0.01, hs[r]))
                t:SetTexCoord(col[1] / a.w, col[2] / a.w, row[1] / a.h, row[2] / a.h)
                t:SetShown(ws[c] > 0.05 and hs[r] > 0.05)
                x = x + ws[c]
            end
            y = y + hs[r]
        end
        for k = i + 1, #self.tex do self.tex[k]:Hide() end
    end
    -- where a point on the art lands, from the frame's top left
    local function Map(cuts, sizes, v)
        if not cuts then return 0 end
        local at = 0
        for i, c in ipairs(cuts) do
            if v <= c[2] or i == #cuts then return at + (v - c[1]) / math.max(0.001, c[2] - c[1]) * sizes[i] end
            at = at + sizes[i]
        end
        return at
    end
    function p:X(ax) return Map(self.cols, self.ws, ax) end
    function p:Y(ay) return Map(self.rows, self.hs, ay) end
    function p:SetArt(n) self.name = n; self:Layout() end
    function p:SetAlpha(v) for _, t in ipairs(self.tex) do t:SetAlpha(v) end end
    function p:SetVertexColor(...) for _, t in ipairs(self.tex) do t:SetVertexColor(...) end end
    -- lay out again whenever the frame changes size (on a watcher, so the frame's own scripts stay free)
    local watch = CreateFrame("Frame", nil, frame)
    watch:SetAllPoints()
    watch:SetScript("OnSizeChanged", function() p:Layout() end)
    p:Layout()
    return p
end

-- one of the gems (blue, green, purple, orange, grey) or medallions (open, locked, hidden, done)
local GEMS = { blue = 0, green = 1, purple = 2, orange = 3, grey = 4 }
function UI.Gem(t, which)
    local i = GEMS[which] or 0
    t:SetTexture(ART_DIR .. "gems")
    t:SetTexCoord(i * 64 / 512, (i + 1) * 64 / 512, 0, 1)
end
local MEDALS = { open = 0, locked = 1, hidden = 2, done = 3 }
UI.MEDAL_RING = 185 / 256 -- the ring's share of a medallion's square
function UI.Medal(t, which)
    local i = MEDALS[which] or 0
    t:SetTexture(ART_DIR .. "medals")
    t:SetTexCoord(i * 0.25, (i + 1) * 0.25, 0, 1)
end

-- Text on parchment is inked, not gold and white
local INK = { 0.29, 0.17, 0.08 }
local INK_SOFT = { 0.42, 0.28, 0.15 }
UI.INK, UI.INK_SOFT = INK, INK_SOFT
UI.FONT = { ink = "GameFontHighlight", small = "GameFontHighlightSmall", bold = "GameFontNormal",
    large = "GameFontNormalLarge", soft = "GameFontHighlightSmall" }
if CreateFont then
    for name, base in pairs({ RubberDuckyInk = "GameFontHighlight", RubberDuckyInkSmall = "GameFontHighlightSmall",
        RubberDuckyInkBold = "GameFontNormal", RubberDuckyInkLarge = "GameFontNormalLarge",
        RubberDuckyInkSoft = "GameFontHighlightSmall" }) do
        local f = CreateFont(name)
        if f and f.CopyFontObject and _G[base] then
            f:CopyFontObject(_G[base])
            local c = name == "RubberDuckyInkSoft" and INK_SOFT or INK
            f:SetTextColor(c[1], c[2], c[3])
            -- bold, the journal's way: the text drawn twice, a pixel apart
            if name == "RubberDuckyInkBold" or name == "RubberDuckyInkLarge" then
                f:SetShadowColor(c[1], c[2], c[3], 1); f:SetShadowOffset(1, 0)
            else
                f:SetShadowColor(0, 0, 0, 0)
            end
        end
    end
    UI.FONT = { ink = "RubberDuckyInk", small = "RubberDuckyInkSmall", bold = "RubberDuckyInkBold",
        large = "RubberDuckyInkLarge", soft = "RubberDuckyInkSoft" }
end
local FONT = UI.FONT

-- A parchment button: the little leafy plate. grey = the dark one.
function UI.Button(parent, text, width, onClick, o)
    o = o or {}
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, o.height or 40)
    b.art = UI.Stretch(b, o.grey and "button_grey" or "button", "BACKGROUND")
    local fs = b:CreateFontString(nil, "OVERLAY", o.font or (o.grey and "GameFontHighlight" or FONT.bold))
    fs:SetPoint("CENTER", 4, 1)
    fs:SetText(text)
    b.text = fs
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", width > 60 and 18 or 6, -7); hl:SetPoint("BOTTOMRIGHT", -12, 7)
    hl:SetColorTexture(1, 1, 1, 0.12)
    b:SetScript("OnClick", function() UI.Sound("button"); UI.Later(onClick) end)
    b:SetScript("OnMouseDown", function() fs:SetPoint("CENTER", 5, 0) end)
    b:SetScript("OnMouseUp", function() fs:SetPoint("CENTER", 4, 1) end)
    return b
end
UI.PillButton = function(parent, text, width, onClick, font) return UI.Button(parent, text, width, onClick, { font = font }) end

-- An icon in a small gold-cornered navy tile
function UI.IconTile(parent, size, icon, crop)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    local s = size / 154
    UI.Stretch(f, "tile_navy", "BACKGROUND", s)
    local t = f:CreateTexture(nil, "ARTWORK")
    -- the tile's opening: 25 in from the left, 23 from the right, 24 top and bottom
    t:SetPoint("TOPLEFT", 26 * s, -25 * s); t:SetPoint("BOTTOMRIGHT", -24 * s, 25 * s)
    t:SetTexture(icon)
    if crop ~= false then t:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    f.icon = t
    return f
end

local NAVY = { 27 / 255, 33 / 255, 52 / 255 }
UI.NAVY = NAVY

-------------------------------------------------------------------------------
-- Card
-------------------------------------------------------------------------------

local Card = {}
Card.__index = Card

local CARD_TOP = 28 -- below the parchment's top edge
local CARD_SCALE = 0.75
local function NewCard(page, title, plain)
    local f = CreateFrame("Frame", nil, page.content, "BackdropTemplate")
    local top = -PAD + 4
    if not plain then
        -- a sheet of parchment in gold corners; everything on it is inked
        UI.Stretch(f, "tile_parch", "BACKGROUND", CARD_SCALE)
        f.minHeight = 110 * CARD_SCALE
        top = -CARD_TOP
    end
    local c = setmetatable({ frame = f, page = page, y = top, rows = {}, controls = page.controls, ink = not plain }, Card)
    if title then
        local t = f:CreateFontString(nil, "OVERLAY", plain and "GameFontNormal" or FONT.large)
        t:SetPoint("TOPLEFT", PAD, c.y)
        t:SetText(title)
        c.y = c.y - 28
    end
    f:SetScript("OnSizeChanged", function(_, w)
        for _, row in ipairs(c.rows) do if row.Relayout then row:Relayout(w) end end
    end)
    return c
end

function Card:Height()
    return math.max(-self.y + 8 + (self.frame.minHeight and 8 or 0), self.frame.minHeight or 0)
end

function Card:Advance(h) local y = self.y; self.y = self.y - h; return y end

-- the font for this card: inked on parchment, the game's own on plain cards
function Card:Font(kind)
    if self.ink then return FONT[kind] end
    return ({ ink = "GameFontHighlight", small = "GameFontHighlightSmall", bold = "GameFontNormal",
        large = "GameFontNormalLarge", soft = "GameFontDisableSmall" })[kind]
end

function Card:Text(text, small)
    local fs = self.frame:CreateFontString(nil, "OVERLAY", self:Font(small and "soft" or "small"))
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    local y = self.y
    fs:SetPoint("TOPLEFT", PAD, y)
    local row = { fs = fs }
    local card, line = self, small and 18 or 20
    -- a long line wraps once the card has a width: then it takes the room it
    -- needs, and everything below it on the card moves down to match
    local grown = 0
    function row:Relayout(w)
        fs:SetWidth(w - PAD * 2)
        local h = fs:GetStringHeight()
        if not h or h <= 0 then return end
        local want = math.max(0, math.ceil(h) + (line - 14) - line)
        local d = want - grown
        if math.abs(d) < 1 then return end
        grown = want
        card:Shift(y, d)
    end
    self.rows[#self.rows + 1] = row
    self:Advance(line)
    return fs
end

-- move everything placed below y on this card down by d, and grow the card
function Card:Shift(y, d)
    local f = self.frame
    local function Move(r)
        if r.GetNumPoints and r:GetNumPoints() > 0 then
            local pts, moved = {}, false
            for i = 1, r:GetNumPoints() do
                local p, rel, rp, x, py = r:GetPoint(i)
                if rel == f and py and py < y - 1 then py = py - d; moved = true end
                pts[i] = { p, rel, rp, x, py }
            end
            if moved then
                r:ClearAllPoints()
                for _, q in ipairs(pts) do r:SetPoint(q[1], q[2], q[3], q[4], q[5]) end
            end
        end
    end
    for _, r in ipairs({ f:GetRegions() }) do Move(r) end
    for _, r in ipairs({ f:GetChildren() }) do Move(r) end
    self.y = self.y - d
    -- the page lays its cards out again, once things have settled
    if self.page and self.page.Layout and not self.page.relayoutSoon then
        self.page.relayoutSoon = true
        C_Timer.After(0, function() self.page.relayoutSoon = nil; self.page:Layout() end)
    end
end

-- remember which settings a page shows, for its Defaults button
local function Track(card, o) if o.key then card.page.keys[o.key] = true end end

function Card:Toggle(o)
    Track(self, o)
    -- column = 2: beside the toggle before it, at colX
    local y
    if o.column == 2 and self.lastToggleY then y = self.lastToggleY
    else y = self:Advance(o.desc and 40 or 28) end
    self.lastToggleY = y
    local cb = CreateFrame("CheckButton", nil, self.frame, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", o.column == 2 and (o.colX or 180) or PAD - 4, y + 2)
    local label = self.frame:CreateFontString(nil, "OVERLAY", self:Font("ink"))
    label:SetPoint("LEFT", cb, "RIGHT", 4, o.desc and 7 or 0)
    label:SetText(o.label)
    if o.desc then
        local d = self.frame:CreateFontString(nil, "OVERLAY", self:Font("soft"))
        d:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -3)
        d:SetPoint("RIGHT", self.frame, "RIGHT", -PAD, 0) -- one line, truncated
        d:SetJustifyH("LEFT")
        d:SetWordWrap(false)
        d:SetText(o.desc)
    end
    cb:SetScript("OnClick", function(self)
        local on = self:GetChecked() and true or false
        UI.Click(on)
        if o.set then o.set(on) else ns.db[o.key] = on end
        if o.onChange then UI.Later(function() o.onChange(on) end) end
        UI.Later(function() if self.page then self.page:Refresh() end end)
    end)
    cb.page = self.page
    local ctl = { Refresh = function() cb:SetChecked(o.get and o.get() or ns.db[o.key] and true or false) end }
    self.controls[#self.controls + 1] = ctl
    return cb
end

local function Round(v, step)
    return math.floor(v / step + 0.5) * step
end

function Card:Slider(o)
    Track(self, o)
    local y = self:Advance(36)
    local label = self.frame:CreateFontString(nil, "OVERLAY", self:Font("ink"))
    label:SetPoint("TOPLEFT", PAD, y - 8)
    label:SetWidth(LABEL_W - 10); label:SetJustifyH("LEFT"); label:SetWordWrap(false)
    label:SetText(o.label)

    -- the wooden bar with its blue fill, and a gem to drag
    local s = CreateFrame("Slider", nil, self.frame)
    s:SetOrientation("HORIZONTAL")
    s:SetHeight(26)
    local track = UI.Stretch(s, "slider", "BACKGROUND")
    local fill = s:CreateTexture(nil, "BORDER")
    fill:SetTexture(ART_DIR .. "slider_fill")
    local thumb = s:CreateTexture(nil, "OVERLAY")
    UI.Gem(thumb, "blue")
    thumb:SetSize(20, 20)
    s:SetThumbTexture(thumb)
    s.padAdjust = true -- the controller's left and right move it
    s:SetMinMaxValues(o.min, o.max)
    s:SetValueStep(o.step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:SetPoint("TOPLEFT", LABEL_W, y - 3)
    s:EnableMouseWheel(true)
    -- the blue runs from the bar's left end to the gem
    local function Fill(v)
        local A = ART.slider
        local x0, x1 = track:X(A.inside[1]), track:X(A.inside[3])
        local y0, y1 = track:Y(A.inside[2]), track:Y(A.inside[4])
        local k = (o.max > o.min) and (v - o.min) / (o.max - o.min) or 0
        k = math.max(0, math.min(1, k))
        fill:ClearAllPoints()
        fill:SetPoint("TOPLEFT", s, "TOPLEFT", x0, -y0)
        fill:SetSize(math.max(0.01, (x1 - x0) * k), math.max(1, y1 - y0))
        fill:SetTexCoord(0, ART.slider_fill.aw / 256 * math.max(0.15, k), 0, ART.slider_fill.ah / 32)
        fill:SetShown(k > 0.01)
    end

    local value = self.frame:CreateFontString(nil, "OVERLAY", self:Font("bold"))
    value:SetPoint("LEFT", s, "RIGHT", 10, 0)
    value:SetWidth(86); value:SetJustifyH("LEFT")

    local refreshing = false
    local function Show(v) value:SetText(o.format and o.format(v) or tostring(v)); Fill(v) end
    s:SetScript("OnValueChanged", function(_, v)
        v = Round(v, o.step)
        Show(v)
        if refreshing then return end
        ns.db[o.key] = v
        if o.onChange then UI.Later(function() o.onChange(v) end) end
    end)
    s:SetScript("OnMouseWheel", function(self, d)
        self:SetValue(math.max(o.min, math.min(o.max, self:GetValue() + d * o.step)))
    end)
    s:SetScript("OnMouseUp", function() UI.Later(function() self.page:Refresh() end) end)

    local row = {}
    function row:Relayout(w) s:SetWidth(math.max(80, w - LABEL_W - 110)); track:Layout(); Fill(s:GetValue() or o.min) end
    self.rows[#self.rows + 1] = row
    self.controls[#self.controls + 1] = { Refresh = function()
        refreshing = true
        local v = ns.db[o.key] or o.min
        s:SetValue(v); Show(v)
        refreshing = false
    end }
    return s
end

-- A row of buttons, one picked
function Card:Choice(o)
    Track(self, o)
    local h = o.tall and 58 or 34
    local y = self:Advance(h + 6)
    local x0 = PAD
    if o.label then
        local label = self.frame:CreateFontString(nil, "OVERLAY", self:Font("ink"))
        label:SetPoint("TOPLEFT", PAD, y - (h / 2) + 6)
        label:SetWidth((o.labelW or LABEL_W) - 10); label:SetJustifyH("LEFT")
        label:SetText(o.label)
        x0 = o.labelW or LABEL_W
    end
    local buttons = {}
    local function Current()
        if o.get then return o.get() end
        return ns.db[o.key]
    end
    local function Paint()
        local cur = Current()
        if type(o.options) == "function" then -- labels can change
            local fresh = o.options()
            for i, b in ipairs(buttons) do
                if fresh[i] then
                    b.text:SetText(fresh[i][2])
                    if b.subText then b.subText:SetText(fresh[i][3] or "") end
                end
            end
        end
        -- the one picked is parchment and inked; the rest navy
        for _, b in ipairs(buttons) do
            local on = (b.value == cur)
            b.art:SetArt(on and "tile_parch" or "tile_navy")
            if on then b.text:SetTextColor(INK[1], INK[2], INK[3]) else b.text:SetTextColor(0.92, 0.92, 0.92) end
            if b.subText then
                if on then b.subText:SetTextColor(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3]) else b.subText:SetTextColor(0.7, 0.7, 0.7) end
            end
        end
    end
    local options = type(o.options) == "function" and o.options() or o.options
    for i, opt in ipairs(options) do
        local b = CreateFrame("Button", nil, self.frame)
        b:SetHeight(h)
        b.art = UI.Stretch(b, "tile_navy", "BACKGROUND", 0.36)
        b.value = opt[1]
        b.text = b:CreateFontString(nil, "OVERLAY", o.tall and "GameFontHighlight" or "GameFontHighlightSmall")
        b.text:SetPoint("CENTER", 0, opt[3] and 8 or 0)
        b.text:SetText(opt[2])
        if opt[3] then
            b.subText = b:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            b.subText:SetPoint("TOP", b.text, "BOTTOM", 0, -3)
            b.subText:SetText(opt[3])
        end
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 8, -8); hl:SetPoint("BOTTOMRIGHT", -8, 8); hl:SetColorTexture(1, 1, 1, 0.08)
        b:SetScript("OnClick", function()
            UI.Sound("on")
            if o.set then o.set(b.value) else ns.db[o.key] = b.value end
            Paint()
            if o.onChange then UI.Later(function() o.onChange(b.value) end) end
            UI.Later(function() self.page:Refresh() end)
        end)
        buttons[i] = b
    end
    local row = {}
    function row:Relayout(w)
        local gap = 6
        local n = #buttons
        local bw = (w - x0 - PAD - gap * (n - 1)) / n
        if o.maxWidth then bw = math.min(bw, o.maxWidth) end
        for i, b in ipairs(buttons) do
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", x0 + (i - 1) * (bw + gap), y)
            b:SetWidth(bw)
            b.art:Layout()
        end
    end
    self.rows[#self.rows + 1] = row
    self.controls[#self.controls + 1] = { Refresh = Paint, buttons = buttons }
    return buttons
end

function Card:Buttons(list)
    self:Advance(6)
    local y = self:Advance(44)
    local x = PAD
    local made = {}
    for _, item in ipairs(list) do
        local b = UI.Button(self.frame, item[1], item.width or 150, item[2], { height = 34 })
        b:SetPoint("TOPLEFT", x - 6, y + 4)
        x = x + (item.width or 150) + 8
        made[#made + 1] = b
    end
    return made
end

-------------------------------------------------------------------------------
-- Page
-------------------------------------------------------------------------------

local Page = {}
Page.__index = Page

-- A slim gold scroll bar on a navy track, in place of the game's grey one, and
-- only while there's something to scroll. The game's bar keeps working out of
-- sight (the mouse wheel goes through it); ours just shows and drags it.
function UI.SlimScrollBar(scroll, parent)
    local bar = rawget(scroll, "ScrollBar") or scroll.ScrollBar
    if type(bar) ~= "table" then
        local name = scroll.GetName and scroll:GetName()
        bar = type(name) == "string" and _G[name .. "ScrollBar"] or nil
    end
    if type(bar) ~= "table" then bar = nil end
    if bar then
        bar:SetAlpha(0); bar:EnableMouse(false)
        for _, k in ipairs({ "ScrollUpButton", "ScrollDownButton" }) do
            if type(bar[k]) == "table" then bar[k]:EnableMouse(false) end
        end
    end
    local track = CreateFrame("Frame", nil, parent)
    track:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 5, -2)
    track:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 5, 2)
    track:SetWidth(6)
    local bg = track:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetColorTexture(NAVY[1], NAVY[2], NAVY[3], 0.9)
    local thumb = CreateFrame("Button", nil, track)
    thumb:SetWidth(6)
    local tt = thumb:CreateTexture(nil, "ARTWORK")
    tt:SetAllPoints(); tt:SetColorTexture(GOLD[1], GOLD[2] * 0.85, 0.15, 0.95)
    local function Range() return scroll:GetVerticalScrollRange() or 0 end
    local function Paint()
        local range = Range()
        track:SetShown(range > 1)
        if range <= 1 then return end
        local h = track:GetHeight() or 1
        local view = scroll:GetHeight() or 1
        local th = math.max(24, h * view / (view + range))
        thumb:SetHeight(th)
        local pos = (scroll:GetVerticalScroll() or 0) / range
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, -(h - th) * pos)
    end
    local function ScrollTo(v)
        v = math.max(0, math.min(Range(), v))
        if bar and bar.SetValue then bar:SetValue(v) else scroll:SetVerticalScroll(v) end
    end
    thumb:RegisterForDrag("LeftButton")
    thumb:SetScript("OnDragStart", function(self)
        local _, y = GetCursorPosition()
        self.from, self.start = y / (self:GetEffectiveScale() or 1), scroll:GetVerticalScroll() or 0
        self:SetScript("OnUpdate", function(me)
            local _, cy = GetCursorPosition()
            cy = cy / (me:GetEffectiveScale() or 1)
            local h, th = track:GetHeight() or 1, me:GetHeight() or 1
            local per = Range() / math.max(1, h - th)
            ScrollTo(me.start + (me.from - cy) * per)
        end)
    end)
    thumb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    scroll:HookScript("OnVerticalScroll", Paint)
    scroll:HookScript("OnScrollRangeChanged", Paint)
    scroll:HookScript("OnShow", Paint)
    track:Hide()
    return track
end

function UI.NewPage(o)
    local f = CreateFrame("Frame")
    f:Hide()
    -- called by the settings window on canvas pages
    f.OnCommit = function() end
    f.OnDefault = function() end
    f.OnRefresh = function() end

    -- the header stays put at the top; only the sections below it scroll
    -- a page heading: the page's icon in a tile, its name, what it's for, its
    -- on/off switch, and a thin gold line under it all
    local HEAD_H = 72
    local head = CreateFrame("Frame", nil, f)
    head:SetPoint("TOPLEFT", 4, -4)
    head:SetPoint("TOPRIGHT", -4, -4)
    head:SetHeight(HEAD_H)
    local rule = head:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(0.78, 0.63, 0.24, 0.55)
    rule:SetHeight(1)
    rule:SetPoint("BOTTOMLEFT", 0, 2); rule:SetPoint("BOTTOMRIGHT", 0, 2)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -(HEAD_H + 8))
    scroll:SetPoint("BOTTOMRIGHT", -16, 6)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(620, 400)
    scroll:SetScrollChild(content)
    scroll:SetScript("OnSizeChanged", function(_, w) content:SetWidth(w) end)
    UI.SlimScrollBar(scroll, f)

    local p = setmetatable({ frame = f, content = content, head = head, scroll = scroll, controls = {}, cards = {},
        refreshers = {}, keys = {}, tools = {}, toggleKey = o.toggleKey }, Page)

    local iconFrame = UI.IconTile(head, 56, o.icon, o.crop)
    iconFrame:SetPoint("LEFT", 0, 2)
    p.icon = iconFrame.icon

    local title = head:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 12, -4)
    title:SetText(o.title)
    local sub = head:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -5)
    sub:SetPoint("RIGHT", head, "RIGHT", -150, 0)
    sub:SetJustifyH("LEFT"); sub:SetWordWrap(false)
    sub:SetText(o.subtitle or "")
    p.subtitle = sub

    -- the page's on/off: a little plate with a lit (or dark) gem and the word
    if o.toggleKey then
        local sw = CreateFrame("CheckButton", nil, head)
        sw:SetSize(96, 38)
        sw:SetPoint("RIGHT", 0, 2)
        sw.art = UI.Stretch(sw, "button", "BACKGROUND")
        local gem = sw:CreateTexture(nil, "ARTWORK")
        gem:SetSize(18, 18); gem:SetPoint("LEFT", 24, 1)
        local l = sw:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("LEFT", gem, "RIGHT", 6, 0)
        local hl = sw:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 16, -7); hl:SetPoint("BOTTOMRIGHT", -10, 7); hl:SetColorTexture(1, 1, 1, 0.12)
        local function Paint(on)
            sw.art:SetArt(on and "button" or "button_grey")
            UI.Gem(gem, on and "green" or "grey")
            l:SetText(on and "On" or "Off")
            if on then l:SetTextColor(INK[1], INK[2], INK[3]) else l:SetTextColor(0.85, 0.85, 0.85) end
        end
        sw:SetScript("OnClick", function(self)
            local on = self:GetChecked() and true or false
            UI.Click(on)
            Paint(on)
            ns.db[o.toggleKey] = on
            if o.onToggle then UI.Later(function() o.onToggle(on) end) end
            UI.Later(function() p:Refresh() end)
        end)
        sw:SetScript("OnEnter", function()
            GameTooltip:SetOwner(sw, "ANCHOR_LEFT")
            GameTooltip:SetText(o.title); GameTooltip:AddLine("Turn this on or off.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
        p.toggleButton = sw
        p.controls[#p.controls + 1] = { Refresh = function()
            local on = ns.db[o.toggleKey] and true or false
            sw:SetChecked(on)
            Paint(on)
        end }
    end

    p.top = -4
    f:SetScript("OnShow", function() p:Refresh() end)
    return p
end

-- The same kit with no header or scrolling, laid out inside any frame (the
-- Welcome screen's two sections).
function UI.NewPanel(parent)
    local p = setmetatable({ frame = parent, content = parent, controls = {}, cards = {}, refreshers = {},
        keys = {}, tools = {} }, Page)
    p.top = 0
    return p
end

-- A big leafy pill button
function UI.PillButton(parent, text, width, onClick, font)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 40)
    UI.Skin(b, "pill", "BACKGROUND")
    local fs = b:CreateFontString(nil, "OVERLAY", font or "GameFontNormalLarge")
    fs:SetPoint("CENTER", 0, 1)
    fs:SetText(text)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 22, -8); hl:SetPoint("BOTTOMRIGHT", -22, 8)
    hl:SetColorTexture(1, 1, 1, 0.08)
    b:SetScript("OnClick", function() UI.Sound("button"); UI.Later(onClick) end)
    b:SetScript("OnMouseDown", function() fs:SetPoint("CENTER", 1, 0) end)
    b:SetScript("OnMouseUp", function() fs:SetPoint("CENTER", 0, 1) end)
    return b
end

-- top-right tools sit in a row level with the on/off switch, to its left
function Page:PlaceTool(b)
    local prev = self.tools[#self.tools]
    if prev then b:SetPoint("RIGHT", prev, "LEFT", -6, 0)
    elseif self.toggleButton then b:SetPoint("RIGHT", self.toggleButton, "LEFT", -8, 0)
    else b:SetPoint("RIGHT", self.head, "RIGHT", 0, 2) end
end

-- small buttons in the top right
function Page:Tool(text, fn, tip)
    local b = UI.Button(self.head, text, 96, function() end, { height = 34, font = FONT.bold })
    b:SetWidth(math.max(86, (b.text:GetStringWidth() or 40) + 44))
    b:SetScript("OnClick", nil)
    self:PlaceTool(b)
    if tip then
        b:SetScript("OnEnter", function()
            GameTooltip:SetOwner(b, "ANCHOR_BOTTOM")
            GameTooltip:SetText(tip[1]); GameTooltip:AddLine(tip[2], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    b:SetScript("OnClick", function() UI.Sound("button"); UI.Later(function() fn(b) end) end)
    self.tools[#self.tools + 1] = b
    return b
end

-- A little popup menu under a button. items: { text, onClick, confirm }.
-- confirm items ask "Sure?" first and stay open for the second click.
local popup
function UI.Popup(anchor, items)
    if not popup then
        popup = CreateFrame("Frame", "RubberDuckyPopup", UIParent)
        popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:SetToplevel(true)
        popup:EnableMouse(true)
        popup:SetClampedToScreen(true)
        popup.art = UI.Stretch(popup, "tile_navy", "BACKGROUND", 0.4)
        popup.rows = {}
        pcall(popup.RegisterEvent, popup, "GLOBAL_MOUSE_DOWN")
        popup:SetScript("OnEvent", function()
            if popup:IsShown() and not popup:IsMouseOver() and not (popup.anchor and popup.anchor:IsMouseOver()) then
                popup:Hide()
            end
        end)
        popup:Hide()
        tinsert(UISpecialFrames, "RubberDuckyPopup")
    end
    if popup:IsShown() and popup.anchor == anchor then popup:Hide() return end
    popup.anchor = anchor
    for _, r in ipairs(popup.rows) do r:Hide() end
    local width = 160
    for i, item in ipairs(items) do
        local r = popup.rows[i]
        if not r then
            r = CreateFrame("Button", nil, popup)
            r:SetHeight(22)
            r.text = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            r.text:SetPoint("LEFT", 8, 0)
            local hl = r:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(); hl:SetColorTexture(1, 0.82, 0, 0.12)
            popup.rows[i] = r
        end
        r:ClearAllPoints()
        r:SetPoint("TOPLEFT", 12, -12 - (i - 1) * 22)
        r:SetPoint("RIGHT", popup, "RIGHT", -12, 0)
        r.text:SetText(item[1])
        r.text:SetTextColor(1, 1, 1)
        local armed = false
        r:SetScript("OnClick", function()
            UI.Sound("button")
            if item.confirm and not armed then
                armed = true
                r.text:SetText("Sure? Click again")
                r.text:SetTextColor(1, 0.5, 0.25)
                return
            end
            popup:Hide()
            UI.Later(item[2])
        end)
        r:Show()
        width = math.max(width, (r.text:GetStringWidth() or 0) + 40)
    end
    popup:SetSize(width + 12, 24 + #items * 22)
    popup:ClearAllPoints()
    popup:SetPoint("TOPRIGHT", anchor, "BOTTOMRIGHT", 0, -2)
    popup:Show()
end

-- The reset icon, top right. Its menu puts this page's settings back to the
-- defaults (all but the page's on/off switch), and offers any position resets.
-- o: { apply = fn after settings change, extra = { keys set by hand-made
-- controls }, positions = { { "Reset log position", fn }, ... } }
function Page:ResetTool(o)
    o = o or {}
    for _, k in ipairs(o.extra or {}) do self.keys[k] = true end
    -- a small tile with the game's undo arrow on it
    local b = CreateFrame("Button", nil, self.head)
    b:SetSize(32, 32)
    self:PlaceTool(b)
    b:SetNormalTexture("Interface\\Buttons\\UI-RotationLeft-Button-Up")
    b:SetPushedTexture("Interface\\Buttons\\UI-RotationLeft-Button-Down")
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b:SetScript("OnEnter", function()
        GameTooltip:SetOwner(b, "ANCHOR_LEFT")
        GameTooltip:SetText("Reset")
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local function ResetSettings()
        for k in pairs(self.keys) do
            if k ~= self.toggleKey and ns.defaults[k] ~= nil then ns.db[k] = ns.defaults[k] end
        end
        if o.apply then o.apply() end
        self:Refresh()
    end
    b:SetScript("OnClick", function()
        UI.Sound("on")
        local items = { { "Reset settings", ResetSettings, confirm = true } }
        for _, pos in ipairs(o.positions or {}) do items[#items + 1] = pos end
        UI.Popup(b, items)
    end)
    self.tools[#self.tools + 1] = b
    return b
end

function Page:Card(title, plain)
    local c = NewCard(self, title, plain)
    self.cards[#self.cards + 1] = c
    return c
end

-- "Fine-tune" line that shows or hides a card
function Page:Expander(text, card)
    local line = self:Card(nil, true)
    local b = CreateFrame("Button", nil, line.frame)
    b:SetHeight(20)
    b:SetPoint("TOPLEFT", 6, -2)
    b:SetPoint("TOPRIGHT", -6, -2)
    local plus = b:CreateTexture(nil, "ARTWORK")
    plus:SetSize(14, 14)
    plus:SetPoint("LEFT", 4, 0)
    local t = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    t:SetPoint("LEFT", plus, "RIGHT", 6, 0)
    t:SetText(text)
    line.y = -24
    card.hidden = true
    local function Paint()
        plus:SetTexture(card.hidden and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up")
    end
    b:SetScript("OnClick", function()
        card.hidden = not card.hidden
        UI.Click(not card.hidden)
        Paint()
        self:Layout()
    end)
    Paint()
    table.remove(self.cards)
    for i, c in ipairs(self.cards) do
        if c == card then table.insert(self.cards, i, line) break end
    end
    return line
end

function Page:Layout()
    local y = self.top
    for _, c in ipairs(self.cards) do
        local f = c.frame
        f:ClearAllPoints()
        if c.hidden then
            f:Hide()
        else
            f:Show()
            f:SetPoint("TOPLEFT", self.content, "TOPLEFT", 4, y)
            f:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", -4, y)
            f:SetHeight(c:Height())
            y = y - c:Height() - 10
        end
    end
    self.content:SetHeight(-y + 12)
end

function Page:OnRefresh(fn) self.refreshers[#self.refreshers + 1] = fn end

function Page:Refresh()
    if not ns.db then return end
    for _, ctl in ipairs(self.controls) do ctl.Refresh() end
    for _, fn in ipairs(self.refreshers) do fn(self) end
    self:Layout()
end
