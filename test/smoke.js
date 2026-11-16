// Automated playthrough of the game rules, without a browser.
// Run with: node test/smoke.js
require('../src/text.js');
const DDN = require('../src/sim.js');
const sim = DDN.sim, G = sim.G;

let failed = 0;
function check(name, ok, extra) {
  console.log((ok ? 'PASS  ' : 'FAIL  ') + name + (extra ? '  (' + extra + ')' : ''));
  if (!ok) failed++;
}

// Runs a list of commands as player 1 until the scene changes. Returns frames used, or -1 on timeout.
function play(S, script, opts) {
  opts = opts || {};
  const scene = S.scene, max = opts.max || 20000;
  let i = 0, f = 0, sub = 0, tog = false;
  while (f++ < max) {
    const p = S.players[0];
    if (opts.god) { p.hp = 3; p.down = 0; p.inv = 2; }   // cannot be hurt or knocked back
    let inp = { mx: 0, jump: false, act: false };
    tog = !tog;
    if (S.mode === 'cut' || S.mode === 'over') inp.act = tog;
    else if (S.mode === 'play') {
      const c = script[Math.min(i, script.length - 1)];
      if (typeof c === 'function') inp = c(S, p, tog) || inp;
      else if (c[0] === 'walk') {
        if (Math.abs(p.x - c[1]) < 1.6) i++; else inp.mx = p.x < c[1] ? 1 : -1;
      } else if (c[0] === 'jump') {
        inp.mx = c[1];
        if (sub === 0) { inp.jump = true; sub = 1; } else if (p.g && sub > 2) { sub = 0; i++; } else sub++;
      } else if (c[0] === 'act') {
        if (sub === 0) { inp.act = true; sub = 1; } else { sub = 0; i++; }
      } else if (c[0] === 'wait') {
        if (++sub >= c[1]) { sub = 0; i++; }
      }
    }
    sim.step(S, [inp, { mx: 0, jump: false, act: false }]);
    if (opts.each) opts.each(S);
    if (S.scene !== scene || S.mode === 'end') return f;
  }
  return -1;
}

// Player 1 against the giant: kick a resting duck towards his feet, bite his head while he lies down,
// jump the shock waves. careful: also walk out of shadows and away from his legs (for playing without cheats).
function giantBot(S, p, tog, careful) {
  const g = S.ents.find(e => e.type === 'giant');
  if (!g) return { mx: 0 };
  const W = sim.W;
  const jump = p.g && (S.ents.some(e => e.type === 'shock' && Math.abs(e.x - p.x) < 26 && Math.sign(p.x - e.x) === Math.sign(e.vx)) ||
    (careful && g.st === 'stomp' && g.t >= sim.STOMP_UP - 3 && g.t < sim.STOMP_UP && Math.abs(p.x - g.x) < 50));   // jump as the foot comes down
  if (g.st === 'down') {
    const hx = g.x - g.face * 48, dir = Math.sign(hx - p.x) || 1;
    if (Math.abs(hx - p.x) > 12 || p.face !== dir) return { mx: dir, jump };
    return { act: tog, jump };
  }
  if (careful) {
    const danger = [];
    if (g.st === 'fist' && g.t < sim.FIST_UP + 2) danger.push([g.fx, 24]);
    if (g.st === 'stomp' && g.t < sim.STOMP_UP + 2) danger.push([g.x, 30]);
    if (g.st === 'walk') danger.push([g.x, 30]);
    for (const s of S.ents) if (s.type === 'stone') danger.push([s.x, 15]);
    const d = danger.find(([x, r]) => Math.abs(p.x - x) < r);
    if (d) {
      let dir = p.x < d[0] ? -1 : 1;
      if ((dir < 0 && p.x < 24) || (dir > 0 && p.x > W - 24)) dir = -dir;
      return { mx: dir, jump };
    }
  }
  const duck = S.ents.find(e => e.type === 'duck' && e.st === 'ground' && Math.abs(e.vx) < 0.4);
  if (duck && g.st !== 'getup' && g.st !== 'roar' && g.st !== 'slip') {
    let dir = Math.sign(g.x - duck.x) || 1;
    if (duck.x < 14) dir = -1; else if (duck.x > W - 14) dir = 1;   // against a wall: kick it into the wall, it bounces back
    const off = (duck.x - p.x) * dir;                                // how far the duck is in front of us
    if (p.face === dir && off >= -4 && off <= 20) return { act: tog, jump };
    if (off >= 3 && off <= 20) return { mx: dir, jump };             // right spot, just turn around
    const px = Math.max(10, Math.min(W - 6, duck.x - dir * 11));
    return { mx: Math.sign(px - p.x) || dir, jump };
  }
  // nothing to kick: keep some distance
  if (Math.abs(p.x - g.x) < 90) {
    let dir = p.x < g.x ? -1 : 1;
    if ((dir < 0 && p.x < 20) || (dir > 0 && p.x > W - 20)) dir = -dir;
    return { mx: dir, jump };
  }
  return { mx: 0, jump };
}

