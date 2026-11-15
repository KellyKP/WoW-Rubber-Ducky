-- Rubber Ducky: catch splash (banner + loot) and miss splash.

local _, ns = ...
local Splash = {}
ns.Splash = Splash

local MEDIA = "Interface\\AddOns\\RubberDucky\\Media\\"
Splash.BANNERS = {
    { "fishon", "Fish On!" }, { "hooked", "Hooked!" }, { "gotone", "Got One!" }, { "yoink", "Yoink!" },
}
local MAX_ROWS = 5
local ROW_H = 38
local ROW_TOP = 262 -- just under the banner art

local frame, bannerHolder, banner, rows, more
local startTime, holdFor, lastBanner

local function QualityColor(q)
    if q and C_Item and C_Item.GetItemQualityColor then
        local ok, r, g, b = pcall(C_Item.GetItemQualityColor, q)
        if ok and r then return r, g, b end
    end
    local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

-- left/right texture pair: transparent at the ends, alpha a in the middle
function Splash.Band(pair, cr, cg, cb, a)
    local l, rr = pair[1], pair[2]
    l:SetColorTexture(1, 1, 1, 1); rr:SetColorTexture(1, 1, 1, 1)
    local ok = pcall(function()
        l:SetGradient("HORIZONTAL", CreateColor(cr, cg, cb, 0), CreateColor(cr, cg, cb, a))
        rr:SetGradient("HORIZONTAL", CreateColor(cr, cg, cb, a), CreateColor(cr, cg, cb, 0))
    end)
    if not ok then -- no gradients: flat
        l:SetColorTexture(cr, cg, cb, a * 0.6); rr:SetColorTexture(cr, cg, cb, a * 0.6)
    end
end

local function Ease(t) return 1 - (1 - t) * (1 - t) end

local function Build()
    if frame then return end
    frame = CreateFrame("Frame", "RubberDuckySplash", UIParent)
    frame:SetSize(520, 480)
    frame:SetFrameStrata("HIGH")
    frame:EnableMouse(false)
    frame:Hide()

    -- own frame so it can be scaled for the pop
    bannerHolder = CreateFrame("Frame", nil, frame)
    bannerHolder:SetSize(512, 256)
    bannerHolder:SetPoint("CENTER", frame, "TOP", 0, -128)
    banner = bannerHolder:CreateTexture(nil, "ARTWORK")
    banner:SetAllPoints()

    rows = {}
    for i = 1, MAX_ROWS do
        local r = CreateFrame("Frame", nil, frame)
        r:SetSize(440, ROW_H)
        r:SetPoint("TOP", frame, "TOP", 0, -ROW_TOP - (i - 1) * (ROW_H + 4))
        -- rarity band: dark base, coloured wash, bright 1px edges
        -- edge: nil = full height, "TOP" / "BOTTOM" = 1px line
        local function Pair(layer, sub, edge)
            local l = r:CreateTexture(nil, layer, nil, sub)
            local rr = r:CreateTexture(nil, layer, nil, sub)
            if edge then
                l:SetPoint(edge .. "LEFT"); l:SetPoint(edge .. "RIGHT", r, edge)
                rr:SetPoint(edge .. "RIGHT"); rr:SetPoint(edge .. "LEFT", r, edge)
                l:SetHeight(1); rr:SetHeight(1)
            else
                l:SetPoint("TOPLEFT"); l:SetPoint("BOTTOMRIGHT", r, "BOTTOM")
                rr:SetPoint("TOPRIGHT"); rr:SetPoint("BOTTOMLEFT", r, "BOTTOM")
            end
            return { l, rr }
        end
        r.base = Pair("BACKGROUND", 0)
        r.wash = Pair("BACKGROUND", 1)
        r.edges = { Pair("BORDER", 0, "TOP"), Pair("BORDER", 0, "BOTTOM") }
        Splash.Band(r.base, 0, 0, 0, 0.6)
        r.icon = r:CreateTexture(nil, "ARTWORK")
        r.icon:SetSize(ROW_H - 4, ROW_H - 4)
        r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        r.text = r:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        r.text:SetShadowOffset(1, -1)
        r:Hide()
        rows[i] = r
    end
    more = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    more:SetShadowOffset(1, -1)

    frame:SetScript("OnUpdate", function(self) Splash:Animate() end)
end

