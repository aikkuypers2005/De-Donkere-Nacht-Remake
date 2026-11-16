// Automated playthrough of the game rules, ported from test/smoke.js.
// Run with: Processing.exe cli --sketch=... --output=... --force --run test

import java.util.Locale;
import java.util.HashSet;

int testFailed = 0;

void check(String name, boolean ok, String extra) {
  println((ok ? "PASS  " : "FAIL  ") + name + (extra != null && !extra.isEmpty() ? "  (" + extra + ")" : ""));
  if (!ok) testFailed++;
}

void check(String name, boolean ok) {
  check(name, ok, null);
}

int isign(double x) {
  return x > 0 ? 1 : x < 0 ? -1 : 0;
}

interface BotFn {
  InputState run(GameState S, Player p, boolean tog);
}

interface EachFn {
  void run(GameState S);
}

class Cmd {
  String kind;
  double val;
  BotFn fn;

  Cmd(String kind, double val) {
    this.kind = kind;
    this.val = val;
  }

  Cmd(String kind) {
    this.kind = kind;
    this.val = 0;
  }

  Cmd(BotFn fn) {
    this.kind = "fn";
    this.fn = fn;
  }
}

class PlayOpts {
  int max = 20000;
  boolean god = false;
  EachFn each = null;

  PlayOpts() {}
  PlayOpts(boolean god) { this.god = god; }
  PlayOpts(int max) { this.max = max; }
  PlayOpts(boolean god, int max, EachFn each) {
    this.god = god;
    this.max = max;
    this.each = each;
  }
}

int play(GameState S, Cmd[] script, PlayOpts opts) {
  if (opts == null) opts = new PlayOpts();
  String scene = S.scene;
  int max = opts.max;
  int i = 0, f = 0, sub = 0;
  boolean tog = false;
  while (f++ < max) {
    Player p = S.players[0];
    if (opts.god) {
      p.hp = 3;
      p.down = 0;
      p.inv = 2;
    }
    InputState inp = new InputState(0, false, false);
    tog = !tog;
    if ("cut".equals(S.mode) || "over".equals(S.mode)) {
      inp.act = tog;
    } else if ("play".equals(S.mode)) {
      Cmd c = script[Math.min(i, script.length - 1)];
      if ("fn".equals(c.kind)) {
        InputState r = c.fn.run(S, p, tog);
        if (r != null) inp = r;
      } else if ("walk".equals(c.kind)) {
        if (Math.abs(p.x - c.val) < 1.6) i++;
        else inp.mx = p.x < c.val ? 1 : -1;
      } else if ("jump".equals(c.kind)) {
        inp.mx = (int) c.val;
        if (sub == 0) {
          inp.jump = true;
          sub = 1;
        } else if (p.g && sub > 2) {
          sub = 0;
          i++;
        } else {
          sub++;
        }
      } else if ("act".equals(c.kind)) {
        if (sub == 0) {
          inp.act = true;
          sub = 1;
        } else {
          sub = 0;
          i++;
        }
      } else if ("wait".equals(c.kind)) {
        if (++sub >= (int) c.val) {
          sub = 0;
          i++;
        }
      }
    }
    step(S, new InputState[] { inp, new InputState(0, false, false) });
    if (opts.each != null) opts.each.run(S);
    if (!scene.equals(S.scene) || "end".equals(S.mode)) return f;
  }
  return -1;
}

InputState giantBot(GameState S, Player p, boolean tog, boolean careful) {
  Ent g = findEnt(S, "giant");
  if (g == null) return new InputState(0, false, false);
  boolean shockNear = false;
  for (Ent e : S.ents) {
    if ("shock".equals(e.type) && Math.abs(e.x - p.x) < 26 && isign(p.x - e.x) == isign(e.vx)) {
      shockNear = true;
      break;
    }
  }
  boolean jump = p.g && (shockNear ||
    (careful && "stomp".equals(g.st) && g.t >= STOMP_UP - 3 && g.t < STOMP_UP && Math.abs(p.x - g.x) < 50));
  if ("down".equals(g.st)) {
    double hx = g.x - g.face * 48;
    int dir = isign(hx - p.x);
    if (dir == 0) dir = 1;
    if (Math.abs(hx - p.x) > 12 || p.face != dir) return new InputState(dir, jump, false);
    return new InputState(0, jump, tog);
  }
  if (careful) {
    ArrayList<double[]> danger = new ArrayList<double[]>();
    if ("fist".equals(g.st) && g.t < FIST_UP + 2) danger.add(new double[] { g.fx, 24 });
    if ("stomp".equals(g.st) && g.t < STOMP_UP + 2) danger.add(new double[] { g.x, 30 });
    if ("walk".equals(g.st)) danger.add(new double[] { g.x, 30 });
    for (Ent s : S.ents) if ("stone".equals(s.type)) danger.add(new double[] { s.x, 15 });
    double[] d = null;
    for (double[] cand : danger) {
      if (Math.abs(p.x - cand[0]) < cand[1]) {
        d = cand;
        break;
      }
    }
    if (d != null) {
      int dir = p.x < d[0] ? -1 : 1;
      if ((dir < 0 && p.x < 24) || (dir > 0 && p.x > SIM_W - 24)) dir = -dir;
      return new InputState(dir, jump, false);
    }
  }
  Ent duck = null;
  for (Ent e : S.ents) {
    if ("duck".equals(e.type) && "ground".equals(e.st) && Math.abs(e.vx) < 0.4) {
      duck = e;
      break;
    }
  }
  if (duck != null && !"getup".equals(g.st) && !"roar".equals(g.st) && !"slip".equals(g.st)) {
    int dir = isign(g.x - duck.x);
    if (dir == 0) dir = 1;
    if (duck.x < 14) dir = -1;
    else if (duck.x > SIM_W - 14) dir = 1;
    double off = (duck.x - p.x) * dir;
    if (p.face == dir && off >= -4 && off <= 20) return new InputState(0, jump, tog);
    if (off >= 3 && off <= 20) return new InputState(dir, jump, false);
    double px = Math.max(10, Math.min(SIM_W - 6, duck.x - dir * 11));
    int m = isign(px - p.x);
    if (m == 0) m = dir;
    return new InputState(m, jump, false);
  }
  if (Math.abs(p.x - g.x) < 90) {
    int dir = p.x < g.x ? -1 : 1;
    if ((dir < 0 && p.x < 20) || (dir > 0 && p.x > SIM_W - 20)) dir = -dir;
    return new InputState(dir, jump, false);
  }
  return new InputState(0, jump, false);
}

