// Drawing for De Donkere Nacht 2: pixel sprites, backgrounds, scenes, cutscenes and HUD.
// Everything is drawn on a 480x270 canvas with whole pixels only.
(function () {
  const DDN = window.DDN, sim = DDN.sim, W = sim.W, H = sim.H, G = sim.G;
  const D = DDN.draw = {};
  let ctx = null;
  const OUT = [12, 10, 22];

  function canvas(w, h) { const c = document.createElement('canvas'); c.width = w; c.height = h; return c; }
  function R(x, y, w, h, c) { ctx.fillStyle = c; ctx.fillRect(Math.round(x), Math.round(y), Math.round(w), Math.round(h)); }
  function disc(c2, cx, cy, r, col) {
    c2.fillStyle = col;
    for (let dy = -r; dy <= r; dy++) {
      const dx = Math.floor(Math.sqrt(r * r - dy * dy) + 0.5);
      c2.fillRect(Math.round(cx - dx), Math.round(cy + dy), dx * 2 + 1, 1);
    }
  }

  // ---------------------------------------------------------------- text
  // Each font is used only at the size it was drawn for, on a whole-pixel baseline, so it stays sharp.
  const FONTS = { ps: { css: "8px 'Press Start 2P'", h: 10, base: 9, big: "64px 'Press Start 2P'" }, vt: { css: "20px 'VT323'", h: 20, base: 15 } };
  const mcv = canvas(4, 4), mctx = mcv.getContext('2d');
  let tcache = new Map();
  function rgb(col) {
    const n = parseInt(col.slice(1), 16);
    return col.length === 4 ? [((n >> 8) & 15) * 17, ((n >> 4) & 15) * 17, (n & 15) * 17] : [n >> 16, (n >> 8) & 255, n & 255];
  }
  function measure(str, font) { mctx.font = FONTS[font].css; return Math.ceil(mctx.measureText(str).width); }
  // Text is drawn once to a small canvas and its soft edges are removed, so it stays sharp when scaled up.
  function textImg(str, font, col) {
    const key = font + col + str;
    let cv = tcache.get(key);
    if (cv) return cv;
    if (tcache.size > 900) tcache = new Map();
    const f = FONTS[font], w = measure(str, font) + 2;
    cv = canvas(Math.max(1, w), f.h);
    const c = cv.getContext('2d'), k = rgb(col);
    const id = c.createImageData(cv.width, cv.height), d = id.data;
    // Draw the text 8 times larger (or at its own size) and read one point per game pixel.
    const z = f.big ? 8 : 1, bc = canvas(cv.width * z, cv.height * z), b = bc.getContext('2d');
    b.font = f.big || f.css; b.textBaseline = 'alphabetic'; b.fillStyle = '#fff';
    b.fillText(str, z, f.base * z);
    const src = b.getImageData(0, 0, bc.width, bc.height).data, half = z >> 1;
    for (let y = 0; y < cv.height; y++) for (let x = 0; x < cv.width; x++) {
      if (src[((y * z + half) * bc.width + x * z + half) * 4 + 3] >= 128) {
        const i = (y * cv.width + x) * 4;
        d[i] = k[0]; d[i + 1] = k[1]; d[i + 2] = k[2]; d[i + 3] = 255;
      }
    }
    c.putImageData(id, 0, 0);
    tcache.set(key, cv);
    return cv;
  }
  // align: 0 left, 1 centre, 2 right. shadow: draw a dark copy underneath.
  function T(str, x, y, col, font, align, scale, shadow) {
    if (!str) return 0;
    font = font || 'vt'; scale = scale || 1;
    const img = textImg(str, font, col || '#ffffff'), w = img.width * scale;
    const dx = Math.round(align === 1 ? x - w / 2 : align === 2 ? x - w : x);
    if (shadow !== false) {
      const sh = textImg(str, font, '#0c0a16');
      ctx.drawImage(sh, dx + scale, Math.round(y) + scale, w, sh.height * scale);
    }
    ctx.drawImage(img, dx, Math.round(y), w, img.height * scale);
    return w;
  }
  function wrap(str, font, maxW) {
    const words = str.split(' '), lines = [];
    let line = '';
    for (const w of words) {
      const t = line ? line + ' ' + w : w;
      if (measure(t, font) > maxW && line) { lines.push(line); line = w; } else line = t;
    }
    if (line) lines.push(line);
    return lines;
  }

  // ---------------------------------------------------------------- sprites
  const SPR = {};
  // Builds a sprite from rectangles and adds a dark outline around it.
  function make(key, w, h, ox, oy, fn, outline) {
    const cv = canvas(w + 2, h + 2), c = cv.getContext('2d');
    const P = (x, y, pw, ph, col) => { c.fillStyle = col; c.fillRect(Math.round(x + ox + 1), Math.round(y + oy + 1), pw, ph); };
    P.disc = (cx, cy, r, col) => disc(c, cx + ox + 1, cy + oy + 1, r, col);
    fn(P);
    if (outline !== false) {
      const id = c.getImageData(0, 0, cv.width, cv.height), d = id.data, s = new Uint8ClampedArray(d), cw = cv.width, ch = cv.height;
      const a = (x, y) => x >= 0 && y >= 0 && x < cw && y < ch && s[(y * cw + x) * 4 + 3] > 0;
      for (let y = 0; y < ch; y++) for (let x = 0; x < cw; x++) {
        if (!a(x, y) && (a(x - 1, y) || a(x + 1, y) || a(x, y - 1) || a(x, y + 1))) {
          const i = (y * cw + x) * 4;
          d[i] = OUT[0]; d[i + 1] = OUT[1]; d[i + 2] = OUT[2]; d[i + 3] = 255;
        }
      }
      c.putImageData(id, 0, 0);
    }
    SPR[key] = { cv, ox: ox + 1, oy: oy + 1 };
  }
  function blit(key, x, y, flip, alpha, scale) {
    const s = SPR[key];
    if (!s) return;
    x = Math.round(x); y = Math.round(y);
    if (alpha != null) ctx.globalAlpha = alpha;
    if (flip || scale) {
      ctx.save(); ctx.translate(x, y); ctx.scale((flip ? -1 : 1) * (scale || 1), scale || 1);
      ctx.drawImage(s.cv, -s.ox, -s.oy); ctx.restore();
    } else ctx.drawImage(s.cv, x - s.ox, y - s.oy);
    if (alpha != null) ctx.globalAlpha = 1;
  }

  const ZC = [
    { body: '#29c44c', dark: '#1b8a36', skin: '#63d97d', sdark: '#3fae5a', hat: '#17171f', band: '#c0302a' },
    { body: '#64c44c', dark: '#479438', skin: '#a2dc7c', sdark: '#7ab85c', hat: '#d8c070', band: '#9a7a2c' }
  ];
  // Gold paint: the same two zombies, in gold.
  const ZG = [
    { body: '#e8b830', dark: '#b8861c', skin: '#f8dc78', sdark: '#d8b048', hat: '#7a5810', band: '#fff0a0' },
    { body: '#f0c840', dark: '#c09020', skin: '#fce488', sdark: '#dcb850', hat: '#c89a30', band: '#8a6414' }
  ];
  // The zombie keeps the 2016 shape: a block body, a round head and one arm stretched out.
  // The hats and collar come from the two captains in the middle of De Nachtwacht.
  function zombie(P, id, o) {
    const c = o.pal || ZC[id], b = o.bob || 0;
    const legs = o.legs || [[-4, 0], [1, 0]];
    for (const [lx, up] of legs) { P(lx, -6 - up, 3, 6, c.dark); P(lx, -1 - up, 4, 1, '#22222a'); }
    P(-5, -18 + b, 10, 13, c.body); P(-5, -18 + b, 2, 13, c.dark);
    P(-3, -5 + b, 2, 1, c.body); P(2, -5 + b, 2, 1, c.body);
    if (id === 0) { P(-3, -17 + b, 2, 2, c.band); P(-1, -15 + b, 2, 2, c.band); P(1, -13 + b, 2, 2, c.band); P(3, -11 + b, 2, 2, c.band); }
    else { P(-5, -10 + b, 10, 2, c.hat); P(-1, -10 + b, 2, 2, c.band); }
    P(-6, -19 + b, 12, 2, '#ebe8da');
    if (!o.nohead) zHead(P, id, c, b, o.mouth);
    const al = o.arm || 8;
    if (o.arm2) { P(3, -13 + b, o.arm2, 2, c.dark); P(3 + o.arm2, -14 + b, 2, 3, c.sdark); }
    P(3, -16 + b, al, 2, c.body); P(3 + al, -17 + b, 2, 3, c.skin);
  }
  // The head and hat on their own, so the head can drop off (the idle gag). b moves it up and down.
  function zHead(P, id, c, b, mouth) {
    P(-4, -29 + b, 8, 10, c.skin); P(-5, -28 + b, 10, 8, c.skin); P(-5, -28 + b, 2, 8, c.sdark); P(-4, -29 + b, 2, 1, c.sdark);
    P(1, -26 + b, 3, 3, '#f6f6e4'); P(3, -25 + b, 1, 1, '#111');
    if (mouth) { P(0, -22 + b, 5, 2, '#3a0a0a'); P(1, -22 + b, 1, 1, '#fff'); P(3, -22 + b, 1, 1, '#fff'); }
    else P(1, -21 + b, 4, 1, '#1a4a22');
    P(-7, -30 + b, 14, 2, c.hat); P(-4, -30 + b - (id ? 3 : 4), 8, id ? 3 : 4, c.hat); P(-4, -31 + b, 8, 1, c.band);
    if (id === 1) P(-6, -36 + b, 2, 5, '#f4f4f4');
  }
  function zombieDown(P, id, pal) {
    const c = pal || ZC[id];
    P(-12, -6, 14, 6, c.body); P(-12, -6, 14, 2, c.dark);
    P(2, -9, 9, 9, c.skin); P(6, -6, 2, 1, '#111'); P(8, -6, 1, 1, '#111'); P(7, -7, 1, 3, '#111');
    P(-17, -3, 5, 3, c.dark); P(12, -4, 8, 2, c.hat); P(14, -7, 5, 3, c.hat);
  }

  const TH = { suit: '#f07a18', dark: '#b85a10', skin: '#8a5a3a', sdark: '#6a4028' };
  // After the bite his skin turns greener in steps (o.sk), and from the chase on he wears a plaster (o.pl).
  const TH1 = { skin: '#7e8a3a', sdark: '#5e6a28' }, TH2 = { skin: '#8cc43c', sdark: '#6a9a2c' };
  function thief(P, o) {
    const b = o.bob || 0, sk = o.sk || TH;
    const legs = o.legs || [[-4, 0], [1, 0]];
    for (const [lx, up] of legs) { P(lx, -7 - up, 3, 7, TH.dark); P(lx, -1 - up, 4, 1, '#3a2418'); }
    if (o.roll) { P(-9, -24 + b, 3, 14, '#dccaa0'); P(-9, -24 + b, 3, 1, '#a08860'); P(-9, -11 + b, 3, 1, '#a08860'); }
    P(-5, -19 + b, 10, 12, TH.suit); P(-5, -19 + b, 2, 12, TH.dark); P(-1, -19 + b, 1, 12, TH.dark);
    if (o.pl) { P(-8, -12 + b, 4, 4, '#ffffff'); P(-7, -11 + b, 2, 2, '#e4d4bc'); }
    P(-4, -28 + b, 8, 9, sk.skin); P(-3, -29 + b, 6, 1, sk.skin); P(-4, -28 + b, 2, 9, sk.sdark);
    if (o.arms === 'ouch') { P(1, -27 + b, 3, 3, '#fff'); P(2, -26 + b, 1, 1, '#111'); }
    else { P(1, -26 + b, 2, 2, '#fff'); P(2, -25 + b, 1, 1, '#111'); }
    if (o.mouth) P(1, -22 + b, 3, 2, '#3a0a0a'); else P(1, -21 + b, 3, 1, '#4a2a1a');
    if (o.arms === 'up') { P(-7, -27 + b, 2, 9, TH.suit); P(5, -27 + b, 2, 9, TH.suit); P(-7, -29 + b, 2, 2, sk.skin); P(5, -29 + b, 2, 2, sk.skin); }
    else if (o.arms === 'throw') { P(-7, -18 + b, 2, 7, TH.suit); P(5, -28 + b, 2, 10, TH.suit); P(5, -30 + b, 3, 2, sk.skin); }
    else if (o.arms === 'knee') { P(-6, -17 + b, 2, 8, TH.suit); P(4, -17 + b, 2, 8, TH.suit); P(8, -27 + b, 1, 2, '#8fd0ff'); P(9, -22 + b, 1, 2, '#8fd0ff'); }
    else if (o.arms === 'ouch') { P(-7, -18 + b, 2, 6, TH.suit); P(-8, -12 + b, 3, 2, sk.skin); P(5, -27 + b, 2, 9, TH.suit); P(5, -29 + b, 2, 2, sk.skin); }
    else if (o.arms === 'itch') {
      // one hand scratching his behind
      P(5, -18 + b, 2, 7, TH.suit); P(-7, -18 + b, 2, 5, TH.suit); P(-8, -13 + b + (o.ih || 0), 3, 2, sk.skin);
      if (o.ih) { P(-10, -15 + b, 1, 1, '#ffffff'); P(-11, -11 + b, 1, 1, '#ffffff'); }
    }
    else { P(-7, -18 + b + (o.swing || 0), 2, 7, TH.suit); P(5, -18 + b - (o.swing || 0), 2, 7, TH.suit); }
  }

  // The giant: the thief after the bite, four times as big. Drawn at full size, facing right, feet at 0,0.
  const GC = { skin: '#8cc43c', sd: '#6a9a2c', deep: '#4a7420', lt: '#b4e06a', suit: '#f07a18', su2: '#b85a10', su3: '#8a3e08',
    tooth: '#f4f0d8', eye: '#f4f0a0', mouth: '#3a0a0a', tongue: '#e8507c', pl: '#f4efe0', pl2: '#d4c4a8', hair: '#2a2a18', nail: '#e8e0a0' };
  function gFist(P, x, y, back) {
    const sk = back ? GC.sd : GC.skin, sd = back ? GC.deep : GC.sd;
    P(x, y, 13, 12, sk); P(x, y + 9, 13, 3, sd); P(x, y, 2, 12, sd);
    P(x + 4, y + 1, 1, 4, sd); P(x + 7, y + 1, 1, 4, sd); P(x + 10, y + 1, 1, 4, sd);
  }
  function gLeg(P, x, up, back) {
    const sk = back ? GC.sd : GC.skin, sd = back ? GC.deep : GC.sd, su = back ? GC.su2 : GC.suit, s2 = back ? GC.su3 : GC.su2;
    P(x, -46 - up, 13, 28, su); P(x, -46 - up, 3, 28, s2);                                        // trouser leg
    P(x + 2, -16 - up, 9, 10, sk); P(x + 2, -16 - up, 2, 10, sd);                                 // shin
    P(x, -7 - up, 18, 7, sk); P(x, -2 - up, 18, 2, sd); P(x, -7 - up, 2, 7, sd);                 // big bare foot
    P(x + 12, -6 - up, 1, 3, sd); P(x + 15, -6 - up, 1, 3, sd); P(x + 16, -7 - up, 2, 1, GC.nail);
    P(x + 1, -18 - up, 3, 2, su); P(x + 7, -18 - up, 4, 3, su); P(x + 5, -18 - up, 1, 1, s2);    // the trousers tore at the knee
  }
  function gHead(P, hx, hy, mouth) {
    P(-4 + hx, -92 + hy, 18, 6, GC.sd);                                                           // neck
    P(-8 + hx, -112 + hy, 24, 22, GC.skin); P(-6 + hx, -114 + hy, 20, 2, GC.skin); P(16 + hx, -108 + hy, 2, 14, GC.skin);
    P(-8 + hx, -112 + hy, 4, 22, GC.sd); P(-6 + hx, -114 + hy, 3, 2, GC.sd);
    P(-3 + hx, -104 + hy, 4, 7, GC.sd); P(-2 + hx, -103 + hy, 2, 5, GC.deep);                    // ear
    P(1 + hx, -117 + hy, 1, 3, GC.hair); P(4 + hx, -118 + hy, 1, 4, GC.hair); P(7 + hx, -117 + hy, 1, 3, GC.hair);
    P(5 + hx, -109 + hy, 12, 2, GC.deep); P(13 + hx, -110 + hy, 4, 1, GC.deep);                   // one big cross eyebrow
    if (mouth === 3) { P(8 + hx, -108 + hy, 6, 5, GC.eye); P(11 + hx, -106 + hy, 2, 2, '#111'); }
    else { P(9 + hx, -106 + hy, 5, 3, GC.eye); P(12 + hx, -105 + hy, 2, 2, '#111'); }
    P(4 + hx, -94 + hy, 15, 4, GC.skin);                                                          // big chin
    if (mouth === 2) {                                                                            // roaring
      P(6 + hx, -100 + hy, 13, 10, GC.mouth); P(8 + hx, -93 + hy, 9, 2, GC.tongue);
      P(7 + hx, -100 + hy, 2, 2, GC.tooth); P(16 + hx, -100 + hy, 2, 2, GC.tooth); P(9 + hx, -92 + hy, 2, 2, GC.tooth); P(14 + hx, -92 + hy, 2, 2, GC.tooth);
      P(4 + hx, -90 + hy, 15, 3, GC.skin);
    } else if (mouth === 3) P(10 + hx, -98 + hy, 6, 5, GC.mouth);                                // surprised
    else if (mouth === 1) { P(7 + hx, -98 + hy, 12, 3, GC.mouth); P(8 + hx, -98 + hy, 10, 1, GC.tooth); }
    else { P(8 + hx, -97 + hy, 10, 2, GC.mouth); P(9 + hx, -99 + hy, 2, 2, GC.tooth); P(15 + hx, -99 + hy, 2, 2, GC.tooth); }
    P(15 + hx, -104 + hy, 5, 6, GC.sd); P(16 + hx, -105 + hy, 3, 1, GC.skin);                    // nose
  }
  function gArmBack(P, X, Y, arm) {
    const sx = -18 + X, sy = -84 + Y;
    if (arm === 'out') { P(sx - 8, sy - 2, 12, 9, GC.su3); P(sx - 20, sy - 8, 14, 8, GC.sd); gFist(P, sx - 32, sy - 18, true); }
    else { P(sx - 5, sy + 2, 10, 14, GC.su3); P(sx - 4, sy + 16, 8, 20, GC.sd); gFist(P, sx - 7, sy + 34, true); }
  }
  function gArm(P, X, Y, arm) {
    const sx = 10 + X, sy = -84 + Y;
    if (arm === 'up') {
      P(sx, sy - 4, 11, 12, GC.suit); P(sx, sy - 4, 2, 12, GC.su2);
      P(sx + 1, sy - 26, 9, 22, GC.skin); P(sx + 1, sy - 26, 2, 22, GC.sd);
      gFist(P, sx - 1, sy - 38);
    } else if (arm === 'down') {
      // reaching down to the sand, the fist lands REACH px in front of him
      for (let i = 0; i < 8; i++) P(sx + 1 + i * 1.5, sy + i * 8, 10, 10, i < 2 ? GC.suit : GC.skin);
      P(sx + 1, sy, 2, 16, GC.su2);
      gFist(P, sim.REACH - 6, -12);
    } else if (arm === 'out') {
      P(sx, sy, 11, 10, GC.suit); P(sx + 8, sy - 6, 14, 8, GC.skin); P(sx + 8, sy - 6, 14, 2, GC.lt);
      gFist(P, sx + 20, sy - 16);
    } else {
      P(sx, sy, 11, 14, GC.suit); P(sx, sy, 2, 14, GC.su2); P(sx + 7, sy + 14, 3, 2, GC.suit);
      P(sx + 1, sy + 14, 9, 22, GC.skin); P(sx + 1, sy + 14, 2, 22, GC.sd);
      gFist(P, sx - 1, sy + 34);
    }
  }
  function gTorso(P, X, Y) {
    P(-20 + X, -86 + Y, 38, 44, GC.suit);                                                         // the suit, stretched tight
    P(18 + X, -78 + Y, 4, 30, GC.suit); P(22 + X, -70 + Y, 2, 16, GC.suit);                      // belly
    P(-23 + X, -56 + Y, 4, 14, GC.suit);                                                          // behind
    P(-20 + X, -86 + Y, 4, 44, GC.su2); P(-23 + X, -56 + Y, 2, 14, GC.su2); P(-18 + X, -44 + Y, 38, 2, GC.su2);
    P(-14 + X, -88 + Y, 30, 3, GC.su2);                                                           // collar
    P(5 + X, -85 + Y, 1, 26, GC.su2);                                                             // zip
    P(6 + X, -58 + Y, 12, 9, GC.skin); P(8 + X, -60 + Y, 7, 2, GC.skin); P(7 + X, -49 + Y, 9, 1, GC.skin); P(12 + X, -54 + Y, 2, 1, GC.deep);
    P(-12 + X, -78 + Y, 6, 4, GC.skin); P(-11 + X, -79 + Y, 3, 1, GC.skin); P(-6 + X, -52 + Y, 4, 3, GC.skin);    // rips
    P(-26 + X, -54 + Y, 7, 8, GC.pl); P(-25 + X, -52 + Y, 4, 4, GC.pl2); P(-26 + X, -54 + Y, 7, 1, '#ffffff');    // the plaster, giant-sized now
  }
  // lf / lb: [forward, lift] of the front and back leg. lean / dip move the upper body.
  function giant(P, o) {
    const X = o.lean || 0, Y = (o.bob || 0) + (o.dip || 0), lf = o.lf || [0, 0], lb = o.lb || [0, 0];
    gArmBack(P, X, Y, o.arm);
    gLeg(P, -16 + lb[0], lb[1], true);
    gLeg(P, 1 + lf[0], lf[1], false);
    gTorso(P, X, Y);
    gHead(P, X + (o.hx || 0), Y + (o.hy || 0), o.mouth || 0);
    gArm(P, X, Y, o.arm);
  }
  function giantSlip(P) {
    gLeg(P, -14, 0, true);
    // the front leg flies up in front of him
    P(-4, -52, 28, 12, GC.suit); P(-4, -42, 28, 2, GC.su2); P(22, -51, 10, 9, GC.skin);
    P(31, -62, 7, 20, GC.skin); P(31, -62, 2, 20, GC.sd); P(32, -64, 2, 2, GC.skin); P(35, -64, 2, 2, GC.skin); P(36, -60, 2, 1, GC.nail);
    P(-46, -98, 8, 18, GC.sd); gFist(P, -50, -110, true);
    // falling over backwards: each slice of the body a bit further back
    for (let i = 0; i < 8; i++) { P(-20 - i * 2, -50 - i * 6, 38, 7, GC.suit); P(-20 - i * 2, -50 - i * 6, 4, 7, GC.su2); }
    P(-2, -64, 10, 7, GC.skin); P(3, -61, 2, 1, GC.deep);
    P(-26, -54, 7, 8, GC.pl); P(-25, -52, 4, 4, GC.pl2);
    gHead(P, -18, 4, 3);
    P(-2, -96, 9, 20, GC.skin); P(-2, -96, 2, 20, GC.sd); gFist(P, -4, -108);
    P(-34, -122, 1, 2, '#8fd0ff'); P(6, -120, 1, 2, '#8fd0ff'); P(10, -114, 1, 2, '#8fd0ff');
  }
  function giantLie(P) {
    // flat on his back: head on the left, feet in the air on the right
    P(6, -22, 28, 12, GC.su2); P(32, -24, 9, 12, GC.sd); P(38, -40, 7, 18, GC.sd); P(38, -42, 2, 2, GC.sd); P(42, -42, 2, 2, GC.sd);
    P(-30, -4, 20, 4, GC.sd);
    P(-38, -26, 46, 24, GC.suit); P(-34, -32, 38, 6, GC.suit); P(-28, -36, 26, 4, GC.suit); P(-22, -38, 14, 2, GC.suit);
    P(-38, -6, 46, 4, GC.su2); P(-38, -26, 3, 20, GC.su2);
    P(-18, -37, 10, 5, GC.skin); P(-14, -35, 2, 1, GC.deep); P(-32, -22, 5, 4, GC.skin); P(-4, -29, 4, 3, GC.skin);
    P(2, -4, 8, 4, GC.pl);                                                                        // the plaster peeks out underneath
    P(4, -18, 30, 12, GC.suit); P(4, -8, 30, 2, GC.su2);
    P(32, -20, 10, 13, GC.skin); P(40, -38, 8, 20, GC.skin); P(40, -38, 2, 20, GC.sd); P(41, -40, 2, 2, GC.skin); P(45, -40, 2, 2, GC.skin); P(45, -36, 2, 1, GC.nail);
    P(-26, -10, 24, 8, GC.skin); P(-26, -10, 24, 2, GC.lt); P(-4, -11, 10, 9, GC.skin); P(5, -10, 3, 2, GC.skin); P(5, -6, 3, 2, GC.skin);
    P(-38, -16, 6, 10, GC.sd);                                                                    // neck
    P(-60, -22, 24, 22, GC.skin); P(-62, -20, 2, 18, GC.skin); P(-60, -4, 24, 4, GC.sd);
    P(-50, -13, 4, 6, GC.sd); P(-49, -12, 2, 4, GC.deep);                                         // ear
    P(-66, -15, 4, 1, GC.hair); P(-67, -12, 5, 1, GC.hair); P(-66, -9, 4, 1, GC.hair);
    P(-57, -26, 5, 4, GC.eye);                                                                    // a dizzy X for an eye
    for (const [x, y] of [[-56, -26], [-54, -26], [-55, -25], [-56, -24], [-54, -24]]) P(x, y, 1, 1, '#111');
    P(-50, -28, 5, 6, GC.sd); P(-49, -29, 3, 1, GC.skin);                                         // nose in the air
    P(-44, -25, 6, 3, GC.mouth); P(-43, -28, 3, 3, GC.tongue); P(-44, -25, 1, 1, GC.tooth); P(-40, -25, 1, 1, GC.tooth);
    P(-38, -24, 3, 4, GC.skin);
  }
  function giantSit(P) {
    // sitting up, dizzy, rubbing the bump on his head
    P(-36, -10, 12, 6, GC.sd); P(-32, -50, 8, 40, GC.sd);
    P(-4, -16, 32, 12, GC.su2); P(26, -14, 10, 12, GC.sd); P(34, -20, 7, 20, GC.sd);
    P(0, -14, 32, 12, GC.suit); P(0, -4, 32, 2, GC.su2); P(28, -12, 10, 12, GC.skin); P(37, -18, 7, 18, GC.skin); P(37, -18, 2, 18, GC.sd); P(42, -20, 2, 2, GC.skin);
    P(-24, -62, 38, 50, GC.suit); P(14, -54, 4, 30, GC.suit); P(-24, -62, 4, 50, GC.su2); P(-18, -64, 30, 3, GC.su2);
    P(2, -40, 10, 8, GC.skin); P(6, -37, 2, 1, GC.deep); P(-12, -54, 5, 3, GC.skin);
    gHead(P, -4, 28, 3);
    P(-12, -86, 4, 3, GC.lt);                                                                     // the bump
    P(8, -62, 9, 12, GC.suit); P(6, -80, 9, 20, GC.skin); P(6, -80, 2, 20, GC.sd); gFist(P, -2, -92);
  }

  function buildSprites() {
    for (let id = 0; id < 2; id++) {
      for (const look of ['', 'g']) {
        const k = 'z' + id + look + '_', pal = look ? ZG[id] : null;
        const mk = (name, o) => make(k + name, 30, 40, 9, 39, P => zombie(P, id, Object.assign({ pal }, o)));
        mk('idle0', {}); mk('idle1', { bob: 1, legs: [[-4, 0], [1, 0]] });
        mk('w0', { legs: [[-6, 1], [2, 0]] }); mk('w1', { bob: 1 }); mk('w2', { legs: [[-3, 0], [3, 1]] }); mk('w3', { bob: 1 });
        mk('jump', { legs: [[-5, 2], [2, 3]], arm: 9 });
        mk('bite', { mouth: 1, arm: 12, arm2: 10, legs: [[-5, 0], [2, 0]] });
        make(k + 'down', 40, 12, 18, 11, P => zombieDown(P, id, pal));
      }
      const k = 'z' + id + '_';
      make(k + 'headless', 30, 40, 9, 39, P => zombie(P, id, { nohead: 1 }));
      make(k + 'head', 16, 20, 8, 19, P => zHead(P, id, ZC[id], 19, 0));      // drawn with its neck at x, y
      make(k + 'icon', 12, 12, 6, 11, P => {
        const c = ZC[id];
        P(-4, -8, 8, 8, c.skin); P(1, -6, 2, 2, '#fff'); P(2, -5, 1, 1, '#111'); P(-6, -9, 12, 2, c.hat); P(-3, -11, 6, 2, c.hat);
      });
    }
    // Thief sets: 't_' as he starts, 'tp_' with the plaster, 'tp1_' and 'tp2_' greener as the arena goes on.
    const TSETS = { '': [TH, false], p: [TH, true], p1: [TH1, true], p2: [TH2, true] };
    for (const set in TSETS) {
      const tk = (name, o) => make('t' + set + '_' + name, 24, 34, 11, 33, P => thief(P, Object.assign({ sk: TSETS[set][0], pl: TSETS[set][1] }, o)));
      tk('r0', { legs: [[-6, 1], [3, 0]], swing: 2, roll: 1 }); tk('r1', { bob: 1, roll: 1 });
      tk('r2', { legs: [[-2, 0], [3, 2]], swing: -2, roll: 1 }); tk('r3', { bob: 1, roll: 1 });
      tk('stand', { roll: 1 }); tk('pant', { bob: 2, arms: 'knee', mouth: 1, roll: 1 });
      tk('throw', { arms: 'throw', mouth: 1, roll: 1 }); tk('scared', { arms: 'up', mouth: 1, roll: 1 });
      tk('scared2', { arms: 'up', mouth: 1 });
      tk('ouch', { arms: 'ouch', mouth: 1, legs: [[-5, 2], [2, 3]], roll: 1 });
      tk('itch0', { arms: 'itch', mouth: 1, bob: 1, roll: 1 }); tk('itch1', { arms: 'itch', mouth: 1, bob: 2, ih: 1, roll: 1 });
    }

    // the giant, one native-size sprite per pose
    const gk = (name, o) => make('g_' + name, 104, 136, 52, 134, P => giant(P, o));
    gk('w0', { lf: [4, 0], lb: [-4, 0] }); gk('w1', { lf: [0, 5], bob: -1 }); gk('w2', { lf: [-4, 0], lb: [4, 0] }); gk('w3', { lb: [0, 5], bob: -1 });
    gk('footup', { lf: [7, 22], lb: [-3, 0], arm: 'out', mouth: 1 });
    gk('stomp', { lf: [7, 0], lb: [-4, 0], bob: 3, mouth: 2 });
    gk('fistup', { lf: [4, 0], lb: [-5, 0], arm: 'up', mouth: 1 });
    gk('fistdown', { lf: [6, 0], lb: [-6, 0], arm: 'down', lean: 8, dip: 6, mouth: 2 });
    gk('roar', { lf: [5, 0], lb: [-5, 0], arm: 'out', mouth: 2, hy: -2 });
    make('g_slip', 104, 136, 52, 134, giantSlip);
    make('g_getup', 104, 136, 52, 134, giantSit);
    make('g_lie', 132, 52, 68, 50, giantLie);
    // what is left after the first sunbeam: dust, rags and the plaster
    make('g_dust', 112, 36, 56, 34, P => {
      P(-46, -6, 92, 6, '#7e8064'); P(-38, -12, 76, 6, '#8e9070'); P(-28, -18, 56, 6, '#9ea07e'); P(-16, -23, 32, 5, '#aeb08c'); P(-8, -26, 16, 3, '#bcbe9a');
      [[-36, -8], [-20, -15], [6, -10], [24, -14], [34, -5], [-6, -20], [12, -21]].forEach(([x, y], i) => P(x, y, 2, 1, i % 2 ? GC.sd : '#6e7056'));
      P(-24, -15, 10, 3, GC.suit); P(-22, -13, 4, 2, GC.su2); P(14, -9, 12, 3, GC.su2); P(16, -10, 6, 1, GC.suit); P(-40, -5, 8, 2, GC.suit);
      P(28, -15, 1, 3, GC.hair); P(30, -16, 1, 4, GC.hair); P(32, -15, 1, 3, GC.hair);
      P(-5, -31, 10, 6, GC.pl); P(-2, -29, 4, 2, GC.pl2); P(-5, -31, 10, 1, '#ffffff');
    });
    make('stone', 12, 10, 6, 5, P => { P(-5, -4, 10, 8, '#9a9488'); P(-5, -4, 10, 2, '#bab4a6'); P(-5, -4, 2, 8, '#7a7468'); P(1, 0, 3, 1, '#6a6458'); });
    make('plaster', 10, 7, 5, 3, P => { P(-5, -3, 10, 7, '#f4efe0'); P(-2, -1, 4, 3, '#d4c4a8'); P(-4, -2, 1, 1, '#d4c4a8'); P(3, 2, 1, 1, '#d4c4a8'); });

    // power-ups: brains, a pot of gold paint, and the dead chicken from the girl's belt in De Nachtwacht
    make('pu_brain', 12, 9, 6, 9, P => {
      P(-5, -8, 10, 7, '#f09ab0'); P(-4, -9, 8, 1, '#f09ab0'); P(-6, -6, 12, 4, '#f09ab0'); P(-5, -2, 10, 1, '#c8607e');
      P(-3, -7, 1, 3, '#c8607e'); P(0, -8, 1, 2, '#c8607e'); P(2, -6, 1, 3, '#c8607e'); P(-1, -4, 3, 1, '#c8607e'); P(-4, -8, 2, 1, '#ffd0dc');
    });
    make('pu_gold', 10, 13, 5, 13, P => {
      P(-4, -8, 8, 8, '#9aa0ac'); P(-4, -8, 2, 8, '#6a707c'); P(-4, -9, 8, 2, '#f8d040'); P(1, -7, 1, 3, '#f8d040'); P(-1, -5, 4, 3, '#f8d040');
      P(2, -13, 1, 5, '#8a5a2c'); P(1, -10, 3, 2, '#f8d040');
    });
    // A plump white hen, side view, drawn from her feet: the pickup, and the one carried in the hand.
    make('pu_chick', 17, 15, 9, 14, P => {
      const Wh = '#f8f6f0', Y = '#f0a020', Rd = '#e02828';
      P(-5, -9, 9, 6, Wh); P(-6, -8, 11, 4, Wh); P(-4, -3, 7, 1, Wh);
      P(-7, -11, 3, 4, Wh); P(-8, -12, 2, 2, Wh);
      P(2, -12, 4, 4, Wh); P(2, -13, 3, 1, Rd); P(3, -14, 1, 1, Rd);
      P(6, -11, 2, 1, Y); P(4, -11, 1, 1, '#111'); P(5, -9, 1, 2, Rd);
      P(-3, -8, 5, 3, '#d8d4cc'); P(-2, -8, 4, 1, '#ebe7df');
      P(-2, -2, 1, 2, Y); P(1, -2, 1, 2, Y); P(-3, 0, 2, 1, Y); P(1, 0, 2, 1, Y);
    });
    // the same hen, standing, as a small HUD icon (drawn from its feet)
    make('chick_i', 11, 10, 5, 10, P => {
      const Wh = '#f8f6f0';
      P(-4, -6, 7, 5, Wh); P(-5, -7, 2, 3, Wh); P(1, -9, 3, 4, Wh); P(4, -7, 2, 1, '#f0a020');
      P(2, -10, 2, 1, '#e02828'); P(3, -8, 1, 1, '#111'); P(-2, -5, 3, 2, '#d0cbc0'); P(-1, -1, 1, 1, '#f0a020'); P(1, -1, 1, 1, '#f0a020');
    });
    // the garden gnome in front of the house, standing and running away
    const gnome = (key, run, f) => make(key, 14, 21, 7, 20, P => {
      P(-4 + (run && f ? 1 : 0), -2 - (run && !f ? 1 : 0), 3, 2, '#5a3a1a'); P(1 - (run && f ? 1 : 0), -2 - (run && f ? 1 : 0), 3, 2, '#5a3a1a');
      P(-4, -9, 8, 7, '#3a6ac8'); P(-4, -9, 2, 7, '#2a4a98'); P(-4, -6, 8, 1, '#2a2a2a');
      P(-3, -12, 6, 5, '#f4f4f4'); P(-2, -14, 4, 3, '#f0c8a0'); P(1, -13, 2, 1, '#e89070'); P(1, -14, 1, 1, '#111');
      P(-3, -16, 6, 2, '#d82828'); P(-2, -18, 4, 2, '#d82828'); P(-1, -20, 2, 2, '#d82828');
      if (run) { P(-6, -14, 2, 5, '#3a6ac8'); P(4, -14, 2, 5, '#3a6ac8'); P(-6, -15, 2, 1, '#f0c8a0'); P(4, -15, 2, 1, '#f0c8a0'); P(0, -11, 2, 2, '#3a0a0a'); P(1, -15, 2, 2, '#fff'); P(2, -14, 1, 1, '#111'); }
    });
    gnome('gnome0', false, 0); gnome('gnome1', true, 0); gnome('gnome2', true, 1);
    // the WANTED poster in the bedroom (the word itself is drawn on top, in the player's language)
    make('poster', 62, 50, 0, 0, P => {
      P(0, 0, 62, 50, '#e8d8a8'); P(0, 0, 62, 1, '#c8b480'); P(0, 49, 62, 1, '#b8a070'); P(61, 0, 1, 50, '#c8b480'); P(54, 44, 8, 6, '#d0bc88');
      P(24, 15, 13, 14, TH.skin); P(24, 15, 3, 14, TH.sdark); P(31, 19, 3, 3, '#fff'); P(32, 20, 1, 1, '#111'); P(31, 25, 4, 1, '#4a2a1a');
      P(20, 29, 21, 6, TH.suit); P(20, 29, 21, 1, TH.dark);
      P(12, 39, 38, 2, '#8a7650'); P(17, 43, 28, 1, '#8a7650'); P(30, 1, 2, 2, '#c03030');
    });
    // the toilet roll on its holder, full and empty
    const holder = (key, full) => make(key, 14, 13, 7, 6, P => {
      P(-6, -1, 2, 4, '#b8bcc8'); P(-6, -1, 12, 1, '#d8dce8');
      if (full) { P(-4, -5, 8, 8, '#f8f8f8'); P(-4, -5, 8, 1, '#ffffff'); P(2, 3, 3, 3, '#f8f8f8'); }
      P(-1, -2, 2, 2, '#c8b090');
    });
    holder('roll1', true); holder('roll0', false);
    // the ghost audience in the arena stands: three shapes (normal, small, tall), calm, cheering or booing
    const ghost = (key, shape, mood) => make(key, 12, 17, 6, 16, P => {
      const c = shape === 1 ? '#e4f4ec' : shape === 2 ? '#ece4ff' : '#e4ecff', k = '#3a3a5a';
      const top = shape === 2 ? -14 : shape === 1 ? -8 : -10, hw = shape === 1 ? 3 : 4;
      P(-hw + 1, top, hw * 2 - 2, -top - 1, c); P(-hw, top + 2, hw * 2, -top - 3, c);
      if (shape === 2) P(-1, top - 1, 2, 1, c);
      for (let x = -hw; x < hw; x += 3) P(x, -2, 2, 2, c);
      const ey = top + (shape === 2 ? 4 : 2);
      if (mood === 1) { P(-hw - 1, top - 1, 1, 4, c); P(hw, top - 1, 1, 4, c); P(-2, ey, 1, 1, k); P(1, ey, 1, 1, k); P(-1, ey + 2, 2, 2, k); }
      else if (mood === 2) { P(-2, ey, 1, 1, k); P(2, ey, 1, 1, k); P(-2, ey + 1, 1, 1, k); P(1, ey + 1, 1, 1, k); P(-2, ey + 3, 4, 1, k); P(-2, ey + 4, 1, 1, k); P(1, ey + 4, 1, 1, k); }
      else { P(-2, ey, 1, 2, k); P(1, ey, 1, 2, k); P(-1, ey + 3, 2, 1, k); }
    }, false);
    for (let s = 0; s < 3; s++) for (let m = 0; m < 3; m++) ghost('ghost' + s + m, s, m);

    const bat = (key, up) => make(key, 20, 12, 10, 7, P => {
      P(-2, -3, 5, 6, '#4a3568'); P(-2, -5, 1, 2, '#4a3568'); P(2, -5, 1, 2, '#4a3568');
      P(-1, -2, 1, 1, '#ff4040'); P(1, -2, 1, 1, '#ff4040');
      if (up) { P(-8, -6, 6, 2, '#5c4480'); P(3, -6, 6, 2, '#5c4480'); P(-6, -4, 4, 2, '#4a3568'); P(3, -4, 4, 2, '#4a3568'); }
      else { P(-8, 0, 6, 2, '#5c4480'); P(3, 0, 6, 2, '#5c4480'); P(-6, -2, 4, 2, '#4a3568'); P(3, -2, 4, 2, '#4a3568'); }
    });
    bat('bat0', true); bat('bat1', false);
    const crow = (key, up) => make(key, 20, 14, 9, 8, P => {
      P(-5, -3, 9, 5, '#20202a'); P(3, -6, 4, 4, '#20202a'); P(7, -5, 2, 1, '#e8a820'); P(5, -5, 1, 1, '#fff');
      P(-8, -2, 3, 2, '#20202a');
      if (up) P(-3, -8, 6, 5, '#34343f'); else P(-3, 0, 6, 4, '#34343f');
    });
    crow('crow0', true); crow('crow1', false);
    const rat = (key, f) => make(key, 18, 8, 9, 7, P => {
      P(-5, -5, 9, 4, '#7c7c86'); P(3, -6, 4, 4, '#7c7c86'); P(4, -8, 2, 2, '#c08a98'); P(6, -4, 1, 1, '#111'); P(7, -3, 1, 1, '#e08aa0');
      P(-9, -3, 4, 1, '#c08a98'); P(f ? -4 : -3, -1, 2, 1, '#55555e'); P(f ? 2 : 1, -1, 2, 1, '#55555e');
    });
    rat('rat0', 0); rat('rat1', 1);

    // The Laughing Toilet. The face is on the inside of the lid, as in the 2016 picture.
    const wc = (key, face) => make(key, 30, 48, 15, 47, P => {
      const w = '#f4f4f8', s = '#c9cfdc';
      P(-6, -8, 12, 8, w); P(-6, -8, 3, 8, s); P(-8, -2, 16, 2, s);
      P(-12, -20, 24, 12, w); P(-11, -8, 22, 1, s); P(-12, -20, 3, 12, s);
      P(-13, -22, 26, 3, w); P(-13, -20, 26, 1, s);
      if (!face) { P(-13, -26, 26, 4, w); P(-13, -23, 26, 1, s); P(-11, -27, 22, 1, w); return; }
      P(-8, -17, 16, 5, '#7ec8f0'); P(-6, -16, 4, 1, '#d8f2ff');
      P(-10, -46, 20, 24, w); P(-11, -44, 22, 20, w); P(-11, -44, 2, 20, s); P(-8, -47, 16, 1, w);
      const k = '#16161e';
      if (face === 'open') {
        P(-7, -41, 5, 6, k); P(-6, -40, 3, 4, '#fff'); P(-5, -39, 2, 2, k);
        P(2, -41, 5, 6, k); P(3, -40, 3, 4, '#fff'); P(3, -39, 2, 2, k);
        P(-8, -44, 4, 1, k); P(4, -44, 4, 1, k);
        P(-8, -33, 16, 2, k); P(-7, -31, 14, 3, k); P(-5, -28, 10, 1, k); P(-3, -30, 6, 2, '#e8507c');
      } else if (face === 'tired') {
        P(-7, -39, 5, 1, k); P(2, -39, 5, 1, k); P(-6, -38, 3, 1, k); P(3, -38, 3, 1, k);
        P(-4, -31, 8, 3, k); P(-2, -29, 4, 2, '#e8507c'); P(8, -43, 1, 2, '#7ec8f0'); P(9, -38, 1, 2, '#7ec8f0');
      } else {
        P(-7, -41, 1, 1, k); P(-6, -40, 1, 1, k); P(-5, -39, 1, 1, k); P(-4, -38, 1, 1, k); P(-4, -41, 1, 1, k); P(-7, -38, 1, 1, k); P(-5, -40, 1, 1, k); P(-6, -39, 1, 1, k);
        P(3, -41, 1, 1, k); P(4, -40, 1, 1, k); P(5, -39, 1, 1, k); P(6, -38, 1, 1, k); P(6, -41, 1, 1, k); P(3, -38, 1, 1, k); P(5, -40, 1, 1, k); P(4, -39, 1, 1, k);
        P(-5, -31, 10, 1, k); P(-6, -30, 2, 1, k); P(4, -30, 2, 1, k);
      }
    });
    wc('wc_closed', null); wc('wc_open', 'open'); wc('wc_tired', 'tired'); wc('wc_hurt', 'hurt');

    make('blob', 8, 8, 4, 4, P => { P.disc(0, 0, 3, '#5db4f0'); P(-1, -2, 2, 1, '#d8f2ff'); });
    const wave = (key, f) => make(key, 16, 14, 8, 14, P => {
      P(-7, -9, 14, 9, '#3f8fe0'); P(-5, -12, 9, 3, '#3f8fe0'); P(-7 + f, -13, 5, 2, '#eaf6ff'); P(-8, -10, 3, 2, '#eaf6ff'); P(-4 + f, -8, 6, 1, '#8fc8ff'); P(-6, -4, 8, 1, '#2a6ab8');
    });
    wave('wave0', 0); wave('wave1', 2);
    make('rock', 8, 8, 4, 4, P => { P.disc(0, 0, 3, '#8a8a92'); P(-2, -2, 2, 2, '#b4b4bc'); P(1, 1, 2, 1, '#5e5e66'); });
    make('pillow', 12, 8, 6, 4, P => { P(-6, -3, 12, 7, '#f0f0f6'); P(-6, 2, 12, 2, '#c4c8d8'); P(-5, -4, 10, 1, '#f0f0f6'); });
    make('lamp', 8, 10, 4, 5, P => { P(-3, -5, 6, 5, '#f4d848'); P(-2, -6, 4, 1, '#f4d848'); P(-1, 0, 2, 4, '#7a5a30'); P(-3, 4, 6, 1, '#7a5a30'); });
    make('log', 16, 10, 8, 10, P => { P(-7, -9, 14, 9, '#7a4a22'); P(-7, -9, 14, 2, '#9a6432'); P(-7, -8, 2, 7, '#c89860'); P(-1, -5, 4, 1, '#5a3414'); P(3, -3, 3, 1, '#5a3414'); });
    make('shock', 14, 10, 7, 10, P => { P(-5, -4, 10, 4, '#d8c090'); P(-3, -8, 6, 4, '#e8d8b0'); P(-6, -2, 3, 2, '#b89868'); P(2, -9, 2, 2, '#e8d8b0'); });
    // Fire, after the fire strip in the 2016 hallway.
    const fire = (key, f) => make(key, 12, 14, 6, 13, P => {
      P(-4, -6, 8, 6, '#f06018'); P(-3, -9 - f, 6, 4, '#f06018'); P(-1 - f, -12, 3, 3, '#f06018');
      P(-2, -5, 5, 5, '#f8b020'); P(-1, -8, 3, 3, '#f8b020'); P(-1, -3, 2, 3, '#fff4b0');
    }, false);
    fire('fire0', 0); fire('fire1', 1); fire('fire2', -1);
    make('duck', 9, 8, 4, 8, P => { P(-4, -4, 8, 4, '#f8d820'); P(0, -8, 4, 4, '#f8d820'); P(4, -6, 2, 1, '#f08020'); P(2, -7, 1, 1, '#111'); });
    const scrap = (key, f) => make(key, 8, 8, 4, 4, P => { P(-3, -3 + f, 5, 2, '#f07a18'); P(-1, -1, 4, 2, '#f07a18'); P(0, 1 - f, 3, 2, '#b85a10'); });
    scrap('scrap0', 0); scrap('scrap1', 1);
    make('key', 10, 6, 5, 3, P => { P(-5, -3, 4, 5, '#f8d040'); P(-4, -2, 2, 3, '#7a5a10'); P(-1, -1, 6, 2, '#f8d040'); P(3, 1, 1, 2, '#f8d040'); P(1, 1, 1, 1, '#f8d040'); });
    make('heart', 7, 6, 0, 0, P => { P(0, 0, 3, 3, '#e8304a'); P(4, 0, 3, 3, '#e8304a'); P(0, 1, 7, 3, '#e8304a'); P(1, 4, 5, 1, '#e8304a'); P(2, 5, 3, 1, '#e8304a'); P(1, 1, 1, 1, '#ffb0b8'); });
    make('heart0', 7, 6, 0, 0, P => { P(0, 0, 3, 3, '#3a3040'); P(4, 0, 3, 3, '#3a3040'); P(0, 1, 7, 3, '#3a3040'); P(1, 4, 5, 1, '#3a3040'); P(2, 5, 3, 1, '#3a3040'); });
    make('roll', 14, 6, 7, 6, P => { P(-7, -5, 14, 5, '#dccaa0'); P(-7, -5, 2, 5, '#a08860'); P(5, -5, 2, 5, '#a08860'); P(-4, -4, 8, 1, '#f0e4c4'); });
    make('sun', 9, 9, 4, 4, P => { P.disc(0, 0, 3, '#f8c830'); P(-1, -1, 2, 2, '#fff0a0'); });

    // things you can stand on or bump into (drawn from their top-left corner)
    make('tomb', 14, 16, 0, 0, P => { P(0, 3, 14, 13, '#8a8e9a'); P(2, 0, 10, 3, '#8a8e9a'); P(1, 1, 12, 2, '#8a8e9a'); P(0, 3, 2, 13, '#646876'); P(4, 5, 6, 1, '#4a4e5a'); P(6, 3, 2, 6, '#4a4e5a'); P(3, 11, 8, 1, '#646876'); });
    make('tomb2', 16, 22, 0, 0, P => { P(0, 10, 16, 12, '#8a8e9a'); P(0, 10, 2, 12, '#646876'); P(6, 0, 4, 10, '#a0a4b0'); P(3, 3, 10, 3, '#a0a4b0'); P(4, 14, 8, 1, '#4a4e5a'); P(4, 17, 6, 1, '#4a4e5a'); });
    make('crate', 18, 18, 0, 0, P => { P(0, 0, 18, 18, '#9a6a34'); P(0, 0, 18, 2, '#c08a48'); P(0, 16, 18, 2, '#6a4420'); P(0, 0, 2, 18, '#6a4420'); P(16, 0, 2, 18, '#6a4420'); P(3, 3, 12, 1, '#6a4420'); P(3, 8, 12, 1, '#6a4420'); P(3, 13, 12, 1, '#6a4420'); });
    make('crate2', 22, 34, 0, 0, P => {
      for (const oy of [0, 17]) { P(0, oy, 22, 17, '#9a6a34'); P(0, oy, 22, 2, '#c08a48'); P(0, oy + 15, 22, 2, '#6a4420'); P(0, oy, 2, 17, '#6a4420'); P(20, oy, 2, 17, '#6a4420'); P(3, oy + 3, 2, 11, '#6a4420'); P(17, oy + 3, 2, 11, '#6a4420'); P(5, oy + 8, 12, 1, '#6a4420'); }
    });
    make('dresser', 36, 24, 0, 0, P => { P(0, 0, 36, 24, '#6a3a1c'); P(0, 0, 36, 2, '#9a5a2c'); P(2, 4, 32, 8, '#84482a'); P(2, 14, 32, 8, '#84482a'); P(16, 7, 4, 2, '#e8c860'); P(16, 17, 4, 2, '#e8c860'); P(0, 22, 4, 2, '#3a1c0c'); P(32, 22, 4, 2, '#3a1c0c'); });
    make('chair', 22, 20, 0, 0, P => { P(0, 0, 22, 20, '#7a4424'); P(0, 0, 22, 3, '#a8643a'); P(0, 3, 2, 17, '#4a2410'); P(20, 3, 2, 17, '#4a2410'); P(9, 8, 4, 4, '#e8c860'); P(2, 17, 18, 3, '#4a2410'); });
    make('shelf', 38, 44, 0, 0, P => {
      P(0, 0, 38, 44, '#5a3018'); P(0, 0, 38, 2, '#8a5028'); P(2, 4, 34, 11, '#2a1408'); P(2, 17, 34, 11, '#2a1408'); P(2, 30, 34, 12, '#2a1408');
      const cols = ['#b83a3a', '#3a6ab8', '#3a9a5a', '#c8a030', '#8a4ab0', '#c86a30'];
      for (let r = 0; r < 3; r++) for (let i = 0; i < 9; i++) { const hh = 7 + ((i * 3 + r) % 4); P(3 + i * 3 + (r === 1 ? 2 : 0), 4 + r * 13 + (11 - hh) + (r === 2 ? 1 : 0), 2, hh, cols[(i + r * 2) % 6]); }
    });
    make('table', 30, 20, 15, 20, P => { P(-15, -20, 30, 3, '#8a5028'); P(-13, -17, 3, 17, '#5a3018'); P(10, -17, 3, 17, '#5a3018'); P(-13, -8, 26, 2, '#5a3018'); });
    make('candle', 6, 10, 3, 10, P => { P(-1, -8, 3, 6, '#f0ead0'); P(0, -9, 1, 1, '#333'); P(-3, -2, 7, 2, '#b89030'); });
    make('branch', 46, 8, 0, 0, P => { P(0, 0, 46, 4, '#6a4424'); P(0, 0, 46, 1, '#8a5c34'); P(2, 4, 10, 2, '#2f9a2a'); P(20, 4, 8, 2, '#2f9a2a'); P(34, 4, 10, 2, '#2f9a2a'); P(6, 6, 4, 1, '#1f7a22'); P(38, 6, 4, 1, '#1f7a22'); });
    make('door', 22, 40, 11, 40, P => { P(-11, -40, 22, 40, '#3a1c0c'); P(-9, -38, 18, 38, '#5a2c14'); P(-7, -36, 6, 14, '#4a2410'); P(1, -36, 6, 14, '#4a2410'); P(-7, -19, 6, 16, '#4a2410'); P(1, -19, 6, 16, '#4a2410'); P(5, -20, 2, 2, '#e8c860'); });
    const gate = (key, st) => make(key, 16, 48, 2, 48, P => {
      const k = '#3a3e4c', l = '#6a7084';
      if (st === 0) { P(-2, -4, 16, 3, k); P(0, -6, 2, 2, l); P(5, -6, 2, 2, l); P(10, -6, 2, 2, l); return; }
      P(-1, -46, 3, 46, k); P(-1, -48, 3, 2, l);
      const lean = st === 3 ? 0 : st === 2 ? 1 : 2;
      for (let i = 0; i < 3; i++) { const x = 4 + i * 3; if (st === 1 && i === 1) continue; P(x + (lean && i ? lean : 0), -42 + i * lean, 1, 42 - i * lean, l); P(x - 1 + (lean && i ? lean : 0), -44 + i * lean, 3, 2, l); }
      P(2, -36, 11, 1, k); P(2, -10, 11, 1, k);
      if (st < 3) P(6, -22, 3, 2, '#c0302a');
    });
    gate('gate3', 3); gate('gate2', 2); gate('gate1', 1); gate('gate0', 0);
    const bed = (key, st) => make(key, 96, 44, 48, 44, P => {
      P(-46, -14, 92, 6, '#7a4a24'); P(-44, -8, 4, 8, '#5a3214'); P(40, -8, 4, 8, '#5a3214');
      P(40, -34, 6, 22, '#7a4a24'); P(40, -36, 6, 2, '#a06a38'); P(-46, -22, 4, 10, '#7a4a24');
      P(-42, -19, 82, 6, '#e8e8f0'); P(26, -24, 14, 6, '#ffffff'); P(26, -19, 14, 1, '#c4c8d8');
      if (st === 'empty') { P(-42, -21, 50, 4, '#5a78c0'); P(-10, -24, 16, 4, '#5a78c0'); P(-42, -18, 60, 4, '#4868b0'); return; }
      P(12, -29, 14, 4, '#dccaa0'); P(12, -29, 2, 4, '#a08860');
      if (st === 'sleep') {
        P(-42, -25, 62, 8, '#5a78c0'); P(-38, -27, 50, 2, '#5a78c0'); P(-42, -18, 62, 4, '#4868b0');
        P(24, -32, 9, 8, TH.skin); P(24, -32, 9, 2, TH.sdark); P(28, -28, 3, 1, '#111'); P(27, -25, 3, 1, '#4a2a1a');
        P(18, -24, 6, 4, TH.suit);
      } else {
        P(-42, -24, 46, 7, '#5a78c0'); P(-42, -18, 46, 4, '#4868b0');
        P(6, -34, 10, 16, TH.suit); P(6, -34, 2, 16, TH.dark);
        P(7, -43, 8, 9, TH.skin); P(7, -43, 2, 9, TH.sdark); P(8, -41, 3, 3, '#fff'); P(8, -40, 1, 1, '#111'); P(9, -36, 3, 2, '#3a0a0a');
        P(0, -32, 6, 2, TH.suit);
      }
    });
    bed('bed_sleep', 'sleep'); bed('bed_awake', 'awake'); bed('bed_empty', 'empty');
    make('grave', 22, 6, 11, 2, P => { P(-9, -1, 18, 4, '#1a0e0c'); P(-11, -2, 5, 3, '#8a4a38'); P(6, -2, 5, 3, '#8a4a38'); P(-7, 2, 14, 1, '#3a1c16'); }, false);
    make('rope', 6, 22, 3, 22, P => { P(-1, -20, 2, 20, '#c8a030'); P(-2, -22, 4, 3, '#e8c860'); P(-3, -2, 6, 2, '#8a6a20'); });
  }

  // ---------------------------------------------------------------- backgrounds
  // gf: how far down the picture the ground starts. The picture is scaled so that lands on G.
  const BGS = { field: 0.758, forest: 0.755, house: 0.755, hall: 0.805, bath: 0.777, bed: 0.777, arena: 0.781 };
  const BG = {};
  let NW = null, NWH = null, nwImg = null;

  function quantize(c, w, h, step) {
    const id = c.getImageData(0, 0, w, h), d = id.data;
    for (let i = 0; i < d.length; i += 4) {
      d[i] = Math.min(255, Math.round(d[i] / step) * step);
      d[i + 1] = Math.min(255, Math.round(d[i + 1] / step) * step);
      d[i + 2] = Math.min(255, Math.round(d[i + 2] / step) * step);
    }
    c.putImageData(id, 0, 0);
  }
  function loadImages() {
    for (const id in BGS) {
      const img = new Image();
      img.onload = () => {
        const cv = canvas(W, H), c = cv.getContext('2d');
        const h = Math.max(H, G / BGS[id]), w = h * img.width / img.height;
        c.imageSmoothingEnabled = true; c.imageSmoothingQuality = 'high';
        c.drawImage(img, (W - w) / 2, 0, w, h);
        quantize(c, W, H, 12);
        BG[id] = cv;
        builtBg = {};
      };
      img.src = 'assets/bg/' + id + '.jpg';
    }
    nwImg = new Image();
    nwImg.onload = () => { NW = painting(false); NWH = painting(true); builtBg = {}; };
    nwImg.src = 'assets/nachtwacht.png';
  }
  // De Nachtwacht as pixel art, whole or with the two captains cut out.
  function painting(hole) {
    const out = {};
    for (const [name, w, h] of [['big', 150, 97], ['small', 84, 54]]) {
      const cv = canvas(w, h), c = cv.getContext('2d');
      c.imageSmoothingEnabled = true; c.imageSmoothingQuality = 'high';
      c.drawImage(nwImg, 0, 0, w, h);
      quantize(c, w, h, 20);
      if (hole) {
        const x0 = Math.round(w * 0.4), x1 = Math.round(w * 0.7), y0 = Math.round(h * 0.28);
        c.fillStyle = '#120d0a'; c.fillRect(x0, y0, x1 - x0, h - y0);
        c.fillStyle = '#e8dcc0';
        for (let y = y0; y < h; y += 3) { c.fillRect(x0 - 1, y, 1, 2); c.fillRect(x1, y + 1, 1, 2); }
        for (let x = x0; x < x1; x += 3) c.fillRect(x, y0 - 1, 2, 1);
      }
      out[name] = cv;
    }
    return out;
  }
  function frame(c, x, y, img) {
    const w = img ? img.width : 84, h = img ? img.height : 54;
    c.fillStyle = '#6a4a10'; c.fillRect(x - 4, y - 4, w + 8, h + 8);
    c.fillStyle = '#d8b040'; c.fillRect(x - 3, y - 3, w + 6, h + 6);
    c.fillStyle = '#f4dc80'; c.fillRect(x - 3, y - 3, w + 6, 1); c.fillRect(x - 3, y - 3, 1, h + 6);
    c.fillStyle = '#6a4a10'; c.fillRect(x - 1, y - 1, w + 2, h + 2);
    if (img) c.drawImage(img, x, y); else { c.fillStyle = '#2a1c10'; c.fillRect(x, y, w, h); }
  }
  function museum(hole) {
    const cv = canvas(W, H), c = cv.getContext('2d');
    c.fillStyle = '#1a2230'; c.fillRect(0, 0, W, H);
    for (let y = 0; y < G; y += 12) { c.fillStyle = y % 24 ? '#1c2534' : '#18202c'; c.fillRect(0, y, W, 12); }
    c.fillStyle = '#243044';
    for (let i = 0; i < 9; i++) { c.fillRect(70 + i * 9, 30 + i * 18, 60, 18); }  // moonlight from a window
    c.fillStyle = '#0e1420'; c.fillRect(0, G - 14, W, 14);
    c.fillStyle = '#2c2420'; c.fillRect(0, G, W, H - G);
    for (let y = G; y < H; y += 9) { c.fillStyle = '#3a302a'; c.fillRect(0, y, W, 1); for (let x = (y * 7) % 40; x < W; x += 40) c.fillRect(x, y, 1, 9); }
    c.fillStyle = '#4a4034'; c.fillRect(0, G, W, 2);
    const set = hole ? NWH : NW;
    frame(c, 165, 60, set ? set.big : null);
    c.fillStyle = '#d8b040'; c.fillRect(215, 166, 50, 7); c.fillStyle = '#3a2a10'; c.fillRect(217, 168, 46, 3);
    return cv;
  }
  let builtBg = {};
  function bg(id) {
    if (id === 'museum' || id === 'museum2') {
      if (!builtBg[id]) builtBg[id] = museum(id === 'museum2');
      ctx.drawImage(builtBg[id], 0, 0);
      blit('rope', 150, G); blit('rope', 330, G);
      R(151, G - 15, 178, 1, '#a02030');
      return;
    }
    const cv = BG[id];
    if (cv) ctx.drawImage(cv, 0, 0);
    else { R(0, 0, W, G, '#0a0a24'); R(0, G, W, H - G, '#763b2e'); }
  }

  // ---------------------------------------------------------------- scene parts
  function flame(x, y, t, small) {
    const f = Math.floor(t / 5) % 3;
    if (small) { R(x - 1, y - 4 - (f === 1 ? 1 : 0), 3, 4 + (f === 1 ? 1 : 0), '#f8a020'); R(x, y - 3, 1, 3, '#fff4b0'); }
    else blit('fire' + f, x, y);
  }
  function hallDecor(v, t, lit) {
    blit('door', 14, G); blit('door', 464, G);
    const set = NWH;
    ctx.save(); ctx.translate(203, 96); frame(ctx, 0, 0, set ? set.small : null); ctx.restore();
    blit('table', 60, G);
    const cs = v ? v.c : [{ x: 60, y: 192, lit: 1 }, { x: 168, y: 152, lit: 1 }, { x: 312, y: 182, lit: 1 }, { x: 398, y: 130, lit: 1 }];
    for (const s of sim.SC.hall.solids) blit(s.k, s.x, s.y);
    cs.forEach((c, i) => {
      if (i > 0) { R(c.x - 4, c.y + 2, 9, 2, '#8a6a20'); R(c.x - 1, c.y + 4, 2, 5, '#8a6a20'); }
      blit('candle', c.x, c.y + 4);
      if (c.lit || lit) flame(c.x, c.y - 5, t + i * 7, true);
    });
  }
  let darkCv = null;
  function darkness(S, t) {
    const v = S.v;
    if (!darkCv) darkCv = canvas(W, H);
    const c = darkCv.getContext('2d');
    c.globalCompositeOperation = 'source-over';
    c.clearRect(0, 0, W, H);
    c.fillStyle = 'rgba(4,4,14,' + (0.94 - v.lit * 0.2) + ')';
    c.fillRect(0, 0, W, H);
    c.globalCompositeOperation = 'destination-out';
    const hole = (x, y, r) => {
      const fl = (Math.floor(t / 6) % 2);
      disc(c, x, y, r + fl, 'rgba(0,0,0,0.4)'); disc(c, x, y, Math.round(r * 0.72), 'rgba(0,0,0,0.5)'); disc(c, x, y, Math.round(r * 0.45), 'rgba(0,0,0,0.8)');
    };
    for (const k of v.c) if (k.lit) hole(k.x, k.y, 46);
    for (const p of S.players) hole(p.x, p.y - 16, p.carry > 0 ? 36 : 15);
    ctx.drawImage(darkCv, 0, 0);
  }
  function chaseBack(v) {
    const d = v.dist;
    for (let i = 0; i < 8; i++) {                       // far trees
      const x = ((i * 97 - d * 0.35) % 620 + 620) % 620 - 70;
      R(x + 9, G - 44, 5, 44, '#161a2c'); disc(ctx, x + 11, G - 50, 14, '#161a2c');
    }
    for (let i = 0; i < 7; i++) {                       // fence posts
      const x = ((i * 80 - d) % 560 + 560) % 560 - 40;
      R(x, G - 14, 3, 14, '#4a2c20'); R(x - 1, G - 15, 5, 2, '#6a4030'); R(x + 3, G - 10, 77, 1, '#3a2018');
    }
    for (let i = 0; i < 26; i++) {                      // ground speckles
      const x = ((i * 53 - d) % 520 + 520) % 520 - 20, y = G + 6 + (i * 37) % 44;
      R(x, y, 4 + (i % 3) * 2, 1, i % 2 ? '#5e2e24' : '#8a4a3a');
    }
  }

  function zPose(S, p) {
    if (p.down > 0) return 'down';
    if (p.bite > 0) return 'bite';
    if (!p.g) return 'jump';
    const run = sim.SC[S.scene] && sim.SC[S.scene].running;
    if (Math.abs(p.vx) > 0.2 || run) return 'w' + (Math.floor(S.tick / 6) % 4);
    return 'idle' + (Math.floor(S.tick / 30 + p.id) % 2);
  }
  // The idle gag: the head drops off, lies on the floor a moment, and is put back. gt counts 0..100.
  function headGag(p, gt) {
    const f = p.face < 0, k = 'z' + p.id + '_';
    let hx = p.x, hy = p.y - 19;
    if (gt < 24) { const q = gt / 24; hx = p.x + p.face * q * 10; hy = p.y - 19 + Math.round(19 * q * q); }
    else if (gt < 70) { hx = p.x + p.face * 10; hy = p.y - (gt < 32 ? Math.round(Math.sin((gt - 24) / 8 * Math.PI) * 4) : 0); }
    else { const q = (gt - 70) / 30; hx = p.x + p.face * 10 * (1 - q); hy = p.y - Math.round(19 * q); }
    blit(k + 'headless', p.x, p.y, f);
    blit(k + 'head', hx, hy, f);
  }
  function drawPlayers(S, t) {
    for (const p of S.players) {
      if (p.inv > 0 && p.down === 0 && Math.floor(t / 3) % 2) continue;
      const pose = zPose(S, p), gt = p.idle - sim.IDLE_GAG;
      // gold paint: a gold zombie with sparkles, flickering in the last 2 seconds
      const gold = p.gold > 0 && pose !== 'down' && (p.gold > 120 || Math.floor(t / 6) % 2);
      if (gt >= 0 && gt < 100 && pose.startsWith('idle')) headGag(p, gt);
      else blit('z' + p.id + (gold ? 'g' : '') + '_' + pose, p.x, p.y, p.face < 0);
      if (gold) for (let i = 0; i < 3; i++) {
        const sx = p.x + ((t * 7 + i * 37) % 22) - 11, sy = p.y - 6 - ((t * 3 + i * 19) % 28);
        R(sx, sy, 1, 1, '#fff8c0'); if ((t + i * 5) % 12 < 4) { R(sx - 1, sy, 3, 1, '#fff8c0'); R(sx, sy - 1, 1, 3, '#fff8c0'); }
      }
      // the chicken hangs from his outstretched hand
      if (p.chick > 0 && p.down === 0 && (p.chick > 120 || Math.floor(t / 6) % 2) && !(gt >= 0 && gt < 100)) {
        const al = pose === 'bite' ? 12 : pose === 'jump' ? 9 : 8, b = pose === 'idle1' || pose === 'w1' || pose === 'w3' ? 1 : 0;
        blit('pu_chick', p.x + p.face * (5 + al), p.y - 3 + b, p.face < 0);       // carried by her back
      }
      if (p.carry > 0 && (p.carry > 120 || Math.floor(t / 4) % 2)) flame(p.x + p.face * 12, p.y - 17, t, false);
      if (p.down > 0 && S.two) T(String(Math.max(0, Math.ceil((240 - p.down) / 60))), p.x, p.y - 26, '#ffffff', 'ps', 1);
    }
  }
  // The ghost audience in the arena stands. It cheers, boos and does a wave, all read from S.v.
  // The crowd is placed once from a fixed seed: uneven seats, a few empty ones, three kinds of ghost.
  let CROWD = null;
  function crowdSeats() {
    if (CROWD) return CROWD;
    CROWD = [];
    let seed = 7;
    const r = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    [170, 151, 133].forEach((y, row) => {
      for (let x = 10 + row * 7 + Math.floor(r() * 8); x < W - 6; x += 15 + Math.floor(r() * 20)) {
        if (r() < 0.18) continue;
        const s = r() < 0.22 ? 1 : r() < 0.28 ? 2 : 0;
        CROWD.push({ x, y: y + Math.floor(r() * 3), s, ph: Math.floor(r() * 120), f: r() < 0.5 });
      }
    });
    return CROWD;
  }
  function ghosts(S, tx, t) {
    const v = S.v, wavePos = v.wave > 0 ? (150 - v.wave) / 150 * (W + 60) - 30 : -999;
    crowdSeats().forEach((c, i) => {
      if (S.scene === 'giant' && c.x > sim.WC_X - 24) return;              // the toilet's seat
      const inWave = Math.abs(c.x - wavePos) < 24;
      const mood = v.boo > 0 ? 2 : v.cheer > 0 || inWave ? 1 : 0;
      const up = inWave ? 5 : v.cheer > 0 ? ((Math.floor(t / 5) + i) % 2) * 2 : (Math.floor((t + c.ph * 7) / 45) % 3 === 0 ? 1 : 0);
      blit('ghost' + c.s + mood, c.x, c.y - up, c.f, 0.55);
    });
    if (v.cheer > 0) { T(tx.cheer, 110, 104, '#e4ecff', 'ps', 1); T(tx.cheer, 330, 112, '#e4ecff', 'ps', 1); }
    else if (v.boo > 0) { T(tx.boo, 130, 106, '#e4ecff', 'ps', 1); T(tx.boo, 310, 110, '#e4ecff', 'ps', 1); }
  }

  function drawScene(S, t, tx) {
    const v = S.v, id = S.scene, sc = sim.SC[id];
    bg(id === 'chase' ? 'field' : id === 'giant' ? 'arena' : id);
    if (id === 'chase') chaseBack(v);
    if (id === 'arena' || id === 'giant') ghosts(S, tx, t);
    if (id === 'field') {
      blit('grave', 30, G); blit('grave', 52, G);
      blit('gate' + Math.max(0, v.gate), 398, G);
    }
    if (id === 'hall') hallDecor(v, t, false);
    else for (const s of sc.solids) blit(s.k, s.x, s.y);
    for (const p of sc.plats) blit('branch', p.x, p.y);
    if (id === 'forest') for (const s of v.sc) if (!s.got) { blit('scrap' + (Math.floor(t / 12) % 2), s.x, s.y + Math.round(Math.sin(t / 15 + s.x) * 1.5)); }
    if (id === 'house' && v.key && Math.floor(t / 20) % 2) T('v', sim.DOOR, 150, '#f8d040', 'ps', 1);
    if (id === 'bath') {
      // the toilet roll, and once bitten the paper all over the floor
      blit(v.roll ? 'roll0' : 'roll1', sim.ROLL_X, 198);
      if (v.roll) {
        R(sim.ROLL_X + 1, 201, 3, G - 201, '#f4f4f4');
        const len = Math.round(v.paper);
        R(sim.ROLL_X + 4 - len, G - 2, len, 2, '#f4f4f4');
        for (let x = sim.ROLL_X - 4; x > sim.ROLL_X + 4 - len; x -= 8) R(x, G - 2, 1, 2, '#c8ccd8');
      }
    }
    if (id === 'bed') {
      blit('poster', 300, 68);
      T(tx.wanted, 331, 70, '#7a2010', 'ps', 1, 1, false);
      for (const d of v.d) blit('duck', d.x, G - (d.cd > 40 ? 1 : 0));
      blit(v.ph === 'listen' ? 'bed_awake' : 'bed_sleep', 392, G);
      if (v.ph === 'snore') {
        const k = Math.floor(t / 20) % 3; for (let i = 0; i <= k; i++) T('Z', 420 + i * 8, 170 - i * 10, '#ffffff', 'ps');
        // he talks in his sleep
        const s = tx['s_' + v.mum];
        if (s) { const w = textImg(s, 'vt', '#2a2a5a').width; T(s, Math.min(400, W - 4 - w / 2), 126, '#2a2a5a', 'vt', 1, 1, false); }
      }
      else if (v.ph === 'stir') T('?', 418, 158, '#f8d040', 'ps', 0, 2);
      else T('!', 418, 150, '#ff4040', 'ps', 0, 2);
    }
    if (id === 'chase') {
      blit('tp_' + (v.thr > 0 ? 'throw' : 'r' + (Math.floor(t / 5) % 4)), 432, G, v.thr > 0);
    }
    if (id === 'giant') {
      // the Laughing Toilet watches from the stands, the canvas lies where the thief threw it
      blit('wc_open', sim.WC_X + (v.wsT > 0 ? Math.floor(t / 4) % 2 : 0), sim.WC_Y - (v.wt > 0 ? 3 : 0));
      blit('roll', 22, G);
      // shadows: where a stone will land, and where the fist will come down
      const shadow = (x, w, a) => { const c = 'rgba(30,10,6,' + a.toFixed(2) + ')'; R(x - w / 2, G - 1, w, 5, c); R(x - w / 2 + 3, G - 2, w - 6, 7, c); };
      for (const e of S.ents) {
        if (e.type === 'stone') shadow(e.x, 8 + Math.round(Math.max(0, Math.min(1, (e.y - 50) / (G - 50))) * 8), 0.5);
        else if (e.type === 'giant' && e.st === 'fist' && e.t < sim.FIST_UP) {
          const k = e.t / sim.FIST_UP, w = 16 + Math.round(k * 14);
          shadow(e.fx, w, 0.3 + 0.3 * k);
          if (e.t > sim.FIST_UP - 16 && Math.floor(t / 3) % 2) { R(e.fx - w / 2, G - 2, 2, 7, '#e8304a'); R(e.fx + w / 2 - 2, G - 2, 2, 7, '#e8304a'); }
        }
      }
    }

    for (const e of S.ents) {
      const a = Math.floor(t / 6) % 2;
      switch (e.type) {
        case 'bat': case 'cbat': blit('bat' + (Math.floor(t / 5) % 2), e.x, e.y); break;
        case 'crow':
          if (e.inv > 0 && a) break;
          blit('crow' + (Math.floor(t / 7) % 2), e.x, e.y, e.dir < 0);
          if (e.hp > 0) blit('key', e.x + e.dir * 8, e.y + 3);
          break;
        case 'key': blit('key', e.x, e.y + Math.round(Math.sin(t / 8))); break;
        case 'pow': {
          const bob = e.air || e.vx ? 0 : Math.round(Math.sin(t / 10 + e.x) * 1.5) - 1;
          if (e.kind === 'chick') blit('pu_chick', e.x, e.y + bob); else blit('pu_' + e.kind, e.x, e.y + bob);
          if (Math.floor((t + e.x) / 16) % 3 === 0) R(e.x + 4, e.y - 15 + bob, 1, 1, '#ffffff');
          break;
        }
        case 'gnome':
          blit(e.st === 'run' ? 'gnome' + (1 + Math.floor(t / 4) % 2) : 'gnome0', e.x, G, e.dir < 0);
          if (e.st === 'run' && e.t < 50) T('!', e.x, G - 36, '#ffffff', 'ps', 1);
          break;
        case 'rat': blit('rat' + (Math.floor(t / 4) % 2), e.x, G, e.dir < 0); break;
        case 'wc': {
          const open = e.st === 'spit' || e.st === 'tired';
          const sx = e.st === 'laugh' || e.st === 'flush' ? (Math.floor(t / 3) % 2) : 0;
          if (e.inv > 0 && a) break;
          blit(e.st === 'ouch' ? 'wc_hurt' : e.st === 'tired' ? 'wc_tired' : open ? 'wc_open' : 'wc_closed', e.x + sx, G);
          if (e.st === 'laugh') T(['HA', 'HA HA', 'HA HA HA'][Math.floor(e.t / 12) % 3], e.x - 4, 150 - (Math.floor(t / 6) % 2), '#ffffff', 'ps', 1);
          if (e.st === 'flush' && e.t < 40) { for (let i = 0; i < 3; i++) R(e.x - 14 - i * 5 - (t % 6), G - 4 - i * 3, 3, 1, '#7ec8f0'); T('!', e.x, 154, '#7ec8f0', 'ps', 1, 2); }
          break;
        }
        case 'blob': blit('blob', e.x, e.y); break;
        case 'wave': case 'shock': blit(e.type === 'wave' ? 'wave' + a : 'shock', e.x, G, e.vx > 0); break;
        case 'rock': blit('rock', e.x, e.y); break;
        case 'pillow': blit('pillow', e.x, e.y); break;
        case 'lamp': blit('lamp', e.x, e.y); break;
        case 'log': blit('log', e.x, G); break;
        case 'fire': blit('fire' + (Math.floor(t / 5) % 3), e.x, G); break;
        case 'fball': blit('fire' + (Math.floor(t / 4) % 3), e.x, e.y + 6); break;
        case 'thief': {
          if (e.inv > 0 && a) break;
          // greener as his leven drops, and itching when he stops to catch his breath
          const set = 'tp' + (e.hp > 700 ? '' : e.hp > 350 ? '1' : '2') + '_';
          let k = 'stand';
          if (e.st === 'pant') k = 'itch' + (Math.floor(t / 6) % 2);
          else if (!e.g) k = 'scared';
          else if (e.st === 'atk') k = (e.t % 55) > 15 && (e.t % 55) < 35 ? 'throw' : 'stand';
          else if (Math.abs(e.vx) > 0.1) k = 'r' + (Math.floor(t / 5) % 4);
          blit(set + k, e.x, e.y, e.face < 0);
          if (e.st === 'pant') T('...', e.x, e.y - 44, '#ffffff', 'ps', 1);
          break;
        }
        case 'giant': {
          let k = 'w0';
          if (e.st === 'walk') k = e.mv ? 'w' + (Math.floor(e.walk / 6) % 4) : 'w0';
          else if (e.st === 'stomp') k = e.t < sim.STOMP_UP ? 'footup' : 'stomp';
          else if (e.st === 'fist') k = e.t < sim.FIST_UP ? 'fistup' : 'fistdown';
          else if (e.st === 'slip') k = 'slip';
          else if (e.st === 'down') k = 'lie';
          else if (e.st === 'getup') k = 'getup';
          else if (e.st === 'roar') k = 'roar';
          if (!(e.st === 'down' && e.inv > 20 && a)) blit('g_' + k, e.x, G, e.face < 0);
          if (e.st === 'down') {
            const hx = e.x - e.face * 48;
            for (let i = 0; i < 3; i++) { const an = t / 9 + i * 2.1; R(hx + Math.cos(an) * 12 - 1, G - 36 + Math.sin(an) * 3, 3, 3, '#f8d040'); }
            // bites left before he gets up
            for (let i = 0; i < sim.MAX_BITES; i++) R(hx - 12 + i * 5, G - 46, 3, 3, i < e.bites ? '#3a3040' : '#ffffff');
          }
          break;
        }
        case 'duck': blit('duck', e.x, e.st === 'ground' ? G : e.y, e.st === 'fly' ? Math.floor(t / 4) % 2 === 0 : e.vx < 0); break;
        case 'stone': blit('stone', e.x, e.y); break;
      }
    }
    drawPlayers(S, t);
    if (id === 'hall') darkness(S, t);
    if (id === 'arena' || id === 'giant') { ctx.fillStyle = 'rgba(255,150,60,' + (Math.min(1, v.sun) * 0.32).toFixed(3) + ')'; ctx.fillRect(0, 0, W, H); }
  }

  // ---------------------------------------------------------------- HUD
  function bar(x, y, w, h, f, col, back) {
    R(x - 1, y - 1, w + 2, h + 2, '#0c0a16'); R(x, y, w, h, back || '#2a2438'); R(x, y, Math.round(w * Math.max(0, Math.min(1, f))), h, col);
  }
  // HUD text on a dark see-through strip, so it reads on any background (like the white bedroom wall).
  function label(s, x, y, col, font, align) {
    if (!s) return;
    const w = textImg(s, font, col).width, lx = align === 1 ? x - w / 2 : align === 2 ? x - w : x;
    if (font === 'vt') R(lx - 4, y + 2, w + 7, 17, 'rgba(8,8,20,0.55)'); else R(lx - 3, y - 1, w + 5, 11, 'rgba(8,8,20,0.55)');
    T(s, x, y, col, font, align);
  }
  function drawHud(S, tx, t) {
    const sc = sim.SC[S.scene], v = S.v;
    let y = 6;
    for (const p of S.players) {
      if (p.ai) continue;
      blit('z' + p.id + '_icon', 12, y + 9);
      for (let i = 0; i < 3; i++) blit(i < p.hp ? 'heart' : 'heart0', 22 + i * 9, y + 1);
      // power-up timers next to the hearts (right of the boss bar in the arena), blinking in the last 2 seconds
      const boss = S.scene === 'arena' || S.scene === 'giant', step = boss ? 25 : 32, bw = boss ? 10 : 16;
      let px = boss ? 424 : 54;
      for (const [kind, left, max, col] of [['gold', p.gold, sim.GOLD_T, '#f8d040'], ['chick', p.chick, sim.CHICK_T, '#f4f0e8']]) {
        if (left <= 0) continue;
        if (left > 120 || Math.floor(t / 6) % 2) {
          if (kind === 'chick') blit('chick_i', px + 4, y + 10); else blit('pu_gold', px + 3, y + 11);
          bar(px + 10, y + 4, bw, 3, left / max, col);
        }
        px += step;
      }
      y += 13;
    }
    const g = sc.goal(S);
    const goalText = tx[g.k] + (g.of ? '  ' + g.n + '/' + g.of : '');
    let gy = 5;
    if (S.scene === 'arena' || S.scene === 'giant') {
      const th = S.ents.find(e => e.type === 'thief' || e.type === 'giant'), hp = th ? th.hp : 0;
      bar(60, 6, 360, 6, hp / 1000, '#e8304a');                 // the leven = 1000 bar from 2016
      label(tx.leven + ' ' + hp, 240, 14, '#ffffff', 'ps', 1);
      bar(180, 30, 120, 3, v.sun, '#f8c830');
      blit('sun', 180 + Math.round(120 * Math.min(1, v.sun)), 31);
      label(tx.sun, 176, 26, '#f8c830', 'ps', 2);
      gy = 36;
    }
    label(goalText, 240, gy, '#ffffff', 'vt', 1);
    if (g.bar != null) { bar(170, 28, 140, 4, g.bar, '#f07a18'); label(tx.dist, 316, 25, '#f07a18', 'ps'); }
    if (S.scene === 'bed') {
      bar(180, 28, 120, 5, v.noise / 100, v.noise > 60 ? '#e8304a' : '#f8c830');
      label(tx.noise, 176, 26, '#ffffff', 'ps', 2);
    }
    if (S.scene === 'giant') {
      const g = S.ents.find(e => e.type === 'giant');
      if (g && g.st === 'roar' && g.t < 55) T(tx.roar, Math.max(80, Math.min(W - 80, g.x)), G - 134 + (Math.floor(t / 3) % 2), '#ffffff', 'ps', 1, 2);
      // the Laughing Toilet heckles from the stands (above the giant's head, under the goal).
      // Positioned by the width of the text image itself, so the whole line stays on screen.
      if (v.wsT > 0 && tx[v.ws]) { const s = tx[v.ws], w = textImg(s, 'vt', '#7ec8f0').width + 1; T(s, Math.min(sim.WC_X + w / 2, W - 4), 58, '#7ec8f0', 'vt', 2); }
    }
    if (S.msgT > 0 && S.msg) label(tx[S.msg], 240, 62, '#f8d040', 'vt', 1);
    // what a zombie says: a small speech bubble over his head (at most 150 px wide). Its border stays 3 px
    // inside the screen, and it is never drawn over the toilet's flush warning (the giant's warnings clear it in sim).
    const flushing = S.ents.some(e => e.type === 'wc' && e.st === 'flush' && e.t < 60);
    if (S.talk && S.mode === 'play' && !flushing && S.players[S.talk.who] && tx[S.talk.k]) {
      const p = S.players[S.talk.who], lines = wrap(tx[S.talk.k], 'vt', 138);
      const w = Math.min(150, Math.max(...lines.map(l => measure(l, 'vt'))) + 10), h = lines.length * 13 + 6;
      const bx = Math.round(Math.max(4, Math.min(W - 4 - w, p.x - w / 2))), by = Math.round(Math.max(40, p.y - 40 - h));
      R(bx - 1, by - 1, w + 2, h + 2, '#0c0a16'); R(bx, by, w, h, '#f4f4ec');
      const tx0 = Math.round(Math.max(bx + 3, Math.min(bx + w - 6, p.x - 1)));
      R(tx0 - 1, by + h + 1, 5, 1, '#0c0a16'); R(tx0, by + h, 3, 1, '#f4f4ec'); R(tx0, by + h + 1, 3, 1, '#f4f4ec'); R(tx0 + 1, by + h + 2, 1, 2, '#0c0a16');
      lines.forEach((l, i) => T(l, bx + 5, by - 2 + i * 13, '#1a1a24', 'vt', 0, 1, false));
    }
    if (S.hint) {
      const s = tx[S.hint], w = measure(s, 'vt');
      const hot = S.hint === 'h_still';
      R(240 - w / 2 - 6, 248, w + 12, 18, hot ? 'rgba(160,20,30,0.85)' : 'rgba(8,8,20,0.7)');
      T(s, 240, 246, hot && Math.floor(t / 8) % 2 ? '#ffd0d0' : '#ffffff', 'vt', 1);
    }
  }

  // ---------------------------------------------------------------- cutscenes
  function drawCut(S, tx, t) {
    const c = S.cut, st = DDN.CUTS[c.id][c.i];
    if (st.card) {
      R(0, 0, W, H, '#07060e');
      const a = Math.min(1, c.t / 25);
      ctx.globalAlpha = a;
      T(tx.chapter + ' ' + st.card, 240, 96, '#9a94b8', 'ps', 1, 1, false);
      T(tx['ch' + st.card], 240, 116, '#ffffff', 'ps', 1, 2);
      R(160, 144, 160, 1, '#c0302a');
      blit('z0_idle0', 226, 190); blit('z1_idle0', 248, 190);
      ctx.globalAlpha = 1;
      return;
    }
    const base = st.bg === 'hall_lit' ? 'hall' : st.bg === 'arena_dawn' ? 'arena' : st.bg;
    bg(base);
    if (st.bg === 'hall_lit') hallDecor(null, t, true);
    if (st.bg === 'field') { blit('grave', 30, G); blit('grave', 52, G); blit('tomb', 140, 200); blit('tomb2', 245, 194); blit('gate3', 398, G); }
    if (st.bg === 'house') { for (const s of sim.SC.house.solids) blit(s.k, s.x, s.y); }
    if (st.bg === 'arena_dawn') { ctx.fillStyle = 'rgba(255,150,60,0.3)'; ctx.fillRect(0, 0, W, H); }
    let spx = null;
    for (const [kind, x, pose, flip, look] of st.a) {
      const speaks = (st.who === 'z1' && kind === 'z0') || (st.who === 'z2' && kind === 'z1') || (st.who === 't' && (kind === 'thief' || (kind === 'bed' && pose === 'awake'))) ||
        (st.who === 'wc' && (kind === 'wc' || kind === 'wcs')) || (st.who === 'g' && (kind === 'giant' || kind === 'grow'));
      if (kind === 'z0' || kind === 'z1') {
        if (pose === 'rise') {
          const up = Math.max(0, 34 - c.t * 0.6);
          ctx.save(); ctx.beginPath(); ctx.rect(0, 0, W, G); ctx.clip();
          blit(kind + '_idle0', x + (up > 0 ? Math.floor(t / 3) % 2 : 0), G + up, flip);
          ctx.restore();
        } else blit(kind + '_' + (pose === 'bite' ? 'bite' : 'idle' + (Math.floor(t / 30) % 2)), x, G, flip);
        if (speaks) spx = [x, G - 44];
      } else if (kind === 'thief') {
        const away = pose === 'run' || pose === 'flee';
        const k = pose === 'run' ? 'r' + (Math.floor(t / 5) % 4) : pose === 'flee' || pose === 'giveup' ? 'scared2' : pose === 'itch' ? 'itch' + (Math.floor(t / 6) % 2) : pose;
        const dx = away ? Math.min(pose === 'flee' ? 220 : 60, c.t * 1.8) : 0;
        const dy = pose === 'flee' ? Math.floor(t / 4) % 2 : pose === 'ouch' ? Math.round(Math.abs(Math.sin(c.t / 7)) * 8) : 0;
        blit('t' + (look || '') + '_' + k, x + dx, G - dy, flip);
        if (speaks) spx = [x, G - 40];
      } else if (kind === 'giant' || kind === 'grow') {
        // 'grow' flickers between the itching thief and the giant, faster and faster
        const big = kind === 'giant' || c.t > 100 || Math.floor(c.t / Math.max(2, 12 - c.t / 10)) % 2 === 1;
        const k = pose === 'walk' ? 'w' + (Math.floor(t / 8) % 4) : pose || 'w0';
        const head = x + (flip ? 48 : -48);
        if (!big) blit('tp2_itch' + (Math.floor(t / 6) % 2), x, G, flip);
        else blit('g_' + k, x, G, flip);
        if (big && k === 'lie') for (let i = 0; i < 3; i++) { const an = t / 9 + i * 2.1; R(head + Math.cos(an) * 12 - 1, G - 36 + Math.sin(an) * 3, 3, 3, '#f8d040'); }
        if (big && k === 'dust') {
          for (let i = 0; i < 10; i++) {
            const py = G - 6 - ((c.t * 0.4 + i * 11) % 60), px = x - 40 + ((i * 23) % 80) + Math.round(Math.sin((c.t + i * 20) / 15) * 3);
            R(px, py, 2, 2, i % 3 ? '#aeb08c' : GC.skin);
          }
        }
        if (speaks) spx = k === 'lie' ? [head, G - 44] : [x, G - 128];
      } else if (kind === 'wcs') {
        // the Laughing Toilet up in the arena stands
        const j = pose === 'laugh' ? Math.floor(t / 4) % 2 : 0;
        blit('wc_' + (pose === 'laugh' ? 'open' : pose), x, sim.WC_Y - j);
        if (speaks) spx = [x, sim.WC_Y - 58];
      } else if (kind === 'beam') {
        // the first sunbeam slants in from the top right and comes down onto x
        const end = Math.min(G, c.t * 5);
        for (let y = 0; y < end; y += 2) {
          const bx = x + (G - y) * 0.6;
          R(bx - 10, y, 20, 2, 'rgba(255,236,150,0.38)'); R(bx - 4, y, 8, 2, 'rgba(255,250,220,0.5)');
        }
      } else if (kind === 'wc') {
        const laughs = pose === 'laugh' || pose === 'plaster';
        const j = laughs ? Math.floor(t / 4) % 2 : 0;
        blit('wc_' + (laughs ? 'open' : pose), x, G - j);
        // the plaster, framed on the bathroom wall as a souvenir
        if (pose === 'plaster') { R(x - 54, G - 80, 20, 16, '#d8b040'); R(x - 52, G - 78, 16, 12, '#2a1c10'); blit('plaster', x - 44, G - 72); }
        if (speaks) spx = [x, G - 56];
      } else if (kind === 'bed') {
        blit('bed_' + pose, 392, G);
        if (pose === 'sleep') { const k = Math.floor(t / 20) % 3; for (let i = 0; i <= k; i++) T('Z', 420 + i * 8, 170 - i * 10, '#ffffff', 'ps'); }
        if (speaks) spx = [400, G - 52];
      } else if (kind === 'roll') blit('roll', x, G);
    }
    if (spx) { const b = Math.floor(t / 10) % 2; R(spx[0] - 2, spx[1] + b, 5, 2, '#f8d040'); R(spx[0] - 1, spx[1] + 2 + b, 3, 1, '#f8d040'); R(spx[0], spx[1] + 3 + b, 1, 1, '#f8d040'); }

    R(0, 256, W, 14, '#07060e');
    R(8, 8, 464, 70, 'rgba(10,10,26,0.93)');
    R(8, 8, 464, 1, '#ebe8da'); R(8, 77, 464, 1, '#ebe8da'); R(8, 8, 1, 70, '#ebe8da'); R(471, 8, 1, 70, '#ebe8da');
    const who = tx['who_' + st.who], full = tx[st.k];
    let ty = 12;
    if (who) { T(who, 18, 13, st.who === 't' ? '#f07a18' : st.who === 'wc' ? '#7ec8f0' : st.who === 'g' ? GC.lt : '#63d97d', 'ps'); ty = 22; }
    const lines = wrap(full, 'vt', 440);
    let left = Math.floor(c.t / 1.2);
    lines.forEach((ln, i) => {
      if (left <= 0) return;
      T(ln.slice(0, left), 18, ty + i * 16, who ? '#ffffff' : '#cfd6ff', 'vt');
      left -= ln.length + 1;
    });
    if (c.t / 1.2 >= full.length && Math.floor(t / 20) % 2) T('> ' + tx.next, 462, 66, '#f8d040', 'ps', 2);
  }

  function drawEnd(S, tx, t) {
    R(0, 0, W, H, '#05050d');
    for (let i = 0; i < 60; i++) R((i * 131) % W, (i * 71) % 180, 1, 1, i % 3 ? '#6a6a90' : '#ffffff');
    disc(ctx, 240, 96, 58, '#1c4a9a'); disc(ctx, 232, 88, 50, '#2a62c0');
    R(206, 70, 30, 18, '#2f9a4a'); R(214, 88, 18, 14, '#2f9a4a'); R(250, 96, 28, 20, '#2f9a4a'); R(262, 76, 16, 12, '#2f9a4a'); R(222, 120, 14, 10, '#2f9a4a');
    R(196, 100, 20, 4, '#e8f0ff'); R(244, 62, 26, 4, '#e8f0ff'); R(256, 128, 22, 3, '#e8f0ff');
    T(tx.end1, 240, 84, '#ffffff', 'ps', 1, 3);
    const a = Math.min(1, S.endT / 120);
    ctx.globalAlpha = a;
    T(tx.end2, 240, 170, '#cfd6ff', 'vt', 1);
    T(tx.end3, 240, 194, '#63d97d', 'ps', 1);
    T(tx.end4, 240, 204, '#9a94b8', 'vt', 1);
    ctx.globalAlpha = 1;
    blit('z0_idle' + (Math.floor(t / 30) % 2), 60, 246); blit('z1_idle' + (Math.floor(t / 30 + 1) % 2), 420, 246, true);
    if (S.endT > 180 && Math.floor(t / 25) % 2) T(tx.end5, 240, 226, '#f8d040', 'vt', 1);
  }

  // The scrolling line from 2016: it moved one pixel to the right every frame.
  function credit(tx, t, y) {
    const w = measure(tx.credit, 'vt');
    T(tx.credit, (t % (W + w)) - w, y, '#787878', 'vt');
  }

  // ---------------------------------------------------------------- public
  D.init = function (c) { ctx = c; ctx.imageSmoothingEnabled = false; buildSprites(); loadImages(); };
  D.clearText = function () { tcache = new Map(); };
  D.R = R; D.T = T; D.blit = blit; D.bg = bg; D.credit = credit; D.measure = measure; D.bar = bar;
  D.disc = (x, y, r, c) => disc(ctx, x, y, r, c);

  D.render = function (S, lang, t) {
    const tx = DDN.TEXT[lang];
    ctx.imageSmoothingEnabled = false;
    if (S.mode === 'end') { drawEnd(S, tx, t); credit(tx, t, 250); return; }
    ctx.save();
    if (S.shake > 0) ctx.translate(Math.round((Math.random() - 0.5) * 4), Math.round((Math.random() - 0.5) * 4));
    if (S.mode === 'cut') { drawCut(S, tx, t); ctx.restore(); return; }
    drawScene(S, t, tx);
    ctx.restore();
    drawHud(S, tx, t);
    if (S.mode === 'over') {
      R(0, 0, W, H, 'rgba(6,4,14,0.72)');
      T(S.overWhy === 'sun' ? tx.over_sun : tx.over, 240, 104, S.overWhy === 'sun' ? '#f8c830' : '#e8304a', 'ps', 1, 2);
      if (S.overT > 45 && Math.floor(t / 25) % 2) T(tx.over_hint, 240, 140, '#ffffff', 'vt', 1);
    }
  };
})();
