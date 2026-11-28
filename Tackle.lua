-- Rubber Ducky: the tackle wheel. A ship's wheel of slices, in pages (LB/RB,
-- or the mouse wheel): Fishing has the lures in your bags (pick one and it goes
-- on your pole) plus Mrrl's shop, Professions and Ducky's Challenges; Camp has
-- the campfire, Forever's camp pieces and the fish foods that boost fishing. Opens from /ducky tackle, a macro (/click
-- RubberDuckyTackleButton) or the tackle box on the fishing log; out of combat
-- only, for now (putting a lure on is something the game guards in combat).
-- Mouse: point and click. Controller: the right stick points, A picks, B closes.

local _, ns = ...
local Tackle = {}
ns.Tackle = Tackle

local DIR = ns.MEDIA .. "Tackle\\"
local SIZE = 400                 -- the wheel on screen
local F = SIZE / 340             -- everything below was laid out at 340
local SLICES = 8
local RING = 99 * F              -- slice centres, from the hub
local SLOT = 62 * F              -- a slice's clickable middle
local ICON = 34 * F              -- a lure's icon
local BIG_ICON = 50 * F          -- Mrrl's and the challenges: their own pictures, no words
local MH = 16                    -- lures go on the main hand: the pole
local HUB = 96 * F               -- the duck in the middle, drawn on its own for the animation
local POINTER_R, POINTER = 56 * F, 34 * F -- the pointer: how far out from the middle, and its size

-- Forever's lures (item id, fishing bonus, skill needed), from Wowhead's Forever
-- fishing guide. Ones you don't carry don't show; ones above your skill are greyed.
Tackle.LURES = {
    { 6529, 25, 1 },     -- Shiny Bauble
    { 6530, 50, 50 },    -- Nightcrawlers
    { 6811, 50, 50 },    -- Aquadynamic Fish Lens
    { 291005, 60, 50 },  -- Camper's Lure
    { 6532, 75, 100 },   -- Bright Baubles
    { 7307, 75, 100 },   -- Flesh Eating Worm
    { 6533, 100, 100 },  -- Aquadynamic Fish Attractor
}
local MAX_LURES = 4
-- the camp page: the campfire, Forever's camp pieces (put out at a campfire),
-- and the fish foods that boost fishing (item id, bonus)
Tackle.CAMPFIRE = 818 -- Basic Campfire (the old spell; Forever's fires are kits in your bags)
-- Forever's campfire kits, best first
Tackle.KITS = { 279974, 279961, 279981 } -- Expert, Journeyman, Basic Campfire Kit
-- every profession's camp features, put out at a campfire (people carry
-- different ones for different jobs); fishing's first
Tackle.CAMP = {
    279967, 279965, 279966, -- Fishing: Fish Bowl, Fishing Rack, Fishing Hut
    279957, 279982,         -- Cooking: Cookie's Feast, Iron Oven
    279956, 279970, 279990, -- Alchemy: Mana Well, Fermenter, Alchemy Laboratory
    279944, 279988, 279955, -- Blacksmithing: Sharpening Wheel, Anvil, Master Forge
    279976, 279985, 279987, -- Enchanting: Enchanted Lute, Arcane Salvager, Arcane Forge
    279950, 279949, 279989, -- Engineering: Reagent Bot, Repair Bot, Anarchist's Workbench
    279962, 279964, 279947, -- Herbalism: Incense Candle, Greenhouse, Seed Hybridizer
    279978, 279941, 279945, -- Leatherworking: Camp Tent, Tanning Rack, Sewing Machine
    279960, 279948, 279952, -- Mining: Lodestone, Rock Garden, Molten Foundry
    279979, 279969, 279938, -- Skinning: Camp Chair, Field Guide, Trapper's Workbench
    279973, 279943, 279959, -- Tailoring: Faction Banner, Spinning Wheel, Loom
    279968, 279940, 279951, -- First Aid: First Aid Kit, Toxin Study, Plague Doctor's Laboratory
}
Tackle.FOODS = {
    { 6316, 3 }, { 5476, 5 }, { 4593, 8 }, { 4594, 12 }, { 13930, 18 }, { 8957, 18 },
}
-- where things sit round the wheel (slice 0 is the top, going clockwise): on
-- the Fishing page: Mrrl's, the journal and the challenges along the bottom,
-- Professions on the left; lures round the top, best first
local SHOP_SLICE, BOOK_SLICE, CHAL_SLICE, PROF_SLICE = 3, 4, 5, 6
local LURE_SLICES = { 7, 0, 1, 2 }
local PAGES = { "Fishing", "Camp" }
local page = 1

