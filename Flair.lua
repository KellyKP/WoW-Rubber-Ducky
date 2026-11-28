-- Rubber Ducky: Fishing Flair. Shiny Fishbones, and the things they buy at
-- Mrrl's Doohicky Emporium: bobbers, quarterboards, charms and mottos.
--
-- Everything here is per character (RubberDuckyJournalDB.flair). Each item is
-- free, on Mrrl's shelf for a price, or earned from a challenge. Fishbones come
-- from catches now and then, and from every challenge you finish.

local _, ns = ...
local Flair = {}
ns.Flair = Flair

Flair.ICON = ns.MEDIA .. "Flair\\fishbone"
Flair.ICON_SMALL = ns.MEDIA .. "Flair\\fishbone_small"
Flair.ICON_GAME = ns.MEDIA .. "Flair\\fishbone_icon" -- square, like the game's item icons
Flair.KINDS = { "bobber", "board", "charm", "motto" }
Flair.TITLES = { bobber = "Bobbers", board = "Quarterboards", charm = "Charms", motto = "Mottos" }
Flair.SINGULAR = { bobber = "bobber", board = "quarterboard", charm = "charm", motto = "motto" }
Flair.DEFAULT = { board = "knotrope", charm = "fishbone", motto = "gonefishin" }

function Flair.BoardArt(key) return ns.MEDIA .. "Flair\\Boards\\" .. key end
function Flair.CharmArt(key) return ns.MEDIA .. "Flair\\Charms\\" .. key end

-- "|T…|t 25": a Fishbone and an amount, for any line of text
function Flair.Bones(n, size)
    size = size or 14
    return ("|T%s:%d:%d|t %s"):format(Flair.ICON_SMALL, size, size, BreakUpLargeNumbers and BreakUpLargeNumbers(n) or tostring(n))
end

-------------------------------------------------------------------------------
-- What each challenge pays: easy 10, medium 25, hard 50, the big collections 100
-------------------------------------------------------------------------------

local E, M, H, C = 10, 25, 50, 100
Flair.REWARD = {
    tour1 = E, tour2 = M, tour3 = H, shores = M, regular = M, homebody = H,
    fish1 = E, fish2 = M, fish3 = C, junk1 = E, junk2 = C, treasure1 = E, treasure2 = C,
    rainbow = E, hoarder = H, rum = M, locks = M, bloated = M,
    roll1 = E, roll2 = M, roll3 = H, lucky1 = M, lucky2 = H, patience = M, bounce = M,
    marathon1 = E, marathon2 = M, marathon3 = H, haul1 = E, haul2 = M, haul3 = H, jackpot = M, steady = M,
    litter = E, wrong = E, fishstory = M, bottle = M, diary = E,
    casts1 = E, casts2 = M, casts3 = H, early = E, night = M,
}

