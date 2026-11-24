-- Rubber Ducky: Fishing Flair out in the world. While your pole is out, your
-- quarterboard (with your motto, bobber and charm) hangs over your head for
-- other Rubber Ducky anglers to see, and theirs over theirs.
--
-- How: the game draws players' names itself, so nothing can be pinned to them;
-- a nameplate is the only thing that follows a player. Flair travels over a
-- hidden addon channel, with the zone you're in. Only when another Rubber Ducky
-- angler is fishing in your zone (and you show player names) do friendly
-- nameplates come on: the game's plates are hidden, names are written back the
-- game's way, and boards hang on the invisible plates. Nobody else around:
-- nameplates and names are left alone. Pole away: everything goes back. Forever has no nameplate for yourself, so your own board
-- shows on the fishing log instead.

local ADDON, ns = ...
local Social = {}
ns.Social = Social

local PREFIX = "RubberDucky"
local CHANNEL = "RubberDuckyFlair"
local VERSION = "1"
local STALE = 200        -- seconds without word before a board comes down
local HEARTBEAT = 90     -- how often you say your flair again while fishing
local PLATE_CVAR = "nameplateShowFriendlyPlayers"

local active = false     -- your pole is out: sharing and listening
local platesOn = false   -- another angler's fishing in your zone: boards up
local seen = {}          -- [full name] = { bobber, board, charm, motto, at }
local boards = {}        -- [nameplate token] = board frame
local pool = {}
local lastSent, lastReply, pendingSend = 0, 0, false
Social.seen = seen

local function db() return ns.db or {} end
local function Now() return GetTime and GetTime() or 0 end

-------------------------------------------------------------------------------
-- A quarterboard: the board, its motto on the plank, your bobber and charm
-- swinging from its hooks. w: how wide; o.name: put a name on it too
-------------------------------------------------------------------------------

local function Swing(tex, phase)
    if not tex.CreateAnimationGroup then return end
    local ag = tex:CreateAnimationGroup()
    -- out one way, back past the middle, and home again: a gentle swing
    local degrees = { 5, -10, 5 }
    local times = { 0.9, 1.8, 0.9 }
    for i = 1, 3 do
        local r = ag:CreateAnimation("Rotation")
        r:SetDegrees(degrees[i] * (phase or 1))
        r:SetDuration(times[i])
        r:SetOrder(i)
        r:SetSmoothing("IN_OUT")
        if r.SetOrigin then r:SetOrigin("TOP", 0, 0) end
    end
    ag:SetLooping("REPEAT")
    tex.swing = ag
    return ag
end

