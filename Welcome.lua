-- Rubber Ducky: welcome screen, shown once after the first login.

local ADDON, ns = ...
local Welcome = {}
ns.Welcome = Welcome

local UI = ns.UI
local MEDIA = "Interface\\AddOns\\RubberDucky\\Media\\"
local dialog, page

local function Feature(card, icon, name, text, crop)
    local y = card:Advance(38)
    local tex = card.frame:CreateTexture(nil, "ARTWORK")
    tex:SetSize(26, 26)
    tex:SetPoint("TOPLEFT", 14, y)
    tex:SetTexture(icon)
    if crop ~= false then tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
    local n = card.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    n:SetPoint("TOPLEFT", tex, "TOPRIGHT", 10, 0)
    n:SetText(name)
    local d = card.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    d:SetPoint("TOPLEFT", n, "BOTTOMLEFT", 0, -3)
    d:SetJustifyH("LEFT")
    d:SetText(text)
end

local function Close()
    ns.db.seenWelcome = true
    dialog:Hide()
end

local function Build()
    dialog = CreateFrame("Frame", "RubberDuckyWelcome", UIParent, "BackdropTemplate")
    dialog:SetSize(580, 680)
    dialog:SetPoint("CENTER", 0, 20)
    dialog:SetFrameStrata("DIALOG")
    dialog:SetToplevel(true)
    dialog:SetMovable(true); dialog:EnableMouse(true); dialog:SetClampedToScreen(true)
    dialog:RegisterForDrag("LeftButton")
    dialog:SetScript("OnDragStart", dialog.StartMoving)
    dialog:SetScript("OnDragStop", dialog.StopMovingOrSizing)
    dialog:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 28,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    dialog:Hide()
    tinsert(UISpecialFrames, "RubberDuckyWelcome")
    dialog:SetScript("OnHide", function() ns.db.seenWelcome = true end)

    local close = CreateFrame("Button", nil, dialog, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)
    close:SetScript("OnClick", Close)

    page = UI.NewPage{ title = "|cffffd100Rubber Ducky|r", subtitle = "Your little fishing buddy.",
        icon = MEDIA .. "bobber_duck", crop = false }
    page.frame:SetParent(dialog)
    page.frame:ClearAllPoints()
    page.frame:SetPoint("TOPLEFT", 10, -12)
    page.frame:SetPoint("BOTTOMRIGHT", -10, 52)
    page.frame:Show()

    local what = page:Card("What it does")
    Feature(what, "Interface\\Icons\\INV_Misc_Drum_01", "Hear the splash",
        "Sound effects go up and everything else fades to a mumble while your line is out.")
    Feature(what, MEDIA .. "bobber_duck", "See your bobber",
        "Sparkles and a rubber duck float over it. Pick from 24 bobbers.", false)
    Feature(what, "Interface\\Icons\\INV_Misc_Spyglass_03", "A closer look",
        "The camera eases in toward the water, then back out when you loot.")
    Feature(what, "Interface\\Icons\\INV_Fishingpole_02", "One button",
        "With a pole equipped, one button casts and reels in.")
    Feature(what, "Interface\\Icons\\INV_Misc_Fish_02", "Celebrate your catch",
        "It goes straight to your bags with a splash showing what you caught.")

    local setup = page:Card("Quick setup")
    local y = setup:Advance(54)
    local bob = setup.frame:CreateTexture(nil, "ARTWORK")
    bob:SetSize(46, 46)
    bob:SetPoint("TOPLEFT", 14, y)
    local bobName = setup.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bobName:SetPoint("TOPLEFT", bob, "TOPRIGHT", 12, -4)
    local choose = CreateFrame("Button", nil, setup.frame, "UIPanelButtonTemplate")
    choose:SetSize(140, 22)
    choose:SetPoint("TOPLEFT", bobName, "BOTTOMLEFT", 0, -6)
    choose:SetText("Choose Bobber")
    choose:SetScript("OnClick", function() UI.Later(function() ns.Picker:Show() end) end)
    page:OnRefresh(function(pg)
        local list = ns.Bobber.MARKERS
        local style = ns.db.markerStyle or 15
        local shown = (style >= 1 and style <= #list) and style or (ns.db.lastStyle or 15)
        bob:SetTexture(MEDIA .. "bobber_" .. list[shown][1])
        bobName:SetText("Your bobber: |cffffd100" .. (style >= 1 and list[shown][2] or "random each cast") .. "|r")
        pg.icon:SetTexture(MEDIA .. "bobber_" .. list[shown][1])
    end)

    setup:Choice{ label = "One-button fishing", key = "oneKeyButton",
        onChange = function() ns.OneKey:Update() end,
        options = function()
            local T = ns.OneKey.TriggerName
            return { { 4, "Interact" }, { 6, T("left") }, { 5, T("right") } }
        end }
    setup:Toggle{ label = "Auto loot your catch", key = "autoLootFishing" }
    setup:Toggle{ label = "Catch splash", key = "splashEnabled" }
    setup:Toggle{ label = "Sound focus while fishing", key = "focusEnabled" }
    setup:Toggle{ label = "Fishing camera", key = "cameraEnabled" }
    setup:Text("You can change all of this later with /ducky.", true)

    local fish = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    fish:SetSize(140, 26)
    fish:SetPoint("BOTTOMRIGHT", -20, 18)
    fish:SetText("Let's fish!")
    fish:SetScript("OnClick", Close)
    local settings = CreateFrame("Button", nil, dialog, "UIPanelButtonTemplate")
    settings:SetSize(140, 26)
    settings:SetPoint("RIGHT", fish, "LEFT", -8, 0)
    settings:SetText("Open settings")
    settings:SetScript("OnClick", function()
        Close()
        UI.Later(function() if ns.Options then ns.Options:Open() end end)
    end)
end

function Welcome:Show()
    if not dialog then Build() end
    dialog:Show()
    page:Refresh()
end

function Welcome:Refresh()
    if dialog and dialog:IsShown() then page:Refresh() end
end

function Welcome:MaybeShowFirstTime()
    if ns.db.seenWelcome then return false end
    C_Timer.After(3, function()
        if not ns.db.seenWelcome and not InCombatLockdown() then Welcome:Show() end
    end)
    return true
end
