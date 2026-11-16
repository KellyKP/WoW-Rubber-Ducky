-- Rubber Ducky: settings pages (overview plus one page per feature).

local _, ns = ...
local Options = {}
ns.Options = Options

local UI = ns.UI
local category
local pages = {}
Options.pages = pages

local MEDIA = "Interface\\AddOns\\RubberDucky\\Media\\"
local function BobberTexture(style)
    local list = ns.Bobber.MARKERS
    if not style or style < 1 or style > #list then style = 1 end
    return MEDIA .. "bobber_" .. list[style][1], list[style][2]
end

local function pct(v) return string.format("%d%%", v * 100 + 0.5) end
local function secs(v) return v == 0 and "Instant" or string.format("%.2g sec", v) end

local function Version()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, v = pcall(get, "RubberDucky", "Version")
    return ok and v or "?"
end
Options.Version = Version

local function Feature(card, icon, name, text, crop)
    local y = card:Advance(40)
    local tex = card.frame:CreateTexture(nil, "ARTWORK")
    tex:SetSize(28, 28)
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

-- Pole swap card: drag or click the icon to pick up the macro
local function AddPoleSwapCard(p)
    local swap = p:Card("Pole swap")
    local y = swap:Advance(56)
    local icon = CreateFrame("Button", nil, swap.frame)
    icon:SetSize(44, 44)
    icon:SetPoint("TOPLEFT", 14, y)
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()
    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local hl = icon:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); hl:SetBlendMode("ADD")
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function() ns.Gear:Pickup() end)
    icon:SetScript("OnClick", function() ns.Gear:Pickup() end)
    local head = swap.frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    head:SetText("Drag this onto an action bar")
    local nextLine = swap.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nextLine:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6)
    nextLine:SetJustifyH("LEFT")
    swap:Text("Swaps your fishing pole and your weapon.", true)
    swap:Toggle{ label = "Show a splash when you swap", key = "swapSplash" }
    swap:Toggle{ label = "Play a sound when you swap", key = "swapSound" }
    swap:Buttons{ { "Show me", function() ns.Splash:PreviewSwap() end, width = 120 } }

    local function Name(id)
        if not id then return end
        local n = ns.Safe(function() return C_Item.GetItemNameByID(id) end)
        return n or ("item " .. id)
    end
    local function Paint()
        icon.tex:SetTexture(ns.Gear:NextIcon())
        local w = ns.Gear.Mine().weapons
        if ns.Gear.PoleEquipped() then
            if w and w.mh then
                nextLine:SetText("Next press: |cffffffff" .. Name(w.mh) .. (w.oh and (" + " .. Name(w.oh)) or "") .. "|r")
            else
                nextLine:SetText("Next press: |cffff8080equip a weapon once so Rubber Ducky knows it|r")
            end
        else
            local pole = ns.Gear.FindPole()
            nextLine:SetText(pole and ("Next press: |cffffffff" .. Name(pole) .. "|r") or "Next press: |cffff8080no fishing pole in your bags|r")
        end
    end
    ns.Gear.onChange = function() if p.frame:IsShown() then Paint() end end
    p:OnRefresh(Paint)
end

