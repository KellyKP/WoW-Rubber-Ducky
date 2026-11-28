-- Rubber Ducky: "What's new" window. Keep in step with CHANGELOG.md.

local _, ns = ...
local Changelog = {}
ns.Changelog = Changelog

Changelog.entries = {
    { "0.25.0", {
        "|cffffd100New|r",
        "Track a challenge: click one in Ducky's Challenges and a progress bar fills along the wooden plank at the bottom of your fishing log. Click it again to stop. The one you're tracking wears a little compass. With nothing tracked, the plank shows your fishing skill instead (and the boost from your lure in green). Your quarterboard on the log is clickable too: it takes you straight to Mrrl's shelf of boards.",
        "Nine new catch splashes: Caught It!, Nice Catch!, Reel Success!, That's a Keeper!, Line's Tight!, Bigger Catch!, Another One!, Lucky Duck! and Quack! And when a catch has treasure in it, it's Treasure! Got One! and Hooked! have a fresh coat of paint too. Misses get a fresh bunch too: Missed!, Oof!, So Close!, Almost!, Not This Time!, Bummer! and Empty!, and No Bite! when the cast runs out.",
        "The hello in chat when you log in has a [Settings] link to click, and the first login after an update has [See what's new].",
        "The tackle wheel: a ship's wheel in two pages. Fishing has the lures in your bags (best first, with how many you have and their fishing bonus; ones above your skill are greyed out), plus Mrrl's shop, Professions, Ducky's Challenges and your fishing journal. Pick a lure and it goes straight on your pole (hold your pole first). Camp has your campfire kits, best first, then any camp features you carry, from every profession (a Fishing Rack, a Camp Tent, a Mana Well...), and the fish foods that boost fishing. Turn the page with LB and RB, the mouse wheel, or the arrows on the parchment. Open it from the tackle box by the duck on your fishing log, with /ducky tackle, or from a macro with /click RubberDuckyTackleButton. It pops open and tucks away with the sound of a tackle box. Out of combat for now. On a controller, the right stick points, A picks, LB and RB turn the page, and B closes. Its settings are under Casting, with a macro to drag onto your bars, and the tackle box on the log can be turned off there.",
        "The journal's Waters page shows the fishing skill each zone needs, using Forever's own numbers: red if you can't fish there yet, orange if some will still get away.",
        "A banner under the fishing log when you can learn the next fishing rank, one for each: Apprentice (if you haven't learned fishing yet), Journeyman, Expert and Artisan, once your skill has reached its cap and catches stop counting. Hover it for where to go, including Nat Pagle's four fish for Artisan, ticked off as you catch them, and where to fish next. Right-click hides it until next time; turn it off on the Fishing log settings.",
        "|cffffd100Changed|r",
        "The journal's Catches page now has every fish in Forever, 51 in all: the nine Bloated fish, Steelscale Crushfish, Spotted Sunfish, Oil Covered Fish, Zulian Mudskunk and Rockhide Strongfish join the rest, each with its own lines from Ducky. The Big-mouth Clam moves to Whosits & Whatsits, since you open it for a pearl. Anything you've already caught moves along with them, and Know Your Fish III now asks for all 51.",
        "Rubber Ducky's macros have shorter names that fit under a button: Pole, Log, Journal, and Lures for the tackle wheel. The ones already on your bars are renamed where they sit, so nothing moves.",
        "Ducky's Challenges shows what each challenge pays in a tile beside it: the quarterboard, bobber, charm or motto it finds you, and its Fishbones. The window's a little wider to fit them.",
        "Pick which challenges to see: All, Close (the ones you're nearest to finishing, closest first), Done (newest first) or To do. It remembers your choice, and X switches it on a controller.",
        "When you finish a challenge, its banner says so, and what it pays pops in underneath, one line at a time, like loot under a catch.",
        "Fish On! has retired from the catch splashes. If you'd picked one splash to always show, pick it again.",
        "Mrrl's Doohickey Emporium on a controller: the D-pad browses the shelf and turns the page at its edge, X buys or wears what you're looking at, the shoulder buttons change tab and B closes. And Buy is one press now, no \"are you sure?\" The one you're looking at sparkles all the way round, so it's easy to spot. And when you buy something, the whole counter sparkles for a moment.",
        "No more controls bar under the windows: with the Gamepad UI on, each controller button's picture sits right on what it does. LB and RB by the tabs or bookmarks, X on Buy or Sort, A on the journal's map, B on the close button. The journal keeps a little bar beside its bookmarks for the one that doesn't sit on anything, View.",
        "The journal on a controller: no more hopping between the left and right pages. On Waters, A walks down \"What bites here\" and X opens the one it's on. Y writes a note (Y or B when you're done), and View opens Ducky's Challenges.",
        "Ducky's Challenges has its groups as a row of tabs along the top, so LB and RB go left and right like they look. The list gets the full width, and each group's count sits beside its name.",
        "Settings has its pages under six tabs along the top, like Ducky's Challenges: Overview, Casting, Sound & Camera, Your Catch, Journal & Log and Social. A tab with more than one page shows them one under another. Developer settings open from a button at the bottom of Overview.",
        "New scroll bars to match the rest: a blue glass track in gold, a rope-bound thumb you can drag, and an arrow at each end.",
        "|cffffd100Fixed|r",
        "On Waters, picking a treasure or a bit of junk in \"What bites here\" opens it on Whosits & Whatsits, not Catches.",
        "On a controller, What's new, Copy my settings and the Interact-key help now close with B, and What's new and Copy my settings scroll with the D-pad. What's new's words no longer run under its scroll bar, and Copy my settings has the new scroll bar to match the rest.",
    } },
    { "0.24.0", {
        "|cffffd100New|r",
        "Fishing journal: a leather-bound book of everything you've ever caught, one for each character. Open it from Rubber Ducky's line in the minimap's AddOns list, an optional journal button you can drag anywhere, or a \"Ducky Journal\" macro for your action bars. /ducky journal does the same.",
        "  Catches: every fish you've caught and the ones still to find, sorted by zone, rarity, name, most caught or most recent, with a note of your own for every catch, a little map of where it bit, and a word from Ducky.",
        "  Whosits & Whatsits: the crates, trunks, bottles, boots and skulls that come up on your line instead of a fish, with the same sorting as Catches and a filter for just treasure or just junk.",
        "  Waters: every spot you've fished, what bites there, and the zones you've yet to discover, in the order you'd travel them.",
        "  Records: your totals, personal bests (biggest haul, rarest catch, busiest and luckiest spots, longest session), streaks, dated firsts and how close each collection is to complete.",
        "  The first time you open a new catch, its page is written in: the name letter by letter, then each line, then its rarity badge is stamped down.",
        "  Find everything on Catches or Whosits & Whatsits and the page gets stamped COMPLETE!",
        "  Ducky's Challenges: dozens of little goals, from finding all three Rumsey Rums to catching something after midnight, some hidden until you stumble on them. Finish one and a banner pops at the top of the screen. Open them from Records, Rubber Ducky's menu or `/ducky challenges`. Anything you'd already done before this update counts straight away.",
        "  Works with a controller: the D-pad browses, the shoulder buttons flip bookmarks, the View button hops between the left and right pages, Y opens Ducky's Challenges, and a bar under the book shows the rest when the Gamepad UI is on.",
        "First-ever catches get a \"New!\" on the catch splash and in the fishing log, with a little sparkle.",
        "The fishing log writes in each new catch: its icon is stamped onto the page, then the words appear left to right with a quill's scratch.",
        "Rubber Ducky has its own settings window, opened from its menu, /ducky, or the feature list on the overview page, and it goes straight to the page you want. It's still listed in the game's own AddOns settings too. It works with a controller too, as do the Welcome screen and Ducky's Challenges: the D-pad moves between settings, A picks, the shoulder buttons turn pages, and the same controls bar as the journal shows the rest.",
        "A fresh look for every Rubber Ducky window: wood, gold and parchment, from settings and the Welcome screen to the bobber picker, What's new and Share settings. The bobber picker works with a controller too.",
        "Six new bobbers: Froggy, Murloc, Otter, Pipi, Thrall and Jaina.",
        "Twelve brand-new bobbers, from a Golden Duck to a Night Owl, and every bobber now has a little story in the picker.",
        "Shiny Fishbones: now and then one comes up with your catch (always with epics and treasure), and every one of Ducky's Challenges pays some. They turn up more often by a Fishing Rack or Fishing Hut, in a Lucky Fishing Hat, at the Stranglethorn Fishing Extravaganza, or while Fellow Ducky Anglers are fishing in your zone; a little framed icon in the fishing log's corner shows when you're in luck. Challenges you'd already finished pay up the first time you log in. They show on the catch splash, in chat with the rest of your loot, in the fishing log and on Records.",
        "Fishing flair: while your pole is out, your quarterboard hangs over your head with your name and motto on it, your bobber and charm swinging from its rivets and your guild just underneath, for your Fellow Ducky Anglers to see. Theirs show over theirs. Your own hangs off the top of the fishing log, since the game shows no name over your own head. Boards only show if you show player names, and nameplates are only touched while a Fellow Ducky Angler is fishing in your zone. Change it all on the new Fishing flair settings page.",
        "Mrrl's Doohicky Emporium: trade your Fishbones with Mrrl for bobbers, 120 quarterboards, charms and mottos. Visit from Rubber Ducky's menu, the bobber picker, the Fishing journal settings page or /ducky shop. Give Mrrl a poke and he'll chat. It works with a controller too. The big prizes, like the Golden Duck, are still earned from Ducky's Challenges, and a bobber you're already using stays yours.",
        "|cffffd100Changed|r",
        "The fishing log has a new look: a hand-lettered title on the top plank, seven rows, and cattails tucked over the bottom one. When it's more than fits, scroll with the mouse wheel or the rope down its side instead of turning pages.",
        "Smaller download: the big pictures are packed the game's own way, at a third of the size, with no difference you can see.",
        "Pole swap gives you a heads up when the pole or weapon you're swapping to is broken, so you know to get it repaired.",
    } },
    { "0.23.0", {
        "|cffffd100New|r",
        "Fishing log: everything you caught this session on a parchment board, each with a cute note written in its rarity colour. It opens when you equip a fishing pole and goes away when you take it off. Turn it off, resize it or stop it opening by itself on the new Fishing log settings page.",
        "Open the log yourself, for when it doesn't open by itself: an optional log button you can drag anywhere (right-click to lock it in place), or a \"Ducky Log\" macro for your action bars, both on the Fishing log settings page. /ducky log does the same.",
        "Rubber Ducky has its own line in the minimap's AddOns list: click it for a little menu with the fishing log and settings.",
        "One-button fishing settings show what each button is bound to, like Interact [F] or Interact [Not Bound], with steps for binding it when it isn't.",
        "The bobber icon can sit Low, Medium or High above your bobber.",
        "After an update, the hello in chat lets you know, and points you to What's new.",
        "Friendlier settings: Pole swap and Your catch have their own pages, and Copy and Paste settings sit at the top of the overview. Each page has a reset button to put its settings back, and on the Fishing log page, its positions too.",
    } },
    { "0.22.0", {
        "|cffffd100New|r",
        "Pole swap shows a splash with its own sound: \"Nice Day for Fishin'\" and \"It's Adventure Time!\". Both can be turned off on the overview page.",
        "New commands: /ducky swap toggles, /ducky swap 1 puts on your pole and /ducky swap 2 your weapon. They replace /ducky pole.",
        "Share settings: copy your settings as text and paste someone else's, from the overview page.",
        "A \"What's new\" button on the overview page shows this changelog in game.",
        "Chat messages are friendlier and carry the duck icon.",
        "|cffffd100Fixes|r",
        "Pole swap remembers your weapon and pole separately for each character.",
        "The swap splash only shows once your gear has actually changed, so it always matches, and a quick double press no longer undoes a swap.",
        "Swapping in combat, or without your weapon or pole in your bags, now says why instead of failing quietly.",
        "Picking a bobber turns the bobber icon on, in case it was off, and shows it on the bobber right away.",
        "/ducky in combat now opens the settings once combat ends.",
        "The Ducky Pole macro is no longer rewritten while the Macros window is open.",
    } },
    { "0.21.0", {
        "First release.",
    } },
}

