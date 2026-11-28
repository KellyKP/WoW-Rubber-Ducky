-- Rubber Ducky: a nudge when you can learn the next fishing rank. When your
-- skill reaches its cap (and every catch stops counting), a banner hangs under
-- the fishing log, one for each rank (Kelly's art: Apprentice, Journeyman, Expert, Artisan).
-- Hover it for where to go and where to fish next; right-click hides it until
-- next time. Forever's ranks and places: Wowhead's Forever fishing guide.

local _, ns = ...
local Rank = {}
ns.Rank = Rank

-- the next rank, by the cap you're at
Rank.NEXT = {
    [0] = { name = "Apprentice", up = 75 },  -- haven't learned fishing yet
    [75] = { name = "Journeyman", up = 150 },
    [150] = { name = "Expert", up = 225 },
    [225] = { name = "Artisan", up = 300, level = 35 },
}
-- fishing trainers, by faction (name, where)
Rank.TRAINERS = {
    Alliance = {
        { "Arnold Leland", "Stormwind City" }, { "Grimnur Stonebrand", "Ironforge" }, { "Astaia", "Darnassus" },
        { "Lee Brown", "Elwynn Forest" }, { "Paxton Ganter", "Dun Morogh" }, { "Androl Oakhand", "Teldrassil" },
        { "Warg Deepwater", "Loch Modan" }, { "Matthew Hooper", "Redridge Mountains" }, { "Harold Riggs", "Wetlands" },
        { "Donald Rabonne", "Hillsbrad Foothills" }, { "Brannock", "Feralas" },
    },
    Horde = {
        { "Lumak", "Orgrimmar" }, { "Kah Mistrunner", "Thunder Bluff" }, { "Armand Cromwell", "Undercity" },
        { "Lau'Tiki", "Durotar" }, { "Uthan Stillwater", "Mulgore" }, { "Clyde Kellen", "Tirisfal Glades" },
        { "Kil'Hiwana", "Ashenvale" }, { "Lui'Mala", "Desolace" }, { "Katoom the Angler", "The Hinterlands" },
    },
    Both = { { "Myizz Luckycatch", "Booty Bay" }, { "Fenn Fairweather", "Zephras Isle" }, { "Krix", "Riverglades" } },
}
-- where to fish while you climb the next rank
Rank.WHERE = {
    Apprentice = { Alliance = "any starting zone", Horde = "any starting zone" },
    Journeyman = { Alliance = "Stormwind City, Ironforge or Darnassus", Horde = "Orgrimmar or Thunder Bluff (Undercity's fish aren't worth much)" },
    Expert = { Alliance = "Dustwallow Marsh (or Stranglethorn Vale)", Horde = "Stranglethorn Vale (or Dustwallow Marsh)" },
    Artisan = { Alliance = "Tanaris", Horde = "Tanaris" },
}
-- Nat Pagle's four fish for Artisan (item, where)
Rank.PAGLE = {
    { 16967, "Feralas Ahi", "Feralas, southeast of Dire Maul" },
    { 16970, "Misty Reed Mahi Mahi", "Swamp of Sorrows, the eastern coast" },
    { 16968, "Sar'theris Striker", "Desolace, the western coast" },
    { 16969, "Savage Coast Blue Sailfin", "Stranglethorn Vale, the western coast" },
}

-- your fishing rank, cap and level of skill (nil if you haven't learned it)
function Rank.Skill()
    if not (GetProfessions and GetProfessionInfo) then return nil end
    local _, _, _, fishing = ns.Safe(GetProfessions)
    if not fishing then return nil end
    local ok, _, _, rank, max = pcall(GetProfessionInfo, fishing)
    if not ok or not rank then return nil end
    return rank, max
end

local hidden -- right-clicked away, this session (by cap)
-- for testing the banners: /ducky ranktest journeyman (and so on; nothing to stop)
local testing
local CAPS = { apprentice = 0, journeyman = 75, expert = 150, artisan = 225 }
function Rank.Test(which)
    testing = which and CAPS[which:lower()] or nil
    if which and not testing then
        ns.Chat("ranktest: apprentice, journeyman, expert or artisan (nothing to stop).")
        return
    end
    hidden = nil
    if testing then
        ns.Chat("showing the " .. which:lower() .. " banner. /ducky ranktest stops.")
        if ns.Log and not (ns.Log.Frame() and ns.Log.Frame():IsShown()) then ns.Log:Show() end
    else
        ns.Chat("rank banner test off.")
    end
    Rank.Update()
end

-- the rank you can learn right now, or nil
function Rank.Ready()
    if testing then return Rank.NEXT[testing], testing end
    if not (GetProfessions and GetProfessionInfo) then return nil end
    local rank, max = Rank.Skill()
    if not rank then rank, max = 0, 0 end -- no fishing yet: Apprentice
    if not max or rank < max then return nil end
    local nx = Rank.NEXT[max]
    if not nx then return nil end
    if nx.level and (UnitLevel("player") or 0) < nx.level then return nil end
    return nx, max
end

local function Faction() return (UnitFactionGroup and UnitFactionGroup("player")) or "Alliance" end
local function Caught(id)
    local db = _G.RubberDuckyJournalDB
    return db and db.items and db.items[id] ~= nil
end

-- the tooltip: what to do, where, and where to fish next
function Rank.Tooltip(owner)
    local nx = Rank.Ready()
    if not nx then return end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    GameTooltip:SetText(nx.name .. " Fishing")
    GameTooltip:AddLine(nx.name == "Apprentice" and "Learn fishing and every catch raises your skill."
        or "Your fishing skill is as high as it goes until you learn it. Catches won't raise it till then.", 1, 1, 1, true)
    GameTooltip:AddLine(" ")
    local f = Faction()
    if nx.name == "Apprentice" or nx.name == "Journeyman" then
        GameTooltip:AddLine("Visit a fishing trainer:", 1, 0.82, 0)
        local here = GetZoneText and GetZoneText()
        local list = {}
        for _, t in ipairs(Rank.TRAINERS[f] or {}) do list[#list + 1] = t end
        for _, t in ipairs(Rank.TRAINERS.Both) do list[#list + 1] = t end
        -- the one in this zone first
        table.sort(list, function(a, b) return (a[2] == here and 0 or 1) < (b[2] == here and 0 or 1) end)
        for i = 1, math.min(6, #list) do
            GameTooltip:AddDoubleLine(list[i][1], list[i][2], 1, 1, 1, 0.7, 0.7, 0.7)
        end
    elseif nx.name == "Expert" then
        GameTooltip:AddLine("Buy the book:", 1, 0.82, 0)
        GameTooltip:AddLine("Expert Fishing - The Bass and You, from Old Man Heming in Booty Bay (Stranglethorn Vale). Read it to learn.", 1, 1, 1, true)
    else
        GameTooltip:AddLine("A quest from Nat Pagle:", 1, 0.82, 0)
        GameTooltip:AddLine("Talk to Nat Pagle in Dustwallow Marsh for Nat Pagle, Angler Extreme. Catch these four:", 1, 1, 1, true)
        for _, p in ipairs(Rank.PAGLE) do
            local got = Caught(p[1])
            GameTooltip:AddDoubleLine((got and "|cff40c040+|r " or "   ") .. p[2], p[3], 1, 1, 1, 0.7, 0.7, 0.7)
        end
    end
    local where = Rank.WHERE[nx.name] and Rank.WHERE[nx.name][f]
    if where then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Then fish here to climb: " .. where .. ".", 0.6, 0.85, 1, true)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click to hide this until next time.", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end

local banner
local function Build(log)
    banner = CreateFrame("Button", "RubberDuckyRankBanner", log)
    banner:SetSize(400, 100)
    banner:SetPoint("TOP", log, "BOTTOM", 0, 22)
    banner:SetFrameLevel(log:GetFrameLevel() + 20)
    banner:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    banner.art = banner:CreateTexture(nil, "ARTWORK")
    banner.art:SetAllPoints()
    banner:SetScript("OnEnter", function(self) Rank.Tooltip(self) end)
    banner:SetScript("OnLeave", function() GameTooltip:Hide() end)
    banner:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            local _, max = Rank.Ready()
            hidden = max
            GameTooltip:Hide()
            self:Hide()
        end
    end)
    -- it pops in with a little bounce
    local g = banner:CreateAnimationGroup()
    local s1 = g:CreateAnimation("Scale"); s1:SetScaleFrom(0.5, 0.5); s1:SetScaleTo(1.06, 1.06); s1:SetDuration(0.16); s1:SetSmoothing("OUT"); s1:SetOrder(1)
    local a1 = g:CreateAnimation("Alpha"); a1:SetFromAlpha(0); a1:SetToAlpha(1); a1:SetDuration(0.12); a1:SetOrder(1)
    local s2 = g:CreateAnimation("Scale"); s2:SetScaleFrom(1.06, 1.06); s2:SetScaleTo(1, 1); s2:SetDuration(0.1); s2:SetOrder(2)
    banner.pop = g
    banner:Hide()
end

-- show or hide the banner under the log
function Rank.Update()
    local log = ns.Log and ns.Log.Frame and ns.Log.Frame()
    if not log then return end
    if not banner then Build(log) end
    local nx, max = Rank.Ready()
    local show = nx and ns.db.rankAlert ~= false and hidden ~= max
    if not show then banner:Hide() return end
    if banner.rank ~= nx.name then banner:Hide() end -- a different rank pops in fresh
    banner.art:SetTexture(ns.MEDIA .. "Log\\rank_" .. nx.name:lower())
    banner.rank = nx.name
    if not banner:IsShown() then
        banner:Show()
        banner.pop:Stop(); banner.pop:Play()
        -- the first time for this rank: a sound and a word from Ducky
        if testing then
            if ns.UI then ns.UI.Sound("challenge") end
        elseif (ns.db.rankSeen or -1) < max then
            ns.db.rankSeen = max
            if ns.UI then ns.UI.Sound("challenge") end
            ns.Chat(nx.name == "Apprentice" and "Quack! You haven't learned fishing yet. Hover the banner under your fishing log for where to learn it."
                or ("Quack! You've reached the top of your fishing skill. Time to learn " .. nx.name
                .. " Fishing! Hover the banner under your fishing log for where to go."))
        end
    end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("SKILL_LINES_CHANGED")
ev:RegisterEvent("PLAYER_LEVEL_UP")
ev:SetScript("OnEvent", function()
    if ns.db and ns.Log and ns.Log.Frame and ns.Log.Frame() and ns.Log.Frame():IsShown() then ns.Safe(Rank.Update) end
end)