// New events since the last call, for counting what happened.
function newEvents(S, seen) {
  const out = [];
  for (const e of S.evs) if (e.n > seen.n) { out.push(e.s); seen.n = e.n; }
  return out;
}

const scripts = {
  field: [(S, p, tog) => ({ mx: 1, jump: p.blk && p.g && tog, act: p.x > 385 && tog })],
  forest: [
    ['walk', 205], ['walk', 75], ['jump', 0],
    ['walk', 100], ['jump', 1], ['walk', 150],
    ['walk', 395], ['jump', 0],
    ['walk', 250], ['jump', 0], ['walk', 268], ['jump', 1], ['walk', 314],
    (S, p) => ({ mx: 1 })
  ],
  house: [(S, p, tog) => {
    const crow = S.ents.find(e => e.type === 'crow' && e.st !== 3), key = S.ents.find(e => e.type === 'key');
    if (crow) return { mx: Math.abs(crow.x - p.x) > 6 ? Math.sign(crow.x - p.x) : 0, jump: tog, act: tog };
    if (key) return { mx: Math.sign(key.x - p.x) };
    if (Math.abs(p.x - sim.DOOR) > 4) return { mx: Math.sign(sim.DOOR - p.x), jump: p.blk && tog };
    return { act: tog };
  }],
  hall: [
    ['walk', 60], ['act'], ['walk', 143], ['jump', 1], ['walk', 168], ['act'], ['wait', 3],
    ['walk', 312], ['act'], ['wait', 3], ['act'],
    (S, p, tog) => p.y > 173 ? { mx: 1, jump: p.g && tog } : Math.abs(p.x - 396) > 2 ? { mx: Math.sign(396 - p.x) } : { act: tog }
  ],
  bath: [(S, p, tog) => {
    const wave = S.ents.find(e => e.type === 'wave' && Math.abs(e.x - p.x) < 30);
    return { mx: p.x < 362 ? 1 : 0, act: tog, jump: !!wave };
  }],
  bed: [(S, p) => {
    const v = S.v;
    if (v.ph !== 'snore' || v.pt < 40) return { mx: 0 };
    const duck = v.d.find(d => d.x - p.x > 4 && d.x - p.x < 16);
    return { mx: 1, jump: !!duck && p.g };
  }],
  chase: [(S, p) => {
    const e = S.ents.find(o => o.type !== 'cbat' && o.x - p.x > 0 && o.x - p.x < 26 && (o.y === undefined || o.y > G - 30));
    return { mx: 0, jump: !!e };
  }],
  arena: [(S, p, tog) => {
    const th = S.ents.find(e => e.type === 'thief');
    const haz = S.ents.find(e => (e.type === 'fball' || e.type === 'shock') && Math.abs(e.x - p.x) < 26);
    return { mx: th && Math.abs(th.x - p.x) > 10 ? Math.sign(th.x - p.x) : 0, act: tog, jump: !!haz };
  }],
  giant: [(S, p, tog) => giantBot(S, p, tog, false)]
};

// 1. Every scene can be finished, with the right scene following it.
for (const id of sim.ORDER) {
  const S = sim.newGame({ players: 1, scene: id });
  const f = play(S, scripts[id], { god: true });
  const want = sim.SC[id].next || 'end';
  const got = S.mode === 'end' ? 'end' : S.scene;
  check('finish ' + id, f > 0 && got === want, f + ' frames, then ' + got);
}

// 2. Scenes that should be beatable without taking damage cheats.
for (const id of ['field', 'bed']) {
  const S = sim.newGame({ players: 1, scene: id });
  const f = play(S, scripts[id], { max: 30000 });
  check('finish ' + id + ' without cheats', f > 0, f + ' frames');
}

// 3. The arena can be won before sunrise.
{
  const S = sim.newGame({ players: 1, scene: 'arena' });
  const f = play(S, scripts.arena, { god: true });
  check('arena won before sunrise', f > 0 && f < 10800, f + ' frames of 10800');
}

