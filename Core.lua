-- Rubber Ducky: fishing state, saved settings, slash commands.

local ADDON, ns = ...
_G.RubberDucky = ns

ns.defaults = {
    -- Sound
    focusEnabled      = true,
    sfxLevel          = 1.0,
    mumbleLevel       = 0.15,  -- music, ambience and dialog are scaled to this
    quietExtras       = true,
    soundInBG         = true,
    fadeIn            = 1.0,
    fadeOut           = 2.5,
    soundReturnOnLoot = true,

    -- Bobber
    sparkleEnabled = true,
    sparkleAmount  = 2,     -- 1 subtle, 2 normal, 3 lots
    sparkleSpread  = 90,
    sparkleOffsetY = -12,
    markerEnabled  = true,
    markerStyle    = 15,    -- 0 = random each cast, else index into Bobber.MARKERS (15 = duck)
    markerSize     = 56,
    markerOffsetY  = -20,   -- Low; Medium 20, High 60

    -- Camera
    cameraEnabled      = true,
    cameraZoom         = 4,
    cameraTilt         = 0.15,
    cameraShoulder     = 0,  -- negative = left
    cameraReturnOnLoot = true,

    -- One-button fishing and looting
    oneKeyEnabled   = true,
    oneKeyButton    = 4,      -- 4 Interact, 5 right trigger, 6 left trigger
    padType         = "auto", -- auto / xbox / playstation / switch
    autoLootFishing = true,

    -- Catch splash
    splashEnabled    = true,
    splashBannerKey  = "",    -- "" = a different one each catch, else a key from Splash.BANNERS
    splashSize       = 0.7,
    splashDuration   = 3,
    splashY          = 200,
    splashCatchSound = true,
    splashMisses     = true,
    splashMissSound  = true,

    -- Fishing log
    logEnabled  = true,
    logAutoOpen = true,   -- opens when a fishing pole goes on (it always closes when the pole comes off)
    logScale    = 1,
    logButton   = false,  -- a little button that opens and closes the log
    rankAlert   = true,   -- a banner under the log when you can learn the next fishing rank
    tackleOnLog = true,   -- the tackle box by the duck on the log (opens the tackle wheel)
    logButtonLocked = false, -- right-click the button to lock it in place
    logButtonSize   = 40,    -- about an action button
    journalEnabled  = true,
    challengeToasts = true,   -- the banner at the top of the screen when you finish one

    -- Fishing flair: quarterboards over heads while fishing
    socialEnabled = true,
    shareFlair    = true,    -- others see yours
    seeFlair      = true,    -- you see theirs
    logBoard      = true,    -- yours hangs off the fishing log
    boardWidth    = 240,     -- Small 200, Medium 240, Large 280
    boardLift     = 4,       -- how far above the name: Low -6, Medium 4, High 16
    journalScale    = 1,
    journalSort     = "zone",
    journalFindsSort = "type",
    journalFindsShow = "all",
    challengesShow = "all",   -- Ducky's Challenges: all, close, done or todo
    journalButton   = false,  -- an on-screen journal button, like the log's
    journalButtonLocked = false,
    journalButtonSize   = 40,

    -- Pole swap
    swapSplash = true,
    swapSound  = true,

    -- General
    welcome        = true,
    softTargetHelp = true,

    -- Developer
    debugMode    = false,
    probeEnabled = false,
    shareDebug   = false,
}

local EVENTS = CreateFrame("Frame")
ns.eventFrame = EVENTS

ns.fishing = false       -- fishing channel active
ns.sessionActive = false -- sound/camera focus applied
ns.castStart = 0

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

-- Art lives in Media\<kind>\; these build the paths.
ns.MEDIA = "Interface\\AddOns\\RubberDucky\\Media\\"
function ns.BobberArt(key) return ns.MEDIA .. "Bobbers\\" .. key end
function ns.SplashArt(kind, key) return ns.MEDIA .. "Splash\\" .. kind .. "\\" .. key end -- kind: Catch, Miss, Swap
ns.DUCK = ns.BobberArt("duck")

