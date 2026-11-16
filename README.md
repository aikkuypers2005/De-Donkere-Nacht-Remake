# De Donkere Nacht 2

A pixel-art tribute to *De Donkere Nacht*, the Processing game Job & Aik made at De Jonge Onderzoekers Groningen in 2016. Built with p5.js, so it runs in a browser.

Two guards of the Night Watch rise as zombies on the darkest night of the year to get back the piece a thief cut out of their painting, before the sun comes up.

## Play

```
node serve.js
```

Then open http://localhost:8123. Opening `index.html` directly from disk does not work, because browsers block the images that way.

The folder is a plain static site, so it can also be hosted as-is (for example on GitHub Pages).

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
4. **HELP ZOMBIES** - sneak to the bed while he snores, then keep up in the chase.
5. **De Arena** - win the canvas back before sunrise.

## Code

| File | What it does |
|---|---|
| `src/text.js` | All Dutch and English text, and the cutscene scripts |
| `src/sim.js` | The game rules (no drawing) |
| `src/draw.js` | Pixel sprites, backgrounds, HUD, cutscenes |
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