ArrayList<String> newEvents(GameState S, int[] seen) {
  ArrayList<String> out = new ArrayList<String>();
  for (Ev e : S.evs) {
    if (e.n > seen[0]) {
      out.add(e.s);
      seen[0] = e.n;
    }
  }
  return out;
}

class TalkWatch {
  int n = 0;
  int minGap = Integer.MAX_VALUE;
  String bad = "";
  int last = -1;
  int f = 0;
  Talk prev = null;

  void each(GameState S) {
    f++;
    Talk t = S.talk;
    if (t != null) {
      if ((t.who != 0 && t.who != 1) || tr("nl", t.k) == null || tr("en", t.k) == null) {
        bad = "invalid talk: " + t.who + ":" + t.k;
      }
      if (S.msgT > 0 || isUrgent(S.hint)) {
        bad = "bubble over a message or urgent hint: " + t.k;
      }
      if (prev == null) {
        if (last >= 0) minGap = Math.min(minGap, f - last);
        last = f;
        n++;
      }
    }
    prev = t;
  }

  boolean ok() {
    return bad.isEmpty() && minGap >= TALK_GAP;
  }

  String info() {
    return n + " bubbles, shortest gap " + (n > 1 ? String.valueOf(minGap) : "-") + " frames" + (!bad.isEmpty() ? ", bad: " + bad : "");
  }
}

GameState quiet(String scene, int players) {
  GameState S = newGame(players, scene);
  S.cut = null;
  S.mode = "play";
  return S;
}

boolean hasPow(GameState S, String kind) {
  for (Ent e : S.ents) if ("pow".equals(e.type) && kind.equals(e.kind)) return true;
  return false;
}

void runSteps(GameState S, int n, InputState inp) {
  InputState i0 = inp != null ? inp : ZERO_INP;
  for (int i = 0; i < n; i++) step(S, new InputState[] { i0, ZERO_INP });
}

InputState randInp() {
  int[] mxs = { -1, 0, 1 };
  return new InputState(mxs[(int) (rnd() * 3)], rnd() < 0.2, rnd() < 0.3);
}

