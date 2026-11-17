-- Rubber Ducky: fishing log. What you caught this session, on the painted board
-- (Media\Log\board). Positions below are in the art's own pixels (1024 square).

local _, ns = ...
local Log = {}
ns.Log = Log

local ART = 1024
local BASE = 440 -- on-screen size at scale 1
local K = BASE / ART
local ROWS = { { 349, 426 }, { 426, 501 }, { 501, 578 }, { 578, 654 }, { 654, 731 }, { 731, 812 } }
local COL_LOOT, COL_COUNT, COL_NOTE = { 162, 629 }, { 629, 705 }, { 705, 942 }
local TOTAL = { 486, 876 } -- centre of the blue strip (a little low: the font sits high)
local TOTAL_RISE = 0.04 -- the total climbs a little to the right, letter by letter
local PAGER = { 560, 318 } -- "< 1/2 >", in the Loot header
local CLOSE = { 922, 137, 52 } -- painted buttons: centre and radius
local RENEW = { 922, 235, 34 }
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

-- this session's catch, in the order first caught
local session = { order = {}, items = {}, total = 0 }
Log.session = session
local page, lastCast = 1, nil

local win, rows, total, pager

local function P(x, y) return x * K, -y * K end -- art pixels -> frame offsets from TOPLEFT

local function SetFont(fs, size)
    local ok = not NO_LATIN_FONT[GetLocale()] and pcall(fs.SetFont, fs, FONT, size, "")
    if not ok or not fs:GetFont() then fs:SetFont(STANDARD_TEXT_FONT, size * 0.85, "") end
    fs:SetTextColor(INK[1], INK[2], INK[3])
end

-- largest size up to `size` that fits `width`
local function Fit(fs, text, size, width)
    fs:SetText(text)
    while size > 8 and (fs:GetStringWidth() or 0) > width do
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

local quiet = false

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
    -- (the swap has its own sound)
    local function Page(kit)
        if quiet or not SOUNDKIT then return end
        pcall(PlaySound, SOUNDKIT[kit])
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
        if SOUNDKIT then pcall(PlaySound, SOUNDKIT.IG_ABILITY_PAGE_TURN) end -- a fresh page
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
            if self.id then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                pcall(GameTooltip.SetItemByID, GameTooltip, self.id)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local mid = -(r[2] - r[1]) / 2

        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(50 * K, 50 * K)
        row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        row.icon:SetPoint("LEFT", row, "TOPLEFT", (COL_LOOT[1] - x0 + 15) * K, mid * K)

        row.name = Text(row, 16, "LEFT")
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 18 * K, 0)
        row.name:SetWidth(NAME_W * K)

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

    pager = CreateFrame("Frame", nil, win)
    pager:SetSize(150 * K, 50 * K)
    pager:SetPoint("CENTER", win, "TOPLEFT", P(PAGER[1], PAGER[2]))
    pager.text = Text(pager, 15)
    pager.text:SetPoint("CENTER")
    local function Arrow(label, dx, step)
        local b = CreateFrame("Button", nil, pager)
        b:SetSize(40 * K, 50 * K)
        b:SetPoint("CENTER", pager, "CENTER", dx * K, 0)
        b.text = Text(b, 18); b.text:SetPoint("CENTER"); b.text:SetText(label)
        b:SetScript("OnClick", function() page = page + step; Log:Refresh() end)
        return b
    end
    pager.prev = Arrow("<", -45, -1)
    pager.next = Arrow(">", 45, 1)

    win:Hide()
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