-- The few messages meant for chat: duck icon + name in front.
local CHAT_PREFIX = "|T" .. ns.DUCK .. ":14:14|t |cffffd100Rubber Ducky:|r "
function ns.Chat(msg) print(CHAT_PREFIX .. msg) end

-- Links in our chat lines: click one to open that part of Rubber Ducky
-- ("rubberducky:bones" opens Mrrl's, "rubberducky:settings" the settings...).
-- The game hands links it doesn't know to whoever registered for them; without
-- that (an older client) they're plain text, as clicking an unknown link would
-- be an error.
ns.LINK_OPEN = {}
if LinkUtil and LinkUtil.RegisterLinkHandler then
    ns.linkable = pcall(LinkUtil.RegisterLinkHandler, "rubberducky", function(link, _, linkData)
        local what = type(link) == "string" and link:match("rubberducky:(%w+)")
            or (type(linkData) == "table" and linkData.options) or "bones"
        local open = ns.LINK_OPEN[what]
        if open then ns.Safe(open) end
        return LinkProcessorResponse and LinkProcessorResponse.Handled
    end)
end
-- a clickable [label] in chat (or just the label, where links don't work)
function ns.Link(what, label, color)
    color = color or "ffd100"
    if not ns.linkable then return "|cff" .. color .. label .. "|r" end
    return "|cff" .. color .. "|Hrubberducky:" .. what .. "|h[" .. label .. "]|h|r"
end
ns.LINK_OPEN.settings = function() if ns.Options then ns.Options:Open() end end
ns.LINK_OPEN.whatsnew = function() if ns.Changelog then ns.Changelog:Show() end end

-- Status messages go to the debug console, never to chat.
ns.consoleLines = {}
function ns.Print(msg, ...)
    local text = select("#", ...) > 0 and string.format(msg, ...) or tostring(msg)
    local line = "|cff888888" .. date("%H:%M:%S") .. "|r  " .. text
    local lines = ns.consoleLines
    lines[#lines + 1] = line
    if #lines > 500 then table.remove(lines, 1) end
    if ns.Console then ns.Console:Add(line) end
end

-- Reading game state can hit "secret" values that throw; wrap it in Safe().
-- Developer page, "Reset everything": as if Rubber Ducky had just been
-- installed. First put back every game setting we changed while fishing (the
-- saves that remember them are about to go), then forget everything and reload.
function ns.FactoryReset()
    if ns.Social then pcall(ns.Social.Stop, ns.Social); pcall(ns.Social.RecoverFromCrash, ns.Social) end
    for _, m in ipairs({ ns.Sound, ns.Bobber, ns.Camera }) do
        if m and m.RecoverFromCrash then pcall(m.RecoverFromCrash, m) end
    end
    RubberDuckyDB = nil
    RubberDuckyJournalDB = nil
    if ReloadUI then ReloadUI() end
end

-- Shrink a line of text until it fits `room`, rather than cutting it with "...".
-- Its width is never held: a fontstring held to a width measures no wider
-- than it. Anchor it by its middle. (min: smallest size it may go)
function ns.Squeeze(fs, room, min)
    if not fs or not room or room <= 0 then return end
    fs:SetWidth(0)
    local font, size, flags = fs:GetFont()
    for _ = 1, 4 do
        local tw = fs.GetUnboundedStringWidth and fs:GetUnboundedStringWidth() or fs:GetStringWidth() or 0
        if not font or not size or tw <= room or tw <= 0 or size <= (min or 5) then break end
        size = math.max(min or 5, size * room / tw * 0.97)
        fs:SetFont(font, size, flags)
    end
    -- and left free: a held width can measure clipped next time round, and
    -- the line would flick between shrunk and cut while things move
end

-- after both have been squeezed: the second line never outgrows `ratio` of the
-- first (a name stays bigger than its motto, however long the name)
function ns.Under(top, sub, ratio)
    local _, a = top:GetFont()
    local font, b, flags = sub:GetFont()
    if a and b and font and b > a * ratio then sub:SetFont(font, a * ratio, flags) end
end

function ns.Safe(fn, ...)
    local ok, a, b, c, d = pcall(fn, ...)
    if ok then return a, b, c, d end
    return nil
end

-- Our macros' names, short so they fit under a button. Ones made before they
-- were shortened ("Ducky Log" and so on) are renamed when they're next looked
-- up, so they stay on your bars.
ns.OLD_MACRO = { Pole = { "Ducky Pole" }, Log = { "Ducky Log" }, Journal = { "Ducky Journal" },
    Lures = { "Ducky Tackle", "Lure" } }
function ns.MacroIndex(name)
    local i = ns.Safe(GetMacroIndexByName, name)
    if i and i > 0 then return i end
    local j
    for _, old in ipairs(ns.OLD_MACRO[name] or {}) do
        local x = ns.Safe(GetMacroIndexByName, old)
        if x and x > 0 then j = x; break end
    end
    if not j then return nil end
    -- not mid-fight, nor under the Macros window (an edit there can be lost)
    if InCombatLockdown() or (MacroFrame and MacroFrame:IsShown()) then return j end
    local _, icon, body = ns.Safe(GetMacroInfo, j)
    ns.Safe(EditMacro, j, name, icon, body)
    local k = ns.Safe(GetMacroIndexByName, name) -- renaming can re-sort the list
    return (k and k > 0) and k or j
end

function ns.IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

function ns.After(seconds, fn)
    C_Timer.After(seconds, fn)
end

-------------------------------------------------------------------------------
-- Fishing spell detection
-------------------------------------------------------------------------------

local FISHING_ICON = 136245 -- Trade_Fishing
local FISHING_SPELL_IDS = {
    7620, 7731, 7732, 18248, 33095, 51294, 88868, 110410,
    131474, 131490, 158743, 271616, 271990, 377895,
}
local fishingNames = {}

local function GetSpellNameCompat(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    elseif GetSpellInfo then
        return (GetSpellInfo(id))
    end
end

local function BuildFishingNames()
    for _, id in ipairs(FISHING_SPELL_IDS) do
        local name = ns.Safe(GetSpellNameCompat, id)
        if name and not ns.IsSecret(name) then fishingNames[name] = true end
    end
end

function ns.IsFishingSpell(spellID)
    if not spellID or ns.IsSecret(spellID) then return false end
    return ns.Safe(function()
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            if info then
                if fishingNames[info.name] then return true end
                if info.iconID == FISHING_ICON or info.originalIconID == FISHING_ICON then return true end
            end
        else
            local name, _, icon = GetSpellInfo(spellID)
            if fishingNames[name] or icon == FISHING_ICON then return true end
        end
        return false
    end) or false
end

function ns.PlayerIsChannelingFishing()
    return ns.Safe(function()
        local name, _, texture, _, _, _, _, spellID = UnitChannelInfo("player")
        if not name then return false end
        if fishingNames[name] or texture == FISHING_ICON then return true end
        return ns.IsFishingSpell(spellID)
    end) or false
end

-------------------------------------------------------------------------------
-- Session
-------------------------------------------------------------------------------

local lingerToken = 0
local LINGER = 5 -- seconds the focus stays after a cast, so it doesn't flap between casts

-- Auto loot by taking the slots directly: the autoLootDefault cvar gets
-- inverted by the auto-loot modifier, which a controller trigger can count as.
local function FromFishing()
    if IsFishingLoot then
        local ok, yes = pcall(IsFishingLoot)
        if ok and yes then return true end
    end
    return ns.fishing or (GetTime() - (ns.lastStop or 0)) < 2
end
ns.FromFishing = FromFishing

local lastLootPass = 0
function ns:LootCatch(gameAutoLooted)
    if not FromFishing() then return end
    local weTake = self.db.autoLootFishing and not gameAutoLooted
    if not weTake and not gameAutoLooted then return end
    if GetTime() - lastLootPass < 0.2 then return end -- LOOT_READY can come twice
    lastLootPass = GetTime()
    if self.Splash and self.db.splashEnabled then
        local ok, items = pcall(self.Splash.ReadLoot)
        if ok and items and #items > 0 then self.Safe(self.Splash.Show, self.Splash, items) end
    end
    if not weTake then return end
    local n = self.Safe(GetNumLootItems) or 0
    for i = n, 1, -1 do self.Safe(LootSlot, i) end
    if self.Probe then self.Probe:Mark(("auto loot: took %d slot(s)"):format(n)) end
end

function ns:BeginSession()
    lingerToken = lingerToken + 1
    if self.sessionActive then
        -- recast after loot restored sound/camera
        if self.Sound then self.Sound:Apply() end
        if self.Camera and not self.db.savedCamera then self.Camera:Apply() end
        return
    end
    self.sessionActive = true
    if self.Sound then self.Sound:Apply() end
    if self.Bobber then self.Bobber:ApplyCVars() end
    if self.Camera then self.Camera:Apply() end
end

-- fade: nil = normal fade-out, 0 = instant
function ns:EndSession(fade)
    if not self.sessionActive then return end
    self.sessionActive = false
    if self.Sound then self.Sound:Restore(fade) end
    if self.Bobber then self.Bobber:RestoreCVars() end
    if self.Camera then self.Camera:Restore(fade ~= 0) end
end

function ns:ScheduleEnd()
    lingerToken = lingerToken + 1
    local token = lingerToken
    local delay = LINGER
    ns.After(delay, function()
        if token == lingerToken and not ns.fishing then
            ns:EndSession()
        end
    end)
end

-------------------------------------------------------------------------------
-- Fishing state transitions
-------------------------------------------------------------------------------

function ns:OnFishingStart()
    self.fishing = true
    self.castStart = GetTime()
    self.castEnd = nil
    self.fishError = nil
    self.Safe(function()
        local _, _, _, _, endMs = UnitChannelInfo("player")
        if type(endMs) == "number" and not (issecretvalue and issecretvalue(endMs)) then
            self.castEnd = endMs / 1000
        end
    end)
    self:BeginSession()
    if self.Journal then self.Safe(self.Journal.NoteCast, self.Journal) end
    if self.OneKey then self.OneKey:Update() end
    if self.Bobber then self.Bobber:StartTracking() end
    if self.Probe then self.Probe:OnCastStart() end
end

function ns:OnFishingStop(reason)
    if not self.fishing then return end
    self.fishing = false
    self.lastStop = GetTime()
    if self.OneKey then self.OneKey:Update() end
    if self.Bobber then self.Bobber:StopTracking() end
    if self.Probe then self.Probe:OnCastStop(reason) end
    self:ScheduleEnd()
    self:CheckMiss()
end

-------------------------------------------------------------------------------
-- Misses: "timeout" when the cast ran out, "missed" for any other empty reel-in
-------------------------------------------------------------------------------

local function ErrorKind(msg)
    if type(msg) ~= "string" or (issecretvalue and issecretvalue(msg)) then return end
    if ERR_FISH_NOT_HOOKED and msg == ERR_FISH_NOT_HOOKED then return "early" end
    if ERR_FISH_ESCAPED and msg == ERR_FISH_ESCAPED then return "away" end
    local low = msg:lower()
    if low:find("no fish") and low:find("hooked") then return "early" end
    if low:find("got away") or low:find("escaped") then return "away" end
end
ns.FishErrorKind = ErrorKind

function ns:ShowMiss(kind)
    local cast = self.castStart or 0
    if self.missShownFor == cast then return end
    if (self.lastLootAt or 0) >= cast then return end
    if InCombatLockdown and InCombatLockdown() then return end
    self.missShownFor = cast
    self.misses = (self.misses or 0) + 1
    if self.Journal then self.Safe(self.Journal.NoteMiss, self.Journal) end
    if self.db.soundReturnOnLoot and self.Sound and not self.fishing then self.Sound:Restore() end
    if self.Probe then self.Probe:Mark("miss shown: " .. kind) end
    if self.Splash then self.Safe(self.Splash.ShowMiss, self.Splash, kind) end
end

-- "No fish are hooked" / "Your fish got away": a miss, shown right away
function ns:OnUIError(...)
    local a, b = ...
    local kind = ErrorKind(type(b) == "string" and b or a)
    if not kind then return end
    if not self.fishing and GetTime() - (self.lastStop or 0) > 1.5 then return end
    self.fishError = kind
    if self.Probe then self.Probe:Mark("miss: " .. kind) end
    self:ShowMiss("missed")
end

-- A cast that ran out is final; otherwise wait briefly for loot.
local LOOT_WAIT = 0.35
function ns:CheckMiss()
    local stopAt = self.lastStop
    local start = self.castStart or stopAt
    local moving = (self.Safe(GetUnitSpeed, "player") or 0) > 0
    local ranOut
    if self.castEnd then ranOut = stopAt >= self.castEnd - 0.5
    else ranOut = (stopAt - start) >= 19.5 end
    if ranOut and not self.fishError then self:ShowMiss("timeout"); return end
    ns.After(LOOT_WAIT, function()
        if self.lastStop ~= stopAt then return end
        if (self.lastLootAt or 0) >= stopAt - 0.5 then return end
        if not self.fishError and moving then return end -- walked away
        self:ShowMiss("missed")
    end)
end


-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

EVENTS:RegisterEvent("ADDON_LOADED")
EVENTS:RegisterEvent("PLAYER_LOGIN")
EVENTS:RegisterEvent("PLAYER_LOGOUT")
EVENTS:RegisterEvent("PLAYER_REGEN_DISABLED")
EVENTS:RegisterEvent("UI_ERROR_MESSAGE")
EVENTS:RegisterEvent("ADDON_ACTION_BLOCKED")
EVENTS:RegisterEvent("ADDON_ACTION_FORBIDDEN")
EVENTS:RegisterEvent("PLAYER_REGEN_ENABLED")
EVENTS:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
EVENTS:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player")
EVENTS:RegisterEvent("LOOT_OPENED")
EVENTS:RegisterEvent("LOOT_READY")
EVENTS:RegisterEvent("PLAYER_SOFT_INTERACT_CHANGED")
EVENTS:RegisterEvent("NAME_PLATE_UNIT_ADDED")
EVENTS:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

EVENTS:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name ~= ADDON then return end
        RubberDuckyDB = RubberDuckyDB or {}
        RubberDuckyDB.lastWeapons, RubberDuckyDB.lastPole = nil, nil -- 0.21 kept these account-wide
        for k, v in pairs(ns.defaults) do
            if RubberDuckyDB[k] == nil then RubberDuckyDB[k] = v end
        end
        ns.db = RubberDuckyDB
        BuildFishingNames()
        -- settings pages now, while the game is still loading: Forever's Settings
        -- window can only open straight to pages added this early (later ones
        -- show up in the list, but opening to them lands on the first addon page)
        if ns.Options then ns.Safe(ns.Options.Build, ns.Options) end

    elseif event == "PLAYER_LOGIN" then
        BuildFishingNames()
        -- put settings back if the game closed mid-session
        if ns.Sound then ns.Sound:RecoverFromCrash() end
        if ns.Bobber then ns.Bobber:RecoverFromCrash() end
        if ns.Camera then ns.Camera:RecoverFromCrash() end
        if ns.Options then ns.Options:Build() end
        if ns.Console then ns.Console:Apply() end
        if ns.Flair then ns.Safe(ns.Flair.Keep); ns.Safe(ns.Flair.HookChat) end -- the bobber you're using stays yours
        local firstTime = ns.Welcome and ns.Welcome:MaybeShowFirstTime()
        -- what's already done gets marked quietly, a moment after the world loads
        if ns.Challenges then ns.After(4, function() ns.Safe(ns.Challenges.Check, ns.Challenges) end) end
        local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
        local ok, v = pcall(get, ADDON, "Version")
        v = ok and v or nil
        -- the first login after an update says so, once (if you like the hello)
        local updated = v and not firstTime and ns.db.lastVersion ~= v
        if v then ns.db.lastVersion = v end
        if ns.db.welcome and not firstTime then
            -- with a link to click, where the game allows them
            if updated then
                if ns.linkable then
                    ns.Chat(string.format("Quack! Updated to v%s. %s", v, ns.Link("whatsnew", "See what's new")))
                else
                    ns.Chat(string.format("Quack! Updated to v%s. See what's new: type |cffffd100/ducky|r, then press What's new.", v))
                end
            elseif ns.linkable then
                ns.Chat(string.format("Quack! %sis ready to fish. %s", v and ("v" .. v .. " ") or "", ns.Link("settings", "Settings")))
            else
                ns.Chat(string.format("Quack! %sis ready to fish. Type |cffffd100/ducky|r for settings.",
                    v and ("v" .. v .. " ") or ""))
            end
        end

    elseif event == "PLAYER_LOGOUT" then
        ns.fishing = false
        ns:EndSession(0)

    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.fishing = false
        if ns.Bobber then ns.Bobber:StopTracking() end
        ns:EndSession(0.5)

    elseif event == "PLAYER_REGEN_ENABLED" then
        if ns.Bobber then ns.Bobber:FlushPending() end

    elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
        local _, _, spellID = ...
        if ns.IsFishingSpell(spellID) or ns.PlayerIsChannelingFishing() then
            ns:OnFishingStart()
        end

    elseif event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        if ns.fishing then ns:OnFishingStop("channel stop") end

    elseif event == "PLAYER_SOFT_INTERACT_CHANGED" then
        if ns.Bobber then ns.Bobber:OnSoftInteractChanged(...) end

    elseif event == "NAME_PLATE_UNIT_ADDED" then
        if ns.Bobber then ns.Bobber:OnPlateAdded(...) end

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        if ns.Bobber then ns.Bobber:OnPlateRemoved(...) end

    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        -- log every blocked action; the blame can land on the wrong addon
        local who, what = ...
        local context = ns.lastUIStep or (GetTime() - (ns.openedSettingsAt or -99) < 2 and "opening settings") or "-"
        ns.Print("|cffff6060%s|r by %s: %s (during: %s)", event == "ADDON_ACTION_FORBIDDEN" and "forbidden" or "blocked",
            tostring(who), tostring(what), context)
        if ns.Probe then ns.Probe:Mark(("blocked: %s %s"):format(tostring(who), tostring(what))) end

    elseif event == "UI_ERROR_MESSAGE" then
        ns:OnUIError(...)

    elseif event == "LOOT_READY" or event == "LOOT_OPENED" then
        local fromFishing = FromFishing()
        if fromFishing then
            ns.lastLootAt = GetTime()
            -- read the catch before auto loot takes it
            if ns.Log and ns.Splash then
                local ok, items = pcall(ns.Splash.ReadLoot)
                if ok then
                    local fresh = ns.Journal and ns.Safe(ns.Journal.Record, ns.Journal, items)
                    ns.Safe(ns.Log.Add, ns.Log, items, fresh)
                end
            end
        end
        -- LOOT_READY's argument: the game is already auto-looting
        if event == "LOOT_READY" then ns:LootCatch((...)) end
        -- once per catch, on whichever loot event comes first
        if fromFishing and GetTime() - (ns.lastLootReturn or 0) > 1 then
            ns.lastLootReturn = GetTime()
            if ns.db.cameraReturnOnLoot and ns.Camera then ns.Camera:Restore(true) end
            if ns.db.soundReturnOnLoot and ns.Sound then ns.Sound:Restore() end
        end
        if ns.fishing or (GetTime() - ns.castStart) < 35 then
            if ns.Probe then ns.Probe:Mark("LOOT_OPENED") end
        end
    end
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------

local function Help()
    ns.Chat("here's what I can do:")
    print("  /ducky               open settings")
    print("  /ducky test          preview the sparkle and bobber icon")
    print("  /ducky icons         pick your bobber icon from a grid")
    print("  /ducky focus | sparkle | marker | camera | onekey   turn a feature on or off")
    print("  /ducky swap          swap between your fishing pole and weapon")
    print("  /ducky swap 1 | 2    put on your pole (1) or weapon (2)")
    print("  /ducky log           open or close the fishing log")
    print("  /ducky journal       open or close the fishing journal")
    print("  /ducky challenges    open or close Ducky's Challenges")
    print("  /ducky shop          visit Mrrl's Doohicky Emporium")
    print("  /ducky tackle        the tackle wheel: your lures, camp gear and more")
    print("  /ducky welcome       show the welcome screen again")
    print("  /ducky restore       put your sound, camera and soft-target settings back now")
    -- developer commands (debug, console, button, probe, events, mark, flairtest, ranktest) aren't listed
end

local function Toggle(key, label)
    ns.db[key] = not ns.db[key]
    ns.Print("%s %s", label, ns.db[key] and "|cff00ff00on|r" or "|cffff4040off|r")
end

SLASH_RUBBERDUCKY1 = "/ducky"
SlashCmdList.RUBBERDUCKY = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" or msg == "config" or msg == "options" then
        if ns.Options and ns.Options:Open() then return end
        Help()
    elseif msg == "test" then
        if ns.Bobber then ns.Bobber:Preview() end
    elseif msg == "focus" then Toggle("focusEnabled", "Sound focus")
    elseif msg == "sparkle" then Toggle("sparkleEnabled", "Bobber sparkle")
    elseif msg == "marker" then Toggle("markerEnabled", "Bobber marker")
    elseif msg == "camera" then Toggle("cameraEnabled", "Fishing camera")
    elseif msg == "button" then
        if ns.OneKey then ns.OneKey:Status() end
    elseif msg == "onekey" then
        Toggle("oneKeyEnabled", "One-button fishing")
        if ns.OneKey then ns.OneKey:Update() end
    elseif msg == "tackle" or msg == "wheel" then
        if ns.Tackle then ns.Tackle:Toggle() end
    elseif msg == "icons" then
        if ns.Picker then ns.Picker:Toggle() end
    elseif msg:match("^swap") then
        local target = msg:match("^swap%s+(%w+)")
        if target == "1" then target = "pole"
        elseif target == "2" or target == "wep" then target = "weapon" end
        if ns.Gear then ns.Gear:Swap(target) end
    elseif msg == "welcome" then
        if ns.Welcome then ns.Welcome:Show() end
    elseif msg == "debug" then
        Toggle("debugMode", "Debug mode")
        if ns.Console then ns.Console:Apply() end
    elseif msg == "console" then
        if ns.Console then ns.Console:Toggle() end
    elseif msg == "probe" then
        Toggle("probeEnabled", "Event recorder")
        if ns.db.probeEnabled then
            if not ns.db.debugMode then ns.Print("the event recorder only runs in debug mode (/ducky debug).") end
            ns.Print("Cast a few times (/ducky mark notes a moment), then /ducky events.")
        end
    elseif msg == "log" then
        if ns.Log then ns.Log:Toggle(true) end
    elseif msg == "journal" then
        if ns.Journal then ns.Journal:Toggle(true) end
    elseif msg == "challenges" then
        if ns.ChallengesWindow then ns.ChallengesWindow:Toggle() end
    elseif msg:match("^ranktest") then
        -- /ducky ranktest apprentice|journeyman|expert|artisan (or nothing, to stop)
        if ns.Rank then ns.Rank.Test(msg:match("^ranktest%s+(%a+)")) end
    elseif msg == "flairtest" then
        if ns.Social then ns.Social:Test() end
    elseif msg == "shop" or msg == "mrrl" then
        if ns.Shop then ns.Shop:Toggle() end
    elseif msg == "events" then
        if ns.Probe then ns.Probe:ShowLog() end
    elseif msg == "mark" then
        if ns.Probe then ns.Probe:Mark("you marked this moment") end
    elseif msg == "restore" then
        ns.fishing = false
        ns:EndSession()
        ns.Print("settings restored.")
    else
        Help()
    end
end