// 4. Doing nothing in the arena ends in sunrise and a retry.
{
  const S = sim.newGame({ players: 1, scene: 'arena' });
  let sawOver = false, tog = false;
  for (let f = 0; f < 12500 && !sawOver; f++) {
    tog = !tog;
    sim.step(S, [{ mx: 0, jump: false, act: S.mode === 'cut' && tog }]);
    S.players[0].hp = S.v.burn ? S.players[0].hp : 3;
    if (S.mode === 'over') sawOver = S.overWhy === 'sun';
  }
  check('sunrise ends the arena', sawOver);
  for (let f = 0; f < 60; f++) sim.step(S, [{ mx: 0, jump: false, act: f % 2 === 0 }]);
  check('retry after game over', S.mode === 'play' && S.scene === 'arena' && S.players[0].hp === 3);
}

// Watches the speech bubbles: always at most one, a real line in both languages, and new ones at least 8 s apart.
function talkWatch() {
  const w = { n: 0, minGap: Infinity, bad: '', last: -1, f: 0, prev: null };
  w.each = S => {
    w.f++;
    const t = S.talk;
    if (t !== null && (typeof t !== 'object' || Array.isArray(t) || (t.who !== 0 && t.who !== 1) || !DDN.TEXT.nl[t.k] || !DDN.TEXT.en[t.k])) w.bad = JSON.stringify(t);
    if (t && (S.msgT > 0 || ['h_still', 'h_stomp', 'h_fist', 'h_head'].includes(S.hint))) w.bad = 'bubble over a message or urgent hint: ' + t.k;
    if (t && !w.prev) {
      if (w.last >= 0) w.minGap = Math.min(w.minGap, w.f - w.last);
      w.last = w.f; w.n++;
    }
    w.prev = t;
  };
  w.ok = () => !w.bad && w.minGap >= sim.TALK_GAP;
  w.info = () => w.n + ' bubbles, shortest gap ' + (w.n > 1 ? w.minGap : '-') + ' frames' + (w.bad ? ', bad: ' + w.bad : '');
  return w;
}

// 5. Random two-player input in every scene, with the state copied as JSON along the way
//    (that is what online co-op sends), must never crash or produce broken numbers.
//    Power-ups are handed out along the way so they go through the round trip too.
for (const id of sim.ORDER) {
  let S = sim.newGame({ players: 2, scene: id }), err = null, frames = 0;
  const r = () => ({ mx: [-1, 0, 1][(Math.random() * 3) | 0], jump: Math.random() < 0.2, act: Math.random() < 0.3 });
  const talk = talkWatch();
  try {
    for (; frames < 15000; frames++) {
      if (frames % 600 === 300 && S.mode === 'play') {
        const p = S.players[(Math.random() * 2) | 0], kind = ['brain', 'gold', 'chick'][(Math.random() * 3) | 0];
        S.ents.push({ type: 'pow', kind, x: p.x + 20, y: G, vx: 0, vy: 0, air: false, t: 0 });
        if (frames % 1200 === 300) S.players[0].chick = sim.CHICK_T; else S.players[1].gold = sim.GOLD_T;
      }
      sim.step(S, [r(), r()]);
      talk.each(S);
      if (frames % 50 === 0) {
        const json = JSON.stringify(S);
        if (/null/.test(json.replace(/"(msg|hint|cut|scene|talk)":null/g, ''))) throw new Error('bad number in state: ' + json.slice(0, 300));
        S = JSON.parse(json);
      }
      if (S.mode === 'end') break;
    }
  } catch (e) { err = e; }
  check('random co-op input from ' + id, !err && talk.ok(), err ? err.stack.split('\n').slice(0, 3).join(' | ') : frames + ' frames, reached ' + S.scene + ', ' + talk.info());
}

// 6. The full game from the first cutscene to the end screen, through the turn and the giant.
{
  const S = sim.newGame({ players: 1 });
  let total = 0, ok = true;
  const cuts = new Set(), scenes = new Set([S.scene]), talk = talkWatch();
  const each = s => { if (s.cut) cuts.add(s.cut.id); scenes.add(s.scene); talk.each(s); };
  while (S.mode !== 'end' && ok) {
    const f = play(S, scripts[S.scene], { god: true, each });
    if (f < 0) ok = false; else total += f;
  }
  const route = ['intro', 'bedout', 'turn', 'ending'].every(c => cuts.has(c)) && sim.ORDER.every(id => scenes.has(id));
  check('full game start to end', ok && S.mode === 'end' && route, Math.round(total / 60) + ' seconds of play for a perfect bot, cutscenes: ' + [...cuts].join(' '));
  check('banter during the full game: one bubble at a time, 8 s apart', talk.ok() && talk.n >= 5, talk.info());
}