local function UsingPad() return ns.OneKey and ns.OneKey.GamepadUIOn and ns.OneKey.GamepadUIOn() end
local wheel, lit, plaque, slots, closeBtn
-- the parchment under the wheel: big enough for what you're pointing at and,
-- on a controller, the buttons along its bottom (the art is 99 high)
local PLAQUE_W, PLAQUE_H = 460, 110
local PQ = PLAQUE_H / 99
local selected
local content = {} -- slice -> { kind = "lure" | "food" | "camp" | "fire" | "shop" | "prof" | "challenges" | "journal", id, bonus, count, low }

local function Count(id)
    local get = C_Item and C_Item.GetItemCount or GetItemCount
    return ns.Safe(get, id) or 0
end
local function ItemName(id)
    local n = C_Item and C_Item.GetItemNameByID and ns.Safe(C_Item.GetItemNameByID, id)
    if not n and GetItemInfo then n = ns.Safe(GetItemInfo, id) end
    return n or "A lure"
end
local function SpellName(id)
    local n = C_Spell and C_Spell.GetSpellName and ns.Safe(C_Spell.GetSpellName, id)
    if not n and GetSpellInfo then n = ns.Safe(GetSpellInfo, id) end
    return n or "Basic Campfire"
end
local function SpellIcon(id)
    local i = C_Spell and C_Spell.GetSpellTexture and ns.Safe(C_Spell.GetSpellTexture, id)
    if not i and GetSpellTexture then i = ns.Safe(GetSpellTexture, id) end
    return i or 135805
end
-- the campfire kits you carry, best first: { id, count }
function Tackle.Kits()
    local list = {}
    for _, id in ipairs(Tackle.KITS) do
        local n = Count(id)
        if n > 0 then list[#list + 1] = { id = id, count = n } end
    end
    return list
end

local function Knows(id)
    if IsPlayerSpell and ns.Safe(IsPlayerSpell, id) then return true end
    return IsSpellKnown and ns.Safe(IsSpellKnown, id) or false
end
local function ItemIcon(id)
    local i = C_Item and C_Item.GetItemIconByID and ns.Safe(C_Item.GetItemIconByID, id)
    if not i and GetItemIcon then i = ns.Safe(GetItemIcon, id) end
    return i or 134335
end

-- what's in your bags right now, best first (ones you can use before ones you can't)
local function MySkill()
    local r = ns.Rank and ns.Rank.Skill and ns.Rank.Skill()
    return r
