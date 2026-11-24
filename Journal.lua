-- Rubber Ducky: the fishing journal. Everything this character has ever caught,
-- in a leather-bound book with three bookmarks: Catches, Waters, Records.
--
-- Saved per character in RubberDuckyJournalDB:
--   items[id]  = { name, icon, quality, class, count, first, last, seen, note,
--                  spots = { [spot] = n }, pins = { [spot] = { {x, y}, ... } } }
--   spots[key] = { zone, sub, mapID, count, last, note, items = { [id] = n }, pins = { {x, y}, ... } }
--   zones[mapID] = name   -- zones this character has been to
--   firsts     = { { id, t, spot }, ... }
--   best       = best session total

local _, ns = ...
local Journal = {}
ns.Journal = Journal
local Data = ns.JournalData

local ART, BASE = 1024, 620
local K = BASE / ART
local function P(x, y) return x * K, -y * K end
local ART_DIR = ns.MEDIA .. "Journal\\"
local function Art(name) return ART_DIR .. name end

-- the book, measured in its own pixels (1024 square)
local CLOSE = { 963, 120, 38 }
local RIBBONS = { { 131, 186, "finds", "chest", "Whosits & Whatsits" }, { 205, 280, "catches", "fish", "Catches" }, { 300, 365, "waters", "wave", "Waters" },
    { 380, 445, "records", "trophy", "Records" } }