// 7. The giant can be beaten by kicking ducks under his feet and biting his head, before sunrise.
{
  const S = sim.newGame({ players: 1, scene: 'giant' });
  const seen = { n: S.evN };
  let slips = 0, kickSlips = 0, kicks = 0, headBites = 0, hpWhileUp = false, lastHp = 1000, lastSt = '', sunAtWin = 0;
  const f = play(S, scripts.giant, { god: true, max: 20000, each: s => {
    const g = s.ents.find(e => e.type === 'giant');
    for (const n of newEvents(s, seen)) if (n === 'quack') kicks++;
    if (!g) return;
    if (g.st === 'slip' && lastSt !== 'slip') { slips++; if (s.ents.some(e => e.type === 'duck' && e.st === 'fly' && e.k)) kickSlips++; }
    if (g.hp < lastHp) { headBites++; if (g.st !== 'down' && s.mode === 'play') hpWhileUp = true; }
    lastHp = g.hp; lastSt = g.st;
    if (s.mode === 'play') sunAtWin = s.v.sun;
  } });
  check('giant beaten with ducks and head bites', f > 0 && S.mode === 'end' && slips >= 4 && kickSlips === slips && headBites >= 17 && !hpWhileUp && sunAtWin < 1,
    f + ' frames, ' + kicks + ' kicks, ' + slips + ' slips (' + kickSlips + ' on a kicked duck), ' + headBites + ' head bites, sun ' + sunAtWin.toFixed(2) + ' at the win');
}

// 8. Biting him while he stands (in every pose) does nothing; lying down, only his head counts.
{
  const S = sim.newGame({ players: 1, scene: 'giant' });
  const seen = { n: S.evN };
  const g = S.ents.find(e => e.type === 'giant'), p = S.players[0];
  S.v.dt = 1e9;                                     // no ducks
  let clangs = 0, f = 0;
  const hold = (st, px, face) => {
    for (let i = 0; i < 160; i++, f++) {
      g.st = st; g.t = 5; g.x = 240; g.face = -1; g.cd = 9999; g.inv = 0; g.bites = 0;
      p.x = px; p.kb = 0; p.hp = 3; p.inv = 2; p.face = face;
      sim.step(S, [{ mx: 0, jump: false, act: i % 24 < 2 }]);
      for (const n of newEvents(S, seen)) if (n === 'clang') clangs++;
    }
  };
  for (const st of ['walk', 'stomp', 'fist', 'roar', 'getup', 'slip']) hold(st, 226, 1);
  check('biting the standing giant does no damage', g.hp === 1000 && clangs >= 30, 'leven ' + g.hp + ', ' + clangs + ' clangs in ' + f + ' frames');
  hold('down', 200, -1);                            // at his feet (facing left, he lies from 192 to 299)
  const feetHp = g.hp;
  hold('down', 272, 1);                             // at his head (288)
  check('lying down, only his head can be bitten', feetHp === 1000 && g.hp < 1000, 'feet: ' + feetHp + ', head: ' + g.hp);
}

