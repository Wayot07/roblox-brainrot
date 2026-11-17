# roblox-brainrot

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/Wayot07/roblox-brainrot/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/Wayot07/roblox-brainrot/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

Brainrot Bonanza is a 3D Roblox game in the Steal a Brainrot style. Meme brainrots walk down the central conveyor: press E to buy one, and it moves to your base and earns cash every second. Hold E on another player's brainrot to steal it, then dash home before they slap you with F. Rebirth for a permanent income multiplier, and run for your base when the Brainrot Tsunami warning sounds. Twelve brainrots across six rarities (Common to Secret), Golden / Diamond / Rainbow mutations, eight coloured base plots, a live leaderboard and a full HUD.

It is published live on Roblox as the Public experience "Tempat raka007037" — play it at https://www.roblox.com/games/129878192969262/Tempat-raka007037 (play code `makefun-cobalt-flame-daisy` is in the experience description).

## Run it

Build the place file with Rojo:

```sh
rojo build default.project.json --output game.rbxl
```

Open `game.rbxl` in Roblox Studio and press Play. To hand the entry in, run the kit's program from this directory:

```sh
mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
```

`main.ts` copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` into the output directory and writes `dossier.json` with the vendored make.fun library.

## How it is built

- `default.project.json` — the Rojo project for the 3D world: conveyor lane, eight base plots, spawn pad, totem, trees, lamps, boundary walls and the tsunami wall, plus the script layout. Regenerate it with `python3 gen_project.py`.
- `src/shared/Config.luau` — every number the server and the client agree on: the 12-brainrot catalogue, rarity weights, mutations, steal/rebirth/wave rules and the base positions.
- `src/server/Brainrot.server.luau` — the whole game state: conveyor spawning, buying, stealing and carrying, slapping, rebirths, the earnings tick, the Brainrot Tsunami wave and leaderstats.
- `src/client/Hud.client.luau` — every screen the player sees: start screen, HUD, collection panel, leaderboard, rebirth and slap buttons, wave banner and notifications.
- `PLAY.json` — the published place (place_id / universe_id). The entry gate refuses a play link that is not a Public experience.
- `gen_screenshots.py` — renders the four preview screenshots in `screenshots/` (top-down map + HUD). Do not re-run it after publishing: the uploaded thumbnail must keep matching `screenshots/1-start.png`.

## Controls

WASD / arrow keys to move, Space to jump. E to buy (hold E to steal). F to slap a nearby player. The game works on desktop and mobile.

---

<sub>Entered on [make.fun](https://make.fun/?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
