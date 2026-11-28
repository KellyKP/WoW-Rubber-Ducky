<p align="center"><img src="docs/logo.png" alt="Rubber Ducky" width="256"></p>

<h1 align="center">Rubber Ducky</h1>

<p align="center"><em>Your little fishing buddy</em> for <strong>World of Warcraft: Forever</strong>.</p>

Rubber Ducky makes fishing easier on the ears and eyes. It hushes the world so the splash stands out, marks your bobber, eases the camera toward the water, and lets one button cast and reel in. Your catch lands straight in your bags with a splash banner. It's made for controller play, and it works just as well with mouse and keyboard.

## Features

- **Sound focus.** While your line is out, sound effects go up and music, ambience and dialog fade to a low mumble. It fades back as soon as you catch something or miss.
- **Bobber marker.** A rubber duck, or any of 37 bobber icons, floats above your bobber, with sparkles around it. Each one has a little story in the picker.
- **Fishing camera.** The camera eases in toward the water while you fish and back out when you're done.
- **One-button fishing.** With a pole equipped, one button casts and reels in. You can use Interact, or the left or right trigger on a controller. The button goes back to normal when you take the pole off or combat starts.
- **Auto loot.** Your catch goes straight to your bags, whichever button reeled it in. It doesn't change the game's own auto-loot setting.
- **Catch splash.** A banner slams onto the screen with what you caught, and each item's rarity colours its line. Misses get a splash too: "Missed!" when you reel in empty, and "Zzz..." when the cast runs out.
- **Fishing log.** Everything you caught this session on a parchment board: how many, what it was, and a cute note, both written in the catch's rarity colour. It opens when you equip a fishing pole and closes when you put it away, can be dragged anywhere, and scrolls when you've caught more than seven kinds of thing. An optional log button brings it up any time; right-click it to lock it in place.
- **Fishing journal.** A leather-bound book of everything you've ever caught, one for each character. Catches is every fish you've caught, with a little map of where each one bit, your own notes and a word from Ducky; Whosits & Whatsits holds everything else that comes up on the line; Waters lists every spot you've fished and what bites there; Records keeps your totals, personal bests, streaks, firsts and collection progress.
- **Ducky's Challenges.** Dozens of little goals, from finding all three Rumsey Rums to catching something after midnight, some hidden until you stumble on them.
- **Shiny Fishbones.** Now and then one comes up with your catch, and every challenge pays some. They turn up more often by a Fishing Rack or Fishing Hut, in a Lucky Fishing Hat, at the Stranglethorn Fishing Extravaganza, or with Fellow Ducky Anglers fishing in your zone.
- **Mrrl's Doohicky Emporium.** Trade your Fishbones with Mrrl for bobbers, quarterboards, charms and mottos. Give him a poke and he'll chat.
- **Fishing flair.** While your pole is out, your quarterboard hangs over your head with your name and motto, your bobber and charm swinging from it, for Fellow Ducky Anglers to see. Yours hangs off the top of the fishing log.
- **Tackle wheel.** Your lures, Mrrl's, the journal, Ducky's Challenges and the Professions window on one ring, with a second page for your campfire kits, camp features from any profession and fishing foods. Open it from the tackle box by the fishing log, the Lures macro or `/ducky tackle`. Point with the mouse or the right stick. Out of combat.
- **Rank-up reminder.** When your fishing skill hits its cap and you can learn the next rank, a banner pops up under the fishing log. Hover it for where to find a trainer. With nothing tracked, the plank on the log shows your fishing skill.
- **Pole swap.** Drag the Pole swap icon onto any action bar or crossbar slot. One press puts your fishing pole on, and the next puts back the weapon you had before, each with its own splash and sound. It warns you if either one is broken.
- **Share settings.** Copy your settings as text to share your setup, or paste a friend's. It's on the overview page.

## Install

1. Download the latest release.
2. Unzip it into `World of Warcraft/_forever_/Interface/AddOns/`, so that you have `AddOns/RubberDucky/RubberDucky.toc`.
3. Restart the game, or type `/reload`.

The first time you log in, a welcome screen helps you set things up. After that, type `/ducky` to open the settings. They're also under **Options > AddOns > Rubber Ducky**.

## Commands

You can also click **Rubber Ducky** in the minimap's AddOns list for a menu with the fishing log, the journal, Ducky's Challenges, Mrrl's shop and settings.

| Command | What it does |
|---|---|
| `/ducky` | Open the settings |
| `/ducky icons` | Pick your bobber icon |
| `/ducky swap` | Swap between your fishing pole and your weapon, out of combat (what the Pole macro runs) |
| `/ducky swap 1`, `/ducky swap 2` | Put on your pole (1) or your weapon (2). `pole` and `weapon` work too |
| `/ducky log` | Open or close the fishing log |
| `/ducky journal` | Open or close the fishing journal |
| `/ducky challenges` | Open or close Ducky's Challenges |
| `/ducky shop` | Visit Mrrl's Doohicky Emporium |
| `/ducky tackle` | Open or close the tackle wheel |
| `/ducky test` | Preview the sparkle and bobber icon |
| `/ducky focus`, `sparkle`, `marker`, `camera`, `onekey` | Turn a feature on or off |
| `/ducky welcome` | Show the welcome screen again |
| `/ducky restore` | Put your sound and camera back right now |
| `/ducky help` | List the commands |

## Good to know

- **Bobber marker range.** Forever only soft-targets the bobber within about 10 yards. The marker and sparkles attach through that, so they don't show on longer casts. Reeling in with one button has the same limit.
- **No bite alert.** Forever doesn't tell addons when a fish bites, so Rubber Ducky can't alert you to one. Sound focus makes the splash as easy to hear as possible instead.
- **Other sound addons.** Another addon that changes music or ambience volume while you fish will fight with sound focus. Turn the sound option off in one of them.
- **Experimental camera notice.** The first time the camera eases in, the game may show a notice about experimental camera settings.

## Reporting a bug

The quickest help: turn on **Include debug info when copying settings** on the Developer page, then press **Copy my settings** on the overview page and paste the text into your issue. It lists your settings, game details and other addons.

For more detail, open the **Developer** page in the settings and switch on debug mode. A small console window appears. Do whatever causes the problem, then press **Copy** in the console and paste the text into your issue. For fishing problems, also tick **Event recorder** under Developer and fish once. Then send its log, which opens with **Show log** under Developer or `/ducky events`.

## Credits

The camera and one-button approaches follow [Improved Forever](https://www.curseforge.com/wow/addons/improved-forever) (MIT), which showed what Forever allows.

The handwriting in the fishing log and on the signs is [Patrick Hand](https://fonts.google.com/specimen/Patrick+Hand) by Patrick Wagesreiter, and Mrrl's lettering is [Lilita One](https://fonts.google.com/specimen/Lilita+One) by Juan Montoreano, both under the SIL Open Font License (`Media/Fonts/OFL.txt`).

## License

MIT. See [LICENSE](LICENSE).
