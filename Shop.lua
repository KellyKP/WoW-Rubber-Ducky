-- Rubber Ducky: Mrrl's Doohicky Emporium (/ducky shop). Mrrl's stall, where
-- Shiny Fishbones buy bobbers, quarterboards, charms and mottos.
--
-- Kelly's stall art is one picture (Media/Shop/stall). Everything on it is
-- placed in the art's own pixels (1536 x 1024) and scaled to the window. A tab
-- for each kind of flair; the shelf on the left, a page at a time; what you've
-- picked on the right, with its button; your Fishbones on the plaque by Mrrl.

local _, ns = ...
local Shop = {}
ns.Shop = Shop

local W, H = 1024, 683            -- the window, in its own units
local K = W / 1536                -- art pixels -> window units
local SCALE = 0.9
local SIGN_FONT = ns.MEDIA .. "Fonts\\LilitaOne-Regular.ttf"
local SIGN_INK = { 0.36, 0.18, 0.07 }

-- the tabs on the art, left to right: { left, right } in art pixels
local TABS = { { 143, 347 }, { 348, 535 }, { 543, 727 }, { 730, 910 } }
local TAB_TOP, TAB_BOTTOM, TAB_LIT_TOP = 308, 376, 284
-- the shelf (left panel) and the counter (right panel)
local SHELF = { 130, 392, 890, 728 }
local PAGER_Y = 755
local COUNTER_X = 1218

-- how each kind sits on the shelf: columns, rows, gap
local LAYOUT = {
    bobber = { cols = 6, rows = 3, gap = 12 },
    charm = { cols = 6, rows = 3, gap = 12 },
    board = { cols = 3, rows = 3, gap = 12 },
    motto = { cols = 2, rows = 6, gap = 10 },
}

-- Mrrl's chatter
local HELLO = { "Mrrgl!", "Mrrgl mrrgl!", "Mrgl? Mrrrgl!", "Mrrrrrgl!!", "Aaaaughibbrgubugbugrguburgle!" }
-- poke him and he's got plenty more to say
local CHATTER = { "Mrrgl?", "Mrrgl mrrgl mrrgl!", "Mlrrgl! Mrrgl!", "Mrrrrgl...", "Mrglglglgl!",
    "Aaaaughibbrgubugbugrguburgle!", "Mrgl mrgl! <3", "Mrrrgl? Mrrrgl!", "Blrrgl!", "Mrgl... mrgl mrgl!" }
local THANKS = { "Mrrgl! Mrrgl!", "Mrrrgl! <3", "Shiny! Mrrgl!", "Mrglglgl!" }
local SHORT = { "Mrrgl... mrgl.", "Mrrrgl? Mrgl.", "Mrgl mrgl..." }

