# De Donkere Nacht Remake

A full browser-based pixel-art remake of [*De Donkere Nacht*](https://github.com/aikkuypers2005/De-Donkere-Nacht), the Processing game Job & Aik made at De Jonge Onderzoekers Groningen in 2016. Built with p5.js so anyone can play it directly in the browser (solo, local co-op, or online co-op).

Two guards of the Night Watch rise as zombies on the darkest night of the year to get back the piece a thief cut out of their painting, before the sun comes up.

## Play

### Online (GitHub Pages)
you can play directly at:
`https://aikkuypers2005.github.io/De-Donkere-Nacht-Remake/`

### Locally
```bash
node serve.js
```

Then open http://localhost:8123. Opening `index.html` directly from disk does not work, because browsers block the images that way.

### Desktop version (Processing)
A full standalone Processing 4 (Java mode) port lives in `processing/DeDonkereNacht/` (solo and 2-player local co-op, with keyboard, mouse, and controller support):

1. Open `processing/DeDonkereNacht/DeDonkereNacht.pde` in the [Processing 4 IDE](https://processing.org) and click **Run**.
2. To build a standalone Windows application, choose **File > Export Application...** in the Processing IDE (select Windows and *Embed Java* if desired).

## Controls

| Action | Keyboard 1 | Keyboard 2 | Mouse (2016 style) | Controller |
|---|---|---|---|---|
| Walk | A / D | arrows | left / right button | stick or d-pad |
| Jump | W or Space | up arrow | wheel up | Cross |
| Bite / use | F | Enter | middle button | Square |
| Pause | Esc | Esc | | Options |

- **Alone:** every device controls your zombie; the second zombie follows you.
- **Together on one computer:** pick a device per player under *Controls*.
- **Online:** one player hosts and gets a 4-letter code, the other joins with it.
- `Shift+X` and `Shift+B`, the cheats from 2016, skip a scene forward or back.

## Chapters

1. **Het Ontwaken** - bite the graveyard gate open, then find the orange threads in the forest.
2. **Het Huis** - get the key from the crow, then light the candles in the hallway.
3. **De Lachende WC** - bite the toilet while its lid is open.
4. **HELP ZOMBIES** - sneak to the bed while he snores, then keep up in the chase. On the way out a zombie bites him in the behind.
5. **De Arena** - win the canvas back before sunrise. Then the bite kicks in: the thief turns into a giant. He cannot be hurt standing up, so kick the Laughing Toilet's rubber ducks under his feet and bite his head while he lies on his back. Losing restarts the giant fight, not the arena.

## Power-ups

Every scene hides one, somewhere that takes a little effort. Touch it to pick it up.

- **Hersens** (brains): one heart back. At full health they stay where they are. Bats in the forest sometimes drop them, and in the giant fight the Laughing Toilet throws some while the giant is down.
- **Gouden verf** (gold paint): 8 seconds of no damage, and you walk faster.
- **De kip** (the chicken, from the girl's belt in *De Nachtwacht*): 10 seconds of biting twice as far, and bosses take double damage.

Power-ups carry on into the next scene. Their timers stop during cutscenes.

## Test links

For trying one part of the game directly:

- `?scene=giant&nocut=1` starts the giant fight (`&p=2` for two players).
- `?scene=arena&cut=turn&i=3` shows one cutscene line. A scene's outro carries on as in the game, so this one leads into the giant fight.
- `?hp=60` sets the thief's or the giant's leven, `?sun=0.9` the sunrise, `?stun=1` puts the giant on his back.
- `?gold=1` and `?chick=1` give player 1 that power-up, `?talk=z_key` shows a speech bubble, `?idle=1` starts the head-drops-off gag.
- `?end=1` shows the end screen.

## Code

| File | What it does |
|---|---|
| `src/text.js` | All Dutch and English text, and the cutscene scripts |
| `src/sim.js` | The game rules (no drawing) |
| `src/draw.js` | Pixel sprites, backgrounds, HUD, cutscenes |
| `src/fx.js` | Dust, sparks, damage numbers and the little things that move in each scene (drawing only) |
| `src/input.js` | Keyboard, mouse, controller |
| `src/audio.js` | Music and sound effects |
| `src/net.js` | Online co-op (PeerJS) |
| `src/main.js` | The p5.js sketch: loop and menus |
| `test/smoke.js` | Automated playthrough: `node test/smoke.js` |

## Credits

- Original game and idea: Job & Aik, 2016.
- Music: *Night of Chaos*, the track that shipped in the original repository.
- Backgrounds: AI-generated pixel art. Characters and objects are drawn in code.
- *De Nachtwacht*: Rembrandt van Rijn, 1642 (public domain).
- Libraries: p5.js (LGPL), PeerJS (MIT). Fonts: Press Start 2P and VT323 (SIL Open Font License).
- Desktop version: controller support through [Jamepad](https://github.com/williamahartman/Jamepad), which bundles SDL2 (zlib License). The desktop version has no online co-op; use the browser version for that.
- License: [MIT](LICENSE)