void runSmokeTests() {
  initScenes();
  HashMap<String, Cmd[]> scripts = new HashMap<String, Cmd[]>();

  scripts.put("field", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        return new InputState(1, p.blk && p.g && tog, p.x > 385 && tog);
      }
    })
  });

  scripts.put("forest", new Cmd[] {
    new Cmd("walk", 205), new Cmd("walk", 75), new Cmd("jump", 0),
    new Cmd("walk", 100), new Cmd("jump", 1), new Cmd("walk", 150),
    new Cmd("walk", 395), new Cmd("jump", 0),
    new Cmd("walk", 250), new Cmd("jump", 0), new Cmd("walk", 268), new Cmd("jump", 1), new Cmd("walk", 314),
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        return new InputState(1, false, false);
      }
    })
  });

  scripts.put("house", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        Ent crow = null, key = null;
        for (Ent e : S.ents) {
          if ("crow".equals(e.type) && e.stN != 3 && crow == null) crow = e;
          if ("key".equals(e.type) && key == null) key = e;
        }
        if (crow != null) return new InputState(Math.abs(crow.x - p.x) > 6 ? isign(crow.x - p.x) : 0, tog, tog);
        if (key != null) return new InputState(isign(key.x - p.x), false, false);
        if (Math.abs(p.x - DOOR) > 4) return new InputState(isign(DOOR - p.x), p.blk && tog, false);
        return new InputState(0, false, tog);
      }
    })
  });

  scripts.put("hall", new Cmd[] {
    new Cmd("walk", 60), new Cmd("act"), new Cmd("walk", 143), new Cmd("jump", 1), new Cmd("walk", 168), new Cmd("act"), new Cmd("wait", 3),
    new Cmd("walk", 312), new Cmd("act"), new Cmd("wait", 3), new Cmd("act"),
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        if (p.y > 173) return new InputState(1, p.g && tog, false);
        if (Math.abs(p.x - 396) > 2) return new InputState(isign(396 - p.x), false, false);
        return new InputState(0, false, tog);
      }
    })
  });

  scripts.put("bath", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        boolean wave = false;
        for (Ent e : S.ents) if ("wave".equals(e.type) && Math.abs(e.x - p.x) < 30) { wave = true; break; }
        return new InputState(p.x < 362 ? 1 : 0, wave, tog);
      }
    })
  });

  scripts.put("bed", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        SceneVars v = S.v;
        if (!"snore".equals(v.ph) || v.pt < 40) return new InputState(0, false, false);
        boolean duck = false;
        for (BedDuck d : v.d) if (d.x - p.x > 4 && d.x - p.x < 16) { duck = true; break; }
        return new InputState(1, duck && p.g, false);
      }
    })
  });

  scripts.put("chase", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        boolean haz = false;
        for (Ent o : S.ents) {
          if (!"cbat".equals(o.type) && o.x - p.x > 0 && o.x - p.x < 26 && (!o.hasY || o.y > SIM_G - 30)) {
            haz = true;
            break;
          }
        }
        return new InputState(0, haz, false);
      }
    })
  });

  scripts.put("arena", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        Ent th = findEnt(S, "thief");
        boolean haz = false;
        for (Ent e : S.ents) {
          if (("fball".equals(e.type) || "shock".equals(e.type)) && Math.abs(e.x - p.x) < 26) {
            haz = true;
            break;
          }
        }
        return new InputState(th != null && Math.abs(th.x - p.x) > 10 ? isign(th.x - p.x) : 0, haz, tog);
      }
    })
  });

  scripts.put("giant", new Cmd[] {
    new Cmd(new BotFn() {
      public InputState run(GameState S, Player p, boolean tog) {
        return giantBot(S, p, tog, false);
      }
    })
  });

  // 1. Every scene can be finished, with the right scene following it.
  for (String id : ORDER) {
    GameState S = newGame(1, id);
    int f = play(S, scripts.get(id), new PlayOpts(true));
    String want = SC.get(id).next != null ? SC.get(id).next : "end";
    String got = "end".equals(S.mode) ? "end" : S.scene;
    check("finish " + id, f > 0 && got.equals(want), f + " frames, then " + got);
  }

  // 2. Scenes that should be beatable without taking damage cheats.
  for (String id : new String[] { "field", "bed" }) {
    GameState S = newGame(1, id);
    int f = play(S, scripts.get(id), new PlayOpts(30000));
    check("finish " + id + " without cheats", f > 0, f + " frames");
  }

  // 3. The arena can be won before sunrise.
  {
    GameState S = newGame(1, "arena");
    int f = play(S, scripts.get("arena"), new PlayOpts(true));
    check("arena won before sunrise", f > 0 && f < 10800, f + " frames of 10800");
  }

  // 4. Doing nothing in the arena ends in sunrise and a retry.
  {
    GameState S = newGame(1, "arena");
    boolean sawOver = false, tog = false;
    for (int f = 0; f < 12500 && !sawOver; f++) {
      tog = !tog;
      step(S, new InputState[] { new InputState(0, false, "cut".equals(S.mode) && tog) });
      S.players[0].hp = S.v.burn ? S.players[0].hp : 3;
      if ("over".equals(S.mode)) sawOver = "sun".equals(S.overWhy);
    }
    check("sunrise ends the arena", sawOver);
    for (int f = 0; f < 60; f++) step(S, new InputState[] { new InputState(0, false, f % 2 == 0) });
    check("retry after game over", "play".equals(S.mode) && "arena".equals(S.scene) && S.players[0].hp == 3);
  }

  // 5. Random two-player input in every scene, with JSON round-trip.
  for (String id : ORDER) {
    GameState S = newGame(2, id);
    Exception err = null;
    int frames = 0;
    TalkWatch talk = new TalkWatch();
    String[] kinds = { "brain", "gold", "chick" };
    try {
      for (; frames < 15000; frames++) {
        if (frames % 600 == 300 && "play".equals(S.mode)) {
          Player p = S.players[(int) (rnd() * 2)];
          String kind = kinds[(int) (rnd() * 3)];
          pow(S, kind, p.x + 20, SIM_G);
          if (frames % 1200 == 300) S.players[0].chick = CHICK_T;
          else S.players[1].gold = GOLD_T;
        }
        step(S, new InputState[] { randInp(), randInp() });
        talk.each(S);
        if (frames % 50 == 0) {
          JSONObject j = stateToJson(S);
          String json = j.toString();
          String cleaned = json.replaceAll("\"(msg|hint|cut|scene|talk|ws)\":\\s*null", "");
          if (cleaned.contains("null") || cleaned.contains("NaN") || cleaned.contains("Infinity")) {
            throw new RuntimeException("bad number in state: " + json.substring(0, Math.min(300, json.length())));
          }
          S = stateFromJson(parseJSONObject(json));
        }
        if ("end".equals(S.mode)) break;
      }
    } catch (Exception e) {
      err = e;
    }
    check("random co-op input from " + id, err == null && talk.ok(),
      err != null ? err.toString() : frames + " frames, reached " + S.scene + ", " + talk.info());
  }

  // 6. The full game from the first cutscene to the end screen, through the turn and the giant.
  {
    GameState S = newGame(1, "field");
    int total = 0;
    boolean ok = true;
    final ArrayList<String> cuts = new ArrayList<String>();
    final HashSet<String> scenes = new HashSet<String>();
    scenes.add(S.scene);
    final TalkWatch talk = new TalkWatch();
    EachFn each = new EachFn() {
      public void run(GameState s) {
        if (s.cut != null && !cuts.contains(s.cut.id)) cuts.add(s.cut.id);
        scenes.add(s.scene);
        talk.each(s);
      }
    };
    while (!"end".equals(S.mode) && ok) {
      int f = play(S, scripts.get(S.scene), new PlayOpts(true, 20000, each));
      if (f < 0) ok = false;
      else total += f;
    }
    boolean route = cuts.contains("intro") && cuts.contains("bedout") && cuts.contains("turn") && cuts.contains("ending");
    for (String id : ORDER) if (!scenes.contains(id)) route = false;
    check("full game start to end", ok && "end".equals(S.mode) && route,
      Math.round(total / 60.0) + " seconds of play for a perfect bot, cutscenes: " + String.join(" ", cuts));
    check("banter during the full game: one bubble at a time, 8 s apart", talk.ok() && talk.n >= 5, talk.info());
  }

  // 7. The giant can be beaten by kicking ducks under his feet and biting his head, before sunrise.
  {
    GameState S = newGame(1, "giant");
    final int[] seen = { S.evN };
    final int[] counts = { 0, 0, 0, 0, 1000 }; // slips, kickSlips, kicks, headBites, lastHp
    final boolean[] hpWhileUp = { false };
    final String[] lastSt = { "" };
    final double[] sunAtWin = { 0 };
    int f = play(S, scripts.get("giant"), new PlayOpts(true, 20000, new EachFn() {
      public void run(GameState s) {
        Ent g = findEnt(s, "giant");
        for (String n : newEvents(s, seen)) if ("quack".equals(n)) counts[2]++;
        if (g == null) return;
        if ("slip".equals(g.st) && !"slip".equals(lastSt[0])) {
          counts[0]++;
          for (Ent e : s.ents) if ("duck".equals(e.type) && "fly".equals(e.st) && e.k != 0) { counts[1]++; break; }
        }
        if (g.hp < counts[4]) {
          counts[3]++;
          if (!"down".equals(g.st) && "play".equals(s.mode)) hpWhileUp[0] = true;
        }
        counts[4] = g.hp;
        lastSt[0] = g.st;
        if ("play".equals(s.mode)) sunAtWin[0] = s.v.sun;
      }
    }));
    int slips = counts[0], kickSlips = counts[1], kicks = counts[2], headBites = counts[3];
    check("giant beaten with ducks and head bites",
      f > 0 && "end".equals(S.mode) && slips >= 4 && kickSlips == slips && headBites >= 17 && !hpWhileUp[0] && sunAtWin[0] < 1,
      f + " frames, " + kicks + " kicks, " + slips + " slips (" + kickSlips + " on a kicked duck), " + headBites + " head bites, sun " + String.format(Locale.US, "%.2f", sunAtWin[0]) + " at the win");
  }

  // 8. Biting him while he stands (in every pose) does nothing; lying down, only his head counts.
  {
    GameState S = newGame(1, "giant");
    int[] seen = { S.evN };
    Ent g = findEnt(S, "giant");
    Player p = S.players[0];
    S.v.dt = 1e9;
    int clangs = 0, f = 0;
    String[] poses = { "walk", "stomp", "fist", "roar", "getup", "slip" };
    for (String st : poses) {
      for (int i = 0; i < 160; i++, f++) {
        g.st = st; g.t = 5; g.x = 240; g.face = -1; g.cd = 9999; g.inv = 0; g.bites = 0;
        p.x = 226; p.kb = 0; p.hp = 3; p.inv = 2; p.face = 1;
        step(S, new InputState[] { new InputState(0, false, i % 24 < 2) });
        for (String n : newEvents(S, seen)) if ("clang".equals(n)) clangs++;
      }
    }
    check("biting the standing giant does no damage", g.hp == 1000 && clangs >= 30, "leven " + g.hp + ", " + clangs + " clangs in " + f + " frames");
    for (int i = 0; i < 160; i++) {
      g.st = "down"; g.t = 5; g.x = 240; g.face = -1; g.cd = 9999; g.inv = 0; g.bites = 0;
      p.x = 200; p.kb = 0; p.hp = 3; p.inv = 2; p.face = -1;
      step(S, new InputState[] { new InputState(0, false, i % 24 < 2) });
    }
    int feetHp = g.hp;
    for (int i = 0; i < 160; i++) {
      g.st = "down"; g.t = 5; g.x = 240; g.face = -1; g.cd = 9999; g.inv = 0; g.bites = 0;
      p.x = 272; p.kb = 0; p.hp = 3; p.inv = 2; p.face = 1;
      step(S, new InputState[] { new InputState(0, false, i % 24 < 2) });
    }
    check("lying down, only his head can be bitten", feetHp == 1000 && g.hp < 1000, "feet: " + feetHp + ", head: " + g.hp);
  }

  // 9. The giant fight can be lost and is retried at 'giant', with the sunrise carried over from the arena and capped.
  {
    GameState S = newGame(1, "arena");
    Cmd[] noop = { new Cmd(new BotFn() { public InputState run(GameState s, Player p, boolean tog) { return ZERO_INP; } }) };
    play(S, noop, new PlayOpts(120));
    S.v.sun = 0.7d;
    findEnt(S, "thief").hp = 60;
    play(S, scripts.get("arena"), new PlayOpts(true));
    check("arena leads to the giant, sunrise capped", "giant".equals(S.scene) && S.v.sun == SUN_CAP && S.sun0 == SUN_CAP, S.scene + ", sun " + S.v.sun);

    boolean over = false;
    for (int f = 0; f < 6000 && !over; f++) {
      Ent g = findEnt(S, "giant");
      step(S, new InputState[] { new InputState(g != null ? isign(g.x - S.players[0].x) : 0, false, false) });
      over = "over".equals(S.mode);
    }
    check("the giant can win", over && "".equals(S.overWhy), "mode " + S.mode + ", why \"" + S.overWhy + "\"");
    for (int f = 0; f < 60; f++) step(S, new InputState[] { new InputState(0, false, f % 2 == 0) });
    Ent g = findEnt(S, "giant");
    check("retry starts at the giant", "play".equals(S.mode) && "giant".equals(S.scene) && g != null && g.hp == 1000 && S.players[0].hp == 3 && Math.abs(S.v.sun - SUN_CAP) < 0.01d,
      S.scene + ", leven " + (g != null ? g.hp : -1) + ", sun " + String.format(Locale.US, "%.3f", S.v.sun));

    GameState S2 = newGame(1, "arena");
    play(S2, noop, new PlayOpts(120));
    S2.v.sun = 0.1d;
    findEnt(S2, "thief").hp = 60;
    play(S2, scripts.get("arena"), new PlayOpts(true));
    double low = S2.v.sun;
    S2.v.sun = 0.999d;
    for (int f = 0; f < 400 && !"over".equals(S2.mode); f++) step(S2, new InputState[] { ZERO_INP });
    String why = S2.overWhy;
    for (int f = 0; f < 60; f++) step(S2, new InputState[] { new InputState(0, false, f % 2 == 0) });
    check("sunrise ends the giant fight, retry keeps the carried sunrise",
      low > 0.1d && low < 0.2d && "sun".equals(why) && "giant".equals(S2.scene) && Math.abs(S2.v.sun - low) < 0.01d,
      "carried " + String.format(Locale.US, "%.3f", low) + ", over: " + why + ", retry sun " + String.format(Locale.US, "%.3f", S2.v.sun));
  }

  // 10. Random two-player input in the giant fight with stuns and JSON round-trip.
  {
    GameState S = newGame(2, "giant");
    Exception err = null;
    int frames = 0, falls = 0;
    try {
      for (; frames < 15000; frames++) {
        Ent g = findEnt(S, "giant");
        if (g != null && frames % 300 == 0 && "walk".equals(g.st)) {
          Ent dk = new Ent("duck");
          dk.x = g.x; dk.y = SIM_G; dk.hasY = true; dk.st = "ground"; dk.k = 1;
          S.ents.add(dk);
          falls++;
        }
        for (Player p : S.players) {
          if (p.down > 0) continue;
          p.hp = 3;
        }
        step(S, new InputState[] { randInp(), randInp() });
        if (frames % 50 == 0) {
          JSONObject j = stateToJson(S);
          String json = j.toString();
          String cleaned = json.replaceAll("\"(msg|hint|cut|scene|talk|ws)\":\\s*null", "");
          if (cleaned.contains("null") || cleaned.contains("NaN") || cleaned.contains("Infinity")) {
            throw new RuntimeException("bad number in state: " + json.substring(0, Math.min(300, json.length())));
          }
          S = stateFromJson(parseJSONObject(json));
        }
        if ("end".equals(S.mode)) break;
      }
    } catch (Exception e) {
      err = e;
    }
    check("random co-op input in the giant fight with stuns", err == null,
      err != null ? err.toString() : frames + " frames, " + falls + " ducks dropped, mode " + S.mode);
  }

  // 10b. Without kicks the giant never slips.
  {
    GameState S = newGame(1, "giant");
    int[] seen = { S.evN };
    boolean stunned = false;
    int squeaks = 0;
    for (int f = 0; f < 9000; f++) {
      Player p = S.players[0];
      p.hp = 3; p.down = 0; p.inv = 2;
      step(S, new InputState[] { ZERO_INP });
      for (String n : newEvents(S, seen)) if ("squeak".equals(n)) squeaks++;
      Ent g = findEnt(S, "giant");
      if (g != null && ("slip".equals(g.st) || "down".equals(g.st))) stunned = true;
    }
    check("without kicks the giant never slips", !stunned && findEnt(S, "giant").hp == 1000,
      "9000 frames, " + squeaks + " ducks squirted away from his feet");
  }

  // 11. Fairness alone: a careful bot without cheats.
  {
    int wins = 0, frames = 0, N = 6;
    for (int i = 0; i < N; i++) {
      GameState S = newGame(1, "giant");
      int f = 0;
      for (; f < 20000 && "play".equals(S.mode); f++) {
        step(S, new InputState[] { giantBot(S, S.players[0], f % 2 == 0, true) });
      }
      if ("cut".equals(S.mode) || "end".equals(S.mode)) {
        wins++;
        frames += f;
      }
    }
    check("giant beatable alone without cheats", wins >= 4,
      wins + "/" + N + " wins by a careful bot" + (wins > 0 ? ", " + Math.round((double) frames / wins / 60.0) + " s on average" : ""));
  }

  // 12. Brains: a heart back, stay put at full health; the follower picks nothing up.
  {
    GameState S = quiet("field", 1);
    Player p = S.players[0];
    p.hp = 1;
    pow(S, "brain", p.x, SIM_G);
    runSteps(S, 1, null);
    boolean healed = p.hp == 2 && !hasPow(S, "brain");
    p.hp = 3;
    pow(S, "brain", p.x, SIM_G);
    runSteps(S, 30, null);
    boolean stays = p.hp == 3 && hasPow(S, "brain");
    Player ai = S.players[1];
    pow(S, "gold", ai.x, SIM_G);
    runSteps(S, 5, null);
    check("brains heal, stay put at full health; the follower picks nothing up",
      healed && stays && ai.gold == 0 && hasPow(S, "gold"),
      "hp 1 -> " + (healed ? 2 : "?") + ", full health: " + (stays ? "stays" : "taken") + ", follower gold " + ai.gold);
  }

  // 13. Gold paint: 8 s of no damage and 40% faster, then it wears off.
  {
    GameState S = quiet("field", 1);
    Player p = S.players[0];
    pow(S, "gold", p.x, SIM_G);
    runSteps(S, 1, null);
    boolean got = p.gold == GOLD_T;
    double x0 = p.x;
    runSteps(S, 20, new InputState(1, false, false));
    double fast = p.x - x0;
    runSteps(S, GOLD_T, null);
    x0 = p.x;
    runSteps(S, 20, new InputState(-1, false, false));
    double slow = x0 - p.x;
    p.gold = 100;
    pow(S, "gold", p.x, SIM_G);
    runSteps(S, 1, null);
    boolean reset = p.gold == GOLD_T;
    runSteps(S, GOLD_T, null);

    GameState C = quiet("chase", 1);
    Player q = C.players[0];
    C.v.sp = 1e9;
    q.gold = GOLD_T;
    Ent lg1 = new Ent("log"); lg1.x = q.x + 2; C.ents.add(lg1);
    runSteps(C, 12, null);
    boolean safe = q.hp == 3;
    q.gold = 0; q.inv = 0;
    Ent lg2 = new Ent("log"); lg2.x = q.x + 2; C.ents.add(lg2);
    runSteps(C, 12, null);
    check("gold paint: no damage, faster, wears off, a second pot resets the timer",
      got && reset && Math.abs(fast - 42) < 2 && Math.abs(slow - 30) < 2 && p.gold == 0 && safe && q.hp == 2,
      "20 frames: " + String.format(Locale.US, "%.1f", fast) + " px with gold, " + String.format(Locale.US, "%.1f", slow) + " px after; log with gold: hp " + (safe ? 3 : "<3") + ", without: hp " + q.hp);
  }

  // 14. The chicken: the bite reaches twice as far for 10 s.
  {
    GameState S = quiet("field", 1);
    Player p = S.players[0];
    pow(S, "chick", p.x, SIM_G);
    runSteps(S, 1, null);
    boolean got = p.chick == CHICK_T;
    int longR = 0;
    for (int i = 0; i < 14; i++) {
      step(S, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
      Box b = biteBox(p);
      if (b != null) longR = (int) b.w;
    }
    runSteps(S, 10, null);
    runSteps(S, CHICK_T, null);
    int shortR = 0;
    for (int i = 0; i < 14; i++) {
      step(S, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
      Box b = biteBox(p);
      if (b != null) shortR = (int) b.w;
    }
    runSteps(S, 10, null);
    check("the chicken doubles the reach and wears off", got && longR == 34 && shortR == 17 && p.chick == 0,
      "reach " + longR + " with the chicken, " + shortR + " after");
  }

  // 15. A chicken bite does double damage to bosses.
  {
    HashMap<String, Integer> out = new HashMap<String, Integer>();
    for (boolean chick : new boolean[] { false, true }) {
      GameState S = quiet("arena", 1);
      Player p = S.players[0];
      for (int i = 0; i < 30; i++) {
        Ent th = findEnt(S, "thief");
        th.st = "pant"; th.t = 0; th.x = p.x + 12; th.y = SIM_G; th.vx = 0; th.g = true; th.inv = th.inv > 0 ? th.inv : 0; p.face = 1;
        p.chick = chick ? 300 : 0; p.inv = 2;
        step(S, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
      }
      out.put("thief" + chick, findEnt(S, "thief").hp);

      S = quiet("giant", 1);
      p = S.players[0];
      for (int i = 0; i < 30; i++) {
        Ent g = findEnt(S, "giant");
        g.st = "down"; g.t = 5; g.x = 240; g.face = -1; p.x = 272; p.face = 1;
        p.chick = chick ? 300 : 0; p.inv = 2;
        step(S, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
      }
      out.put("giant" + chick, findEnt(S, "giant").hp);

      S = quiet("bath", 1);
      p = S.players[0];
      for (int i = 0; i < 30; i++) {
        Ent wc = findEnt(S, "wc");
        wc.st = "tired"; wc.t = 5; p.x = 360; p.face = 1;
        p.chick = chick ? 300 : 0; p.inv = 2;
        step(S, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
      }
      out.put("wc" + chick, findEnt(S, "wc").hp);
    }
    check("chicken bites do double damage to the bosses",
      out.get("thieffalse") == 940 && out.get("thieftrue") == 880 &&
      out.get("giantfalse") == 940 && out.get("gianttrue") == 880 &&
      out.get("wcfalse") == 5 && out.get("wctrue") == 4,
      "thief " + out.get("thieffalse") + "/" + out.get("thieftrue") + ", giant " + out.get("giantfalse") + "/" + out.get("gianttrue") + ", toilet " + out.get("wcfalse") + "/" + out.get("wctrue") + " (without/with)");
  }

  // 16. Power-up timers stand still in cutscenes, carry on into the next scene, and are gone after a retry.
  {
    GameState S = newGame(1, "arena");
    S.players[0].gold = 300;
    S.players[0].chick = 400;
    int f = 0;
    while ("cut".equals(S.mode) && f++ < 3000) step(S, new InputState[] { new InputState(0, false, f % 2 == 0) });
    boolean frozen = "play".equals(S.mode) && S.players[0].gold == 300 && S.players[0].chick == 400;

    GameState H = quiet("hall", 1);
    Player p = H.players[0];
    H.v.lit = 3; H.v.doneT = 1; p.gold = 300;
    step(H, new InputState[] { ZERO_INP });
    int before = p.gold;
    boolean cutSeen = "cut".equals(H.mode);
    f = 0;
    while (("cut".equals(H.mode) || !"bath".equals(H.scene)) && f++ < 3000) step(H, new InputState[] { new InputState(0, false, f % 2 == 0) });
    boolean carried = cutSeen && "bath".equals(H.scene) && "play".equals(H.mode) && H.players[0].gold == before;
    H.mode = "over"; H.overT = 50;
    step(H, new InputState[] { ZERO_INP });
    step(H, new InputState[] { new InputState(0, false, true) });
    check("power-up timers stop in cutscenes, carry into the next scene, reset on retry",
      frozen && carried && H.players[0].gold == 0,
      "after the arena intro: " + S.players[0].gold + "/" + S.players[0].chick + "; hall -> bath: " + before + " -> " + (carried ? before : "?") + "; after retry: " + H.players[0].gold);
  }

  // 16b. Toilet throws brains only while the giant is down.
  {
    int downBrain = 0, downDuck = 0, upBrain = 0, upDuck = 0;
    for (int i = 0; i < 40; i++) {
      GameState S = quiet("giant", 1);
      Ent g = findEnt(S, "giant");
      g.st = "down"; g.t = 5; g.cd = 9999; S.players[0].hp = 2; S.v.dt = 1;
      step(S, new InputState[] { ZERO_INP, ZERO_INP });
      if (hasPow(S, "brain")) downBrain++;
      else if (findEnt(S, "duck") != null) downDuck++;

      S = quiet("giant", 1);
      g = findEnt(S, "giant");
      g.st = "walk"; g.t = 5; g.cd = 9999; S.players[0].hp = 2; S.v.dt = 1;
      step(S, new InputState[] { ZERO_INP, ZERO_INP });
      if (hasPow(S, "brain")) upBrain++;
      else if (findEnt(S, "duck") != null) upDuck++;
    }
    check("the toilet throws brains only while the giant is down",
      downBrain > 0 && downDuck > 0 && upBrain == 0 && upDuck == 40,
      "giant down: " + downBrain + " brains, " + downDuck + " ducks; giant standing: " + upBrain + " brains, " + upDuck + " ducks");
  }

  // 17. The garden gnome runs off when bitten; the toilet roll unrolls and the paper stays.
  {
    GameState S = quiet("house", 1);
    Player p = S.players[0];
    Ent gn = findEnt(S, "gnome");
    p.x = gn.x - 10; p.face = 1;
    for (int i = 0; i < 12; i++) {
      p.inv = 2;
      step(S, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
    }
    boolean ran = "run".equals(gn.st);
    for (int i = 0; i < 200; i++) {
      p.inv = 2;
      step(S, new InputState[] { ZERO_INP, ZERO_INP });
    }
    boolean gone = findEnt(S, "gnome") == null;

    GameState B = quiet("bath", 1);
    Player q = B.players[0];
    q.x = ROLL_X - 12; q.face = 1;
    for (int i = 0; i < 400; i++) {
      q.inv = 2; q.hp = 3;
      step(B, new InputState[] { new InputState(0, false, i == 0), ZERO_INP });
    }
    check("the gnome and the toilet roll react to a bite",
      ran && gone && B.v.roll == 1 && B.v.paper == 150,
      "gnome " + (ran ? "ran" : "stayed") + (gone ? " and left" : "") + ", roll " + B.v.roll + ", paper " + (int) B.v.paper + " px");
  }

  // 18. The head-drops-off gag: only after 6 s of standing still somewhere safe, and any input ends it at once.
  {
    GameState S = quiet("field", 1);
    Player p = S.players[0];
    runSteps(S, IDLE_GAG + 10, null);
    boolean started = p.idle >= IDLE_GAG;
    double x0 = p.x;
    runSteps(S, 1, new InputState(1, false, false));
    GameState A = quiet("arena", 1);
    runSteps(A, IDLE_GAG + 10, null);
    check("idle gag after 6 s, any input ends it, never in the arena",
      started && p.idle == 0 && p.x > x0 && A.players[0].idle == 0,
      "idle " + (started ? "reached the gag" : "did not start") + ", after one step of walking: idle " + p.idle + ", moved " + String.format(Locale.US, "%.1f", p.x - x0) + " px");
  }

  // 19. Events with positions survive the JSON round trip, and the list stays capped at 14.
  {
    GameState S = newGame(1, "giant");
    final HashMap<String, Integer> kinds = new HashMap<String, Integer>();
    final HashSet<String> counted = new HashSet<String>();
    final int[] longestAndPlain = { 0, 0 };
    final String[] bad = { "" };
    EachFn each = new EachFn() {
      public void run(GameState s) {
        JSONObject j = stateToJson(s);
        JSONArray copy = parseJSONObject(j.toString()).getJSONArray("evs");
        longestAndPlain[0] = Math.max(longestAndPlain[0], s.evs.size());
        for (int i = 0; i < copy.size(); i++) {
          JSONObject e = copy.getJSONObject(i);
          Ev o = s.evs.get(i);
          Integer ex = e.hasKey("x") ? e.getInt("x") : null;
          Integer ey = e.hasKey("y") ? e.getInt("y") : null;
          Integer evv = e.hasKey("v") ? e.getInt("v") : null;
          if (e.getInt("n") != o.n || !e.getString("s").equals(o.s) ||
              !java.util.Objects.equals(ex, o.x) || !java.util.Objects.equals(ey, o.y) || !java.util.Objects.equals(evv, o.v)) {
            bad[0] = e.toString();
          }
          String key = s.scene + o.n;
          if (counted.contains(key)) continue;
          counted.add(key);
          if (o.x == null) {
            longestAndPlain[1]++;
            continue;
          }
          kinds.put(o.s, kinds.getOrDefault(o.s, 0) + 1);
        }
      }
    };
    play(S, scripts.get("giant"), new PlayOpts(true, 20000, each));
    play(newGame(1, "field"), scripts.get("field"), new PlayOpts(true, 20000, each));
    int longest = longestAndPlain[0], plain = longestAndPlain[1];
    ArrayList<String> parts = new ArrayList<String>();
    for (String k : kinds.keySet()) parts.add(k + " " + kinds.get(k));
    check("events with positions survive the JSON round trip",
      bad[0].isEmpty() && kinds.getOrDefault("bosshit", 0) > 0 && kinds.getOrDefault("thud", 0) > 0 && kinds.getOrDefault("land", 0) > 0 && plain > 0 && longest <= 14,
      String.join(", ", parts) + ", " + plain + " without a position; longest list " + longest + (!bad[0].isEmpty() ? "; bad: " + bad[0] : ""));
  }

  // 20. Drawing-only changes must not change the game: field === 462 and hall === 389.
  {
    int fieldF = play(newGame(1, "field"), scripts.get("field"), new PlayOpts(true));
    int hallF = play(newGame(1, "hall"), scripts.get("hall"), new PlayOpts(true));
    GameState S = newGame(1, "field");
    int total = 0;
    while (!"end".equals(S.mode)) {
      int f = play(S, scripts.get(S.scene), new PlayOpts(true));
      if (f < 0) break;
      total += f;
    }
    check("the game rules are unchanged by the effects",
      fieldF == 462 && hallF == 389 && "end".equals(S.mode) && total > 7000 && total < 14000,
      "field " + fieldF + " frames (was 462), hall " + hallF + " (was 389), full game " + Math.round(total / 60.0) + " s (stage 2 runs: 159-167 s)");
  }

  runSysChecks();

  println(testFailed > 0 ? "\n" + testFailed + " check(s) failed" : "\nAll checks passed");
  if (testFailed > 0) {
    System.exit(1);
  }
  exit();
}

void saveShot(File dir, String name) {
  syncFramePg();
  File out = new File(dir, name);
  framePg.save(out.getAbsolutePath());
  println("SHOT  " + name);
}

void runShotsMode(String outFolder) {
  File dir = new File(outFolder);
  if (!dir.isAbsolute()) {
    dir = new File(sketchPath(), outFolder);
  }
  dir.mkdirs();

  // 1. Title screen
  saveLang = "nl";
  saveCh = 5;
  chSel = 1;
  menuSel = 0;
  appMode = "title";
  appTick = 40;
  renderApp();
  saveShot(dir, "01_title.png");

  // 2. Controls screen
  appMode = "controls";
  ctrlSel = 0;
  appTick = 40;
  renderApp();
  saveShot(dir, "02_controls.png");

  // 3-11. Every scene in play mode
  GameState sField = quiet("field", 1);
  sField.tick = 45;
  renderGame(sField, "nl", 45);
  saveShot(dir, "03_scene_field.png");

  GameState sForest = quiet("forest", 1);
  runSteps(sForest, 140, new InputState(1, false, false));
  renderGame(sForest, "nl", 140);
  saveShot(dir, "04_scene_forest.png");

  GameState sHouse = quiet("house", 1);
  runSteps(sHouse, 30, new InputState(1, false, false));
  renderGame(sHouse, "nl", 30);
  saveShot(dir, "05_scene_house.png");

  GameState sHall = quiet("hall", 1);
  sHall.players[0].x = 120;
  sHall.players[0].carry = 400;
  sHall.v.c.get(1).lit = 1;
  sHall.v.lit = 1;
  renderGame(sHall, "nl", 60);
  saveShot(dir, "06_scene_hall.png");

  GameState sBath = quiet("bath", 1);
  sBath.v.roll = 1;
  sBath.v.paper = 120;
  runSteps(sBath, 85, new InputState(1, false, false));
  renderGame(sBath, "nl", 85);
  saveShot(dir, "07_scene_bath.png");

  GameState sBed = quiet("bed", 1);
  sBed.players[0].x = 120;
  sBed.v.noise = 35;
  renderGame(sBed, "nl", 50);
  saveShot(dir, "08_scene_bed.png");

  GameState sChase = quiet("chase", 1);
  runSteps(sChase, 130, ZERO_INP);
  renderGame(sChase, "nl", 130);
  saveShot(dir, "09_scene_chase.png");

  GameState sArena = quiet("arena", 1);
  sArena.v.sun = 0.25d;
  sArena.v.cheer = 30;
  runSteps(sArena, 40, new InputState(1, false, false));
  renderGame(sArena, "nl", 40);
  saveShot(dir, "10_scene_arena.png");

  GameState sGiantUp = quiet("giant", 1);
  Ent gUp = findEnt(sGiantUp, "giant");
  gUp.st = "stomp";
  gUp.t = 20;
  gUp.x = 320;
  sGiantUp.v.sun = 0.35d;
  Ent dk = new Ent("duck");
  dk.x = 200; dk.y = SIM_G; dk.hasY = true; dk.st = "ground";
  sGiantUp.ents.add(dk);
  renderGame(sGiantUp, "nl", 90);
  saveShot(dir, "11_scene_giant_standing.png");

  // 12. Giant stunned on his back
  GameState sGiantDown = quiet("giant", 1);
  Ent gDown = findEnt(sGiantDown, "giant");
  gDown.st = "down";
  gDown.t = 40;
  gDown.x = 260;
  gDown.face = -1;
  gDown.hp = 940;
  gDown.bites = 1;
  sGiantDown.players[0].x = 290;
  sGiantDown.players[0].face = 1;
  sGiantDown.players[0].bite = 15;
  sGiantDown.v.ws = "w_slip";
  sGiantDown.v.wsT = 100;
  fxEnter(sGiantDown);
  ev(sGiantDown, "bosshit", gDown.x - gDown.face * 48, SIM_G - 30, 60);
  fxEvents(sGiantDown);
  fxFreeze = 0;
  renderGame(sGiantDown, "nl", 120);
  saveShot(dir, "12_scene_giant_stunned.png");

  // 13-19. Cutscene lines including intro, bedout, turn, and ending
  GameState sCut = newGame(1, "field");
  sCut.cut = new CutState("intro", 2, 120, "play");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 120);
  saveShot(dir, "13_cut_intro_museum.png");

  sCut = newGame(1, "bed");
  sCut.cut = new CutState("bedout", 2, 80, "next");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 80);
  saveShot(dir, "14_cut_bedout_bite.png");

  sCut = newGame(1, "arena");
  sCut.cut = new CutState("turn", 3, 95, "next");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 95);
  saveShot(dir, "15_cut_turn_grow.png");

  sCut = newGame(1, "arena");
  sCut.cut = new CutState("turn", 4, 100, "next");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 100);
  saveShot(dir, "16_cut_turn_roar.png");

  sCut = newGame(1, "arena");
  sCut.cut = new CutState("turn", 5, 140, "next");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 140);
  saveShot(dir, "17_cut_turn_wc.png");

  sCut = newGame(1, "giant");
  sCut.cut = new CutState("ending", 2, 120, "end");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 120);
  saveShot(dir, "18_cut_ending_beam.png");

  sCut = newGame(1, "giant");
  sCut.cut = new CutState("ending", 6, 120, "end");
  sCut.mode = "cut";
  renderGame(sCut, "nl", 120);
  saveShot(dir, "19_cut_ending_wc.png");

  // 20. End screen
  GameState sEnd = newGame(1, "giant");
  sEnd.cut = null;
  sEnd.mode = "end";
  sEnd.endT = 200;
  renderGame(sEnd, "nl", 200);
  saveShot(dir, "20_end_screen.png");

  // 21. Power-up active
  GameState sPow = quiet("forest", 1);
  sPow.players[0].x = 180;
  sPow.players[0].gold = GOLD_T - 40;
  sPow.players[0].chick = CHICK_T - 60;
  renderGame(sPow, "nl", 60);
  saveShot(dir, "21_powerup_active.png");

  // 22. Speech bubble and idle head-drops-off gag
  GameState sTalk = quiet("house", 1);
  sTalk.players[0].x = 180;
  sTalk.talk = new Talk(0, "z_key", 120);
  sTalk.players[0].idle = IDLE_GAG + 40;
  renderGame(sTalk, "nl", 80);
  saveShot(dir, "22_speech_bubble.png");

  println("Saved 22 screenshots to " + dir.getAbsolutePath());
  exit();
}