function Social.NewBoard(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.tex = f:CreateTexture(nil, "ARTWORK", nil, 1)
    -- the bobber and charm in front of the board, hanging from its rivets
    f.bobber = f:CreateTexture(nil, "ARTWORK", nil, 2)
    f.charm = f:CreateTexture(nil, "ARTWORK", nil, 2)
    f.tex:SetPoint("TOP")
    f.motto = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.motto:SetWordWrap(false)
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.name:SetWordWrap(false)
    Swing(f.bobber, 1)
    Swing(f.charm, -1)
    -- flair: { board, motto, bobber, charm } as items (Flair.Get); w: width
    -- textScale: bigger or smaller words than usual
    -- hang: the bobber and charm's size, if not in step with the board
    function f:Set(flair, w, name, textScale, hang)
        local key = table.concat({ flair.board and flair.board.key or "", flair.motto and flair.motto.key or "",
            flair.bobber and flair.bobber.key or "", flair.charm and flair.charm.key or "",
            w, name or "", textScale or 1, hang or 0 }, "|")
        if key == self.laidOut then return end -- the same as last time: leave it be
        self.laidOut = key
        local F = ns.Flair
        local L = F.BOARD -- every board shares one layout
        local b = flair.board or F.Get("board", F.DEFAULT.board)
        local h = w / 2
        hang = hang or math.floor(w * 0.2 + 0.5)
        self:SetSize(w, h) -- just the board: the bobber and charm hang below it
        self.foot = h * L.foot -- below the plank
        self.tex:SetSize(w, h)
        self.tex:SetTexture(b.art)
        self.tex:SetTexCoord(0, 1, 0, 1)
        -- the words on the plank: the name leads, the motto a size smaller beneath it
        local ph, cy, room = h * L.plank.h / 256, h * (b.py or L.plank.y) / 256, w * L.plank.w
        local font = self.motto:GetFont()
        local size = math.max(7, ph * 0.5 * (textScale or 1))
        if font then self.motto:SetFont(font, name and size * 0.8 or size, "OUTLINE") end
        self.motto:ClearAllPoints()
        self.motto:SetTextColor(1, 0.82, 0)
        if name then
            if font then self.name:SetFont(font, size, "OUTLINE") end
            self.name:ClearAllPoints(); self.name:SetPoint("CENTER", self, "TOP", 0, -(cy - ph * 0.2))
            self.motto:SetPoint("CENTER", self, "TOP", 0, -(cy + ph * 0.26))
            self.name:SetText(name)
            self.name:Show()
        else
            self.motto:SetPoint("CENTER", self, "TOP", 0, -cy)
            self.name:Hide()
        end
        self.motto:SetText(flair.motto and flair.motto.name or "")
        -- a long motto (or name, like "Wizardy McWizardpant") shrinks to fit the plank, not "..."
        ns.Squeeze(self.motto, room)
        if name then
            ns.Squeeze(self.name, room)
            ns.Under(self.name, self.motto, 0.8) -- and the name always the bigger
        end
        -- the bobber and charm hang from the rivets either end of the plank
        for _, k in ipairs({ "bobber", "charm" }) do
            local t, it = self[k], flair[k]
            if it then
                t:SetTexture(it.art)
                t:SetSize(hang, hang)
                t:ClearAllPoints()
                -- a touch below the rivet's middle, so it hangs from it
                local rx = k == "bobber" and (b.rl or L.rivets[1]) or (b.rr or L.rivets[2])
                t:SetPoint("TOP", self, "TOPLEFT", w * rx / 512, -h * (L.rivets[3] / 256 + 0.05))
                t:Show()
                if t.swing and not t.swing:IsPlaying() then t.swing:Play() end
            else
                t:Hide()
            end
        end
    end
    return f
end

-- your own flair, as items
function Social.Mine()
    local F = ns.Flair
    local bobber = F.Worn("bobber")
    if bobber and not F.Owns(bobber) then bobber = F.Get("bobber", "duck") end -- what the marker shows, too
    return { board = F.Worn("board"), motto = F.Worn("motto"), bobber = bobber, charm = F.Worn("charm") }
end

-- someone else's, from the keys they sent: anything we don't know falls back
local function Theirs(s)
    local F = ns.Flair
    return {
        board = F.Get("board", s.board) or F.Get("board", F.DEFAULT.board),
        motto = F.Get("motto", s.motto) or F.Get("motto", F.DEFAULT.motto),
        bobber = F.Get("bobber", s.bobber),
        charm = F.Get("charm", s.charm) or F.Get("charm", F.DEFAULT.charm),
    }
end

-------------------------------------------------------------------------------
-- Talking: a hidden channel only Rubber Ducky uses
-------------------------------------------------------------------------------

local function ChannelID()
    local id = GetChannelName and GetChannelName(CHANNEL)
    if type(id) == "number" and id > 0 then return id end
end

-- the channel never shows in chat: no "joined" line, no tab
local function Hush()
    if not ChatFrame_AddMessageEventFilter or Social.hushed then return end
    Social.hushed = true
    local function ours(_, _, ...)
        for i = 1, select("#", ...) do
            local v = select(i, ...)
            if type(v) == "string" and v:find(CHANNEL, 1, true) then return true end
        end
    end
    for _, e in ipairs({ "CHAT_MSG_CHANNEL_NOTICE", "CHAT_MSG_CHANNEL_NOTICE_USER", "CHAT_MSG_CHANNEL_JOIN",
        "CHAT_MSG_CHANNEL_LEAVE", "CHAT_MSG_CHANNEL" }) do
        ChatFrame_AddMessageEventFilter(e, ours)
    end
end

local function Join()
    if ChannelID() then return true end
    Hush()
    if JoinTemporaryChannel then pcall(JoinTemporaryChannel, CHANNEL) end
    -- keep it out of every chat window
    if ChatFrame_RemoveChannel then
        for i = 1, (NUM_CHAT_WINDOWS or 10) do
            local cf = _G["ChatFrame" .. i]
            if cf then pcall(ChatFrame_RemoveChannel, cf, CHANNEL) end
        end
    end
    return ChannelID() ~= nil
end

local function Send(msg)
    local id = ChannelID()
    if not id or not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return false end
    return pcall(C_ChatInfo.SendAddonMessage, PREFIX, msg, "CHANNEL", id)
end

-- the zone you're in: boards only matter to anglers in the same one
local function MyMap()
    local m = C_Map and C_Map.GetBestMapForUnit and ns.Safe(C_Map.GetBestMapForUnit, "player")
    return m and tostring(m) or "?"
end
Social.MyMap = MyMap

-- A tag on everything we send, so our own messages coming back to us on the
-- channel are never mistaken for someone else's (names alone aren't reliable:
-- the sender can come back spelled differently from UnitName)
Social.ME = ("%x%x"):format(math.random(0, 0xFFFFFF), math.floor((GetTime and GetTime() or 0) * 1000) % 0xFFFFFF)

