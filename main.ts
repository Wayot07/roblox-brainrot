// Brainrot Bonanza — a roblox-brainrot-01 entry (Node 22, standard library only).
// Published live on Roblox as Public experience "Tempat raka007037" — place 129878192969262, universe 8219977418 (see PLAY.json).
// The game is this directory's Rojo project, built into game.rbxl with
// `rojo build default.project.json --output game.rbxl`, and this program hands
// it in: it copies game.rbxl, src/, screenshots/ and PLAY.json from beside this
// file to /output and writes /output/dossier.json, the summary the judge reads,
// with the vendored make.fun library.
//
// The game: a 3D Roblox brainrot game. Meme brainrots walk down the central
// conveyor — buy one with E and it moves to your base and earns cash every
// second. Hold E on another player's brainrot to steal it, then dash home
// before they slap you (F). Rebirth for a permanent income multiplier, and
// run to your base when the Brainrot Tsunami warning sounds. The server is
// src/server/Brainrot.server.luau; the screens are src/client/Hud.client.luau;
// the numbers both sides agree on are src/shared/Config.luau.
//
// Screenshots: put your PNG or JPEG screenshots in screenshots/ (the first by
// name is the cover, and one of them is the thumbnail you upload for your game
// on Roblox). Fill in PLAY.json with your published place before you submit —
// the gate refuses an entry whose play link is not a Public experience.
//
// Every name under /output starts with a letter, a digit or _ and holds only letters, digits, . _ and -: the
// grader fails an entry whose output holds any other, so a file such as .gitkeep or .DS_Store copied in fails it.
// So src/ and screenshots/ are copied without any name that starts with a dot, at any depth.
//
// Outside the grader's container, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// The play-link gate refuses a placeholder PLAY.json, so fail fast here
// with a readable error instead of handing in a dead link.
const playLink = JSON.parse(readFileSync(join(here, 'PLAY.json'), 'utf8')) as { place_id: number; universe_id: number; url: string };
if (!playLink.place_id || !playLink.universe_id) {
  throw new Error('PLAY.json still holds a placeholder: publish the game as a Public experience first, then fill in place_id and universe_id.');
}

/** cpSync's filter: leave out every file and directory whose name starts with a dot (.gitkeep, .DS_Store, .git). */
const notDotted = (path: string): boolean => !basename(path).startsWith('.');

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
if (existsSync(join(here, 'screenshots'))) cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's own caps (reference/gate.json): only text_max_bytes shapes the bytes; the others refuse an entry the
// scorer would refuse (more than 4 screenshots or one over 256 KiB; a place of more than 500000 instances, whose
// scripts' sources come to over 8 MiB or whose scripts' paths come to over 1048576 characters, in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);

// Hand-in complete: the output directory now holds everything the judge reads.
console.log(`Brainrot Bonanza handed in to ${out} (game.rbxl + dossier.json).`);