function Splash:Animate()
    local t = GetTime() - startTime
    local fadeOut = 0.45
    -- slam in big, overshoot small, settle
    local s, a
    if t < 0.14 then
        local k = Ease(t / 0.14)
        s, a = 1.9 - 1.0 * k, k
    elseif t < 0.26 then
        s, a = 0.9 + 0.1 * Ease((t - 0.14) / 0.12), 1
    else
        s, a = 1, 1
    end
    local shake = 0
    if t > 0.12 and t < 0.4 then shake = math.sin(t * 90) * 6 * (0.4 - t) / 0.28 end
    bannerHolder:SetScale(math.max(s, 0.01))
    bannerHolder:ClearAllPoints()
    bannerHolder:SetPoint("CENTER", frame, "TOP", shake / s, -128 / s)
    bannerHolder:SetAlpha(a)

    for i, r in ipairs(rows) do
        if r:IsShown() then
            local k = math.min(1, math.max(0, (t - 0.22 - i * 0.07) / 0.2))
            r:SetAlpha(Ease(k))
            r:ClearAllPoints()
            r:SetPoint("TOP", frame, "TOP", 0, -ROW_TOP - (i - 1) * (ROW_H + 4) - (1 - Ease(k)) * 14)
        end
    end
    more:SetAlpha(math.min(1, math.max(0, (t - 0.6) / 0.2)))

    if t > holdFor then
        local k = math.min(1, (t - holdFor) / fadeOut)
        frame:SetAlpha(1 - k)
        frame:ClearAllPoints()
        frame:SetPoint("TOP", UIParent, "CENTER", 0, (ns.db.splashY or 200) + 210 + 20 * k)
        if k >= 1 then frame:Hide() end
    end
end

