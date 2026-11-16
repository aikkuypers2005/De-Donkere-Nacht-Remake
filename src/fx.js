// Effects and ambience for De Donkere Nacht 2: dust, sparks, damage numbers, and the small things that move
// in every scene. Drawing only: nothing here changes the game. It uses its own randomness and time, so two
// online players may see slightly different leaves and smoke; what matters (dust where someone lands, a damage
// number where a boss was hit) comes from positioned events in S.evs, so both players see that in the same place.
(function () {
  const DDN = window.DDN, sim = DDN.sim, W = sim.W, G = sim.G;
  const FX = DDN.fx = {};
  let D = null, ctx = null;
  const rnd = Math.random;

  // ---------------------------------------------------------------- particles
  // A fixed pool of 150, reused in turn, so nothing piles up however busy it gets.
  const MAX = 150, POOL = [];
  for (let i = 0; i < MAX; i++) POOL.push({ on: false, x: 0, y: 0, vx: 0, vy: 0, g: 0, drag: 1, life: 0, max: 1, s: 1, grow: 0, sway: 0, ph: 0, cols: null, front: true });
  let next = 0;
  // four steps from solid to faint, made once
  const fade = (r, g, b, a) => [a, a * 0.7, a * 0.45, a * 0.2].map(k => 'rgba(' + r + ',' + g + ',' + b + ',' + k.toFixed(2) + ')');
  const C = {
    dust: fade(196, 170, 140, 0.8), sand: fade(232, 206, 156, 0.85), smoke: fade(160, 160, 172, 0.45), steam: fade(236, 242, 255, 0.3),
    spark: ['#ffffff', '#fff4a0', '#f8d040', '#e89020'], sweat: fade(150, 210, 255, 0.95), splash: fade(170, 215, 255, 0.85),
    leaf: ['#3a9a2a', '#4a9a2a', '#7a8a2a', '#8a6a2a'], chip: fade(150, 144, 130, 0.95)
  };
  const NONE = {};
  function spawn(x, y, vx, vy, life, cols, o) {
    o = o || NONE;
    const p = POOL[next]; next = (next + 1) % MAX;
    p.on = true; p.x = x; p.y = y; p.vx = vx; p.vy = vy; p.life = p.max = Math.max(1, Math.round(life)); p.cols = cols;
    p.g = o.g || 0; p.drag = o.drag || 1; p.s = o.s || 1; p.grow = o.grow || 0; p.sway = o.sway || 0; p.ph = rnd() * 6; p.front = !o.back;
  }
  function particles(front) {
    for (const p of POOL) {
      if (!p.on || p.front !== front) continue;
      if (--p.life <= 0) { p.on = false; continue; }
      p.vx *= p.drag; p.vy = p.vy * p.drag + p.g;
      p.x += p.vx + (p.sway ? Math.sin(p.life / 12 + p.ph) * p.sway : 0); p.y += p.vy;
      const k = 1 - p.life / p.max, s = Math.max(1, Math.round(p.s + p.grow * k));
      D.R(p.x - (s >> 1), p.y - (s >> 1), s, s, p.cols[Math.min(3, (k * 4) | 0)]);
    }
  }
  function clearParticles() { for (const p of POOL) p.on = false; }

  const sandy = id => id === 'arena' || id === 'giant';
  function dust(x, y, n, id) {
    for (let i = 0; i < n; i++) spawn(x + (rnd() - 0.5) * 10, y - 1, (rnd() - 0.5) * 1.4, -rnd() * 0.7, 16 + rnd() * 12, sandy(id) ? C.sand : C.dust, { grow: 2, drag: 0.9 });
  }
  function burst(x, y, size, id) {
    const n = 4 + size * 4;
    for (let i = 0; i < n; i++) spawn(x + (rnd() - 0.5) * size * 12, y - 1, (rnd() - 0.5) * size * 1.3, -rnd() * size * 0.5, 24 + rnd() * 16, sandy(id) ? C.sand : C.dust, { grow: 3, drag: 0.92, g: -0.01 });
    if (size >= 3) for (let i = 0; i < size * 2; i++) spawn(x + (rnd() - 0.5) * 30, y - 2, (rnd() - 0.5) * 3, -2 - rnd() * 2.5, 30, C.chip, { g: 0.22, s: 2 });
  }
  function sparks(x, y, n) {
    for (let i = 0; i < n; i++) { const a = rnd() * 6.28, sp = 1 + rnd() * 1.6; spawn(x, y, Math.cos(a) * sp, Math.sin(a) * sp, 8 + rnd() * 8, C.spark, { drag: 0.82 }); }
  }

  // ---------------------------------------------------------------- events from the game
  // Floating damage numbers: six slots, reused.
  const NUMS = [];
  for (let i = 0; i < 6; i++) NUMS.push({ on: false, x: 0, y: 0, t: 0, s: '' });
  let numNext = 0, seen = -1, freeze = 0;
  const squashT = [0, 0], lastBh = [false, false], dipT = [0, 0, 0, 0, 0, 0, 0, 0];

  FX.events = function (S) {
    if (seen < 0 || S.evN < seen) seen = S.evN;                // a new game: never replay old events
    for (const e of S.evs) {
      if (e.n <= seen) continue;
      seen = e.n;
      if (typeof e.x !== 'number') continue;
      if (e.s === 'land') {
        dust(e.x, e.y, 5, S.scene);
        if (e.v === 0 || e.v === 1) squashT[e.v] = 6;
        sim.SC[S.scene].plats.forEach((pl, i) => { if (e.y === pl.y && e.x > pl.x - 5 && e.x < pl.x + pl.w + 5 && i < dipT.length) dipT[i] = 12; });
      } else if (e.s === 'bosshit') {
        const n = NUMS[numNext]; numNext = (numNext + 1) % NUMS.length;
        n.on = true; n.x = e.x; n.y = e.y; n.t = 0; n.s = '-' + (e.v || 1);
        sparks(e.x, e.y + 8, 10);
        freeze = 3;
      } else if (e.s === 'thud') burst(e.x, e.y, e.v || 1, S.scene);
    }
  };
  FX.hold = function () { if (freeze > 0) { freeze--; return true; } return false; };
  FX.squash = id => squashT[id] > 0;
  FX.dip = i => (dipT[i] > 6 ? 2 : dipT[i] > 0 ? 1 : 0);

  // ---------------------------------------------------------------- scene state (crow, owl, ...)
  let scene = '', lastTick = 0, crow = null, gStep = -1;
  function enter(S) {
    if (S.scene === scene && S.tick >= lastTick) { lastTick = S.tick; return; }
    scene = S.scene; lastTick = S.tick; gStep = -1;
    crow = { st: 'sit', x: 147, y: 198, t: 0 };
    clearParticles();
    for (let i = 0; i < dipT.length; i++) dipT[i] = 0;
  }

  // ---------------------------------------------------------------- sprites of our own
  let STARS = null, FLIES = null, hills = null, sky = null, skyFrom = null;
  FX.init = function (c) {
    ctx = c; D = DDN.draw;
    const owl = (key, up) => D.make(key, 14, 10, 7, 6, P => {
      P(-3, -3, 6, 6, '#6a4a2a'); P(-2, -5, 4, 2, '#6a4a2a'); P(-2, -4, 1, 1, '#f8d040'); P(1, -4, 1, 1, '#f8d040'); P(0, -3, 1, 1, '#c89020');
      if (up) { P(-7, -5, 4, 2, '#5a3a1a'); P(3, -5, 4, 2, '#5a3a1a'); } else { P(-7, 0, 4, 2, '#5a3a1a'); P(3, 0, 4, 2, '#5a3a1a'); }
    });
    owl('owl0', true); owl('owl1', false);
    // stars that twinkle (slowly), fireflies, and a strip of far hills for the chase
    let seed = 11;
    const r = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    STARS = [];
    for (let i = 0; i < 18; i++) STARS.push({ x: 60 + Math.floor(r() * 410), y: 8 + Math.floor(r() * 130), ph: Math.floor(r() * 200), per: 90 + Math.floor(r() * 120) });
    FLIES = [];
    for (let i = 0; i < 9; i++) FLIES.push({ x: 20 + Math.floor(r() * 440), y: 110 + Math.floor(r() * 85), ph: Math.floor(r() * 150) });
    hills = D.canvas(640, 60);
    const hc = hills.getContext('2d');
    for (let i = 0; i < 6; i++) D.discOn(hc, 50 + i * 110 + Math.floor(r() * 30), 60 + 20, 40 + Math.floor(r() * 25), i % 2 ? '#141a34' : '#18203c');
  };

  // The sky behind the arena's arches warms up with the sunrise: a glow drawn only through the sky pixels.
  function arenaSky(sun) {
    const bg = D.bgCanvas('arena');
    if (!bg) return;
    if (skyFrom !== bg) {
      skyFrom = bg;
      const w = bg.width, h = 130, src = bg.getContext('2d').getImageData(0, 0, w, h).data;
      sky = D.canvas(w, h);
      const c = sky.getContext('2d'), out = c.createImageData(w, h), d = out.data;
      for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
        const i = (y * w + x) * 4, R = src[i], Gn = src[i + 1], B = src[i + 2];
        if (B > R + 6 && R + Gn + B < 300) {
          const k = y / h;
          d[i] = 248; d[i + 1] = Math.round(150 + 70 * k); d[i + 2] = Math.round(100 + 40 * k); d[i + 3] = 255;
        }
      }
      c.putImageData(out, 0, 0);
    }
    if (sun <= 0) return;
    ctx.globalAlpha = Math.min(1, sun) * 0.5;
    ctx.drawImage(sky, 0, 0);
    ctx.globalAlpha = 1;
  }

  // ---------------------------------------------------------------- the little things, per scene
  function stars(t) {
    for (const s of STARS) {
      const on = (t + s.ph) % s.per < s.per * 0.55;
      D.R(s.x, s.y, 1, 1, on ? '#ffffff' : '#6a70a0');
      if (on && (t + s.ph) % s.per < 12) { D.R(s.x - 1, s.y, 3, 1, 'rgba(255,255,255,0.5)'); D.R(s.x, s.y - 1, 1, 3, 'rgba(255,255,255,0.5)'); }
    }
  }
  // far away on the hill a hand comes up out of a grave, waves, and goes back down
  function graveHand(t, x, base) {
    const c = t % 760;
    if (c >= 200) return;
    const up = c < 30 ? c / 30 : c > 170 ? (200 - c) / 30 : 1, h = Math.round(up * 7);
    if (h <= 0) return;
    D.R(x, base - h, 2, h, '#6a8a5a');
    if (h >= 6) {
      const w = Math.floor(c / 14) % 2;
      D.R(x - 1, base - h - 3, 4, 3, '#7a9a6a');
      D.R(x - 1 + w, base - h - 5, 1, 2, '#7a9a6a'); D.R(x + 1 + w, base - h - 6, 1, 3, '#7a9a6a'); D.R(x + 3, base - h - 3 - w, 1, 2, '#7a9a6a');
    }
  }
  function sitCrow(x, y, flip) { D.blit('crow1', x, y, flip); }
  function mist(t) {
    for (let i = 0; i < 6; i++) {
      const y = 190 + i * 4, sp = 0.15 + i * 0.05, w = 70 + i * 12;
      for (let j = 0; j < 3; j++) D.R(((t * sp + i * 131 + j * 240) % 720) - 120, y, w, 3, 'rgba(190,200,240,0.09)');
    }
  }
  function field(S, t) {
    stars(t);
    graveHand(t, 300, 172);
    // a crow on the first tombstone; it flies off when a zombie comes near
    if (crow.st === 'sit') {
      sitCrow(crow.x, crow.y, true);
      if (S.players.some(p => Math.abs(p.x - crow.x) < 46)) { crow.st = 'fly'; crow.t = 0; }
    } else if (crow.x < W + 20) {
      crow.t++; crow.x += 2.4; crow.y -= 1.5 - Math.min(1, crow.t / 60);
      D.blit('crow' + (Math.floor(crow.t / 4) % 2), crow.x, crow.y, false);
    }
  }
  function forest(S, t) {
    // an owl's eyes in the dark between the trees, blinking now and then
    if (t % 260 < 8) { D.R(198, 132, 2, 1, '#4a3a10'); D.R(203, 132, 2, 1, '#4a3a10'); }
    else { D.R(198, 131, 2, 2, '#f8d040'); D.R(203, 131, 2, 2, '#f8d040'); D.R(199, 132, 1, 1, '#1a1206'); D.R(204, 132, 1, 1, '#1a1206'); }
    for (const f of FLIES) {
      if ((t + f.ph) % 150 > 90) continue;
      const x = Math.round(f.x + Math.sin(t / 97 + f.ph) * 26), y = Math.round(f.y + Math.sin(t / 71 + f.ph * 2) * 18);
      D.R(x - 1, y - 1, 3, 3, 'rgba(220,255,120,0.18)'); D.R(x, y, 1, 1, '#e8ff80');
    }
    if (rnd() < 0.03) spawn(rnd() * W, 62 + rnd() * 40, 0.15, 0.3 + rnd() * 0.2, 420, C.leaf, { sway: 0.5, back: true, s: 2 });
  }
  function clipR(x, y, w, h, x0, y0, x1, y1, col) {
    const a = Math.max(x, x0), b = Math.max(y, y0), c = Math.min(x + w, x1), d = Math.min(y + h, y1);
    if (c > a && d > b) D.R(a, b, c - a, d - b, col);
  }
  function house(S, t) {
    // a chimney with smoke, a cat on the roof, and now and then the thief's shadow behind the lit window
    D.R(450, 68, 13, 3, '#4a2418'); D.R(452, 71, 9, 15, '#7a3a2a'); D.R(452, 75, 9, 1, '#5a2a1a'); D.R(452, 80, 9, 1, '#5a2a1a'); D.R(456, 71, 1, 4, '#5a2a1a');
    if (t % 10 === 0) spawn(456, 66, -0.12 - rnd() * 0.1, -0.32 - rnd() * 0.1, 140, C.smoke, { grow: 5, back: true, s: 2 });
    const k = '#121216';
    D.R(405, 79, 7, 6, k); D.R(402, 75, 5, 5, k); D.R(402, 74, 1, 1, k); D.R(406, 74, 1, 1, k);
    if (t % 300 > 8) { D.R(403, 77, 1, 1, '#f8e040'); D.R(405, 77, 1, 1, '#f8e040'); }
    for (let i = 0; i < 6; i++) D.R(412 + i, 84 - i - Math.round(Math.sin(t / 25 + i * 0.7) * i * 0.5), 1, 1, k);
    const c = t % 620;
    if (c < 90) {
      const sx = 386 + c * 0.45, col = 'rgba(60,32,12,0.7)';
      clipR(sx - 3, 163, 6, 6, 397, 160, 414, 183, col); clipR(sx - 5, 169, 10, 14, 397, 160, 414, 183, col);
    }
  }
  function nearestZombie(S, x) {
    let best = null;
    for (const p of S.players) if (!p.down && (!best || Math.abs(p.x - x) < Math.abs(best.x - x))) best = p;
    return best;
  }
  function hall(S, t) {
    // a wall clock with a swinging pendulum
    D.R(105, 66, 14, 41, '#5a3018'); D.R(107, 68, 10, 10, '#e8dcc0'); D.R(111, 72, 2, 2, '#2a1a0a');
    D.R(112, 69, 1, 4, '#2a1a0a'); D.R(112, 73, 3, 1, '#2a1a0a');
    const sec = t / 60 * Math.PI / 30;
    D.R(112 + Math.round(Math.sin(sec) * 4), 73 - Math.round(Math.cos(sec) * 4), 1, 1, '#a02020');
    D.R(107, 80, 10, 24, '#1a0e06');
    const sw = Math.sin(t / 28) * 3;
    for (let y = 81; y < 97; y++) D.R(112 + Math.round(sw * (y - 81) / 16), y, 1, 1, '#c8a040');
    D.R(111 + Math.round(sw), 97, 3, 3, '#e8c060');
    // a spider going up and down on its thread
    const sy = 40 + Math.round((Math.sin(t / 90) + 1) * 22);
    D.R(190, 0, 1, sy, 'rgba(230,230,240,0.4)');
    D.R(188, sy, 5, 4, '#141414'); D.R(186, sy + 1, 2, 1, '#141414'); D.R(193, sy + 1, 2, 1, '#141414'); D.R(186, sy + 3, 2, 1, '#141414'); D.R(193, sy + 3, 2, 1, '#141414');
    D.R(189, sy + 1, 1, 1, '#e83030'); D.R(191, sy + 1, 1, 1, '#e83030');
    // a stern portrait whose eyes follow the nearest zombie
    D.R(318, 92, 22, 28, '#c89a30'); D.R(320, 94, 18, 24, '#2a3a2a');
    D.R(323, 97, 12, 4, '#3a2410'); D.R(324, 99, 10, 12, '#e8c8a0'); D.R(323, 97, 2, 10, '#3a2410');
    D.R(325, 103, 3, 2, '#ffffff'); D.R(330, 103, 3, 2, '#ffffff');
    const z = nearestZombie(S, 329), dx = z ? Math.max(0, Math.min(2, Math.round((z.x - 329) / 60) + 1)) : 1, dy = z && z.y > 120 ? 1 : 0;
    D.R(325 + dx, 103 + dy, 1, 1, '#111'); D.R(330 + dx, 103 + dy, 1, 1, '#111');
    D.R(327, 108, 4, 1, '#8a4a3a'); D.R(322, 111, 14, 3, '#ebe8da'); D.R(321, 114, 16, 4, '#1a1a22');
  }
  function bath(S, t) {
    // the tap drips into the basin
    const c = t % 120;
    if (c < 70) D.R(70, 149, 1, c > 40 ? 2 : 1, 'rgba(170,215,255,0.9)');
    else if (c < 78) D.R(70, 149 + (c - 70), 1, 2, 'rgba(170,215,255,0.9)');
    else if (c === 78) for (let i = 0; i < 3; i++) spawn(70, 157, (rnd() - 0.5) * 1.2, -0.6 - rnd() * 0.6, 12, C.splash, { g: 0.15, back: true });
    // steam in the shower, and a rubber duck bobbing behind the glass
    if (t % 9 === 0) spawn(142 + rnd() * 80, 196 - rnd() * 24, (rnd() - 0.5) * 0.2, -0.25 - rnd() * 0.15, 170, C.steam, { grow: 5, back: true, s: 2 });
    D.blit('duck', 206, 205 + Math.round(Math.sin(t / 25)), false, 0.5);
  }
  function bed(S, t) {
    // moonlight falls from the skylight, with dust drifting in it, and the curtains move a little
    for (let y = 112; y < G; y += 2) D.R(196 + Math.round((y - 112) * 0.35), y, 88, 2, 'rgba(150,170,255,0.08)');
    for (let i = 0; i < 14; i++) {
      const y = 112 + ((i * 59 + t * (0.08 + (i % 3) * 0.03)) % 100), x = 196 + ((i * 37 + t * 0.12) % 88) + (y - 112) * 0.35;
      D.R(Math.round(x), Math.round(y), 1, 1, 'rgba(110,120,180,0.6)');
    }
    for (const [x0, side] of [[188, 1], [282, -1]]) {
      D.R(x0 - 2, 72, 16, 2, '#4a2a18');
      for (let r = 0; r < 34; r++) {
        const sway = Math.round(Math.sin(t / 50 + r / 9) * (r / 12)), w = 10 - Math.floor(r / 9);
        D.R(side > 0 ? x0 + sway : x0 + 10 - w + sway, 74 + r, w, 1, r % 6 < 3 ? '#7a4a9a' : '#6a3a8a');
      }
    }
  }
  function chase(S, t) {
    // far hills, slower than everything else
    const off = -((S.v.dist * 0.12) % 640);
    ctx.drawImage(hills, Math.round(off), G - 82); ctx.drawImage(hills, Math.round(off) + 640, G - 82);
    // an owl flying along against the sky now and then
    const c = t % 1100;
    if (c < 700) D.blit('owl' + (Math.floor(t / 8) % 2), W + 20 - c * 0.75, 74 + Math.round(Math.sin(c / 20) * 4));
  }
  function arena(S, t) {
    arenaSky(S.v.sun || 0);
    // flags on the rim of the stands
    for (const [x, y, col] of [[70, 87, '#c03030'], [140, 100, '#3060c0']]) {
      D.R(x, y - 16, 1, 16, '#3a2a1a');
      for (let r = 0; r < 6; r++) D.R(x + 1, y - 16 + r, 8 + Math.round(Math.sin(t / 9 - r * 0.7) * 1.5), 1, r % 2 ? col : '#e8e0c8');
    }
    // torches along the wall under the stands
    for (const x of [40, 150, 330, 410]) {
      D.R(x - 1, 184, 3, 8, '#3a2a1a'); D.R(x - 3, 181, 7, 3, '#5a4a3a');
      const fh = 5 + ((Math.floor(t / 5) + x) % 3);
      D.R(x - 6, 174 - fh, 13, 13, 'rgba(255,170,60,0.08)');
      D.R(x - 2, 181 - fh, 5, fh, '#f06018'); D.R(x - 1, 182 - fh, 3, fh - 2, '#f8b020'); D.R(x, 183 - fh, 1, fh - 3, '#fff4b0');
    }
  }
  const BACK = { field, forest, house, hall, bath, bed, chase, arena, giant: arena };

  FX.back = function (S, t) {
    enter(S);
    if (BACK[S.scene]) BACK[S.scene](S, t);
    particles(false);
  };

  FX.front = function (S, t, tx) {
    for (let i = 0; i < 2; i++) if (squashT[i] > 0) squashT[i]--;
    for (let i = 0; i < dipT.length; i++) if (dipT[i] > 0) dipT[i]--;
    // a chomp spark where a bite hits something
    for (const p of S.players) {
      if (p.bh && !lastBh[p.id] && p.bite > 0) { const w = p.chick > 0 ? 34 : 17; sparks(p.x + p.face * w * 0.75, p.y - 15, 6); }
      lastBh[p.id] = p.bh;
    }
    if (S.scene === 'giant') {
      // dust under his feet at every step
      const g = S.ents.find(e => e.type === 'giant');
      if (g && g.st === 'walk' && g.mv) {
        const k = Math.floor(g.walk / 6) % 4;
        if (k !== gStep && (k === 0 || k === 2)) dust(g.x + g.face * (k === 0 ? 9 : -6), G, 4, 'giant');
        gStep = k;
      }
    }
    if (S.scene === 'chase') {
      // dust behind every runner, and the thief sweats
      if (t % 7 === 0) {
        for (const p of S.players) if (!p.down) spawn(p.x - 4, G - 1, -2 - rnd() * 0.5, -rnd() * 0.4, 20, C.dust, { grow: 2, drag: 0.97 });
        spawn(428, G - 1, -2 - rnd() * 0.5, -rnd() * 0.4, 20, C.dust, { grow: 2, drag: 0.97 });
      }
      if (t % 18 === 0) spawn(429, G - 27, -1.2 - rnd(), -0.8 - rnd() * 0.6, 26, C.sweat, { g: 0.12 });
    }
    if (S.scene === 'field') mist(t);
    particles(true);
    // damage numbers rise and fade
    for (const n of NUMS) {
      if (!n.on) continue;
      if (++n.t > 50) { n.on = false; continue; }
      ctx.globalAlpha = Math.max(0, 1 - n.t / 50);
      D.T(n.s, n.x, Math.round(n.y - n.t * 0.5), '#fff4a0', 'ps', 1);
      ctx.globalAlpha = 1;
    }
  };

  // the title screen: the same graveyard, with stars, the waving hand, a crow on the tombstone and mist
  FX.title = function (t) {
    if (!D) return;
    stars(t);
    graveHand(t, 300, 172);
    sitCrow(428, 192, Math.floor(t / 240) % 2 === 0);
    mist(t);
  };
})();