local function Encode()
    local m = Social.Mine()
    local function k(it) return it and it.key or "-" end
    return table.concat({ "F" .. VERSION, k(m.bobber), k(m.board), k(m.charm), k(m.motto), MyMap(), Social.ME }, "|")
end
Social.Encode = Encode

local function Sharing() return db().socialEnabled and db().shareFlair end

-- say your flair (not more than once every few seconds)
function Social:Announce()
    if not active or not Sharing() then return end
    if Now() - lastSent < 3 then
        if not pendingSend and C_Timer then
            pendingSend = true
            C_Timer.After(3, function() pendingSend = false; Social:Announce() end)
        end
        return
    end
    if Send(Encode()) then lastSent = Now() end
end

local function Short(name) return name and (name:gsub("%-.*$", "")) end
-- Forever names have a first and last name; boards show both.
-- Forever's UnitName gives only the first name; GetUnitName(unit, true)
-- gives the whole thing ("Healbert Mchealface")
function Social.FullName(unit)
    local full = GetUnitName and ns.Safe(GetUnitName, unit, true)
    if type(full) == "string" and full ~= "" then return full end
    return UnitName and ns.Safe(UnitName, unit)
end
function Social.BoardName(name)
    return Short(name) -- the whole name: a long one shrinks to fit the plank
end

function Social.Receive(prefix, msg, channel, sender)
    if prefix ~= PREFIX or type(msg) ~= "string" then return end
    local who = Short(sender)
    if not who then return end
    local mine = Short(UnitName and UnitName("player"))
    if mine and who:lower() == mine:lower() then return end
    -- our own tag: ourselves, whatever the name says
    local tag = msg:match("|([%x]+)$")
    if tag and tag == Social.ME then return end
    local kind = msg:sub(1, 1)
    if kind == "F" then
        local _, bobber, board, charm, motto, map = strsplit("|", msg) -- (then our tag)
        local function v(x) return x ~= "-" and x or nil end
        seen[who] = { bobber = v(bobber), board = v(board), charm = v(charm), motto = v(motto), map = map, at = Now() }
        Social:Update()
    elseif kind == "X" then
        seen[who] = nil
        Social:Update()
    elseif kind == "Q" then
        -- someone just got their pole out: say yours, after a moment, so a
        -- crowd doesn't all answer at once
        if active and Sharing() and Now() - lastReply > 20 and C_Timer then
            lastReply = Now()
            C_Timer.After(1 + math.random() * 3, function() Social:Announce() end)
        end
    end
end

-------------------------------------------------------------------------------
-- The boards over heads
-------------------------------------------------------------------------------

local function Seeing() return platesOn end

local function Plate(token)
    return C_NamePlate and C_NamePlate.GetNamePlateForUnit and ns.Safe(C_NamePlate.GetNamePlateForUnit, token)
end

local function FriendlyPlayer(token)
    return ns.Safe(UnitIsPlayer, token) and ns.Safe(UnitIsFriend, "player", token)
        and not ns.Safe(UnitIsUnit, token, "player")
end

-- The game's own plate: hidden while we're fishing, back afterwards. With
-- friendly nameplates on, the game stops drawing players' names over their
-- heads (the plate has them now), so while the plate is hidden we write the
-- name back ourselves, the game's way: title and name, and <Guild> under it.
local hiddenPlates, tags, tagPool = {}, {}, {}

