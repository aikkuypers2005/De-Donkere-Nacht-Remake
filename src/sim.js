// Game rules for De Donkere Nacht 2. No drawing in here, so it also runs in Node for testing.
// The whole game state S is plain data, which is what online co-op sends to the guest.
(function (root) {
  const DDN = root.DDN = root.DDN || {};
  const W = 480, H = 270, G = 216;           // screen size and ground height
  const ORDER = ['field', 'forest', 'house', 'hall', 'bath', 'bed', 'chase', 'arena', 'giant'];
  const CHAPTERS = ['field', 'house', 'bath', 'bed', 'arena'];
  const DOOR = 364;                          // front door of the house
  const ROLL_X = 300;                        // the toilet roll holder in the bathroom
  const CHASE_LEN = 5400;
  const SUN_FRAMES = 10800;                  // 3 minutes until sunrise
  const SUN_CAP = 0.4;                       // the giant fight starts at most this far into the sunrise
  const WC_X = 446, WC_Y = 172;              // the Laughing Toilet's seat in the arena stands
  const ZERO = { mx: 0, jump: false, act: false };
  const rnd = () => Math.random();
  const GOLD_T = 480, CHICK_T = 600;         // gold paint 8 s, the chicken 10 s
  const TALK_T = 150, TALK_GAP = 480;        // a speech bubble shows 2.5 s, at most one every 8 s
  const IDLE_GAG = 360, IDLE_END = 480;      // after 6 s standing still his head drops off for 2 s
  const URGENT = ['h_still', 'h_stomp', 'h_fist', 'h_head'];
  const HAZARD = ['bat', 'crow', 'rat', 'blob', 'wave'];

  function mkPlayer(i) {
    return { id: i, x: 30 + i * 22, y: G, vx: 0, vy: 0, face: 1, g: true, hp: 3, inv: 0, bite: 0, bh: false,
      down: 0, carry: 0, kb: 0, stun: 0, pj: false, pa: false, ai: false, blk: false, jumped: false, gold: 0, chick: 0, idle: 0 };
  }
  function ev(S, s) { S.evs.push({ n: ++S.evN, s }); if (S.evs.length > 14) S.evs.shift(); }
  function say(S, k) { S.msg = k; S.msgT = 150; }
  // A zombie says something in a bubble. once: only the first time in this game.
  function chat(S, k, who, once) {
    if (once && S.said[k]) return false;
    if (S.mode !== 'play' || S.talk || S.talkCd > 0 || S.msgT > 0 || URGENT.includes(S.hint)) return false;
    S.talk = { who: who === 0 || who === 1 ? who : (rnd() < 0.5 ? 0 : 1), k, t: TALK_T };
    S.talkCd = TALK_GAP;
    if (once) S.said[k] = 1;
    return true;
  }
  function humans(S) { return S.players.filter(p => !p.ai); }
  function alive(S) { return humans(S).filter(p => p.down === 0); }
  function pbox(p) { return { x: p.x - 5, y: p.y - 26, w: 10, h: 26 }; }
  function hit(a, b) { return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y; }
  // With the chicken in his hand a zombie bites twice as far.
  function biteBox(p) {
    if (p.down || p.bite < 6 || p.bite > 16) return null;
    const w = p.chick > 0 ? 34 : 17;
    return { x: p.face > 0 ? p.x : p.x - w, y: p.y - 26, w, h: 24 };
  }
  function power(p) { return p.chick > 0 ? 2 : 1; }     // bosses take double damage from a chicken bite
  // A bite that has not hit anything yet and overlaps box b.
  function bites(p, b) {
    const bb = biteBox(p);
    if (!bb || p.bh || !hit(bb, b)) return false;
    p.bh = true;
    return true;
  }
  function nearest(S, x) {
    let best = null;
    for (const p of alive(S)) if (!best || Math.abs(p.x - x) < Math.abs(best.x - x)) best = p;
    return best;
  }
  function hurt(S, p, dir) {
    if (p.inv > 0 || p.down > 0 || p.ai || p.gold > 0) return false;
    p.hp--; p.inv = 90; p.kb = dir * 3; p.vy = -2.5; p.g = false;
    if (p.carry > 0) p.carry = 0;
    S.shake = 5; ev(S, 'hurt');
    if (typeof S.v.boo === 'number') S.v.boo = 50;     // the ghost audience boos
    if (p.hp <= 0) { p.down = 1; ev(S, 'down'); }
    else chat(S, rnd() < 0.5 ? 'z_hurt1' : 'z_hurt2', p.id);
    return true;
  }
  function remove(S, pred) { S.ents = S.ents.filter(e => !pred(e)); }
  // A power-up lying in the world: 'brain', 'gold' or 'chick'. air: falling, vx: carried along (the chase).
  function pow(S, kind, x, y, extra) { S.ents.push(Object.assign({ type: 'pow', kind, x, y, vx: 0, vy: 0, air: false, t: 0 }, extra || {})); }
  // Standing still is only safe when nothing dangerous is near (for the head-drops-off gag).
  function calm(S, p) {
    const sc = SC[S.scene];
    if (sc.running || S.scene === 'bath' || S.scene === 'arena' || S.scene === 'giant') return false;
    return !S.ents.some(e => HAZARD.includes(e.type) && Math.abs(e.x - p.x) < 140);
  }
  // The ghost audience in the arena stands: cheering and booing fade out, now and then they do a wave.
  function crowd(v) {
    if (v.cheer > 0) v.cheer--;
    if (v.boo > 0) v.boo--;
    if (v.wave > 0) v.wave--; else if (rnd() < 1 / 700) v.wave = 150;
  }

  // ------------------------------------------------------------------ scenes
  const SC = {};

  // Chapter 1a: tutorial. Jump the tombstones, bite the gate open.
  SC.field = {
    intro: 'intro', next: 'forest', chapter: 1,
    solids: [{ x: 140, y: 200, w: 14, h: 16, k: 'tomb' }, { x: 245, y: 194, w: 16, h: 22, k: 'tomb2' }],
    plats: [],
    init(S) { S.v = { gate: 3, open: false }; pow(S, 'chick', 278, G); },      // the chicken waits behind the second tombstone
    goal(S) { return S.v.open ? { k: 'g_go' } : { k: 'g_field' }; },
    maxX(S) { return S.v.open ? W + 10 : 392; },
    update(S) {
      const v = S.v, lead = humans(S)[0];
      S.hint = lead.x < 110 ? 'h_move' : lead.x < 275 ? 'h_jump' : !v.open ? 'h_bite' : null;
      if (lead.x > 128) chat(S, 'z_tomb', lead.id, true);
      if (!v.open) for (const p of humans(S)) {
        if (bites(p, { x: 398, y: 170, w: 12, h: 46 })) {
          v.gate--; S.shake = 6; ev(S, 'hit');
          if (v.gate <= 0) { v.open = true; ev(S, 'door'); }
        }
      }
    }
  };

  // Chapter 1b: collect 5 orange threads from the branches while bats swoop.
  SC.forest = {
    next: 'house', chapter: 1,
    solids: [],
    plats: [{ x: 52, y: 178, w: 46 }, { x: 128, y: 150, w: 46 }, { x: 226, y: 178, w: 46 }, { x: 292, y: 142, w: 44 }, { x: 372, y: 176, w: 46 }],
    init(S) {
      S.v = { open: false, got: 0, spawn: 120,
        sc: [{ x: 75, y: 168 }, { x: 150, y: 140 }, { x: 205, y: 206 }, { x: 314, y: 132 }, { x: 395, y: 166 }] };
      pow(S, 'gold', 328, 142);                    // gold paint on the end of the highest branch
    },
    goal(S) { return S.v.open ? { k: 'g_go' } : { k: 'g_forest', n: S.v.got, of: 5 }; },
    update(S) {
      const v = S.v;
      for (const s of v.sc) {
        if (s.got) continue;
        for (const p of humans(S)) if (!p.down && hit(pbox(p), { x: s.x - 5, y: s.y - 5, w: 10, h: 10 })) {
          s.got = 1; v.got++; ev(S, 'pick');
          if (v.got >= 5) { v.open = true; ev(S, 'door'); }
          break;
        }
      }
      const bats = S.ents.filter(e => e.type === 'bat');
      const max = humans(S).length > 1 ? 3 : 2;
      if (!v.open && bats.length < max && --v.spawn <= 0) {
        v.spawn = 200;
        const left = rnd() < 0.5;
        S.ents.push({ type: 'bat', x: left ? -10 : W + 10, y: 60, by: 66 + rnd() * 36, dir: left ? 1 : -1, t: 0, st: 0, cd: 120 + rnd() * 100, tx: 0, ty: 0 });
      }
      for (const b of bats) {
        b.t++;
        if (v.open) b.st = 3;
        if (b.st === 0) {
          b.x += b.dir * 1.1;
          if (b.x < 20 && b.dir < 0) b.dir = 1;
          if (b.x > W - 20 && b.dir > 0) b.dir = -1;
          b.y += (b.by + Math.sin(b.t / 14) * 8 - b.y) * 0.1;
          const t = nearest(S, b.x);
          if (--b.cd <= 0 && t && Math.abs(t.x - b.x) < 200) { b.st = 1; b.tx = t.x; b.ty = t.y - 14; b.tt = 0; }
        } else if (b.st === 1) {
          const dx = b.tx - b.x, dy = b.ty - b.y, d = Math.hypot(dx, dy);
          if (d < 3 || ++b.tt > 80) b.st = 2;
          else { b.x += dx / d * 2.5; b.y += dy / d * 2.5; }
        } else if (b.st === 2) {
          b.y -= 1.4; b.x += b.dir * 0.8;
          if (b.y <= b.by) { b.st = 0; b.cd = 150 + rnd() * 120; }
        } else { b.y -= 2.2; b.x += b.dir; }
        const box = { x: b.x - 6, y: b.y - 4, w: 12, h: 8 };
        for (const p of humans(S)) {
          if (bites(p, box)) {
            b.dead = 1; ev(S, 'pop'); chat(S, 'z_bat', p.id, true);
            if (rnd() < 1 / 3) pow(S, 'brain', b.x, b.y, { air: true });   // one bat in three drops brains
            break;
          }
          if (!p.down && hit(pbox(p), box)) hurt(S, p, p.x < b.x ? -1 : 1);
        }
      }
      remove(S, e => e.type === 'bat' && (e.dead || e.y < -20));
    }
  };

  // Chapter 2a: bite the crow that carries the key, then open the door.
  SC.house = {
    intro: 'house', next: 'hall', chapter: 2,
    solids: [{ x: 120, y: 198, w: 18, h: 18, k: 'crate' }, { x: 138, y: 182, w: 22, h: 34, k: 'crate2' }],
    plats: [],
    init(S) {
      S.v = { open: false, key: false };
      S.ents.push({ type: 'crow', x: 220, y: 150, dir: 1, hp: 2, t: 0, st: 0, cd: 220, inv: 0, tx: 0, ty: 0 });
      S.ents.push({ type: 'gnome', x: 96, st: 'stand', dir: 1, t: 0 });   // a garden gnome by the bushes
      pow(S, 'brain', 149, 182);                                           // brains on top of the high crate
    },
    goal(S) { return { k: S.v.key ? 'g_house2' : 'g_house' }; },
    interact(S, p) {
      if (Math.abs(p.x - DOOR) > 16 || p.y < G - 2) return false;
      if (S.v.key) { ev(S, 'door'); complete(S); } else say(S, 'm_locked');
      return true;
    },
    update(S) {
      const v = S.v;
      for (const c of S.ents) {
        if (c.type === 'crow') {
          c.t++; if (c.inv > 0) c.inv--;
          const base = c.hp >= 2 ? 150 : 132;
          if (c.st === 0) {
            c.x += c.dir * (c.hp >= 2 ? 1.2 : 1.7);
            if (c.x < 40 && c.dir < 0) c.dir = 1;
            if (c.x > 330 && c.dir > 0) c.dir = -1;
            c.y += (base + Math.sin(c.t / 20) * 5 - c.y) * 0.1;
            const t = nearest(S, c.x);
            if (--c.cd <= 0 && t && Math.abs(t.x - c.x) < 180) { c.st = 1; c.tx = t.x; c.ty = t.y - 20; c.tt = 0; }
          } else if (c.st === 1) {
            const dx = c.tx - c.x, dy = c.ty - c.y, d = Math.hypot(dx, dy);
            if (d < 3 || ++c.tt > 80) c.st = 2;
            else { c.x += dx / d * 2.3; c.y += dy / d * 2.3; if (dx) c.dir = dx > 0 ? 1 : -1; }
          } else if (c.st === 2) {
            c.y -= 1.3; c.x += c.dir * 0.8;
            if (c.y <= base) { c.st = 0; c.cd = 170 + rnd() * 120; }
          } else { c.y -= 2; c.x += c.dir * 1.5; }
          const box = { x: c.x - 6, y: c.y - 5, w: 12, h: 9 };
          if (c.st !== 3) for (const p of humans(S)) {
            if (c.inv <= 0 && bites(p, box)) {
              c.hp--; c.inv = 40; c.st = 2; ev(S, 'caw');
              if (c.hp <= 0) { c.st = 3; S.ents.push({ type: 'key', x: c.x, y: c.y, vy: 0 }); }
              break;
            }
            if (c.st === 1 && !p.down && hit(pbox(p), box)) { hurt(S, p, p.x < c.x ? -1 : 1); c.st = 2; }
          }
        } else if (c.type === 'key') {
          c.vy += 0.25; c.y = Math.min(G - 4, c.y + c.vy);
          for (const p of humans(S)) if (!p.down && hit(pbox(p), { x: c.x - 5, y: c.y - 5, w: 10, h: 10 })) {
            c.dead = 1; v.key = true; ev(S, 'pick'); say(S, 'm_key'); break;
          }
        } else if (c.type === 'gnome') {
          // bite the gnome and it shrieks and runs off. That is all it does.
          if (c.st === 'stand') {
            for (const p of humans(S)) if (bites(p, { x: c.x - 5, y: G - 14, w: 10, h: 14 })) {
              c.st = 'run'; c.t = 0; c.dir = p.x < c.x ? 1 : -1; ev(S, 'shriek'); chat(S, 'z_gnome', p.id); break;
            }
          } else { c.t++; c.x += c.dir * 2.6; if (c.x < -20 || c.x > W + 20) c.dead = 1; }
        }
      }
      if (v.key && S.msgT === 0) chat(S, 'z_key', null, true);
      remove(S, e => e.dead || (e.type === 'crow' && e.y < -20));
    }
  };

  // Chapter 2b: carry the flame to three candles. Rats run across the floor.
  SC.hall = {
    outro: 'hall', next: 'bath', chapter: 2,
    solids: [{ x: 150, y: 192, w: 36, h: 24, k: 'dresser' }, { x: 340, y: 196, w: 22, h: 20, k: 'chair' }, { x: 362, y: 172, w: 38, h: 44, k: 'shelf' }],
    plats: [],
    init(S) {
      S.v = { open: false, lit: 0, rat: 240, doneT: 0,
        c: [{ x: 60, y: 192, lit: 1 }, { x: 168, y: 152, lit: 0 }, { x: 312, y: 182, lit: 0 }, { x: 398, y: 130, lit: 0 }] };
      pow(S, 'gold', 374, 172);                    // gold paint on the shelf, right before the toilet fight
    },
    goal(S) { return { k: 'g_hall', n: S.v.lit, of: 3 }; },
    interact(S, p) {
      const v = S.v;
      for (const c of v.c) {
        const dy = p.y - c.y;
        if (Math.abs(p.x - c.x) > 13 || dy < 0 || dy > 52) continue;
        if (c.lit) { p.carry = 480; ev(S, 'flame'); }
        else if (p.carry > 0) {
          c.lit = 1; v.lit++; ev(S, 'light'); chat(S, 'z_candle', p.id, true);
          if (v.lit >= 3) v.doneT = 70;
        } else say(S, 'h_flame');
        return true;
      }
      return false;
    },
    update(S) {
      const v = S.v;
      if (v.doneT > 0) { if (--v.doneT === 0) complete(S); return; }
      let carrying = false;
      for (const p of humans(S)) if (p.carry > 0) { carrying = true; if (--p.carry === 0) say(S, 'm_out'); }
      S.hint = carrying ? 'h_flame2' : 'h_flame';
      chat(S, 'z_dark', null, true);
      const rats = S.ents.filter(e => e.type === 'rat');
      if (rats.length < 2 && --v.rat <= 0) {
        v.rat = 200 + rnd() * 80;
        const left = rnd() < 0.5;
        S.ents.push({ type: 'rat', x: left ? -10 : W + 10, dir: left ? 1 : -1, t: 0 });
      }
      for (const r of rats) {
        r.t++; r.x += r.dir * 1.3;
        const box = { x: r.x - 6, y: G - 6, w: 12, h: 6 };
        for (const p of humans(S)) {
          if (bites(p, box)) { r.dead = 1; ev(S, 'pop'); break; }
          if (!p.down && hit(pbox(p), box)) hurt(S, p, p.x < r.x ? -1 : 1);
        }
      }
      remove(S, e => e.type === 'rat' && (e.dead || e.x < -20 || e.x > W + 20));
    }
  };

  // Chapter 3: the Laughing Toilet. Bite it while the lid is open.
  SC.bath = {
    intro: 'bath', outro: 'bathout', next: 'bed', chapter: 3,
    solids: [], plats: [],
    init(S) {
      S.v = { open: false, roll: 0, paper: 0 };
      S.ents.push({ type: 'wc', x: 384, hp: 6, st: 'laugh', t: 0, n: 0, inv: 0 });
      pow(S, 'brain', 340, G);                     // brains, right where the toilet spits
    },
    goal(S) { const wc = S.ents.find(e => e.type === 'wc'); return { k: 'g_bath', n: wc ? 6 - wc.hp : 6, of: 6 }; },
    maxX() { return 364; },
    update(S) {
      const wc = S.ents.find(e => e.type === 'wc');
      if (!wc) return;
      const mad = wc.hp <= 3;
      wc.t++; if (wc.inv > 0) wc.inv--;
      if (wc.st === 'laugh') {
        if (wc.t === 1) ev(S, 'laugh');
        if (wc.t > (mad ? 50 : 70)) { wc.st = 'spit'; wc.t = 0; wc.n = 0; }
      } else if (wc.st === 'spit') {
        const every = mad ? 18 : 25, shots = mad ? 5 : 3;
        if (wc.t % every === 10 && wc.n < shots) {
          wc.n++;
          const pl = alive(S), t = pl[(rnd() * pl.length) | 0];
          const tx = t ? t.x + t.vx * 20 : 200;
          S.ents.push({ type: 'blob', x: 374, y: 182, vx: (tx - 374) / 53, vy: -4.2 });
          ev(S, 'spit');
        }
        if (wc.t > every * shots + 20) { wc.st = 'flush'; wc.t = 0; }
      } else if (wc.st === 'flush') {
        if (wc.t === 1) ev(S, 'flush');
        if (wc.t === 40 || (mad && wc.t === 78)) { S.ents.push({ type: 'wave', x: 366, vx: -2.8 }); S.shake = 6; }
        if (wc.t > 105) { wc.st = 'tired'; wc.t = 0; }
      } else if (wc.st === 'tired') {
        if (wc.t > (mad ? 100 : 130)) { wc.st = 'laugh'; wc.t = 0; }
      } else if (wc.st === 'ouch') {
        if (wc.t > 35) { wc.st = 'laugh'; wc.t = 0; }
      }
      const open = wc.st === 'spit' || wc.st === 'tired';
      chat(S, 'z_wc', null, true);
      if (S.v.roll && S.v.paper < 150) S.v.paper = Math.min(150, S.v.paper + 2.5);
      for (const p of humans(S)) {
        // the toilet roll on the wall: bite it and the paper unrolls across the floor, and stays there
        if (!S.v.roll && bites(p, { x: ROLL_X - 6, y: 190, w: 12, h: 12 })) { S.v.roll = 1; ev(S, 'unroll'); chat(S, 'z_roll', p.id); continue; }
        if (bites(p, { x: 370, y: 176, w: 28, h: 40 })) {
          if (open && wc.inv <= 0) {
            wc.hp = Math.max(0, wc.hp - power(p)); wc.inv = 30; wc.st = 'ouch'; wc.t = 0; S.shake = 8; ev(S, 'bosshit');
            if (wc.hp <= 0) { remove(S, e => e.type !== 'wc'); complete(S); return; }
          } else ev(S, 'clang');
        }
      }
      for (const e of S.ents) {
        if (e.type === 'blob') {
          e.x += e.vx; e.y += e.vy; e.vy += 0.18;
          if (e.y >= G - 3) { e.dead = 1; ev(S, 'splash'); }
          for (const p of humans(S)) if (!p.down && hit(pbox(p), { x: e.x - 4, y: e.y - 4, w: 8, h: 8 })) { if (hurt(S, p, -1)) e.dead = 1; }
        } else if (e.type === 'wave') {
          e.x += e.vx;
          if (e.x < -20) e.dead = 1;
          for (const p of humans(S)) if (!p.down && hit(pbox(p), { x: e.x - 7, y: G - 13, w: 14, h: 13 })) hurt(S, p, -1);
        }
      }
      remove(S, e => e.dead);
    }
  };

  // Chapter 4a: sneak to the bed. Only move while he snores.
  SC.bed = {
    intro: 'bed', outro: 'bedout', next: 'chase', chapter: 4,
    solids: [], plats: [],
    init(S) {
      S.v = { open: false, noise: 0, ph: 'snore', pt: 170, mum: 0, d: [{ x: 140, cd: 0 }, { x: 215, cd: 0 }, { x: 285, cd: 0 }] };
      pow(S, 'gold', 304, G);                      // gold paint just past the last squeaky duck
    },
    goal() { return { k: 'g_bed' }; },
    maxX() { return 342; },
    update(S) {
      const v = S.v;
      if (--v.pt <= 0) {
        if (v.ph === 'snore') { v.ph = 'stir'; v.pt = 40; ev(S, 'huh'); }
        else if (v.ph === 'stir') { v.ph = 'listen'; v.pt = 80; }
        else { v.ph = 'snore'; v.pt = 110 + rnd() * 70; v.mum = (v.mum + 1) % 4; }   // he mumbles something new in his sleep
      }
      if (v.ph === 'snore' && S.tick % 70 === 0) ev(S, 'snore');
      const hs = alive(S);
      const moving = hs.some(p => Math.abs(p.vx) > 0.2 || !p.g);
      if (v.ph === 'listen' && moving) v.noise += 2.4;
      v.noise = Math.max(0, v.noise - 0.12);
      for (const d of v.d) {
        if (d.cd > 0) { d.cd--; continue; }
        for (const p of hs) if (p.g && Math.abs(p.x - d.x) < 6) { v.noise += 40; d.cd = 50; ev(S, 'squeak'); chat(S, 'z_duck', p.id); break; }
      }
      S.hint = v.ph === 'snore' ? 'h_walk' : 'h_still';
      if (v.noise >= 100) {
        v.noise = 0; v.ph = 'snore'; v.pt = 170; ev(S, 'alarm'); say(S, 'm_caught'); S.shake = 10;
        for (const p of hs) {
          if (!p.gold) p.hp--;                     // gold paint keeps you safe, but you still go back
          p.inv = 90; p.x = 30 + p.id * 22; p.y = G; p.vy = 0;
          if (p.hp <= 0) { p.down = 1; ev(S, 'down'); }
        }
        for (const p of S.players) if (p.ai) { p.x = 52; p.y = G; }
        return;
      }
      if (hs.some(p => p.x >= 338)) complete(S);
    }
  };

  // Chapter 4b: the chase. The thief throws things; keep up until the arena.
  SC.chase = {
    next: 'arena', chapter: 4, running: true,
    solids: [], plats: [],
    init(S) { S.v = { open: false, dist: 0, sp: 100, thr: 0, pw: 0 }; for (const p of S.players) p.x = 90 + p.id * 26; },
    goal(S) { return { k: 'g_chase', bar: S.v.dist / CHASE_LEN }; },
    minX() { return 10; },
    maxX() { return 300; },
    update(S) {
      const v = S.v, prog = v.dist / CHASE_LEN;
      v.dist += 2; if (v.thr > 0) v.thr--;
      if (v.dist >= CHASE_LEN) { complete(S); return; }
      chat(S, 'z_chase', null, true);
      // halfway, brains come floating along at jumping height
      if (!v.pw && v.dist >= 2600) { v.pw = 1; pow(S, 'brain', W + 10, G - 34, { vx: -2 }); }
      if (--v.sp <= 0 && prog < 0.95) {
        v.sp = 105 - 45 * prog + rnd() * 30;
        const r = rnd(), t = alive(S)[0];
        if (r < 0.3) S.ents.push({ type: 'log', x: W + 12 });
        else if (r < 0.55) { S.ents.push({ type: 'pillow', x: 424, y: G - 22, vx: -3.4, vy: -1.5 }); v.thr = 16; ev(S, 'throw'); }
        else if (r < 0.8 || prog < 0.15) {
          const tx = (t ? t.x : 150) - 20;
          S.ents.push({ type: 'lamp', x: 424, y: G - 24, vx: (tx - 424) / 60, vy: -5 }); v.thr = 16; ev(S, 'throw');
        } else S.ents.push({ type: 'cbat', x: W + 10, y: G - 34 });
      }
      for (const e of S.ents) {
        let box = null;
        if (e.type === 'log') { e.x -= 2; box = { x: e.x - 7, y: G - 9, w: 14, h: 9 }; }
        else if (e.type === 'fire') { e.x -= 2; e.t++; box = { x: e.x - 6, y: G - 10, w: 12, h: 10 }; }
        else if (e.type === 'cbat') { e.x -= 3.6; box = { x: e.x - 6, y: e.y - 4, w: 12, h: 8 }; }
        else if (e.type === 'pillow') {
          e.x += e.vx; e.y += e.vy; e.vy += 0.2;
          if (e.y >= G - 4) { e.y = G - 4; e.vy = -2.6; }
          box = { x: e.x - 6, y: e.y - 4, w: 12, h: 8 };
        } else if (e.type === 'lamp') {
          e.x += e.vx; e.y += e.vy; e.vy += 0.18;
          if (e.y >= G - 4) { e.type = 'fire'; e.t = 0; ev(S, 'smash'); continue; }
          box = { x: e.x - 4, y: e.y - 4, w: 8, h: 8 };
        }
        if (!box) continue;
        if (e.x < -20) { e.dead = 1; continue; }
        for (const p of humans(S)) if (!p.down && hit(pbox(p), box)) {
          if (hurt(S, p, -1)) { p.kb = -4; p.stun = 20; if (e.type === 'pillow' || e.type === 'cbat' || e.type === 'lamp') e.dead = 1; }
        }
      }
      remove(S, e => e.dead);
    }
  };

  // Chapter 5: the arena. Three phases against leven = 1000, before the sun is up.
  SC.arena = {
    intro: 'arena', outro: 'turn', next: 'giant', chapter: 5,
    solids: [], plats: [],
    init(S) {
      S.v = { open: false, sun: 0, burn: false, cheer: 0, boo: 0, wave: 0 };
      S.ents.push({ type: 'thief', x: 400, y: G, vx: 0, vy: 0, g: true, face: -1, hp: 1000, st: 'run', t: 0, n: 0, inv: 0, hits: 0, stomp: false });
      pow(S, 'chick', 456, G);                     // the chicken, behind the thief in the far corner
    },
    goal(S) { return { k: 'g_arena' }; },
    update(S) {
      const v = S.v, th = S.ents.find(e => e.type === 'thief');
      v.sun += 1 / SUN_FRAMES;
      crowd(v);
      if (v.sun >= 1 && !v.burn) {
        v.burn = true; ev(S, 'burn');
        for (const p of humans(S)) if (!p.down) { p.hp = 0; p.down = 1; }
      }
      if (!th) return;
      const ph = th.hp > 700 ? 1 : th.hp > 350 ? 2 : 3;
      const tg = nearest(S, th.x);
      th.t++; if (th.inv > 0) th.inv--;
      const d = tg ? th.x - tg.x : 200;
      if (th.st === 'run') {
        const dir = d >= 0 ? 1 : -1;
        th.vx = Math.abs(d) < 110 ? dir * (ph === 1 ? 1.7 : 1.9) : 0;
        th.face = th.vx ? dir : -dir;
        const cornered = (th.x < 26 && dir < 0) || (th.x > W - 26 && dir > 0);
        if (cornered && Math.abs(d) < 60 && th.g) { th.vy = -6.4; th.g = false; th.vx = -dir * 3.2; th.st = 'leap'; ev(S, 'jump'); }
        else if (th.t > (ph === 1 ? 110 : 80) && th.g) { th.st = 'atk'; th.t = 0; th.n = 0; th.vx = 0; }
      } else if (th.st === 'leap') {
        if (th.g) { th.st = 'run'; th.vx = 0; }
      } else if (th.st === 'atk') {
        th.vx = 0; th.face = d >= 0 ? -1 : 1;
        const L = ph === 1 ? 55 : ph === 2 ? 50 : 70, cnt = ph === 3 ? 2 : 3;
        const tx = tg ? tg.x : 240;
        if (th.t % L === 25 && th.n < cnt) {
          if (ph === 1) { S.ents.push({ type: 'rock', x: th.x, y: th.y - 22, vx: (tx - th.x) / 55, vy: -4.6 }); ev(S, 'throw'); }
          else if (ph === 2) { S.ents.push({ type: 'fball', x: th.x + th.face * 8, y: G - 8, vx: th.face * 3, t: 0 }); ev(S, 'fire'); }
          else if (th.n % 2 === 0) { th.vy = -7; th.g = false; th.stomp = true; ev(S, 'jump'); }
          else { for (const o of [-44, 0, 44]) S.ents.push({ type: 'rock', x: th.x, y: th.y - 22, vx: (tx + o - th.x) / 55, vy: -4.6 }); ev(S, 'throw'); }
          th.n++;
        }
        if (th.n >= cnt && th.t % L === L - 1) { th.st = 'pant'; th.t = 0; th.hits = 0; }
      } else if (th.st === 'pant') {
        th.vx = 0;
        if (th.t > (ph === 1 ? 160 : ph === 2 ? 130 : 105) || th.hits >= 2) { th.st = 'run'; th.t = 0; }
      }
      th.x = Math.max(16, Math.min(W - 16, th.x + th.vx));
      th.vy += 0.32; th.y += th.vy;
      if (th.y >= G) {
        th.y = G; th.vy = 0;
        if (!th.g && th.stomp) {
          th.stomp = false; S.shake = 10; ev(S, 'thud');
          S.ents.push({ type: 'shock', x: th.x - 8, vx: -2.6 }, { type: 'shock', x: th.x + 8, vx: 2.6 });
        }
        th.g = true;
      }
      for (const p of humans(S)) {
        if (th.inv <= 0 && bites(p, { x: th.x - 5, y: th.y - 26, w: 10, h: 26 })) {
          th.hp -= 60 * power(p); th.inv = 35; th.hits++; S.shake = 6; ev(S, 'bosshit'); v.cheer = 50;
          th.x = Math.max(16, Math.min(W - 16, th.x + p.face * 6));
          if (th.hp <= 0) { th.hp = 0; remove(S, e => e.type !== 'thief'); complete(S); return; }
          // two bites in a row and he jumps away
          if (th.hits >= 2 && th.g) {
            const away = (th.x - p.x >= 0 ? 1 : -1) * (th.x > W - 80 ? -1 : th.x < 80 ? -1 : 1);
            th.vy = -6.2; th.g = false; th.vx = away * 3; th.st = 'leap'; th.t = 0; th.hits = 0; th.stomp = false;
          }
        }
      }
      for (const e of S.ents) {
        let box = null;
        if (e.type === 'rock') {
          e.x += e.vx; e.y += e.vy; e.vy += 0.18;
          if (e.y >= G - 3) { e.dead = 1; ev(S, 'thud'); }
          box = { x: e.x - 4, y: e.y - 4, w: 8, h: 8 };
        } else if (e.type === 'fball') { e.x += e.vx; e.t++; box = { x: e.x - 5, y: e.y - 5, w: 10, h: 10 }; }
        else if (e.type === 'shock') { e.x += e.vx; box = { x: e.x - 6, y: G - 10, w: 12, h: 10 }; }
        if (!box) continue;
        if (e.x < -20 || e.x > W + 20) e.dead = 1;
        for (const p of humans(S)) if (!p.down && hit(pbox(p), box)) {
          if (hurt(S, p, e.vx < 0 ? -1 : 1) && e.type === 'rock') e.dead = 1;
        }
      }
      remove(S, e => e.dead);
    }
  };

  // Chapter 5b: the bitten thief has grown into a giant. He cannot be hurt standing up,
  // so make him slip on a rubber duck from the Laughing Toilet, then bite his head.
  const REACH = 34;                          // how far in front of him his fist lands
  const STOMP_UP = 45, FIST_UP = 50, STUN = 300, MAX_BITES = 5;
  const G_SPEED = [0, 0.6, 0.75, 0.9], G_CD = [0, 190, 150, 115], DUCK_EVERY = [0, 150, 130, 110];
  const HECKLE = ['w_h1', 'w_h2', 'w_h3', 'w_h4'];
  function wcSay(S, k) { S.v.ws = k; S.v.wsT = 140; }
  function clamp(x, lo, hi) { return Math.max(lo, Math.min(hi, x)); }
  // Lying on his back he is 106 px long, head behind him: keep all of him inside the arena.
  function lieRange(g) { return g.face > 0 ? [62, W - 52] : [52, W - 62]; }
  function headBox(g) { const hx = g.x - g.face * 48; return { x: hx - 11, y: G - 22, w: 22, h: 22 }; }
  function slip(S, g, d) {
    g.st = 'slip'; g.t = 0; g.fx = 0;
    d.st = 'fly'; d.t = 0; d.y = G - 4; d.vx = -g.face * 1.5; d.vy = -5;
    ev(S, 'squeak'); wcSay(S, 'w_slip'); S.v.cheer = 50; chat(S, 'z_slip');
  }
  // Only a duck a zombie has kicked makes him slip. One that is just lying there squirts away from his foot.
  function duckUnder(S, g, d) {
    if (d.k) { slip(S, g, d); return true; }
    d.vx = (d.x < g.x ? -1 : 1) * 2.2;
    ev(S, 'squeak'); wcSay(S, 'w_miss');
    return false;
  }
  function toWalk(g, ph) { g.st = 'walk'; g.t = 0; g.cd = G_CD[ph] + rnd() * 60; }

  SC.giant = {
    outro: 'ending', chapter: 5,
    solids: [], plats: [],
    init(S) {
      S.v = { open: false, sun: S.sun0, burn: false, dt: 90, ws: 'w_h1', wsT: 150, wt: 0, cheer: 0, boo: 0, wave: 0 };
      S.ents.push({ type: 'giant', x: 380, face: -1, hp: 1000, st: 'roar', t: 0, inv: 0, cd: 160, bites: 0, walk: 0, mv: false, fx: 0, tx: 0 });
    },
    goal(S) { const g = S.ents.find(e => e.type === 'giant'); return { k: g && g.st === 'down' ? 'g_giant2' : 'g_giant' }; },
    update(S) {
      const v = S.v, g = S.ents.find(e => e.type === 'giant');
      v.sun += 1 / SUN_FRAMES;
      if (v.sun >= 1 && !v.burn) {
        v.burn = true; ev(S, 'burn');
        for (const p of humans(S)) if (!p.down) { p.hp = 0; p.down = 1; }
      }
      if (v.wsT > 0) v.wsT--;
      if (v.wt > 0) v.wt--;
      crowd(v);
      if (!g) return;
      if (g.st === 'walk') chat(S, 'z_giant', null, true);
      const ph = g.hp > 700 ? 1 : g.hp > 350 ? 2 : 3;
      const tg = nearest(S, g.x);
      g.t++; if (g.inv > 0) g.inv--;
      g.mv = false;
      const ducks = S.ents.filter(e => e.type === 'duck' && e.st !== 'fly');
      const under = ducks.find(d => d.st === 'ground' && Math.abs(d.x - g.x) < 20 && (d.k || Math.abs(d.vx) < 1));

      if (g.st === 'walk') {
        const d = tg ? tg.x - g.x : 0;
        if (Math.abs(d) > 2) g.face = d > 0 ? 1 : -1;
        if (tg && Math.abs(d) > 6) { g.x += g.face * G_SPEED[ph]; g.walk += G_SPEED[ph]; g.mv = true; }
        g.cd -= tg && Math.abs(d) < 70 ? 3 : 1;      // close by, he loses patience faster
        if (under && duckUnder(S, g, under)) { /* he slips */ }
        else if (g.cd <= 0 && tg) {
          const ad = Math.abs(d);
          if (ad < 18 || ad > 110 || rnd() < 0.4) { g.st = 'stomp'; g.t = 0; }
          else { g.st = 'fist'; g.t = 0; g.tx = clamp(tg.x, 12, W - 12); g.face = d >= 0 ? 1 : -1; }
          if (rnd() < 0.5) wcSay(S, 'w_h4');
        }
      } else if (g.st === 'stomp') {
        if (g.t === STOMP_UP) {
          if (under && duckUnder(S, g, under)) { /* the foot comes down on a kicked duck */ }
          else {
            S.shake = 12; ev(S, 'thud'); ev(S, 'rumble');
            S.ents.push({ type: 'shock', x: g.x - 20, vx: -2.4 }, { type: 'shock', x: g.x + 20, vx: 2.4 });
            // stones tumble out of the stands, one near each zombie
            const pl = alive(S), n = ph === 1 ? 2 : 3, xs = [];
            for (let i = 0; i < n; i++) {
              let x = 0;
              for (let k = 0; k < 6; k++) {
                x = clamp(i < pl.length ? pl[i].x + (rnd() - 0.5) * 50 : 30 + rnd() * 420, 12, W - 12);
                if (xs.every(o => Math.abs(o - x) > 28)) break;
              }
              xs.push(x);
              S.ents.push({ type: 'stone', x, y: 108, vy: -2.5 });        // from the top row of the stands
            }
            for (const p of humans(S)) if (!p.down && p.y > G - 20 && Math.abs(p.x - (g.x + g.face * 6)) < 18) hurt(S, p, p.x < g.x ? -1 : 1);
          }
        }
        if (g.st === 'stomp' && g.t >= STOMP_UP + 28) toWalk(g, ph);
      } else if (g.st === 'fist') {
        // he lines his fist up with the shadow, then slams it down
        if (g.t < FIST_UP - 8) {
          const want = clamp(g.tx - g.face * REACH, 24, W - 24);
          g.x += clamp(want - g.x, -2, 2);
        }
        g.fx = g.x + g.face * REACH;
        if (under && duckUnder(S, g, under)) { /* he slips */ }
        else {
          if (g.t === FIST_UP) {
            S.shake = 10; ev(S, 'thud');
            for (const p of humans(S)) if (!p.down && p.y > G - 30 && Math.abs(p.x - g.fx) < 15) hurt(S, p, p.x < g.fx ? -1 : 1);
          }
          if (g.t >= FIST_UP + 30) toWalk(g, ph);
        }
      } else if (g.st === 'slip') {
        const r = lieRange(g);
        g.x += g.face * 0.8;
        g.x += clamp(clamp(g.x, r[0], r[1]) - g.x, -1.5, 1.5);
        if (g.t >= 36) { g.st = 'down'; g.t = 0; g.bites = 0; S.shake = 14; ev(S, 'thud'); }
      } else if (g.st === 'down') {
        if (g.t >= STUN || (g.bites >= MAX_BITES && g.inv <= 15)) { g.st = 'getup'; g.t = 0; wcSay(S, 'w_up'); }
      } else if (g.st === 'getup') {
        if (g.t >= 45) { g.st = 'roar'; g.t = 0; }
      } else if (g.st === 'roar') {
        if (g.t === 1) { ev(S, 'roar'); S.shake = 20; }
        if (g.t >= 6 && g.t <= 40) {
          // the roar blows everybody (and every duck near his feet) away, without hurting
          for (const p of S.players) if (!p.down && Math.abs(p.x - g.x) < 230) p.kb = (p.x < g.x ? -1 : 1) * 3;
          for (const d of ducks) if (d.st === 'ground' && Math.abs(d.x - g.x) < 40) d.vx = (d.x < g.x ? -1 : 1) * 3;
        }
        if (g.t >= 70) toWalk(g, ph);
      }
      if (g.st !== 'slip' && g.st !== 'down') g.x = clamp(g.x, 24, W - 24);

      // his walking legs hurt (not right after an attack, so you can get out from under him)
      if (g.st === 'walk' && g.mv && g.t > 30) {
        for (const p of humans(S)) if (!p.down && hit(pbox(p), { x: g.x - 15, y: G - 48, w: 30, h: 48 })) {
          const dir = p.x < g.x ? -1 : 1;
          if (hurt(S, p, dir)) p.kb = dir * 4.5;
        }
      }

      // bites: a duck gets kicked, his head only counts while he lies down, the rest is too tough
      const down = g.st === 'down';
      const body = down ? { x: g.x + (g.face > 0 ? -36 : -48), y: G - 36, w: 84, h: 36 } : { x: g.x - 20, y: G - 112, w: 40, h: 112 };
      for (const p of humans(S)) {
        let kicked = false;
        for (const d of ducks) {
          if (d.st === 'ground' && bites(p, { x: d.x - 5, y: G - 10, w: 10, h: 10 })) { d.vx = p.face * 4.6; d.k = 1; ev(S, 'quack'); kicked = true; break; }
        }
        if (kicked) continue;
        if (down && bites(p, headBox(g))) {
          if (g.inv <= 0 && g.bites < MAX_BITES) {
            g.hp -= 60 * power(p); g.inv = 35; g.bites++; S.shake = 6; ev(S, 'bosshit'); v.cheer = 50;
            if (g.hp <= 0) { g.hp = 0; remove(S, e => e.type !== 'giant'); complete(S); return; }
          }
        } else if (bites(p, body)) ev(S, 'clang');
      }

      // the Laughing Toilet throws a new duck when there is none on the sand. While the giant is down and
      // somebody is hurt it sometimes throws brains instead (never when a duck is needed to stop him).
      if (!ducks.length && --v.dt <= 0) {
        v.dt = DUCK_EVERY[ph];
        let tx = 0;
        for (let k = 0; k < 8; k++) { tx = 40 + rnd() * 400; if (Math.abs(tx - g.x) > 80) break; }
        const T = 56, x0 = WC_X - 8, y0 = WC_Y - 30, vx = (tx - x0) / T, vy = (G - y0 - 0.1 * T * T) / T;
        const standing = g.st === 'walk' || g.st === 'stomp' || g.st === 'fist' || g.st === 'roar';
        const hurtOne = humans(S).some(p => !p.down && p.hp < 3);
        if (!standing && hurtOne && !S.ents.some(e => e.type === 'pow') && rnd() < 0.5) {
          pow(S, 'brain', x0, y0, { vx, vy, air: true });
          v.dt = 60; wcSay(S, 'w_brain');
        } else { S.ents.push({ type: 'duck', x: x0, y: y0, vx, vy, st: 'air', t: 0, k: 0 }); wcSay(S, 'w_duck'); }
        ev(S, 'throw'); v.wt = 24;
      } else if (v.wsT <= 0 && rnd() < 0.004) wcSay(S, HECKLE[(rnd() * HECKLE.length) | 0]);

      for (const e of S.ents) {
        let box = null;
        if (e.type === 'duck') {
          e.t++;
          if (e.st === 'air') {
            e.x += e.vx; e.y += e.vy; e.vy += 0.2;
            if (e.y >= G) { e.y = G; e.st = 'ground'; e.vx *= 0.3; ev(S, 'pop'); }
          } else if (e.st === 'ground') {
            e.x += e.vx; e.vx *= 0.975;
            if (Math.abs(e.vx) < 0.05) e.vx = 0;
            if ((e.x < 8 && e.vx < 0) || (e.x > W - 8 && e.vx > 0)) e.vx = -e.vx * 0.6;
            e.x = clamp(e.x, 6, W - 6);
          } else {
            e.x += e.vx; e.y += e.vy; e.vy += 0.25;
            if (e.t > 60) e.dead = 1;
          }
        } else if (e.type === 'stone') {
          e.y += e.vy; e.vy += 0.16;
          if (e.y >= G - 4) { e.dead = 1; ev(S, 'thud'); }
          box = { x: e.x - 5, y: e.y - 5, w: 10, h: 10 };
        } else if (e.type === 'shock') {
          e.x += e.vx;
          if (e.x < -20 || e.x > W + 20) e.dead = 1;
          box = { x: e.x - 6, y: G - 10, w: 12, h: 10 };
        }
        if (!box) continue;
        for (const p of humans(S)) if (!p.down && hit(pbox(p), box)) {
          if (hurt(S, p, e.vx < 0 ? -1 : e.vx > 0 ? 1 : (p.x < e.x ? -1 : 1)) && e.type === 'stone') e.dead = 1;
        }
      }
      remove(S, e => e.dead);

      // hints for what to do right now
      if (down) S.hint = 'h_head';
      else if (g.st === 'stomp' && g.t < STOMP_UP + 20) S.hint = 'h_stomp';
      else if (g.st === 'fist' && g.t < FIST_UP + 5) S.hint = 'h_fist';
      else S.hint = ducks.some(d => d.st === 'ground') ? 'h_kick' : 'h_wait';
    }
  };

  // ------------------------------------------------------------------ flow
  function newGame(opts) {
    opts = opts || {};
    const S = { tick: 0, mode: 'play', scene: null, ents: [], v: {}, cut: null, evs: [], evN: 0, msg: null, msgT: 0,
      hint: null, shake: 0, overT: 0, overWhy: '', endT: 0, downT: 0, paused: false, two: opts.players === 2, sun0: SUN_CAP,
      talk: null, talkCd: 0, said: {},
      players: [mkPlayer(0), mkPlayer(1)], pp: [{ j: false, a: false }, { j: false, a: false }] };
    S.players[1].ai = !S.two;
    startScene(S, opts.scene || 'field', true);
    return S;
  }

  function startScene(S, id, first) {
    // the sunrise carries over from the arena into the giant fight, capped so the fight stays winnable
    if (id === 'giant' && S.scene === 'arena') S.sun0 = Math.min(SUN_CAP, S.v.sun || 0);
    S.scene = id; S.ents = []; S.v = {}; S.hint = null; S.msg = null; S.msgT = 0; S.talk = null;
    S.mode = 'play'; S.overT = 0; S.downT = 0; S.cut = null;
    for (const p of S.players) {
      // power-ups carry on into the next scene (through its cutscenes), but not into a retry
      const ai = p.ai, gold = first ? p.gold : 0, chick = first ? p.chick : 0;
      Object.assign(p, mkPlayer(p.id));
      p.ai = ai; p.gold = gold; p.chick = chick;
    }
    SC[id].init(S);
    ev(S, 'scene');
    if (first && SC[id].intro) startCut(S, SC[id].intro, 'play');
  }

  function startCut(S, id, after) { S.cut = { id, i: 0, t: 0, after }; S.mode = 'cut'; S.hint = null; }

  function complete(S) {
    if (S.mode !== 'play') return;
    const sc = SC[S.scene];
    ev(S, 'win');
    if (sc.outro) startCut(S, sc.outro, sc.next ? 'next' : 'end');
    else startScene(S, sc.next, true);
  }

  function pressed(S, inputs) {
    let any = false;
    S.players.forEach((p, i) => {
      const inp = (!p.ai && inputs[i]) || ZERO, pp = S.pp[i];
      if ((inp.jump && !pp.j) || (inp.act && !pp.a)) any = true;
      pp.j = !!inp.jump; pp.a = !!inp.act;
    });
    return any;
  }

  function stepCut(S, inputs) {
    const c = S.cut, steps = DDN.CUTS[c.id], st = steps[c.i];
    c.t++;
    if (c.t === 1) {
      if (st.fx) ev(S, st.fx);
      if (st.shake) S.shake = 24;
      if (st.card) ev(S, 'card');
    }
    const press = pressed(S, inputs);
    let adv = false;
    if (st.card) adv = (press && c.t > 30) || c.t > 210;
    else if (press && c.t > 8) {
      if (c.t < st.len * 1.2 + 6) c.t = 100000; else adv = true;
    }
    if (!adv) return;
    c.i++; c.t = 0;
    if (c.i < steps.length) return;
    S.cut = null;
    for (const p of S.players) { p.pj = true; p.pa = true; }
    if (c.after === 'play') S.mode = 'play';
    else if (c.after === 'next') startScene(S, SC[S.scene].next, true);
    else { S.mode = 'end'; S.endT = 0; ev(S, 'end'); }
  }

  // The second zombie follows the first one when playing alone.
  function aiInput(S, p) {
    const l = S.players[0];
    if (l.down) return ZERO;
    const d = l.x - l.face * 20 - p.x;
    const mx = Math.abs(d) > 5 ? (d > 0 ? 1 : -1) : 0;
    let j = false;
    if (p.g) {
      if (l.g && l.y < p.y - 10 && Math.abs(l.x - p.x) < 70) j = true;
      if (mx && p.blk) j = true;
      if (l.jumped && Math.abs(d) < 40) j = true;
    }
    return { mx, jump: j && !p.pj, act: false };
  }

  function stepPlayer(S, p, inp, sc) {
    p.jumped = false;
    if (p.inv > 0) p.inv--;
    // power-up timers only run here, so they stand still during cutscenes, pauses and game over
    if (p.gold > 0) p.gold--;
    if (p.chick > 0) p.chick--;
    if (p.down > 0) { p.idle = 0; p.vx = 0; p.vy += 0.32; p.y = Math.min(G, p.y + p.vy); return; }
    const jp = inp.jump && !p.pj, ap = inp.act && !p.pa;
    p.pj = !!inp.jump; p.pa = !!inp.act;
    let mx = Math.max(-1, Math.min(1, inp.mx || 0));
    // standing still somewhere safe for 6 s: the head-drops-off gag (drawn only; any input ends it)
    p.idle = !p.ai && !mx && !inp.jump && !inp.act && p.g && calm(S, p) ? (p.idle + 1) % IDLE_END : 0;
    if (p.idle === IDLE_END - 1) chat(S, 'z_head', p.id);
    if (p.stun > 0) { p.stun--; mx = 0; }
    p.vx = mx * (p.gold > 0 ? 2.1 : 1.5) + p.kb;          // gold paint: 40% faster
    p.kb *= 0.85; if (Math.abs(p.kb) < 0.1) p.kb = 0;
    if (mx) p.face = mx > 0 ? 1 : -1;
    if (sc.running && !mx) p.face = 1;
    if (jp && p.g) { p.vy = -5.4; p.g = false; p.jumped = true; ev(S, 'jump'); }
    if (ap && !p.ai) {
      if (!(sc.interact && sc.interact(S, p)) && p.bite <= 0) { p.bite = 20; p.bh = false; ev(S, 'bite'); }
    }
    if (S.mode !== 'play') return;
    if (p.bite > 0) p.bite--;

    // sideways, blocked by solid things
    let nx = p.x + p.vx;
    p.blk = false;
    for (const s of sc.solids) {
      if (p.y > s.y + 1 && p.y - 26 < s.y + s.h && nx + 5 > s.x && nx - 5 < s.x + s.w) {
        nx = p.x < s.x + s.w / 2 ? s.x - 5 : s.x + s.w + 5;
        p.blk = true;
      }
    }
    const lo = sc.minX ? sc.minX(S) : 10;
    const hi = sc.maxX ? sc.maxX(S) : (S.v.open ? W + 10 : W - 6);
    p.x = Math.max(lo, Math.min(hi, nx));

    // up and down, landing on the ground, on solid things and on branches
    const oy = p.y;
    p.vy = Math.min(6, p.vy + 0.32);
    p.y += p.vy; p.g = false;
    if (p.y >= G) { p.y = G; p.vy = 0; p.g = true; }
    if (p.vy >= 0) {
      for (const s of sc.solids.concat(sc.plats)) {
        if (oy <= s.y + 0.01 && p.y >= s.y && p.x + 5 > s.x && p.x - 5 < s.x + s.w) { p.y = s.y; p.vy = 0; p.g = true; }
      }
    }
  }

  // Power-ups: falling or floating along, and picked up by touching (never by the follower when playing alone).
  function stepPows(S) {
    for (const e of S.ents) {
      if (e.type !== 'pow') continue;
      e.t++;
      e.x += e.vx;
      if (e.air) {
        e.y += e.vy; e.vy += 0.2;
        if (e.y >= G) { e.y = G; e.air = false; e.vx = 0; e.vy = 0; }
      }
      if (e.x < -20 || e.x > W + 30) { e.dead = 1; continue; }
      for (const p of humans(S)) {
        if (p.down || !hit(pbox(p), { x: e.x - 6, y: e.y - 12, w: 12, h: 12 })) continue;
        if (e.kind === 'brain') {
          if (p.hp >= 3) continue;                       // at full health the brains stay where they are
          p.hp++; ev(S, 'pick'); chat(S, 'z_brain', p.id);
        } else if (e.kind === 'gold') { p.gold = GOLD_T; ev(S, 'power'); chat(S, 'z_gold', p.id); }
        else { p.chick = CHICK_T; ev(S, 'power'); chat(S, 'z_chick', p.id); }
        e.dead = 1;
        break;
      }
    }
    remove(S, e => e.type === 'pow' && e.dead);
  }

  function step(S, inputs) {
    if (S.paused) return;
    S.tick++;
    if (S.shake > 0) S.shake--;
    if (S.msgT > 0) S.msgT--;
    if (S.mode === 'cut') { stepCut(S, inputs); return; }
    if (S.mode === 'end') { S.endT++; return; }
    if (S.mode === 'over') {
      S.overT++;
      if (pressed(S, inputs) && S.overT > 45) startScene(S, S.scene, false);
      return;
    }
    const sc = SC[S.scene];
    for (const p of S.players) {
      stepPlayer(S, p, p.ai ? aiInput(S, p) : (inputs[p.id] || ZERO), sc);
      if (S.mode !== 'play') return;
    }
    sc.update(S);
    if (S.mode !== 'play' || S.scene !== sc.id) return;
    stepPows(S);
    // a bubble gives way to a message or an urgent hint
    if (S.talk && (--S.talk.t <= 0 || S.msgT > 0 || URGENT.includes(S.hint))) S.talk = null;
    if (S.talkCd > 0) S.talkCd--;

    // fallen zombies: a partner gets you back up, otherwise the scene restarts
    const hs = humans(S), up = hs.filter(p => p.down === 0);
    for (const p of hs) {
      if (p.down > 0) { p.down++; if (up.length && p.down > 240 && !S.v.burn) { p.down = 0; p.hp = 2; p.inv = 120; ev(S, 'pick'); } }
    }
    if (!up.length) {
      if (++S.downT > 50) { S.mode = 'over'; S.overT = 0; S.overWhy = S.v.burn ? 'sun' : ''; ev(S, 'over'); }
      return;
    }
    if (S.v.open && up.some(p => p.x >= W - 7)) complete(S);
  }

  // Shift+X and Shift+B from the 2016 game: jump a scene forward or back.
  function skip(S, dir) {
    const i = ORDER.indexOf(S.scene) + dir;
    if (i < 0) return;
    if (i >= ORDER.length) { startCut(S, 'ending', 'end'); return; }
    startScene(S, ORDER[i], true);
  }

  for (const id in SC) SC[id].id = id;
  DDN.sim = { W, H, G, ORDER, CHAPTERS, DOOR, CHASE_LEN, SUN_FRAMES, SUN_CAP, WC_X, WC_Y, REACH, STUN, MAX_BITES, STOMP_UP, FIST_UP, GOLD_T, CHICK_T, TALK_T, TALK_GAP, IDLE_GAG, IDLE_END, ROLL_X, SC, newGame, startScene, step, skip, humans, biteBox };
  if (typeof module !== 'undefined') module.exports = DDN;
})(typeof window !== 'undefined' ? window : globalThis);