// 9. The giant fight can be lost and is retried at 'giant', with the sunrise carried over from the arena and capped.
{
  const S = sim.newGame({ players: 1, scene: 'arena' });
  play(S, [(s) => ({})], { max: 120 });             // through the arena intro
  S.v.sun = 0.7;
  S.ents.find(e => e.type === 'thief').hp = 60;
  play(S, scripts.arena, { god: true });
  check('arena leads to the giant, sunrise capped', S.scene === 'giant' && S.v.sun === sim.SUN_CAP && S.sun0 === sim.SUN_CAP, S.scene + ', sun ' + S.v.sun);

  // walk into him until all hearts are gone
  let over = false;
  for (let f = 0; f < 6000 && !over; f++) {
    const g = S.ents.find(e => e.type === 'giant');
    sim.step(S, [{ mx: g ? Math.sign(g.x - S.players[0].x) : 0, jump: false, act: false }]);
    over = S.mode === 'over';
  }
  check('the giant can win', over && S.overWhy === '', 'mode ' + S.mode + ', why "' + S.overWhy + '"');
  for (let f = 0; f < 60; f++) sim.step(S, [{ mx: 0, jump: false, act: f % 2 === 0 }]);
  const g = S.ents.find(e => e.type === 'giant');
  check('retry starts at the giant', S.mode === 'play' && S.scene === 'giant' && g && g.hp === 1000 && S.players[0].hp === 3 && Math.abs(S.v.sun - sim.SUN_CAP) < 0.01,
    S.scene + ', leven ' + (g && g.hp) + ', sun ' + S.v.sun.toFixed(3));

  // a quick arena keeps its low sunrise value, and sunrise still ends the giant fight
  const S2 = sim.newGame({ players: 1, scene: 'arena' });
  play(S2, [(s) => ({})], { max: 120 });
  S2.v.sun = 0.1; S2.ents.find(e => e.type === 'thief').hp = 60;
  play(S2, scripts.arena, { god: true });
  const low = S2.v.sun;
  S2.v.sun = 0.999;
  let why = '';
  for (let f = 0; f < 400 && S2.mode !== 'over'; f++) sim.step(S2, [{ mx: 0, jump: false, act: false }]);
  why = S2.overWhy;
  for (let f = 0; f < 60; f++) sim.step(S2, [{ mx: 0, jump: false, act: f % 2 === 0 }]);
  check('sunrise ends the giant fight, retry keeps the carried sunrise', low > 0.1 && low < 0.2 && why === 'sun' && S2.scene === 'giant' && Math.abs(S2.v.sun - low) < 0.01,
    'carried ' + low.toFixed(3) + ', over: ' + why + ', retry sun ' + S2.v.sun.toFixed(3));
}

// 10. Random two-player input in the giant fight, with ducks dropped under his feet so he keeps falling over,
//     and the state copied as JSON along the way.
{
  let S = sim.newGame({ players: 2, scene: 'giant' }), err = null, frames = 0, falls = 0;
  const r = () => ({ mx: [-1, 0, 1][(Math.random() * 3) | 0], jump: Math.random() < 0.2, act: Math.random() < 0.3 });
  try {
    for (; frames < 15000; frames++) {
      const g = S.ents.find(e => e.type === 'giant');
      if (g && frames % 300 === 0 && g.st === 'walk') { S.ents.push({ type: 'duck', x: g.x, y: G, vx: 0, vy: 0, st: 'ground', t: 0, k: 1 }); falls++; }
      for (const p of S.players) { if (p.down) continue; p.hp = 3; }
      sim.step(S, [r(), r()]);
      if (frames % 50 === 0) {
        const json = JSON.stringify(S);
        if (/null/.test(json.replace(/"(msg|hint|cut|scene|talk)":null/g, ''))) throw new Error('bad number in state: ' + json.slice(0, 300));
        S = JSON.parse(json);
      }
      if (S.mode === 'end') break;
    }
  } catch (e) { err = e; }
  check('random co-op input in the giant fight with stuns', !err, err ? err.stack.split('\n').slice(0, 3).join(' | ') : frames + ' frames, ' + falls + ' ducks dropped, mode ' + S.mode);
}

// 10b. Nobody touches a key (the zombie cannot be hurt, so the run lasts): ducks the toilet throws are never
//      kicked, so he must never slip, however often he walks onto one.
{
  const S = sim.newGame({ players: 1, scene: 'giant' });
  const seen = { n: S.evN };
  let stunned = false, squeaks = 0;
  for (let f = 0; f < 9000; f++) {
    const p = S.players[0]; p.hp = 3; p.down = 0; p.inv = 2;
    sim.step(S, [{ mx: 0, jump: false, act: false }]);
    for (const n of newEvents(S, seen)) if (n === 'squeak') squeaks++;
    const g = S.ents.find(e => e.type === 'giant');
    if (g && (g.st === 'slip' || g.st === 'down')) stunned = true;
  }
  check('without kicks the giant never slips', !stunned && S.ents.find(e => e.type === 'giant').hp === 1000, '9000 frames, ' + squeaks + ' ducks squirted away from his feet');
}

// 11. Fairness alone: a careful bot without cheats (the AI partner cannot help). It is not perfect,
//     so only most of its tries have to succeed.
{
  let wins = 0, frames = 0;
  const N = 6;
  for (let i = 0; i < N; i++) {
    const S = sim.newGame({ players: 1, scene: 'giant' });
    let f = 0;
    for (; f < 20000 && S.mode === 'play'; f++) sim.step(S, [giantBot(S, S.players[0], f % 2 === 0, true)]);
    if (S.mode === 'cut' || S.mode === 'end') { wins++; frames += f; }
  }
  check('giant beatable alone without cheats', wins >= 4, wins + '/' + N + ' wins by a careful bot' + (wins ? ', ' + Math.round(frames / wins / 60) + ' s on average' : ''));
}

