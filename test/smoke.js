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
    if (S.scene !== scene || S.mode === 'end') return f;
  }
  return -1;
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
  }]
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

// 6. The full game from the first cutscene to the end screen.
{
  const S = sim.newGame({ players: 1 });
  let total = 0, ok = true;
  while (S.mode !== 'end' && ok) {
    const f = play(S, scripts[S.scene], { god: true });
    if (f < 0) ok = false; else total += f;
  }
  check('full game start to end', ok && S.mode === 'end', Math.round(total / 60) + ' seconds of play for a perfect bot');
}

console.log(failed ? '\n' + failed + ' check(s) failed' : '\nAll checks passed');
process.exit(failed ? 1 : 0);
