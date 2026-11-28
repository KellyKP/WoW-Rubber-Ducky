-- Rubber Ducky: settings pages (overview plus one page per feature).

local _, ns = ...
local Options = {}
ns.Options = Options

local UI = ns.UI
local category
local pages = {}
Options.pages = pages

local function BobberTexture(style)
    local list = ns.Bobber.MARKERS
    if not style or style < 1 or style > #list then style = 1 end
    return ns.BobberArt(list[style][1]), list[style][2]
end

local function pct(v) return string.format("%d%%", v * 100 + 0.5) end
local function secs(v) return v == 0 and "Instant" or string.format("%.2g sec", v) end

local function Version()
    local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local ok, v = pcall(get, "RubberDucky", "Version")
    return ok and v or "?"
end
Options.Version = Version

local function Feature(card, icon, name, text, crop, key)
    local y = card:Advance(42)
    if key then
        -- the whole row opens that feature's page in our settings window
        local row = CreateFrame("Button", nil, card.frame)
        row:SetPoint("TOPLEFT", 8, y + 4)
        row:SetPoint("RIGHT", card.frame, "RIGHT", -8, 0)
        row:SetHeight(38)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.06)
        row:SetScript("OnClick", function() UI.Sound("page"); if ns.SettingsWindow then ns.SettingsWindow:Show(key) end end)
    end
    -- the icon in a little gold-cornered tile, as on the Welcome screen
    local tex = UI.IconTile(card.frame, 34, icon, crop)
    tex:SetPoint("TOPLEFT", 18, y + 3)
    local n = card.frame:CreateFontString(nil, "OVERLAY", card:Font("bold"))
    n:SetPoint("TOPLEFT", tex, "TOPRIGHT", 10, 0)
    n:SetText(name)
    local d = card.frame:CreateFontString(nil, "OVERLAY", card:Font("soft"))
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
    icon:SetPoint("TOPLEFT", 22, y)
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()
    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local hl = icon:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); hl:SetBlendMode("ADD")
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function() ns.Gear:Pickup() end)
    icon:SetScript("OnClick", function() ns.Gear:Pickup() end)
    local head = swap.frame:CreateFontString(nil, "OVERLAY", swap:Font("bold"))
    head:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    head:SetText("Drag this onto an action bar")
    local nextLine = swap.frame:CreateFontString(nil, "OVERLAY", swap:Font("small"))
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
                nextLine:SetText("Next press: |cff1a5a2a" .. Name(w.mh) .. (w.oh and (" + " .. Name(w.oh)) or "") .. "|r")
            else
                nextLine:SetText("Next press: |cffa02010equip a weapon once so Rubber Ducky knows it|r")
            end
        else
            local pole = ns.Gear.FindPole()
            nextLine:SetText(pole and ("Next press: |cff1a5a2a" .. Name(pole) .. "|r") or "Next press: |cffa02010no fishing pole in your bags|r")
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
    -- share your setup with a friend, or send it along when asking for help
    p:Tool("Copy", function() ns.Share:ShowCopy() end,
        { "Copy settings", "Turns your setup into text you can share with a friend or send along when asking for help." })
    p:Tool("Paste", function() ns.Share:ShowPaste() end,
        { "Paste settings", "Brings in a setup someone shared with you." })

    local c = p:Card("What it does")
    Feature(c, "Interface\\Icons\\INV_Fishingpole_01", "Pole swap", "One button swaps your fishing pole and your weapon.", nil, "poleswap")
    Feature(c, "Interface\\Icons\\INV_Misc_Drum_01", "Sound", "Effects up, everything else to a mumble, so the splash stands out.", nil, "sound")
    Feature(c, "Interface\\Icons\\INV_Misc_Spyglass_03", "Camera", "Eases in toward the water while you fish, back out when you loot.", nil, "camera")
    Feature(c, ns.BobberArt("glowlantern"), "Bobber", "Sparkles and your choice of 30 bobber icons mark where it landed.", false, "bobber")
    Feature(c, "Interface\\Icons\\INV_Fishingpole_02", "One-button fishing", "One button casts and reels in.", nil, "onebutton")
    Feature(c, ns.MEDIA .. "Tackle\\icon_wheel", "Tackle wheel", "Your lures, camp gear and favourite places, on one wheel.", false, "tackle")
    Feature(c, "Interface\\Icons\\INV_Misc_Fish_02", "Your catch", "Straight to your bags, with a splash to celebrate.", nil, "catch")
    Feature(c, ns.MEDIA .. "Log\\button", "Fishing log", "Everything you caught this session, written on a parchment board.", false, "log")
    Feature(c, ns.MEDIA .. "Journal\\button", "Fishing journal", "A book of every fish this character has caught, where, and the ones still to find.", false, "journal")
    c:Advance(4)
    c:Text("Pick a tab above to change its settings.", true)
    c:Buttons{ { "What's new", function() ns.Changelog:Show() end, width = 140 },
        { "Welcome screen", function() ns.Welcome:Show() end, width = 150 } }

    local hello = p:Card("Hello")
    hello:Toggle{ label = "Say hello in chat when you log in", key = "welcome",
        desc = "One line with the version, and what's new after an update." }
    -- the developer page isn't a tab: it opens from here
    local dev = p:Card("Developer")
    dev:Text("Tools for testing and troubleshooting: the console, the event recorder and starting fresh.", true)
    dev:Buttons{ { "Developer settings", function() UI.Sound("page"); Options:Open("developer") end, width = 190 } }
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
    p:ResetTool()
    return p
