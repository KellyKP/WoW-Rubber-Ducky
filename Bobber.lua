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
    { "classic",     "Classic Red" },   { "cork",       "Cork" },
    { "pencil",      "Pencil Float" },  { "bluestripe", "Blue Stripes" },
    { "alliance",    "Alliance" },      { "horde",      "Horde" },
    { "feather",     "Feathered" },     { "greenglass", "Green Glass" },
    { "arcane",      "Arcane" },        { "molten",     "Molten" },
    { "frost",       "Frost" },         { "leafy",      "Leafy" },
    { "sweetheart",  "Sweetheart" },    { "fish",       "Fish" },
    { "duck",        "Rubber Duck" },   { "crab",       "Crab" },
    { "keg",         "Keg" },           { "sharkfin",   "Shark Fin" },
    { "glowlantern", "Glowing Orb" },   { "moonlit",    "Moonlit" },
    { "tentacle",    "Tentacle" },      { "skull",      "Skull" },
    { "lifering",    "Life Ring" },     { "lantern",    "Lantern" },
}

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
    if style < 1 or style > #Bobber.MARKERS then style = math.random(#Bobber.MARKERS) end
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