-------------------------------------------------------------------------------
-- Overview
-------------------------------------------------------------------------------
local function OverviewPage()
    local p = UI.NewPage{ title = "|cffffd100Rubber Ducky|r", subtitle = "Version " .. Version() .. "  ·  for WoW: Forever",
        icon = BobberTexture(1), crop = false }
    local c = p:Card("What it does")
    Feature(c, "Interface\\Icons\\INV_Misc_Drum_01", "Sound", "Effects up, everything else to a mumble, so the splash stands out.")
    Feature(c, MEDIA .. "bobber_glowlantern", "Bobber", "Sparkles and your choice of 24 bobber icons mark where it landed.", false)
    Feature(c, "Interface\\Icons\\INV_Misc_Spyglass_03", "Camera", "Eases in toward the water while you fish, back out when you loot.")
    Feature(c, "Interface\\Icons\\INV_Fishingpole_02", "One-button fishing", "One button casts and reels in; your catch lands in your bags with a splash.")
    c:Advance(4)
    c:Text("Pick a section on the left to change its settings.", true)
    c:Buttons{ { "What's new", function() ns.Changelog:Show() end, width = 140 } }

    AddPoleSwapCard(p)

    local share = p:Card("Share settings")
    share:Text("Share your setup with a friend, or send it along when asking for help.", true)
    share:Buttons{ { "Copy my settings", function() ns.Share:ShowCopy() end, width = 160 },
        { "Paste settings", function() ns.Share:ShowPaste() end, width = 160 } }

    local hello = p:Card("Welcome")
    hello:Toggle{ label = "Say hello in chat when you log in", key = "welcome",
        desc = "One line with the version and the /ducky command." }
    hello:Buttons{ { "Show welcome screen", function() ns.Welcome:Show() end, width = 180 } }
    p:OnRefresh(function(page)
        local style = ns.db.markerStyle or 1
        if style < 1 then style = math.random(#ns.Bobber.MARKERS) end
        page.icon:SetTexture((BobberTexture(style)))
    end)
    return p
end

-------------------------------------------------------------------------------
-- Sound
-------------------------------------------------------------------------------
local FADES = { quick = { 0.5, 1.0 }, smooth = { 1.0, 2.5 }, slow = { 2.0, 5.0 } }

local function SoundPage()
    local p = UI.NewPage{ title = "Sound", subtitle = "Make the splash the loudest thing you hear.",
        icon = "Interface\\Icons\\INV_Misc_Drum_01", toggleKey = "focusEnabled" }

    local c = p:Card("While your line is out")
    c:Slider{ label = "Splash and effects", key = "sfxLevel", min = 0, max = 1, step = 0.05, format = pct }
    c:Slider{ label = "Music and ambience", key = "mumbleLevel", min = 0, max = 1, step = 0.05, format = function(v)
        if v == 0 then return "Silent" end
        local word = v <= 0.2 and "Quiet" or v <= 0.5 and "Soft" or "Normal"
        return word .. " (" .. pct(v) .. ")"
    end }
    c:Toggle{ label = "Hush emotes, pets and error voices", key = "quietExtras" }
    c:Toggle{ label = "Keep listening when you alt-tab", key = "soundInBG" }

    local f = p:Card("Fading")
    f:Choice{ label = "Fade speed", options = { { "quick", "Quick" }, { "smooth", "Smooth" }, { "slow", "Slow" } },
        get = function()
            for name, v in pairs(FADES) do
                if math.abs((ns.db.fadeIn or 0) - v[1]) < 0.01 and math.abs((ns.db.fadeOut or 0) - v[2]) < 0.01 then return name end
            end
        end,
        set = function(name) ns.db.fadeIn, ns.db.fadeOut = FADES[name][1], FADES[name][2] end }
    f:Toggle{ label = "Fade back as soon as you catch or miss", key = "soundReturnOnLoot",
        desc = "Otherwise your sound comes back a few seconds after your line is in." }

    local fine = p:Card("Exact fade times")
    fine:Slider{ label = "Fade in", key = "fadeIn", min = 0, max = 5, step = 0.25, format = secs }
    fine:Slider{ label = "Fade out", key = "fadeOut", min = 0, max = 8, step = 0.25, format = secs }
    p:Expander("Fine-tune", fine)
    return p
end

-------------------------------------------------------------------------------
-- Bobber
-------------------------------------------------------------------------------
local function BobberPage()
    local p = UI.NewPage{ title = "Bobber", subtitle = "Spot your bobber at a glance.", icon = BobberTexture(1), crop = false }
    local function marker() if ns.Bobber.RefreshMarker then ns.Bobber:RefreshMarker() end end
    local function sparkle() if ns.Bobber.RefreshSparkle then ns.Bobber:RefreshSparkle() end end

    local mine = p:Card("Your bobber")
    local y = mine:Advance(84)
    local big = mine.frame:CreateTexture(nil, "ARTWORK")
    big:SetSize(76, 76)
    big:SetPoint("TOPLEFT", 14, y)
    local name = mine.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", big, "TOPRIGHT", 14, -8)
    local choose = CreateFrame("Button", nil, mine.frame, "UIPanelButtonTemplate")
    choose:SetSize(150, 24)
    choose:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -10)
    choose:SetText("Choose Bobber")
    choose:SetScript("OnClick", function() UI.Later(function() ns.Picker:Show() end) end)
    local random = CreateFrame("CheckButton", nil, mine.frame, "UICheckButtonTemplate")
    random:SetSize(24, 24)
    random:SetPoint("LEFT", choose, "RIGHT", 14, 0)
    local rl = mine.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    rl:SetPoint("LEFT", random, "RIGHT", 2, 0)
    rl:SetText("Random each cast")
    random:SetScript("OnClick", function(self)
        ns.db.markerStyle = self:GetChecked() and 0 or (ns.db.lastStyle or 15)
        if self:GetChecked() then ns.db.markerEnabled = true end
        UI.Later(function() marker(); p:Refresh() end)
    end)
    p:OnRefresh(function(page)
        local style = ns.db.markerStyle or 1
        if style >= 1 then ns.db.lastStyle = style end
        local shown = style >= 1 and style or (ns.db.lastStyle or 15)
        local tex, label = BobberTexture(shown)
        big:SetTexture(tex)
        big:SetDesaturated(style < 1)
        name:SetText(style >= 1 and label or "A different one each cast")
        random:SetChecked(style < 1)
        page.icon:SetTexture(tex)
    end)

    local icon = p:Card("Icon")
    icon:Toggle{ label = "Show the icon above your bobber", key = "markerEnabled", onChange = marker }
    icon:Choice{ label = "Size", options = { { 40, "Small" }, { 56, "Medium" }, { 80, "Large" } }, key = "markerSize",
        onChange = marker, maxWidth = 110 }

    local sp = p:Card("Sparkles")
    sp:Toggle{ label = "Sparkles around your bobber", key = "sparkleEnabled", onChange = sparkle }
    sp:Choice{ label = "Amount", options = { { 1, "Subtle" }, { 2, "Normal" }, { 3, "Lots" } }, key = "sparkleAmount",
        onChange = sparkle, maxWidth = 110 }
    sp:Choice{ label = "Spread", options = { { 60, "Tight" }, { 90, "Normal" }, { 130, "Wide" } }, key = "sparkleSpread",
        onChange = sparkle, maxWidth = 110 }

    local fine = p:Card("Exact position and size")
    fine:Slider{ label = "Icon height", key = "markerOffsetY", min = -40, max = 120, step = 2, format = function(v) return v .. " px" end, onChange = marker }
    fine:Slider{ label = "Icon size", key = "markerSize", min = 24, max = 160, step = 4, format = function(v) return v .. " px" end, onChange = marker }
    fine:Slider{ label = "Sparkle height", key = "sparkleOffsetY", min = -80, max = 40, step = 2, format = function(v) return v .. " px" end, onChange = sparkle }
    fine:Slider{ label = "Sparkle spread", key = "sparkleSpread", min = 40, max = 200, step = 5, format = function(v) return v .. " px" end, onChange = sparkle }
    p:Expander("Fine-tune position", fine)
    return p