-------------------------------------------------------------------------------
-- The catalogue. { key, name, price } is on Mrrl's shelf; earn = a challenge
-- (or one of Mrrl's own: "mrrl1" your first purchase, "mrrl2" 2,000 spent);
-- neither is free.
-------------------------------------------------------------------------------

-- quarterboards. Every one is drawn to the same layout (512x256): the plank
-- for the words in the same place, and a rivet each side for the bobber and
-- the charm to hang from; whatever's on top is free to stick up.
Flair.BOARD = {
    foot = 0.19, -- of its height, below the plank (leaves and such)
    plank = { y = 178, w = 0.58, h = 55 }, -- the words: centre height (px of 256), room, plank height (px)
    rivets = { 66, 446, 176 }, -- left x, right x, y (px of 512x256)
}
-- py: where this board's plank sits (px of 256); rl/rr: its rivets, if not the usual
Flair.BOARDS = {
    -- simple and seaside
    { "knotrope", "Knotted Rope", py = 170, rl = 66, rr = 444 }, -- everyone's first board
    { "oldanchor", "Old Anchor", 40, py = 169 },
    { "rodandreel", "Rod & Reel", 40, py = 171 },
    { "fishnet", "Fishing Net", 40, py = 167 },
    { "baitbucket", "Bait Bucket", 40, py = 174 },
    { "awning", "Drying Line", 40, py = 172 },
    { "seashell", "Shells & Floats", 50, py = 172, rl = 67, rr = 445 },
    { "anchor", "Iron Anchor", 50, py = 180 },
    { "bloom", "Island Bloom", 50, py = 177 },
    { "lilypad", "Sunken Grove", 50, py = 176 },
    { "cattail", "Cattail Marsh", 50, py = 170 },
    { "tacklebox", "Tackle Box", 60, py = 174 },
    { "fishinghat", "Lucky Hat", 60, py = 175 },
    { "creel", "Wicker Creel", 60, py = 174 },
    { "fishbowl", "Fishbowl", 60, py = 175 },
    { "biglure", "Giant Lure", 60, py = 168 },
    { "driftwood", "Driftwood & Bottle", 60, py = 176 },
    { "lifering", "Life Ring", 60, py = 172 },
    { "wave", "Waterfall", 60, py = 176 },
    { "coral", "Coral Reef", 60, py = 180 },
    { "moonlit", "Moonlit Night", 60, py = 174 },
    { "ironbone", "Iron Fishbone", 60, py = 169 },
    { "twilight", "Twilight Vine", 60, py = 178 },
    { "fishinghut", "Fishing Hut", 70, py = 175 },
    { "frost", "Snow Leopard", 70, py = 172 },
    { "seagull", "Seagull", 70, py = 172 },
    { "glassfloats", "Glass Floats", 70, py = 180 },
    { "netcatch", "Catch of the Day", 70, py = 178, rl = 80, rr = 432 },
    { "sunstone", "Pirate's Gold", 80, py = 176 },
    -- places
    { "sunrise", "Sunrise", earn = "early", py = 177 },
    { "lanterns", "Lanterns & Moon", earn = "night", py = 175 },
    { "wheel", "Tall Ship", earn = "shores", py = 174 },
    { "lighthouse", "Lighthouse", 80, py = 174 },
    { "coastlight", "Coast Watch", 80, py = 172 },
    { "flowers", "Island Flowers", 100, py = 180 },
    { "autumn", "Autumn Leaves", 100, py = 170 },
    { "shroom", "Mossy Ruins", 100, py = 172 },
    { "seahorse", "Sunken Wreck", 100, py = 176 },
    { "desertbones", "Desert Bones", 100, py = 176 },
    { "tidepool", "Tidepool", 120, py = 186 },
    { "trollcamp", "Troll Camp", 120, py = 174 },
    { "jawbone", "Shark Jaw", 120, py = 176 },
    { "tidalroots", "Tidal Roots", 120, py = 182 },
    { "locks", "Locked Chest", earn = "locks", py = 174 },
    { "nightelf", "Moonglade", 120, py = 169 },
    { "desert", "Dunes", 120, py = 172 },
    { "glacier", "Glacier", 150, py = 180 },
    { "volcano", "Volcano", 150, py = 172 },
    { "isles", "Hidden Isles", 150, py = 166 },
    { "undead", "Plaguelands", 150, py = 171 },
    { "barrens", "Crossroads", 120, py = 168 },
    { "pawprint", "Bamboo Grove", 150, py = 169, rl = 68, rr = 441 },
    { "naga", "Drowned Temple", 150, py = 168 },
    { "exodar", "Crystal Hall", 150, py = 162 },
    { "tauren", "Mulgore", 150, py = 162, rl = 75, rr = 436 },
    { "wildwood", "Wildwood", 150, py = 173 },
    { "arcane", "Arcane Crystal", 200, py = 174 },
    { "darkiron", "Dark Iron", 200, py = 172 },
    { "alliance", "For the Alliance", 200, py = 169 },
    { "horde", "For the Horde", 200, py = 158, rl = 78, rr = 432 },
    -- critters
    { "turtle", "Turtle", 150, py = 170 },
    { "otter", "Otter", 150, py = 168 },
    { "crab", "Crab", 120, py = 177 },
    { "frog", "Frog", 120, py = 162 },
    { "wolf", "Wolf", 150, py = 177 },
    { "deer", "Stag", 150, py = 169 },
    { "moose", "Moose", 180, py = 172 },
    { "eagle", "Eagle", 180, py = 168 },
    { "bear", "Bear", 180, py = 169 },
    { "boar", "Boar", 150, py = 171 },
    { "panther", "Panther", 180, py = 174 },
    { "raptor", "Raptor", 180, py = 170 },
    { "spider", "Spider", 150, py = 163 },
    { "marshduck", "Marsh Duck", 100, py = 172 },
    { "duck", "Rubber Ducky", earn = "fish2", py = 174 },
    { "leapfish", "Leaping Fish", 150, py = 177 },
    -- Mrrl and friends
    { "murloc", "Mrrl", earn = "litter", py = 174 },
    { "mrrlcousin", "Mrrl's Cousin", 120, py = 170 },
    { "skeleton", "Fish Skeleton", earn = "patience", py = 174 },
    { "murlocnet", "Murloc Net", 100, py = 173 },
    { "murlocsign", "Mrrgl Sign", 100, py = 176 },
    { "rum", "Mrrl's Barrel", earn = "rum", py = 175 },
    { "murlocconch", "Conch & Claw", 120, py = 172 },
    { "bloated", "Slimy Bog", earn = "bloated", py = 177 },
    { "murlocbanner", "Murloc Banner", 120, py = 170 },
    { "murlocraid", "Murloc Raid", 150, py = 174 },
    { "murlocjaw", "Murloc Jaw", 150, py = 174 },
    { "murlochoard", "Murloc Hoard", 150, py = 170 },
    { "murlocbottle", "Bottled Glow", 150, py = 176 },
    { "spiralstone", "Spiral Stone", 100, py = 182 },
    { "murloclantern", "Lantern Light", 150, py = 181 },
    -- ducks
    { "explorerduck", "Explorer Duck", 150, py = 176 },
    { "pirateduck", "Pirate Duck", 180, py = 173 },
    { "sleepyduck", "Sleepy Duck", 150, py = 174 },
    { "bubbleduck", "Bubble Bath", 150, py = 175 },
    { "luckyduck", "Lucky Duck", 200, py = 176 },
    { "kingduck", "King Duck", 250, py = 174 },
    { "catchduck", "Duck & Catch", 150, py = 174 },
    { "nightduck", "Nightcap Duck", 150, py = 174 },
    { "summerduck", "Summer Duck", 150, py = 173 },
    { "autumnduck", "Autumn Duck", 150, py = 168 },
    { "winterduck", "Winter Duck", 150, py = 178 },
    { "loveduck", "Love Duck", 150, py = 175 },
    { "sailorduck", "Sailor Duck", 150, py = 166 },
    { "partyduck", "Party Duck", 200, py = 176 },
    -- earned in Ducky's Challenges
    { "map", "Treasure Map", earn = "tour2", py = 179 },
    { "trophy", "Trophy Cup", earn = "fishstory", py = 175 },
    { "goldstar", "Gold Star", earn = "roll2", py = 181 },
    { "crossedrods", "Crossed Rods", earn = "casts2", py = 184 },
    { "ledger", "Lantern & Ledger", earn = "diary", py = 181 },
    { "crown", "Golden Crown", earn = "homebody", py = 180, rl = 69, rr = 456 },
    { "goldenfish", "Golden Fish", earn = "jackpot", py = 187 },
    { "anglercrest", "Angler's Crest", earn = "regular", py = 184 },
    { "chest", "Overflowing Chest", earn = "lucky1", py = 180 },
    { "fishcards", "Fish Cards", earn = "fish1", py = 178 },
    { "globe", "Wide World", earn = "wrong", py = 180 },
    { "goldanchor", "Golden Anchor", earn = "marathon2", py = 182 },
    { "cookpot", "Campfire Stew", earn = "marathon1", py = 181, rl = 68, rr = 443 },
    { "orb", "Scrying Orb", earn = "rainbow", py = 176 },
    { "guildcrest", "Fishing Guild", 200, py = 174 },
}

-- a line about each, for Mrrl's shelf and tooltips
Flair.BOARD_LORE = {
    knotrope = "Every angler's first sign. Rope, posts and a lantern for the late ones.",
    oldanchor = "Rusted, roped and resting. It's done holding ships still.",
    rodandreel = "A spare rod, a red float and a reel that only clicks a little.",
    fishnet = "Mended so many times there's more patch than net.",
    baitbucket = "One worm got out. It's living its best life.",
    awning = "Today's catch, hung out to dry. The cats know exactly where it is.",
    seashell = "Glass floats and shells, washed up on the same lucky beach.",
    anchor = "Chain and all. Hauled up off the Booty Bay docks, mostly in one piece.",
    bloom = "A spiral stone and island flowers. Nobody remembers who carved it.",
    lilypad = "Old stumps standing in still water. The fish like the shade.",
    cattail = "Reeds, mud and murky water. Perfect.",
    tacklebox = "Lures, hooks and one sandwich of unknown age.",
    fishinghat = "Not the Lucky Fishing Hat. But it believes in itself.",
    creel = "Woven in Westfall. Smells like it, too.",
    fishbowl = "For the one you couldn't bring yourself to cook.",
    biglure = "Made for a fish nobody has ever seen. Yet.",
    driftwood = "Planks, moss and a bottle. The message inside is just 'hi'.",
    lifering = "Thrown to a gnome who fell off the Menethil pier. He kept it.",
    wave = "Falls water. Repeatedly.",
    coral = "A little bit of the reef, without the sharks.",
    moonlit = "A full moon over still water: the best time to fish, they say.",
    ironbone = "Bolted together with iron plates. A murloc is very proud of it.",
    twilight = "Glowing pools in twisted roots. Something in there is watching.",
    fishinghut = "Thatched roof, one window, no visitors. Bliss.",
    frost = "Found curled up on a Winterspring sign. It didn't move, so it's yours now.",
    seagull = "It wants your fish. It will always want your fish.",
    glassfloats = "A string of old net floats, still catching the light.",
    netcatch = "It's still a little cross about the whole thing.",
    sunstone = "Every pirate says they buried it. Nobody says where.",
    sunrise = "First light over the water, when the fish are hungriest and the angler sleepiest.",
    lanterns = "A lantern on the pier and the moon on the water. Night fishing at its best.",
    wheel = "A tall ship sailing past three shores. It never stops to fish.",
    lighthouse = "Keeps ships off the rocks and anglers up all night.",
    coastlight = "A little lighthouse on a little rock in a big sea.",
    flowers = "Hibiscus, sand and a quiet cove off Zephras Isle.",
    autumn = "Elwynn in autumn: crisp leaves, cold water, warm cider.",
    shroom = "Old stone, older moss. The fish here are very old too.",
    seahorse = "What's left of a ship nobody can name, under bubbles that never stop.",
    desertbones = "Tanaris has no fish. This sign has never understood why.",
    tidepool = "Shells, coral and whatever the tide forgot.",
    trollcamp = "Tents, tusks and drums at night. Bring snacks.",
    jawbone = "The shark wasn't using it any more.",
    tidalroots = "Old roots curled round a hidden pool. Things glow at night.",
    locks = "Locked tight, rope-bound and very heavy. The key is somewhere in a fish.",
    nightelf = "Silver moon, violet banners and a quiet lake under the trees.",
    desert = "Sand, sun and a cactus that has seen things.",
    glacier = "Carved out of a Dun Morogh mountainside. Still cold to the touch.",
    volcano = "Fishing in the Burning Steppes. Bold.",
    isles = "Green peaks over blue water, somewhere south of Stranglethorn.",
    undead = "Bones, green fire and a skull that smiles a little too much.",
    barrens = "Dust, banners and a long walk to any water.",
    pawprint = "A paw print, a pagoda and the smell of tea.",
    naga = "Carved stone that used to be dry. The naga liked it better this way.",
    exodar = "Violet crystals that hum a note only fish can hear.",
    tauren = "Horns, feathers and fur. Thunder Bluff's finest.",
    wildwood = "A spiral stone in a mossy wood. Druids leave it alone.",
    arcane = "Hums faintly. Dalaran swears it isn't theirs either.",
    darkiron = "Black iron and burning lanterns from deep under Blackrock.",
    alliance = "Stormwind blue, with a lion on top. Very proper.",
    horde = "Red banners, spikes and a lot of shouting.",
    turtle = "Slow, steady and absolutely not moving off your sign.",
    otter = "Here for the fish. Stays for the belly rubs.",
    crab = "Snippy. Very snippy.",
    frog = "Sits on lily pads and judges your casting.",
    wolf = "A grey wolf from Alterac. Only howls at really big catches.",
    deer = "Came down to the water to drink and decided to stay.",
    moose = "Big, brown and unbothered.",
    eagle = "Steals fish from bears. Respect.",
    bear = "Paws on the plank, berries on the side, eye on your catch.",
    boar = "Durotar's finest. Smells like it too.",
    panther = "A night elf's companion that wandered off with a crescent moon.",
    raptor = "Clever girl. Loves fish.",
    spider = "Duskwood's friendliest spider. That's not saying much.",
    marshduck = "A duck in a hat among the cattails. Ducky's cousin, probably.",
    duck = "Ducky's own sign, cattails and all. Only for anglers who really know their fish.",
    leapfish = "Caught mid-jump and polished up in gold. Showing off.",
    murloc = "Mrrl himself, hat and all. He insists on being on the sign.",
    mrrlcousin = "Same hat, same grin. Mrrl says they're not related.",
    skeleton = "What's left after a very patient fisherman's very long wait.",
    murlocnet = "Mrrl caught a net. Then he caught himself in it.",
    murlocsign = "A sign in Murloc. It says 'Mrrgl'. That's all it says.",
    rum = "Mrrl's barrel of 'medicine'. Don't ask what's in it.",
    murlocconch = "A shell to listen to and a murloc who won't stop waving.",
    bloated = "Something in this bog smells fishy. It's the fish.",
    murlocbanner = "A sun banner, a lantern and a murloc who stole both.",
    murlocraid = "Spears up, banner flying. They're mostly after your bait.",
    murlocjaw = "He's sitting in the shark's mouth on purpose. Don't ask.",
    murlochoard = "Coins, bottles and shiny bits. Mrrl's rainy-day fund.",
    murlocbottle = "Something glows in the bottle. The murloc won't let go of it.",
    spiralstone = "An old stone the murlocs sing to on full moons.",
    murloclantern = "A murloc, a lantern and a fishbone. Grand evening out.",
    explorerduck = "Map, compass, goggles. Lost anyway.",
    pirateduck = "Arr. Quack. Mostly quack.",
    sleepyduck = "Fell asleep waiting for a bite. Still waiting.",
    bubbleduck = "Rubber duck, meet bath. Bath, rubber duck.",
    luckyduck = "Horseshoe, clover and a hat. Fish just jump in.",
    kingduck = "Crown, shades and a velvet throne. Bow to the duck.",
    catchduck = "Caught a fish nearly its own size. Very pleased.",
    nightduck = "Moon up, cap on, snoring softly.",
    summerduck = "Shades on, surf up.",
    autumnduck = "Scarf on, leaves falling, cider somewhere.",
    winterduck = "Knitted hat, snowy pines, cold feet.",
    loveduck = "Heart shades and pink flowers. It's in love with fishing.",
    sailorduck = "Ship-shape and ready to swab.",
    partyduck = "Balloons, confetti and a very small hat.",
    map = "An old map and a compass. X marks every fishing spot in Azeroth.",
    trophy = "For the one that didn't get away. Fifty pounds of proof.",
    goldstar = "Gold star for not missing. Ducky's very proud of you.",
    crossedrods = "Two rods crossed over a golden fish. Five thousand casts will do that.",
    ledger = "A lantern, a quill and somebody's diary. Fished up, page by page.",
    crown = "Five hundred catches in one spot. You're the ruler of that pond now.",
    goldenfish = "A rare fish and treasure in the same session. Shining.",
    anglercrest = "The crest of an angler who keeps coming back to the same water.",
    chest = "Treasure twice in a row. The chest can't even close.",
    fishcards = "Your first ten fish, drawn on cards. Collect them all.",
    globe = "A fish where it shouldn't be means a world bigger than you thought.",
    goldanchor = "Two hours in one sitting. You've dropped anchor for good.",
    cookpot = "An hour of fishing deserves a pot of stew by the fire.",
    orb = "Grey, white, green and blue. The orb has seen every colour you've caught.",
    guildcrest = "The Fishing Guild's own crest. Membership is just loving fish.",
}

Flair.CHARMS = {
    { "fishbone", "Shiny Fishbone" },
    { "duck", "Rubber Duck" },
    { "bobber", "Classic Bobber" },
    { "boot", "Old Boot", earn = "junk1" },
    { "chest", "Treasure Chest", earn = "treasure1" },
    { "bottle", "Message in a Bottle", earn = "bottle" },
    { "compass", "Compass", earn = "tour1" },
    { "sardines", "Sardines", earn = "haul2" },
    { "lobster", "Lobster", earn = "hoarder" },
    { "moon", "Crescent Moon", earn = "bounce" },
    { "frog", "Frog", 30 }, { "fish", "Fish", 25 }, { "starfish", "Starfish", 25 },
    { "seashell", "Seashell", 25 }, { "anchor", "Anchor", 30 }, { "wheel", "Ship's Wheel", 40 },
    { "crab", "Crab", 30 }, { "jellyfish", "Jellyfish", 50 }, { "lantern", "Lantern", 40 },
    { "sailboat", "Sailboat", 40 }, { "seaweed", "Seaweed", 25 }, { "hook", "Fishhook", 25 },
    { "feathers", "Feathers", 35 }, { "sanddollar", "Sand Dollar", 30 }, { "conch", "Conch", 30 },
    { "turtle", "Turtle", 40 }, { "mallard", "Mallard", 40 }, { "puffer", "Pufferfish", 45 },
    { "purplestar", "Purple Star", 50 }, { "orb", "Glowing Orb", 60 },
}

-- the line under your name on your quarterboard
Flair.MOTTOS = {
    { "gonefishin", "Gone Fishin'" },
    { "pondpal", "Pond Pal" },
    { "angler", "Master Angler", earn = "fish3" },
    { "whatsits", "Collector of Whatsits", earn = "junk2" },
    { "treasure", "Treasure Hunter", earn = "treasure2" },
    { "globe", "Globetrotter", earn = "tour3" },
    { "whisperer", "Fish Whisperer", earn = "roll3" },
    { "luckyduck", "Lucky Duck", earn = "lucky2" },
    { "reelpro", "Reel Professional", earn = "haul3" },
    { "onemore", "Just One More Cast...", earn = "marathon3" },
    { "botherer", "Certified Fish Botherer", earn = "casts3" },
    { "saint", "Patience of a Saint", earn = "patience" },
    { "nibble", "Waiting on a Nibble...", earn = "night" },
    { "friend", "Friend of Mrrl", earn = "mrrl1" },
    { "customer", "Mrrl's Best Customer", earn = "mrrl2" },
    { "mrrgl", "Mrrgl Mrrgl!", 100 },
    { "scare", "Don't Scare the Fish", 75 },
    { "herefor", "Here for the Fish", 75 },
    { "probably", "Probably Fishing", 75 },
    { "reelin", "Reelin' & Relaxin'", 75 },
    { "niceday", "Nice Day For Fishin'", 150 },
}

-- Mrrl's own: not challenges, but earned all the same
Flair.MRRL = {
    mrrl1 = { name = "Friend of Mrrl", goal = "Buy anything from Mrrl." },
    mrrl2 = { name = "Mrrl's Best Customer", goal = "Spend 2,000 Shiny Fishbones at Mrrl's." },
}

-- every item as one shape: { kind, key, name, price, earn, index (bobbers), art }
local items, byKey = {}, {}
local function Build()
    if items.bobber then return end
    for _, kind in ipairs(Flair.KINDS) do items[kind], byKey[kind] = {}, {} end
    local function Add(kind, it)
        items[kind][#items[kind] + 1] = it
        byKey[kind][it.key] = it
    end
    for i, m in ipairs(ns.Bobber and ns.Bobber.MARKERS or {}) do
        Add("bobber", { kind = "bobber", key = m[1], name = m[2], price = m.price, earn = m.earn, index = i,
            art = ns.BobberArt(m[1]), lore = ns.Bobber.LORE and ns.Bobber.LORE[m[1]] })
    end
    for _, b in ipairs(Flair.BOARDS) do
        local L = Flair.BOARD
        Add("board", { kind = "board", key = b[1], name = b[2], price = b[3], earn = b.earn,
            w = 512, h = 256, foot = L.foot, art = Flair.BoardArt(b[1]), lore = Flair.BOARD_LORE[b[1]],
            py = b.py or L.plank.y, rl = b.rl or L.rivets[1], rr = b.rr or L.rivets[2] })
    end
    for _, c in ipairs(Flair.CHARMS) do
        Add("charm", { kind = "charm", key = c[1], name = c[2], price = c[3], earn = c.earn, art = Flair.CharmArt(c[1]) })
    end
    for _, t in ipairs(Flair.MOTTOS) do
        Add("motto", { kind = "motto", key = t[1], name = t[2], price = t[3], earn = t.earn })
    end
end

function Flair.Get(kind, key) Build(); return byKey[kind] and byKey[kind][key] end

-- the challenge (or Mrrl's goal) that earns an item: { name, goal, hidden }
function Flair.Earner(id)
    if Flair.MRRL[id] then return Flair.MRRL[id] end
    for _, d in ipairs(ns.Challenges and ns.Challenges.DEFS or {}) do
        if d.id == id then return d end
    end
end

-------------------------------------------------------------------------------
-- The save
-------------------------------------------------------------------------------

function Flair.Saved()
    local j = ns.Journal and ns.Journal.DB and ns.Journal.DB()
    if not j then return { bones = 0, earned = 0, spent = 0, bought = 0, paid = {}, owned = {}, wear = {} } end
    local f = j.flair
    if not f then
        f = { bones = 0, earned = 0, spent = 0, bought = 0, paid = {}, owned = {}, wear = {} }
        j.flair = f
    end
    f.paid, f.owned, f.wear = f.paid or {}, f.owned or {}, f.wear or {}
    for _, kind in ipairs(Flair.KINDS) do f.owned[kind] = f.owned[kind] or {} end
    return f
end

function Flair.Balance() return Flair.Saved().bones or 0 end

local function ChallengeDone(id)
    if id == "mrrl1" then return (Flair.Saved().bought or 0) >= 1 end
    if id == "mrrl2" then return (Flair.Saved().spent or 0) >= 2000 end
    local CH = ns.Challenges
    local ok, saved = pcall(function() return CH and CH.Saved and CH.Saved() end)
    return ok and saved and (saved.done or {})[id] ~= nil or false
end

-- yours: free, bought, or earned
function Flair.Owns(it)
    if not it then return false end
    if not it.price and not it.earn then return true end
    local f = Flair.Saved()
    if f.owned[it.kind][it.key] then return true end
    if it.earn then return ChallengeDone(it.earn) end
    return false
end

function Flair.Status(it)
    if Flair.Owns(it) then return "owned" end
    if it.price then return Flair.Balance() >= it.price and "buy" or "short" end
    return "locked"
end

-- the one you're wearing, or the default if that's no longer yours
function Flair.Worn(kind)
    Build()
    if kind == "bobber" then
        local i = ns.db and ns.db.markerStyle or 15
        local m = ns.Bobber and ns.Bobber.MARKERS[i]
        return m and byKey.bobber[m[1]] or nil
    end
    local it = byKey[kind][Flair.Saved().wear[kind] or Flair.DEFAULT[kind]]
    if not it or not Flair.Owns(it) then it = byKey[kind][Flair.DEFAULT[kind]] end
    return it
end

function Flair.IsWorn(it)
    if it.kind == "bobber" then return ns.db and ns.db.markerStyle == it.index end
    return Flair.Worn(it.kind) == it
end

function Flair.Equip(it)
    if not Flair.Owns(it) then return false end
    if it.kind == "bobber" then
        ns.db.markerStyle = it.index
        ns.db.markerEnabled = true -- picking a bobber means you want to see it
        if ns.Bobber and ns.Bobber.RefreshMarker then ns.Bobber:RefreshMarker() end
        if ns.Options and ns.Options.RefreshOverview then ns.Options.RefreshOverview() end
        if ns.Picker and ns.Picker.Refresh then ns.Picker:Refresh() end
    else
        Flair.Saved().wear[it.kind] = it.key
        Flair.Changed() -- previews, your board on the log, and everyone nearby
    end
    return true
end

-- buy it from Mrrl and put it on. Returns true, or nil and why not.
function Flair.Buy(it)
    if not it or not it.price then return nil, "not for sale" end
    if Flair.Owns(it) then return nil, "owned" end
    local f = Flair.Saved()
    if (f.bones or 0) < it.price then return nil, "short" end
    local wasFriend, wasBest = ChallengeDone("mrrl1"), ChallengeDone("mrrl2")
    f.bones = f.bones - it.price
    f.spent = (f.spent or 0) + it.price
    f.bought = (f.bought or 0) + 1
    f.owned[it.kind][it.key] = true
    Flair.Equip(it)
    -- Mrrl's thank-yous: a motto each
    local CH = ns.Challenges
    if CH and CH.Toast and not (ns.db and ns.db.challengeToasts == false) then
        if not wasFriend and ChallengeDone("mrrl1") then
            CH:Toast({ name = "Friend of Mrrl", header = "MRRL SAYS THANKS  ·  NEW MOTTO!", flair = true })
        end
        if not wasBest and ChallengeDone("mrrl2") then
            CH:Toast({ name = "Mrrl's Best Customer", header = "MRRL SAYS THANKS  ·  NEW MOTTO!", flair = true })
        end
    end
    Flair.Changed()
    return true
end

local listeners = {}
function Flair.OnChange(fn) listeners[#listeners + 1] = fn end
function Flair.Changed()
    for _, fn in ipairs(listeners) do pcall(fn) end
end

function Flair.Add(n)
    if not n or n <= 0 then return end
    local f = Flair.Saved()
    f.bones = (f.bones or 0) + n
    f.earned = (f.earned or 0) + n
    Flair.Changed()
end

-------------------------------------------------------------------------------
-- Earning
-------------------------------------------------------------------------------

-- What a catch is worth: junk sometimes, commons now and then, more often the
-- better it is; epics and treasure always.
-- q: the best quality in the catch; treasure: the catch had treasure in it
-- boost: Fishbone luck right now (Flair.Luck), 1 = normal
function Flair.Roll(q, treasure, rnd, boost)
    rnd = rnd or math.random
    boost = boost or 1
    q = q or 1
    if treasure or q >= 4 then return rnd(2, 5) end
    if q == 3 then
        if rnd() < math.min(1, 0.6 * boost) then return rnd() < 1 / 3 and 2 or 1 end
        return 0
    end
    local chance = q == 2 and 0.25 or q == 1 and 0.10 or 0.05
    return rnd() < math.min(1, chance * boost) and 1 or 0
end

-------------------------------------------------------------------------------
-- Fishbone luck: like the game's own fishing boosts, some things make
-- Fishbones turn up more often. They stack, up to 3x.
-------------------------------------------------------------------------------

-- buffs on you, by (part of) their name, or their spell ID
Flair.LUCK_BUFFS = {
    { "Fishing Rack", 1.5 },   -- camping: better uncommon fish for an hour
    { "Fishing Hut", 2 },      -- camping: better rare fish for an hour
}
-- things you're wearing, by item ID
Flair.LUCK_GEAR = {
    [19972] = { "Lucky Fishing Hat", 1.25 },
}
local STV = { [1434] = true }   -- Stranglethorn Vale

local function Buffs()
    local out = {}
    for i = 1, 40 do
        local name, id
        if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
            local a = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
            if not a then break end
            name, id = a.name, a.spellId
        elseif UnitBuff then
            local n, _, _, _, _, _, _, _, _, sid = UnitBuff("player", i)
            if not n then break end
            name, id = n, sid
        else break end
        out[#out + 1] = { name = name, id = id }
    end
    return out
end

-- Stranglethorn's Fishing Extravaganza: Sundays, 2 to 4 in the afternoon,
-- server time, in Stranglethorn
local function Extravaganza()
    local t = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and ns.Safe(C_DateAndTime.GetCurrentCalendarTime)
    if not t or t.weekday ~= 1 then return false end -- 1 = Sunday
    if (t.hour or 0) < 14 or (t.hour or 0) >= 16 then return false end
    local map = C_Map and C_Map.GetBestMapForUnit and ns.Safe(C_Map.GetBestMapForUnit, "player")
    return map and STV[map] or false
end

-- how lucky you are right now, and why: 1.5, { "Fishing Rack" }
function Flair.Luck()
    local mult, why = 1, {}
    local ok, buffs = pcall(Buffs)
    for _, b in ipairs(ok and buffs or {}) do
        for _, l in ipairs(Flair.LUCK_BUFFS) do
            local match = (type(l[1]) == "number" and b.id == l[1]) or
                (type(l[1]) == "string" and b.name and b.name:find(l[1], 1, true))
            if match then mult = mult * l[2]; why[#why + 1] = b.name end
        end
    end
    for slot = 1, 19 do
        local id = GetInventoryItemID and ns.Safe(GetInventoryItemID, "player", slot)
        local g = id and Flair.LUCK_GEAR[id]
        if g then mult = mult * g[2]; why[#why + 1] = g[1] end
    end
    if Extravaganza() then mult = mult * 1.5; why[#why + 1] = "Fishing Extravaganza" end
    -- fishing together: +10% for each other Rubber Ducky angler in your zone,
    -- up to double with ten
    local buddies = ns.Social and ns.Social.Buddies and ns.Social.Buddies() or 0
    if buddies > 0 then
        mult = mult * math.min(2, 1 + 0.1 * buddies)
        why[#why + 1] = buddies == 1 and "fishing with a Fellow Ducky Angler" or ("fishing with " .. buddies .. " Fellow Ducky Anglers")
    end
    return math.min(3, mult), why
end

-- once per cast, from the journal. Remembers it for the catch popup.
Flair.last = nil
function Flair.Catch(q, treasure)
    local n = Flair.Roll(q, treasure, nil, (Flair.Luck()))
    Flair.last = { cast = ns.castStart, n = n }
    if n > 0 then
        Flair.Add(n)
        Flair.LootLine(n)
    end
    return n
end

-- What a Shiny Fishbone is, for a tooltip: the fishing log's line and the
-- link in chat both show this
function Flair.Tooltip(owner, anchor)
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
    GameTooltip:SetText("Shiny Fishbones")
    GameTooltip:AddLine("Mrrl trades flair for these at his Doohicky Emporium.", 1, 1, 1, true)
    GameTooltip:AddLine("You have " .. Flair.Bones(Flair.Balance()) .. ".", 1, 0.82, 0)
    local luck, why = Flair.Luck()
    if luck > 1 then
        GameTooltip:AddLine(("Lucky right now: %sx as many (%s)"):format(
            (("%.2f"):format(luck):gsub("0+$", ""):gsub("%.$", "")), table.concat(why, ", ")), 0.4, 1, 0.4, true)
    end
    GameTooltip:AddLine("Click to visit Mrrl.", 0.4, 0.8, 1)
    GameTooltip:Show()
end

-- While you're lucky, a little buff-style icon sits beside the fishing log:
-- the Fishbone, with how lucky ("x1.5"); hover it for why
function Flair.LuckIcon()
    local log = _G.RubberDuckyLog
    if not log then return end
    local b = Flair.luckIcon
    if not b then
        -- sits in the log's framed box, filling it right up to the wood
        b = CreateFrame("Button", nil, log)
        b:SetSize(34, 34)
        b.icon = b:CreateTexture(nil, "ARTWORK")
        b.icon:SetAllPoints()
        b.icon:SetTexture(Flair.ICON_GAME)
        b.icon:SetTexCoord(0.08, 0.92, 0.095, 0.905) -- the box is a touch wider than tall
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints(); hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square"); hl:SetBlendMode("ADD")
        b.text = b:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        b.text:SetPoint("BOTTOMRIGHT", -2, 3)
        b:SetScript("OnEnter", function(self) Flair.Tooltip(self, "ANCHOR_RIGHT") end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:SetScript("OnClick", function() if ns.Shop then ns.Shop:Show() end end)
        b.t = 0
        b:SetScript("OnUpdate", function(self, el)
            self.t = self.t + el
            if self.t < 2 then return end
            self.t = 0
            Flair.LuckIcon()
        end)
        Flair.luckIcon = b
    end
    local luck = Flair.Luck()
    local on = luck > 1
    if not (ns.Log and ns.Log.LuckSlot and ns.Log.LuckSlot(b, on)) then
        b:ClearAllPoints(); b:SetPoint("TOPLEFT", log, "TOPRIGHT", -4, -96)
    end
    if on then
        b.text:SetText("x" .. (("%.2f"):format(luck):gsub("0+$", ""):gsub("%.$", "")))
        b.icon:SetAlpha(1); b.text:Show()
        b:EnableMouse(true)
    else
        -- keep checking, quietly: nothing shows until luck turns up
        b.icon:SetAlpha(0); b.text:Hide()
        b:EnableMouse(false)
    end
    b:Show()
end

-- The chat link (see ns.Link in Core): clicking it visits Mrrl's.
Flair.LINK = "rubberducky:bones"
Flair.linkable = ns.linkable
ns.LINK_OPEN.bones = function() if ns.Shop then ns.Shop:Show() end end
-- hovering one in any chat window says what it does
function Flair.HookChat()
    if Flair.chatHooked or not Flair.linkable then return end
    Flair.chatHooked = true
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local cf = _G["ChatFrame" .. i]
        if cf and cf.HookScript then
            cf:HookScript("OnHyperlinkEnter", function(self, link)
                if link == Flair.LINK then Flair.Tooltip(self, "ANCHOR_CURSOR")
                elseif link == "rubberducky:settings" or link == "rubberducky:whatsnew" then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:SetText("Rubber Ducky")
                    GameTooltip:AddLine(link == "rubberducky:settings" and "Click to open the settings."
                        or "Click to see what's new in this update.", 1, 1, 1, true)
                    GameTooltip:Show()
                end
            end)
            cf:HookScript("OnHyperlinkLeave", function() GameTooltip:Hide() end)
        end
    end
end

-- A line in chat with the rest of your loot, the game's way, so you hear about
-- it even if you loot by hand without the splash:
-- "You receive currency: [Shiny Fishbone] x2."
function Flair.LootLine(n)
    local cf = DEFAULT_CHAT_FRAME
    if not (cf and cf.AddMessage) then return end
    local label = "[" .. (n > 1 and "Shiny Fishbones" or "Shiny Fishbone") .. "]"
    -- a link like the game's own loot: hover it for what it is, click to visit Mrrl
    local name = Flair.linkable and ("|cffe6cc80|H" .. Flair.LINK .. "|h" .. label .. "|h|r") or ("|cffe6cc80" .. label .. "|r")
    local text
    if n > 1 then
        text = (CURRENCY_GAINED_MULTIPLE or "You receive currency: %s x%d."):format(name, n)
    else
        text = (CURRENCY_GAINED or "You receive currency: %s."):format(name)
    end
    local c = ChatTypeInfo and ChatTypeInfo.CURRENCY or ChatTypeInfo and ChatTypeInfo.LOOT
    cf:AddMessage(text, c and c.r or 0, c and c.g or 0.667, c and c.b or 0)
end
-- what this cast found, for the popup and the log
function Flair.ThisCast()
    local l = Flair.last
    if l and l.cast == ns.castStart and l.n > 0 then return l.n end
end

-- the items a challenge earns
function Flair.Prizes(id)
    Build()
    local out = {}
    for _, kind in ipairs(Flair.KINDS) do
        for _, it in ipairs(items[kind]) do
            if it.earn == id then out[#out + 1] = it end
        end
    end
    return out
end

-- Pays every finished challenge not paid for yet. Returns the total and how
-- many. The first time, that's a back payment for challenges already done.
function Flair.Settle()
    local CH = ns.Challenges
    if not (CH and CH.Saved) then return 0, 0 end
    local done = CH.Saved().done or {}
    local f = Flair.Saved()
    local total, n = 0, 0
    for id in pairs(done) do
        if not f.paid[id] then
            f.paid[id] = true
            local r = Flair.REWARD[id] or 0
            total, n = total + r, n + 1
        end
    end
    if total > 0 then Flair.Add(total) end
    return total, n
end

-------------------------------------------------------------------------------
-- Lists for the shop: Mrrl's shelf first, cheapest first; then earned; then free
-------------------------------------------------------------------------------

function Flair.Items(kind)
    Build()
    local shelf, earned, free = {}, {}, {}
    for _, it in ipairs(items[kind]) do
        if it.price then shelf[#shelf + 1] = it
        elseif it.earn then earned[#earned + 1] = it
        else free[#free + 1] = it end
    end
    table.sort(shelf, function(a, b)
        if a.price ~= b.price then return a.price < b.price end
        return a.name < b.name
    end)
    local out = {}
    for _, l in ipairs({ shelf, earned, free }) do for _, it in ipairs(l) do out[#out + 1] = it end end
    return out
end

-- start over (Developer page): no Fishbones, nothing bought, the free loadout.
-- Challenges already done pay out again at the next check.
function Flair.Reset()
    local j = ns.Journal and ns.Journal.DB and ns.Journal.DB()
    if not j then return end
    j.flair = { bones = 0, earned = 0, spent = 0, bought = 0, paid = {}, owned = {}, wear = {}, kept = true }
    Flair.Saved()
    if ns.db and ns.Bobber then
        local m = ns.Bobber.MARKERS[ns.db.markerStyle or 15]
        if m and (m.price or m.earn) then ns.db.markerStyle = 15 end -- back to the duck
    end
    Flair.Changed()
end

-- At login, once per character: a bobber you're already using that's now on
-- Mrrl's shelf, or earned, stays yours.
function Flair.Keep()
    local f = Flair.Saved()
    if f.kept then return end
    f.kept = true
    local it = Flair.Worn("bobber")
    if it and (it.price or it.earn) then f.owned.bobber[it.key] = true end
end