local function NewTag()
    local t = CreateFrame("Frame", nil, UIParent)
    t:SetSize(300, 50)
    t.name = t:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    t.guild = t:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    for i, fs in ipairs({ t.name, t.guild }) do
        -- the game's floating names: its own font, a drop shadow, no outline;
        -- big up close, and the plate's scale shrinks them with distance
        local font = fs:GetFont()
        if font then fs:SetFont(font, i == 1 and 24 or 21, "") end
        fs:SetShadowColor(0, 0, 0, 1)
        fs:SetShadowOffset(1.5, -1.5)
        fs:SetWordWrap(false)
    end
    t.guild:SetPoint("BOTTOM", t, "BOTTOM", 0, 0)
    return t
end

-- the colour the game gives a friendly player's floating name (the plate's
-- own name is white, so it's no guide)
local function NameColor()
    return 0.41, 0.41, 1
end

local function PaintTag(token)
    local p = hiddenPlates[token]
    local t = tags[token]
    if not (p and t) then return end
    local name = ns.Safe(UnitPVPName, token) or ns.Safe(UnitName, token) or ""
    local guild = ns.Safe(GetGuildInfo, token)
    local r, g, b = NameColor()
    t.name:SetText(name)
    t.name:SetTextColor(r, g, b)
    t.name:Show()
    t.guild:SetText(guild and guild ~= "" and ("<" .. guild .. ">") or "")
    local font = t.guild:GetFont()
    if font then t.guild:SetFont(font, 21, "") end -- full size again if a board had shrunk it
    t.guild:SetWidth(0) -- and no longer held to the board's width
    t.guild:SetTextColor(r, g, b)
    t.name:ClearAllPoints()
    if guild and guild ~= "" then
        t.name:SetPoint("BOTTOM", t.guild, "TOP", 0, 0)
    else
        t.name:SetPoint("BOTTOM", t, "BOTTOM", 0, 0)
    end
    t:SetHeight(((guild and guild ~= "") and 48 or 26))
end
Social.tags = tags

-- The game turns its plate back on now and then: when you target someone,
-- when they start casting (their Fishing bar). So every frame, from our own
-- code and never from inside the game's (hooking its nameplate functions taints
-- them, and the game then blocks things like clicking a plate to target), any
-- hidden plate that's come back goes straight back to nothing.
local function KeepHidden()
    for _, p in pairs(hiddenPlates) do
        local uf = p.UnitFrame
        if uf and uf:GetAlpha() > 0 then uf:SetAlpha(0) end
    end
end

local function HidePlate(token)
    local p = Plate(token)
    if not (p and p.UnitFrame) then return end
    p.UnitFrame:SetAlpha(0)
    hiddenPlates[token] = p
    local t = tags[token] or table.remove(tagPool) or NewTag()
    tags[token] = t
    t:SetParent(p)
    t:ClearAllPoints()
    -- where the game's name would be: just over the head, at the plate's foot
    t:SetPoint("BOTTOM", p, "BOTTOM", 0, 0)
    t:Show()
    PaintTag(token)