end

-------------------------------------------------------------------------------
-- Camera
-------------------------------------------------------------------------------
local function CameraPage()
    local reapply = function() ns.Camera:Reapply() end
    local p = UI.NewPage{ title = "Camera", subtitle = "Ease in toward the water while you fish.",
        icon = "Interface\\Icons\\INV_Misc_Spyglass_03", toggleKey = "cameraEnabled" }

    local c = p:Card("Framing")
    c:Choice{ label = "Distance", options = { { 2.5, "Close" }, { 4, "Medium" }, { 7, "Far" } }, key = "cameraZoom", onChange = reapply }
    c:Choice{ label = "View", options = { { 0.08, "Over the water" }, { 0.15, "Balanced" }, { 0.3, "Classic" } },
        key = "cameraTilt", onChange = reapply }
    c:Choice{ label = "Your character", options = { { -1.5, "Left" }, { 0, "Center" }, { 1.5, "Right" } },
        key = "cameraShoulder", onChange = reapply }
    c:Text("The game may show a notice about experimental camera settings the first time.", true)

    local t = p:Card("Coming back")
    t:Toggle{ label = "Return the camera when the loot window opens", key = "cameraReturnOnLoot" }

    local fine = p:Card("Exact framing")
    fine:Slider{ label = "Distance", key = "cameraZoom", min = 1, max = 15, step = 0.5, format = function(v) return string.format("%.1f yd", v) end, onChange = reapply }
    fine:Slider{ label = "View (character height)", key = "cameraTilt", min = 0, max = 0.4, step = 0.01, format = function(v) return string.format("%.2f", v) end, onChange = reapply }
    fine:Slider{ label = "Sideways", key = "cameraShoulder", min = -3, max = 3, step = 0.25, format = function(v) return string.format("%.2f", v) end, onChange = reapply }
    p:Expander("Fine-tune", fine)
    return p
end

