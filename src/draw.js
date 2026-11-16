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
  // The zombie keeps the 2016 shape: a block body, a round head and one arm stretched out.
  // The hats and collar come from the two captains in the middle of De Nachtwacht.
  function zombie(P, id, o) {
    const c = ZC[id], b = o.bob || 0;
    const legs = o.legs || [[-4, 0], [1, 0]];
    for (const [lx, up] of legs) { P(lx, -6 - up, 3, 6, c.dark); P(lx, -1 - up, 4, 1, '#22222a'); }
    P(-5, -18 + b, 10, 13, c.body); P(-5, -18 + b, 2, 13, c.dark);
    P(-3, -5 + b, 2, 1, c.body); P(2, -5 + b, 2, 1, c.body);
    if (id === 0) { P(-3, -17 + b, 2, 2, c.band); P(-1, -15 + b, 2, 2, c.band); P(1, -13 + b, 2, 2, c.band); P(3, -11 + b, 2, 2, c.band); }
    else { P(-5, -10 + b, 10, 2, c.hat); P(-1, -10 + b, 2, 2, c.band); }
    P(-6, -19 + b, 12, 2, '#ebe8da');
    P(-4, -29 + b, 8, 10, c.skin); P(-5, -28 + b, 10, 8, c.skin); P(-5, -28 + b, 2, 8, c.sdark); P(-4, -29 + b, 2, 1, c.sdark);
    P(1, -26 + b, 3, 3, '#f6f6e4'); P(3, -25 + b, 1, 1, '#111');
    if (o.mouth) { P(0, -22 + b, 5, 2, '#3a0a0a'); P(1, -22 + b, 1, 1, '#fff'); P(3, -22 + b, 1, 1, '#fff'); }
    else P(1, -21 + b, 4, 1, '#1a4a22');
    P(-7, -30 + b, 14, 2, c.hat); P(-4, -30 + b - (id ? 3 : 4), 8, id ? 3 : 4, c.hat); P(-4, -31 + b, 8, 1, c.band);
    if (id === 1) P(-6, -36 + b, 2, 5, '#f4f4f4');
    const al = o.arm || 8;
    if (o.arm2) { P(3, -13 + b, o.arm2, 2, c.dark); P(3 + o.arm2, -14 + b, 2, 3, c.sdark); }
    P(3, -16 + b, al, 2, c.body); P(3 + al, -17 + b, 2, 3, c.skin);
  }
  function zombieDown(P, id) {
    const c = ZC[id];
    P(-12, -6, 14, 6, c.body); P(-12, -6, 14, 2, c.dark);
    P(2, -9, 9, 9, c.skin); P(6, -6, 2, 1, '#111'); P(8, -6, 1, 1, '#111'); P(7, -7, 1, 3, '#111');
    P(-17, -3, 5, 3, c.dark); P(12, -4, 8, 2, c.hat); P(14, -7, 5, 3, c.hat);
  }

  const TH = { suit: '#f07a18', dark: '#b85a10', skin: '#8a5a3a', sdark: '#6a4028' };
  function thief(P, o) {
    const b = o.bob || 0;
    const legs = o.legs || [[-4, 0], [1, 0]];
    for (const [lx, up] of legs) { P(lx, -7 - up, 3, 7, TH.dark); P(lx, -1 - up, 4, 1, '#3a2418'); }
    if (o.roll) { P(-9, -24 + b, 3, 14, '#dccaa0'); P(-9, -24 + b, 3, 1, '#a08860'); P(-9, -11 + b, 3, 1, '#a08860'); }
    P(-5, -19 + b, 10, 12, TH.suit); P(-5, -19 + b, 2, 12, TH.dark); P(-1, -19 + b, 1, 12, TH.dark);
    P(-4, -28 + b, 8, 9, TH.skin); P(-3, -29 + b, 6, 1, TH.skin); P(-4, -28 + b, 2, 9, TH.sdark);
    P(1, -26 + b, 2, 2, '#fff'); P(2, -25 + b, 1, 1, '#111');
    if (o.mouth) P(1, -22 + b, 3, 2, '#3a0a0a'); else P(1, -21 + b, 3, 1, '#4a2a1a');
    if (o.arms === 'up') { P(-7, -27 + b, 2, 9, TH.suit); P(5, -27 + b, 2, 9, TH.suit); P(-7, -29 + b, 2, 2, TH.skin); P(5, -29 + b, 2, 2, TH.skin); }
    else if (o.arms === 'throw') { P(-7, -18 + b, 2, 7, TH.suit); P(5, -28 + b, 2, 10, TH.suit); P(5, -30 + b, 3, 2, TH.skin); }
    else if (o.arms === 'knee') { P(-6, -17 + b, 2, 8, TH.suit); P(4, -17 + b, 2, 8, TH.suit); P(8, -27 + b, 1, 2, '#8fd0ff'); P(9, -22 + b, 1, 2, '#8fd0ff'); }
    else { P(-7, -18 + b + (o.swing || 0), 2, 7, TH.suit); P(5, -18 + b - (o.swing || 0), 2, 7, TH.suit); }
  }

  function buildSprites() {
    for (let id = 0; id < 2; id++) {
      const k = 'z' + id + '_';
      const mk = (name, o) => make(k + name, 30, 40, 9, 39, P => zombie(P, id, o));
      mk('idle0', {}); mk('idle1', { bob: 1, legs: [[-4, 0], [1, 0]] });
      mk('w0', { legs: [[-6, 1], [2, 0]] }); mk('w1', { bob: 1 }); mk('w2', { legs: [[-3, 0], [3, 1]] }); mk('w3', { bob: 1 });
      mk('jump', { legs: [[-5, 2], [2, 3]], arm: 9 });
      mk('bite', { mouth: 1, arm: 12, arm2: 10, legs: [[-5, 0], [2, 0]] });
      make(k + 'down', 40, 12, 18, 11, P => zombieDown(P, id));
      make(k + 'icon', 12, 12, 6, 11, P => {
        const c = ZC[id];
        P(-4, -8, 8, 8, c.skin); P(1, -6, 2, 2, '#fff'); P(2, -5, 1, 1, '#111'); P(-6, -9, 12, 2, c.hat); P(-3, -11, 6, 2, c.hat);
      });
    }
    const tk = (name, o) => make('t_' + name, 24, 34, 11, 33, P => thief(P, o));
    tk('r0', { legs: [[-6, 1], [3, 0]], swing: 2, roll: 1 }); tk('r1', { bob: 1, roll: 1 });
    tk('r2', { legs: [[-2, 0], [3, 2]], swing: -2, roll: 1 }); tk('r3', { bob: 1, roll: 1 });
    tk('stand', { roll: 1 }); tk('pant', { bob: 2, arms: 'knee', mouth: 1, roll: 1 });
    tk('throw', { arms: 'throw', mouth: 1, roll: 1 }); tk('scared', { arms: 'up', mouth: 1, roll: 1 });
    tk('scared2', { arms: 'up', mouth: 1 });

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
  function drawPlayers(S, t) {
    for (const p of S.players) {
      if (p.inv > 0 && p.down === 0 && Math.floor(t / 3) % 2) continue;
      blit('z' + p.id + '_' + zPose(S, p), p.x, p.y, p.face < 0);
      if (p.carry > 0 && (p.carry > 120 || Math.floor(t / 4) % 2)) flame(p.x + p.face * 12, p.y - 17, t, false);
      if (p.down > 0 && S.two) T(String(Math.max(0, Math.ceil((240 - p.down) / 60))), p.x, p.y - 26, '#ffffff', 'ps', 1);
    }
  }

  function drawScene(S, t) {
    const v = S.v, id = S.scene, sc = sim.SC[id];
    bg(id === 'chase' ? 'field' : id);
    if (id === 'chase') chaseBack(v);
    if (id === 'field') {
      blit('grave', 30, G); blit('grave', 52, G);
      blit('gate' + Math.max(0, v.gate), 398, G);
    }
    if (id === 'hall') hallDecor(v, t, false);
    else for (const s of sc.solids) blit(s.k, s.x, s.y);
    for (const p of sc.plats) blit('branch', p.x, p.y);
    if (id === 'forest') for (const s of v.sc) if (!s.got) { blit('scrap' + (Math.floor(t / 12) % 2), s.x, s.y + Math.round(Math.sin(t / 15 + s.x) * 1.5)); }
    if (id === 'house' && v.key && Math.floor(t / 20) % 2) T('v', sim.DOOR, 150, '#f8d040', 'ps', 1);
    if (id === 'bed') {
      for (const d of v.d) blit('duck', d.x, G - (d.cd > 40 ? 1 : 0));
      blit(v.ph === 'listen' ? 'bed_awake' : 'bed_sleep', 392, G);
      if (v.ph === 'snore') { const k = Math.floor(t / 20) % 3; for (let i = 0; i <= k; i++) T('Z', 420 + i * 8, 170 - i * 10, '#ffffff', 'ps'); }
      else if (v.ph === 'stir') T('?', 418, 158, '#f8d040', 'ps', 0, 2);
      else T('!', 418, 150, '#ff4040', 'ps', 0, 2);
    }
    if (id === 'chase') {
      blit('t_' + (v.thr > 0 ? 'throw' : 'r' + (Math.floor(t / 5) % 4)), 432, G, v.thr > 0);
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
          let k = 'stand';
          if (e.st === 'pant') k = 'pant';
          else if (!e.g) k = 'scared';
          else if (e.st === 'atk') k = (e.t % 55) > 15 && (e.t % 55) < 35 ? 'throw' : 'stand';
          else if (Math.abs(e.vx) > 0.1) k = 'r' + (Math.floor(t / 5) % 4);
          blit('t_' + k, e.x, e.y, e.face < 0);
          if (e.st === 'pant') T('...', e.x, e.y - 44, '#ffffff', 'ps', 1);
          break;
        }
      }
    }
    drawPlayers(S, t);
    if (id === 'hall') darkness(S, t);
    if (id === 'arena') { ctx.fillStyle = 'rgba(255,150,60,' + (Math.min(1, v.sun) * 0.32).toFixed(3) + ')'; ctx.fillRect(0, 0, W, H); }
  }

  // ---------------------------------------------------------------- HUD
  function bar(x, y, w, h, f, col, back) {
    R(x - 1, y - 1, w + 2, h + 2, '#0c0a16'); R(x, y, w, h, back || '#2a2438'); R(x, y, Math.round(w * Math.max(0, Math.min(1, f))), h, col);
  }
  function drawHud(S, tx, t) {
    const sc = sim.SC[S.scene], v = S.v;
    let y = 6;
    for (const p of S.players) {
      if (p.ai) continue;
      blit('z' + p.id + '_icon', 12, y + 9);
      for (let i = 0; i < 3; i++) blit(i < p.hp ? 'heart' : 'heart0', 22 + i * 9, y + 1);
      y += 13;
    }
    const g = sc.goal(S);
    let label = tx[g.k] + (g.of ? '  ' + g.n + '/' + g.of : '');
    let gy = 5;
    if (S.scene === 'arena') {
      const th = S.ents.find(e => e.type === 'thief'), hp = th ? th.hp : 0;
      bar(60, 6, 360, 6, hp / 1000, '#e8304a');                 // the leven = 1000 bar from 2016
      T(tx.leven + ' ' + hp, 240, 14, '#ffffff', 'ps', 1);
      bar(180, 30, 120, 3, v.sun, '#f8c830');
      blit('sun', 180 + Math.round(120 * Math.min(1, v.sun)), 31);
      T(tx.sun, 176, 26, '#f8c830', 'ps', 2);
      gy = 36;
    }
    T(label, 240, gy, '#ffffff', 'vt', 1);
    if (g.bar != null) { bar(170, 28, 140, 4, g.bar, '#f07a18'); T(tx.dist, 316, 25, '#f07a18', 'ps'); }
    if (S.scene === 'bed') {
      bar(180, 28, 120, 5, v.noise / 100, v.noise > 60 ? '#e8304a' : '#f8c830');
      T(tx.noise, 176, 26, '#ffffff', 'ps', 2);
    }
    if (S.msgT > 0 && S.msg) T(tx[S.msg], 240, 62, '#f8d040', 'vt', 1);
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
    for (const [kind, x, pose, flip] of st.a) {
      const speaks = (st.who === 'z1' && kind === 'z0') || (st.who === 'z2' && kind === 'z1') || (st.who === 't' && (kind === 'thief' || (kind === 'bed' && pose === 'awake'))) || (st.who === 'wc' && kind === 'wc');
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
        const k = pose === 'run' ? 'r' + (Math.floor(t / 5) % 4) : pose === 'flee' || pose === 'giveup' ? 'scared2' : pose;
        const dx = away ? Math.min(pose === 'flee' ? 220 : 60, c.t * 1.8) : 0;
        blit('t_' + k, x + dx, G - (pose === 'flee' ? Math.floor(t / 4) % 2 : 0), flip);
        if (speaks) spx = [x, G - 40];
      } else if (kind === 'wc') {
        const j = pose === 'laugh' ? Math.floor(t / 4) % 2 : 0;
        blit('wc_' + (pose === 'laugh' ? 'open' : pose), x, G - j);
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
    if (who) { T(who, 18, 13, st.who === 't' ? '#f07a18' : st.who === 'wc' ? '#7ec8f0' : '#63d97d', 'ps'); ty = 22; }
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
    drawScene(S, t);
    ctx.restore();
    drawHud(S, tx, t);
    if (S.mode === 'over') {
      R(0, 0, W, H, 'rgba(6,4,14,0.72)');
      T(S.overWhy === 'sun' ? tx.over_sun : tx.over, 240, 104, S.overWhy === 'sun' ? '#f8c830' : '#e8304a', 'ps', 1, 2);
      if (S.overT > 45 && Math.floor(t / 25) % 2) T(tx.over_hint, 240, 140, '#ffffff', 'vt', 1);
    }
  };
})();
