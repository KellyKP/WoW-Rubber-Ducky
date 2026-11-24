-- Rubber Ducky: Ducky's Challenges. Little goals worked out from what the
-- journal already keeps, per character. Finishing one pops a banner at the top
-- of the screen; the window (ChallengesWindow.lua) shows them all.
--
-- Challenges are built so that, where possible, each counts something no other
-- one counts (fish, junk and treasure apart; casts apart from catches; Steady
-- Hands judged when a session ends). When two do finish together, the banners
-- queue up and play one after the other.

local ADDON, ns = ...
local CH = {}
ns.Challenges = CH

CH.GROUPS = {
    { "all", "All challenges", "Every dare Ducky's ever thought up." },
    { "waters", "Waters", "Ducky bets you can't fish these places dry." },
    { "collection", "Collection", "A little of everything, and then everything." },
    { "streaks", "Streaks", "Keep it going. Or don't, Ducky's not judging." },
    { "sessions", "Sessions", "What you can do in one sitting." },
    { "fun", "Just for fun", "The silly ones. Some you'll find by accident." },
}

-- Kalimdor's zones; the rest of the known zones are the Eastern Kingdoms,
-- except Zephras Isle (its own shore) and Riverglades (we don't know yet).
local KALIMDOR = {}
for _, z in ipairs({ "Ashenvale", "Azshara", "Darkshore", "Darnassus", "Desolace", "Durotar", "Dustwallow Marsh",
    "Felwood", "Feralas", "Moonglade", "Mulgore", "Orgrimmar", "Silithus", "Stonetalon Mountains", "Tanaris",
    "Teldrassil", "The Barrens", "Thousand Needles", "Thunder Bluff", "Un'Goro Crater", "Winterspring",
    "Mount Hyjal" }) do KALIMDOR[z] = true end
local function Shore(zone)
    if zone == "Zephras Isle" then return "isle" end
    if KALIMDOR[zone] then return "kalimdor" end
    if zone ~= "Riverglades" and ns.JournalData and ns.JournalData.ZONES[zone] then return "kingdoms" end
end

-- What every challenge needs, worked out once per check from the journal.
local function Facts()
    local J = ns.Journal
    local j, D = J.DB(), ns.JournalData
    local st = J.Stats()
    local f = { st = st, j = j, zones = 0, shores = {}, regular = 0, homebody = 0,
        fish = 0, junk = 0, treasure = 0, allFish = 0, allJunk = 0, allTreasure = 0,
        nFish = 0, nJunk = 0, nTreasure = 0, quality = {}, hoard = 0, litter = 0,
        wrong = false }
    -- where each item has been caught
    local caughtIn, seenZone = {}, {}
    for _, spot in pairs(j.spots or {}) do
        if (spot.count or 0) > 0 and spot.zone and spot.zone ~= "Unknown waters" then
            if not seenZone[spot.zone] then
                seenZone[spot.zone] = true
                f.zones = f.zones + 1
                local s = Shore(spot.zone)
                if s then f.shores[s] = true end
            end
            f.regular = math.max(f.regular, spot.days or 0)
            f.homebody = math.max(f.homebody, spot.count or 0)
            for id, n in pairs(spot.items or {}) do
                if n > 0 then
                    caughtIn[id] = caughtIn[id] or {}
                    caughtIn[id][spot.zone] = true
                end
            end
        end
    end
    for id, e in pairs(j.items or {}) do
        local kind = J.Kind(e, id)
        f[kind] = (f[kind] or 0) + 1
        if e.quality then f.quality[e.quality] = true end
        if kind == "fish" then f.hoard = math.max(f.hoard, e.count or 0) end
        if kind == "junk" then f.litter = math.max(f.litter, e.count or 0) end
    end
    -- the known lists, for "every"
    for id in pairs(D.FISH) do
        f.nFish = f.nFish + 1
        if j.items[id] then f.allFish = f.allFish + 1 end
    end
    for id, find in pairs(D.FINDS) do
        if find[1] == "junk" then
            f.nJunk = f.nJunk + 1
            if j.items[id] then f.allJunk = f.allJunk + 1 end
        else
            f.nTreasure = f.nTreasure + 1
            if j.items[id] then f.allTreasure = f.allTreasure + 1 end
        end
    end
    -- a fish caught somewhere it isn't known to live
    for id, fish in pairs(D.FISH) do
        local home = {}
        for _, z in ipairs(fish.zones or {}) do home[z] = true end
        for z in pairs(caughtIn[id] or {}) do
            if not home[z] and D.ZONES[z] then f.wrong = true end
        end
    end
    return f
end

local function Flag(name) return function(f) return f.st[name] and 1 or 0 end end
-- how many of these items you've found
local function Have(ids)
    return function(f)
        local n = 0
        for _, id in ipairs(ids) do if f.j.items[id] then n = n + 1 end end
        return n
    end
end
local RUMS = { 20709, 21114, 21151 }
local LOCKED = { 6354, 6355, 13875 }
local BLOATED = { 6643, 6645, 6647, 8366, 13881, 13891, 21162, 21164, 21243 }
local TROPHIES = { 13878, 13879, 13887 } -- 53 and 59 Pound Yellowtail, 52 Pound Redgill

-- { id, group, name, goal, need, have(f), hidden }
local DEFS = {
    -- Waters
    { "tour1", "waters", "Tour of Azeroth", "Catch something in 10 different zones.", 10, function(f) return f.zones end },
    { "tour2", "waters", "Tour of Azeroth II", "Catch something in 20 different zones.", 20, function(f) return f.zones end },
    { "tour3", "waters", "Tour of Azeroth III", "Catch something in 30 different zones.", 30, function(f) return f.zones end },
    { "shores", "waters", "Three Shores", "Catch something in Kalimdor, the Eastern Kingdoms and on Zephras Isle.", 3,
        function(f) local n = 0; for _ in pairs(f.shores) do n = n + 1 end; return n end },
    { "regular", "waters", "Regular", "Fish the same spot on 10 different days.", 10, function(f) return f.regular end },
    { "homebody", "waters", "Homebody", "Make 500 catches at a single spot.", 500, function(f) return f.homebody end },
    -- Collection
    { "fish1", "collection", "Know Your Fish", "Discover 10 different fish.", 10, function(f) return f.fish end },
    { "fish2", "collection", "Know Your Fish II", "Discover 25 different fish.", 25, function(f) return f.fish end },
    { "fish3", "collection", "Know Your Fish III", "Discover every fish.", function(f) return f.nFish end, function(f) return f.allFish end },
    { "junk1", "collection", "Whosits & Whatsits", "Find 5 different bits of junk.", 5, function(f) return f.junk end },
    { "junk2", "collection", "Whosits & Whatsits II", "Find every bit of junk.", function(f) return f.nJunk end, function(f) return f.allJunk end },
    { "treasure1", "collection", "Treasure Hunter", "Find 5 different treasures.", 5, function(f) return f.treasure end },
    { "treasure2", "collection", "Treasure Hunter II", "Find every treasure.", function(f) return f.nTreasure end, function(f) return f.allTreasure end },
    { "rainbow", "collection", "Rainbow", "Catch something grey, white, green and blue.", 4,
        function(f) local n = 0; for q = 0, 3 do if f.quality[q] then n = n + 1 end end; return n end },
    { "hoarder", "collection", "Hoarder", "Catch 100 of a single fish.", 100, function(f) return f.hoard end },
    { "rum", "collection", "Happy Hour", "Find all three Rumsey Rums: Light, Dark and Black Label.", 3, Have(RUMS) },
    { "locks", "collection", "Locksmith", "Find all three locked chests: Small, Sturdy and Ironbound.", 3, Have(LOCKED) },
    { "bloated", "collection", "Something Smells Fishy", "Find 5 different Bloated fish.", 5, Have(BLOATED) },
    -- Streaks
    { "roll1", "streaks", "On a Roll", "Make 10 catches in a row without a miss.", 10, function(f) return f.st.streakBest or 0 end },
    { "roll2", "streaks", "On a Roll II", "Make 25 catches in a row without a miss.", 25, function(f) return f.st.streakBest or 0 end },
    { "roll3", "streaks", "On a Roll III", "Make 50 catches in a row without a miss.", 50, function(f) return f.st.streakBest or 0 end },
    { "lucky1", "streaks", "Lucky Streak", "Find treasure twice in a row.", 2, function(f) return f.st.tStreakBest or 0 end },
    { "lucky2", "streaks", "Lucky Streak II", "Find treasure three times in a row.", 3, function(f) return f.st.tStreakBest or 0 end },
    { "patience", "streaks", "Patience of a Saint", "Reel in empty 15 times in a row.", 15, function(f) return f.st.dryBest or 0 end, true },
    { "bounce", "streaks", "Bounce Back", "Catch something rare after 5 misses in a row.", 1, Flag("bounce"), true },
    -- Sessions
    { "marathon1", "sessions", "Marathon", "Fish for an hour in one session.", 60, function(f) return math.floor((f.st.longest or 0) / 60) end },
    { "marathon2", "sessions", "Marathon II", "Fish for 2 hours in one session.", 120, function(f) return math.floor((f.st.longest or 0) / 60) end },
    { "marathon3", "sessions", "Marathon III", "Fish for 4 hours in one session.", 240, function(f) return math.floor((f.st.longest or 0) / 60) end },
    { "haul1", "sessions", "Big Haul", "Make 75 catches in one session.", 75, function(f) return math.max(f.st.haulBest or 0, f.j.best or 0) end },
    { "haul2", "sessions", "Big Haul II", "Make 150 catches in one session.", 150, function(f) return math.max(f.st.haulBest or 0, f.j.best or 0) end },
    { "haul3", "sessions", "Big Haul III", "Make 300 catches in one session.", 300, function(f) return math.max(f.st.haulBest or 0, f.j.best or 0) end },
    { "jackpot", "sessions", "Jackpot", "Catch a rare fish and find treasure in the same session.", 1, Flag("jackpot") },
    { "steady", "sessions", "Steady Hands", "Finish a session of 40 or more catches, missing no more than 1 in 10.", 1, Flag("steady") },
    -- Just for fun
    { "litter", "fun", "Somebody's Littering", "Fish up the same bit of junk 5 times.", 5, function(f) return f.litter end, true },
    { "wrong", "fun", "Wrong Neighbourhood", "Catch a fish somewhere it doesn't usually live.", 1, function(f) return f.wrong and 1 or 0 end, true },
    { "fishstory", "fun", "Fish Story", "Land a trophy fish of 50 pounds or more.", 1, function(f) return math.min(1, Have(TROPHIES)(f)) end },
    { "bottle", "fun", "Message in a Bottle", "Fish up a Message in a Bottle.", 1, Have({ 6307 }), true },
    { "diary", "fun", "Dear Diary", "Fish up a page of somebody's diary.", 1, Have({ 6306 }), true },
    { "casts1", "fun", "Cast Away", "Cast 1,000 times.", 1000, function(f) return f.st.casts or 0 end },
    { "casts2", "fun", "Cast Away II", "Cast 5,000 times.", 5000, function(f) return f.st.casts or 0 end },
    { "casts3", "fun", "Cast Away III", "Cast 10,000 times.", 10000, function(f) return f.st.casts or 0 end },
    { "early", "fun", "Early Bird", "Catch something between 5 and 7 in the morning, game time.", 1, Flag("earlyBird") },
    { "night", "fun", "Night Owl", "Catch something between midnight and 3 in the morning, game time.", 1, Flag("nightOwl"), true },
}
CH.DEFS = {}
for i, d in ipairs(DEFS) do
    CH.DEFS[i] = { id = d[1], group = d[2], name = d[3], goal = d[4], need = d[5], have = d[6], hidden = d[7] }
end

local function Saved()
    local j = ns.Journal.DB()
    j.challenges = j.challenges or { done = {} }
    j.challenges.done = j.challenges.done or {}
    return j.challenges
end
CH.Saved = Saved

-- Every challenge with where it stands: { def, have, need, done = { time, zone } }
function CH:State()
    local f, done, list = Facts(), Saved().done, {}
    for _, d in ipairs(CH.DEFS) do
        local need = type(d.need) == "function" and d.need(f) or d.need
        local have = math.min(d.have(f) or 0, need)
        list[#list + 1] = { def = d, have = have, need = need, done = done[d.id] }
    end
    return list, f
end

function CH:Count(group)
    local n, all = 0, 0
    local done = Saved().done
    for _, d in ipairs(CH.DEFS) do
        if group == nil or group == "all" or d.group == group then
            all = all + 1
            if done[d.id] then n = n + 1 end
        end
    end
    return n, all
end

-- After anything the journal notes. The first check marks what's already done
-- quietly, with one banner to say so, rather than a parade of them.
function CH:Check()
    if not (ns.Journal and ns.Journal.DB) then return end
    local saved = Saved()
    local list = self:State()
    local first = not saved.init
    local fresh = {}
    for _, c in ipairs(list) do
        if not c.done and c.need > 0 and c.have >= c.need then
            local entry = { first and 0 or time() }
            if not first then entry[2] = GetRealZoneText and GetRealZoneText() or nil end
            saved.done[c.def.id] = entry
            fresh[#fresh + 1] = c.def
        end
    end
    saved.init = true
    -- every finished challenge pays its Shiny Fishbones, once; the first time
    -- this runs that includes the ones done before Fishbones were a thing
    local F = ns.Flair
    local paid = F and F.Settle() or 0
    if #fresh == 0 and paid == 0 then return end
    if ns.ChallengesWindow and ns.ChallengesWindow.Refresh then ns.ChallengesWindow:Refresh() end
    if ns.db and ns.db.challengeToasts == false then return end
    if first and #fresh > 0 then
        self:Toast({ name = #fresh .. " already done!",
            header = paid > 0 and ("DUCKY'S CHALLENGES  ·  +" .. F.Bones(paid, 13)) or "DUCKY'S CHALLENGES",
            summary = true })
    elseif #fresh == 0 then
        -- challenges done before Fishbones: Ducky pays up
        self:Toast({ name = "+" .. paid .. " Shiny Fishbones", header = "BACK PAY FROM DUCKY'S CHALLENGES", summary = true })
    else
        for _, d in ipairs(fresh) do self:Toast(d) end
    end
end

-- start over (Developer page): nothing done. The next check counts whatever
-- the journal already shows, quietly, with one banner.
function CH.Reset()
    local j = ns.Journal and ns.Journal.DB and ns.Journal.DB()
    if not j then return end
    j.challenges = { done = {} }
    if ns.ChallengesWindow and ns.ChallengesWindow.Refresh then ns.ChallengesWindow:Refresh() end
end

-------------------------------------------------------------------------------
-- The banner: the starred medallion drops in from the top, fading in; the
-- parchment plate slides out from behind it; it holds, then folds back and
-- slides away. Every banner is the same width. Several at once queue up and
-- play one after another.
-------------------------------------------------------------------------------

local TW, RING = 420, 72              -- banner width, the medallion's ring
local queue, toast, playing = {}, nil, nil

local function Ease(t) t = math.max(0, math.min(1, t)); return 1 - (1 - t) * (1 - t) end

local function Build()
    local UI = ns.UI
    local A = UI.ART.plate
    local s = RING / A.ring[3]
    toast = CreateFrame("Button", "RubberDuckyChallengeToast", UIParent)
    toast:SetSize(TW, A.ah * s)
    toast:SetPoint("TOP", UIParent, "TOP", 0, -110)
    toast:SetFrameStrata("DIALOG")
    toast:SetFrameLevel(50)
    toast:Hide()
    -- the plate, its width changing as it opens
    local plate = CreateFrame("Frame", nil, toast)
    plate:SetSize(A.ring[1] * s * 2, A.ah * s)
    toast.plate = plate
    toast.art = UI.Stretch(plate, "plate", "BACKGROUND", s)
    toast.s = s
    -- the starred medallion over the plate's own
    local ring = CreateFrame("Frame", nil, toast)
    local size = RING / UI.MEDAL_RING
    ring:SetSize(size, size)
    ring:SetFrameLevel((toast:GetFrameLevel() or 1) + 3)
    local medal = ring:CreateTexture(nil, "ARTWORK")
    medal:SetAllPoints()
    UI.Medal(medal, "done")
    toast.ring, toast.medalSize = ring, size
    local head = plate:CreateFontString(nil, "OVERLAY", UI.FONT.soft)
    local name = plate:CreateFontString(nil, "OVERLAY", UI.FONT.large)
    head:SetJustifyH("LEFT"); name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    toast.head, toast.name = head, name
    toast:SetScript("OnClick", function()
        if toast.flair then
            if ns.Shop then ns.Shop:Show("motto") end
        elseif ns.ChallengesWindow then ns.ChallengesWindow:Show(toast.group) end
    end)
end

local DROP, LAND, OPEN, TEXT, FOLD, AWAY = 0.35, 0.15, 0.4, 0.2, 0.35, 0.3
local function Paint(t)
    local d = playing
    local hold = d.hold
    local tOpen = DROP + LAND
    local tHold = tOpen + OPEN
    local tFold = tHold + hold
    local tAway = tFold + FOLD
    local drop, open, alpha, text
    if t < DROP then
        drop, open, alpha, text = 1 - Ease(t / DROP), 0, Ease(t / DROP), 0
    elseif t < tOpen then
        drop, open, alpha, text = 0, 0, 1, 0
    elseif t < tHold then
        drop, open, alpha = 0, Ease((t - tOpen) / OPEN), 1
        text = math.max(0, ((t - tOpen) - (OPEN - TEXT)) / TEXT)
    elseif t < tFold then
        drop, open, alpha, text = 0, 1, 1, 1
    elseif t < tAway then
        local k = (t - tFold) / FOLD
        drop, open, alpha, text = 0, 1 - Ease(k), 1, math.max(0, 1 - k * 3)
    else
        local k = (t - tAway) / AWAY
        drop, open, alpha, text = Ease(k), 0, 1 - Ease(k), 0
    end
    -- the medallion travels from the middle to the left end as the plate opens
    local A, sc = ns.UI.ART.plate, toast.s
    local ringX = A.ring[1] * sc                     -- the ring's centre, from the plate's left
    local cx = (-TW / 2 + ringX) * open
    local y = drop * 50
    local plate = toast.plate
    local pw = ringX * 2 + (TW - ringX * 2) * open
    plate:ClearAllPoints()
    plate:SetPoint("LEFT", toast, "CENTER", cx - ringX, y)
    plate:SetWidth(pw)
    toast.art:Layout()
    toast.art:SetAlpha(alpha * math.min(1, open * 4))
    toast.ring:ClearAllPoints()
    toast.ring:SetPoint("CENTER", toast, "CENTER", cx, y + (A.ah / 2 - A.ring[2]) * sc - toast.medalSize * 11 / 256)
    toast.ring:SetAlpha(alpha)
    -- the words on the parchment, once there's room for them
    local B = A.body
    local x0, x1 = toast.art:X(B[1]) + 6, toast.art:X(B[3]) - 6
    local mid = (toast.art:Y(B[2]) + toast.art:Y(B[4])) / 2
    toast.head:ClearAllPoints()
    toast.head:SetPoint("BOTTOMLEFT", plate, "TOPLEFT", x0, -mid + 1)
    toast.name:ClearAllPoints()
    toast.name:SetPoint("TOPLEFT", plate, "TOPLEFT", x0, -mid - 1)
    toast.name:SetWidth(math.max(20, x1 - x0))
    toast.head:SetAlpha(text); toast.name:SetAlpha(text)
    return t >= tAway + AWAY
end

local function Next()
    playing = table.remove(queue, 1)
    if not playing then toast:Hide(); toast:SetScript("OnUpdate", nil); return end
    -- later ones in a long queue hold for less time
    playing.hold = #queue >= 2 and 2.5 or 4
    toast.head:SetText(playing.header or "CHALLENGE COMPLETE")
    toast.name:SetText(playing.name)
    toast.group, toast.flair = playing.group, playing.flair
    local start = GetTime()
    toast:SetScript("OnUpdate", function()
        if Paint(GetTime() - start) then Next() end
    end)
    Paint(0)
    toast:Show()
    ns.UI.Sound("challenge")
end

-- the banner's top line: what you got besides the challenge itself
function CH.Header(def)
    local F = ns.Flair
    local r = F and F.REWARD[def.id]
    local bones = r and ("+" .. F.Bones(r, 13)) or nil
    local prizes = F and F.Prizes(def.id) or {}
    local what = prizes[1] and ("NEW " .. F.SINGULAR[prizes[1].kind]:upper() .. "!")
    if #prizes > 1 then what = "NEW FLAIR!" end
    if what and bones then return bones .. "  ·  " .. what end
    if what then return "CHALLENGE COMPLETE  ·  " .. what end
    if bones then return "CHALLENGE COMPLETE  ·  " .. bones end
    return "CHALLENGE COMPLETE"
end

function CH:Toast(def)
    if not toast then Build() end
    local header = def.header or (not def.summary and CH.Header(def)) or nil
    queue[#queue + 1] = { name = def.name, header = header, group = def.group, summary = def.summary, flair = def.flair }
    if not playing then Next() end
end
CH.queue = queue
function CH:IsPlaying() return playing ~= nil end