// ---------------------------------------------------------------- stage 2: power-ups, banter, details
const NONE = { mx: 0, jump: false, act: false };
function quiet(scene, players) { const S = sim.newGame({ players: players || 1, scene }); S.cut = null; S.mode = 'play'; return S; }
function putPow(S, kind, x, y) { S.ents.push({ type: 'pow', kind, x, y: y || G, vx: 0, vy: 0, air: false, t: 0 }); }
function hasPow(S, kind) { return S.ents.some(e => e.type === 'pow' && e.kind === kind); }
function run(S, n, inp) { for (let i = 0; i < n; i++) sim.step(S, [inp || NONE, NONE]); }

// 12. Brains: a heart back, but at full health they stay on the ground. The follower never picks anything up.
{
  const S = quiet('field'), p = S.players[0];
  p.hp = 1; putPow(S, 'brain', p.x); run(S, 1);
  const healed = p.hp === 2 && !hasPow(S, 'brain');
  p.hp = 3; putPow(S, 'brain', p.x); run(S, 30);
  const stays = p.hp === 3 && hasPow(S, 'brain');
  const ai = S.players[1]; putPow(S, 'gold', ai.x); run(S, 5);
  check('brains heal, stay put at full health; the follower picks nothing up', healed && stays && ai.gold === 0 && hasPow(S, 'gold'),
    'hp 1 -> ' + (healed ? 2 : '?') + ', full health: ' + (stays ? 'stays' : 'taken') + ', follower gold ' + ai.gold);
}

// 13. Gold paint: 8 s of no damage and 40% faster, then it wears off.
{
  const S = quiet('field'), p = S.players[0];
  putPow(S, 'gold', p.x); run(S, 1);
  const got = p.gold === sim.GOLD_T;
  let x0 = p.x; run(S, 20, { mx: 1 }); const fast = p.x - x0;
  run(S, sim.GOLD_T);
  x0 = p.x; run(S, 20, { mx: -1 }); const slow = x0 - p.x;
  p.gold = 100; putPow(S, 'gold', p.x); run(S, 1);
  const reset = p.gold === sim.GOLD_T; run(S, sim.GOLD_T);
  // hazards: a log in the chase
  const C = quiet('chase'), q = C.players[0];
  C.v.sp = 1e9; q.gold = sim.GOLD_T;
  C.ents.push({ type: 'log', x: q.x + 2 }); run(C, 12);
  const safe = q.hp === 3;
  q.gold = 0; q.inv = 0; C.ents.push({ type: 'log', x: q.x + 2 }); run(C, 12);
  check('gold paint: no damage, faster, wears off, a second pot resets the timer', got && reset && Math.abs(fast - 42) < 2 && Math.abs(slow - 30) < 2 && p.gold === 0 && safe && q.hp === 2,
    '20 frames: ' + fast.toFixed(1) + ' px with gold, ' + slow.toFixed(1) + ' px after; log with gold: hp ' + (safe ? 3 : '<3') + ', without: hp ' + q.hp);
}

// 14. The chicken: the bite reaches twice as far for 10 s.
{
  const S = quiet('field'), p = S.players[0];
  putPow(S, 'chick', p.x); run(S, 1);
  const got = p.chick === sim.CHICK_T;
  const reach = () => { let w = 0; for (let i = 0; i < 14; i++) { sim.step(S, [{ mx: 0, jump: false, act: i === 0 }, NONE]); const b = sim.biteBox(p); if (b) w = b.w; } run(S, 10); return w; };
  const long = reach();
  run(S, sim.CHICK_T);
  const short = reach();
  check('the chicken doubles the reach and wears off', got && long === 34 && short === 17 && p.chick === 0, 'reach ' + long + ' with the chicken, ' + short + ' after');
}

