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

// 5. Random two-player input in every scene, with the state copied as JSON along the way
//    (that is what online co-op sends), must never crash or produce broken numbers.
for (const id of sim.ORDER) {
  let S = sim.newGame({ players: 2, scene: id }), err = null, frames = 0;
  const r = () => ({ mx: [-1, 0, 1][(Math.random() * 3) | 0], jump: Math.random() < 0.2, act: Math.random() < 0.3 });
  try {
    for (; frames < 15000; frames++) {
      sim.step(S, [r(), r()]);
      if (frames % 50 === 0) {
        const json = JSON.stringify(S);
        if (/null/.test(json.replace(/"(msg|hint|cut|scene)":null/g, ''))) throw new Error('bad number in state: ' + json.slice(0, 300));
        S = JSON.parse(json);
      }
      if (S.mode === 'end') break;
    }
  } catch (e) { err = e; }
  check('random co-op input from ' + id, !err, err ? err.stack.split('\n').slice(0, 3).join(' | ') : frames + ' frames, reached ' + S.scene);
}

// 6. The full game from the first cutscene to the end screen, through the turn and the giant.
{
  const S = sim.newGame({ players: 1 });
  let total = 0, ok = true;
  const cuts = new Set(), scenes = new Set([S.scene]);
  const each = s => { if (s.cut) cuts.add(s.cut.id); scenes.add(s.scene); };
  while (S.mode !== 'end' && ok) {
    const f = play(S, scripts[S.scene], { god: true, each });
    if (f < 0) ok = false; else total += f;
  }
  const route = ['intro', 'bedout', 'turn', 'ending'].every(c => cuts.has(c)) && sim.ORDER.every(id => scenes.has(id));
  check('full game start to end', ok && S.mode === 'end' && route, Math.round(total / 60) + ' seconds of play for a perfect bot, cutscenes: ' + [...cuts].join(' '));
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
  check('giant beaten with ducks and head bites', f > 0 && S.mode === 'end' && slips >= 4 && kickSlips >= 1 && headBites >= 17 && !hpWhileUp && sunAtWin < 1,
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
      if (g && frames % 300 === 0 && g.st === 'walk') { S.ents.push({ type: 'duck', x: g.x, y: G, vx: 0, vy: 0, st: 'ground', t: 0, k: 0 }); falls++; }
      for (const p of S.players) { if (p.down) continue; p.hp = 3; }
      sim.step(S, [r(), r()]);
      if (frames % 50 === 0) {
        const json = JSON.stringify(S);
        if (/null/.test(json.replace(/"(msg|hint|cut|scene)":null/g, ''))) throw new Error('bad number in state: ' + json.slice(0, 300));
        S = JSON.parse(json);
      }
      if (S.mode === 'end') break;
    }
  } catch (e) { err = e; }
  check('random co-op input in the giant fight with stuns', !err, err ? err.stack.split('\n').slice(0, 3).join(' | ') : frames + ' frames, ' + falls + ' ducks dropped, mode ' + S.mode);
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

console.log(failed ? '\n' + failed + ' check(s) failed' : '\nAll checks passed');
process.exit(failed ? 1 : 0);