local function PickBanner()
    local list = Splash.BANNERS
    local pick = ns.db.splashBanner or 0
    if pick >= 1 and pick <= #list then return pick end
    -- random, never the same twice in a row
    local i = math.random(#list)
    if i == lastBanner and #list > 1 then i = i % #list + 1 end
    lastBanner = i
    return i
end

function Splash.PlaySound()
    if ns.db.splashCatchSound then
        pcall(PlaySound, (SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST) or 31578, "SFX")
    end
end

-- items: list of { icon, name, count, quality }
function Splash:Show(items)
    if not ns.db.splashEnabled then return end
    if not pcall(Build) or not frame then return end
    items = items or {}
    local idx = PickBanner()
    banner:SetTexture(MEDIA .. "splash_" .. Splash.BANNERS[idx][1])

    local shown = math.min(#items, MAX_ROWS)
    if #items > MAX_ROWS then shown = MAX_ROWS - 1 end
    for i, r in ipairs(rows) do
        local it = items[i]
        if it and i <= shown then
            r.icon:SetTexture(it.icon or 134400)
            local name = it.name or "?"
            if it.count and it.count > 1 then name = name .. " |cffffffffx" .. it.count .. "|r" end
            r.text:SetText(name)
            -- rarity in the band, white text
            local q = it.quality
            local cr, cg, cb
            if q and q >= 0 then cr, cg, cb = QualityColor(q) else cr, cg, cb = 1, 0.82, 0 end -- coins
            local strong = (q or 1) >= 2 or not q -- softer for common/poor
            Splash.Band(r.wash, cr, cg, cb, strong and 0.45 or 0.18)
            for _, e in ipairs(r.edges) do Splash.Band(e, cr, cg, cb, strong and 0.95 or 0.4) end
            if q == 0 then r.text:SetTextColor(0.75, 0.75, 0.75) else r.text:SetTextColor(1, 1, 1) end
            local w = math.min(r.text:GetStringWidth() or 0, 380)
            r.icon:ClearAllPoints()
            r.icon:SetPoint("LEFT", r, "CENTER", -(w + ROW_H + 2) / 2, 0)
            r.text:ClearAllPoints()
            r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
            r:SetAlpha(0)
            r:Show()
        else
            r:Hide()
        end
    end
    more:ClearAllPoints()
    more:SetPoint("TOP", frame, "TOP", 0, -ROW_TOP - shown * (ROW_H + 4) - 2)
    more:SetText(#items > shown and ("+ " .. (#items - shown) .. " more") or "")

    frame:SetScale(ns.db.splashSize or 0.7)
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "CENTER", 0, (ns.db.splashY or 200) + 210)
    frame:SetAlpha(1)
    startTime = GetTime()
    holdFor = ns.db.splashDuration or 3
    Splash.PlaySound()
    frame:Show()
    Splash:Animate()
end

-- call before looting
function Splash.ReadLoot()
    local items = {}
    local n = ns.Safe(GetNumLootItems) or 0
    for i = 1, n do
        local ok, icon, name, count, currencyID, quality = pcall(GetLootSlotInfo, i)
        if ok and name and not (issecretvalue and issecretvalue(name)) then
            -- coin names already include the amount
            local isCoin = ns.Safe(GetLootSlotType, i) == (LOOT_SLOT_MONEY or 2)
            if isCoin then name = name:gsub("\n", " "); count = 0 end
            items[#items + 1] = { icon = icon, name = name, count = tonumber(count) or 0, quality = quality }
        end
    end
    return items
end

function Splash:Preview()
    self:Show({
        { icon = "Interface\\Icons\\INV_Misc_Fish_02", name = "Raw Brilliant Smallfish", count = 3, quality = 1 },
        { icon = "Interface\\Icons\\INV_Misc_Bag_10", name = "Waterlogged Satchel", count = 1, quality = 2 },
        { icon = "Interface\\Icons\\INV_Helmet_31", name = "Lucky Fishing Hat", count = 1, quality = 3 },
        { icon = "Interface\\Icons\\INV_Misc_Coin_03", name = "12 Silver", count = 0 },
    })
end

-------------------------------------------------------------------------------
-- Misses
-------------------------------------------------------------------------------
-- art, hint, SOUNDKIT names (first one this client has)
Splash.MISSES = {
    timeout = { "miss_timeout", "Seems you fell asleep.", { "IG_QUEST_LOG_ABANDON_QUEST", "IG_MAINMENU_CLOSE" } },
    missed  = { "miss_away",    "You missed that one, try again!",       { "IG_QUEST_FAILED", "IG_QUEST_LOG_ABANDON_QUEST" } },
}

local function MissSound(names)
    if not ns.db.splashMissSound or not SOUNDKIT then return end
    for _, n in ipairs(names) do
        local id = SOUNDKIT[n]
        if id then pcall(PlaySound, id, "SFX"); return end
    end
end

local miss, missStart
local MISS_HOLD, MISS_FADE = 2.2, 0.4

local function BuildMiss()
    if miss then return end
    miss = CreateFrame("Frame", "RubberDuckyMiss", UIParent)
    miss:SetSize(512, 300)
    miss:SetFrameStrata("HIGH")
    miss:EnableMouse(false)
    miss:Hide()
    miss.art = miss:CreateTexture(nil, "ARTWORK")
    miss.art:SetSize(512, 256)
    miss.art:SetPoint("TOP")
    miss.sub = miss:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    miss.sub:SetPoint("TOP", miss.art, "BOTTOM", 0, 2)
    miss.sub:SetTextColor(0.9, 0.9, 0.9)
    miss.sub:SetShadowOffset(2, -2)
    miss:SetScript("OnUpdate", function() Splash:AnimateMiss() end)
end

function Splash:AnimateMiss()
    local t = GetTime() - missStart
    -- drop in, one bounce, sink away
    local y
    if t < 0.22 then
        local k = t / 0.22
        y = 40 * (1 - k * k)
        miss:SetAlpha(math.min(1, k * 1.5))
    elseif t < 0.4 then
        y = 8 * math.sin((t - 0.22) / 0.18 * math.pi)
        miss:SetAlpha(1)
    else
        y = 0
    end
    if t > MISS_HOLD then
        local k = math.min(1, (t - MISS_HOLD) / MISS_FADE)
        y = -18 * k
        miss:SetAlpha(1 - k)
        if k >= 1 then miss:Hide() end
    end
    miss:ClearAllPoints()
    miss:SetPoint("TOP", UIParent, "CENTER", 0, (ns.db.splashY or 200) + 210 + y)
end

function Splash:ShowMiss(kind)
    if not ns.db.splashMisses then return end
    local text = Splash.MISSES[kind] or Splash.MISSES.missed
    if not pcall(BuildMiss) or not miss then return end
    if frame and frame:IsShown() then return end -- catch splash showing
    miss.art:SetTexture(MEDIA .. "splash_" .. text[1])
    miss.sub:SetText(text[2])
    MissSound(text[3])
    miss:SetScale(ns.db.splashSize or 0.7)
    missStart = GetTime()
    miss:Show()
    Splash:AnimateMiss()
end

function Splash:PreviewMiss()
    local kinds = { "missed", "timeout" }
    self.previewMissIndex = (self.previewMissIndex or 0) % #kinds + 1
    local was = ns.db.splashMisses
    ns.db.splashMisses = true
    self:ShowMiss(kinds[self.previewMissIndex])
    ns.db.splashMisses = was
end