local RIBBON_Y = { 885, 990 }
-- banners: centre x, widest text, and the curve of their middle (y = a*x*x + b*x + c)
-- (text grows to fill the banner, up to the banner's height)
local LEFT_BANNER = { 300, 300, { 4.63e-4, -0.29338, 231.68 }, 30, -6 } -- [5]: nudge up (art px)
local RIGHT_BANNER = { 740, 330, { 0, 0, 206 }, 30 } -- no banner: a straight title across the top of the page
local TITLE_DROP = 0.4 -- the font sits high in its line: drop (art px) per point of size
local BOLD = 1 -- the titles are drawn twice, this far apart (px), to make them bold
-- Waters has no rarity badge over the name, so the name sits in the middle of the
-- space above the lines instead (centre x, y in art px)
local RIGHT_CENTRED = { 757, 172 }
local STRIP_Y, COUNT_Y = 268, 294 -- sort and show, then the "found" count under them
local LEFT_X = { 118, 488 }
local GRID_TOP, GRID_BOTTOM, CELL = 316, 808, 92
local COMPLETE = { 303, 560, 400 } -- centre x, y and width of the COMPLETE! stamp
local PAGER_Y = 832
local FIELD_Y = { 255, 292, 329, 365 }
local BOX = { 552, 715, 445, 635 }       -- spots / what bites here
local BOX_BAR = 20                        -- the scroll bar's column down the box's right edge
local ScrollBox, BoxTip -- the right-page box: defined further down, used by the window built above them
local BOX_LABEL_Y = 424
local HOLE = { 733, 947, 433, 638 }      -- the map shows through the photo frame (747-933, 447-624); a little bigger so no edge shows
local NOTES = { 566, 885, 660, 720 }
local PENCIL = { 888, 665, 935, 715 }   -- the painted pencil starts a note
local BUBBLE = { 722, 908, 750, 835 }
local MAP_VIEW = 0.3                      -- how much of the zone's width the map shows
local MAX_PINS = 12

local win, ui, mapClip, canvas
local mode = "catches"
local sel = {}          -- selected thing per bookmark
local pageOf = { finds = 1, catches = 1, waters = 1, records = 1 }
local Ink

-------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------
-- one journal per character (SavedVariablesPerCharacter)
local function DB()
    local j = RubberDuckyJournalDB
    if type(j) ~= "table" or not j.items then
        j = { items = {}, spots = {}, zones = {}, firsts = {}, best = 0 }
        RubberDuckyJournalDB = j
    end
    return j
end
Journal.DB = DB


local function Where()
    local zone = GetRealZoneText and GetRealZoneText() or GetZoneText()
    if not zone or zone == "" then zone = "Unknown waters" end
    local sub = GetSubZoneText and GetSubZoneText() or nil
    if sub == "" or sub == zone then sub = nil end
    local mapID, x, y
    pcall(function()
        mapID = C_Map.GetBestMapForUnit("player")
        local pos = mapID and C_Map.GetPlayerMapPosition(mapID, "player")
        if pos then x, y = pos:GetXY() end
    end)
    if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then x, y = nil, nil end
    if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then x, y = nil, nil end
    if x then x, y = math.floor(x * 1000 + 0.5) / 1000, math.floor(y * 1000 + 0.5) / 1000 end
    return zone, sub, mapID, x, y
end

-- icon and item class straight from the game files (no server query, no tooltip)
local function Instant(id)
    local ok, _, _, _, _, icon, class = pcall(C_Item.GetItemInfoInstant, id)
    if ok then return icon, class end
end
Journal.Instant = Instant

local function AddPin(list, x, y)
    if not x then return end
    for _, p in ipairs(list) do
        if math.abs(p[1] - x) < 0.01 and math.abs(p[2] - y) < 0.01 then return end
    end
    list[#list + 1] = { x, y }
    -- the first catch stays (it's the pin); later ones only widen the range circle
    if #list > MAX_PINS then table.remove(list, 2) end
end

-- fish, treasure or junk. What we know about an item first, then a good guess.
function Journal.Kind(e, id)
    if id and Data.FISH[id] then return "fish" end
    local find = id and Data.FINDS[id]
    if find then return find[1] end
    if e and e.quality == 0 then return "junk" end
    if not e or e.class == 7 or e.class == nil then return "fish" end
    return "treasure"
end

local justNew, lastCast = {}, nil
-- the catch, from Splash.ReadLoot. Once per cast. Returns { [id] = true } for first-ever catches.
-- Records' running tallies: casts, misses, streaks and how long you've fished.
-- A pause of more than 15 minutes starts a new fishing session.
local SESSION_GAP = 15 * 60
local function Stats()
    local j = DB()
    j.stats = j.stats or { casts = 0, catches = 0, misses = 0, dry = 0, dryBest = 0,
        streak = 0, streakBest = 0, tStreak = 0, tStreakBest = 0, longest = 0 }
    return j.stats
end
-- For Ducky's Challenges, each session also keeps its own tally. Steady Hands
-- is judged when a session ends, so it never pops on top of another challenge.
local function Busy()
    local st, now = Stats(), time()
    if not st.sessLast or now - st.sessLast > SESSION_GAP then
        local c, m = st.sessCatches or 0, st.sessMisses or 0
        if c >= 40 and c / (c + m) >= 0.9 then st.steady = true end
        st.sessStart = now
        st.sessCatches, st.sessMisses, st.sessCasts, st.sessRare, st.sessTreasure = 0, 0, 0, nil, nil
    end
    st.sessLast = now
    st.longest = math.max(st.longest or 0, now - (st.sessStart or now))
end
local function Check()
    if ns.Challenges then ns.Challenges:Check() end
end
function Journal:NoteCast()
    local st = Stats()
    st.casts = (st.casts or 0) + 1
    Busy()
    st.sessCasts = (st.sessCasts or 0) + 1
    Check()
end
-- reeled in empty, or the cast ran out
function Journal:NoteMiss()
    local st = Stats()
    st.misses = (st.misses or 0) + 1
    st.dry = (st.dry or 0) + 1
    st.dryBest = math.max(st.dryBest or 0, st.dry)
    st.streak, st.tStreak = 0, 0
    Busy()
    st.sessMisses = (st.sessMisses or 0) + 1
    Check()
end
-- rare: anything blue or better; rareFish: a blue-or-better fish
local function NoteCatch(treasure, rare, rareFish)
    local st = Stats()
    Busy()
    st.catches = (st.catches or 0) + 1
    -- the moments some challenges look for, kept as they happen
    if rare and (st.dry or 0) >= 5 then st.bounce = true end
    local h = GetGameTime and GetGameTime()
    if type(h) == "number" then
        if h >= 5 and h < 7 then st.earlyBird = true end
        if h < 3 then st.nightOwl = true end
    end
    st.sessCatches = (st.sessCatches or 0) + 1
    st.haulBest = math.max(st.haulBest or 0, st.sessCatches)
    if rareFish then st.sessRare = true end
    if treasure then st.sessTreasure = true end
    if st.sessRare and st.sessTreasure then st.jackpot = true end
    st.dry = 0
    st.streak = (st.streak or 0) + 1
    st.streakBest = math.max(st.streakBest or 0, st.streak)
    st.tStreak = treasure and (st.tStreak or 0) + 1 or 0
    st.tStreakBest = math.max(st.tStreakBest or 0, st.tStreak)
end
Journal.Stats = Stats

function Journal:Record(items)
    local cast = ns.castStart or GetTime()
    if lastCast == cast then return {} end
    lastCast = cast
    local j, fresh = DB(), {}
    local treasure, any, rare, rareFish, best = false, false, false, false, nil
    local zone, sub, mapID, x, y = Where()
    local key = zone .. " / " .. (sub or "")
    local spot = j.spots[key]
    if not spot then
        spot = { zone = zone, sub = sub, mapID = mapID, count = 0, items = {}, pins = {} }
        j.spots[key] = spot
    end
    spot.mapID = mapID or spot.mapID
    local now = time()
    for _, it in ipairs(items or {}) do
        if not it.coin and it.id and it.name then
            local n = math.max(1, it.count or 1)
            local e = j.items[it.id]
            if not e then
                local _, class = Instant(it.id)
                e = { name = it.name, icon = it.icon, quality = it.quality, class = class, count = 0,
                    first = now, spots = {}, pins = {}, seen = false }
                j.items[it.id] = e
                j.firsts[#j.firsts + 1] = { it.id, now, key }
                fresh[it.id] = true
                justNew[it.id] = GetTime()
            end
            e.count, e.last = e.count + n, now
            e.spots[key] = (e.spots[key] or 0) + n
            e.pins[key] = e.pins[key] or {}
            AddPin(e.pins[key], x, y)
            spot.count = spot.count + n
            spot.items[it.id] = (spot.items[it.id] or 0) + n
            any = true
            local kind = Journal.Kind(e, it.id)
            if kind == "treasure" then treasure = true end
            local q = it.quality or e.quality or 1
            if not best or q > best then best = q end
            if (it.quality or e.quality or 1) >= 3 then
                rare = true
                if kind == "fish" then rareFish = true end
            end
        end
    end
    if any then
        NoteCatch(treasure, rare, rareFish)
        -- now and then, a Shiny Fishbone comes up with the catch
        if ns.Flair then ns.Safe(ns.Flair.Catch, best, treasure) end
        -- how many different days you've fished here
        local day = date("%Y%m%d")
        if spot.lastDay ~= day then spot.lastDay, spot.days = day, (spot.days or 0) + 1 end
    end
    spot.last = now
    AddPin(spot.pins, x, y)
    if win and win:IsShown() then Journal:Refresh() end
    Check()
    return fresh
end

-- for the splash: caught for the first time just now
function Journal:IsJustNew(id)
    return id and justNew[id] and GetTime() - justNew[id] < 10
end

function Journal:NoteSession(total)
    local j = DB()
    if total and total > (j.best or 0) then j.best = total end
end

-- zones this character has been to (the game's own exploration)
local CONTINENTS = { 1414, 1415 }
local EXTRA_ZONES = { 2521 } -- Zephras Isle floats in Skywall, off both continents
local function AllZones()
    local list = {}
    for _, id in ipairs(EXTRA_ZONES) do
        local info = ns.Safe(C_Map.GetMapInfo, id)
        if info and info.name then list[#list + 1] = { id = id, name = info.name } end
    end
    for _, c in ipairs(CONTINENTS) do
        local cont = ns.Safe(C_Map.GetMapInfo, c)
        local kids = ns.Safe(C_Map.GetMapChildrenInfo, c, (Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3, false)
        for _, m in ipairs(kids or {}) do list[#list + 1] = { id = m.mapID, name = m.name, cont = cont and cont.name } end
    end
    return list
end
local function ZoneOf(mapID)
    for _ = 1, 6 do
        local info = mapID and ns.Safe(C_Map.GetMapInfo, mapID)
        if not info then return end
        if info.mapType == ((Enum and Enum.UIMapType and Enum.UIMapType.Zone) or 3) then return mapID, info.name end
        mapID = info.parentMapID
    end
end
function Journal:ScanZones()
    local j = DB()
    for _, z in ipairs(AllZones()) do
        local ex = C_MapExplorationInfo and ns.Safe(C_MapExplorationInfo.GetExploredMapTextures, z.id)
        if ex and #ex > 0 then j.zones[z.id] = z.name end
    end
    self:NoteZone()
end
function Journal:NoteZone()
    local id, name = ZoneOf(ns.Safe(C_Map.GetBestMapForUnit, "player"))
    if id and not DB().zones[id] then
        DB().zones[id] = name
        if win and win:IsShown() and mode == "waters" then self:Refresh() end
    end
end

-------------------------------------------------------------------------------
-- Looking things up
-------------------------------------------------------------------------------
local function CountOf(e) return e.count or 0 end

local function MainSpot(e)
    local best, n = nil, -1
    for k, c in pairs(e.spots or {}) do if c > n then best, n = k, c end end
    return best
end
local function ZoneName(e)
    local k = MainSpot(e)
    local s = k and DB().spots[k]
    return s and s.zone or "Unknown waters"
end
local function Levels(zone) return Data.ZONES[zone] end
-- a little faction crest before Alliance and Horde zones (contested ones get none)
local CREST = {
    Alliance = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:15:15:0:0:64:64:4:38:2:38|t ",
    Horde = "|TInterface\\TargetingFrame\\UI-PVP-Horde:15:15:0:0:64:64:2:38:2:38|t ",
}
local function Crest(zone) return CREST[Data.FACTION[zone] or ""] or "" end
Journal.Crest = Crest
local function ZoneLabel(zone)
    local z = Levels(zone)
    if not z then return Crest(zone) .. zone end
    local text = ("%s%s · Lv %d-%d"):format(Crest(zone), zone, z[1], z[2])
    -- (no fishing skill here yet: the numbers we have are Classic's, and may not
    -- be Forever's; see docs/zone-skill-plan.md)
    return text
end
-- the order you'd travel in: by level (zones we know nothing about go last)
local function ZoneRank(zone)
    local z = Levels(zone)
    if not z then return 99999, 999 end
    return z[1], z[2]
end
local function ZoneBefore(a, b)
    local sa, la = ZoneRank(a)
    local sb, lb = ZoneRank(b)
    if sa ~= sb then return sa < sb end
    if la ~= lb then return la < lb end
    return a < b
end
Journal.ZoneBefore = ZoneBefore
local function Date(t) return t and date("%b %d, %Y", t) or "-" end
local function SpotName(s) return s.sub or s.zone end

-- known items plus undiscovered fish
-- everything you've caught plus every fish in the game
-- what you've caught plus what's out there: fish for Catches, everything else
-- for Whosits & Whatsits
local function Catalogue(fish)
    local j, list = DB(), {}
    local known = fish and Data.FISH or Data.FINDS
    for id, e in pairs(j.items) do
        if CountOf(e) > 0 and (Journal.Kind(e, id) == "fish") == fish then
            list[#list + 1] = { id = id, e = e, f = known[id] }
        end
    end
    for id, f in pairs(known) do
        if not j.items[id] or CountOf(j.items[id]) == 0 then list[#list + 1] = { id = id, f = f } end
    end
    return list
end
local SORTS = { "zone", "rarity", "name", "most", "recent" }
local FINDS_SORTS = { "type", "zone", "rarity", "name", "most", "recent" }
local SORT_NAMES = { type = "Type", zone = "Zone", level = "Level", rarity = "Rarity", name = "Name", most = "Most caught", recent = "Recent" }
local SHOWS = { "all", "treasure", "junk" }
local SHOW_NAMES = { all = "All", treasure = "Treasure", junk = "Junk" }
-- the sort for the page you're on
local function SortKey() return mode == "finds" and "journalFindsSort" or "journalSort" end
local function SortList() return mode == "finds" and FINDS_SORTS or SORTS end

-- fish: Catches (true) or Whosits & Whatsits (false). how: the sort.
-- show: for Whosits & Whatsits, "all", "treasure" or "junk".
local GROUP_NAMES = { treasure = "Treasure", junk = "Junk" }
local function SortedCatalogue(fish, how, show)
    if fish == nil then fish = true end
    how = how or ns.db.journalSort or "zone"
    local list = {}
    for _, c in ipairs(Catalogue(fish)) do
        local kind = fish and "fish" or (c.e and Journal.Kind(c.e, c.id)) or (c.f and c.f[1]) or "treasure"
        if fish or not show or show == "all" or show == kind then
            local name = c.e and ns.FishName(c.e.name) or "~"
            -- zones you've caught it in
            local caught, order = {}, {}
            for k in pairs(c.e and c.e.spots or {}) do
                local sp = DB().spots[k]
                if sp and not caught[sp.zone] then caught[sp.zone] = true; order[#order + 1] = sp.zone end
            end
            if how == "zone" then
                -- under every zone it bites in; it's only discovered in the zones you caught it in
                local zones, seen = {}, {}
                for _, z in ipairs(c.f and c.f.zones or {}) do if not seen[z] then seen[z] = true; zones[#zones + 1] = z end end
                for _, z in ipairs(order) do if not seen[z] then seen[z] = true; zones[#zones + 1] = z end end
                if #zones == 0 then zones[1] = "Unknown waters" end
                for _, z in ipairs(zones) do
                    -- elsewhere it's a mystery, just like a fish you've never caught
                    local here = caught[z] and c.e or nil
                    list[#list + 1] = { id = c.id, e = here, f = c.f, zone = z, name = here and name or "~", unknown = here == nil,
                        group = GROUP_NAMES[kind] }
                end
            else
                list[#list + 1] = { id = c.id, e = c.e, f = c.f, name = name, unknown = c.e == nil, group = GROUP_NAMES[kind],
                    zone = c.e and ZoneName(c.e) or (c.f and c.f.zones and c.f.zones[1]) or "Unknown waters" }
            end
        end
    end
    table.sort(list, function(a, b)
        if how == "type" and a.group ~= b.group then return a.group == "Treasure" end
        if a.unknown ~= b.unknown and how ~= "zone" then return not a.unknown end
        if how == "zone" and a.zone ~= b.zone then return ZoneBefore(a.zone, b.zone) end
        if how == "rarity" then
            local qa, qb = a.e and a.e.quality or -1, b.e and b.e.quality or -1
            if qa ~= qb then return qa > qb end
        elseif how == "most" or how == "type" then
            local ca, cb = a.e and CountOf(a.e) or 0, b.e and CountOf(b.e) or 0
            if ca ~= cb then return ca > cb end
        elseif how == "recent" then
            local ta, tb = a.e and a.e.last or 0, b.e and b.e.last or 0
            if ta ~= tb then return ta > tb end
        end
        if a.name ~= b.name then return a.name < b.name end
        return a.id < b.id
    end)
    return list
end

Journal.SortedCatalogue = SortedCatalogue

-- Whosits & Whatsits, with its own sort and filter
local function FindsCatalogue()
    return SortedCatalogue(false, ns.db.journalFindsSort or "type", ns.db.journalFindsShow or "all")
end
Journal.FindsCatalogue = FindsCatalogue

-------------------------------------------------------------------------------
-- Building the book
-------------------------------------------------------------------------------
local function Text(size, justify, parent) return Ink.Text(parent or ui, size, justify) end
local function Icon(name, size, parent)
    local t = (parent or ui):CreateTexture(nil, "ARTWORK")
    t:SetTexture(Art(name))
    t:SetSize(size * K, size * K)
    return t
end
local function Sound(kit) if SOUNDKIT and SOUNDKIT[kit] then pcall(PlaySound, SOUNDKIT[kit], "Master") end end
-- a soft click each time the selection moves
local TICK = "U_CHAT_SCROLL_BUTTON"
local function Tick() Sound(TICK) end
local function Tip(owner, title, line)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    if line then GameTooltip:AddLine(line, 1, 1, 1, true) end
    GameTooltip:Show()
end
local function HotSpot(x1, y1, x2, y2, onClick, title, line)
    local b = CreateFrame("Button", nil, ui)
    b:SetPoint("TOPLEFT", ui, "TOPLEFT", P(x1, y1))
    b:SetSize((x2 - x1) * K, (y2 - y1) * K)
    b:SetScript("OnClick", onClick)
    if title then
        b:SetScript("OnEnter", function(self) Tip(self, type(title) == "function" and title() or title, line) end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    return b
end

-- map: the zone's art plus explored areas, under the page's see-through frame
local tilePool, pinPool = {}, {}
local function ClearMap()
    for _, t in ipairs(tilePool) do t:Hide() end
    for _, t in ipairs(pinPool) do t:Hide() end
    if win.rangeDisc then win.rangeDisc:Hide(); win.rangeRing:Hide() end
end
local function Tile(i)
    local t = tilePool[i]
    if not t then t = canvas:CreateTexture(nil, "BACKGROUND"); tilePool[i] = t end
    t:ClearAllPoints(); t:SetTexCoord(0, 1, 0, 1); t:SetVertexColor(1, 0.93, 0.8); t:Show()
    return t
end
-- no pins (a "???" catch, or nowhere to pin): the zone as an undiscovered map
-- (its bare parchment, none of the explored areas) under a "???"; with no zone
-- (or one you haven't found), just blank parchment and the "???"
local function DrawMap(mapID, pins)
    ClearMap()
    local mystery = not pins or #pins == 0
    win.noMap:SetShown(mystery)
    local L = mapID and ns.Safe(C_Map.GetMapArtLayers, mapID)
    L = L and L[1]
    local files = L and ns.Safe(C_Map.GetMapArtLayerTextures, mapID, 1)
    if not L or not files or #files == 0 then return end
    local W, H, i = L.layerWidth, L.layerHeight, 0
    local cols = math.ceil(W / L.tileWidth)
    for n, file in ipairs(files) do
        i = i + 1
        local t = Tile(i)
        t:SetDrawLayer("BACKGROUND", 0)
        t:SetSize(L.tileWidth, L.tileHeight)
        t:SetPoint("TOPLEFT", canvas, "TOPLEFT", ((n - 1) % cols) * L.tileWidth, -math.floor((n - 1) / cols) * L.tileHeight)
        t:SetTexture(file)
    end
    local TILE = 256
    local function Pow2(v) local f = 16; while f < v do f = f * 2 end return f end
    local explored = not mystery and C_MapExplorationInfo and ns.Safe(C_MapExplorationInfo.GetExploredMapTextures, mapID)
    for _, info in ipairs(explored or {}) do
        local wide, tall = math.ceil(info.textureWidth / TILE), math.ceil(info.textureHeight / TILE)
        for r = 1, tall do
            local ph = r < tall and TILE or (info.textureHeight - (tall - 1) * TILE)
            for c = 1, wide do
                local pw = c < wide and TILE or (info.textureWidth - (wide - 1) * TILE)
                local file = info.fileDataIDs[(r - 1) * wide + c]
                if file and pw > 0 and ph > 0 then
                    i = i + 1
                    local t = Tile(i)
                    t:SetDrawLayer("BACKGROUND", 1)
                    t:SetSize(pw, ph)
                    t:SetTexCoord(0, pw / Pow2(pw), 0, ph / Pow2(ph))
                    t:SetPoint("TOPLEFT", canvas, "TOPLEFT", info.offsetX + TILE * (c - 1), -(info.offsetY + TILE * (r - 1)))
                    t:SetTexture(file)
                end
            end
        end
    end
    -- one pin where it was first caught, and a dotted circle out to the furthest catch
    local cw, ch = mapClip:GetWidth(), mapClip:GetHeight()
    if mystery then
        for n = 1, i do tilePool[n]:SetVertexColor(0.8, 0.72, 0.58) end
        pins = { { 0.5, 0.5 } }
    end
    local first = pins[1]
    local cx, cy = first[1] * W, first[2] * H
    local reach = 0
    for _, p in ipairs(pins) do
        reach = math.max(reach, math.sqrt(((p[1] - first[1]) * W) ^ 2 + ((p[2] - first[2]) * H) ^ 2))
    end
    local radius = reach > 0 and math.max(reach + 6, 14) or 0
    -- zoom so the circle fits, never closer than the usual view
    local view = mystery and W * 0.55 or math.max(W * MAP_VIEW, radius * 2.6)
    local s = cw / view
    canvas:SetScale(math.max(s, 0.01))
    canvas:SetSize(W, H)
    local hw, hh = cw / s / 2, ch / s / 2
    local vx = math.min(math.max(cx, hw), W - hw) -- keep the view inside the map
    local vy = math.min(math.max(cy, hh), H - hh)
    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT", mapClip, "CENTER", -vx, vy)
    if not mystery then
        if radius > 0 then
            if not win.rangeDisc then
                win.rangeDisc = canvas:CreateTexture(nil, "ARTWORK")
                win.rangeDisc:SetTexture(Art("disc"))
                win.rangeDisc:SetVertexColor(1, 0.97, 0.88, 0.38)
                win.rangeRing = canvas:CreateTexture(nil, "ARTWORK", nil, 1)
                win.rangeRing:SetTexture(Art("ring"))
            end
            local d = radius * 2 * 256 / 240 -- the art's circle sits a little inside its square
            for _, t in ipairs({ win.rangeDisc, win.rangeRing }) do
                t:SetSize(d, d)
                t:ClearAllPoints()
                t:SetPoint("CENTER", canvas, "TOPLEFT", cx, -cy)
                t:Show()
            end
        end
        local t = pinPool[1]
        if not t then t = canvas:CreateTexture(nil, "OVERLAY"); t:SetTexture(Art("pin")); pinPool[1] = t end
        t:SetSize(16 / s, 16 / s)
        t:ClearAllPoints()
        t:SetPoint("BOTTOM", canvas, "TOPLEFT", first[1] * W, -first[2] * H)
        t:Show()
    end
end

local fields, boxLines, tiles, lines = {}, {}, {}, {}
local ShowZone -- set further down
local box = { offset = 0, cursor = 1 }
local focus = "left" -- which page the controller is on; the View button swaps
local function BoxUsable() return box.onPick ~= nil and box.items ~= nil and #box.items > 0 end
local popped = {} -- New! badges that have already popped in on the grid
local CurvedTitle

-- banner text that follows the banner's curve, a letter at a time
-- (a rotated FontString renders jagged)
CurvedTitle = function(banner)
    local size = banner[4]
    local t = { letters = {}, text = "", color = nil }
    local drop, cx, cy = 0, nil, nil
    local function Y(x)
        if cy then return cy + drop end
        local c = banner[3]; return c[1] * x * x + c[2] * x + c[3] + drop + (banner[5] or 0)
    end
    -- move a straight title somewhere else (nil puts it back)
    function t:Centre(x, y) cx, cy = x, y; self:Draw() end
    function t:SetTextColor(r, g, b) self.color = { r, g, b }; self:Draw() end
    function t:SetText(text) self.text, self.color = text or "", nil; self:Draw() end
    function t:Draw()
        local chars = {}
        for ch in self.text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do chars[#chars + 1] = ch end
        local sz, widths, sum = size, {}, 0
        for _ = 1, 30 do
            sum = 0
            for i, ch in ipairs(chars) do
                local fs = self.letters[i]
                if not fs then fs = Ink.Text(ui, sz); self.letters[i] = fs end
                Ink.SetFont(fs, sz)
                fs:SetText(ch)
                local w = (fs:GetStringWidth() or 0) + BOLD
                if w <= BOLD then w = sz * 0.3 end
                widths[i] = w
                sum = sum + w
            end
            if sum <= banner[2] * K or sz <= 11 then break end
            sz = sz - 1
        end
        drop = sz * TITLE_DROP
        local c = self.color or Ink.INK
        local x = (cx or banner[1]) * K - sum / 2
        for i, fs in ipairs(self.letters) do
            if chars[i] then
                local mid = x + widths[i] / 2
                fs:ClearAllPoints()
                fs:SetPoint("CENTER", ui, "TOPLEFT", mid, -Y(mid / K) * K)
                fs:SetTextColor(c[1], c[2], c[3])
                -- bold: a second copy of the letter, a pixel to the right
                fs:SetShadowColor(c[1], c[2], c[3], 1)
                fs:SetShadowOffset(BOLD, 0)
                fs:Show()
                x = x + widths[i]
            else
                fs:Hide()
            end
        end
    end
    return t
end

local function Build()
    Ink = ns.Log.Ink
    win = CreateFrame("Frame", "RubberDuckyJournal", UIParent)
    win:SetSize(BASE, BASE)
    win:SetFrameStrata("MEDIUM")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true); win:EnableMouse(true)
    win:RegisterForDrag("LeftButton")
    win:SetScript("OnDragStart", win.StartMoving)
    win:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, rel, x, y = self:GetPoint()
        ns.db.journalPos = { point, rel, x, y }
    end)
    win:SetScript("OnShow", function() Sound("IG_SPELLBOOK_OPEN") end)
    win:SetScript("OnHide", function()
        Sound("IG_SPELLBOOK_CLOSE")
        GameTooltip:Hide()
        -- never leave the notes box holding the keyboard: that also holds the controller
        if win.notes then win.notes:ClearFocus() end
        focus = "left"
    end)
    tinsert(UISpecialFrames, "RubberDuckyJournal")

    -- map under the book, book art, then everything written on it
    mapClip = CreateFrame("Frame", nil, win)
    mapClip:SetFrameLevel((win:GetFrameLevel() or 1) + 1)
    mapClip:SetPoint("TOPLEFT", win, "TOPLEFT", P(HOLE[1], HOLE[3]))
    mapClip:SetSize((HOLE[2] - HOLE[1]) * K, (HOLE[4] - HOLE[3]) * K)
    mapClip:SetClipsChildren(true)
    local paper = mapClip:CreateTexture(nil, "BACKGROUND", nil, -8)
    -- blank parchment (a clean patch of the book's own page) when there's no map to show
    paper:SetAllPoints(); paper:SetTexture(Art("book")); paper:SetTexCoord(150 / 1024, 336 / 1024, 420 / 1024, 597 / 1024)
    canvas = CreateFrame("Frame", nil, mapClip)
    canvas:SetSize(1, 1)

    local art = CreateFrame("Frame", nil, win)
    art:SetAllPoints()
    art:SetFrameLevel((win:GetFrameLevel() or 1) + 5)
    local book = art:CreateTexture(nil, "BACKGROUND")
    book:SetAllPoints()
    book:SetTexture(Art("book"))

    ui = CreateFrame("Frame", nil, win)
    ui:SetAllPoints()
    ui:SetFrameLevel((win:GetFrameLevel() or 1) + 10)

    -- the flowers in the bottom-left corner sit on top of the writing
    local top = CreateFrame("Frame", nil, win)
    top:SetAllPoints()
    top:SetFrameLevel((win:GetFrameLevel() or 1) + 20)
    local corner = top:CreateTexture(nil, "ARTWORK")
    corner:SetTexture(Art("flower")) -- 114x159 flower in a 128x256 file, pixel-matched to the book
    corner:SetSize(128 * K, 256 * K)
    corner:SetPoint("TOPLEFT", win, "TOPLEFT", P(98, 715))

    win.noMap = Text(40, "CENTER")
    win.noMap:SetPoint("CENTER", ui, "TOPLEFT", P((747 + 933) / 2, (447 + 624) / 2 + 8))
    win.noMap:SetText("???")
    win.noMap:SetTextColor(Ink.INK[1], Ink.INK[2], Ink.INK[3])
    win.noMap:SetAlpha(0.7)

    -- painted buttons
    HotSpot(CLOSE[1] - CLOSE[3], CLOSE[2] - CLOSE[3], CLOSE[1] + CLOSE[3], CLOSE[2] + CLOSE[3],
        function() win:Hide() end, "Close")
    win.ribbons = {}
    for _, r in ipairs(RIBBONS) do
        local b = HotSpot(r[1], RIBBON_Y[1], r[2], RIBBON_Y[2], function()
            if mode ~= r[3] then mode = r[3]; focus = "left"; Sound("IG_ABILITY_PAGE_TURN"); Journal:Refresh() end
        end, r[5])
        b.icon = Icon(r[4], 40, b)
        b.icon:SetPoint("CENTER", ui, "TOPLEFT", P((r[1] + r[2]) / 2, RIBBON_Y[1] + 38))
        b.mode = r[3]
        win.ribbons[#win.ribbons + 1] = b
    end
    function win.flip(step)
        for n, r in ipairs(RIBBONS) do
            if r[3] == mode then
                mode = RIBBONS[(n - 1 + step) % #RIBBONS + 1][3]
                Sound("IG_ABILITY_PAGE_TURN")
                Journal:Refresh()
                return
            end
        end
    end

    -- controller: buttons we use stay with the book, the rest go on to the game
    local function Pass(on) if not InCombatLockdown() then pcall(win.SetPropagateKeyboardInput, win, on) end end
    pcall(win.EnableGamePadButton, win, true)
    -- buttons the journal doesn't use go to the game from the very first press,
    -- so the action-bar button that opened it can close it again
    win:HookScript("OnShow", function() Pass(true) end)
    pcall(win.SetScript, win, "OnGamePadButtonDown", function(self, button)
        local f = Journal.PAD[button]
        if f and not (win.notes and win.notes:HasFocus()) then
            Pass(false)
            f()
        else
            Pass(true)
        end
    end)

    -- the controls, on a bar under the book (only with a controller on), in the
    -- game's own controller-hint style. On UIParent so it stays full size when
    -- the journal is set small.
    local bar = ns.Pad.NewBar(win:GetFrameStrata() or "HIGH")
    bar:SetPoint("TOP", win, "TOPLEFT", P(512, 1000))
    function bar:Paint()
        local list = { { "DPAD", "Browse" }, { "PADLSHOULDER", "PADRSHOULDER", "Bookmarks" } }
        local function Add(btn, label) list[#list + 1] = { btn, label } end
        if focus == "right" then Add("PAD1", "Select") elseif mode == "catches" or mode == "finds" then Add("PAD1", "Next spot") end
        if (mode == "catches" or mode == "finds") and focus == "left" then Add("PAD3", "Sort") end
        if mode == "finds" and focus == "left" then Add("PADRSTICK", "Show") end
        if ns.ChallengesWindow then Add("PAD4", "Challenges") end
        if focus == "right" then Add("PADBACK", "Left page") elseif BoxUsable() then Add("PADBACK", "Right page") end
        Add("PAD2", "Close")
        self:SetItems(list)
    end
    bar:SetScript("OnShow", bar.Paint)
    win:HookScript("OnHide", function() bar:Hide() end)
    bar:Hide()
    win.padBar = bar

    -- banners
    win.leftTitle = CurvedTitle(LEFT_BANNER)
    win.rightTitle = CurvedTitle(RIGHT_BANNER)
    -- "New!" sits on the banner's top-left corner, like on the grid
    win.newStamp = Icon("new", 96)
    win.newStamp:SetSize(96 * K, 48 * K)
    win.newStamp:SetDrawLayer("OVERLAY")
    win.newStamp:SetPoint("CENTER", ui, "TOPLEFT", P(590, 118)) -- on the rarity badge's top-left corner
    -- the rarity badge, stamped a little crooked above the name
    win.rarityStamp = ui:CreateTexture(nil, "ARTWORK", nil, 2)
    win.rarityStamp:SetSize(344 * K, 86 * K)
    win.rarityStamp:SetPoint("CENTER", ui, "TOPLEFT", P(738, 146))
    win.rarityStamp:SetRotation(-0.06)
    -- COMPLETE! stamped across the collection once you've found everything there.
    -- On its own frame over the thumbnails; it doesn't take the mouse.
    local done = CreateFrame("Frame", nil, ui)
    done:SetAllPoints(ui)
    done:SetFrameLevel((ui:GetFrameLevel() or 1) + 8)
    win.completeFrame = done
    done:EnableMouse(false)
    win.complete = done:CreateTexture(nil, "OVERLAY")
    win.complete:SetTexture(Art("complete"))
    win.complete:SetSize(COMPLETE[3] * K, COMPLETE[3] / 2 * K)
    win.complete:SetPoint("CENTER", ui, "TOPLEFT", P(COMPLETE[1], COMPLETE[2]))
    win.complete:SetAlpha(0.9)
    win.complete:Hide()

    -- left page strip: sort, show, counter
    win.sortBtn = HotSpot(LEFT_X[1], STRIP_Y - 14, LEFT_X[1] + 160, STRIP_Y + 14, function()
        Tick()
        local key, list, i = SortKey(), SortList(), 1
        for n, v in ipairs(list) do if v == (ns.db[key] or list[1]) then i = n end end
        ns.db[key] = list[i % #list + 1]
        pageOf[mode] = 1
        Journal:Refresh()
    end, "Sort", "Click to change the order.")
    win.sortText = Text(15, "LEFT", win.sortBtn)
    win.sortText:SetPoint("LEFT")
    win.showBtn = HotSpot(LEFT_X[2] - 170, STRIP_Y - 14, LEFT_X[2], STRIP_Y + 14, function()
        Tick()
        local i = 1
        for n, v in ipairs(SHOWS) do if v == (ns.db.journalFindsShow or "all") then i = n end end
        ns.db.journalFindsShow = SHOWS[i % #SHOWS + 1]
        pageOf.finds = 1
        Journal:Refresh()
    end, "Show", "Click to change what's shown.")
    win.showText = Text(15, "RIGHT", win.showBtn)
    win.showText:SetPoint("RIGHT")
    -- on Records, the strip is a way into Ducky's Challenges instead
    win.chalBtn = HotSpot(LEFT_X[1], STRIP_Y - 14, LEFT_X[2], STRIP_Y + 14, function()
        Tick()
        if ns.ChallengesWindow then ns.ChallengesWindow:Toggle() end
    end, "Ducky's Challenges", "Click to see your challenges.")
    win.chalText = Text(15, "LEFT", win.chalBtn)
    win.chalText:SetPoint("LEFT")
    win.chalCount = Text(15, "RIGHT", win.chalBtn)
    win.chalCount:SetPoint("RIGHT")
    win.chalBtn:Hide()
    win.counter = Text(13)
    win.counter:SetPoint("CENTER", ui, "TOPLEFT", P((LEFT_X[1] + LEFT_X[2]) / 2, COUNT_Y))
    win.counter:SetAlpha(0.75)

    -- pager
    local function Arrow(name, dx, step)
        local b = CreateFrame("Button", nil, ui)
        b:SetSize(34 * K, 34 * K)
        b:SetPoint("CENTER", ui, "TOPLEFT", P(300 + dx, PAGER_Y))
        b:SetNormalTexture(Art("arrow_" .. name))
        b:SetPushedTexture(Art("arrow_" .. name .. "_down"))
        b:SetScript("OnClick", function()
            pageOf[mode] = (pageOf[mode] or 1) + step
            Sound("IG_ABILITY_PAGE_TURN")
            Journal:Refresh()
        end)
        return b
    end
    win.prev, win.next = Arrow("left", -70, -1), Arrow("right", 70, 1)
    win.pageText = Text(16)
    win.pageText:SetPoint("CENTER", ui, "TOPLEFT", P(300, PAGER_Y))

    -- right page fields
    local FIELD_ICONS = { "star", "hook", "sunrise", "moon" }
    for i, y in ipairs(FIELD_Y) do
        local f = {}
        f.icon = Icon(FIELD_ICONS[i], 30)
        f.icon:SetPoint("CENTER", ui, "TOPLEFT", P(578, y))
        f.label = Text(16, "LEFT")
        f.label:SetPoint("LEFT", ui, "TOPLEFT", P(600, y))
        f.value = Text(16, "LEFT")
        f.value:SetPoint("LEFT", ui, "TOPLEFT", P(765, y))
        -- a faction crest, between the label and the value
        f.crest = ui:CreateTexture(nil, "ARTWORK")
        f.crest:SetSize(24 * K, 24 * K)
        f.crest:SetPoint("CENTER", ui, "TOPLEFT", P(746, y))
        f.crest:SetTexCoord(2 / 64, 38 / 64, 2 / 64, 38 / 64)
        f.crest:Hide()
        fields[i] = f
    end
    win.boxIcon = Icon("pin", 26)
    win.boxIcon:SetPoint("CENTER", ui, "TOPLEFT", P(566, BOX_LABEL_Y))
    win.boxLabel = Text(16, "LEFT")
    win.boxLabel:SetPoint("LEFT", ui, "TOPLEFT", P(584, BOX_LABEL_Y))
    for i = 1, 5 do
        local y = BOX[3] + 8 + (i - 1) * 36
        local b = HotSpot(BOX[1] + 6, y, BOX[2] - BOX_BAR - 2, y + 34)
        b.text = Text(14, "LEFT", b)
        b.text:SetPoint("LEFT", 6, 0)
        b.text:SetWidth((BOX[2] - BOX[1] - 30 - BOX_BAR) * K)
        -- a share or count on the right edge, so a long name never pushes it off
        b.right = Text(13, "RIGHT", b)
        b.right:SetPoint("RIGHT", -6, 0)
        local hl = b:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints(); hl:SetColorTexture(0.55, 0.38, 0.18, 0.18)
        b.sel = hl
        -- where the controller is, when it's on the right page
        local cur = b:CreateTexture(nil, "BORDER")
        cur:SetAllPoints(); cur:SetColorTexture(0.55, 0.38, 0.18, 0.4)
        cur:Hide()
        b.cur = cur
        b:SetScript("OnEnter", BoxTip)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        boxLines[i] = b
    end
    local wheel = CreateFrame("Frame", nil, ui)
    wheel:SetPoint("TOPLEFT", ui, "TOPLEFT", P(BOX[1], BOX[3]))
    wheel:SetPoint("BOTTOMRIGHT", ui, "TOPLEFT", P(BOX[2], BOX[4]))
    wheel:EnableMouseWheel(true)
    wheel:SetScript("OnMouseWheel", function(_, d) ScrollBox(-d) end)
    -- the scroll bar, in its own column clear of the names: an arrow at each
    -- end and an inked track between, with a thumb for where you are
    local BAR_X = BOX[2] - BOX_BAR / 2 - 1
    local function BoxArrow(y, rot, step)
        local b = CreateFrame("Button", nil, ui)
        b:SetSize(18 * K, 18 * K)
        b:SetPoint("CENTER", ui, "TOPLEFT", P(BAR_X, y))
        local t = b:CreateTexture(nil, "OVERLAY")
        t:SetAllPoints()
        t:SetTexture(Art("arrow_right"))
        t:SetRotation(rot)
        b.tex = t
        b:SetScript("OnClick", function() if ScrollBox(step) then Tick() end end)
        b:Hide()
        return b
    end
    win.boxUp = BoxArrow(BOX[3] + 12, math.pi / 2, -1)
    win.boxDown = BoxArrow(BOX[4] - 12, -math.pi / 2, 1)
    local track = ui:CreateTexture(nil, "ARTWORK")
    track:SetColorTexture(Ink.INK[1], Ink.INK[2], Ink.INK[3], 0.3)
    track:SetSize(3 * K, (BOX[4] - BOX[3] - 52) * K)
    track:SetPoint("TOP", ui, "TOPLEFT", P(BAR_X, BOX[3] + 26))
    track:Hide()
    local thumb = ui:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(Ink.INK[1], Ink.INK[2], Ink.INK[3], 0.75)
    thumb:SetWidth(6 * K)
    thumb:Hide()
    win.boxTrack, win.boxThumb = track, thumb
    win.hint = Text(14, "LEFT")
    win.hint:SetPoint("TOPLEFT", ui, "TOPLEFT", P(BOX[1] + 10, BOX[3] + 10))
    win.hint:SetWidth((BOX[2] - BOX[1] - 20) * K)
    win.hint:SetWordWrap(true)

    -- your notes
    local eb = CreateFrame("EditBox", nil, ui)
    eb:SetAutoFocus(false) -- before anything else: an edit box grabs the keyboard when shown otherwise
    eb:SetMultiLine(true)
    eb:SetMaxLetters(140)
    eb:SetPoint("TOPLEFT", ui, "TOPLEFT", P(NOTES[1], NOTES[3]))
    eb:SetSize((NOTES[2] - NOTES[1]) * K, (NOTES[4] - NOTES[3]) * K)
    Ink.SetFont(eb, 14)
    eb:SetTextInsets(2, 2, 2, 2)
    -- only the pencil opens it for typing, so it never takes the keyboard (or the controller) by surprise
    eb:EnableMouse(false)
    eb:SetScript("OnEscapePressed", eb.ClearFocus)
    eb:SetScript("OnEnterPressed", eb.ClearFocus)
    eb:SetScript("OnHide", eb.ClearFocus)
    eb:SetScript("OnTextChanged", function(self, user)
        if user and self.target then self.target.note = self:GetText() ~= "" and self:GetText() or nil end
        win.notesHint:SetShown(self:GetText() == "" and not self:HasFocus())
    end)
    eb:SetScript("OnEditFocusGained", function() win.notesHint:Hide() end)
    eb:SetScript("OnEditFocusLost", function(self) win.notesHint:SetShown(self.target ~= nil and self:GetText() == "") end)
    win.notes = eb
    win.pencil = HotSpot(PENCIL[1], PENCIL[2], PENCIL[3], PENCIL[4], function()
        if not eb.target then return end
        if eb:HasFocus() then eb:ClearFocus() else eb:SetFocus(); eb:SetCursorPosition(#eb:GetText()) end
    end, "Write a note", "Enter or Esc when you're done.")
    local phl = win.pencil:CreateTexture(nil, "HIGHLIGHT")
    phl:SetAllPoints(); phl:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight"); phl:SetBlendMode("ADD")
    win.notesHint = Text(14, "LEFT")
    win.notesHint:SetPoint("TOPLEFT", eb, "TOPLEFT", 3, -3)
    win.notesHint:SetText("Click the pencil to write a note...")
    win.notesHint:SetAlpha(0.5)

    -- Ducky Says
    win.duckHead = Text(15)
    win.duckHead:SetPoint("TOP", ui, "TOPLEFT", P((BUBBLE[1] + BUBBLE[2]) / 2, BUBBLE[3]))
    win.duckHead:SetText("Ducky Says:")
    win.duckLine = Text(13)
    win.duckLine:SetPoint("TOP", win.duckHead, "BOTTOM", 0, -2)
    win.duckLine:SetWidth((BUBBLE[2] - BUBBLE[1]) * K)
    win.duckLine:SetWordWrap(true)

    -- left page: tiles (Catches) and lines (Waters, Records)
    for i = 1, 24 do
        local b = CreateFrame("Button", nil, ui)
        b:SetSize((CELL - 10) * K, (CELL - 10) * K)
        b.bg = b:CreateTexture(nil, "BACKGROUND")
        b.bg:SetAllPoints(); b.bg:SetColorTexture(0.55, 0.38, 0.18, 0.15)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetPoint("CENTER")
        b.icon:SetSize((CELL - 30) * K, (CELL - 30) * K)
        b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.new = b:CreateTexture(nil, "OVERLAY")
        b.new:SetTexture(Art("new"))
        b.new:SetSize(80 * K, 40 * K)
        b.new:SetPoint("TOPLEFT", -10 * K, 12 * K)
        b.selTex = b:CreateTexture(nil, "OVERLAY")
        b.selTex:SetAllPoints(); b.selTex:SetTexture("Interface\\Buttons\\CheckButtonHilight"); b.selTex:SetBlendMode("ADD")
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.12)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        tiles[i] = b
    end
    for i = 1, 20 do
        local b = CreateFrame("Button", nil, ui)
        b:SetHeight(26 * K)
        b.text = Text(15, "LEFT", b)
        b.text:SetPoint("LEFT", 4, 0)
        b.right = Text(14, "RIGHT", b)
        b.right:SetPoint("RIGHT", -4, 0)
        b.selTex = b:CreateTexture(nil, "BACKGROUND")
        b.selTex:SetAllPoints(); b.selTex:SetColorTexture(0.55, 0.38, 0.18, 0.18)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        lines[i] = b
    end
end

-------------------------------------------------------------------------------
-- Filling the pages
-------------------------------------------------------------------------------
local function ResetLeft()
    for _, t in ipairs(tiles) do t:Hide(); t:SetScript("OnClick", nil); t:SetScript("OnEnter", nil) end
    for _, l in ipairs(lines) do l:Hide(); l:SetScript("OnClick", nil); l:SetScript("OnEnter", nil); l:EnableMouse(true) end
    win.sortBtn:Hide(); win.showBtn:Hide(); win.chalBtn:Hide(); win.counter:SetText("")
    win.complete:Hide(); win.completeFrame:SetScript("OnUpdate", nil)
    win.nav, win.spotKeys = {}, nil
end

local function Pager(page, pages)
    win.navPage, win.navPages = page, pages
    local show = pages > 1
    win.prev:SetShown(show and page > 1)
    win.next:SetShown(show and page < pages)
    win.pageText:SetText(show and (page .. " / " .. pages) or "")
end

-- Ducky's line shrinks until it fits in the speech bubble
local function SetDuck(line)
    local fs, room = win.duckLine, (BUBBLE[4] - BUBBLE[3] - 22) * K
    fs:SetText(line or "")
    for size = 13, 9, -1 do
        Ink.SetFont(fs, size)
        fs:SetText(line or "")
        if (fs:GetStringHeight() or 0) <= room then break end
    end
end

local function Fields(rows)
    for i, f in ipairs(fields) do
        local r = rows[i]
        f.icon:SetShown(r ~= nil)
        f.label:SetText(r and r[1] or "")
        Ink.SetFont(f.value, 16)
        f.value:SetText(r and r[2] or "")
        if r and r[3] then f.value:SetTextColor(r[3][1], r[3][2], r[3][3]) end
        local faction = r and r.faction
        f.crest:SetShown(faction == "Alliance" or faction == "Horde")
        if f.crest:IsShown() then f.crest:SetTexture("Interface\\TargetingFrame\\UI-PVP-" .. faction) end
        -- keep long values inside the page
        if r and r[2] then Ink.Fit(f.value, r[2], 16, (935 - 765) * K) end
    end
end

-- the little list on the right page; scrolls with the mouse wheel when it's long.
-- who: what it's a list for, so the scroll stays put while you click around in it
-- the list by the map: text shrinks to fit, but no smaller than this; a name
-- that still doesn't fit ends in "..." and shows in full on hover
local BOX_MIN = 12
local function Cut(b) return b.text.IsTruncated and b.text:IsTruncated() end
BoxTip = function(b)
    if b and b:IsShown() and Cut(b) then Tip(b, b.full) else GameTooltip:Hide() end
end
local function PaintBox()
    local items, n = box.items or {}, #boxLines
    box.offset = math.max(0, math.min(box.offset, #items - n))
    for i, b in ipairs(boxLines) do
        local it = items[i + box.offset]
        b:SetShown(it ~= nil)
        if it then
            Ink.SetFont(b.right, 13)
            b.right:SetText(it.right or "")
            local room = (BOX[2] - BOX[1] - 30 - BOX_BAR) * K - (it.right and ((b.right:GetStringWidth() or 0) + 6) or 0)
            b.text:SetWidth(room)
            Ink.SetFont(b.text, 14)
            Ink.Fit(b.text, it.text, 14, room, BOX_MIN)
            b.full = it.text
            b.right:SetAlpha(it.faded and 0.55 or 1)
            b.text:SetAlpha(it.faded and 0.55 or 1)
            b.sel:SetShown(box.selected ~= nil and it.key == box.selected)
            b.cur:SetShown(focus == "right" and i + box.offset == box.cursor)
            b:SetScript("OnClick", box.onPick and function() Tick(); box.onPick(it.key, it) end or nil)
        end
    end
    -- the scroll bar, only when there's more than fits
    local more = #items > n
    win.boxUp:SetShown(more); win.boxDown:SetShown(more)
    win.boxTrack:SetShown(more); win.boxThumb:SetShown(more)
    if more then
        win.boxUp.tex:SetAlpha(box.offset > 0 and 0.85 or 0.25)
        win.boxDown.tex:SetAlpha(box.offset + n < #items and 0.85 or 0.25)
        local len = BOX[4] - BOX[3] - 52
        local th = math.max(14, len * n / #items)
        local pos = box.offset / (#items - n)
        win.boxThumb:SetHeight(th * K)
        win.boxThumb:ClearAllPoints()
        win.boxThumb:SetPoint("TOP", ui, "TOPLEFT", P(BOX[2] - BOX_BAR / 2 - 1, BOX[3] + 26 + (len - th) * pos))
    end
end
local function Box(label, items, selected, onPick, who)
    win.boxLabel:SetText(label or "")
    win.hint:SetText("")
    local same = who ~= nil and who == box.who
    box.items, box.selected, box.onPick, box.who = items or {}, selected, onPick, who
    if not same then
        box.offset, box.cursor = 0, 1
        for i, it in ipairs(box.items) do if selected ~= nil and it.key == selected then box.cursor = i end end
        if focus == "right" and not BoxUsable() then focus = "left" end
        -- start with the picked line in view
        for i, it in ipairs(box.items) do
            if selected ~= nil and it.key == selected and i > #boxLines then box.offset = i - #boxLines end
        end
    end
    PaintBox()
end
ScrollBox = function(d)
    if not box.items or #box.items <= #boxLines then return false end
    local was = box.offset
    box.offset = box.offset + d
    PaintBox()
    return box.offset ~= was
end

local function Notes(target)
    win.notes.target = target
    win.notes:SetText(target and target.note or "")
    win.pencil:SetShown(target ~= nil)
    win.notes:ClearFocus()
    win.notesHint:SetShown(target ~= nil and (target.note or "") == "")
end

local function HintFor(id, f)
    local zone = f and f.zones and f.zones[1]
    if not zone then return "Nobody's quite sure where this one bites." end
    local known = false
    for _, name in pairs(DB().zones) do if name == zone then known = true end end
    if known then return Data.Pick(Data.HINT_KNOWN, id):format(zone) end
    local z = Levels(zone)
    local range = z and ("Lv %d-%d"):format(z[1], z[2]) or "Lv ?"
    local pool = Data.HINT_LOCKED[#Data.HINT_LOCKED].lines
    for _, band in ipairs(Data.HINT_LOCKED) do
        if z and z[1] <= band.max then pool = band.lines; break end
    end
    return Data.Pick(pool, id):format(range)
end

Journal.HintFor = HintFor

-- right page: one catch
-- A new fish is written in the first time you open its page: the name letter by
-- letter, then each line, then the rarity badge is stamped down and New! pops.
-- The same quill sound and text fade as the fishing log. Anything that redraws
-- the page finishes it at once.
local WRITE_CPS, SOFT = 40, 6
local function Ease(t) t = math.min(math.max(t, 0), 1); return 1 - (1 - t) * (1 - t) end
local function Reveal(fs, done) if fs.SetAlphaGradient then fs:SetAlphaGradient(done or 1024, SOFT) end end
local writer
local function StopWriting()
    if not writer or not writer.parts then return end
    writer:SetScript("OnUpdate", nil)
    for _, p in ipairs(writer.parts) do
        p.fs:SetAlpha(1)
        if p.text then Reveal(p.fs) end
    end
    local r, n = win.rarityStamp, win.newStamp
    r:SetSize(344 * K, 86 * K); r:SetAlpha(1)
    n:SetSize(96 * K, 48 * K); n:SetAlpha(1)
    writer.parts = nil
end
function Journal.Writer() return writer end
local function WriteIn()
    writer = writer or CreateFrame("Frame", nil, win)
    StopWriting()
    local parts, at = {}, 0.1
    -- the name, a letter at a time
    for _, fs in ipairs(win.rightTitle.letters) do
        if fs:IsShown() then parts[#parts + 1] = { fs = fs, start = at, letter = true }; at = at + 1 / 22 end
    end
    at = at + 0.15
    -- then each line, label and value
    for _, f in ipairs(fields) do
        for _, fs in ipairs({ f.label, f.value }) do
            local len = #(fs:GetText() or "")
            if len > 0 then parts[#parts + 1] = { fs = fs, start = at, text = true }; at = at + len / WRITE_CPS + 0.04 end
        end
    end
    for _, b in ipairs(boxLines) do
        if b:IsShown() then
            local len = #(b.text:GetText() or "")
            parts[#parts + 1] = { fs = b.text, start = at, text = true }; at = at + len / WRITE_CPS + 0.04
        end
    end
    for _, p in ipairs(parts) do p.fs:SetAlpha(0) end
    local stampAt, popAt = at + 0.1, at + 0.45
    local r, n = win.rarityStamp, win.newStamp
    local stamped, popped = not r:IsShown(), false
    r:SetAlpha(0); n:SetAlpha(0)
    writer.parts = parts
    local t = 0
    ns.WriteSound()
    writer:SetScript("OnUpdate", function(self, el)
        t = t + el
        for _, p in ipairs(parts) do
            if t >= p.start then
                if p.letter then p.fs:SetAlpha(math.min(1, (t - p.start) / 0.12))
                else p.fs:SetAlpha(1); Reveal(p.fs, (t - p.start) * WRITE_CPS) end
            end
        end
        -- the badge: big and faint, then down with a thump
        if t >= stampAt and r:IsShown() then
            local k = (t - stampAt) / 0.16
            local sc = k < 1 and (1.8 - 0.85 * Ease(k)) or (0.95 + 0.05 * Ease((t - stampAt - 0.16) / 0.08))
            r:SetSize(344 * K * sc, 86 * K * sc)
            r:SetAlpha(math.min(1, k * 1.5))
            if k >= 1 and not stamped then stamped = true; Sound("IG_ABILITY_ICON_DROP") end
        end
        if t >= popAt then
            local k = Ease((t - popAt) / 0.2)
            n:SetAlpha(k)
            n:SetSize(96 * K * (1.4 - 0.4 * k), 48 * K * (1.4 - 0.4 * k))
            if not popped then popped = true; ns.Glint(n, 5, 1.4) end
        end
        if t > popAt + 0.3 then StopWriting() end
    end)
end

local function ShowItem(id, mystery, zone)
    StopWriting()
    win.rightTitle:Centre(nil, nil)
    local j = DB()
    local e = id and not mystery and j.items[id] or nil
    win.newStamp:Hide()
    win.rarityStamp:Hide()
    if not id then
        win.rightTitle:SetText("")
        Fields({}); Box(nil, {}); Notes(nil); DrawMap(nil); SetDuck(Data.Pick(Data.DUCKY_GENERAL, "empty"))
        return
    end
    if not e or CountOf(e) == 0 then
        win.rightTitle:SetText("???")
        Fields({ { "Rarity:", "???" }, { "Caught:", "0" }, { "First caught:", "Not yet" }, { "Last caught:", "-" } })
        Box("Hint", {})
        win.hint:SetText(HintFor(id, Data.FISH[id] or Data.FINDS[id]))
        -- a zone you've found shows its map, unexplored; otherwise just a mystery
        local mapID
        local known = Data.FISH[id] or Data.FINDS[id]
        zone = zone or (known and known.zones and known.zones[1])
        for zid, name in pairs(DB().zones) do if name == zone then mapID = zid end end
        Notes(nil); DrawMap(mapID)
        SetDuck(Data.Pick(Data.DUCKY_MYSTERY, id))
        return
    end
    local q = Ink.RARITY[e.quality or 1] or Ink.RARITY[1]
    win.rightTitle:SetText(ns.FishName(e.name))
    win.rightTitle:SetTextColor(q[1], q[2], q[3])
    local qname = _G["ITEM_QUALITY" .. (e.quality or 1) .. "_DESC"] or "?"
    Fields({ { "Rarity:", qname, q }, { "Caught:", tostring(CountOf(e)) },
        { "First caught:", Date(e.first) }, { "Last caught:", Date(e.last) } })
    local fresh = not e.seen
    if fresh then win.newStamp:Show(); e.seen = true end
    if (e.quality or 0) >= 1 and e.quality <= 7 then
        win.rarityStamp:SetTexture(Art("rarity" .. e.quality))
        win.rarityStamp:Show()
    end
    -- spots, most catches first
    local spots = {}
    for k, n in pairs(e.spots or {}) do
        local s = j.spots[k]
        if s then spots[#spots + 1] = { key = k, n = n, text = SpotName(s), right = tostring(n) } end
    end
    table.sort(spots, function(a, b) return a.n > b.n end)
    win.spotKeys = {}
    for n, sp in ipairs(spots) do win.spotKeys[n] = sp.key end
    local spot = sel.spot and e.spots[sel.spot] and sel.spot or (spots[1] and spots[1].key)
    sel.spot = spot
    Box("Spotted at", spots, spot, function(k) sel.spot = k; Journal:Refresh() end, "item" .. id)
    local s = spot and j.spots[spot]
    DrawMap(s and s.mapID, spot and e.pins and e.pins[spot])
    Notes(e)
    -- Ducky's word on this fish, for the zone you're looking at it in
    local kind = Journal.Kind(e, id)
    local general = kind == "treasure" and Data.DUCKY_TREASURE or kind == "junk" and Data.DUCKY_JUNK or Data.DUCKY_GENERAL
    SetDuck(Data.Pun(id, zone or ZoneName(e)) or Data.Pick(general, id))
    if fresh and win:IsShown() then WriteIn() end
end

-- what bites in a zone: what you caught at this spot (with its share), what you've
-- caught elsewhere in the zone, then "???" for every fish here you haven't caught here
local function BitesIn(zone, spot)
    local j, list, have = DB(), {}, {}
    local function Name(id) local e = j.items[id]; return e and ns.FishName(e.name) or "?" end
    if spot then
        local mine = {}
        for id, n in pairs(spot.items) do mine[#mine + 1] = { key = id, n = n } end
        table.sort(mine, function(a, b) return a.n > b.n end)
        for _, m in ipairs(mine) do
            have[m.key] = true
            list[#list + 1] = { key = m.key, text = Name(m.key), right = ("%d%%"):format(math.floor(m.n / math.max(spot.count, 1) * 100 + 0.5)) }
        end
    end
    local elsewhere = {}
    for _, s in pairs(j.spots) do
        if s.zone == zone and s ~= spot then
            for id in pairs(s.items) do if not have[id] then have[id] = true; elsewhere[#elsewhere + 1] = id end end
        end
    end
    table.sort(elsewhere, function(a, b) return Name(a) < Name(b) end)
    for _, id in ipairs(elsewhere) do list[#list + 1] = { key = id, text = Name(id) } end
    local unknown = {}
    for id, f in pairs(Data.FISH) do
        if not have[id] then
            for _, z in ipairs(f.zones or {}) do if z == zone then unknown[#unknown + 1] = id; break end end
        end
    end
    table.sort(unknown)
    for _, id in ipairs(unknown) do list[#list + 1] = { key = id, text = "???", faded = true, mystery = true } end
    return list
end
-- clicking a fish in that list opens it on Catches (a "???" stays a mystery)
local function BitePick(zone, spotKey)
    return function(id, it)
        focus = "left"
        mode, sel.catches, sel.spot = "catches", id, nil
        sel.catchesZone, sel.catchesUnknown = zone, it and it.mystery or false
        if not (it and it.mystery) and spotKey and DB().items[id] and DB().items[id].spots[spotKey] then sel.spot = spotKey end
        Journal.jump = id
        Journal:Refresh()
    end
end

-- right page: one spot
local function ShowSpot(key)
    StopWriting()
    win.rightTitle:Centre(RIGHT_CENTRED[1], RIGHT_CENTRED[2])
    local s = key and DB().spots[key]
    win.newStamp:Hide()
    win.rarityStamp:Hide()
    if not s then
        win.rightTitle:SetText("")
        Fields({}); Box(nil, {}); Notes(nil); DrawMap(nil); SetDuck(Data.Pick(Data.DUCKY_WATERS, "empty"))
        return
    end
    win.rightTitle:SetText(SpotName(s))
    local kinds = 0
    for _ in pairs(s.items) do kinds = kinds + 1 end
    Fields({ { "Zone:", s.zone, faction = Data.FACTION[s.zone] }, { "Catches here:", tostring(s.count) },
        { "Kinds:", tostring(kinds) }, { "Last fished:", Date(s.last) } })
    Box("What bites here", BitesIn(s.zone, s), nil, BitePick(s.zone, key), "spot" .. key)
    DrawMap(s.mapID, s.pins)
    Notes(s)
    SetDuck(Data.Pick(Data.DUCKY_WATERS, key))
end

-- right page: a zone you haven't fished (yet), or haven't even found
ShowZone = function(z)
    StopWriting()
    win.rightTitle:Centre(RIGHT_CENTRED[1], RIGHT_CENTRED[2])
    win.newStamp:Hide()
    win.rarityStamp:Hide()
    Notes(nil)
    -- "???" for everything that bites there
    Box("What bites here", BitesIn(z.name), nil, z.state ~= 3 and BitePick(z.name) or nil, "zone" .. z.name)
    if z.state == 3 then
        win.rightTitle:SetText("Undiscovered")
        Fields({ { "Zone:", "???" }, { "Catches here:", "???" }, { "Kinds:", "???" }, { "Last fished:", "???" } })
        DrawMap(nil)
        local where = z.cont and Data.Pick(Data.DUCKY_UNDISCOVERED, z.name):format(z.cont) or Data.DUCKY_OFF_MAP
        SetDuck(where)
        return
    end
    win.rightTitle:SetText(z.name)
    Fields({ { "Zone:", z.name, faction = Data.FACTION[z.name] }, { "Catches here:", "0" },
        { "Kinds:", "0" }, { "Last fished:", "Never" } })
    DrawMap(z.id)
    SetDuck(Data.Pick(Data.DUCKY_UNFISHED, z.name))
end

-- a page of thumbnails, in groups with headings. m: which bookmark it is.
-- Head(c) is the group a thing goes under, Label(h) how that heading reads.
-- everything known for that bookmark found?
function Journal.IsComplete(m)
    local known = m == "finds" and Data.FINDS or Data.FISH
    local items = DB().items
    if not next(known) then return false end
    for id in pairs(known) do
        local e = items[id]
        if not e or CountOf(e) == 0 then return false end
    end
    return true
end
-- the stamp comes down with a thump the first time you see it, then just stays
local function ShowComplete(m)
    local t = win.complete
    win.completeFrame:SetScript("OnUpdate", nil)
    if not Journal.IsComplete(m) then t:Hide(); return end
    t:Show(); t:SetAlpha(0.9)
    local w = COMPLETE[3] * K
    t:SetSize(w, w / 2)
    local j = DB()
    j.stamped = j.stamped or {}
    if j.stamped[m] or not win:IsShown() then return end
    j.stamped[m] = true
    local f, el = win.completeFrame, 0
    t:SetAlpha(0)
    f:SetScript("OnUpdate", function(self, d)
        el = el + d
        local k = math.min(1, math.max(0, (el - 0.3) / 0.18))
        local sc = 1.8 - 0.8 * Ease(k)
        t:SetSize(w * sc, w / 2 * sc)
        t:SetAlpha(0.9 * math.min(1, k * 1.5))
        if k >= 1 then
            self:SetScript("OnUpdate", nil)
            Sound("IG_ABILITY_ICON_DROP")
        end
    end)
end

local function GridPage(m, list, dupes, Head, Label, empty)
    -- lay out: zone headings take a short row, then rows of 4 tiles
    local grouped = dupes -- the same fish under more than one zone
    local pages, y, col, lastZone = { {} }, GRID_TOP, 0, nil
    local function Add(cell) table.insert(pages[#pages], cell) end
    local function Heading(h, more) Add({ heading = Label(h) .. (more and " (more)" or ""), y = y }); y = y + 30 end
    local function NewPage() pages[#pages + 1] = {}; y, col = GRID_TOP, 0 end
    for _, c in ipairs(list) do
        local head = Head(c)
        if head and head ~= lastZone then
            if col > 0 then y, col = y + CELL, 0 end
            if y + 30 + CELL > GRID_BOTTOM then NewPage() end
            Heading(head)
            lastZone = head
        end
        if col == 0 and y + CELL > GRID_BOTTOM then
            NewPage()
            if head then Heading(head, true) end
        end
        Add({ c = c, x = LEFT_X[1] + col * CELL, y = y })
        col = col + 1
        if col == 4 then y, col = y + CELL, 0 end
    end
    if Journal.jump then -- turn to the page with that catch
        for n, pg in ipairs(pages) do
            for _, cell in ipairs(pg) do
                if cell.c and cell.c.id == Journal.jump and (not grouped or cell.c.zone == sel[m .. "Zone"]) then pageOf[m] = n end
            end
        end
        Journal.jump = nil
    end
    local page = math.min(math.max(pageOf[m], 1), #pages)
    pageOf[m] = page
    Pager(page, #pages)
    local t, l = 0, 0
    if not sel[m] and list[1] then sel[m] = list[1].id end
    local lit = false
    for _, cell in ipairs(pages[page]) do
        if cell.heading then
            l = l + 1
            local b = lines[l]
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", ui, "TOPLEFT", P(LEFT_X[1], cell.y))
            b:SetWidth((LEFT_X[2] - LEFT_X[1]) * K)
            Ink.SetFont(b.text, 15)
            Ink.Fit(b.text, cell.heading, 15, (LEFT_X[2] - LEFT_X[1] - 10) * K)
            b.right:SetText("")
            b.selTex:Hide()
            b:EnableMouse(false)
            b:Show()
        elseif tiles[t + 1] then
            t = t + 1
            local b, c = tiles[t], cell.c
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", ui, "TOPLEFT", P(cell.x + 5, cell.y + 5))
            local icon = c.e and c.e.icon or Instant(c.id) or 134400
            -- only one copy lights up: the one in the zone you picked it from
            local on = sel[m] == c.id and (not grouped or sel[m .. "Zone"] == c.zone
                or (sel[m .. "Zone"] == nil and not lit))
            if on then lit = { unknown = c.unknown, zone = c.zone } end
            b.icon:SetTexture(icon)
            if c.unknown then
                b.icon:SetVertexColor(0.18, 0.12, 0.06); b.icon:SetAlpha(0.7)
            else
                b.icon:SetVertexColor(1, 1, 1); b.icon:SetAlpha(1)
            end
            b.new:SetShown(c.e ~= nil and not c.e.seen)
            -- a fresh catch's New! pops in the first time you see it on the grid
            b:SetScript("OnUpdate", nil); b.new:SetAlpha(1); b.new:SetSize(80 * K, 40 * K)
            if b.new:IsShown() and not popped[c.id] and win:IsShown() then
                popped[c.id] = true
                local t = 0
                b.new:SetAlpha(0)
                b.glinted = nil
                b:SetScript("OnUpdate", function(self, el)
                    t = t + el
                    local k = Ease((t - 0.15) / 0.2)
                    if t >= 0.15 and not self.glinted then self.glinted = true; ns.Glint(self.new, 3, 1.2) end
                    self.new:SetAlpha(t < 0.15 and 0 or k)
                    self.new:SetSize(80 * K * (1.4 - 0.4 * k), 40 * K * (1.4 - 0.4 * k))
                    if t > 0.4 then self:SetScript("OnUpdate", nil) end
                end)
            end
            b.selTex:SetShown(on)
            local function Pick()
                sel[m], sel[m .. "Zone"], sel[m .. "Unknown"], sel.spot = c.id, grouped and c.zone or nil, c.unknown, nil
                Journal:Refresh()
            end
            b:SetScript("OnClick", function() Tick(); Pick() end)
            win.nav[#win.nav + 1] = { x = cell.x, y = cell.y, go = Pick, on = on }
            b:SetScript("OnEnter", function(self)
                if c.unknown then Tip(self, "???", HintFor(c.id, c.f))
                else
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    if not pcall(GameTooltip.SetItemByID, GameTooltip, c.id) then GameTooltip:SetText(ns.FishName(c.e.name)) end
                    GameTooltip:Show()
                end
            end)
            b:Show()
        end
    end
    if #list == 0 then
        win.counter:SetText("")
        win.pageText:SetText(empty)
    end
    if lit then ShowItem(sel[m], lit.unknown, grouped and lit.zone or nil)
    else ShowItem(sel[m], sel[m .. "Unknown"], sel[m .. "Zone"]) end
    ShowComplete(m)
end

local function CatchesPage()
    win.leftTitle:SetText("Fishing Journal")
    win.sortBtn:Show()
    win.sortText:SetText("Sort: " .. SORT_NAMES[ns.db.journalSort or "zone"])
    local list = SortedCatalogue()
    local found = 0
    local ids, kinds = {}, 0
    for _, c in ipairs(list) do
        if not ids[c.id] then
            ids[c.id] = true
            kinds = kinds + 1
            local e = DB().items[c.id]
            if e and CountOf(e) > 0 then found = found + 1 end
        end
    end
    win.counter:SetText(found .. " of " .. kinds .. " found")
    local byZone = (ns.db.journalSort or "zone") == "zone"
    GridPage("catches", list, byZone, function(c) return byZone and c.zone or nil end, ZoneLabel, "Nothing caught yet!")
end

-- Whosits & Whatsits: everything that isn't a fish
local function FindsPage()
    win.leftTitle:SetText("Whosits & Whatsits")
    local how = ns.db.journalFindsSort or "type"
    win.sortBtn:Show(); win.showBtn:Show()
    win.sortText:SetText("Sort: " .. SORT_NAMES[how])
    win.showText:SetText("Show: " .. SHOW_NAMES[ns.db.journalFindsShow or "all"])
    local list = FindsCatalogue()
    local ids, found, kinds = {}, 0, 0
    for _, c in ipairs(list) do
        if not ids[c.id] then
            ids[c.id] = true; kinds = kinds + 1
            local e = DB().items[c.id]
            if e and CountOf(e) > 0 then found = found + 1 end
        end
    end
    win.counter:SetText(found .. " of " .. kinds .. " found")
    local Head = how == "type" and function(c) return c.group end or how == "zone" and function(c) return c.zone end or function() return nil end
    local Label = how == "zone" and ZoneLabel or function(h) return h end
    GridPage("finds", list, how == "zone", Head, Label, "Nothing but fish so far!")
end

local LINES_PER_PAGE = 18
local function ListPage(entries, onDraw)
    local pages = math.max(1, math.ceil(#entries / LINES_PER_PAGE))
    local page = math.min(math.max(pageOf[mode], 1), pages)
    pageOf[mode] = page
    Pager(page, pages)
    for i = 1, LINES_PER_PAGE do
        local en = entries[(page - 1) * LINES_PER_PAGE + i]
        if en then
            local b = lines[i]
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", ui, "TOPLEFT", P(LEFT_X[1] + (en.indent or 0), GRID_TOP + (i - 1) * 27))
            b:SetWidth((LEFT_X[2] - LEFT_X[1] - (en.indent or 0)) * K)
            Ink.SetFont(b.text, en.size or 15)
            Ink.Fit(b.text, en.text, en.size or 15, (LEFT_X[2] - LEFT_X[1] - (en.indent or 0) - 50) * K)
            local c = en.color or Ink.INK
            b.text:SetTextColor(c[1], c[2], c[3])
            b.text:SetAlpha(en.faded and 0.55 or 1)
            b.right:SetText(en.right or "")
            local rc = en.rightColor or c
            b.right:SetTextColor(rc[1], rc[2], rc[3])
            b.selTex:SetShown(en.selected or false)
            b:EnableMouse(en.onClick ~= nil)
            b:SetScript("OnClick", function() Tick(); en.onClick() end)
            b:Show()
            if en.onClick and not en.skipNav then win.nav[#win.nav + 1] = { x = 0, y = i, go = en.onClick, on = en.selected } end
        end
    end
end

local function WatersPage()
    win.leftTitle:SetText("Waters")
    local j = DB()
    -- spots by zone
    local byZone = {}
    for key, s in pairs(j.spots) do
        byZone[s.zone] = byZone[s.zone] or {}
        table.insert(byZone[s.zone], { key = key, s = s })
    end
    local zones, seen = {}, {}
    for zone, list in pairs(byZone) do
        table.sort(list, function(a, b) return SpotName(a.s) < SpotName(b.s) end)
        zones[#zones + 1] = { name = zone, spots = list, state = 1 }
        seen[zone] = true
    end
    local all = AllZones()
    local found = 0
    for _, z in ipairs(all) do
        if j.zones[z.id] then found = found + 1 end
        if not seen[z.name] then
            zones[#zones + 1] = { name = z.name, id = z.id, cont = z.cont, state = j.zones[z.id] and 2 or 3 }
            seen[z.name] = true
        end
    end
    table.sort(zones, function(a, b)
        if a.state ~= b.state then return a.state < b.state end
        return ZoneBefore(a.name, b.name)
    end)
    if #all > 0 then win.counter:SetText(found .. " of " .. #all .. " zones found") end
    local entries = {}
    if not sel.waters and not sel.watersZone then
        for _, z in ipairs(zones) do if z.spots then sel.waters = z.spots[1].key; break end end
        if not sel.waters and zones[1] then sel.watersZone = zones[1].name end
    end
    local picked -- a zone with no spots of yours, picked from the list
    for _, z in ipairs(zones) do
        local function PickZone() sel.waters, sel.watersZone = nil, z.name; Journal:Refresh() end
        if sel.watersZone == z.name then picked = z end
        if z.state == 3 then
            -- not found yet: still something to point at, with a hint from Ducky
            local lv = Levels(z.name)
            entries[#entries + 1] = { text = "???", right = lv and ("Lv %d-%d"):format(lv[1], lv[2]) or nil, faded = true,
                selected = sel.watersZone == z.name, onClick = PickZone }
        elseif not z.spots then
            entries[#entries + 1] = { text = ZoneLabel(z.name), size = 16, faded = true,
                selected = sel.watersZone == z.name, onClick = PickZone }
        else
            local first = z.spots[1].key
            -- the D-pad skips the heading (it would only jump back to the first spot)
            entries[#entries + 1] = { text = ZoneLabel(z.name), size = 16, skipNav = true,
                onClick = function() sel.waters, sel.watersZone = first, nil; Journal:Refresh() end }
            for _, sp in ipairs(z.spots) do
                entries[#entries + 1] = { text = SpotName(sp.s), right = tostring(sp.s.count), indent = 22, size = 14,
                    selected = sel.waters == sp.key,
                    onClick = function() sel.waters, sel.watersZone = sp.key, nil; Journal:Refresh() end }
            end
        end
    end
    ListPage(entries)
    if picked then ShowZone(picked) else ShowSpot(sel.waters) end
end

local RARE = 3 -- blue and up
local COMPLETE_RED = { 0.75, 0.08, 0.06 }
local function Duration(sec)
    sec = math.floor((sec or 0) / 60)
    if sec < 60 then return sec .. "m" end
    return ("%dh %02dm"):format(math.floor(sec / 60), sec % 60)
end

local function RecordsPage()
    win.leftTitle:SetText("Records")
    local j, st = DB(), Stats()
    local by, found = { fish = 0, treasure = 0, junk = 0 }, { fish = 0, treasure = 0, junk = 0 }
    local rarest, most, firstOf = nil, nil, {}
    for id, e in pairs(j.items) do
        local n = CountOf(e)
        if n > 0 then
            local k = Journal.Kind(e, id)
            by[k], found[k] = by[k] + n, found[k] + 1
            if not rarest or (e.quality or 0) > (j.items[rarest].quality or 0) then rarest = id end
            if k == "fish" and (not most or n > CountOf(j.items[most])) then most = id end
        end
    end
    for _, f in ipairs(j.firsts) do -- oldest first
        local e = j.items[f[1]]
        if e then
            local k = Journal.Kind(e, f[1])
            firstOf[k] = firstOf[k] or f
            if (e.quality or 0) >= RARE then firstOf.rare = firstOf.rare or f end
            firstOf.water = firstOf.water or f
        end
    end
    -- spots: most catches, most rare catches, most days
    local busiest, lucky, luckyN, visited = nil, nil, 0, nil
    for key, sp in pairs(j.spots) do
        if not busiest or sp.count > j.spots[busiest].count then busiest = key end
        local r = 0
        for id, n in pairs(sp.items) do
            local e = j.items[id]
            if e and (e.quality or 0) >= RARE then r = r + n end
        end
        if r > luckyN then lucky, luckyN = key, r end
        if (sp.days or 0) > 0 and (not visited or sp.days > (j.spots[visited].days or 0)) then visited = key end
    end
    local zonesFound, zonesAll = 0, #AllZones()
    for _ in pairs(j.zones) do zonesFound = zonesFound + 1 end
    local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end
    local nFish, nTreasure, nJunk = count(Data.FISH), 0, 0
    for _, f in pairs(Data.FINDS) do if f[1] == "junk" then nJunk = nJunk + 1 else nTreasure = nTreasure + 1 end end

    local entries = {}
    local function Head(text) entries[#entries + 1] = { text = text, size = 17 } end
    local function Line(text, right, extra)
        local en = { text = text, right = right and tostring(right) or nil, size = 15, indent = 10 }
        for k, v in pairs(extra or {}) do en[k] = v end
        entries[#entries + 1] = en
    end
    local function Item(label, id, right)
        if not id then return end
        local e = j.items[id]
        Line(label .. ": " .. ns.FishName(e.name), right, { color = Ink.RARITY[e.quality or 1],
            selected = sel.records == id, onClick = function() sel.records = id; Journal:Refresh() end })
    end
    local function Spot(label, key, right)
        if not key then return end
        Line(label .. ": " .. SpotName(j.spots[key]), right,
            { onClick = function() mode = "waters"; sel.waters, sel.watersZone = key, nil; Journal:Refresh() end })
    end
    local function First(label, f)
        if not f then return end
        local e = j.items[f[1]]
        Line(label .. ": " .. ns.FishName(e.name), date("%b %d", f[2]), { color = Ink.RARITY[e.quality or 1],
            selected = sel.records == f[1], onClick = function() sel.records = f[1]; Journal:Refresh() end })
    end
    local function Done(label, have, all)
        local full = all > 0 and have >= all
        Line(label, full and "COMPLETE!" or (have .. " of " .. all), full and { rightColor = COMPLETE_RED } or nil)
    end

    if ns.Challenges then
        local n, all = ns.Challenges:Count()
        win.chalText:SetText("Ducky's Challenges  \194\187")
        win.chalCount:SetText(n .. " of " .. all .. " done")
        win.chalBtn:Show()
    end
    Head("General")
    Line("Fish caught", by.fish)
    Line("Treasure found", by.treasure)
    Line("Junk found", by.junk)
    Line("Total casts", st.casts or 0)
    Line("Successful catches", st.catches or 0)
    Line("Waters discovered", zonesFound)
    Line("Fish discovered", found.fish)
    Line("Whosits & Whatsits discovered", found.treasure + found.junk)
    if ns.Flair then
        local f = ns.Flair.Saved()
        Head("Shiny Fishbones")
        Line("Fishbones found", f.earned or 0)
        Line("Spent at Mrrl's", f.spent or 0)
        Line("In your pocket", f.bones or 0)
    end

    Head("Personal bests")
    Line("Biggest haul", j.best or 0)
    Item("Rarest catch", rarest)
    Item("Most caught", most, most and CountOf(j.items[most]))
    Spot("Busiest spot", busiest, busiest and j.spots[busiest].count)
    Spot("Lucky spot", lucky, lucky and luckyN)
    Spot("Most visited", visited, visited and (j.spots[visited].days .. (j.spots[visited].days == 1 and " day" or " days")))
    Line("Longest session", Duration(st.longest))

    Head("Streaks")
    Line("Longest dry spell", st.dryBest or 0)
    Line("Longest catch streak", st.streakBest or 0)
    Line("Longest treasure streak", st.tStreakBest or 0)

    Head("Firsts")
    First("Fish", firstOf.fish)
    First("Treasure", firstOf.treasure)
    First("Junk", firstOf.junk)
    First("Rare catch", firstOf.rare)
    if firstOf.water then
        local sp = j.spots[firstOf.water[3]]
        if sp then Spot("Water", firstOf.water[3], date("%b %d", firstOf.water[2])) end
    end

    Head("Collection")
    Done("All fish", found.fish, nFish)
    Done("All treasure", found.treasure, nTreasure)
    Done("All junk", found.junk, nJunk)
    Done("All waters", zonesFound, zonesAll)

    Head("Diary of firsts")
    for i = #j.firsts, 1, -1 do
        local f = j.firsts[i]
        local e = j.items[f[1]]
        if e then
            entries[#entries + 1] = { text = date("%b %d", f[2]) .. "  " .. ns.FishName(e.name), color = Ink.RARITY[e.quality or 1],
                indent = 10, size = 14, selected = sel.records == f[1],
                onClick = function() sel.records = f[1]; Journal:Refresh() end }
        end
    end
    sel.records = sel.records or rarest
    ListPage(entries)
    ShowItem(sel.records)
end

function Journal:Refresh()
    if not win then return end
    ResetLeft()
    for _, r in ipairs(win.ribbons) do
        local on = r.mode == mode
        r.icon:SetDesaturated(not on)
        r.icon:SetAlpha(on and 1 or 0.6)
        r.icon:SetSize((on and 46 or 38) * K, (on and 46 or 38) * K)
    end
    if mode == "waters" then WatersPage()
    elseif mode == "records" then RecordsPage()
    elseif mode == "finds" then FindsPage()
    else CatchesPage() end
    -- after a page turn from the controller: pick the first or last thing on it
    local want = Journal.pendingNav
    Journal.pendingNav = nil
    if want and #win.nav > 0 then (want == "first" and win.nav[1] or win.nav[#win.nav]).go() end
    -- only with Forever's Gamepad UI turned on
    if ns.OneKey and ns.OneKey.GamepadUIOn() then win.padBar:Show() else win.padBar:Hide() end
    if win.padBar:IsShown() then win.padBar:Paint() end
end

-------------------------------------------------------------------------------
-- Controller: the D-pad moves through the left page (turning pages at the
-- edges), the shoulders flip bookmarks, A shows the next spot, X sorts, Y
-- filters, View hops between the left and right pages, B closes. Triggers are left alone, so
-- one-button fishing keeps working with the book open.
-------------------------------------------------------------------------------
local function Turn(step, pick)
    local page = (win.navPage or 1) + step
    if page < 1 or page > (win.navPages or 1) then return false end
    pageOf[mode] = page
    Journal.pendingNav = pick
    Sound("IG_ABILITY_PAGE_TURN")
    Journal:Refresh()
    return true
end
local function Move(dir)
    local nav = win.nav or {}
    if #nav == 0 then return end
    local cur
    for n, it in ipairs(nav) do if it.on then cur = n end end
    if not cur then Tick(); nav[1].go() return end
    local here = nav[cur]
    if dir == "left" or dir == "right" then
        local step = dir == "left" and -1 or 1
        if mode == "catches" or mode == "finds" then
            local to = nav[cur + step]
            if to then Tick(); to.go() else Turn(step, step < 0 and "last" or "first") end
        else
            Turn(step, "first")
        end
        return
    end
    local up = dir == "up"
    if mode == "catches" or mode == "finds" then
        -- the nearest tile straight above or below, else the nearest row's closest tile
        local best, bestScore
        for n, it in ipairs(nav) do
            if (up and it.y < here.y) or (not up and it.y > here.y) then
                local score = math.abs(it.y - here.y) * 10 + math.abs(it.x - here.x)
                if not bestScore or score < bestScore then best, bestScore = n, score end
            end
        end
        if best then Tick(); nav[best].go() else Turn(up and -1 or 1, up and "last" or "first") end
    else
        local to = nav[cur + (up and -1 or 1)]
        if to then Tick(); to.go() else Turn(up and -1 or 1, up and "last" or "first") end
    end
end
local function NextSpot()
    local keys = win.spotKeys
    if not keys or #keys < 2 then return end
    local at = 1
    for n, k in ipairs(keys) do if k == sel.spot then at = n end end
    sel.spot = keys[at % #keys + 1]
    Journal:Refresh()
end
-- on the right page the D-pad walks the little list there instead
local Swap
local function RightMove(dir)
    if dir == "left" then return Swap() end
    if dir ~= "up" and dir ~= "down" then return end
    local n = #(box.items or {})
    if n == 0 then return end
    local was = box.cursor
    box.cursor = math.max(1, math.min(n, box.cursor + (dir == "up" and -1 or 1)))
    if box.cursor ~= was then Tick() end
    if box.cursor <= box.offset then box.offset = box.cursor - 1 end
    if box.cursor > box.offset + #boxLines then box.offset = box.cursor - #boxLines end
    PaintBox()
    BoxTip(boxLines[box.cursor - box.offset])
end
Swap = function()
    if focus == "left" and not BoxUsable() then return end
    focus = focus == "left" and "right" or "left"
    Tick()
    if focus == "right" then
        -- start on the line in view
        box.cursor = math.max(box.offset + 1, math.min(box.cursor, box.offset + #boxLines, #box.items))
    end
    PaintBox()
    if focus == "right" then BoxTip(boxLines[box.cursor - box.offset]) else GameTooltip:Hide() end
    if win.padBar:IsShown() then win.padBar:Paint() end
end
local function D(dir) return function() if focus == "right" then RightMove(dir) else Move(dir) end end end
local PAD = {
    PADDUP = D("up"), PADDDOWN = D("down"), PADDLEFT = D("left"), PADDRIGHT = D("right"),
    PADLSHOULDER = function() win.flip(-1) end, PADRSHOULDER = function() win.flip(1) end,
    PAD1 = function()
        Tick()
        if focus == "right" then
            local it = box.items and box.items[box.cursor]
            if it and box.onPick then box.onPick(it.key, it) end
        elseif mode == "catches" or mode == "finds" then NextSpot() end
    end,
    PAD2 = function() win:Hide() end,
    PAD3 = function() if (mode == "catches" or mode == "finds") and focus == "left" then pcall(win.sortBtn.Click, win.sortBtn) end end,
    PADRSTICK = function() if mode == "finds" and focus == "left" then pcall(win.showBtn.Click, win.showBtn) end end,
    -- Y, from anywhere in the journal: Ducky's Challenges
    PAD4 = function() if ns.ChallengesWindow then Tick(); ns.ChallengesWindow:Toggle() end end,
    PADBACK = Swap,
}
Journal.PAD = PAD

-------------------------------------------------------------------------------
-- Showing it
-------------------------------------------------------------------------------
local function Place()
    win:SetScale(ns.db.journalScale or 1)
    win:ClearAllPoints()
    local pos = ns.db.journalPos
    if pos then win:SetPoint(pos[1], UIParent, pos[2] or pos[1], pos[3], pos[4])
    else win:SetPoint("CENTER", UIParent, "CENTER", 0, 120) end -- room below for the controller bar, clear of the controller's own buttons
end

-- from the fishing log: open on one catch
function Journal:OpenTo(id)
    if not ns.db.journalEnabled then return self:Toggle(true) end
    local e = DB().items[id]
    -- fish open on Catches, everything else on Whosits & Whatsits
    mode = (Journal.Kind(e, id) == "fish") and "catches" or "finds"
    sel[mode], sel.spot, Journal.jump = id, nil, id
    sel[mode .. "Zone"], sel[mode .. "Unknown"] = mode == "catches" and e and ZoneName(e) or nil, false
    if win and win:IsShown() then self:Refresh() else self:Show() end
end

function Journal:Show()
    if not ns.db.journalEnabled then return end
    if not win then Build() end
    Place()
    win:Show()
    self:Refresh()
end
function Journal:Hide() if win then win:Hide() end end
function Journal:Toggle(loud)
    if win and win:IsShown() then win:Hide() return end
    if not ns.db.journalEnabled then
        if loud then ns.Chat("the fishing journal is turned off. Turn it on in the settings, on the Fishing journal page.") end
        return
    end
    self:Show()
end
local button = ns.Launcher{ name = "RubberDuckyJournalButton", art = Art("button"), title = "Fishing journal",
    show = "journalButton", locked = "journalButtonLocked", size = "journalButtonSize", pos = "journalButtonPos",
    point = { "LEFT", UIParent, "LEFT", 30, 330 },
    enabled = function() return ns.db.journalEnabled end, toggle = function() Journal:Toggle(true) end }
function Journal:ApplyButton() button:Apply() end
function Journal:ResetButton() button:Reset() end

-- the "Ducky Journal" macro
Journal.MACRO_ICON = "Interface\\Icons\\INV_Misc_Book_11"
function Journal:PickupMacro() ns.PickupMacro("Ducky Journal", Journal.MACRO_ICON, "/ducky journal", "journal") end

function Journal:ResetPosition()
    ns.db.journalPos = nil
    if win then Place() end
end
function Journal:Apply()
    self:ApplyButton()
    if not ns.db.journalEnabled then self:Hide() return end
    if win and win:IsShown() then Place() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        DB()
        Journal:ApplyButton()
        C_Timer.After(3, function() ns.Safe(Journal.ScanZones, Journal) end)
    else
        C_Timer.After(1, function() ns.Safe(Journal.NoteZone, Journal) end)
    end
end)