function Log:Refresh()
    if not win then return end
    local n = #session.order
    local pages = math.max(1, math.ceil(n / #ROWS))
    page = math.min(math.max(page, 1), pages)
    for i, row in ipairs(rows) do
        local e = session.items[session.order[(page - 1) * #ROWS + i]]
        if e then
            local r = RARITY[e.quality or 1] or RARITY[1]
            row.count:SetText(e.count)
            row.icon:SetTexture(e.icon or 134400)
            SetFont(row.name, 16)
            Fit(row.name, e.name, 16, NAME_W * K)
            row.name:SetTextColor(r[1], r[2], r[3])
            SetFont(row.note, 16)
            Fit(row.note, e.note, 16, (COL_NOTE[2] - COL_NOTE[1] - 52) * K)
            row.note:SetTextColor(r[1], r[2], r[3])
            row.id = e.id
            row:Show()
        else
            row.id = nil
            row:Hide()
        end
    end
    Log.DrawTotal(("Total: %d fish"):format(session.total))
    pager:SetShown(pages > 1)
    pager.text:SetText(("%d/%d"):format(page, pages))
    pager.prev:SetShown(page > 1)
    pager.next:SetShown(page < pages)
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
function Log:Add(items)
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
                    note = Log.PickNote(it.quality) }
                session.items[key] = e
                session.order[#session.order + 1] = key
            end
            local n = math.max(1, it.count or 1)
            e.count = e.count + n
            session.total = session.total + n
            added = true
        end
    end
    if not added then return end
    page = math.ceil(#session.order / #ROWS) -- show the newest
    self:Refresh()
end

function Log:Show()
    if not ns.db.logEnabled then return end
    if not win then Build() end
    Place()
    self:Refresh()
    win:Show()
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

-- The "Ducky Log" character macro, for an action bar (handy on a controller).
-- Made the first time you pick it up; after that yours, icon and all.
local MACRO, MACRO_BODY = "Ducky Log", "/ducky log"
Log.MACRO_ICON = "Interface\\Icons\\INV_Misc_Book_09"
function Log:PickupMacro()
    if InCombatLockdown() then return end
    local i = ns.Safe(GetMacroIndexByName, MACRO)
    if not i or i == 0 then
        local ok, made = pcall(CreateMacro, MACRO, Log.MACRO_ICON, MACRO_BODY, true) -- per character
        if not ok or not made then
            ns.Chat("couldn't make the log macro (" .. tostring(made or "your character macros may be full") .. ").")
            return
        end
        i = made
    end
    ns.Safe(PickupMacro, i)
end

-- The log button: drag it anywhere, right-click to lock it. Off by default.
local button
local function PlaceButton()
    button:ClearAllPoints()
    local pos = ns.db.logButtonPos
    if pos then button:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
    else button:SetPoint("LEFT", UIParent, "LEFT", 30, 280) end
end
local function BuildButton()
    button = CreateFrame("Button", "RubberDuckyLogButton", UIParent)
    button:SetSize(ns.db.logButtonSize or 40, ns.db.logButtonSize or 40)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:SetMovable(true)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local art = ns.MEDIA .. "Log\\button"
    local tex = button:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(art)
    local hl = button:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture(art); hl:SetBlendMode("ADD"); hl:SetAlpha(0.3)
    -- a little press, like an action button
    button:SetScript("OnMouseDown", function() tex:SetPoint("TOPLEFT", 1, -1); tex:SetPoint("BOTTOMRIGHT", 1, -1) end)
    button:SetScript("OnMouseUp", function() tex:SetAllPoints() end)
    button:SetScript("OnDragStart", function(self)
        if not ns.db.logButtonLocked then self:StartMoving() end
    end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, rel, x, y = self:GetPoint()
        ns.db.logButtonPos = { point, rel, x, y }
    end)
    local function Tip(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Fishing log")
        GameTooltip:AddLine("Click to open or close.", 1, 1, 1)
        if ns.db.logButtonLocked then
            GameTooltip:AddLine("Locked. Right-click to unlock.", 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine("Drag to move. Right-click to lock.", 0.7, 0.7, 0.7)
        end
        GameTooltip:Show()
    end
    button:SetScript("OnClick", function(self, mouse)
        if mouse == "RightButton" then
            ns.db.logButtonLocked = not ns.db.logButtonLocked
            if GameTooltip:IsOwned(self) then Tip(self) end
        else
            Log:Toggle(true)
        end
    end)
    button:SetScript("OnEnter", Tip)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    PlaceButton()
end
function Log:ApplyButton()
    if not ns.db then return end
    local want = ns.db.logButton and ns.db.logEnabled
    if want and not button then BuildButton() end
    if button then
        button:SetSize(ns.db.logButtonSize or 40, ns.db.logButtonSize or 40)
        if want then button:Show() else button:Hide() end
    end
end
function Log:ResetButton()
    ns.db.logButtonPos = nil
    if button then PlaceButton() end
end

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
    page, lastCast = 1, nil
    self:Refresh()
end

-- settings changed (on/off, size, button)
function Log:Apply()
    self:ApplyButton()
    if not ns.db.logEnabled then self:Hide() return end
    if win and win:IsShown() then Place() end
end