end

-------------------------------------------------------------------------------
-- Bobber
-------------------------------------------------------------------------------
local function BobberPage()
    local function marker() if ns.Bobber.RefreshMarker then ns.Bobber:RefreshMarker() end end
    -- the page switch is the icon above your bobber; sparkles have their own
    local p = UI.NewPage{ title = "Bobber", subtitle = "Spot your bobber at a glance.", icon = BobberTexture(1), crop = false,
        toggleKey = "markerEnabled", onToggle = marker }
    local function sparkle() if ns.Bobber.RefreshSparkle then ns.Bobber:RefreshSparkle() end end

    local mine = p:Card("Your bobber")
    local y = mine:Advance(84)
    local big = mine.frame:CreateTexture(nil, "ARTWORK")
    big:SetSize(76, 76)
    big:SetPoint("TOPLEFT", 22, y)
    local name = mine.frame:CreateFontString(nil, "OVERLAY", mine:Font("large"))
    name:SetPoint("TOPLEFT", big, "TOPRIGHT", 14, -8)
    local choose = UI.Button(mine.frame, "Choose bobber", 160, function() ns.Picker:Show() end, { height = 36 })
    choose:SetPoint("TOPLEFT", name, "BOTTOMLEFT", -6, -4)
    local random = CreateFrame("CheckButton", nil, mine.frame, "UICheckButtonTemplate")
    random:SetSize(24, 24)
    random:SetPoint("LEFT", choose, "RIGHT", 14, 0)
    local rl = mine.frame:CreateFontString(nil, "OVERLAY", mine:Font("ink"))
    rl:SetPoint("LEFT", random, "RIGHT", 2, 0)
    rl:SetText("Random each cast")
    random:SetScript("OnClick", function(self)
        UI.Click(self:GetChecked())
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

    mine:Choice{ label = "Size", options = { { 40, "Small" }, { 56, "Medium" }, { 80, "Large" } }, key = "markerSize",
        onChange = marker, maxWidth = 110 }
    mine:Choice{ label = "Height", options = { { -20, "Low" }, { 20, "Medium" }, { 60, "High" } }, key = "markerOffsetY",
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
    p:ResetTool{ apply = function() marker(); sparkle() end, extra = { "markerStyle" } }
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
    c:Choice{ label = "View", options = { { 0.08, "Over water" }, { 0.15, "Balanced" }, { 0.3, "Classic" } },
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
    p:ResetTool{ apply = reapply }
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
    -- tiles like the bobber picker's: navy, the chosen one parchment with a blue gem
    local TW, TH, GAP, PER = 132, 72, 6, 3
    local rowsN = math.ceil(#list / PER)
    local y = pick:Advance(rowsN * (TH + GAP))
    local thumbs = {}
    for i, b in ipairs(list) do
        local t = CreateFrame("Button", nil, pick.frame)
        t:SetSize(TW, TH)
        t:SetPoint("TOPLEFT", 14 + ((i - 1) % PER) * (TW + GAP), y - math.floor((i - 1) / PER) * (TH + GAP))
        t.art = UI.Stretch(t, "tile_navy", "BACKGROUND", TH / 154 * 0.9)
        t.tex = t:CreateTexture(nil, "ARTWORK")
        t.tex:SetPoint("TOPLEFT", 8, -6); t.tex:SetPoint("BOTTOMRIGHT", -8, 6)
        t.tex:SetTexture(ns.SplashArt("Catch", b[1]))
        local hl = t:CreateTexture(nil, "HIGHLIGHT")
        hl:SetPoint("TOPLEFT", 6, -6); hl:SetPoint("BOTTOMRIGHT", -6, 6)
        hl:SetColorTexture(1, 1, 1, 0.15)
        t.gem = t:CreateTexture(nil, "OVERLAY")
        UI.Gem(t.gem, "blue")
        t.gem:SetSize(18, 18)
        t.gem:SetPoint("CENTER", t, "TOPRIGHT", -4, -4)
        t.gem:Hide()
        t:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(b[2])
            GameTooltip:AddLine("Click to always show this one.", 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end)
        t:SetScript("OnLeave", function() GameTooltip:Hide() end)
        t:SetScript("OnClick", function()
            UI.Sound("on")
            ns.db.splashBannerKey = b[1]
            UI.Later(function() p:Refresh(); ns.Splash:Preview() end)
        end)
        thumbs[i] = t
    end
    pick:Toggle{ label = "A different one each catch", get = function() return (ns.db.splashBannerKey or "") == "" end,
        set = function(v) ns.db.splashBannerKey = v and "" or (ns.db.lastSplashBannerKey or list[1][1]) end }
    pick:Toggle{ label = "Show misses too", key = "splashMisses",
        desc = "\"Missed!\" when you reel in empty, \"Zzz...\" when the cast runs out." }
    pick:Toggle{ label = "Play a sound when caught", key = "splashCatchSound",
        onChange = function(on) if on then ns.Splash.PlaySound() end end }
    pick:Toggle{ label = "Play a sound when missed", key = "splashMissSound" }
    pick:Buttons{ { "Show me", function() ns.Splash:Preview() end, width = 120 },
        { "Show a miss", function() ns.Splash:PreviewMiss() end, width = 120 } }
    p:OnRefresh(function()
        local key = ns.db.splashBannerKey or ""
        if key ~= "" then ns.db.lastSplashBannerKey = key end
        local cur = 0
        for i, b in ipairs(list) do if b[1] == key then cur = i end end
        for i, t in ipairs(thumbs) do
            t.art:SetArt(i == cur and "tile_parch" or "tile_navy")
            t.gem:SetShown(i == cur)
            if i == cur then
                t.tex:SetAlpha(1)
            else
                t.tex:SetAlpha(cur < 1 and 1 or 0.55)
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
local bindHelp, ShowBindHelp
local BIND_STEPS = {
    "Press |cffffd200Esc|r, then pick |cffffd200Options|r.",
    "Under |cffffd200Gameplay|r, pick |cffffd200Controls|r.",
    "Find |cffffd200Interact With Target|r, click the first box next to it, and press the key you want.",
}
function ShowBindHelp()
    if bindHelp then bindHelp:Show() return end
    -- our navy frame, its title on a plaque on the top edge
    local w = ns.SettingsWindow.Chrome("RubberDuckyBindHelp", nil, { title = "Binding the Interact key", frame = 0.55,
        width = 440, height = 300, scale = 1, strata = "FULLSCREEN_DIALOG" })
    bindHelp = w
    local L, T, R = unpack(w.inner)
    local y = -T
    local function Line(text, font, indent)
        local fs = w:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
        fs:SetPoint("TOPLEFT", L + (indent or 0), y)
        fs:SetWidth(440 - L - R - (indent or 0)); fs:SetJustifyH("LEFT")
        fs:SetText(text)
        y = y - (fs:GetStringHeight() or 14) - 8
    end
    for i, step in ipairs(BIND_STEPS) do Line(i .. ".  " .. step) end
    w:Show()
    y = y - 4
    Line("\"Enable Interact Key\" isn't needed: Rubber Ducky turns on what it needs while you fish. "
        .. "Turn it on if you also want the key for NPCs, mail and so on.", "GameFontDisableSmall")
    Line("No key handy? Pick a controller trigger instead: it works without any binding.", "GameFontDisableSmall")
    -- on a controller: nothing to pick here, so B closes it
    if ns.Pad and ns.Pad.Attach then
        ns.Pad.Attach(w, { roots = function() return {} end,
            badges = function(nav) if w.close then nav:Badge(w.close, "PAD2", "TOPLEFT", 2, -2, 22) end end })
    end
end

local function OneButtonPage()
    local update = function() ns.OneKey:Update() end
    local p = UI.NewPage{ title = "One-button fishing", subtitle = "With a pole equipped, one button casts and reels in.",
        icon = "Interface\\Icons\\INV_Fishingpole_02", toggleKey = "oneKeyEnabled", onToggle = update }

    local c = p:Card("Your button")
    local OK = ns.OneKey
    c:Choice{ tall = true, key = "oneKeyButton", onChange = update, options = function()
        return {
            { 4, "Interact", (OK.Binding(4)) },
            { 6, OK.TriggerName("left"), (OK.Binding(6)) },
            { 5, OK.TriggerName("right"), (OK.Binding(5)) },
        }
    end }
    c:Text("Interact casts when nothing's targeted. The triggers cast, then reel in.", true)
    local noteY = c.y
    c:Text("Your button works normally again when you equip your weapon or combat starts.", true)
    local help = CreateFrame("Button", nil, c.frame)
    help:SetSize(130, 16)
    help.bindHelpLink = true
    help:SetPoint("TOPRIGHT", c.frame, "TOPRIGHT", -14, noteY + 1)
    help.text = help:CreateFontString(nil, "OVERLAY", c:Font("bold"))
    help.text:SetPoint("RIGHT")
    help.text:SetText("How do I bind it?")
    -- an inked link: blue, darker under the mouse
    help.text:SetTextColor(0.1, 0.3, 0.6)
    help:SetScript("OnEnter", function() help.text:SetTextColor(0.05, 0.18, 0.4) end)
    help:SetScript("OnLeave", function() help.text:SetTextColor(0.1, 0.3, 0.6) end)
    help:SetScript("OnClick", function() UI.Sound("button"); UI.Later(ShowBindHelp) end)
    p:OnRefresh(function()
        local _, works = OK.Binding(ns.db.oneKeyButton or 4)
        help:SetShown(not works)
    end)
    -- bindings and controllers can change while the page is open
    local watch = CreateFrame("Frame")
    for _, e in ipairs({ "UPDATE_BINDINGS", "CVAR_UPDATE", "GAME_PAD_CONNECTED", "GAME_PAD_DISCONNECTED" }) do
        pcall(watch.RegisterEvent, watch, e)
    end
    watch:SetScript("OnEvent", function()
        if p.frame and p.frame:IsVisible() then UI.Later(function() p:Refresh() end) end
    end)

    local ctl = p:Card("Controller")
    ctl:Choice{ label = "Controller type", key = "padType",
        options = { { "auto", "Automatic" }, { "xbox", "Xbox" }, { "playstation", "PlayStation" }, { "switch", "Switch" } } }

    p:ResetTool{ apply = update }
    return p
end

-------------------------------------------------------------------------------
-- Pole swap
-------------------------------------------------------------------------------
local function PoleSwapPage()
    local p = UI.NewPage{ title = "Pole swap", subtitle = "One button swaps your fishing pole and your weapon.",
        icon = "Interface\\Icons\\INV_Fishingpole_01" }
    AddPoleSwapCard(p)
    p:ResetTool()
    return p
end

-------------------------------------------------------------------------------
-- Your catch
-------------------------------------------------------------------------------
local function CatchPage()
    local p = UI.NewPage{ title = "Your catch", subtitle = "Straight to your bags, with a splash to celebrate.",
        icon = "Interface\\Icons\\INV_Misc_Fish_02" }
    local loot = p:Card("Looting")
    loot:Toggle{ label = "Auto loot your catch", key = "autoLootFishing",
        desc = "Your catch goes straight to your bags." }
    AddSplashCards(p)
    p:ResetTool{ extra = { "splashBannerKey" } }
    return p
end

-------------------------------------------------------------------------------
-- Fishing log
-------------------------------------------------------------------------------
-- an icon to drag onto an action bar: picks up one of our macros
local function MacroRow(card, iconTex, pickup, what)
    local y = card:Advance(52)
    local icon = CreateFrame("Button", nil, card.frame)
    icon:SetSize(40, 40)
    icon:SetPoint("TOPLEFT", 22, y)
    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()
    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon.tex:SetTexture(iconTex)
    local hl = icon:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); hl:SetBlendMode("ADD")
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", pickup)
    icon:SetScript("OnClick", pickup)
    local head = card.frame:CreateFontString(nil, "OVERLAY", card:Font("bold"))
    head:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    head:SetText("Or drag this onto an action bar")
    local sub = card.frame:CreateFontString(nil, "OVERLAY", card:Font("small"))
    sub:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6)
    sub:SetText("A macro that opens and closes " .. what .. ", handy on a controller.")
end

local function TacklePage()
    local p = UI.NewPage{ title = "Tackle wheel", subtitle = "Your lures, camp gear and favourite places, on one wheel.",
        icon = ns.MEDIA .. "Tackle\\icon_wheel", crop = false }
    local c = p:Card("The wheel")
    c:Text("Two pages. Fishing: up to four of your lures round the top (hold your pole, pick one and it goes straight on); Mrrl's, your journal and Ducky's Challenges along the bottom, Professions on the left. Camp: your campfire kits, any camp features you carry (from any profession) and fishing foods. Out of combat for now.", true)
    c:Buttons{ { "Open the wheel", function() if ns.Tackle then ns.Tackle:Open() end end, width = 160 } }
    c:Text("With a mouse: point and click, and the mouse wheel turns the page. With a controller: the right stick points, A picks, LB and RB turn the page, B closes.", true)
    local m = p:Card("Opening the wheel")
    m:Toggle{ label = "Show the tackle box on the fishing log", key = "tackleOnLog",
        desc = "It sits on the stones by the fishing duck. Click it to open the wheel.",
        onChange = function(on) if ns.Log and ns.Log.tackleButton then ns.Log.tackleButton:SetShown(on) end end }
    MacroRow(m, "Interface\\Icons\\INV_G_FishingBobber_05", function() if ns.Tackle then ns.Tackle:PickupMacro() end end, "the tackle wheel")
    m:Text("Or type /ducky tackle.", true)
    return p
end

local function JournalPage()
    local p = UI.NewPage{ title = "Fishing journal", subtitle = "Everything this character has ever caught.",
        icon = ns.MEDIA .. "Journal\\fish", crop = false, toggleKey = "journalEnabled",
        onToggle = function() ns.Journal:Apply() end }
    local c = p:Card("The journal")
    c:Choice{ label = "Size", options = { { 0.8, "Small" }, { 1, "Medium" }, { 1.25, "Large" } }, key = "journalScale",
        onChange = function() ns.Journal:Apply() end, maxWidth = 110 }
    c:Buttons{ { "Open the journal", function() ns.Journal:Show() end, width = 160 },
        { "Ducky's Challenges", function() ns.ChallengesWindow:Show() end, width = 170 },
        { "Visit Mrrl", function() ns.Shop:Show() end, width = 120 } }
    c:Toggle{ label = "Pop a banner when you finish a challenge", key = "challengeToasts" }
    c:Text("Open it any time from Rubber Ducky's line in the minimap's AddOns list. Drag the book to move it.", true)
    local m = p:Card("Opening the journal yourself")
    m:Toggle{ label = "Show a journal button", key = "journalButton", onChange = function() ns.Journal:ApplyButton() end,
        desc = "Opens and closes the journal. Drag it anywhere, right-click it to lock it in place." }
    MacroRow(m, ns.Journal.MACRO_ICON, function() ns.Journal:PickupMacro() end, "the journal")
    m:Slider{ label = "Button size", key = "journalButtonSize", min = 24, max = 80, step = 2,
        format = function(v) return v .. " px" end, onChange = function() ns.Journal:ApplyButton() end }
    p:ResetTool{ apply = function() ns.Journal:Apply() end, extra = { "journalSort", "journalFindsSort", "journalFindsShow", "journalButtonLocked" },
        positions = { { "Reset journal position", function() ns.Journal:ResetPosition() end },
            { "Reset button position", function() ns.Journal:ResetButton() end } } }
    return p
end

local function LogPage()
    local p = UI.NewPage{ title = "Fishing log", subtitle = "Everything you caught this session.",
        icon = "Interface\\Icons\\INV_Misc_Note_01", toggleKey = "logEnabled",
        onToggle = function() ns.Log:Apply() end }

    local c = p:Card("The log")
    c:Toggle{ label = "Open when you equip a fishing pole", key = "logAutoOpen",
        desc = "It goes away when the pole comes off. The X closes it until next time." }
    c:Choice{ label = "Size", options = { { 0.8, "Small" }, { 1, "Medium" }, { 1.25, "Large" } }, key = "logScale",
        onChange = function() ns.Log:Apply() end, maxWidth = 110 }
    c:Toggle{ label = "Tell me when I can learn the next fishing rank", key = "rankAlert",
        desc = "A banner under the log when your skill reaches its cap. Hover it for where to go.",
        onChange = function() if ns.Rank then ns.Safe(ns.Rank.Update) end end }
    c:Buttons{ { "Open the log", function() ns.Log:Show() end, width = 140 },
        { "Start a new session", function() ns.Log:NewSession() end, width = 170 } }
    c:Text("Drag the board to move it. The reset icon up top puts it back.", true)

    local m = p:Card("Opening the log yourself")
    m:Toggle{ label = "Show a log button", key = "logButton", onChange = function() ns.Log:ApplyButton() end,
        desc = "Opens and closes the log. Drag it anywhere, right-click it to lock it in place." }
    MacroRow(m, ns.Log.MACRO_ICON, function() ns.Log:PickupMacro() end, "the log")

    local fine = p:Card("Exact sizes")
    fine:Slider{ label = "Log size", key = "logScale", min = 0.5, max = 1.6, step = 0.05, format = pct,
        onChange = function() ns.Log:Apply() end }
    fine:Slider{ label = "Button size", key = "logButtonSize", min = 24, max = 80, step = 2,
        format = function(v) return v .. " px" end, onChange = function() ns.Log:ApplyButton() end }
    p:Expander("Fine-tune", fine)
    p:ResetTool{ apply = function() ns.Log:Apply() end, extra = { "logButtonLocked" }, positions = {
        { "Reset log position", function() ns.Log:ResetPosition() end },
        { "Reset button position", function() ns.Log:ResetButton() end },
    } }
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

    -- start over as if Rubber Ducky had just been installed: click once to arm,
    -- again to do it
    local prog = p:Card("Start fresh")
    prog:Text("Wipes all of Rubber Ducky's settings, and this character's journal, challenges and Fishbones, as if it had just been installed, then reloads. Other characters keep their journals until you do this on them. This can't be undone.", true)
    local made
    made = prog:Buttons{ { "Reset everything", function()
        local b = made and made[1]
        if not b then return end
        if not b.armed then
            b.armed = true
            b.text:SetText("Sure? Click again")
            C_Timer.After(4, function() b.armed = false; b.text:SetText("Reset everything") end)
            return
        end
        ns.FactoryReset()
    end, width = 190 } }
    return p
end


-- Fishing flair: your quarterboard over your head while you fish, for other
-- Rubber Ducky anglers to see
local function FlairPage()
    local apply = function() if ns.Social then ns.Social:Apply() end end
    local p = UI.NewPage{ title = "Fishing flair", subtitle = "Your quarterboard, for Fellow Ducky Anglers to see.",
        icon = ns.MEDIA .. "Flair\\fishbone", crop = false, toggleKey = "socialEnabled", onToggle = apply }
    local c = p:Card("Your quarterboard")
    -- a live look at it, swinging and all
    local y = c:Advance(138)
    local holder = CreateFrame("Frame", nil, c.frame)
    holder:SetPoint("TOPLEFT", 24, y)
    holder:SetSize(240, 132)
    local preview = ns.Social and ns.Social.NewBoard(holder)
    if preview then preview:SetPoint("TOP", holder, "TOP", 0, -2) end
    local function Paint()
        if preview and ns.Flair then preview:Set(ns.Social.Mine(), 240, ns.Social.BoardName(ns.Social.FullName("player"))) end
    end
    p.controls[#p.controls + 1] = { Refresh = Paint }
    -- live: change something at Mrrl's (or pick a bobber) and it changes here
    if ns.Flair then ns.Flair.OnChange(function() if p.frame:IsShown() then Paint() end end) end
    c:Buttons{ { "Visit Mrrl", function() ns.Shop:Show("board") end, width = 140 } }
    c:Text("Change your quarterboard, motto and charm at Mrrl's Doohicky Emporium.", true)
    local s = p:Card("Showing boards")
    s:Toggle{ label = "Show my board to Fellow Ducky Anglers", key = "shareFlair", onChange = apply }
    s:Toggle{ label = "Show Fellow Ducky Anglers' boards", key = "seeFlair", onChange = apply }
    s:Toggle{ label = "Hang my board on the fishing log", key = "logBoard", onChange = apply,
        desc = "The game shows no name over your own head, so this is where you'll see yours." }
    s:Choice{ label = "Size", options = { { 200, "Small" }, { 240, "Medium" }, { 280, "Large" } }, key = "boardWidth",
        onChange = apply, maxWidth = 110 }
    s:Choice{ label = "Height", options = { { -6, "Low" }, { 4, "Medium" }, { 16, "High" } }, key = "boardLift",
        onChange = apply, maxWidth = 110 }
    s:Text("Boards only show while your fishing pole is out, and only if you show player names. When a Fellow Ducky Angler is fishing in your zone, friendly nameplates come on so their boards have something to hang from. Everyone's names, titles and guilds still show, and it all goes back when they leave or you put your pole away. Nobody else fishing nearby: nothing changes.", true)
    p:ResetTool{ apply = apply }
    return p
end

-------------------------------------------------------------------------------

local function Build()
    pages.overview = OverviewPage()
    category = Settings.RegisterCanvasLayoutCategory(pages.overview.frame, "Rubber Ducky")
    Settings.RegisterAddOnCategory(category)
    Options.ORDER = { { "overview", "Overview" } }
    local list = {
        { "poleswap", "Pole swap", PoleSwapPage }, { "sound", "Sound", SoundPage }, { "camera", "Camera", CameraPage },
        { "bobber", "Bobber", BobberPage }, { "onebutton", "One-button fishing", OneButtonPage },
        { "tackle", "Tackle wheel", TacklePage },
        { "catch", "Your catch", CatchPage }, { "log", "Fishing log", LogPage },
        { "journal", "Fishing journal", JournalPage }, { "flair", "Fishing flair", FlairPage },
        { "developer", "Developer", DeveloperPage },
    }
    for _, item in ipairs(list) do
        local page = item[3]()
        pages[item[1]] = page
        Options.ORDER[#Options.ORDER + 1] = { item[1], item[2] }
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

-- With some other addons installed (Auctionator on Forever), any addon opening
-- the Settings window makes the game flash "Interface action failed because of
-- an AddOn". The window still opens fine; the notice is just noise, so take
-- that one line back off the screen. Nothing else is touched.
local function ClearBlockedNotice()
    local text = INTERFACE_ACTION_BLOCKED or "Interface action failed because of an AddOn"
    local f = UIErrorsFrame
    if f and f.RemoveMessagesByPredicate then
        pcall(f.RemoveMessagesByPredicate, f, function(msg) return msg == text end)
    end
end

local openAfterCombat
function Options:Open(key)
    if ns.SettingsWindow and ns.SettingsWindow:Show(key) then return true end
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
    ClearBlockedNotice()
    C_Timer.After(0.05, function()
        if SettingsPanel and SettingsPanel:IsShown() and not ShowingOurs() then
            Call("select page", id)
        end
        ClearBlockedNotice()
    end)
    C_Timer.After(0.25, ClearBlockedNotice)
    return true
end
