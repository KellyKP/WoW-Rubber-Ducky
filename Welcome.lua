-- Rubber Ducky: welcome screen, shown once after the first login.

local ADDON, ns = ...
local Welcome = {}
ns.Welcome = Welcome

local UI = ns.UI
local dialog

local panels = {}

-- one line under "What I do", like the settings' feature list: an icon in a
-- tile, its name, and a short line
local function Feature(card, icon, name, text, crop)
    local y = card:Advance(42)
    local tile = UI.IconTile(card.frame, 36, icon, crop)
    tile:SetPoint("TOPLEFT", 18, y + 2)
    local n = card.frame:CreateFontString(nil, "OVERLAY", UI.FONT.bold)
    n:SetPoint("TOPLEFT", tile, "TOPRIGHT", 10, -3)
    n:SetPoint("RIGHT", card.frame, "RIGHT", -20, 0); n:SetJustifyH("LEFT"); n:SetWordWrap(false)
    n:SetText(name)
    local d = card.frame:CreateFontString(nil, "OVERLAY", UI.FONT.soft)
    d:SetPoint("TOPLEFT", n, "BOTTOMLEFT", 0, -3)
    d:SetPoint("RIGHT", card.frame, "RIGHT", -20, 0); d:SetJustifyH("LEFT"); d:SetWordWrap(false)
    d:SetText(text)
end

-- closed by one of its own buttons: that button already made a sound
local function Close()
    ns.db.seenWelcome = true
    dialog.quiet = true
    dialog:Hide()
    dialog.quiet = nil
end

-- the two sections end level with each other
local evening = false
local function Even()
    if evening then return end
    evening = true
    local h = 0
    for _, p in ipairs(panels) do
        p:Refresh()
        for _, c in ipairs(p.cards) do h = math.max(h, c:Height()) end
    end
    for _, p in ipairs(panels) do
        for _, c in ipairs(p.cards) do c.frame:SetHeight(h) end
    end
    evening = false
end