// 15. A chicken bite does double damage to bosses: thief and giant 120, the toilet 2 hits.
{
  const bite = (S, hold, chick) => {
    const p = S.players[0];
    for (let i = 0; i < 30; i++) { hold(S, p); p.chick = chick ? 300 : 0; p.inv = 2; sim.step(S, [{ mx: 0, jump: false, act: i === 0 }, NONE]); }
  };
  const thiefHold = (S, p) => { const th = S.ents.find(e => e.type === 'thief'); th.st = 'pant'; th.t = 0; th.x = p.x + 12; th.y = G; th.vx = 0; th.g = true; th.inv = th.inv > 0 ? th.inv : 0; p.face = 1; };
  const giantHold = (S, p) => { const g = S.ents.find(e => e.type === 'giant'); g.st = 'down'; g.t = 5; g.x = 240; g.face = -1; p.x = 272; p.face = 1; };
  const wcHold = (S, p) => { const wc = S.ents.find(e => e.type === 'wc'); wc.st = 'tired'; wc.t = 5; p.x = 360; p.face = 1; };
  const out = {};
  for (const chick of [false, true]) {
    let S = quiet('arena'); bite(S, thiefHold, chick); out['thief' + chick] = S.ents.find(e => e.type === 'thief').hp;
    S = quiet('giant'); bite(S, giantHold, chick); out['giant' + chick] = S.ents.find(e => e.type === 'giant').hp;
    S = quiet('bath'); bite(S, wcHold, chick); out['wc' + chick] = S.ents.find(e => e.type === 'wc').hp;
  }
  check('chicken bites do double damage to the bosses', out.thieffalse === 940 && out.thieftrue === 880 && out.giantfalse === 940 && out.gianttrue === 880 && out.wcfalse === 5 && out.wctrue === 4,
    'thief ' + out.thieffalse + '/' + out.thieftrue + ', giant ' + out.giantfalse + '/' + out.gianttrue + ', toilet ' + out.wcfalse + '/' + out.wctrue + ' (without/with)');
}

// 16. Power-up timers stand still in cutscenes, carry on into the next scene, and are gone after a retry.
{
  const S = sim.newGame({ players: 1, scene: 'arena' });          // starts in its intro
  S.players[0].gold = 300; S.players[0].chick = 400;
  let f = 0; while (S.mode === 'cut' && f++ < 3000) sim.step(S, [{ mx: 0, jump: false, act: f % 2 === 0 }]);
  const frozen = S.mode === 'play' && S.players[0].gold === 300 && S.players[0].chick === 400;
  // the last candle in the hall: hall outro, bath intro, then the bath fight
  const H = quiet('hall'), p = H.players[0];
  H.v.lit = 3; H.v.doneT = 1; p.gold = 300;
  sim.step(H, [NONE]);
  const before = p.gold, cutSeen = H.mode === 'cut';
  f = 0; while ((H.mode === 'cut' || H.scene !== 'bath') && f++ < 3000) sim.step(H, [{ mx: 0, jump: false, act: f % 2 === 0 }]);
  const carried = cutSeen && H.scene === 'bath' && H.mode === 'play' && H.players[0].gold === before;
  // a retry starts clean
  H.mode = 'over'; H.overT = 50; sim.step(H, [NONE]); sim.step(H, [{ mx: 0, jump: false, act: true }]);
  check('power-up timers stop in cutscenes, carry into the next scene, reset on retry', frozen && carried && H.players[0].gold === 0,
    'after the arena intro: ' + S.players[0].gold + '/' + S.players[0].chick + '; hall -> bath: ' + before + ' -> ' + (carried ? before : '?') + '; after retry: ' + H.players[0].gold);
}

// 16b. In the giant fight the toilet sometimes throws brains to a hurt zombie, but only while the giant is down:
//      when he stands and there is no duck, a duck is needed.
{
  const throwOnce = st => {
    const S = quiet('giant'), g = S.ents.find(e => e.type === 'giant');
    g.st = st; g.t = 5; g.cd = 9999; S.players[0].hp = 2; S.v.dt = 1;
    sim.step(S, [NONE, NONE]);
    return hasPow(S, 'brain') ? 'brain' : S.ents.some(e => e.type === 'duck') ? 'duck' : '';
  };
  const down = { brain: 0, duck: 0 }, up = { brain: 0, duck: 0 };
  for (let i = 0; i < 40; i++) { down[throwOnce('down')]++; up[throwOnce('walk')]++; }
  check('the toilet throws brains only while the giant is down', down.brain > 0 && down.duck > 0 && up.brain === 0 && up.duck === 40,
    'giant down: ' + down.brain + ' brains, ' + down.duck + ' ducks; giant standing: ' + up.brain + ' brains, ' + up.duck + ' ducks');
}

