-- Rubber Ducky: fixed data for the fishing journal: every fish, everything
-- else that comes up on the line, the zones, and Ducky's lines. Most of it is
-- from Wowhead's Forever data (see the notes on each table).

local _, ns = ...
local Data = {}
ns.JournalData = Data

-- Every fish in WoW Forever 1.60.1, for the collection. zones: where it bites, most first
-- (share of catches logged on Wowhead Forever, Nov 17 2026; zones under ~0.5% left out).
Data.FISH = {
    [6291] = { zones = { "Elwynn Forest", "Dun Morogh", "Mulgore", "Zephras Isle", "Tirisfal Glades", "Teldrassil" } }, -- Raw Brilliant Smallfish
    [6303] = { zones = { "Durotar", "Teldrassil", "The Barrens", "Darkshore", "Westfall", "Silverpine Forest" } }, -- Raw Slitherskin Mackerel
    [6289] = { zones = { "Ironforge", "Thunder Bluff", "Orgrimmar", "Darnassus", "Stormwind City", "Undercity" } }, -- Raw Longjaw Mud Snapper
    [6317] = { zones = { "Loch Modan" } }, -- Raw Loch Frenzy
    [6361] = { zones = { "Wetlands", "The Barrens", "Darkshore", "Westfall", "Ashenvale", "Hillsbrad Foothills" } }, -- Raw Rainbow Fin Albacore
    [21071] = { zones = { "Hillsbrad Foothills", "Loch Modan", "Stonetalon Mountains", "Silverpine Forest", "Ashenvale" } }, -- Raw Sagefish
    [6308] = { zones = { "Duskwood", "Redridge Mountains", "Shen'dralas", "Stonetalon Mountains", "Ashenvale", "Thousand Needles" } }, -- Raw Bristle Whisker Catfish
    [6522] = { zones = { "The Barrens" } }, -- Deviate Fish
    [6299] = { zones = { "Undercity", "Tirisfal Glades", "Silverpine Forest" } }, -- Sickly Looking Fish
    [12238] = { zones = { "Darkshore" } }, -- Darkshore Grouper
    [6358] = { zones = { "Westfall", "Wetlands", "The Barrens", "Riverglades", "Stranglethorn Vale", "Darkshore" } }, -- Oily Blackmouth
    [6359] = { zones = { "Wetlands", "Stranglethorn Vale", "Tanaris", "Riverglades", "Dustwallow Marsh", "Stonetalon Mountains" } }, -- Firefin Snapper
    [6362] = { zones = { "Swamp of Sorrows", "Stranglethorn Vale", "Dustwallow Marsh", "Riverglades", "Azshara", "Desolace" } }, -- Raw Rockscale Cod
    [8365] = { zones = { "Thousand Needles", "Arathi Highlands", "Shen'dralas", "Desolace", "Alterac Mountains", "Dustwallow Marsh" } }, -- Raw Mithril Head Trout
    [21153] = { zones = { "Alterac Mountains", "Riverglades", "Stranglethorn Vale" } }, -- Raw Greater Sagefish
    [4603] = { zones = { "Azshara", "Tanaris", "Swamp of Sorrows", "The Hinterlands", "Stranglethorn Vale", "Dustwallow Marsh" } }, -- Raw Spotted Yellowtail
    [13422] = { zones = { "Azshara", "Tanaris", "Riverglades", "The Hinterlands", "Feralas", "Stranglethorn Vale" } }, -- Stonescale Eel
    [13754] = { zones = { "Azshara", "Tanaris", "The Hinterlands", "Feralas" } }, -- Raw Glossy Mightfish
    [13755] = { zones = { "Tanaris", "Azshara", "The Hinterlands", "Feralas" } }, -- Raw Winter Squid
    [13757] = { zones = { "Eastern Plaguelands", "Mount Hyjal", "The Hinterlands", "Western Plaguelands", "Moonglade", "Feralas" } }, -- Lightning Eel
    [13758] = { zones = { "Moonglade", "Feralas", "Western Plaguelands", "The Hinterlands", "Azshara", "Mount Hyjal" } }, -- Raw Redgill
    [13759] = { zones = { "Deadwind Pass", "Moonglade", "Mount Hyjal", "Feralas", "Western Plaguelands", "Azshara" } }, -- Raw Nightfin Snapper
    [13760] = { zones = { "Eastern Plaguelands", "Western Plaguelands", "Mount Hyjal", "The Hinterlands", "Feralas", "Moonglade" } }, -- Raw Sunscale Salmon
    [13888] = { zones = { "Azshara" } }, -- Darkclaw Lobster
    [13889] = { zones = { "Eastern Plaguelands", "Mount Hyjal", "Deadwind Pass" } }, -- Raw Whitescale Salmon
    [13893] = { zones = { "Azshara" } }, -- Large Raw Mightfish
    [13890] = { zones = { "Deadwind Pass", "Mount Hyjal", "Eastern Plaguelands" } }, -- Raw Plated Armorfish
    [251524] = { zones = { "Redridge Mountains" } }, -- Whimsyfin
    [16967] = { zones = { "Feralas" } }, -- Feralas Ahi
    [16968] = { zones = { "Desolace" } }, -- Sar'theris Striker
    [16969] = { zones = { "Stranglethorn Vale" } }, -- Savage Coast Blue Sailfin
    [16970] = { zones = { "Swamp of Sorrows" } }, -- Misty Reed Mahi Mahi
    [19803] = { zones = { "Stranglethorn Vale" } }, -- Brownell's Blue Striped Racer
    [19805] = { zones = { "Stranglethorn Vale" } }, -- Keefer's Angelfish
    [19806] = { zones = { "Stranglethorn Vale" } }, -- Dezian Queenfish
    [19807] = { zones = { "Stranglethorn Vale" } }, -- Speckled Tastyfish
    [13756] = { zones = { "Tanaris", "Azshara", "The Hinterlands", "Feralas" } }, -- Raw Summer Bass (seasonal; ID from Classic, not logged yet)

    -- Bloated fish: open them for what they swallowed
    [6643] = { zones = { "Zephras Isle", "Elwynn Forest", "Tirisfal Glades", "Dun Morogh", "Mulgore", "Durotar" } }, -- Bloated Brilliant Smallfish
    [6645] = { zones = { "Stormwind City", "Orgrimmar", "Thunder Bluff", "Undercity", "Ironforge", "The Barrens" } }, -- Bloated Mud Snapper
    [6647] = { zones = { "Stonetalon Mountains", "Redridge Mountains", "Hillsbrad Foothills", "Ashenvale", "Wetlands", "Mount Hyjal" } }, -- Bloated Bristle Whisker Catfish
    [8366] = { zones = { "Stranglethorn Vale", "Arathi Highlands", "Desolace", "Riverglades", "Dustwallow Marsh", "Mount Hyjal" } }, -- Bloated Mithril Head Trout
    [13881] = { zones = { "Hillsbrad Foothills", "Stonetalon Mountains", "Feralas", "Ashenvale", "Western Plaguelands", "Wetlands" } }, -- Bloated Redgill
    [13891] = { zones = { "Mount Hyjal", "Moonglade" } }, -- Bloated Whitescale Salmon
    [21162] = { zones = { "Azshara" } }, -- Bloated Oily Blackmouth
    [21164] = { zones = { "Alterac Mountains", "Stranglethorn Vale", "Mount Hyjal" } }, -- Bloated Rockscale Cod
    [21243] = { zones = { "Tanaris", "Riverglades" } }, -- Bloated Glossy Mightfish

    -- the odd ones: grey vendor fish and a Stranglethorn quest fish
    [6360] = { zones = { "Hillsbrad Foothills" } }, -- Steelscale Crushfish
    [1467] = { zones = { "Redridge Mountains" } }, -- Spotted Sunfish
    [6458] = { zones = { "Stonetalon Mountains", "The Barrens" } }, -- Oil Covered Fish
    [19975] = { zones = { "Hillsbrad Foothills", "Winterspring" } }, -- Zulian Mudskunk
    [19808] = { zones = { "Stranglethorn Vale" } }, -- Rockhide Strongfish (Fishing Extravaganza; not logged on Wowhead Forever yet)
}