Object makeTestPadState(boolean connected, float lx, float ly, boolean dU, boolean dD, boolean dL, boolean dR, boolean a, boolean b, boolean x, boolean start) throws Exception {
  Constructor<?> ctor = padStateClass.getDeclaredConstructor();
  ctor.setAccessible(true);
  Object cs = ctor.newInstance();
  Field[] fs = { fConnected, fLeftX, fLeftY, fDpadUp, fDpadDown, fDpadLeft, fDpadRight, fA, fB, fX, fStart };
  for (Field f : fs) f.setAccessible(true);
  fConnected.setBoolean(cs, connected);
  fLeftX.setFloat(cs, lx);
  fLeftY.setFloat(cs, ly);
  fDpadUp.setBoolean(cs, dU);
  fDpadDown.setBoolean(cs, dD);
  fDpadLeft.setBoolean(cs, dL);
  fDpadRight.setBoolean(cs, dR);
  fA.setBoolean(cs, a);
  fB.setBoolean(cs, b);
  fX.setBoolean(cs, x);
  fStart.setBoolean(cs, start);
  return cs;
}

void runSysChecks() {
  // 21. Jamepad SDL2 native library load & live poll
  initControllers();
  refreshPads();
  check("jamepad native SDL2 library loaded", padLibraryLoaded && padManager != null, "loaded=" + padLibraryLoaded + ", connected=" + padCount());

  // 22. Controller mappings (stick/d-pad walk, Cross jump/ok, Square bite, Circle back, Options pause)
  try {
    Object walkL = makeTestPadState(true, -0.8f, 0f, false, false, false, false, false, false, false, false);
    Object dpadRJumpBite = makeTestPadState(true, 0f, 0f, false, false, false, true, true, false, true, false);
    injectedPadStates = new Object[] { walkL, dpadRJumpBite };
    int cnt = padCount();
    InputState p0 = pollDevice("pad0");
    InputState p1 = pollDevice("pad1");
    check("controller gameplay mapping (stick/d-pad walk, Cross jump, Square bite)",
      cnt == 2 && p0.mx == -1 && !p0.jump && !p0.act && p1.mx == 1 && p1.jump && p1.act,
      "padCount=" + cnt + ", pad0 mx=" + p0.mx + ", pad1 mx=" + p1.mx + " jump=" + p1.jump + " act=" + p1.act);

    prevMenu.clear();
    injectedPadStates = new Object[] { makeTestPadState(true, 0f, 0.85f, false, false, false, false, true, false, false, false), null };
    MenuInput m1 = inputTick();
    injectedPadStates = new Object[] { makeTestPadState(true, 0f, 0f, false, true, false, false, false, true, false, true), null };
    MenuInput m2 = inputTick();
    injectedPadStates = null;
    check("controller menu mapping (stick/d-pad up/down, Cross ok, Circle back, Options pause)",
      m1.up && m1.ok && !m1.back && !m1.pause && m2.down && m2.back && m2.pause,
      "m1(up=" + m1.up + ",ok=" + m1.ok + ") m2(down=" + m2.down + ",back=" + m2.back + ",pause=" + m2.pause + ")");
  } catch (Exception e) {
    check("controller mappings", false, e.toString());
  }

  // 23. Synthesized SFX & downsampled music WAV
  buildAllSfx();
  File wav = dataFile("night-of-chaos.wav");
  boolean wavOk = false;
  String wavInfo = "";
  try {
    AudioInputStream ais = AudioSystem.getAudioInputStream(wav);
    AudioFormat fmt = ais.getFormat();
    wavOk = (int) fmt.getSampleRate() == 22050 && fmt.getChannels() == 1 && fmt.getSampleSizeInBits() == 16;
    wavInfo = (int) fmt.getSampleRate() + " Hz, " + fmt.getChannels() + " ch, " + fmt.getSampleSizeInBits() + "-bit, " + (wav.length() / 1024) + " KB";
    ais.close();
  } catch (Exception e) {
    wavInfo = e.toString();
  }
  check("audio: 41 synthesized SFX and 22050 Hz mono 16-bit music WAV", sfxBuffers.size() == 41 && wavOk,
    sfxBuffers.size() + " SFX, music: " + wavInfo);

  // 24. Saved settings & progress round-trip
  File saveFile = new File(sketchPath("save.json"));
  boolean hadSave = saveFile.exists();
  byte[] oldBytes = null;
  try {
    if (hadSave) oldBytes = java.nio.file.Files.readAllBytes(saveFile.toPath());
    saveEnabled = true;
    saveLang = "en";
    saveCh = 4;
    saveMusic = false;
    saveDev[0] = "mouse";
    saveDev[1] = "pad0";
    storeSettings();
    saveLang = "nl";
    saveCh = 1;
    saveMusic = true;
    saveDev[0] = "kb1";
    saveDev[1] = "kb2";
    loadSettings();
    boolean ok = "en".equals(saveLang) && saveCh == 4 && !saveMusic && "mouse".equals(saveDev[0]) && "pad0".equals(saveDev[1]);
    check("saved settings and progress JSON round-trip", ok,
      "lang=" + saveLang + ", ch=" + saveCh + ", music=" + saveMusic + ", dev=" + saveDev[0] + "/" + saveDev[1]);
  } catch (Exception e) {
    check("saved settings and progress JSON round-trip", false, e.toString());
  } finally {
    saveEnabled = false;
    try {
      if (hadSave && oldBytes != null) java.nio.file.Files.write(saveFile.toPath(), oldBytes);
      else if (saveFile.exists()) saveFile.delete();
    } catch (Exception e) {}
  }
}