local function Build()
    local SW = ns.SettingsWindow
    dialog = SW.Chrome("RubberDuckyWelcome", nil, { sign = "welcome", height = 560, strata = "DIALOG" })
    dialog:ClearAllPoints()
    dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    dialog:SetScript("OnHide", function(self)
        ns.db.seenWelcome = true
        if not self.quiet then UI.Sound("welcomeClose") end
    end)
    dialog:SetScript("OnShow", function(self)
        -- always in the middle of the screen
        self:ClearAllPoints(); self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        UI.Sound("welcomeOpen")
    end)

    -- everything inside the frame, a touch bigger like the settings window
    local W, H = dialog:GetWidth() or SW.SIZE[1], dialog:GetHeight() or 560
    local L, T, R, B = unpack(dialog.inner)
    local k = SW.TEXT_SCALE
    local inner = CreateFrame("Frame", nil, dialog)
    inner:SetScale(k)
    inner:SetPoint("TOPLEFT", dialog, "TOPLEFT", L / k, -T / k)
    local iw, ih = (W - L - R) / k, (H - T - B) / k
    inner:SetSize(iw, ih)
    inner:SetFrameLevel((dialog:GetFrameLevel() or 1) + 5)

    -- a line from Ducky under the sign
    local sub = inner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sub:SetPoint("TOP", inner, "TOP", 0, -4)
    sub:SetText("Rubber Ducky makes fishing in Azeroth a little nicer.")

    -- two sections side by side
    local gap, top, bottom = 14, 28, 58
    local cw = (iw - gap) / 2
    local function Column(x)
        local f = CreateFrame("Frame", nil, inner)
        f:SetPoint("TOPLEFT", inner, "TOPLEFT", x, -top)
        f:SetSize(cw, ih - top - bottom)
        local p = UI.NewPanel(f)
        panels[#panels + 1] = p
        return p
    end
    local left, right = Column(0), Column(cw + gap)

    local what = left:Card("What I do")
    Feature(what, "Interface\\Icons\\INV_Misc_Drum_01", "Hear the splash", "Everything else fades to a mumble.")
    Feature(what, ns.DUCK, "See your bobber", "Sparkles and a duck mark the spot.", false)
    Feature(what, "Interface\\Icons\\INV_Misc_Spyglass_03", "A closer look", "The camera eases toward the water.")
    Feature(what, "Interface\\Icons\\INV_Fishingpole_02", "One button", "Cast and reel with a single key.")
    Feature(what, "Interface\\Icons\\INV_Misc_Fish_02", "Celebrate your catch", "A splash shows what you caught.")
    Feature(what, ns.MEDIA .. "Journal\\button", "Keep a log and journal", "Every catch, written down.", false)

    local setup = right:Card("Let's set you up")
    local y = setup:Advance(62)
    local bobTile = UI.IconTile(setup.frame, 56, nil, false)
    bobTile:SetPoint("TOPLEFT", 18, y + 2)
    local bob = bobTile.icon
    local bobName = setup.frame:CreateFontString(nil, "OVERLAY", UI.FONT.ink)
    bobName:SetPoint("TOPLEFT", bobTile, "TOPRIGHT", 10, -4)
    local choose = UI.Button(setup.frame, "Choose bobber", 160, function() ns.Picker:Show() end, { height = 36 })
    choose:SetPoint("TOPLEFT", bobName, "BOTTOMLEFT", -6, -4)
    right:OnRefresh(function()
        local list = ns.Bobber.MARKERS
        local style = ns.db.markerStyle or 15
        local shown = (style >= 1 and style <= #list) and style or (ns.db.lastStyle or 15)
        bob:SetTexture(ns.BobberArt(list[shown][1]))
        bobName:SetText("Your bobber: |cff4a2a10" .. (style >= 1 and list[shown][2] or "random each cast") .. "|r")
    end)
    -- the triggers as the controller's own pictures
    setup:Choice{ label = "One-button fishing", key = "oneKeyButton", labelW = 150,
        onChange = function() ns.OneKey:Update() end,
        options = function()
            local I = ns.OneKey.TriggerIcon
            return { { 4, "Interact" }, { 6, I("left", 22) }, { 5, I("right", 22) } }
        end }
    setup:Advance(4)
    -- two by two, to leave room above the frame's bottom for the buttons
    setup:Toggle{ label = "Auto loot", key = "autoLootFishing" }
    setup:Toggle{ label = "Catch splash", key = "splashEnabled", column = 2 }
    setup:Toggle{ label = "Sound focus", key = "focusEnabled" }
    setup:Toggle{ label = "Fishing camera", key = "cameraEnabled", column = 2 }
    -- refreshing one section re-evens both
    right:OnRefresh(function() if not evening then C_Timer.After(0, Even) end end)

    -- off you go
    local settings = UI.Button(inner, "Open settings", 180, function()
        Close()
        UI.Later(function() if ns.Options then ns.Options:Open() end end)
    end, { height = 44 })
    settings:SetPoint("BOTTOMRIGHT", inner, "BOTTOM", -8, 4)
    local fish = UI.Button(inner, "Let's fish!", 180, Close, { height = 44 })
    fish:SetPoint("BOTTOMLEFT", inner, "BOTTOM", 8, 4)
    Welcome.panels = panels
    Welcome.area = { iw, ih - top - bottom }
    Welcome.pad = ns.Pad.Attach(dialog, { roots = function() return { inner } end, close = Close })
end

function Welcome:Show()
    if not dialog then Build() end
    dialog:Show()
    Even()
end

function Welcome:Refresh()
    if dialog and dialog:IsShown() then Even() end
end

function Welcome:MaybeShowFirstTime()
    if ns.db.seenWelcome then return false end
    C_Timer.After(3, function()
        if not ns.db.seenWelcome and not InCombatLockdown() then Welcome:Show() end
    end)
    return true
end