-- Everything else that comes up on the line: [itemID] = { group, zones by how often }
-- (from Wowhead's Forever fishing loot, Nov 2026)
Data.FINDS = {
    [20708] = { "treasure", zones = { "The Barrens", "Darkshore", "Silverpine Forest", "Westfall", "Loch Modan", "Redridge Mountains" } }, -- Tightly Sealed Trunk
    [21150] = { "treasure", zones = { "Stranglethorn Vale", "Alterac Mountains", "Dustwallow Marsh", "Desolace", "The Barrens", "Riverglades" } }, -- Iron Bound Trunk
    [21113] = { "treasure", zones = { "Hillsbrad Foothills", "Stonetalon Mountains", "Wetlands", "Ashenvale" } }, -- Watertight Trunk
    [6718] = { "treasure", zones = { "Darkshore" } }, -- Electropeller
    [21228] = { "treasure", zones = { "Stranglethorn Vale", "Tanaris", "Riverglades", "Feralas", "Azshara", "Mount Hyjal" } }, -- Mithril Bound Trunk
    [6717] = { "treasure", zones = { "Darkshore" } }, -- Gaffer Jack
    [20709] = { "treasure", zones = { "The Barrens", "Darkshore", "Westfall", "Silverpine Forest", "Loch Modan", "Redridge Mountains" } }, -- Rumsey Rum Light
    [21151] = { "treasure", zones = { "Stranglethorn Vale", "Riverglades", "Alterac Mountains", "Tanaris", "Dustwallow Marsh", "Desolace" } }, -- Rumsey Rum Black Label
    [21114] = { "treasure", zones = { "Hillsbrad Foothills", "Stonetalon Mountains", "Wetlands", "Ashenvale" } }, -- Rumsey Rum Dark
    [6292] = { "treasure", zones = { "Elwynn Forest", "Zephras Isle", "Tirisfal Glades", "Mulgore", "Dun Morogh", "Teldrassil" } }, -- 10 Pound Mud Snapper
    [6309] = { "treasure", zones = { "Stormwind City", "Orgrimmar", "Thunder Bluff", "Undercity", "Darkshore", "Ironforge" } }, -- 17 Pound Catfish
    [6310] = { "treasure", zones = { "Stormwind City", "Orgrimmar", "Thunder Bluff", "Redridge Mountains", "Stonetalon Mountains", "Ashenvale" } }, -- 19 Pound Catfish
    [6294] = { "treasure", zones = { "Elwynn Forest", "Zephras Isle", "Mulgore", "Dun Morogh", "Tirisfal Glades", "Teldrassil" } }, -- 12 Pound Mud Snapper
    [6307] = { "treasure", zones = { "Darkshore", "The Barrens", "Wetlands", "Hillsbrad Foothills", "Ashenvale", "Stormwind City" } }, -- Message in a Bottle
    [6353] = { "treasure", zones = { "Darkshore", "The Barrens", "Stormwind City", "Westfall", "Silverpine Forest" } }, -- Small Chest
    [6357] = { "treasure", zones = { "Stranglethorn Vale", "Dustwallow Marsh", "Riverglades", "Desolace", "Swamp of Sorrows" } }, -- Sealed Crate
    [6355] = { "treasure", zones = { "Stranglethorn Vale", "Dustwallow Marsh", "Riverglades", "Swamp of Sorrows", "Desolace", "Arathi Highlands" } }, -- Sturdy Locked Chest
    [6351] = { "treasure", zones = { "Darkshore", "The Barrens", "Westfall", "Stormwind City", "Silverpine Forest" } }, -- Dented Crate
    [6356] = { "treasure", zones = { "Durotar", "Teldrassil", "Tirisfal Glades" } }, -- Battered Chest
    [6311] = { "treasure", zones = { "Redridge Mountains", "Orgrimmar", "Stormwind City", "Stonetalon Mountains", "Desolace", "Ashenvale" } }, -- 22 Pound Catfish
    [6354] = { "treasure", zones = { "Wetlands", "Ashenvale", "Hillsbrad Foothills" } }, -- Small Locked Chest
    [6352] = { "treasure", zones = { "Wetlands", "Hillsbrad Foothills", "Ashenvale" } }, -- Waterlogged Crate
    [6295] = { "treasure", zones = { "Elwynn Forest", "Zephras Isle", "Mulgore", "Dun Morogh", "Tirisfal Glades", "Durotar" } }, -- 15 Pound Mud Snapper
    [13875] = { "treasure", zones = { "Tanaris", "Azshara", "Feralas" } }, -- Ironbound Locked Chest
    [13874] = { "treasure", zones = { "Tanaris", "Stranglethorn Vale", "Feralas", "Azshara" } }, -- Heavy Crate
    [13876] = { "treasure", zones = { "Tanaris", "The Hinterlands", "Feralas", "Azshara" } }, -- 40 Pound Yellowtail
    [13877] = { "treasure", zones = { "Tanaris", "Feralas", "Azshara" } }, -- 47 Pound Yellowtail
    [13885] = { "treasure", zones = { "Feralas", "Western Plaguelands", "Desolace", "Eastern Plaguelands" } }, -- 34 Pound Redgill
    [6363] = { "treasure", zones = { "Ashenvale", "Wetlands", "Dustwallow Marsh", "Arathi Highlands", "Redridge Mountains", "Desolace" } }, -- 26 Pound Catfish
    [13886] = { "treasure", zones = { "Feralas", "The Hinterlands", "Eastern Plaguelands", "Desolace", "Western Plaguelands" } }, -- 37 Pound Redgill
    [13878] = { "treasure", zones = { "Tanaris", "Feralas" } }, -- 53 Pound Yellowtail
    [13882] = { "treasure", zones = { "Feralas", "Ashenvale", "Moonglade" } }, -- 42 Pound Redgill
    [13905] = { "treasure", zones = { "Eastern Plaguelands", "Winterspring", "Mount Hyjal" } }, -- 29 Pound Salmon
    [6364] = { "treasure", zones = { "Arathi Highlands", "Redridge Mountains", "Ashenvale" } }, -- 32 Pound Catfish
    [13879] = { "treasure", zones = { "Tanaris" } }, -- 59 Pound Yellowtail
    [13902] = { "treasure", zones = { "Stormwind City", "Silithus" } }, -- 18 Pound Salmon
    [13904] = { "treasure", zones = { "Eastern Plaguelands", "Mount Hyjal" } }, -- 25 Pound Salmon
    [17058] = { "treasure", zones = { "Desolace", "Riverglades" } }, -- Fish Oil
    [13883] = { "treasure", zones = { "The Hinterlands", "Eastern Plaguelands" } }, -- 45 Pound Redgill
    [13884] = { "treasure", zones = { "Western Plaguelands", "Felwood" } }, -- 49 Pound Redgill
    [13901] = { "treasure", zones = { "Mount Hyjal", "Duskwood" } }, -- 15 Pound Salmon
    [17057] = { "treasure", zones = { "Desolace" } }, -- Shiny Fish Scales
    [13887] = { "treasure", zones = { "Un'Goro Crater" } }, -- 52 Pound Redgill
    [13903] = { "treasure", zones = { "Duskwood" } }, -- 22 Pound Salmon
    [6297] = { "junk", zones = { "Undercity", "Tirisfal Glades", "Silverpine Forest", "Ashenvale", "Westfall", "Alterac Mountains" } }, -- Old Skull
    [6301] = { "junk", zones = { "Tirisfal Glades", "Undercity", "Silverpine Forest" } }, -- Old Teamster's Skull
    [6457] = { "junk", zones = { "Stonetalon Mountains" } }, -- Rusted Engineering Parts
    [6456] = { "junk", zones = { "Stonetalon Mountains", "The Barrens" } }, -- Acidic Slime
    [6455] = { "junk", zones = { "The Barrens" } }, -- Old Wagonwheel
    [6306] = { "junk", zones = { "Ashenvale" } }, -- Damp Diary Page (Day 512)
    [770] = { "junk", zones = { "Stranglethorn Vale" } }, -- Pointy Crocolisk Tooth
    [7973] = { "treasure", zones = { "Tanaris", "The Hinterlands", "Azshara", "Feralas" } }, -- Big-mouth Clam (a shellfish: you open it for a pearl)
}

-- Zone level range and fishing skill (Wowhead's Forever fishing guide): the skill you
-- need to fish there at all, and the skill where every cast catches. nil = no water,
-- or not in the guide (Riverglades, Mount Hyjal).
Data.ZONES = {
    ["Alterac Mountains"] = { 27, 39, 130, 225 },
    ["Arathi Highlands"] = { 30, 40, 130, 225 },
    ["Ashenvale"] = { 19, 30, 55, 150 },
    ["Azshara"] = { 42, 55, 205, 300 },
    ["Badlands"] = { 36, 45 },
    ["Blasted Lands"] = { 46, 63 },
    ["Burning Steppes"] = { 50, 59, 330, 425 },
    ["Darkshore"] = { 11, 19, 1, 75 },
    ["Darnassus"] = { 1, 60, 1, 75 },
    ["Deadwind Pass"] = { 50, 60, 330, 425 },
    ["Desolace"] = { 30, 39, 130, 225 },
    ["Dun Morogh"] = { 1, 56, 1, 25 },
    ["Durotar"] = { 1, 10, 1, 25 },
    ["Duskwood"] = { 10, 30, 55, 150 },
    ["Dustwallow Marsh"] = { 36, 61, 130, 225 },
    ["Eastern Plaguelands"] = { 54, 59, 330, 425 },
    ["Elwynn Forest"] = { 1, 10, 1, 25 },
    ["Felwood"] = { 47, 54, 205, 300 },
    ["Feralas"] = { 41, 60, 205, 300 },
    ["Hillsbrad Foothills"] = { 20, 31, 55, 150 },
    ["Ironforge"] = { 1, 60, 1, 75 },
    ["Loch Modan"] = { 10, 18, 1, 75 },
    ["Moonglade"] = { 15, 15, 205, 300 },
    ["Mulgore"] = { 1, 10, 1, 25 },
    ["Orgrimmar"] = { 1, 60, 1, 75 },
    ["Redridge Mountains"] = { 15, 25, 55, 150 },
    ["Riverglades"] = { 36, 44 },
    ["Searing Gorge"] = { 43, 56 },
    ["Silithus"] = { 55, 59, 330, 425 },
    ["Silverpine Forest"] = { 10, 20, 1, 75 },
    ["Stonetalon Mountains"] = { 15, 25, 55, 150 },
    ["Stormwind City"] = { 1, 60, 1, 75 },
    ["Stranglethorn Vale"] = { 30, 50, 130, 225 },
    ["Swamp of Sorrows"] = { 36, 43, 130, 225 },
    ["Tanaris"] = { 40, 50, 205, 300 },
    ["Teldrassil"] = { 1, 11, 1, 25 },
    ["The Barrens"] = { 10, 33, 1, 75 },
    ["The Hinterlands"] = { 41, 56, 205, 300 },
    ["Thousand Needles"] = { 6, 35, 130, 225 },
    ["Thunder Bluff"] = { 1, 60, 1, 75 },
    ["Tirisfal Glades"] = { 1, 12, 1, 25 },
    ["Un'Goro Crater"] = { 48, 55, 205, 300 },
    ["Undercity"] = { 1, 60, 1, 75 },
    ["Western Plaguelands"] = { 46, 57, 205, 300 },
    ["Westfall"] = { 9, 18, 1, 75 },
    ["Wetlands"] = { 20, 30, 55, 150 },
    ["Winterspring"] = { 55, 60, 330, 425 },
    ["Zephras Isle"] = { 1, 12, 1, 25 },
    ["Mount Hyjal"] = { 55, 60 },   -- level range a guess: Forever's endgame zone
}

-- Spots that need more than the rest of their zone (fish from, every cast catches)
Data.SUBZONES = {
    ["Jaguero Isle"] = { 205, 300 },
    ["Bay of Storms"] = { 330, 425 }, ["Hetaera's Clutch"] = { 330, 425 }, ["Scalebeard's Cave"] = { 330, 425 },
    ["Jademir Lake"] = { 330, 425 },
}

-- Faction territory (Wowhead Forever); anything not listed is contested
Data.FACTION = {
    ["Elwynn Forest"] = "Alliance", ["Dun Morogh"] = "Alliance", ["Teldrassil"] = "Alliance",
    ["Westfall"] = "Alliance", ["Loch Modan"] = "Alliance", ["Darkshore"] = "Alliance",
    ["Stormwind City"] = "Alliance", ["Ironforge"] = "Alliance", ["Darnassus"] = "Alliance",
    ["Durotar"] = "Horde", ["Mulgore"] = "Horde", ["Tirisfal Glades"] = "Horde",
    ["The Barrens"] = "Horde", ["Silverpine Forest"] = "Horde",
    ["Orgrimmar"] = "Horde", ["Thunder Bluff"] = "Horde", ["Undercity"] = "Horde",
}

-- Ducky Says: a line per fish, usually a pun. [1] is for anywhere, then one per zone.
Data.PUNS = {
    [6291] = { -- Brilliant Smallfish
        "Small fish, brilliant attitude. Like me!",
        ["Elwynn Forest"] = "Elwynn's finest! Small, shiny and a little smug.",
        ["Dun Morogh"] = "Brrr! Even the smallfish wear mittens here.",
        ["Mulgore"] = "Small fish, big plains. It's very humble about it.",
        ["Zephras Isle"] = "An island smallfish! It's on holiday, like you.",
        ["Tirisfal Glades"] = "Still shiny, even in all this gloom. Good for it!",
        ["Teldrassil"] = "It sparkles like the moonlight on the leaves.",
    },
    [6303] = { -- Slitherskin Mackerel
        "Slippery! Hold on with both hands... or wings.",
        ["Durotar"] = "A mackerel in the desert? Holy mackerel!",
        ["Teldrassil"] = "It slithered all the way up the World Tree!",
        ["The Barrens"] = "The Barrens aren't so barren after all!",
        ["Darkshore"] = "Slithery and shadowy. Very on theme.",
        ["Westfall"] = "Westfall's best-kept secret. Don't tell the gnolls.",
        ["Silverpine Forest"] = "Silverpine silver, swimming right at you.",
    },
    [6289] = { -- Longjaw Mud Snapper
        "All jaw and no manners. Mind your fingers!",
        ["Ironforge"] = "Fresh from the forge pools. Pre-heated!",
        ["Thunder Bluff"] = "It snapped at a kodo once. The kodo won.",
        ["Orgrimmar"] = "Even the fish in Orgrimmar look tough.",
        ["Darnassus"] = "The fanciest mud snapper you'll ever meet.",
        ["Stormwind City"] = "A city fish. It's seen things in those canals.",
        ["Undercity"] = "It lives down here by choice. Respect.",
    },
    [6317] = { -- Loch Frenzy
        "Frenzied! Just like me at bath time.",
        ["Loch Modan"] = "The loch's very own frenzy. Och aye!",
    },
    [6361] = { -- Rainbow Fin Albacore
        "Taste the rainbow! Well, cook it first.",
        ["Wetlands"] = "A rainbow in the Wetlands! Must've been raining.",
        ["The Barrens"] = "The only rainbow for miles out here.",
        ["Darkshore"] = "A splash of colour on a moody shore!",
        ["Westfall"] = "Somewhere over the farmland... a rainbow fin!",
        ["Ashenvale"] = "It matches the pretty forest. Very stylish.",
        ["Hillsbrad Foothills"] = "Rainbows over Hillsbrad. Lovely day for it.",
    },
    [21071] = { -- Sagefish
        "A very wise fish. It saw you coming, though.",
        ["Hillsbrad Foothills"] = "Wise old Hillsbrad sage. It gives great advice.",
        ["Loch Modan"] = "A dwarf sage once said: more fish, less talk.",
        ["Stonetalon Mountains"] = "Wisdom from the mountain streams!",
        ["Silverpine Forest"] = "The sage of Silverpine. Very mysterious.",
        ["Ashenvale"] = "Ashenvale's quietest philosopher.",
    },
    [6308] = { -- Bristle Whisker Catfish
        "Whiskers! Is it a cat? Is it a fish? Yes!",
        ["Duskwood"] = "Even the catfish are spooky in Duskwood.",
        ["Redridge Mountains"] = "Redridge whiskers! Very distinguished.",
        ["Shen'dralas"] = "Fancy whiskers for a fancy place.",
        ["Stonetalon Mountains"] = "It climbed up here just to meet you.",
        ["Ashenvale"] = "Meow? No, glub. Definitely glub.",
        ["Thousand Needles"] = "A thousand needles and one bristly fish!",
    },
    [6522] = { -- Deviate Fish
        "It's not quite right. In a fun way!",
        ["The Barrens"] = "Fresh from the Wailing Caverns. Eat at your own risk!",
    },
    [6299] = { -- Sickly Looking Fish
        "Oh dear. Someone get this fish a healer.",
        ["Undercity"] = "It looks how the Undercity smells.",
        ["Tirisfal Glades"] = "Tirisfal's finest. Which isn't saying much.",
        ["Silverpine Forest"] = "Poor thing. Even the wolves won't eat it.",
    },
    [12238] = { -- Darkshore Grouper
        "A grouper! Bring a group. It's a big one.",
        ["Darkshore"] = "Born in Darkshore, named after Darkshore. Proud!",
    },
    [6358] = { -- Oily Blackmouth
        "Slick! Great for the frying pan... or the oil.",
        ["Wetlands"] = "Wetlands oil spill! Er, oil fish.",
        ["The Barrens"] = "An oily treat from the dusty Barrens.",
        ["Riverglades"] = "Oily and glossy. The river's very proud.",
        ["Stranglethorn Vale"] = "Pirates love these. Something about the oil.",
        ["Darkshore"] = "Shiny black, just like the night here.",
        ["Westfall"] = "Oil from Westfall? Don't tell the Defias.",
    },
    [6359] = { -- Firefin Snapper
        "Careful, it's hot! Well, not really. But look at it!",
        ["Wetlands"] = "Fire in the Wetlands? Don't worry, it's soggy.",
        ["Stranglethorn Vale"] = "A jungle firecracker!",
        ["Tanaris"] = "Fire and sand. It must love it here.",
        ["Riverglades"] = "The river's spiciest resident.",
        ["Dustwallow Marsh"] = "A spark in the swamp. Very cosy.",
        ["Stonetalon Mountains"] = "It lit up the mountain stream!",
    },
    [6362] = { -- Rockscale Cod
        "Scales like rocks. Rock on!",
        ["Swamp of Sorrows"] = "Don't be sorrowful, you caught a cod!",
        ["Stranglethorn Vale"] = "Rock-hard and jungle-tough.",
        ["Dustwallow Marsh"] = "A rock in the marsh. A fishy one!",
        ["Riverglades"] = "The river polished it smooth. Mostly.",
        ["Azshara"] = "Even the cod here have fancy scales.",
        ["Desolace"] = "Desolace has one thing going for it: cod.",
    },
    [8365] = { -- Mithril Head Trout
        "A fish with a helmet! Very sensible.",
        ["Thousand Needles"] = "Its mithril head keeps the needles away.",
        ["Arathi Highlands"] = "Battle-ready trout! For the highlands!",
        ["Shen'dralas"] = "Shiny head, fancy waters. Perfect match.",
        ["Desolace"] = "It wore its helmet to brave Desolace.",
        ["Alterac Mountains"] = "Mithril AND a cold head. Tough cookie.",
        ["Dustwallow Marsh"] = "Muddy marsh, shiny head. Fashion!",
    },
    [21153] = { -- Greater Sagefish
        "Even wiser than the regular sagefish!",
        ["Alterac Mountains"] = "A mountain-top guru. Very chilly wisdom.",
        ["Riverglades"] = "The greatest sage of the river!",
        ["Stranglethorn Vale"] = "Jungle wisdom: always bring bait.",
    },
    [4603] = { -- Spotted Yellowtail
        "Spotted! Like it was hiding badly.",
        ["Azshara"] = "Spotted in Azshara! Very glamorous.",
        ["Tanaris"] = "Yellow like the sand. Clever camouflage!",
        ["Swamp of Sorrows"] = "A little sunshine in the sorrows.",
        ["The Hinterlands"] = "Spotted in the Hinterlands. Gryphons jealous.",
        ["Stranglethorn Vale"] = "A tropical treat! Spotted, not stirred.",
        ["Dustwallow Marsh"] = "Yellowtail in the swamp. Bold choice!",
    },
    [7973] = { -- Big-mouth Clam
        "Big mouth! I know the feeling.",
        ["The Hinterlands"] = "It's been gossiping to the trolls.",
        ["Azshara"] = "Maybe there's a pearl in there!",
        ["Feralas"] = "A Feralas clam! Open it, open it!",
        ["Tanaris"] = "Sandy, but worth it. Pearl time?",
    },
    [13422] = { -- Stonescale Eel
        "Stone scales! Rock and eel!",
        ["Azshara"] = "Azshara's toughest noodle.",
        ["Tanaris"] = "A desert eel with a hard shell. Wise!",
        ["Riverglades"] = "The river's wiggliest rock.",
        ["The Hinterlands"] = "Wriggly AND stony. The trolls are impressed.",
        ["Feralas"] = "A Feralas eel. Wriggly and proud!",
        ["Stranglethorn Vale"] = "Jungle eel! Slippery AND stony.",
    },
    [13754] = { -- Glossy Mightfish
        "So glossy! What's its skincare routine?",
        ["Azshara"] = "Azshara's shiniest! Very fancy.",
        ["Tanaris"] = "Glossy in the sun. Sunglasses on!",
        ["The Hinterlands"] = "Mighty AND glossy. Show-off.",
        ["Feralas"] = "Feralas gloss. Very polished!",
    },
    [13755] = { -- Winter Squid
        "A squid in a scarf! Okay, I made up the scarf.",
        ["Tanaris"] = "A winter squid in the desert? It's lost!",
        ["Azshara"] = "Chilly squid from chilly waters. Brr!",
        ["The Hinterlands"] = "Winter came early in the Hinterlands!",
        ["Feralas"] = "Snow day in Feralas! Squid edition.",
    },
    [13757] = { -- Lightning Eel
        "Zap! Shocking catch!",
        ["Eastern Plaguelands"] = "A spark of life in the plaguelands!",
        ["Mount Hyjal"] = "Lightning on the mountain. Electrifying!",
        ["The Hinterlands"] = "It's been zapping the trolls. Rude.",
        ["Western Plaguelands"] = "Watt a find in the west!",
        ["Moonglade"] = "Lightning under the moon. Very dramatic.",
        ["Feralas"] = "Feralas' brightest idea!",
    },
    [13758] = { -- Redgill
        "Red gills! It's blushing. You flatter it.",
        ["Feralas"] = "Red in the green! Feralas fashion.",
        ["Western Plaguelands"] = "Rosy cheeks, even in the plaguelands.",
        ["The Hinterlands"] = "It blushed at the gryphons.",
        ["Azshara"] = "Azshara's rosiest little fish.",
        ["Mount Hyjal"] = "A mountain blush! So shy.",
        ["Moonglade"] = "Red under the moon. Romantic!",
    },
    [13759] = { -- Nightfin Snapper
        "A night owl fish! I mean, night fin.",
        ["Deadwind Pass"] = "Deadwind at night? Brave fish. Brave you!",
        ["Moonglade"] = "Moonglade by moonlight. Perfect for a nightfin!",
        ["Mount Hyjal"] = "Starry nights on the mountain.",
        ["Feralas"] = "Nightfin in the jungle dark. Spooky!",
        ["Western Plaguelands"] = "Night in the plaguelands. Keep a light on!",
        ["Azshara"] = "Azshara after dark. So glamorous.",
    },
    [13760] = { -- Sunscale Salmon
        "Sun-kissed scales! Lucky salmon.",
        ["Eastern Plaguelands"] = "Sunshine in the plaguelands. Rare!",
        ["Western Plaguelands"] = "A ray of hope in the west!",
        ["Mount Hyjal"] = "Sunrise on the mountain. Gorgeous.",
        ["The Hinterlands"] = "Sunny Hinterlands salmon. Holiday vibes.",
        ["Feralas"] = "Sunbathing in Feralas. Good life.",
        ["Moonglade"] = "A sun fish in Moonglade? Confused, but cute.",
    },
    [13888] = { -- Darkclaw Lobster
        "Pinchy! Watch the claws!",
        ["Azshara"] = "Azshara's crankiest crustacean.",
    },
    [13889] = { -- Whitescale Salmon
        "Pale and proud. It doesn't tan.",
        ["Eastern Plaguelands"] = "Pale as a ghost. Fits right in here.",
        ["Mount Hyjal"] = "White as mountain snow!",
        ["Deadwind Pass"] = "Spooky pale salmon from a spooky place.",
    },
    [13893] = { -- Large Mightfish
        "LARGE. And mighty. Mostly large.",
        ["Azshara"] = "Azshara's biggest show-off.",
    },
    [13890] = { -- Plated Armorfish
        "Full plate! It's ready for a raid.",
        ["Deadwind Pass"] = "It armoured up for Deadwind. Smart.",
        ["Mount Hyjal"] = "Plated and ready to defend the mountain!",
        ["Eastern Plaguelands"] = "Armour on. The plaguelands are rough.",
    },
    [251524] = { -- Whimsyfin
        "How whimsical! It's having the best day.",
        ["Redridge Mountains"] = "A spot of whimsy in Redridge!",
    },
    [16967] = { -- Feralas Ahi
        "Ahi! Ahoy! Ahaha!",
        ["Feralas"] = "Feralas ahi! Straight from the source.",
    },
    [16968] = { -- Sar'theris Striker
        "Strike! A perfect catch.",
        ["Desolace"] = "Desolace's best striker. Strike one!",
    },
    [16969] = { -- Savage Coast Blue Sailfin
        "Sail away! Okay, not that far.",
        ["Stranglethorn Vale"] = "Blue as the Savage Coast. Ahoy!",
    },
    [16970] = { -- Misty Reed Mahi Mahi
        "Mahi mahi! So good they named it twice.",
        ["Swamp of Sorrows"] = "Misty reeds, happy fish. No sorrows here!",
    },
    [19803] = { -- Brownell's Blue Striped Racer
        "Zoom! Brownell would be proud.",
        ["Stranglethorn Vale"] = "A tournament racer! Hurry to Booty Bay!",
    },
    [19805] = { -- Keefer's Angelfish
        "An angel! Keefer will be thrilled.",
        ["Stranglethorn Vale"] = "Tournament angel! Get it to Booty Bay!",
    },
    [6643] = { -- Bloated Brilliant Smallfish
        "Small fish, big appetite. Open wide!",
        ["Zephras Isle"] = "Island snacking. Something's in there!",
        ["Elwynn Forest"] = "Elwynn's finest overeater. Pop it open!",
        ["Tirisfal Glades"] = "Even the fish here are stuffed. Spooky.",
        ["Dun Morogh"] = "Puffed up against the cold. Smart fish.",
        ["Mulgore"] = "A plains fish that ate the plains.",
        ["Durotar"] = "Durotar's toughest little glutton.",
    },
    [6645] = { -- Bloated Mud Snapper
        "Swallowed something shiny, I bet.",
        ["Stormwind City"] = "City fish, city appetite.",
        ["Orgrimmar"] = "Ate its way through the canals!",
        ["Thunder Bluff"] = "From the pools up high, puffed up proud.",
        ["Undercity"] = "What has it been eating down here?!",
        ["Ironforge"] = "A forge-fed feast in there.",
        ["The Barrens"] = "Barrens fish don't skip meals.",
    },
    [6647] = { -- Bloated Bristle Whisker Catfish
        "Whiskers and a full belly. Classic catfish.",
        ["Stonetalon Mountains"] = "Mountain catfish, mountain-sized lunch.",
        ["Redridge Mountains"] = "Redridge's roundest resident.",
        ["Hillsbrad Foothills"] = "Stuffed full of Hillsbrad goodies.",
        ["Ashenvale"] = "Ate half the forest floor, by the looks.",
        ["Wetlands"] = "Swamp-fed and swollen. Lovely.",
        ["Mount Hyjal"] = "Even on the holy mountain, it overate.",
    },
    [8366] = { -- Bloated Mithril Head Trout
        "Mithril head, treasure belly!",
        ["Stranglethorn Vale"] = "A jungle trout with jungle loot inside.",
        ["Arathi Highlands"] = "Highland trout, hearty helping.",
        ["Desolace"] = "Found something to eat in Desolace. Impressive.",
        ["Riverglades"] = "A Riverglades trout full of surprises.",
        ["Dustwallow Marsh"] = "Marsh-stuffed and ready to pop.",
        ["Mount Hyjal"] = "A sacred trout. Sacredly stuffed.",
    },
    [13881] = { -- Bloated Redgill
        "Red gills, round belly. Open it up!",
        ["Hillsbrad Foothills"] = "Hillsbrad redgill, full to the brim.",
        ["Stonetalon Mountains"] = "Stuffed with Stonetalon pebbles? Let's see!",
        ["Feralas"] = "Feralas feasting at its finest.",
        ["Ashenvale"] = "An Ashenvale glutton. Respect.",
        ["Western Plaguelands"] = "I'd check what it ate here. Carefully.",
        ["Wetlands"] = "A wet, round, wonderful redgill.",
    },
    [13891] = { -- Bloated Whitescale Salmon
        "A salmon with a secret in its tummy.",
        ["Mount Hyjal"] = "Mountain salmon, mountain of loot?",
        ["Moonglade"] = "Moonlit and well fed. Peek inside!",
    },
    [21162] = { -- Bloated Oily Blackmouth
        "Oily, bloated and suspicious. Perfect.",
        ["Azshara"] = "Azshara's slickest snack-eater.",
    },
    [21164] = { -- Bloated Rockscale Cod
        "Rocks in its scales, treasure in its belly.",
        ["Alterac Mountains"] = "An Alterac cod that ate well. Good for it.",
        ["Stranglethorn Vale"] = "Jungle cod, jungle-sized meal.",
        ["Mount Hyjal"] = "Cod on the mountain? And stuffed, too!",
    },
    [21243] = { -- Bloated Glossy Mightfish
        "Shiny outside, shinier inside, hopefully.",
        ["Tanaris"] = "A desert-coast mightfish, munched to bursting.",
        ["Riverglades"] = "Glossy, mighty and very, very full.",
    },
    [6360] = { -- Steelscale Crushfish
        "Steel scales! Don't bite down.",
        ["Hillsbrad Foothills"] = "Hillsbrad's heavy-metal fish.",
    },
    [1467] = { -- Spotted Sunfish
        "A little spotted sunbeam.",
        ["Redridge Mountains"] = "Sunshine in the Redridge rivers.",
    },
    [6458] = { -- Oil Covered Fish
        "Ew. Someone's been spilling in the water.",
        ["Stonetalon Mountains"] = "Venture Co. mess, I'd wager. Poor thing.",
        ["The Barrens"] = "The oil fields leak. This fish knows.",
    },
    [19975] = { -- Zulian Mudskunk
        "Smells like Zul'Gurub. Hold your beak.",
        ["Hillsbrad Foothills"] = "A mudskunk in Hillsbrad? Long way from home!",
        ["Winterspring"] = "A frozen mudskunk. Smells less, at least.",
    },
    [19808] = { -- Rockhide Strongfish
        "Rock-hard and proud of it. Mind your fingers.",
        ["Stranglethorn Vale"] = "A tournament heavyweight! Off to Booty Bay with it!",
    },
    [19806] = { -- Dezian Queenfish
        "Bow before the queen! Of fish.",
        ["Stranglethorn Vale"] = "Royalty in the tournament! Quick, to Booty Bay!",
    },
    [19807] = { -- Speckled Tastyfish
        "Tasty by name, tasty by nature!",
        ["Stranglethorn Vale"] = "Tastyfish from the tournament! Yum.",
    },
    [13756] = { -- Summer Bass
        "Summer bass! Drop the bass!",
        ["Tanaris"] = "Summer in Tanaris? Every day is summer here!",
        ["Azshara"] = "A summer holiday in Azshara!",
        ["The Hinterlands"] = "Summer in the Hinterlands. Picnic time!",
        ["Feralas"] = "Feralas summer bass. Beach day!",
    },
}

-- Ducky's line for a fish: the one for where you were, or the general one
function Data.Pun(id, zone)
    local p = Data.PUNS[id]
    if type(p) ~= "table" then return p end
    return (zone and p[zone]) or p[1]
end

-- for anything without its own line
Data.DUCKY_GENERAL = {
    "Of all the fish in the sea, you picked this one!",
    "Ooh, that one's going in the scrapbook!",
    "Reel-y nice work!",
    "Another one for the collection!",
    "I knew you had it in you!",
}
-- for "???" fish
Data.DUCKY_MYSTERY = {
    "Ooh, a mystery! I'm not telling...",
    "My beak is sealed!",
    "Keep casting, you'll see!",
}
-- for spots on the Waters bookmark
Data.DUCKY_WATERS = {
    "Nice spot! I'd come back here.",
    "The water's lovely today!",
    "I can feel a big one nearby...",
    "Quack-tastic place to fish!",
}

-- for a zone you've found but never fished
Data.DUCKY_UNFISHED = {
    "Haven't wet a line here yet!",
    "Ooh, fresh water! Cast away!",
    "No one's fished here... yet!",
}
-- for a zone you haven't found yet. %s = the continent
Data.DUCKY_UNDISCOVERED = {
    "I've heard of waters somewhere in %s...",
    "A little bird told me it's in %s!",
    "Somewhere in %s, a pond is waiting for you.",
}
-- for things that aren't fish
Data.DUCKY_TREASURE = {
    "Ooh, what's inside? Open it, open it!",
    "Finders keepers!",
    "Treasure! Don't tell the pirates.",
    "The water gives up its secrets!",
}
Data.DUCKY_JUNK = {
    "One angler's junk is another angler's... still junk.",
    "Well, it's not a fish. But it's something!",
    "Into the collection it goes. Somehow.",
    "Someone dropped this. A long time ago.",
}
Data.DUCKY_OFF_MAP = "It's somewhere off the edge of the map!"

-- Hints for undiscovered fish. %s = zone name, %s = level range.
Data.HINT_KNOWN = {
    "Rumour says it bites in %s.",
    "Try your luck in the waters of %s.",
    "Old anglers swear by %s for this one.",
    "Somewhere in %s, it's waiting for you.",
}
-- zone not discovered yet: by difficulty, not distance
Data.HINT_LOCKED = {
    { max = 20, lines = {
        "Calm waters you haven't found yet (%s).",
        "Swims somewhere you haven't been yet (%s).",
        "An easy catch, once you find where it hides (%s).",
    } },
    { max = 40, lines = {
        "The ducks whisper of waters you've never seen (%s).",
        "It's playing hard to get, somewhere out there (%s).",
        "Bring a bit more line for this one (%s).",
    } },
    { max = 999, lines = {
        "Only brave anglers have cast where this one swims (%s).",
        "Bring a sharp hook and a sharper sword (%s).",
        "Far from home, in waters still unknown (%s).",
    } },
}

-- the same answer every time for the same thing
function Data.Pick(list, seed)
    if not list or #list == 0 then return "" end
    local n = 0
    seed = tostring(seed or "")
    for i = 1, #seed do n = (n * 31 + seed:byte(i)) % 100003 end
    return list[n % #list + 1]
end
