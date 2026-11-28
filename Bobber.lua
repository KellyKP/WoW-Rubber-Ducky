-- Rubber Ducky: bobber sparkle and marker. Soft targeting gives the bobber a
-- nameplate (within ~10 yards in Forever); both are anchored to it. Nameplates
-- can't be measured here (restricted), so the position is never read.

local _, ns = ...
local Bobber = {}
ns.Bobber = Bobber

-------------------------------------------------------------------------------
-- Soft-target cvars, only while fishing
-------------------------------------------------------------------------------

local CVARS = {
    SoftTargetInteract          = "3",
    SoftTargetIconGameObject    = "1",
    SoftTargetIconInteract      = "1",
    SoftTargetNameplateInteract = "1",
    SoftTargetInteractRange     = "30",
}

local pendingRestore = false

function Bobber:ApplyCVars()
    local db = ns.db
    if not db.softTargetHelp or db.savedCVars then return end
    if InCombatLockdown() then return end
    local saved = {}
    for cvar in pairs(CVARS) do
        local v = ns.Safe(GetCVar, cvar)
        if v ~= nil then saved[cvar] = v end
    end
    db.savedCVars = saved
    for cvar, value in pairs(CVARS) do
        if saved[cvar] ~= nil then ns.Safe(SetCVar, cvar, value) end
    end
end

function Bobber:RestoreCVars()
    local saved = ns.db and ns.db.savedCVars
    if not saved then return end
    if InCombatLockdown() then pendingRestore = true return end
    for cvar, value in pairs(saved) do ns.Safe(SetCVar, cvar, value) end
    ns.db.savedCVars = nil
    pendingRestore = false
end

function Bobber:FlushPending()
    if pendingRestore and not ns.sessionActive then self:RestoreCVars() end
end

function Bobber:RecoverFromCrash()
    if ns.db.savedCVars then self:RestoreCVars() end
end

-------------------------------------------------------------------------------
-- Sparkle: stars twinkling at random spots and moments
-------------------------------------------------------------------------------

local sparkle = CreateFrame("Frame", "RubberDuckyBobberSparkle", UIParent)
sparkle:SetFrameStrata("BACKGROUND")
sparkle:SetSize(90, 90)
sparkle:Hide()

local SPARKS = 14
local AMOUNT = { 5, 8, 14 } -- subtle, normal, lots
local COLORS = {
    { 1.00, 1.00, 1.00 },   -- white
    { 1.00, 0.92, 0.55 },   -- pale gold
    { 0.65, 0.90, 1.00 },   -- pale water blue
    { 1.00, 0.97, 0.80 },   -- warm white
}
local sparkling = false
local sparks = {}