// 17. The garden gnome runs off when bitten; the toilet roll unrolls and the paper stays.
{
  const S = quiet('house'), p = S.players[0], gn = S.ents.find(e => e.type === 'gnome');
  p.x = gn.x - 10; p.face = 1;
  for (let i = 0; i < 12; i++) { p.inv = 2; sim.step(S, [{ mx: 0, jump: false, act: i === 0 }, NONE]); }
  const ran = gn.st === 'run';
  for (let i = 0; i < 200; i++) { p.inv = 2; sim.step(S, [NONE, NONE]); }
  const gone = !S.ents.some(e => e.type === 'gnome');
  const B = quiet('bath'), q = B.players[0];
  q.x = sim.ROLL_X - 12; q.face = 1;
  for (let i = 0; i < 400; i++) { q.inv = 2; q.hp = 3; sim.step(B, [{ mx: 0, jump: false, act: i === 0 }, NONE]); }
  check('the gnome and the toilet roll react to a bite', ran && gone && B.v.roll === 1 && B.v.paper === 150,
    'gnome ' + (ran ? 'ran' : 'stayed') + (gone ? ' and left' : '') + ', roll ' + B.v.roll + ', paper ' + B.v.paper + ' px');
}

// 18. The head-drops-off gag: only after 6 s of standing still somewhere safe, and any input ends it at once.
{
  const S = quiet('field'), p = S.players[0];
  run(S, sim.IDLE_GAG + 10);
  const started = p.idle >= sim.IDLE_GAG;
  const x0 = p.x; run(S, 1, { mx: 1 });
  const A = quiet('arena'); run(A, sim.IDLE_GAG + 10);
  check('idle gag after 6 s, any input ends it, never in the arena', started && p.idle === 0 && p.x > x0 && A.players[0].idle === 0,
    'idle ' + (started ? 'reached the gag' : 'did not start') + ', after one step of walking: idle ' + p.idle + ', moved ' + (p.x - x0).toFixed(1) + ' px');
}

// ---------------------------------------------------------------- stage 3: effects
// 19. Events can carry a position (and a value) for the effects. They must survive the JSON round trip
//     that online co-op does, old events without a position still work, and the list stays capped at 14.
{
  let S = sim.newGame({ players: 1, scene: 'giant' });
  const kinds = {}, counted = new Set();
  let longest = 0, bad = '', plain = 0;
  const each = s => {
    const copy = JSON.parse(JSON.stringify(s.evs));
    longest = Math.max(longest, s.evs.length);
    copy.forEach((e, i) => {
      const o = s.evs[i];
      if (e.n !== o.n || e.s !== o.s || e.x !== o.x || e.y !== o.y || e.v !== o.v) bad = JSON.stringify(o);
      if (counted.has(s.scene + o.n)) return;
      counted.add(s.scene + o.n);
      if (typeof o.x !== 'number') { plain++; return; }
      if (Number.isInteger(o.x) && Number.isInteger(o.y)) kinds[o.s] = (kinds[o.s] || 0) + 1; else bad = 'not whole pixels: ' + JSON.stringify(o);
    });
  };
  play(S, scripts.giant, { god: true, max: 20000, each });
  play(sim.newGame({ players: 1, scene: 'field' }), scripts.field, { god: true, each });       // the field bot always jumps
  check('events with positions survive the JSON round trip', !bad && kinds.bosshit > 0 && kinds.thud > 0 && kinds.land > 0 && plain > 0 && longest <= 14,
    Object.keys(kinds).map(k => k + ' ' + kinds[k]).join(', ') + ', ' + plain + ' without a position; longest list ' + longest + (bad ? '; bad: ' + bad : ''));
}

// 20. Drawing-only changes must not change the game: these two scripted scenes are fully predictable and
//     take exactly as many frames as before stage 3, and the full game still takes a similar time.
{
  const field = play(sim.newGame({ players: 1, scene: 'field' }), scripts.field, { god: true });
  const hall = play(sim.newGame({ players: 1, scene: 'hall' }), scripts.hall, { god: true });
  const S = sim.newGame({ players: 1 });
  let total = 0;
  while (S.mode !== 'end') { const f = play(S, scripts[S.scene], { god: true }); if (f < 0) break; total += f; }
  check('the game rules are unchanged by the effects', field === 462 && hall === 389 && S.mode === 'end' && total > 7000 && total < 14000,
    'field ' + field + ' frames (was 462), hall ' + hall + ' (was 389), full game ' + Math.round(total / 60) + ' s (stage 2 runs: 159-167 s)');
}

console.log(failed ? '\n' + failed + ' check(s) failed' : '\nAll checks passed');
process.exit(failed ? 1 : 0);