end
function Tackle.Lures()
    local list, skill = {}, MySkill()
    for _, l in ipairs(Tackle.LURES) do
        local n = Count(l[1])
        if n > 0 then
            list[#list + 1] = { id = l[1], bonus = l[2], need = l[3], count = n, low = skill ~= nil and skill < l[3] }
        end
    end
    table.sort(list, function(a, b)
        if a.low ~= b.low then return not a.low end
        return a.bonus > b.bonus
    end)
    while #list > MAX_LURES do table.remove(list) end
    return list
end
function Tackle.Foods()
    local list = {}
    for _, f in ipairs(Tackle.FOODS) do
        local n = Count(f[1])
        if n > 0 then list[#list + 1] = { id = f[1], bonus = f[2], count = n } end
    end
    table.sort(list, function(a, b) return a.bonus > b.bonus end)
    return list
end

-- the lure on your pole now, and how long it has left
local function PoleLine()
    if not (ns.Gear and ns.Gear.PoleEquipped()) then return "Put your fishing pole on first.", true end
    local has, ms = ns.Safe(GetWeaponEnchantInfo)
    if has and ms then
        local min = math.ceil(ms / 60000)
        return ("On your pole now: a lure, %d min left."):format(min)
    end
    return "No lure on your pole."
end

-- the game's own button for the Professions window (or the spellbook, where
-- professions live in it)
function Tackle.ProfButton()
    for _, n in ipairs({ "ProfessionMicroButton", "SpellbookMicroButton" }) do
        if _G[n] then return _G[n] end
    end
end

local function Point(i) -- a slice's centre, from the wheel's middle
    local a = math.rad(i * (360 / SLICES))
    return math.sin(a) * RING, math.cos(a) * RING
end

local function Paint()
    if not wheel then return end
    local c = selected and content[selected]
    if c then
        local a = math.rad(selected * (360 / SLICES))
        lit:SetRotation(-a)
        lit:Show()
        -- the gold pointer at the hub's edge, aiming at it
        wheel.pointer:ClearAllPoints()
        wheel.pointer:SetPoint("CENTER", wheel, "CENTER", math.sin(a) * POINTER_R, math.cos(a) * POINTER_R)
        wheel.pointer:SetRotation(-a)
        wheel.pointer:Show()
    else
        lit:Hide()
        wheel.pointer:Hide()
    end
    local title, sub, warn = "", "", false
    if not c then
        if PAGES[page] == "Camp" then title = "Nothing for camp in your bags"
        else title = #Tackle.Lures() == 0 and "No lures in your bags" or "Pick a lure" end
    elseif c.kind == "lure" then
        title = ("%s  |cff2e7d1e+%d fishing|r"):format(ItemName(c.id), c.bonus)
        if c.nopole then
            sub, warn = "Put your fishing pole on first.", true
        elseif c.low then
            sub, warn = ("Needs %d Fishing (you have %d)."):format(c.need, MySkill() or 0), true
        else
            sub, warn = PoleLine()
        end
    elseif c.kind == "food" then
        title = ("%s  |cff2e7d1e+%d fishing|r"):format(ItemName(c.id), c.bonus)
        sub = "Eat it for a fishing boost."
    elseif c.kind == "camp" then
        title, sub = ItemName(c.id), "Set it up at a campfire."
    elseif c.kind == "fire" then
        title, sub = c.id and ItemName(c.id) or SpellName(Tackle.CAMPFIRE), "Light a fire to make camp."
    elseif c.kind == "shop" then
        title = "Mrrl's Doohickey Emporium"
    elseif c.kind == "journal" then
        title = "Fishing Journal"
    elseif c.kind == "prof" then
        title = "Professions"
    else
        title = "Ducky's Challenges"
    end
    plaque.title:SetText(title)
    plaque.sub:SetText(sub)
    plaque.sub:SetTextColor(warn and 0.6 or 0.35, warn and 0.15 or 0.24, 0.08)
    for i = 0, SLICES - 1 do
        local s = slots[i]
        s.hl:SetShown(i == selected and content[i] ~= nil)
    end
    -- which page: a dot for each
    for i, d in ipairs(plaque.dots) do
        d:SetTexture(i == page and "Interface\\COMMON\\Indicator-Yellow" or "Interface\\COMMON\\Indicator-Gray")
    end
    plaque.page:SetText(PAGES[page])
    -- a controller: A presses the slice it points at, the bumpers turn the page, B closes
    if wheel:IsShown() and not InCombatLockdown() then
        ClearOverrideBindings(wheel)
        SetOverrideBindingClick(wheel, true, "PAD2", "RubberDuckyTackleClose", "LeftButton")
        SetOverrideBindingClick(wheel, true, "PADLSHOULDER", "RubberDuckyTacklePrev", "LeftButton")
        SetOverrideBindingClick(wheel, true, "PADRSHOULDER", "RubberDuckyTackleNext", "LeftButton")
        if c and not c.low then SetOverrideBindingClick(wheel, true, "PAD1", slots[selected]:GetName(), "LeftButton") end
    end
    if UsingPad() then
        local function Glyph(btn)
            local g = ns.OneKey.Glyph(btn, 22)
            if g:sub(1, 1) == "[" then g = g:sub(2, -2) end -- no picture: just the name
            return g
        end
        -- A is always there; it fades when there's nothing it can do
        local verb = ({ lure = "Put it on", food = "Eat", camp = "Set up", fire = "Light" })[c and c.kind or ""] or "Open"
        local can = c and not c.low
        local INK = "|cff452914"
        local k = plaque.keys
        k[1]:SetText(Glyph("PAD1") .. " " .. INK .. verb .. "|r")
        k[1]:SetAlpha(can and 1 or 0.35)
        k[2]:SetText(Glyph("PADLSHOULDER") .. Glyph("PADRSHOULDER") .. " " .. INK .. "Page|r")
        k[3]:SetText(Glyph("PAD2") .. " " .. INK .. "Close|r")
        -- side by side, the row centred
        local GAP, total = 26, 0
        for i = 1, 3 do total = total + (k[i]:GetStringWidth() or 0) end
        total = total + GAP * 2
        k[1]:ClearAllPoints(); k[1]:SetPoint("BOTTOMLEFT", plaque, "BOTTOM", -total / 2, 22 * PQ)
        k[2]:ClearAllPoints(); k[2]:SetPoint("LEFT", k[1], "RIGHT", GAP, 0)
        k[3]:ClearAllPoints(); k[3]:SetPoint("LEFT", k[2], "RIGHT", GAP, 0)
        for i = 1, 3 do k[i]:Show() end
    else
        for i = 1, 3 do plaque.keys[i]:Hide() end
    end
end

function Tackle.Select(i)
    if i == selected then return end
    selected = i
    if ns.UI then ns.UI.Sound("tick") end
    Paint()
end

-- fill the slices for the page you're on (out of combat: they're secure buttons)
local function Fill()
    content = {}
    if PAGES[page] == "Fishing" then
        content[SHOP_SLICE] = { kind = "shop" }
        content[PROF_SLICE] = { kind = "prof" }
        content[CHAL_SLICE] = { kind = "challenges" }
        content[BOOK_SLICE] = { kind = "journal" }
        -- a lure only goes on a pole in your hands: without one they can't be picked
        local nopole = not (ns.Gear and ns.Gear.PoleEquipped())
        for k, l in ipairs(Tackle.Lures()) do
            content[LURE_SLICES[k]] = { kind = "lure", id = l.id, bonus = l.bonus, count = l.count, need = l.need,
                low = l.low or nopole, nopole = nopole }
        end
    else
        -- the campfire on top, then the camp pieces you carry, then foods, round the wheel
        local list = {}
        local kits = Tackle.Kits()
        for _, k in ipairs(kits) do list[#list + 1] = { kind = "fire", id = k.id, count = k.count } end
        if #kits == 0 and Knows(Tackle.CAMPFIRE) then list[#list + 1] = { kind = "fire" } end
        for _, id in ipairs(Tackle.CAMP) do
            local n = Count(id)
            if n > 0 then list[#list + 1] = { kind = "camp", id = id, count = n } end
        end
        for _, f in ipairs(Tackle.Foods()) do list[#list + 1] = { kind = "food", id = f.id, bonus = f.bonus, count = f.count } end
        for k = 1, math.min(#list, SLICES) do content[k - 1] = list[k] end
    end
    for i = 0, SLICES - 1 do
        local s, c = slots[i], content[i]
        s.icon:SetShown(c ~= nil)
        -- items sit over their numbers; Mrrl's, Professions and the challenges fill the slice
        local big = c and (c.kind == "shop" or c.kind == "challenges" or c.kind == "prof" or c.kind == "journal")
        s.icon:SetSize(big and BIG_ICON or ICON, big and BIG_ICON or ICON)
        s.icon:ClearAllPoints()
        s.icon:SetPoint("CENTER", 0, big and 0 or 8 * F)
        s.icon:SetDesaturated(c and c.low or false)
        s.icon:SetAlpha(c and c.low and 0.6 or 1)
        s.count:SetText(""); s.bonus:SetText(""); s.label:SetText("")
        s:SetAttribute("type", nil); s:SetAttribute("item", nil); s:SetAttribute("spell", nil)
        s:SetAttribute("target-slot", nil); s:SetAttribute("macrotext", nil); s:SetAttribute("clickbutton", nil)
        if c and c.id then -- an item from your bags (lures, foods, camp pieces, campfire kits)
            s.icon:SetTexture(ItemIcon(c.id))
            s.count:SetText(c.count and c.count > 1 and c.count or "")
            if c.bonus then s.bonus:SetText("+" .. c.bonus) end
            if not c.low then
                if c.kind == "lure" then
                    -- the lure, then the pole: the same two lines as the classic
                    -- lure macro, which this client always follows through on
                    -- (the button's own "use it on a slot" step was left hanging)
                    s:SetAttribute("type", "macro")
                    s:SetAttribute("macrotext", "/use item:" .. c.id .. "\n/use " .. MH)
                else
                    s:SetAttribute("type", "item")
                    s:SetAttribute("item", "item:" .. c.id)
                end
            end
        elseif c and c.kind == "fire" then
            s.icon:SetTexture(SpellIcon(Tackle.CAMPFIRE))
            s:SetAttribute("type", "spell")
            s:SetAttribute("spell", Tackle.CAMPFIRE)
        elseif c then
            -- Professions: a secure click on the game's own Professions button, so
            -- the game opens it. Opened from our code it would carry our mark, and
            -- anything protected done through it afterwards gets blocked.
            if c.kind == "prof" then
                local b = Tackle.ProfButton()
                if b then s:SetAttribute("type", "click"); s:SetAttribute("clickbutton", b) end
            end
            s.icon:SetTexture(c.kind == "shop" and (DIR .. "icon_shop") or c.kind == "prof" and "Interface\\Icons\\Trade_Fishing"
                or c.kind == "journal" and (ns.MEDIA .. "Journal\\button")
                or (DIR .. "icon_challenges"))
        end
    end
end

-- the first slice worth pointing at: your best lure on Fishing, the first thing on Camp
local function FirstPick()
    if PAGES[page] == "Fishing" then
        for _, i in ipairs(LURE_SLICES) do if content[i] and not content[i].low then return i end end
        return nil
    end
    for i = 0, SLICES - 1 do if content[i] then return i end end
end

function Tackle.Page(dir)
    if not (wheel and wheel:IsShown()) or InCombatLockdown() then return end
    page = (page - 1 + dir) % #PAGES + 1
    Fill()
    selected = FirstPick()
    if wheel.spin then wheel.spin:Stop(); wheel.spin:Play() end
    if ns.UI then ns.UI.Sound("page") end
    Paint()
end

-- a lure's gone on: the duck boings, with the swirl and sparkles over it
local function Sparkle()
    if not wheel then return end
    if wheel.cheer then wheel.cheer:Stop(); wheel.cheer:Play() end
    wheel.swirl.anim:Stop(); wheel.swirl.anim:Play()
    if ns.Glint then ns.Glint(wheel.hub, 14, 1.0, 1.4) end
end
local CHEER = 0.85 -- how long the wheel waits for it before tucking away

local function Build()
    wheel = CreateFrame("Frame", "RubberDuckyTackle", UIParent)
    wheel:SetSize(SIZE, SIZE)
    wheel:SetFrameStrata("DIALOG")
    wheel:SetClampedToScreen(true)
    wheel:EnableMouse(true)
    wheel:Hide()
    tinsert(UISpecialFrames, "RubberDuckyTackle") -- Escape closes it

    local art = wheel:CreateTexture(nil, "ARTWORK")
    art:SetAllPoints()
    art:SetTexture(DIR .. "wheel")
    lit = wheel:CreateTexture(nil, "ARTWORK", nil, 2)
    lit:SetAllPoints()
    lit:SetTexture(DIR .. "wheel_lit")
    lit:SetBlendMode("BLEND")
    lit:Hide()

    -- a few ornaments: a shell and waves at the bottom
    local function Orn(file, w, h, point, x, y, layer)
        local t = wheel:CreateTexture(nil, layer or "OVERLAY")
        t:SetTexture(DIR .. file)
        t:SetSize(w, h)
        t:SetPoint("CENTER", wheel, point, x, y)
        return t
    end
    Orn("wave", 74 * F, 74 * F, "BOTTOMLEFT", 40 * F, 34 * F)
    Orn("wave2", 50 * F, 50 * F, "BOTTOMRIGHT", -44 * F, 30 * F)
    Orn("shell", 54 * F, 54 * F, "BOTTOM", 0, 6 * F)

    wheel.pointer = wheel:CreateTexture(nil, "OVERLAY", nil, 4)
    wheel.pointer:SetTexture(DIR .. "pointer")
    wheel.pointer:SetSize(POINTER, POINTER)
    wheel.pointer:Hide()

    -- the hub, for the sparkle when you pick something
    wheel.hub = CreateFrame("Frame", nil, wheel)
    wheel.hub:SetSize(120, 120)
    wheel.hub:SetPoint("CENTER")
    wheel.hub:SetFrameLevel(wheel:GetFrameLevel() + 12)
    local swirl = wheel.hub:CreateTexture(nil, "OVERLAY")
    swirl:SetTexture(DIR .. "swirl")
    swirl:SetBlendMode("ADD")
    swirl:SetSize(110, 110)
    swirl:SetPoint("CENTER")
    swirl:SetAlpha(0)
    local ag = swirl:CreateAnimationGroup()
    local a1 = ag:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.15); a1:SetOrder(1)
    local r1 = ag:CreateAnimation("Rotation"); r1:SetDegrees(-200); r1:SetDuration(0.7); r1:SetOrder(1)
    local a2 = ag:CreateAnimation("Alpha"); a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetDuration(0.5); a2:SetOrder(2)
    swirl.anim = ag
    wheel.swirl = swirl

    slots = {}
    for i = 0, SLICES - 1 do
        local s = CreateFrame("Button", "RubberDuckyTackleSlot" .. i, wheel, "SecureActionButtonTemplate")
        s:SetSize(SLOT, SLOT)
        local x, y = Point(i)
        s:SetPoint("CENTER", wheel, "CENTER", x, y)
        s:SetFrameLevel(wheel:GetFrameLevel() + 5)
        -- the press and the release both, like the game's own buttons: which one acts
        -- follows the "cast on key press" option, and listening to only one could
        -- leave a lure's second step (putting it on the pole) undone
        s:RegisterForClicks("AnyUp", "AnyDown")
        s.icon = s:CreateTexture(nil, "ARTWORK")
        s.icon:SetSize(ICON, ICON)
        s.icon:SetPoint("CENTER", 0, 8 * F)
        s.hl = s:CreateTexture(nil, "OVERLAY")
        s.hl:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        s.hl:SetBlendMode("ADD")
        s.hl:SetAllPoints(s.icon)
        s.hl:Hide()
        s.count = s:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        s.count:SetPoint("BOTTOMRIGHT", s.icon, "BOTTOMRIGHT", 2, -1)
        s.bonus = s:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        s.bonus:SetPoint("TOP", s.icon, "BOTTOM", 0, -2)
        s.bonus:SetTextColor(0.18, 0.49, 0.12)
        s.bonus:SetShadowOffset(0, 0)
        s.label = s:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        s.label:SetPoint("TOP", s.icon, "BOTTOM", 0, -2)
        s.label:SetTextColor(0.35, 0.22, 0.08)
        s.label:SetShadowOffset(0, 0)
        s:SetScript("OnEnter", function() Tackle.Select(i) end)
        -- after the click: a lure's gone on (the secure part did that), or open
        -- Mrrl's or the challenges; then the wheel closes
        local last = 0
        s:HookScript("OnClick", function()
            -- the press and the release are one pick
            local now = GetTime()
            if now - last < 0.4 then return end
            last = now
            local c = content[i]
            if not c then return end
            if c.low then return end
            if c.kind == "lure" or c.kind == "food" or c.kind == "camp" or c.kind == "fire" then
                Sparkle()
                if ns.UI then ns.UI.Sound("shopBought") end
                C_Timer.After(CHEER, function() Tackle:Close() end)
            elseif c.kind == "prof" then
                Tackle:Close() -- the secure click has opened it
            elseif c.kind == "shop" then
                Tackle:Close()
                if ns.Shop then ns.Shop:Show() end
            elseif c.kind == "journal" then
                Tackle:Close()
                if ns.Journal then ns.Journal:Show() end
            else
                Tackle:Close()
                if ns.ChallengesWindow then ns.ChallengesWindow:Show() end
            end
        end)
        slots[i] = s
    end

    -- under the wheel: what you're pointing at, and what's on your pole
    -- (the art scales with its height; PQ is that scale, for placing things on it)
    plaque = CreateFrame("Frame", nil, wheel)
    plaque:SetSize(PLAQUE_W, PLAQUE_H)
    plaque:SetPoint("TOP", wheel, "BOTTOM", 0, 6)
    if ns.UI and ns.UI.Stretch then ns.UI.Stretch(plaque, "strip_parch", "BACKGROUND") end
    plaque.title = plaque:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    plaque.title:SetPoint("TOP", 0, -23 * PQ)
    plaque.title:SetTextColor(0.27, 0.16, 0.08)
    plaque.title:SetShadowOffset(0, 0)
    plaque.sub = plaque:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    plaque.sub:SetPoint("TOP", plaque.title, "BOTTOM", 0, -4)
    plaque.sub:SetShadowOffset(0, 0)

    -- B (and a macro, or Escape) closes it
    closeBtn = CreateFrame("Button", "RubberDuckyTackleClose", wheel)
    closeBtn:SetScript("OnClick", function() Tackle:Close() end)

    -- pages: the bumpers, the mouse wheel, or the arrows at the parchment's ends
    local function Arrow(name, dir, point, x, art)
        local b = CreateFrame("Button", name, plaque)
        b:SetSize(26, 26)
        b:SetPoint("CENTER", plaque, point, x, 0)
        b:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Up")
        b:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-" .. art .. "-Down")
        b:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        b:SetScript("OnClick", function() Tackle.Page(dir) end)
        return b
    end
    Arrow("RubberDuckyTacklePrev", -1, "LEFT", 44 * PQ, "PrevPage")
    Arrow("RubberDuckyTackleNext", 1, "RIGHT", -44 * PQ, "NextPage")
    wheel:EnableMouseWheel(true)
    wheel:SetScript("OnMouseWheel", function(_, d) Tackle.Page(d > 0 and -1 or 1) end)
    -- the page's name on the wooden rail along the top, a dot for each page after it
    plaque.page = plaque:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    plaque.page:SetPoint("CENTER", plaque, "TOP", -(#PAGES * 7), -11 * PQ)
    plaque.page:SetTextColor(1, 0.86, 0.5)
    plaque.dots = {}
    for i = 1, #PAGES do
        local d = plaque:CreateTexture(nil, "OVERLAY")
        d:SetSize(12, 12)
        d:SetPoint("LEFT", plaque.page, "RIGHT", 2 + (i - 1) * 12, 0)
        plaque.dots[i] = d
    end
    -- turning the page: the wheel gives an eighth of a turn (it looks the same
    -- an eighth round, so it settles back without a jump)
    local spin = art:CreateAnimationGroup()
    local r = spin:CreateAnimation("Rotation"); r:SetDegrees(-45); r:SetDuration(0.22); r:SetSmoothing("OUT")
    wheel.spin = spin

    -- with the Gamepad UI on: the buttons along the bottom of the parchment
    -- (white text, so the button pictures keep their own colours; the words are
    -- inked brown in the text itself)
    plaque.keys = {}
    for i = 1, 3 do
        local f = plaque:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f:SetTextColor(1, 1, 1)
        f:SetShadowOffset(0, 0)
        f:Hide()
        plaque.keys[i] = f
    end

    -- the right stick points at a slice, like the game's own wheels. The wheel
    -- takes the sticks while it's open, so pointing doesn't turn the camera
    -- (the game can't take just the one, so you stand still for that moment;
    -- addons can't turn its camera speed below 0.1, which still drifts)
    pcall(wheel.EnableGamePadStick, wheel, true)
    local function Aim(x, y)
        if not (x and y) or (x * x + y * y) < 0.3 * 0.3 then return end
        local deg = math.deg(math.atan2(x, y)) % 360
        local best, bestD
        for i = 0, SLICES - 1 do
            if content[i] then
                local d = math.abs(((deg - i * (360 / SLICES)) + 180) % 360 - 180)
                if not bestD or d < bestD then best, bestD = i, d end
            end
        end
        if best then Tackle.Select(best) end
    end
    Tackle.Aim = Aim
    pcall(wheel.SetScript, wheel, "OnGamePadStick", function(_, stick, x, y)
        if stick == "Right" or stick == "Camera" then Aim(x, y) end
    end)
    wheel:SetScript("OnUpdate", function()
        if not (C_GamePad and C_GamePad.GetDeviceMappedState) then return end
        local ok, st = pcall(C_GamePad.GetDeviceMappedState, C_GamePad.GetActiveDeviceID and C_GamePad.GetActiveDeviceID() or nil)
        local l = ok and type(st) == "table" and type(st.sticks) == "table" and st.sticks[2]
        if type(l) == "table" then Aim(l.x, l.y) end
    end)
    wheel:SetScript("OnHide", function()
        if not InCombatLockdown() then ClearOverrideBindings(wheel) end
        if wheel.leave then for _, g in ipairs(wheel.leave) do g:Stop() end end
        wheel.leaving = false
        if wheel.duck then wheel.duck:Hide() end
        wheel:SetAlpha(1)
        if ns.UI then ns.UI.Sound("tackleClose") end
    end)

    -- The duck on its own, over the wheel's hub: it pops up first and the wheel
    -- springs out from behind it; going, the wheel tucks back in behind the
    -- duck and the duck pops away. (Its own frame, so the wheel's growing and
    -- shrinking doesn't move it.)
    local duck = CreateFrame("Frame", "RubberDuckyTackleDuck", UIParent)
    duck:SetSize(HUB, HUB)
    duck:SetPoint("CENTER", wheel, "CENTER")
    duck:SetFrameStrata("DIALOG")
    duck:SetFrameLevel(wheel:GetFrameLevel() + 30)
    duck:EnableMouse(false)
    duck:Hide()
    local dt = duck:CreateTexture(nil, "ARTWORK")
    dt:SetAllPoints()
    dt:SetTexture(DIR .. "hub")
    wheel.duck = duck
    -- the swirl and sparkles when you pick something go over the duck
    wheel.hub:SetParent(duck)
    wheel.hub:ClearAllPoints()
    wheel.hub:SetPoint("CENTER", duck, "CENTER")
    wheel.hub:SetFrameLevel(duck:GetFrameLevel() + 2)

    local function Scale(g, from, to, dur, order, smooth, delay)
        local a = g:CreateAnimation("Scale")
        a:SetScaleFrom(from, from); a:SetScaleTo(to, to)
        a:SetDuration(dur); a:SetOrder(order); a:SetSmoothing(smooth or "NONE")
        if delay then a:SetStartDelay(delay) end
        return a
    end
    local function Fade(g, from, to, dur, order, delay)
        local a = g:CreateAnimation("Alpha")
        a:SetFromAlpha(from); a:SetToAlpha(to); a:SetDuration(dur); a:SetOrder(order)
        if delay then a:SetStartDelay(delay) end
        return a
    end
    -- in: the duck boings up...
    local duckIn = duck:CreateAnimationGroup()
    Scale(duckIn, 0.2, 1.22, 0.14, 1, "OUT"); Fade(duckIn, 0, 1, 0.1, 1)
    Scale(duckIn, 1.22, 0.92, 0.08, 2, "IN_OUT")
    Scale(duckIn, 0.92, 1, 0.07, 3, "IN_OUT")
    -- ...and the wheel springs out from behind it, overshoots and settles
    local wheelIn = wheel:CreateAnimationGroup()
    wheelIn:SetToFinalAlpha(true)
    Scale(wheelIn, 0.25, 1.08, 0.17, 1, "OUT", 0.12); Fade(wheelIn, 0, 1, 0.1, 1, 0.12)
    Scale(wheelIn, 1.08, 0.96, 0.08, 2, "IN_OUT")
    Scale(wheelIn, 0.96, 1, 0.07, 3, "IN_OUT")
    -- out: the wheel tucks in behind the duck...
    local wheelOut = wheel:CreateAnimationGroup()
    wheelOut:SetToFinalAlpha(true)
    Scale(wheelOut, 1, 0.25, 0.14, 1, "IN"); Fade(wheelOut, 1, 0, 0.12, 1)
    -- ...then the duck gives a little hop and pops away
    local duckOut = duck:CreateAnimationGroup()
    duckOut:SetToFinalAlpha(true)
    Scale(duckOut, 1, 1.15, 0.06, 1, "OUT", 0.11)
    Scale(duckOut, 1.15, 0.2, 0.1, 2, "IN"); Fade(duckOut, 1, 0, 0.1, 2)
    duckOut:SetScript("OnFinished", function()
        duck:Hide()
        if not InCombatLockdown() then wheel:Hide() end
    end)
    -- a lure on: the same boing the duck pops up with, a little bigger
    local cheer = duck:CreateAnimationGroup()
    Scale(cheer, 1, 1.3, 0.12, 1, "OUT")
    Scale(cheer, 1.3, 0.9, 0.1, 2, "IN_OUT")
    Scale(cheer, 0.9, 1.06, 0.08, 3, "IN_OUT")
    Scale(cheer, 1.06, 1, 0.07, 4, "IN_OUT")
    wheel.cheer = cheer
    wheel.come = { duckIn, wheelIn }
    wheel.leave = { wheelOut, duckOut }
    function wheel:Come()
        for _, g in ipairs(self.leave) do g:Stop() end
        duck:SetAlpha(1); duck:Show()
        self:SetAlpha(0)
        for _, g in ipairs(self.come) do g:Stop(); g:Play() end
    end
    function wheel:Leave()
        if self.leaving then return end
        self.leaving = true
        for _, g in ipairs(self.come) do g:Stop() end
        if self.cheer then self.cheer:Stop() end
        for _, g in ipairs(self.leave) do g:Play() end
    end
    wheel:HookScript("OnShow", function(self) self.leaving = false end)
end


function Tackle:IsShown() return wheel ~= nil and wheel:IsShown() end

function Tackle:Open()
    if InCombatLockdown() then
        ns.Chat("Not mid-fight! The tackle wheel opens once the fight's over.")
        return false
    end
    if not wheel then Build() end
    page = 1
    Fill()
    -- start on the lure you're most likely after: your best one
    selected = FirstPick()
    wheel:ClearAllPoints()
    if UsingPad() then
        wheel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    else
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale() or 1
        wheel:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
    end
    wheel:Show()
    wheel:Come()
    if ns.UI then ns.UI.Sound("tackleOpen") end
    Paint()
    return true
end

function Tackle:Close(now)
    if not (wheel and wheel:IsShown()) or InCombatLockdown() then return end
    -- B and the macro don't do anything more while it goes
    ClearOverrideBindings(wheel)
    if now then wheel:Hide() return end
    wheel:Leave()
end

function Tackle:Toggle()
    if self:IsShown() then self:Close() else self:Open() end
end

-- a fight starting closes it, while it still can; bags changing refills it
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:SetScript("OnEvent", function(_, event)
    if not (wheel and wheel:IsShown()) then return end
    if event == "PLAYER_REGEN_DISABLED" then wheel:Hide(); return end -- at once: no time for a fade
    if not InCombatLockdown() then Fill(); Paint() end
end)

-- for macros and bars: /click RubberDuckyTackleButton
local macro = CreateFrame("Button", "RubberDuckyTackleButton", UIParent)
macro:SetScript("OnClick", function() Tackle:Toggle() end)

-- a macro to drag onto an action bar
Tackle.MACRO_ICON = "Interface\\Icons\\INV_G_FishingBobber_05" -- the rubber duck bobber
function Tackle:PickupMacro() ns.PickupMacro("Lures", Tackle.MACRO_ICON, "/ducky tackle", "tackle wheel") end

-- for tests
function Tackle.State() return { selected = selected, content = content, slots = slots, wheel = wheel, page = PAGES[page], plaque = plaque } end