local function PlaceSpark(s)
    local size = ns.db.sparkleSpread or 90
    local r = (size / 2) * math.sqrt(math.random()) * 0.9 -- even spread
    local a = math.random() * 2 * math.pi
    s.tex:ClearAllPoints()
    s.tex:SetPoint("CENTER", sparkle, "CENTER", math.cos(a) * r, math.sin(a) * r * 0.75) -- flattened, like on water
    local px = (8 + math.random() * 14) * math.max(0.6, size / 90)
    s.tex:SetSize(px, px)
    local c = COLORS[math.random(#COLORS)]
    s.tex:SetVertexColor(c[1], c[2], c[3])
end

local function Twinkle(s)
    if not sparkling then return end
    PlaceSpark(s)
    C_Timer.After(math.random() * 0.7, function()
        if sparkling then s.anim:Play() end
    end)
end

for i = 1, SPARKS do
    local tex = sparkle:CreateTexture(nil, "OVERLAY")
    tex:SetTexture("Interface\\Cooldown\\star4")
    tex:SetBlendMode("ADD")
    tex:SetAlpha(0)
    local anim = tex:CreateAnimationGroup()
    local fadeIn = anim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.25); fadeIn:SetOrder(1)
    local grow = anim:CreateAnimation("Scale")
    grow:SetScaleFrom(0.2, 0.2); grow:SetScaleTo(1, 1); grow:SetDuration(0.25); grow:SetOrder(1)
    grow:SetSmoothing("OUT")
    local turn = anim:CreateAnimation("Rotation")
    turn:SetDegrees(-90); turn:SetDuration(0.65); turn:SetOrder(1)
    local rise = anim:CreateAnimation("Translation")
    rise:SetOffset(0, 5); rise:SetDuration(0.65); rise:SetOrder(1)
    local fadeOut = anim:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetStartDelay(0.05)
    fadeOut:SetDuration(0.35); fadeOut:SetOrder(2)
    local shrink = anim:CreateAnimation("Scale")
    shrink:SetScaleFrom(1, 1); shrink:SetScaleTo(0.4, 0.4); shrink:SetStartDelay(0.05)
    shrink:SetDuration(0.35); shrink:SetOrder(2)
    local s = { tex = tex, anim = anim }
    anim:SetScript("OnFinished", function() tex:SetAlpha(0); Twinkle(s) end)
    sparks[i] = s
end

local function StartSparkle()
    local size = ns.db.sparkleSpread or 90
    sparkle:SetSize(size, size)
    sparkle:Show()
    if sparkling then return end
    sparkling = true
    local n = AMOUNT[ns.db.sparkleAmount or 2] or 8
    for i, s in ipairs(sparks) do
        if i <= n then Twinkle(s) else s.anim:Stop(); s.tex:SetAlpha(0) end
    end
end

local function HideSparkle()
    sparkling = false
    for _, s in ipairs(sparks) do s.anim:Stop(); s.tex:SetAlpha(0) end
    sparkle:Hide()
    sparkle:ClearAllPoints()
end

-- A short burst of the same stars over any part of the interface (the New!
-- badges): ns.Glint(region, count, seconds). Safe to call again while running.
function ns.Glint(region, count, seconds, scale) -- scale: bigger stars (default 1)
    if not (region and region.GetParent) then return end
    local f = region.rdGlint
    if not f then
        local parent = region.GetObjectType and region:GetObjectType() == "Texture" and region:GetParent() or region
        f = CreateFrame("Frame", nil, parent)
        f:SetAllPoints(region)
        f:SetFrameLevel((parent.GetFrameLevel and parent:GetFrameLevel() or 1) + 6)
        f.sparks = {}
        region.rdGlint = f
    end
    f:Show()
    local untilT = GetTime() + (seconds or 1.2)
    local w, h = region:GetWidth() or 40, region:GetHeight() or 20
    for i = 1, count or 4 do
        local s = f.sparks[i]
        if not s then
            local tex = f:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\Cooldown\\star4")
            tex:SetBlendMode("ADD")
            tex:SetAlpha(0)
            local anim = tex:CreateAnimationGroup()
            local a1 = anim:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.2); a1:SetOrder(1)
            local g = anim:CreateAnimation("Scale"); g:SetScaleFrom(0.2, 0.2); g:SetScaleTo(1, 1); g:SetDuration(0.2); g:SetOrder(1)
            local r = anim:CreateAnimation("Rotation"); r:SetDegrees(-90); r:SetDuration(0.5); r:SetOrder(1)
            local a2 = anim:CreateAnimation("Alpha"); a2:SetFromAlpha(1); a2:SetToAlpha(0); a2:SetDuration(0.3); a2:SetOrder(2)
            s = { tex = tex, anim = anim }
            f.sparks[i] = s
        end
        local function Again()
            if GetTime() > f.untilT then s.tex:SetAlpha(0); return end
            s.tex:ClearAllPoints()
            s.tex:SetPoint("CENTER", f, "CENTER", (math.random() - 0.5) * f.w, (math.random() - 0.5) * f.h)
            local px = (7 + math.random() * 9) * (f.scale or 1)
            s.tex:SetSize(px, px)
            local c = COLORS[math.random(#COLORS)]
            s.tex:SetVertexColor(c[1], c[2], c[3])
            C_Timer.After(math.random() * 0.35, function() s.anim:Play() end)
        end
        s.anim:SetScript("OnFinished", function() s.tex:SetAlpha(0); Again() end)
        f.untilT, f.w, f.h, f.scale = untilT, w, h, scale
        if not s.anim:IsPlaying() then Again() end
    end
end

function Bobber:RefreshSparkle()
    if not sparkling then return end
    sparkling = false
    for _, sp in ipairs(sparks) do sp.anim:Stop(); sp.tex:SetAlpha(0) end
    StartSparkle()
end


-------------------------------------------------------------------------------
-- Marker: the bobber icon above your bobber
-------------------------------------------------------------------------------

Bobber.MARKERS = {
    -- price = on Mrrl's shelf, for that many Shiny Fishbones; earn = the
    -- challenge that finds it for you; the rest are always yours
    { "classic",     "Classic Red" },   { "cork",       "Cork" },
    { "pencil",      "Pencil Float" },  { "bluestripe", "Blue Stripes" },
    { "alliance",    "Alliance" },      { "horde",      "Horde" },
    { "feather",     "Feathered" },     { "greenglass", "Green Glass" },
    { "arcane",      "Arcane", price = 80 },
    { "molten",      "Molten", price = 80 },
    { "frost",       "Frost", price = 80 },
    { "leafy",       "Leafy" },
    { "sweetheart",  "Sweetheart" },    { "fish",       "Fish" },
    { "duck",        "Rubber Duck" },
    { "crab",        "Crab", price = 60 },
    { "keg",         "Keg", price = 60 },
    { "sharkfin",    "Shark Fin", price = 90 },
    { "glowlantern", "Glowing Orb", price = 70 },
    { "moonlit",     "Moonlit", price = 70 },
    { "tentacle",    "Tentacle", price = 90 },
    { "skull",       "Skull", price = 90 },
    { "lifering",    "Life Ring", price = 50 },
    { "lantern",     "Lantern" },
    -- a third value is a dedication, shown under the name in the picker,
    -- with an optional fourth: a small logo (Media/Logos/<name>.tga) after it
    { "frog",        "Froggy", "For mollpies", "twitch" },
    { "murloc",      "Murloc", price = 100 },
    { "otter",       "Otter", price = 100 },
    { "pipi",        "Pipi" },
    { "thrall",      "Thrall", price = 150 },
    { "jaina",       "Jaina", price = 150 },
    { "rumbottle",     "Rum Bottle",          price = 60 },
    { "treasurechest", "Treasure Chest",      earn = "treasure2" },
    { "oldboot",       "Old Boot",            earn = "junk2" },
    { "goldenduck",    "Golden Duck",         earn = "fish3" },
    { "compass",       "Compass",             earn = "tour3" },
    { "bottlemessage", "Message in a Bottle", price = 70 },
    { "clover",        "Four-Leaf Clover",    price = 80 },
    { "hourglass",     "Hourglass",           price = 80 },
    { "trophy",        "Trophy",              price = 100 },
    { "owl",           "Night Owl",           price = 90 },
    { "rooster",       "Rooster",             price = 90 },
    { "trophyfish",    "Trophy Fish",         price = 120 },
}

-- A line of lore for every bobber, in the picker: where it turned up
Bobber.LORE = {
    classic = "The one every angler starts with. Red side up, mostly.",
    cork = "Pulled from a wine bottle in Stormwind. The wine didn't last.",
    pencil = "A gnome's design: long, thin and wildly over-engineered.",
    bluestripe = "Painted by a Menethil dockhand with leftover boat paint.",
    alliance = "Lion-blue and proud. Floats best in Alliance waters, apparently.",
    horde = "Forged in Orgrimmar. It bobs aggressively.",
    feather = "A gryphon lost a feather. A fisher found a float.",
    greenglass = "Old Kul Tiran glass, worn smooth by a hundred tides.",
    arcane = "Hums faintly. Dalaran swears it isn't theirs.",
    molten = "Fished out of Searing Gorge. Still warm, somehow.",
    frost = "Carved from Winterspring ice. Never quite melts.",
    leafy = "Woven by a druid who wanted the fish to feel at home.",
    sweetheart = "Somebody's love note, sealed in a float. Shh.",
    fish = "A fish shaped like a float, or a float shaped like a fish. Nobody knows.",
    duck = "Ducky! The very best bobber. No bias here.",
    crab = "Snatched it right off the line and then just... stayed.",
    keg = "From a Thunderbrew barrel. The ale went first, naturally.",
    sharkfin = "Clears a lake out fast. Fish are rightly nervous.",
    glowlantern = "Glows softly through the night. Moths adore it.",
    moonlit = "Catches the moonlight on Lake Elune'ara.",
    tentacle = "Found it in Darkshore. Best not to ask what it's attached to.",
    skull = "A pirate's lucky charm. Luckier for the fish, it turns out.",
    lifering = "Off a Booty Bay ship. Saved a gnome, once.",
    lantern = "Lights the way for night fishing on the Barrens' oases.",
    frog = "A happy little frog, ribbiting along on the ripples.",
    murloc = "Mrglglgl! Traded for a shiny button.",
    otter = "Floats on its back, holding a tiny pebble. Adorable.",
    pipi = "Pipi came to fish and stayed for the company.",
    thrall = "Steady as the Warchief himself. Very serious about fishing.",
    jaina = "A little Kul Tiran charm. Wind and waves at her command.",
    rumbottle = "Found with the third Rumsey Rum. Somebody's party ran out of bottles.",
    treasurechest = "Every treasure in the water, and this was the last one at the bottom.",
    oldboot = "The one boot that got away, back for its laces.",
    goldenduck = "Every fish in the book, and Ducky's very proudest gift: gold.",
    compass = "Thirty zones later, it always points to the next good spot.",
    bottlemessage = "The message inside just says: \"keep fishing.\"",
    clover = "Three treasures in a row? That's no accident. Keep this close.",
    hourglass = "Four hours of fishing, and every grain of sand well spent.",
    trophy = "Three hundred catches in one sitting. Polished and well earned.",
    owl = "Hooted from a branch past midnight until you noticed it.",
    rooster = "Crows at dawn, right when the fish start biting.",
    trophyfish = "Fifty pounds, tag and all. Nobody back home believed it.",
}

-- yours: always, bought from Mrrl, or earned from a challenge (Flair.lua)
function Bobber.Unlocked(i)
    local m = Bobber.MARKERS[i]
    if not m then return false end
    if not m.earn and not m.price then return true end
    local F = ns.Flair
    local ok, have = pcall(function() return F and F.Owns(F.Get("bobber", m[1])) end)
    return ok and have or false
end

local marker = CreateFrame("Frame", "RubberDuckyBobberMarker", UIParent)
marker:SetFrameStrata("LOW")
marker:Hide()
local markerTex = marker:CreateTexture(nil, "ARTWORK")
markerTex:SetAllPoints()

local float = markerTex:CreateAnimationGroup()
float:SetLooping("BOUNCE")
local up = float:CreateAnimation("Translation")
up:SetOffset(0, 6); up:SetDuration(0.9); up:SetSmoothing("IN_OUT")
local pop = marker:CreateAnimationGroup()
local grow = pop:CreateAnimation("Scale")
grow:SetScaleFrom(0.3, 0.3); grow:SetScaleTo(1, 1); grow:SetDuration(0.2); grow:SetSmoothing("OUT")
local fadeIn = pop:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.2)

local function PickMarker()
    local style = ns.db.markerStyle or 0
    if style >= 1 and not Bobber.Unlocked(style) then style = 15 end -- not yours (yet): the duck
    if style < 1 or style > #Bobber.MARKERS then
        -- random: from the ones you have
        local have = {}
        for i = 1, #Bobber.MARKERS do if Bobber.Unlocked(i) then have[#have + 1] = i end end
        style = have[math.random(#have)] or 15
    end
    markerTex:SetTexture(ns.BobberArt(Bobber.MARKERS[style][1]))
end

local function ShowMarker(anchor, relPoint, yOff)
    local w = ns.db.markerSize or 56
    marker:SetSize(w, w)
    marker:ClearAllPoints()
    marker:SetPoint("BOTTOM", anchor, relPoint, 0, yOff)
    marker:Show()
    pop:Stop(); pop:Play()
    float:Play()
end

local function HideMarker()
    marker:Hide(); float:Stop(); pop:Stop()
    marker:ClearAllPoints()
end

-- icon picked or switched on/off: show the change on the live bobber too
function Bobber:RefreshMarker()
    -- your bobber hangs on your quarterboard too
    if ns.Flair and ns.Flair.Changed then ns.Flair.Changed() end
    if not ns.db.markerEnabled then HideMarker() return end
    if marker:IsShown() then PickMarker()
    elseif ns.fishing and self.Attach then self:Attach() end
end

-------------------------------------------------------------------------------
-- Following the bobber's nameplate
-------------------------------------------------------------------------------

local bobberGUID, plateToken, softChangedAt = nil, nil, 0
local anchorBlocked = false -- the game refused the anchor; don't retry

local function IsGameObject(guid)
    return type(guid) == "string" and not ns.IsSecret(guid) and guid:find("^GameObject") ~= nil
end

local function Note(msg)
    if ns.Probe then ns.Probe:Sample("bobber", msg) end
end

function Bobber:Attach()
    local db = ns.db
    if not ns.fishing or anchorBlocked or not plateToken then return end
    if not db.sparkleEnabled and not db.markerEnabled then return end
    local plate = ns.Safe(C_NamePlate.GetNamePlateForUnit, plateToken)
    if not plate then Note("no nameplate frame for " .. plateToken) return end
    local ok, err = pcall(function()
        if db.sparkleEnabled then
            sparkle:ClearAllPoints()
            sparkle:SetPoint("CENTER", plate, "CENTER", 0, db.sparkleOffsetY or 0)
        end
        if db.markerEnabled then
            marker:ClearAllPoints()
            marker:SetPoint("BOTTOM", plate, "CENTER", 0, (db.sparkleOffsetY or 0) + (db.markerOffsetY or -20))
        end
    end)
    if ok then
        if db.sparkleEnabled then StartSparkle() end
        if db.markerEnabled then
            PickMarker()
            ShowMarker(plate, "CENTER", (db.sparkleOffsetY or 0) + (db.markerOffsetY or -20))
        end
        Note("sparkle/marker anchored to " .. plateToken)
    else
        anchorBlocked = true
        HideSparkle(); HideMarker()
        Note("anchor refused: " .. tostring(err))
        ns.Print("Forever won't let Rubber Ducky attach the sparkle or icon to the bobber. The game's own soft-target icon over the bobber still shows.")
    end
end

function Bobber:OnSoftInteractChanged(_, newGUID)
    if not ns.fishing then return end
    if IsGameObject(newGUID) then
        if newGUID ~= bobberGUID then plateToken = nil end
        bobberGUID = newGUID
        softChangedAt = GetTime()
        if not plateToken then self:FindPlateToken() end
    end
end

function Bobber:OnPlateAdded(token)
    if not ns.fishing or not bobberGUID then return end
    local guid = ns.Safe(UnitGUID, token)
    if guid == bobberGUID or (guid == nil and GetTime() - softChangedAt < 0.5) then
        plateToken = token
        self:Attach()
    end
end

function Bobber:OnPlateRemoved(token)
    if token == plateToken then
        plateToken = nil
        HideSparkle(); HideMarker()
    end
end

function Bobber:FindPlateToken()
    if not bobberGUID then return end
    for i = 1, 40 do
        local token = "nameplate" .. i
        local guid = ns.Safe(UnitGUID, token)
        if guid and guid == bobberGUID then
            plateToken = token
            self:Attach()
            return
        end
    end
end

function Bobber:StartTracking()
    bobberGUID, plateToken = nil, nil
end

function Bobber:StopTracking()
    bobberGUID, plateToken = nil, nil
    HideSparkle(); HideMarker()
end

function Bobber:Preview()
    sparkle:ClearAllPoints()
    sparkle:SetPoint("CENTER", UIParent, "CENTER", 0, -60)
    if ns.db.sparkleEnabled then StartSparkle() end
    if ns.db.markerEnabled then
        PickMarker()
        ShowMarker(sparkle, "CENTER", ns.db.markerOffsetY or -20)
    end
    C_Timer.After(4, function() if not ns.fishing then HideSparkle(); HideMarker() end end)
end