local function P(x, y) return x * K, -y * K end
-- a line from a list, never the one he just said
local lastLine
local function Pick(list)
    local line = list[math.random(#list)]
    if line == lastLine and #list > 1 then
        for _, l in ipairs(list) do if l ~= lastLine then line = l; break end end
    end
    lastLine = line
    return line
end
-- the sign's font is ours; until the game's been restarted after an update it
-- may not be there yet, so fall back to the game's own
local function SignFont(fs, size, fallback)
    local ok = fs:SetFont(SIGN_FONT, size, "")
    if ok == false or not fs:GetFont() then fs:SetFontObject(fallback or "GameFontNormalHuge") end
end

local win, tabs, cells, detail, pager, balance, bubble
local kind, page, selected = "bobber", 1, nil

local function Sound(what) if ns.UI then ns.UI.Sound(what) end end

-- Mrrl's voice: the game's own murloc sounds (file IDs from the game's files),
-- a different one for each mood. If one isn't in this client, the classic
-- murloc gurgle plays instead.
local VOICE = {
    hello = { 556000 },                                -- the famous one
    chatter = { 555997, 555992, 556006, 555998 },      -- aggro calls and the pre-aggro gurgle
    thanks = { 556000, 555992 },                       -- the big gurgle
    short = { 555999, 555996, 555994 },                -- wounded little noises
    idle = { 555993, 556002, 556001, 556003, 556004, 556005 }, -- fidgets and grunts, now and then
}
local lastVoice
local function Gurgle(mood)
    local list = VOICE[mood] or VOICE.chatter
    local i = math.random(#list)
    if list[i] == lastVoice and #list > 1 then i = i % #list + 1 end -- not the same one twice
    local id = list[i]
    lastVoice = id
    local ok, willPlay = pcall(PlaySoundFile, id, "Master")
    if not ok or not willPlay then Sound("murloc") end
end
Shop.Gurgle = Gurgle

-------------------------------------------------------------------------------
-- Mrrl's speech bubble: pops up, holds, fades
-------------------------------------------------------------------------------

-- secs: how long his mouth moves (default: as long as the line)
local function Say(text, secs)
    if not bubble then return end
    if Shop.Talk then Shop.Talk(text, secs) end
    bubble.text:SetText(text)
    bubble.t = 0
    bubble:SetAlpha(0)
    bubble:Show()
end

local function BuildBubble()
    bubble = CreateFrame("Frame", nil, win)
    bubble:SetSize(256 * K, 128 * K)
    bubble:SetPoint("TOPLEFT", win, "TOPLEFT", P(860, 138))
    bubble:SetFrameLevel((win:GetFrameLevel() or 1) + 20)
    local t = bubble:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints()
    t:SetTexture(ns.MEDIA .. "Shop\\bubble")
    local fs = bubble:CreateFontString(nil, "OVERLAY")
    SignFont(fs, 18, "GameFontNormalLarge")
    fs:SetTextColor(SIGN_INK[1], SIGN_INK[2], SIGN_INK[3])
    fs:SetShadowOffset(0, 0); fs:SetShadowColor(0, 0, 0, 0) -- plain ink, no shadow
    -- the bubble's body is the top left 190 x 80 of its texture
    fs:SetPoint("CENTER", bubble, "TOPLEFT", 95 * K, -42 * K)
    fs:SetWidth(168 * K)
    fs:SetWordWrap(true)
    bubble.text = fs
    bubble:Hide()
    bubble:SetScript("OnUpdate", function(self, el)
        self.t = (self.t or 0) + el
        local t = self.t
        local a = t < 0.15 and t / 0.15 or (t > 3.2 and math.max(0, 1 - (t - 3.2) / 0.4) or 1)
        self:SetAlpha(a)
        if t > 3.6 then self:Hide() end
    end)
end

-------------------------------------------------------------------------------
-- Pictures of flair: a bobber or charm in a tile; a quarterboard with your
-- name and motto on it
-------------------------------------------------------------------------------

local function PlayerName()
    local n = ns.Social and ns.Social.FullName("player") or (UnitName and UnitName("player"))
    if n and ns.Social then n = ns.Social.BoardName(n) end -- what goes on the board
    return n or "You"
end

-- a quarterboard texture plus its words; fit(w, h) sizes it inside a box
local function NewBoard(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetAllPoints()
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.name:SetShadowOffset(1, -1)
    f.name:SetWordWrap(false)
    f.motto = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.motto:SetShadowOffset(1, -1)
    f.motto:SetWordWrap(false)
    -- it: the board; boxW/boxH: the space it fits in; words: show name and motto
    function f:Set(it, boxW, boxH, words, motto)
        local s = math.min(boxW / it.w, boxH / it.h)
        local w, h = it.w * s, it.h * s
        self:SetSize(w, h)
        self.tex:SetTexture(it.art)
        self.tex:SetTexCoord(0, 1, 0, 1)
        self.name:SetShown(words); self.motto:SetShown(words)
        if not words then return end
        -- the words on the plank, where every board has it
        local L = ns.Flair.BOARD
        local ph, cy = h * L.plank.h / 256, h * (it.py or L.plank.y) / 256
        local size = math.max(8, ph * 0.5)
        local font = self.name:GetFont()
        if font then
            self.name:SetFont(font, size, "OUTLINE")
            self.motto:SetFont(font, math.max(7, size * 0.72), "OUTLINE")
        end
        local textW = w * L.plank.w
        self.name:ClearAllPoints(); self.name:SetPoint("CENTER", self, "TOP", 0, -(cy - ph * 0.2))
        self.motto:ClearAllPoints(); self.motto:SetPoint("CENTER", self, "TOP", 0, -(cy + ph * 0.26))
        self.name:SetText(PlayerName())
        self.motto:SetText(motto or "")
        ns.Squeeze(self.name, textW) -- long names shrink, never "..."
        ns.Squeeze(self.motto, textW)
        ns.Under(self.name, self.motto, 0.72) -- the name always the bigger
    end
    return f
end

-------------------------------------------------------------------------------
-- The shelf
-------------------------------------------------------------------------------

local function List() return ns.Flair.Items(kind) end
local function Pages()
    local L = LAYOUT[kind]
    return math.max(1, math.ceil(#List() / (L.cols * L.rows)))
end

local Refresh

local function Select(it)
    selected = it
    Refresh()
end

local function NewCell(i)
    local UI = ns.UI
    local b = CreateFrame("Button", nil, win)
    b.art = UI.Stretch(b, "tile_navy", "BACKGROUND", 0.45)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.board = NewBoard(b)
    b.board:SetPoint("TOP", b, "TOP", 0, -6)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    b.label:SetWordWrap(false)
    b.price = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    b.price:SetShadowOffset(1, -1)
    b.tick = b:CreateTexture(nil, "OVERLAY")
    b.tick:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    b.tick:SetSize(18, 18)
    b.lock = b:CreateTexture(nil, "OVERLAY")
    b.lock:SetAtlas("Forge-Lock")
    if not b.lock:GetAtlas() then b.lock:SetTexture("Interface\\PetBattles\\PetBattle-LockIcon") end
    b.lock:SetSize(18, 18)
    -- the one you're looking at: a gold outline
    b.ring = CreateFrame("Frame", nil, b, "BackdropTemplate")
    b.ring:SetPoint("TOPLEFT", -3, 3); b.ring:SetPoint("BOTTOMRIGHT", 3, -3)
    b.ring:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 2 })
    pcall(b.ring.SetBackdropBorderColor, b.ring, 1, 0.82, 0, 1)
    b.ring:Hide()
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetPoint("TOPLEFT", 5, -5); hl:SetPoint("BOTTOMRIGHT", -5, 5)
    hl:SetColorTexture(1, 1, 1, 0.12)
    b:SetScript("OnClick", function(self)
        if not self.item then return end
        Sound("on"); Select(self.item)
    end)
    b:SetScript("OnEnter", function(self)
        local it = self.item
        if not it then return end
        local F = ns.Flair
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(it.name)
        local st = F.Status(it)
        if st == "owned" then
            GameTooltip:AddLine(F.IsWorn(it) and "Yours, and you're wearing it." or "Yours.", 0.4, 1, 0.4)
        elseif it.price then
            GameTooltip:AddLine("On Mrrl's shelf for " .. F.Bones(it.price) .. ".", 1, 1, 1)
            if st == "short" then
                GameTooltip:AddLine(("You need %d more."):format(it.price - F.Balance()), 1, 0.5, 0.4)
            end
        else
            local d = F.Earner(it.earn)
            if d and not d.hidden then
                GameTooltip:AddLine("Earned: " .. d.name, 1, 0.82, 0)
                GameTooltip:AddLine(d.goal, 1, 1, 1, true)
            else
                GameTooltip:AddLine("Earned from a secret challenge. Keep fishing!", 0.7, 0.7, 0.7, true)
            end
        end
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cells[i] = b
    return b
end

local function PaintCell(b, it, x, y, w, h)
    local F = ns.Flair
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", win, "TOPLEFT", x, y)
    b:SetSize(w, h)
    b.item = it
    local st = F.Status(it)
    local dim = st == "locked" or st == "short"
    b.icon:Hide(); b.board:Hide(); b.label:Hide()
    b.tick:Hide(); b.lock:Hide(); b.price:SetText("")
    if kind == "bobber" or kind == "charm" then
        b.icon:ClearAllPoints()
        b.icon:SetPoint("TOP", b, "TOP", 0, -h * 0.11)
        b.icon:SetSize(h * 0.6, h * 0.6)
        b.icon:SetTexture(it.art)
        b.icon:SetDesaturated(st == "locked")
        b.icon:SetAlpha(dim and 0.55 or 1)
        b.icon:Show()
    elseif kind == "board" then
        b.board:Set(it, w - 16, h - 24, false)
        b.board.tex:SetDesaturated(st == "locked")
        b.board:SetAlpha(dim and 0.55 or 1)
        b.board:Show()
    else -- motto: just the words
        b.label:ClearAllPoints()
        b.label:SetPoint("LEFT", b, "LEFT", 14, 0)
        b.label:SetPoint("RIGHT", b, "RIGHT", -64, 0)
        b.label:SetJustifyH("LEFT")
        b.label:SetText(it.name)
        b.label:SetTextColor(dim and 0.6 or 1, dim and 0.6 or 0.92, dim and 0.6 or 0.75)
        b.label:Show()
    end
    -- the corner: a tick if it's yours, a lock if earned, else its price
    local motto = kind == "motto"
    if st == "owned" then
        b.tick:ClearAllPoints()
        if motto then b.tick:SetPoint("RIGHT", b, "RIGHT", -12, 0) else b.tick:SetPoint("BOTTOMRIGHT", -8, 7) end
        b.tick:Show()
    elseif st == "locked" then
        b.lock:ClearAllPoints()
        if motto then b.lock:SetPoint("RIGHT", b, "RIGHT", -12, 0) else b.lock:SetPoint("BOTTOMRIGHT", -7, 7) end
        b.lock:Show()
    else
        b.price:ClearAllPoints()
        if motto then b.price:SetPoint("RIGHT", b, "RIGHT", -12, 0)
        elseif kind == "board" then b.price:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -10, 6)
        else b.price:SetPoint("BOTTOM", b, "BOTTOM", 0, 9) end
        b.price:SetText(F.Bones(it.price, 12))
        if st == "short" then b.price:SetTextColor(0.75, 0.75, 0.75) else b.price:SetTextColor(1, 1, 1) end
    end
    b.ring:Hide() -- the sparkle frame marks the one you picked
    b:Show()
end


-- the one you're looking at: a soft gold glow that breathes, with stars
-- twinkling on and off all the way round it
local SPARK_COLORS = { { 1, 0.95, 0.6 }, { 1, 0.82, 0.25 }, { 1, 1, 1 }, { 0.7, 0.9, 1 } }
local selFx
local function SelFx()
    if selFx then return selFx end
    local f = CreateFrame("Frame", nil, win)
    f:SetFrameLevel(win:GetFrameLevel() + 20)
    f:EnableMouse(false)
    -- the journal's soft selected glow, the same one a picked catch gets
    local glow = f:CreateTexture(nil, "ARTWORK")
    glow:SetAllPoints()
    glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    glow:SetBlendMode("ADD")
    -- doubled up, so it reads on the dark tiles too
    local glow2 = f:CreateTexture(nil, "ARTWORK")
    glow2:SetAllPoints()
    glow2:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    glow2:SetBlendMode("ADD")
    glow2:SetAlpha(0.6)
    local breathe = f:CreateAnimationGroup()
    breathe:SetLooping("BOUNCE")
    local a = breathe:CreateAnimation("Alpha")
    a:SetFromAlpha(1); a:SetToAlpha(0.7); a:SetDuration(0.9); a:SetSmoothing("IN_OUT")
    f.breathe = breathe
    f.sparks = {}
    for i = 1, 12 do
        local tex = f:CreateTexture(nil, "OVERLAY")
        tex:SetTexture("Interface\\Cooldown\\star4")
        tex:SetBlendMode("ADD")
        tex:SetAlpha(0)
        local anim = tex:CreateAnimationGroup()
        local a1 = anim:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.25); a1:SetOrder(1)
        local g = anim:CreateAnimation("Scale"); g:SetScaleFrom(0.2, 0.2); g:SetScaleTo(1, 1); g:SetDuration(0.25); g:SetOrder(1)
        local r = anim:CreateAnimation("Rotation"); r:SetDegrees(-90); r:SetDuration(0.7); r:SetOrder(1)
        local a2 = anim:CreateAnimation("Alpha"); a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetDuration(0.4); a2:SetOrder(2)
        local s = { tex = tex, anim = anim }
        function s.Again()
            if not f:IsShown() then tex:SetAlpha(0); return end
            -- somewhere on the edge
            local w, h = f:GetWidth() or 60, f:GetHeight() or 60
            local d = math.random() * 2 * (w + h)
            local x, y
            if d < w then x, y = d, 0
            elseif d < w + h then x, y = w, -(d - w)
            elseif d < 2 * w + h then x, y = w - (d - w - h), -h
            else x, y = 0, -(h - (d - 2 * w - h)) end
            tex:ClearAllPoints()
            tex:SetPoint("CENTER", f, "TOPLEFT", x, y)
            local px = 10 + math.random() * 12
            tex:SetSize(px, px)
            local c = SPARK_COLORS[math.random(#SPARK_COLORS)]
            tex:SetVertexColor(c[1], c[2], c[3])
            C_Timer.After(math.random() * 0.5, function() if f:IsShown() then anim:Play() end end)
        end
        anim:SetScript("OnFinished", function() tex:SetAlpha(0); s.Again() end)
        f.sparks[i] = s
    end
    f:SetScript("OnShow", function(self)
        self.breathe:Play()
        for _, s in ipairs(self.sparks) do if not s.anim:IsPlaying() then s.Again() end end
    end)
    f:SetScript("OnHide", function(self)
        self.breathe:Stop()
        for _, s in ipairs(self.sparks) do s.anim:Stop(); s.tex:SetAlpha(0) end
    end)
    f:Hide()
    selFx = f
    return f
end

local function PaintShelf()
    local L = LAYOUT[kind]
    local list = List()
    local per = L.cols * L.rows
    page = math.min(math.max(page, 1), Pages())
    local sx0, sy0, sx1, sy1 = SHELF[1] * K, SHELF[2] * K, SHELF[3] * K, SHELF[4] * K
    local gap = L.gap * K
    local cw = (sx1 - sx0 - gap * (L.cols - 1)) / L.cols
    local ch = (sy1 - sy0 - gap * (L.rows - 1)) / L.rows
    -- square slots for bobbers and charms, centred on the shelf
    if kind == "bobber" or kind == "charm" then
        local s = math.min(cw, ch)
        cw, ch = s, s
        sx0 = (sx0 + sx1) / 2 - (s * L.cols + gap * (L.cols - 1)) / 2
    end
    for i = 1, math.max(#cells, per) do
        local it = list[(page - 1) * per + i]
        local b = cells[i] or NewCell(i)
        if it and i <= per then
            local c, r = (i - 1) % L.cols, math.floor((i - 1) / L.cols)
            PaintCell(b, it, sx0 + c * (cw + gap), -(sy0 + r * (ch + gap)), cw, ch)
            -- motto rows on the navy strip, not tiles
            b.art:SetArt(kind == "motto" and "strip_navy" or "tile_navy")
            b.art.s = kind == "motto" and (ch / 103) or (kind == "board" and 0.35 or 0.45)
            b.art:Layout()
        else
            b.item = nil
            b:Hide()
        end
    end
    -- sparkle round the one you're looking at, if it's on this page
    local fx, on = SelFx(), nil
    for _, b in ipairs(cells) do if b.item and b.item == selected and b:IsShown() then on = b end end
    if on then
        fx:ClearAllPoints()
        fx:SetPoint("TOPLEFT", on, "TOPLEFT", 2, -2)
        fx:SetPoint("BOTTOMRIGHT", on, "BOTTOMRIGHT", -2, 2)
        fx:Show()
    else
        fx:Hide()
    end
    local n = Pages()
    pager.text:SetText(page .. " / " .. n)
    pager:SetShown(n > 1)
    pager.prev:SetShown(page > 1)
    pager.next:SetShown(page < n)
end

-------------------------------------------------------------------------------
-- The counter: the one you picked
-------------------------------------------------------------------------------

local function StatusLine(it)
    local F = ns.Flair
    if it.lore then return it.lore end
    if not it.price and not it.earn then return "Everyone starts with this one." end
    if it.price then return "Fresh from Mrrl's shelf. He swears it's genuine." end
    local d = F.Earner(it.earn)
    if d and not d.hidden then return "Earned by finishing " .. d.name .. ": " .. d.goal end
    return "Earned from a secret challenge. Keep fishing!"
end

local function PaintDetail()
    local F = ns.Flair
    local it = selected
    if not it then detail:Hide(); return end
    detail:Show()
    detail.name:SetText(it.name)
    detail.tile:Hide(); detail.board:Hide()
    if it.kind == "bobber" or it.kind == "charm" then
        detail.tile.icon:SetTexture(it.art)
        detail.tile.icon:SetDesaturated(F.Status(it) == "locked")
        detail.tile:Show()
    else
        -- a quarterboard shows itself; a motto shows on the board you've got
        local board = it.kind == "board" and it or F.Worn("board")
        local motto = it.kind == "motto" and it.name or (F.Worn("motto") or {}).name
        detail.board:Set(board, 262, 120, true, motto)
        detail.board.tex:SetDesaturated(it.kind == "board" and F.Status(it) == "locked")
        detail.board:Show()
    end
    detail.lore:SetText(StatusLine(it))

    local st = F.Status(it)
    local worn = st == "owned" and F.IsWorn(it)
    -- the price, or what it takes
    if st == "owned" then
        detail.price:SetText("|TInterface\\RaidFrame\\ReadyCheck-Ready:18:18|t |cff2e8b22Yours|r")
    elseif it.price then
        detail.price:SetText(F.Bones(it.price, 22))
    else
        detail.price:SetText("|cff7a5a3aEarned, not sold|r")
    end
    -- the one button
    local b, text, grey = detail.button, nil, false
    if worn then text, grey = it.kind == "motto" and "Wearing it" or "Equipped", true
    elseif st == "owned" then text = it.kind == "bobber" and "Equip" or "Wear it"
    elseif st == "buy" then text = "Buy"
    elseif st == "short" then text, grey = ("Need %d more"):format(it.price - F.Balance()), true
    else text, grey = "Locked", true end
    b.text:SetText(text)
    b.art:SetArt(grey and "button_grey" or "button")
    b.text:SetFontObject(grey and "GameFontDisable" or ns.UI.FONT.bold)
    b.grey = grey
end

local function Press()
    local F = ns.Flair
    local it = selected
    if not it then return end
    local st = F.Status(it)
    if st == "owned" then
        if F.IsWorn(it) then return end
        F.Equip(it); Sound("on")
    elseif st == "buy" then
        if F.Buy(it) then
            Sound("shopBought")
            Gurgle("thanks")
            Say(Pick(THANKS))
            if ns.Glint and detail.tile:IsShown() then ns.Glint(detail.tile, 6, 1.4) end
            if ns.Glint and detail.board:IsShown() then ns.Glint(detail.board, 6, 1.4) end
            -- and the whole counter sparkles for a moment
            if ns.Glint and detail.burst then ns.Glint(detail.burst, 28, 1.8, 1.6) end
        end
    elseif st == "short" then
        Sound("off"); Gurgle("short"); Say(Pick(SHORT), 0.3) -- a short, sad mumble
    else
        Sound("off")
    end
    Refresh()
end

-------------------------------------------------------------------------------

function Refresh()
    if not win or not win:IsShown() then return end
    for i, t in ipairs(tabs) do
        local on = ns.Flair.KINDS[i] == kind
        t.lit:SetShown(on)
        t.text:SetTextColor(on and SIGN_INK[1] or 0.96, on and SIGN_INK[2] or 0.88, on and SIGN_INK[3] or 0.7)
    end
    balance:SetText(ns.Flair.Balance())
    PaintShelf()
    PaintDetail()
    if Shop.pad then Shop.pad:Paint() end
end

-- turn to a tab: at the front of Mrrl's shelf, or on the page with `it`
local function OpenTab(k, it)
    kind = k
    it = it or List()[1]
    selected = it
    local per = LAYOUT[k].cols * LAYOUT[k].rows
    page = 1
    for i, x in ipairs(List()) do if x == it then page = math.ceil(i / per) end end
    Refresh()
end

local function Build()
    local UI = ns.UI
    win = CreateFrame("Frame", "RubberDuckyShop", UIParent)
    win:SetSize(W, H)
    win:SetScale(SCALE)
    win:SetFrameStrata("DIALOG")
    win:SetToplevel(true)
    win:EnableMouse(true)
    win:SetPoint("CENTER")
    win:Hide()
    if UISpecialFrames then tinsert(UISpecialFrames, "RubberDuckyShop") end -- Escape closes it

    local bg = win:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(ns.MEDIA .. "Shop\\stall")
    bg:SetTexCoord(0, 1, 0, H / 1024)

    -- the sign: carved in, like the fishing log's title
    local sign = CreateFrame("Frame", nil, win)
    sign:SetAllPoints()
    sign:SetFrameLevel(win:GetFrameLevel() + 2)
    local lines = {
        -- text, size, height (art px), each letter's nudge (art px), and a width
        -- to spread it across: the whole parchment, vine and all
        { "Mrrl's", 51 * K, 141, { -3, 4.5, -4.5, 3, 6, -4.5 } },
        { "Doohicky Emporium", 34 * K, 183, { 2, -3, 4, -2, 3, -4, 1, -3, 0, 3, -2, 4, -3, 2, -4, 8, -1 }, 340 },
    }
    Shop.signLines = {}
    for i, l in ipairs(lines) do
        Shop.signLines[i] = { carved = ns.CarvedText(sign, l[1], l[2]), y = l[3], bob = l[4], width = l[5] }
    end
    function Shop.PlaceSign()
        for _, l in ipairs(Shop.signLines) do
            local bob = {}
            for j, b in ipairs(l.bob) do bob[j] = b * K end
            l.carved:Place(win, 515 * K, -l.y * K, bob, l.width and l.width * K) -- the plaque's middle
        end
    end
    Shop.PlaceSign()

    -- the close button, painted on the top right post
    local close = CreateFrame("Button", nil, win)
    Shop.close = close
    close:SetSize(44, 44)
    close:SetPoint("CENTER", win, "TOPLEFT", P(1473, 122))
    local chl = close:CreateTexture(nil, "HIGHLIGHT")
    chl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    chl:SetBlendMode("ADD")
    chl:SetAllPoints()
    close:SetScript("OnClick", function() win:Hide() end)

    -- the tabs: a lit parchment tab over the wooden one you're on
    tabs = {}
    for i, k in ipairs(ns.Flair.KINDS) do
        local r = TABS[i]
        local t = CreateFrame("Button", nil, win)
        t:SetPoint("TOPLEFT", win, "TOPLEFT", P(r[1], TAB_TOP))
        t:SetSize((r[2] - r[1]) * K, (TAB_BOTTOM - TAB_TOP) * K)
        t.lit = t:CreateTexture(nil, "BACKGROUND")
        t.lit:SetTexture(ns.MEDIA .. "Shop\\tab")
        t.lit:SetTexCoord(0, 204 / 256, 0, 92 / 128)
        t.lit:SetPoint("BOTTOMLEFT", t, "BOTTOMLEFT", 0, 0)
        t.lit:SetSize((r[2] - r[1]) * K, (TAB_BOTTOM - TAB_LIT_TOP) * K)
        t.text = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t.text:SetPoint("CENTER", 0, 0)
        t.text:SetText(ns.Flair.TITLES[k])
        t.text:SetShadowOffset(1, -1)
        local hl = t:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 6, -6); hl:SetPoint("BOTTOMRIGHT", -6, 6)
        hl:SetColorTexture(1, 1, 1, 0.1)
        t:SetScript("OnClick", function()
            if kind == k then return end
            Sound("shopPage"); OpenTab(k)
        end)
        tabs[i] = t
    end

    -- your Fishbones, on the plaque on Mrrl's shelf
    -- the Fishbone and the count, each with a soft shadow on the plaque
    local plaqueX, plaqueY = P(1332, 357)
    balance = CreateFrame("Frame", nil, win)
    balance:SetSize(150, 34)
    balance:SetPoint("CENTER", win, "TOPLEFT", plaqueX, plaqueY)
    balance:SetFrameLevel((win:GetFrameLevel() or 1) + 3)
    balance.shadow = balance:CreateTexture(nil, "ARTWORK", nil, 1)
    balance.shadow:SetTexture(ns.MEDIA .. "Flair\\fishbone_small")
    balance.shadow:SetVertexColor(0, 0, 0, 0.55)
    balance.shadow:SetSize(30, 30)
    balance.icon = balance:CreateTexture(nil, "ARTWORK", nil, 2)
    balance.icon:SetTexture(ns.MEDIA .. "Flair\\fishbone_small")
    balance.icon:SetSize(30, 30)
    balance.text = balance:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    balance.text:SetTextColor(1, 0.88, 0.55)
    balance.text:SetShadowColor(0, 0, 0, 0.85)
    balance.text:SetShadowOffset(1.5, -1.5)
    function balance:SetText(n)
        self.text:SetText(BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n))
        -- the pair, centred on the plaque
        local w = 30 + 6 + (self.text:GetStringWidth() or 20)
        self.icon:ClearAllPoints(); self.icon:SetPoint("LEFT", self, "CENTER", -w / 2, 0)
        self.shadow:ClearAllPoints(); self.shadow:SetPoint("TOPLEFT", self.icon, "TOPLEFT", 1.5, -1.5)
        self.text:ClearAllPoints(); self.text:SetPoint("LEFT", self.icon, "RIGHT", 6, 0)
    end
    local plaque = CreateFrame("Frame", nil, win)
    plaque:SetPoint("TOPLEFT", win, "TOPLEFT", P(1232, 318))
    plaque:SetSize(200 * K, 68 * K)
    plaque:EnableMouse(true)
    plaque:SetScript("OnEnter", function(self)
        local f = ns.Flair.Saved()
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Shiny Fishbones")
        GameTooltip:AddLine("They come up with your catch now and then, and every challenge you finish pays some.", 1, 1, 1, true)
        GameTooltip:AddDoubleLine("Found", f.earned or 0, 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:AddDoubleLine("Spent here", f.spent or 0, 0.8, 0.8, 0.8, 1, 1, 1)
        GameTooltip:Show()
    end)
    plaque:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- the shelf's pages: the journal's arrows
    cells, selFx = {}, nil
    pager = CreateFrame("Frame", nil, win)
    pager:SetAllPoints()
    pager.text = pager:CreateFontString(nil, "OVERLAY", UI.FONT.bold)
    pager.text:SetPoint("CENTER", win, "TOPLEFT", P(525, PAGER_Y))
    local function Arrow(name, x, step)
        local b = CreateFrame("Button", nil, pager)
        b:SetSize(46 * K * 1.1, 46 * K * 1.1)
        b:SetPoint("CENTER", win, "TOPLEFT", P(x, PAGER_Y))
        b:SetNormalTexture(ns.MEDIA .. "Journal\\arrow_" .. name)
        b:SetPushedTexture(ns.MEDIA .. "Journal\\arrow_" .. name .. "_down")
        b:SetScript("OnClick", function()
            page = page + step
            Sound("shopPage")
            Refresh()
        end)
        return b
    end
    pager.prev, pager.next = Arrow("left", 440, -1), Arrow("right", 610, 1)

    -- the counter
    detail = CreateFrame("Frame", nil, win)
    detail:SetAllPoints()
    detail.name = detail:CreateFontString(nil, "OVERLAY", UI.FONT.large)
    detail.name:SetPoint("TOP", win, "TOPLEFT", P(COUNTER_X, 420))
    detail.name:SetWidth(400 * K)
    detail.name:SetWordWrap(false)
    detail.tile = UI.IconTile(detail, 170 * K, nil, false)
    detail.tile:SetPoint("TOP", win, "TOPLEFT", P(COUNTER_X, 470))
    detail.board = NewBoard(detail)
    -- the counter, from the name down to the button: sparkles all over it when you buy
    detail.burst = CreateFrame("Frame", nil, detail)
    detail.burst:SetPoint("TOPLEFT", win, "TOPLEFT", P(COUNTER_X - 210, 400))
    detail.burst:SetPoint("BOTTOMRIGHT", win, "TOPLEFT", P(COUNTER_X + 210, 830))
    detail.burst:SetFrameLevel((detail:GetFrameLevel() or 1) + 20)
    detail.burst:EnableMouse(false)
    detail.board:SetPoint("CENTER", win, "TOPLEFT", P(COUNTER_X, 560))
    detail.lore = detail:CreateFontString(nil, "OVERLAY", UI.FONT.ink)
    detail.lore:SetPoint("TOP", win, "TOPLEFT", P(COUNTER_X, 655))
    detail.lore:SetWidth(380 * K)
    detail.lore:SetHeight(54 * K)
    detail.lore:SetJustifyV("TOP")
    local rule = detail:CreateTexture(nil, "ARTWORK")
    rule:SetColorTexture(0.55, 0.4, 0.22, 0.6)
    rule:SetSize(340 * K, 1.5)
    rule:SetPoint("CENTER", win, "TOPLEFT", P(COUNTER_X, 714))
    detail.price = detail:CreateFontString(nil, "OVERLAY", UI.FONT.large)
    detail.price:SetPoint("CENTER", win, "TOPLEFT", P(COUNTER_X, 742))
    detail.button = UI.Button(detail, "Buy", 260 * K, Press, { height = 56 * K })
    detail.button:SetPoint("CENTER", win, "TOPLEFT", P(COUNTER_X, 797))

    BuildBubble()

    -- Mrrl, peeking over his counter: poke him and he talks
    local mrrl = CreateFrame("Button", nil, win)
    mrrl:SetPoint("TOPLEFT", win, "TOPLEFT", P(1030, 135))
    mrrl:SetSize(200 * K, 182 * K) -- his head and hands, clear of the Fishbones plaque
    mrrl:SetScript("OnClick", function()
        local now = GetTime()
        if mrrl.at and now - mrrl.at < 0.4 then return end -- not a machine gun
        mrrl.at = now
        Gurgle("chatter")
        Say(Pick(CHATTER))
        if Shop.Blink then Shop.Blink() end
    end)
    mrrl:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Mrrl")
        GameTooltip:AddLine("Proprietor. Mostly says \"mrrgl\".", 1, 1, 1)
        GameTooltip:Show()
    end)
    mrrl:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Shop.mrrl = mrrl

    -- Mrrl blinks now and then: half shut, shut, half shut, open. Kelly
    -- repainted his face for each; only the eyes, cut from those, go on top
    -- and his mouth moves while he talks: closed, open, wide, in no set
    -- order, for about as long as what he's saying; then back to his grin
    local mouth = win:CreateTexture(nil, "ARTWORK", nil, 1)
    mouth:SetTexture(ns.MEDIA .. "Shop\\talk")
    mouth:SetSize(140 * K, 100 * K)
    mouth:SetPoint("TOPLEFT", win, "TOPLEFT", P(1091, 227))
    mouth:Hide()
    local talkLeft, talkNext, lastShape = 0, 0, 0
    local function Shape(i)
        mouth:SetTexCoord((i - 1) * 170 / 512, ((i - 1) * 170 + 140) / 512, 0, 100 / 128)
        mouth:Show()
        lastShape = i
    end
    function Shop.Talk(text, secs)
        if not text or text == "" then talkLeft = 0; mouth:Hide(); return end -- hush
        talkLeft = secs or math.min(1.6, 0.35 + 0.045 * #text)
        talkNext = 0
        if Shop.StopGrunt then Shop.StopGrunt() end -- talking beats grunting
    end
    -- Now and then, while you browse, a little grunt: mouth open, shut, back
    -- to his grin. On its own clock, slower than his blinking.
    local GRUNT = { { 2, 0.16 }, { 1, 0.14 } }
    local gruntAt, gstep, gstepAt = 10 + math.random() * 10, 0, 0
    function Shop.StopGrunt() gstep = 0 end
    function Shop.Grunt()
        gstep, gstepAt = 1, 0
        Shape(GRUNT[1][1])
        Gurgle("idle")
    end
    win:HookScript("OnUpdate", function(_, el)
        if talkLeft > 0 then return end
        if gstep > 0 then
            gstepAt = gstepAt + el
            if gstepAt >= GRUNT[gstep][2] then
                gstep, gstepAt = gstep + 1, 0
                if GRUNT[gstep] then Shape(GRUNT[gstep][1])
                else gstep = 0; mouth:Hide(); gruntAt = 12 + math.random() * 16 end
            end
            return
        end
        gruntAt = gruntAt - el
        if gruntAt <= 0 and not (bubble and bubble:IsShown()) then Shop.Grunt() end
    end)
    win:HookScript("OnUpdate", function(_, el)
        if talkLeft <= 0 then return end
        talkLeft = talkLeft - el
        if talkLeft <= 0 then mouth:Hide(); return end
        talkNext = talkNext - el
        if talkNext <= 0 then
            local i = math.random(3)
            if i == lastShape then i = i % 3 + 1 end
            Shape(i)
            talkNext = 0.08 + math.random() * 0.07
        end
    end)

    local lids = win:CreateTexture(nil, "ARTWORK", nil, 2)
    lids:SetTexture(ns.MEDIA .. "Shop\\blink")
    lids:SetSize(136 * K, 80 * K)
    lids:SetPoint("TOPLEFT", win, "TOPLEFT", P(1093, 195))
    lids:Hide()
    local FRAMES = { { "half", 0.04 }, { "shut", 0.08 }, { "half", 0.04 } }
    local blinkAt, step, stepAt = 3, 0, 0
    local function Lid(which)
        if which == "half" then lids:SetTexCoord(0, 136 / 512, 0, 80 / 128)
        else lids:SetTexCoord(256 / 512, 392 / 512, 0, 80 / 128) end
        lids:Show()
    end
    function Shop.Blink() step, stepAt = 1, 0; Lid(FRAMES[1][1]) end
    win:HookScript("OnUpdate", function(_, el)
        if step > 0 then
            stepAt = stepAt + el
            if stepAt >= FRAMES[step][2] then
                step, stepAt = step + 1, 0
                if FRAMES[step] then Lid(FRAMES[step][1])
                else
                    step = 0
                    lids:Hide()
                    -- every so often, a quick second blink
                    blinkAt = math.random() < 0.2 and 0.15 or (2.5 + math.random() * 4)
                end
            end
            return
        end
        blinkAt = blinkAt - el
        if blinkAt <= 0 then Shop.Blink() end
    end)

    win:SetScript("OnShow", function()
        Sound("shopOpen")
        Say(Pick(HELLO))
        -- and Mrrl says hello, a beat after the shop opens
        if C_Timer then C_Timer.After(0.25, function() if win:IsShown() then Gurgle("hello") end end) end
        Refresh()
    end)
    win:SetScript("OnHide", function()
        Sound("shopClose")
        if Shop.Talk then Shop.Talk() end
        if bubble then bubble:Hide() end
    end)
    -- a controller: the D-pad walks the shelf (and on to the next page), X
    -- presses the counter's button, the shoulders change tab, B closes. Each
    -- has a badge on the thing it works, with the Gamepad UI on.
    local function Walk(dir)
        local list = List()
        if #list == 0 then return end
        local cols = LAYOUT[kind].cols
        local at = 1
        for i, x in ipairs(list) do if x == selected then at = i end end
        local step = ({ up = -cols, down = cols, left = -1, right = 1 })[dir] or 0
        local to = at + step
        if to < 1 or to > #list then return end
        local per = cols * LAYOUT[kind].rows
        local was = page
        page = math.ceil(to / per)
        Sound(page ~= was and "shopPage" or "tick")
        Select(list[to])
    end
    Shop.Walk = Walk
    Shop.pad = ns.Pad.Attach(win, {
        roots = function() return { win } end,
        move = Walk,
        noSelect = true,
        extra = { button = "PAD3", fn = function() Press() end },
        pages = function(dir)
            local list, at = ns.Flair.KINDS, 1
            for i, k in ipairs(list) do if k == kind then at = i end end
            at = (at - 1 + dir) % #list + 1
            Sound("shopPage"); OpenTab(list[at])
        end,
        -- the buttons' badges: on the things they work
        badges = function(nav)
            nav:Badge(tabs[1], "PADLSHOULDER", "LEFT", -24, -4, 30)
            nav:Badge(tabs[#tabs], "PADRSHOULDER", "RIGHT", 24, -4, 30)
            nav:Badge(detail.button, "PAD3", "TOPLEFT", 4, -4, 26, function()
                return selected and detail:IsShown() and not detail.button.grey
            end)
            nav:Badge(Shop.close, "PAD2", "TOPLEFT", 2, -2, 22)
        end,
    })
    ns.Flair.OnChange(function() if win:IsShown() then Refresh() end end)
end

-- open on a tab (and an item): Shop:Show("board"), Shop:Show("bobber", "murloc")
function Shop:Show(k, key)
    if not ns.Flair then return end
    if not win then Build() end
    win:ClearAllPoints()
    win:SetPoint("CENTER")
    local it = k and key and ns.Flair.Get(k, key)
    kind = k or kind
    win:Show()
    Shop.PlaceSign() -- again now: the sign's letters measure right once the font's loaded
    OpenTab(kind, it)
end

function Shop:Hide() if win then win:Hide() end end
function Shop:Toggle() if win and win:IsShown() then win:Hide() else self:Show() end end
function Shop:IsShown() return win and win:IsShown() or false end
function Shop:Refresh() Refresh() end
-- for tests
function Shop.State() return { kind = kind, page = page, selected = selected, cells = cells, detail = detail, tabs = tabs, pager = pager } end
function Shop.Press() Press() end