-------------------------------------------------------------------------------
-- Catch splash (cards on the One-button page)
-------------------------------------------------------------------------------
local function AddSplashCards(p)
    local list = ns.Splash.BANNERS

    local pick = p:Card("Catch splash")
    pick:Toggle{ label = "Show a splash with your catch", key = "splashEnabled",
        desc = "A big BAM and what you caught, when your catch skips the loot window." }
    local TW, TH, GAP, PER = 200, 100, 8, 2
    local rowsN = math.ceil(#list / PER)
    local y = pick:Advance(rowsN * (TH + GAP))
    local thumbs = {}
    for i, b in ipairs(list) do
        local t = CreateFrame("Button", nil, pick.frame, "BackdropTemplate")
        t:SetSize(TW, TH)
        t:SetPoint("TOPLEFT", 14 + ((i - 1) % PER) * (TW + GAP), y - math.floor((i - 1) / PER) * (TH + GAP))
        t:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        t.tex = t:CreateTexture(nil, "ARTWORK")
        t.tex:SetPoint("TOPLEFT", 2, -2); t.tex:SetPoint("BOTTOMRIGHT", -2, 2)
        t.tex:SetTexture(MEDIA .. "splash_" .. b[1])
        local hl = t:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
        t:SetScript("OnClick", function()
            ns.db.splashBanner = i
            UI.Later(function() p:Refresh(); ns.Splash:Preview() end)
        end)
        thumbs[i] = t
    end
    pick:Toggle{ label = "A different one each catch", get = function() return (ns.db.splashBanner or 0) < 1 end,
        set = function(v) ns.db.splashBanner = v and 0 or (ns.db.lastSplashBanner or 1) end }
    pick:Toggle{ label = "Show misses too", key = "splashMisses",
        desc = "\"Missed!\" when you reel in empty, \"Zzz...\" when the cast runs out." }
    pick:Toggle{ label = "Play a sound when caught", key = "splashCatchSound",
        onChange = function(on) if on then ns.Splash.PlaySound() end end }
    pick:Toggle{ label = "Play a sound when missed", key = "splashMissSound" }
    pick:Buttons{ { "Show me", function() ns.Splash:Preview() end, width = 120 },
        { "Show a miss", function() ns.Splash:PreviewMiss() end, width = 120 } }
    p:OnRefresh(function()
        local cur = ns.db.splashBanner or 0
        if cur >= 1 then ns.db.lastSplashBanner = cur end
        for i, t in ipairs(thumbs) do
            if i == cur then
                t:SetBackdropColor(1, 0.82, 0, 0.18); t:SetBackdropBorderColor(1, 0.82, 0, 0.9)
                t.tex:SetDesaturated(false); t.tex:SetAlpha(1)
            else
                t:SetBackdropColor(0, 0, 0, 0.3); t:SetBackdropBorderColor(1, 1, 1, 0.15)
                t.tex:SetDesaturated(false); t.tex:SetAlpha(cur < 1 and 1 or 0.55)
            end
        end
    end)

    local look = p:Card("Splash look")
    look:Choice{ label = "Size", options = { { 0.5, "Small" }, { 0.7, "Medium" }, { 0.9, "Large" } }, key = "splashSize",
        onChange = function() ns.Splash:Preview() end, maxWidth = 110 }
    look:Choice{ label = "On screen for", options = { { 2, "Short" }, { 3, "Normal" }, { 4.5, "Long" } }, key = "splashDuration",
        maxWidth = 110 }
    look:Choice{ label = "Height", options = { { 320, "High" }, { 200, "Middle" }, { 60, "Low" } }, key = "splashY",
        onChange = function() ns.Splash:Preview() end, maxWidth = 110 }

    local fine = p:Card("Exact splash size and height")
    fine:Slider{ label = "Size", key = "splashSize", min = 0.3, max = 1.3, step = 0.05, format = pct }
    fine:Slider{ label = "Height", key = "splashY", min = -300, max = 450, step = 10, format = function(v) return v .. " px" end }
    fine:Slider{ label = "On screen for", key = "splashDuration", min = 1, max = 8, step = 0.5, format = secs }
    p:Expander("Fine-tune the splash", fine)
end

-------------------------------------------------------------------------------
-- One-button fishing
-------------------------------------------------------------------------------
local function OneButtonPage()
    local update = function() ns.OneKey:Update() end
    local p = UI.NewPage{ title = "One-button fishing", subtitle = "With a pole equipped, one button casts and reels in.",
        icon = "Interface\\Icons\\INV_Fishingpole_02", toggleKey = "oneKeyEnabled", onToggle = update }

    local c = p:Card("Your button")
    c:Choice{ tall = true, key = "oneKeyButton", onChange = update, options = function()
        local T = ns.OneKey.TriggerName
        return {
            { 4, "Interact", "casts when nothing's targeted" },
            { 6, T("left"), "casts, then reels in" },
            { 5, T("right"), "casts, then reels in" },
        }
    end }
    c:Text("Your button works normally again when you equip your weapon or combat starts.", true)

    local ctl = p:Card("Controller")
    ctl:Choice{ label = "Controller type", key = "padType",
        options = { { "auto", "Automatic" }, { "xbox", "Xbox" }, { "playstation", "PlayStation" }, { "switch", "Switch" } } }

    local loot = p:Card("Looting")
    loot:Toggle{ label = "Auto loot your catch", key = "autoLootFishing",
        desc = "Your catch goes straight to your bags." }

    AddSplashCards(p)
    return p
end

-------------------------------------------------------------------------------
-- Developer
-------------------------------------------------------------------------------
local function DeveloperPage()
    local p = UI.NewPage{ title = "Developer", subtitle = "Tools for testing and troubleshooting.",
        icon = "Interface\\Icons\\INV_Misc_Gear_01", toggleKey = "debugMode",
        onToggle = function() ns.Console:Apply() end }

    local con = p:Card("Console")
    con:Text("With debug mode on, Rubber Ducky's status messages go to a small console window instead of chat.")
    con:Buttons{ { "Show console", function() ns.Console:Show() end }, { "Copy console", function() ns.Console.ShowCopy() end } }

    local share = p:Card("Sharing")
    share:Toggle{ label = "Include debug info when copying settings", key = "shareDebug",
        desc = "Version, game details and your list of addons." }

    local rec = p:Card("Event recorder")
    rec:Toggle{ label = "Record what the game reports during each cast", key = "probeEnabled" }
    rec:Buttons{ { "Show log", function() ns.Probe:ShowLog() end } }

    local one = p:Card("One-button fishing")
    one:Buttons{ { "Write status to console", function() ns.Console:Show(); ns.OneKey:Status() end, width = 200 } }

    local bob = p:Card("Bobber targeting")
    bob:Toggle{ label = "Soft-target the bobber while fishing", key = "softTargetHelp",
        desc = "Gives the bobber the nameplate the sparkle and icon attach to." }
    return p
end

-------------------------------------------------------------------------------

local function Build()
    pages.overview = OverviewPage()
    category = Settings.RegisterCanvasLayoutCategory(pages.overview.frame, "Rubber Ducky")
    Settings.RegisterAddOnCategory(category)
    local list = {
        { "sound", "Sound", SoundPage }, { "bobber", "Bobber", BobberPage }, { "camera", "Camera", CameraPage },
        { "onebutton", "One-button fishing", OneButtonPage }, { "developer", "Developer", DeveloperPage },
    }
    for _, item in ipairs(list) do
        local page = item[3]()
        pages[item[1]] = page
        Settings.RegisterCanvasLayoutSubcategory(category, page.frame, item[2])
    end
end

function Options:Build()
    if category or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end
    local ok, err = pcall(Build)
    if not ok then
        category = nil
        ns.Print("settings pages unavailable on this client (%s). Use /ducky help for commands.", tostring(err))
    end
end

-- redraw open pages after changes made elsewhere
function Options.RefreshOverview()
    for _, page in pairs(pages) do
        if page.frame:IsShown() then page:Refresh() end
    end
    if ns.Welcome then ns.Welcome:Refresh() end
end

local function ShowingOurs()
    local panel = SettingsPanel
    if not panel or not panel:IsShown() then return false end
    local ok, cur = pcall(function()
        if panel.GetCurrentCategory then return panel:GetCurrentCategory() end
        local list = panel.GetCategoryList and panel:GetCategoryList()
        return list and list.GetCurrentCategory and list:GetCurrentCategory()
    end)
    if not ok then return false end
    while cur do
        if cur == category then return true end
        cur = cur.GetParentCategory and cur:GetParentCategory() or nil
    end
    return false
end

-- The first open of a session builds the page list after OpenToCategory runs,
-- so nothing gets selected: call it again a moment later. Never select pages
-- by reaching into SettingsPanel.
local function Call(step, id)
    ns.lastUIStep = step
    local ok = pcall(Settings.OpenToCategory, id)
    ns.lastUIStep = nil
    return ok
end

local openAfterCombat
function Options:Open()
    if not category then return false end
    -- the Settings window can't be opened safely by an addon in combat
    if InCombatLockdown() then
        if not openAfterCombat then
            openAfterCombat = CreateFrame("Frame")
            openAfterCombat:SetScript("OnEvent", function(f)
                f:UnregisterEvent("PLAYER_REGEN_ENABLED")
                Options:Open()
            end)
        end
        openAfterCombat:RegisterEvent("PLAYER_REGEN_ENABLED")
        ns.Chat("Hang tight! Settings will open once combat's over.")
        return true
    end
    local id = category:GetID()
    ns.openedSettingsAt = GetTime()
    Call("open settings", id)
    C_Timer.After(0.05, function()
        if SettingsPanel and SettingsPanel:IsShown() and not ShowingOurs() then
            Call("select page", id)
        end
    end)
    return true
end