local win

local function Text()
    local out = {}
    for _, e in ipairs(Changelog.entries) do
        out[#out + 1] = "|cffffd100" .. e[1] .. "|r"
        for _, line in ipairs(e[2]) do
            -- a coloured line is a sub-heading (e.g. Fixes), not a bullet
            -- two leading spaces: a point under the line above
            if line:find("^|c") then out[#out + 1] = "  " .. line
            elseif line:find("^  ") then out[#out + 1] = "        -  " .. line:sub(3)
            else out[#out + 1] = "  •  " .. line end
        end
        out[#out + 1] = " "
    end
    return table.concat(out, "\n")
end

local function Build()
    -- our navy frame, with its title on a plaque on the top edge
    win = ns.SettingsWindow.Chrome("RubberDuckyChangelog", nil, { title = "What's new", frame = 0.55,
        width = 560, height = 420, scale = 1, strata = "DIALOG" })
    local L, T, R, B = unpack(win.inner)

    local scroll = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", L + 4, -T)
    scroll:SetPoint("BOTTOMRIGHT", -(R + ns.UI.SCROLL_ROOM), B)
    local body = CreateFrame("Frame", nil, scroll)
    body:SetSize(560 - L - R - 4 - ns.UI.SCROLL_ROOM, 10)
    scroll:SetScrollChild(body)
    ns.UI.SlimScrollBar(scroll, win)
    local text = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT")
    -- inside the scrolling box, clear of the scroll bar beside it
    text:SetWidth(560 - L - R - 4 - ns.UI.SCROLL_ROOM - 8)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    win.text, win.body = text, body

    -- on a controller: nothing to pick, so the D-pad scrolls, and B closes
    if ns.Pad and ns.Pad.Attach then
        Changelog.pad = ns.Pad.Attach(win, { roots = function() return {} end, scroll = function() return scroll end,
            badges = function(nav) if win.close then nav:Badge(win.close, "PAD2", "TOPLEFT", 2, -2, 22) end end })
    end
end

function Changelog:Show()
    if not win then Build() end
    win.text:SetText(Text())
    win.body:SetHeight((win.text:GetStringHeight() or 0) + 10)
    win:Show()
end