end
local function ShowPlate(token)
    local p = hiddenPlates[token]
    if p and p.UnitFrame then p.UnitFrame:SetAlpha(1) end
    hiddenPlates[token] = nil
    local t = tags[token]
    if t then t:Hide(); t:ClearAllPoints(); tags[token] = nil; tagPool[#tagPool + 1] = t end
end

local function Drop(token)
    local b = boards[token]
    if b then
        b:Hide(); b:ClearAllPoints()
        pool[#pool + 1] = b
        boards[token] = nil
        PaintTag(token) -- the name goes back on top of the guild
    end
end

local function Hang(token)
    local p = Plate(token)
    if not p then return end
    local who = Short(ns.Safe(UnitName, token))
    local s = who and seen[who]
    if not s or Now() - s.at > STALE then Drop(token); return end
    local b = boards[token]
    if not b then
        b = table.remove(pool) or Social.NewBoard(UIParent)
        boards[token] = b
    end
    b:SetParent(p)
    b:Set(Theirs(s), db().boardWidth or 240, Social.BoardName(Social.FullName(token) or who))
    b:ClearAllPoints()
    -- their first name and motto on the board, and the guild (usually shorter)
    -- under it, between the bobber and charm hanging from its hooks
    local tag = tags[token]
    local lift = db().boardLift or 4
    if tag then
        local hasGuild = (tag.guild:GetText() or "") ~= ""
        -- the plank sits on the guild line; the hooks come down either side of it
        local drop = (b.foot or 0) - 2
        if hasGuild then b:SetPoint("BOTTOM", tag.guild, "TOP", 0, lift - drop)
        else b:SetPoint("BOTTOM", tag, "BOTTOM", 0, lift - drop) end
        tag.name:Hide() -- it's on the board now
        -- the guild, smaller, between the hooks under the board; a long one
        -- (up to 24 letters) shrinks a little more to fit
        local font = tag.guild:GetFont()
        if font then
            tag.guild:SetFont(font, 13, "")
            ns.Squeeze(tag.guild, b:GetWidth() * 0.74, 9)
        end
    else
        b:SetPoint("BOTTOM", p, "BOTTOM", 0, 20 + lift)
    end
    b:Show()
end

function Social:Paint()
    if not Seeing() then
        for token in pairs(boards) do Drop(token) end
        return
    end
    for token in pairs(hiddenPlates) do Hang(token) end
    for token in pairs(boards) do if not hiddenPlates[token] then Drop(token) end end
end

function Social:OnPlateAdded(token)
    if not platesOn or not FriendlyPlayer(token) then return end
    HidePlate(token)
    if Seeing() then Hang(token) end
end

function Social:OnPlateRemoved(token)
    Drop(token)
    ShowPlate(token)
end

-------------------------------------------------------------------------------
-- Pole out, pole away
-------------------------------------------------------------------------------

local function NamesOn()
    local v = ns.Safe(GetCVar, "UnitNameFriendlyPlayerName")
    return v == nil or v == "1"
end

-- Friendly nameplates on (each setting remembered), or put back. Plates also
-- shrink with distance about as much as the game's names do, so the names we
-- write on them look like the game's own.
local PLATE_CVARS = { { PLATE_CVAR, "1" }, { "nameplateMinScale", "0.5" }, { "nameplateMaxScale", "1" } }
local pendingPlates
local function SetPlates(on)
    if InCombatLockdown and InCombatLockdown() then pendingPlates = on; return end
    pendingPlates = nil
    local d = db()
    if type(d.savedPlates) == "string" then d.savedPlates = { [PLATE_CVAR] = d.savedPlates } end
    if on then
        if d.savedPlates == nil then
            d.savedPlates = {}
            for _, c in ipairs(PLATE_CVARS) do d.savedPlates[c[1]] = ns.Safe(GetCVar, c[1]) end
        end
        for _, c in ipairs(PLATE_CVARS) do
            if d.savedPlates[c[1]] ~= nil then ns.Safe(SetCVar, c[1], c[2]) end
        end
    elseif d.savedPlates ~= nil then
        for k, v in pairs(d.savedPlates) do ns.Safe(SetCVar, k, v) end
        d.savedPlates = nil
    end
end

-- someone else with Rubber Ducky fishing in your zone, heard from lately
local function AnyoneHere()
    local here = MyMap()
    for _, v in pairs(seen) do
        if Now() - v.at <= STALE and (v.map == here or v.map == nil) then return true end
    end
    return false
end

-- how many other Rubber Ducky anglers are fishing in your zone right now:
-- fishing together brings a little Fishbone luck (Flair.Luck)
function Social.Buddies()
    if not active then return 0 end
    local here, n = MyMap(), 0
    for _, v in pairs(seen) do
        if Now() - v.at <= STALE and v.map == here then n = n + 1 end
    end
    return n
end

-- boards up only while another angler's fishing in your zone; otherwise
-- nameplates (and everyone's names) are left exactly as the game has them
function Social:Update()
    local want = active and db().socialEnabled and db().seeFlair and NamesOn() and AnyoneHere()
    if want and not platesOn then
        platesOn = true
        SetPlates(true)
        for i = 1, 40 do
            local token = "nameplate" .. i
            if Plate(token) and FriendlyPlayer(token) then HidePlate(token) end
        end
    elseif not want and platesOn then
        platesOn = false
        for token in pairs(boards) do Drop(token) end
        for token in pairs(hiddenPlates) do ShowPlate(token) end
        SetPlates(false)
    end
    Social:Paint()
end

function Social:Start()
    if active then return end
    if not db().socialEnabled then return end
    if not (db().shareFlair or db().seeFlair) then return end
    active = true
    Join()
    -- say hello, and ask who else is fishing
    if C_Timer then
        C_Timer.After(1 + math.random() * 2, function()
            if not active then return end
            Social:Announce()
            Send("Q" .. VERSION .. "|" .. Social.ME)
        end)
    end
    Social:Update()
    Social:LogBoard()
end

function Social:Stop()
    if not active then return end
    active = false
    if Sharing() then Send("X" .. VERSION .. "|" .. Social.ME) end
    Social:Update()
    Social:LogBoard()
end

function Social:IsActive() return active end
function Social:PlatesOn() return platesOn end

function Social:PoleCheck()
    local pole = ns.Gear and ns.Gear.PoleEquipped() and true or false
    if pole then self:Start() else self:Stop() end
end

-- settings changed: start over
function Social:Apply()
    self:Stop()
    self:PoleCheck()
    self:LogBoard()
end

-- the game closed while fishing: nameplates back the way they were
function Social:RecoverFromCrash()
    if db().savedPlates ~= nil then SetPlates(false) end
end

-- Trying it with nobody else around: target a friendly player while fishing
-- and they "wear" your flair for a minute or so (/ducky flairtest)
function Social:Test()
    if not active then ns.Print("get your fishing pole out first."); return end
    if not NamesOn() then ns.Print("turn on player names first: boards hang over names."); return end
    local who = Short(ns.Safe(UnitName, "target"))
    if not who or not FriendlyPlayer("target") then ns.Print("target a friendly player first."); return end
    local keys = {}
    for k, it in pairs(Social.Mine()) do keys[k] = it.key end
    keys.at, keys.map = Now(), MyMap()
    seen[who] = keys
    Social:Update()
    ns.Print("%s is wearing your quarterboard for a bit.", who)
end

-------------------------------------------------------------------------------
-- Your own board, hanging off the top of the fishing log
-------------------------------------------------------------------------------

function Social:LogBoard()
    local log = _G.RubberDuckyLog
    local want = log and db().socialEnabled and db().logBoard and ns.Flair
    if not want then
        if Social.mine then Social.mine:Hide() end
        return
    end
    if not Social.mine then
        Social.mine = Social.NewBoard(log)
    end
    local b = Social.mine
    -- resting on the top plank, the bobber and charm dangling over it
    b:Set(Social.Mine(), 260, Social.BoardName(Social.FullName("player")), 1, 60)
    b:ClearAllPoints()
    b:SetPoint("BOTTOM", log, "TOP", 15, -52 - (b.foot or 0))
    b:SetFrameLevel(log:GetFrameLevel() + 10) -- the bobber and charm in front of the title
    b:Show()
end

-------------------------------------------------------------------------------

local ev = CreateFrame("Frame")
for _, e in ipairs({ "PLAYER_LOGIN", "PLAYER_EQUIPMENT_CHANGED", "CHAT_MSG_ADDON", "NAME_PLATE_UNIT_ADDED",
    "NAME_PLATE_UNIT_REMOVED", "PLAYER_REGEN_ENABLED", "CVAR_UPDATE", "ZONE_CHANGED_NEW_AREA" }) do ev:RegisterEvent(e) end
local ticker = 0
ev:SetScript("OnEvent", function(_, event, a, b, c, d)
    if event == "PLAYER_LOGIN" then
        if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
        Social:RecoverFromCrash()
        if ns.Flair then ns.Flair.OnChange(function() Social:Announce(); Social:LogBoard() end) end
        if C_Timer then C_Timer.After(3, function() Social:PoleCheck() end) end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        if a ~= 16 then return end
        if C_Timer then C_Timer.After(0.3, function() Social:PoleCheck() end) end
    elseif event == "CHAT_MSG_ADDON" then
        Social.Receive(a, b, c, d)
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        Social:OnPlateAdded(a)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Social:OnPlateRemoved(a)
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        -- new zone: tell anglers here, and check who's around
        if active then Social:Announce(); Social:Update() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if pendingPlates ~= nil then SetPlates(pendingPlates) end
    elseif event == "CVAR_UPDATE" then
        -- player names switched off while fishing: boards come down
        if a == "UnitNameFriendlyPlayerName" or a == "UNIT_NAME_FRIENDLY_PLAYER_NAME" then
            if C_Timer then C_Timer.After(0, function() Social:Apply() end) end
        end
    end
end)
-- while fishing: say it again now and then, and take down boards gone quiet
ev:SetScript("OnUpdate", function(_, el)
    if not active then return end
    if platesOn then KeepHidden() end
    ticker = ticker + el
    if ticker < 5 then return end
    ticker = 0
    if Now() - lastSent > HEARTBEAT then Social:Announce() end
    for who, s in pairs(seen) do if Now() - s.at > STALE then seen[who] = nil end end
    Social:Update()
end)
