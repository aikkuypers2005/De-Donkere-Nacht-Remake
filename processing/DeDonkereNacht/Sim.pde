// Game rules for De Donkere Nacht 2. No drawing in here, so it runs headless for testing.

final String[] ORDER = { "field", "forest", "house", "hall", "bath", "bed", "chase", "arena", "giant" };
final String[] CHAPTERS = { "field", "house", "bath", "bed", "arena" };
final int DOOR = 364;
final int ROLL_X = 300;
final int CHASE_LEN = 5400;
final int SUN_FRAMES = 10800;
final double SUN_CAP = 0.4d;
final int WC_X = 446, WC_Y = 172;
final int GOLD_T = 480, CHICK_T = 600;
final int TALK_T = 150, TALK_GAP = 480;
final int IDLE_GAG = 360, IDLE_END = 480;
final String[] URGENT = { "h_still", "h_stomp", "h_fist", "h_head" };
final String[] HAZARD = { "bat", "crow", "rat", "blob", "wave" };
final int REACH = 34;
final int STOMP_UP = 45, FIST_UP = 50, STUN = 300, MAX_BITES = 5;
final double[] G_SPEED = { 0, 0.6d, 0.75d, 0.9d };
final int[] G_CD = { 0, 190, 150, 115 };
final int[] DUCK_EVERY = { 0, 150, 130, 110 };
final String[] HECKLE = { "w_h1", "w_h2", "w_h3", "w_h4" };

class InputState {
  int mx;
  boolean jump;
  boolean act;

  InputState() {
    this(0, false, false);
  }

  InputState(int mx, boolean jump, boolean act) {
    this.mx = mx;
    this.jump = jump;
    this.act = act;
  }
}

final InputState ZERO_INP = new InputState(0, false, false);

class Box {
  double x, y, w, h;
  String k;

  Box(double x, double y, double w, double h) {
    this(x, y, w, h, null);
  }

  Box(double x, double y, double w, double h, String k) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.k = k;
  }
}

class Goal {
  String k;
  int n;
  int of;
  Double bar;

  Goal(String k) {
    this.k = k;
  }

  Goal(String k, int n, int of) {
    this.k = k;
    this.n = n;
    this.of = of;
  }

  Goal(String k, double bar) {
    this.k = k;
    this.bar = bar;
  }
}

class Player {
  int id;
  double x, y, vx, vy;
  int face = 1;
  boolean g = true;
  int hp = 3, inv = 0, bite = 0;
  boolean bh = false;
  int down = 0, carry = 0;
  double kb = 0;
  int stun = 0;
  boolean pj = false, pa = false, ai = false, blk = false, jumped = false;
  int gold = 0, chick = 0, idle = 0;

  Player(int i) {
    reset(i);
  }

  void reset(int i) {
    id = i;
    x = 30 + i * 22;
    y = SIM_G;
    vx = 0;
    vy = 0;
    face = 1;
    g = true;
    hp = 3;
    inv = 0;
    bite = 0;
    bh = false;
    down = 0;
    carry = 0;
    kb = 0;
    stun = 0;
    pj = false;
    pa = false;
    ai = false;
    blk = false;
    jumped = false;
    gold = 0;
    chick = 0;
    idle = 0;
  }
}

class Ev {
  int n;
  String s;
  Integer x, y, v;

  Ev(int n, String s) {
    this.n = n;
    this.s = s;
  }
}

class Talk {
  int who;
  String k;
  int t;

  Talk(int who, String k, int t) {
    this.who = who;
    this.k = k;
    this.t = t;
  }
}

class CutState {
  String id;
  int i;
  int t;
  String after;

  CutState(String id, int i, int t, String after) {
    this.id = id;
    this.i = i;
    this.t = t;
    this.after = after;
  }
}

class PrevPress {
  boolean j = false;
  boolean a = false;
}

class Scrap {
  double x, y;
  int got = 0;

  Scrap(double x, double y) {
    this.x = x;
    this.y = y;
  }
}

class Candle {
  double x, y;
  int lit;

  Candle(double x, double y, int lit) {
    this.x = x;
    this.y = y;
    this.lit = lit;
  }
}

class BedDuck {
  double x;
  int cd;

  BedDuck(double x, int cd) {
    this.x = x;
    this.cd = cd;
  }
}

class SceneVars {
  boolean isOpen = false;
  int gate = 3;
  int got = 0;
  double spawn = 120;
  ArrayList<Scrap> sc = new ArrayList<Scrap>();
  boolean key = false;
  int lit = 0;
  double rat = 240;
  int doneT = 0;
  ArrayList<Candle> c = new ArrayList<Candle>();
  int roll = 0;
  double paper = 0;
  double noise = 0;
  String ph = "snore";
  double pt = 170;
  int mum = 0;
  ArrayList<BedDuck> d = new ArrayList<BedDuck>();
  double dist = 0;
  double sp = 100;
  int thr = 0;
  int pw = 0;
  double sun = 0;
  boolean burn = false;
  boolean hasCrowd = false;
  int cheer = 0, boo = 0, wave = 0;
  double dt = 90;
  String ws = null;
  int wsT = 0, wt = 0;
}

class Ent {
  String type;
  String kind = "";
  double x = 0, y = 0, vx = 0, vy = 0;
  boolean hasY = false;
  boolean air = false;
  int t = 0;
  double by = 0;
  int dir = 1;
  int stN = 0;
  String st = "";
  double cd = 0;
  double tx = 0, ty = 0;
  int tt = 0;
  boolean dead = false;
  int hp = 0;
  int inv = 0;
  int n = 0;
  int face = 1;
  boolean g = true;
  int hits = 0;
  boolean stomp = false;
  int bites = 0;
  double walk = 0;
  boolean mv = false;
  double fx = 0;
  int k = 0;

  Ent(String type) {
    this.type = type;
  }
}

class GameState {
  int tick = 0;
  String mode = "play";
  String scene = null;
  ArrayList<Ent> ents = new ArrayList<Ent>();
  SceneVars v = new SceneVars();
  CutState cut = null;
  ArrayList<Ev> evs = new ArrayList<Ev>();
  int evN = 0;
  String msg = null;
  int msgT = 0;
  String hint = null;
  int shake = 0;
  int overT = 0;
  String overWhy = "";
  int endT = 0;
  int downT = 0;
  boolean paused = false;
  boolean two = false;
  double sun0 = SUN_CAP;
  Talk talk = null;
  int talkCd = 0;
  HashMap<String, Integer> said = new HashMap<String, Integer>();
  Player[] players = new Player[] { new Player(0), new Player(1) };
  PrevPress[] pp = new PrevPress[] { new PrevPress(), new PrevPress() };
}

abstract class SceneDef {
  String id;
  String intro = null;
  String outro = null;
  String next = null;
  int chapter = 1;
  boolean running = false;
  Box[] solids = new Box[0];
  Box[] plats = new Box[0];

  abstract void init(GameState S);
  abstract Goal goal(GameState S);
  abstract void update(GameState S);

  boolean interact(GameState S, Player p) { return false; }
  boolean hasInteract() { return false; }
  double minX(GameState S) { return 10; }
  double maxX(GameState S) { return S.v.isOpen ? SIM_W + 10 : SIM_W - 6; }
}

HashMap<String, SceneDef> SC = new HashMap<String, SceneDef>();

double rnd() {
  return Math.random();
}

boolean isUrgent(String h) {
  if (h == null) return false;
  for (String u : URGENT) if (u.equals(h)) return true;
  return false;
}

boolean isHazard(String t) {
  if (t == null) return false;
  for (String h : HAZARD) if (h.equals(t)) return true;
  return false;
}

void ev(GameState S, String s) {
  Ev e = new Ev(++S.evN, s);
  S.evs.add(e);
  if (S.evs.size() > 14) S.evs.remove(0);
}

void ev(GameState S, String s, double x, double y, int v) {
  Ev e = new Ev(++S.evN, s);
  e.x = (int) Math.round(x);
  e.y = (int) Math.round(y);
  e.v = v;
  S.evs.add(e);
  if (S.evs.size() > 14) S.evs.remove(0);
}

void say(GameState S, String k) {
  S.msg = k;
  S.msgT = 150;
}

boolean chat(GameState S, String k, Integer who, boolean once) {
  if (once && S.said.containsKey(k)) return false;
  if (!"play".equals(S.mode) || S.talk != null || S.talkCd > 0 || S.msgT > 0 || isUrgent(S.hint)) return false;
  int w = (who != null && (who == 0 || who == 1)) ? who : (rnd() < 0.5d ? 0 : 1);
  S.talk = new Talk(w, k, TALK_T);
  S.talkCd = TALK_GAP;
  if (once) S.said.put(k, 1);
  return true;
}

boolean chat(GameState S, String k, Integer who) {
  return chat(S, k, who, false);
}

boolean chat(GameState S, String k) {
  return chat(S, k, null, false);
}

ArrayList<Player> humans(GameState S) {
  ArrayList<Player> out = new ArrayList<Player>();
  for (Player p : S.players) if (!p.ai) out.add(p);
  return out;
}

ArrayList<Player> alive(GameState S) {
  ArrayList<Player> out = new ArrayList<Player>();
  for (Player p : S.players) if (!p.ai && p.down == 0) out.add(p);
  return out;
}

Box pbox(Player p) {
  return new Box(p.x - 5, p.y - 26, 10, 26);
}

boolean hit(Box a, Box b) {
  return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

Box biteBox(Player p) {
  if (p.down > 0 || p.bite < 6 || p.bite > 16) return null;
  double w = p.chick > 0 ? 34 : 17;
  return new Box(p.face > 0 ? p.x : p.x - w, p.y - 26, w, 24);
}

int power(Player p) {
  return p.chick > 0 ? 2 : 1;
}

boolean bites(Player p, Box b) {
  Box bb = biteBox(p);
  if (bb == null || p.bh || !hit(bb, b)) return false;
  p.bh = true;
  return true;
}

Player nearest(GameState S, double x) {
  Player best = null;
  for (Player p : alive(S)) {
    if (best == null || Math.abs(p.x - x) < Math.abs(best.x - x)) best = p;
  }
  return best;
}

boolean hurt(GameState S, Player p, int dir) {
  if (p.inv > 0 || p.down > 0 || p.ai || p.gold > 0) return false;
  p.hp--;
  p.inv = 90;
  p.kb = dir * 3;
  p.vy = -2.5d;
  p.g = false;
  if (p.carry > 0) p.carry = 0;
  S.shake = 5;
  ev(S, "hurt");
  if (S.v.hasCrowd) S.v.boo = 50;
  if (p.hp <= 0) {
    p.down = 1;
    ev(S, "down");
  } else {
    chat(S, rnd() < 0.5d ? "z_hurt1" : "z_hurt2", p.id);
  }
  return true;
}

Ent pow(GameState S, String kind, double x, double y) {
  return pow(S, kind, x, y, false, 0, 0);
}

Ent pow(GameState S, String kind, double x, double y, boolean air, double vx, double vy) {
  Ent e = new Ent("pow");
  e.kind = kind;
  e.x = x;
  e.y = y;
  e.hasY = true;
  e.vx = vx;
  e.vy = vy;
  e.air = air;
  e.t = 0;
  S.ents.add(e);
  return e;
}

boolean calm(GameState S, Player p) {
  SceneDef sc = SC.get(S.scene);
  if (sc.running || "bath".equals(S.scene) || "arena".equals(S.scene) || "giant".equals(S.scene)) return false;
  for (Ent e : S.ents) {
    if (isHazard(e.type) && Math.abs(e.x - p.x) < 140) return false;
  }
  return true;
}

void crowd(SceneVars v) {
  if (v.cheer > 0) v.cheer--;
  if (v.boo > 0) v.boo--;
  if (v.wave > 0) v.wave--;
  else if (rnd() < 1.0d / 700.0d) v.wave = 150;
}

void wcSay(GameState S, String k) {
  S.v.ws = k;
  S.v.wsT = 140;
}

double clampD(double x, double lo, double hi) {
  return Math.max(lo, Math.min(hi, x));
}

double[] lieRange(Ent g) {
  return g.face > 0 ? new double[] { 62, SIM_W - 52 } : new double[] { 52, SIM_W - 62 };
}

Box headBox(Ent g) {
  double hx = g.x - g.face * 48;
  return new Box(hx - 11, SIM_G - 22, 22, 22);
}

void slip(GameState S, Ent g, Ent d) {
  g.st = "slip";
  g.t = 0;
  g.fx = 0;
  d.st = "fly";
  d.t = 0;
  d.y = SIM_G - 4;
  d.hasY = true;
  d.vx = -g.face * 1.5d;
  d.vy = -5;
  ev(S, "squeak");
  wcSay(S, "w_slip");
  S.v.cheer = 50;
  chat(S, "z_slip");
}

boolean duckUnder(GameState S, Ent g, Ent d) {
  if (d.k != 0) {
    slip(S, g, d);
    return true;
  }
  d.vx = (d.x < g.x ? -1 : 1) * 2.2d;
  ev(S, "squeak");
  wcSay(S, "w_miss");
  return false;
}

void toWalk(Ent g, int ph) {
  g.st = "walk";
  g.t = 0;
  g.cd = G_CD[ph] + rnd() * 60;
}

Ent findEnt(GameState S, String type) {
  for (Ent e : S.ents) if (type.equals(e.type)) return e;
  return null;
}

void initScenes() {
  if (!SC.isEmpty()) return;
  initText();

  SceneDef field = new SceneDef() {
    {
      id = "field"; intro = "intro"; next = "forest"; chapter = 1;
      solids = new Box[] { new Box(140, 200, 14, 16, "tomb"), new Box(245, 194, 16, 22, "tomb2") };
      plats = new Box[0];
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.gate = 3;
      S.v.isOpen = false;
      pow(S, "chick", 278, SIM_G);
    }
    Goal goal(GameState S) {
      return S.v.isOpen ? new Goal("g_go") : new Goal("g_field");
    }
    double maxX(GameState S) {
      return S.v.isOpen ? SIM_W + 10 : 392;
    }
    void update(GameState S) {
      SceneVars v = S.v;
      Player lead = humans(S).get(0);
      S.hint = lead.x < 110 ? "h_move" : lead.x < 275 ? "h_jump" : !v.isOpen ? "h_bite" : null;
      if (lead.x > 128) chat(S, "z_tomb", lead.id, true);
      if (!v.isOpen) {
        for (Player p : humans(S)) {
          if (bites(p, new Box(398, 170, 12, 46))) {
            v.gate--;
            S.shake = 6;
            ev(S, "hit");
            if (v.gate <= 0) {
              v.isOpen = true;
              ev(S, "door");
            }
          }
        }
      }
    }
  };
  SC.put("field", field);

  SceneDef forest = new SceneDef() {
    {
      id = "forest"; next = "house"; chapter = 1;
      solids = new Box[0];
      plats = new Box[] {
        new Box(52, 178, 46, 0), new Box(128, 150, 46, 0), new Box(226, 178, 46, 0),
        new Box(292, 142, 44, 0), new Box(372, 176, 46, 0)
      };
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.got = 0;
      S.v.spawn = 120;
      S.v.sc.add(new Scrap(75, 168));
      S.v.sc.add(new Scrap(150, 140));
      S.v.sc.add(new Scrap(205, 206));
      S.v.sc.add(new Scrap(314, 132));
      S.v.sc.add(new Scrap(395, 166));
      pow(S, "gold", 328, 142);
    }
    Goal goal(GameState S) {
      return S.v.isOpen ? new Goal("g_go") : new Goal("g_forest", S.v.got, 5);
    }
    void update(GameState S) {
      SceneVars v = S.v;
      for (Scrap s : v.sc) {
        if (s.got != 0) continue;
        for (Player p : humans(S)) {
          if (p.down == 0 && hit(pbox(p), new Box(s.x - 5, s.y - 5, 10, 10))) {
            s.got = 1;
            v.got++;
            ev(S, "pick");
            if (v.got >= 5) {
              v.isOpen = true;
              ev(S, "door");
            }
            break;
          }
        }
      }
      ArrayList<Ent> bats = new ArrayList<Ent>();
      for (Ent e : S.ents) if ("bat".equals(e.type)) bats.add(e);
      int max = humans(S).size() > 1 ? 3 : 2;
      if (!v.isOpen && bats.size() < max && --v.spawn <= 0) {
        v.spawn = 200;
        boolean left = rnd() < 0.5;
        Ent b = new Ent("bat");
        b.x = left ? -10 : SIM_W + 10;
        b.y = 60;
        b.hasY = true;
        b.by = 66 + rnd() * 36;
        b.dir = left ? 1 : -1;
        b.t = 0;
        b.stN = 0;
        b.cd = 120 + rnd() * 100;
        b.tx = 0;
        b.ty = 0;
        S.ents.add(b);
      }
      for (Ent b : bats) {
        b.t++;
        if (v.isOpen) b.stN = 3;
        if (b.stN == 0) {
          b.x += b.dir * 1.1d;
          if (b.x < 20 && b.dir < 0) b.dir = 1;
          if (b.x > SIM_W - 20 && b.dir > 0) b.dir = -1;
          b.y += (b.by + Math.sin(b.t / 14.0d) * 8 - b.y) * 0.1d;
          Player t = nearest(S, b.x);
          if (--b.cd <= 0 && t != null && Math.abs(t.x - b.x) < 200) {
            b.stN = 1;
            b.tx = t.x;
            b.ty = t.y - 14;
            b.tt = 0;
          }
        } else if (b.stN == 1) {
          double dx = b.tx - b.x, dy = b.ty - b.y, d = Math.hypot(dx, dy);
          if (d < 3 || ++b.tt > 80) b.stN = 2;
          else {
            b.x += dx / d * 2.5d;
            b.y += dy / d * 2.5d;
          }
        } else if (b.stN == 2) {
          b.y -= 1.4d;
          b.x += b.dir * 0.8d;
          if (b.y <= b.by) {
            b.stN = 0;
            b.cd = 150 + rnd() * 120;
          }
        } else {
          b.y -= 2.2d;
          b.x += b.dir;
        }
        Box box = new Box(b.x - 6, b.y - 4, 12, 8);
        for (Player p : humans(S)) {
          if (bites(p, box)) {
            b.dead = true;
            ev(S, "pop");
            chat(S, "z_bat", p.id, true);
            if (rnd() < 1.0d / 3.0d) pow(S, "brain", b.x, b.y, true, 0, 0);
            break;
          }
          if (p.down == 0 && hit(pbox(p), box)) hurt(S, p, p.x < b.x ? -1 : 1);
        }
      }
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        Ent e = S.ents.get(i);
        if ("bat".equals(e.type) && (e.dead || e.y < -20)) S.ents.remove(i);
      }
    }
  };
  SC.put("forest", forest);

  SceneDef house = new SceneDef() {
    {
      id = "house"; intro = "house"; next = "hall"; chapter = 2;
      solids = new Box[] { new Box(120, 198, 18, 18, "crate"), new Box(138, 182, 22, 34, "crate2") };
      plats = new Box[0];
    }
    boolean hasInteract() { return true; }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.key = false;
      Ent crow = new Ent("crow");
      crow.x = 220; crow.y = 150; crow.hasY = true; crow.dir = 1; crow.hp = 2; crow.t = 0; crow.stN = 0; crow.cd = 220; crow.inv = 0; crow.tx = 0; crow.ty = 0;
      S.ents.add(crow);
      Ent gn = new Ent("gnome");
      gn.x = 96; gn.st = "stand"; gn.dir = 1; gn.t = 0;
      S.ents.add(gn);
      pow(S, "brain", 149, 182);
    }
    Goal goal(GameState S) {
      return new Goal(S.v.key ? "g_house2" : "g_house");
    }
    boolean interact(GameState S, Player p) {
      if (Math.abs(p.x - DOOR) > 16 || p.y < SIM_G - 2) return false;
      if (S.v.key) {
        ev(S, "door");
        complete(S);
      } else {
        say(S, "m_locked");
      }
      return true;
    }
    void update(GameState S) {
      SceneVars v = S.v;
      // iterate over snapshot size or allow adding key at the end
      int sz = S.ents.size();
      for (int idx = 0; idx < sz; idx++) {
        Ent c = S.ents.get(idx);
        if ("crow".equals(c.type)) {
          c.t++;
          if (c.inv > 0) c.inv--;
          double base = c.hp >= 2 ? 150 : 132;
          if (c.stN == 0) {
            c.x += c.dir * (c.hp >= 2 ? 1.2d : 1.7d);
            if (c.x < 40 && c.dir < 0) c.dir = 1;
            if (c.x > 330 && c.dir > 0) c.dir = -1;
            c.y += (base + Math.sin(c.t / 20.0d) * 5 - c.y) * 0.1d;
            Player t = nearest(S, c.x);
            if (--c.cd <= 0 && t != null && Math.abs(t.x - c.x) < 180) {
              c.stN = 1;
              c.tx = t.x;
              c.ty = t.y - 20;
              c.tt = 0;
            }
          } else if (c.stN == 1) {
            double dx = c.tx - c.x, dy = c.ty - c.y, d = Math.hypot(dx, dy);
            if (d < 3 || ++c.tt > 80) c.stN = 2;
            else {
              c.x += dx / d * 2.3d;
              c.y += dy / d * 2.3d;
              if (dx != 0) c.dir = dx > 0 ? 1 : -1;
            }
          } else if (c.stN == 2) {
            c.y -= 1.3d;
            c.x += c.dir * 0.8d;
            if (c.y <= base) {
              c.stN = 0;
              c.cd = 170 + rnd() * 120;
            }
          } else {
            c.y -= 2;
            c.x += c.dir * 1.5d;
          }
          Box box = new Box(c.x - 6, c.y - 5, 12, 9);
          if (c.stN != 3) {
            for (Player p : humans(S)) {
              if (c.inv <= 0 && bites(p, box)) {
                c.hp--;
                c.inv = 40;
                c.stN = 2;
                ev(S, "caw");
                if (c.hp <= 0) {
                  c.stN = 3;
                  Ent k = new Ent("key");
                  k.x = c.x; k.y = c.y; k.hasY = true; k.vy = 0;
                  S.ents.add(k);
                }
                break;
              }
              if (c.stN == 1 && p.down == 0 && hit(pbox(p), box)) {
                hurt(S, p, p.x < c.x ? -1 : 1);
                c.stN = 2;
              }
            }
          }
        } else if ("key".equals(c.type)) {
          c.vy += 0.25d;
          c.y = Math.min(SIM_G - 4, c.y + c.vy);
          for (Player p : humans(S)) {
            if (p.down == 0 && hit(pbox(p), new Box(c.x - 5, c.y - 5, 10, 10))) {
              c.dead = true;
              v.key = true;
              ev(S, "pick");
              say(S, "m_key");
              break;
            }
          }
        } else if ("gnome".equals(c.type)) {
          if ("stand".equals(c.st)) {
            for (Player p : humans(S)) {
              if (bites(p, new Box(c.x - 5, SIM_G - 14, 10, 14))) {
                c.st = "run";
                c.t = 0;
                c.dir = p.x < c.x ? 1 : -1;
                ev(S, "shriek");
                chat(S, "z_gnome", p.id);
                break;
              }
            }
          } else {
            c.t++;
            c.x += c.dir * 2.6d;
            if (c.x < -20 || c.x > SIM_W + 20) c.dead = true;
          }
        }
      }
      if (v.key && S.msgT == 0) chat(S, "z_key", null, true);
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        Ent e = S.ents.get(i);
        if (e.dead || ("crow".equals(e.type) && e.y < -20)) S.ents.remove(i);
      }
    }
  };
  SC.put("house", house);

  SceneDef hall = new SceneDef() {
    {
      id = "hall"; outro = "hall"; next = "bath"; chapter = 2;
      solids = new Box[] {
        new Box(150, 192, 36, 24, "dresser"),
        new Box(340, 196, 22, 20, "chair"),
        new Box(362, 172, 38, 44, "shelf")
      };
      plats = new Box[0];
    }
    boolean hasInteract() { return true; }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.lit = 0;
      S.v.rat = 240;
      S.v.doneT = 0;
      S.v.c.add(new Candle(60, 192, 1));
      S.v.c.add(new Candle(168, 152, 0));
      S.v.c.add(new Candle(312, 182, 0));
      S.v.c.add(new Candle(398, 130, 0));
      pow(S, "gold", 374, 172);
    }
    Goal goal(GameState S) {
      return new Goal("g_hall", S.v.lit, 3);
    }
    boolean interact(GameState S, Player p) {
      SceneVars v = S.v;
      for (Candle c : v.c) {
        double dy = p.y - c.y;
        if (Math.abs(p.x - c.x) > 13 || dy < 0 || dy > 52) continue;
        if (c.lit != 0) {
          p.carry = 480;
          ev(S, "flame");
        } else if (p.carry > 0) {
          c.lit = 1;
          v.lit++;
          ev(S, "light");
          chat(S, "z_candle", p.id, true);
          if (v.lit >= 3) v.doneT = 70;
        } else {
          say(S, "h_flame");
        }
        return true;
      }
      return false;
    }
    void update(GameState S) {
      SceneVars v = S.v;
      if (v.doneT > 0) {
        if (--v.doneT == 0) complete(S);
        return;
      }
      boolean carrying = false;
      for (Player p : humans(S)) {
        if (p.carry > 0) {
          carrying = true;
          if (--p.carry == 0) say(S, "m_out");
        }
      }
      S.hint = carrying ? "h_flame2" : "h_flame";
      chat(S, "z_dark", null, true);
      ArrayList<Ent> rats = new ArrayList<Ent>();
      for (Ent e : S.ents) if ("rat".equals(e.type)) rats.add(e);
      if (rats.size() < 2 && --v.rat <= 0) {
        v.rat = 200 + rnd() * 80;
        boolean left = rnd() < 0.5d;
        Ent r = new Ent("rat");
        r.x = left ? -10 : SIM_W + 10;
        r.dir = left ? 1 : -1;
        r.t = 0;
        S.ents.add(r);
      }
      for (Ent r : rats) {
        r.t++;
        r.x += r.dir * 1.3d;
        Box box = new Box(r.x - 6, SIM_G - 6, 12, 6);
        for (Player p : humans(S)) {
          if (bites(p, box)) {
            r.dead = true;
            ev(S, "pop");
            break;
          }
          if (p.down == 0 && hit(pbox(p), box)) hurt(S, p, p.x < r.x ? -1 : 1);
        }
      }
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        Ent e = S.ents.get(i);
        if ("rat".equals(e.type) && (e.dead || e.x < -20 || e.x > SIM_W + 20)) S.ents.remove(i);
      }
    }
  };
  SC.put("hall", hall);

  SceneDef bath = new SceneDef() {
    {
      id = "bath"; intro = "bath"; outro = "bathout"; next = "bed"; chapter = 3;
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.roll = 0;
      S.v.paper = 0;
      Ent wc = new Ent("wc");
      wc.x = 384; wc.hp = 6; wc.st = "laugh"; wc.t = 0; wc.n = 0; wc.inv = 0;
      S.ents.add(wc);
      pow(S, "brain", 340, SIM_G);
    }
    Goal goal(GameState S) {
      Ent wc = findEnt(S, "wc");
      return new Goal("g_bath", wc != null ? 6 - wc.hp : 6, 6);
    }
    double maxX(GameState S) {
      return 364;
    }
    void update(GameState S) {
      Ent wc = findEnt(S, "wc");
      if (wc == null) return;
      boolean mad = wc.hp <= 3;
      wc.t++;
      if (wc.inv > 0) wc.inv--;
      if ("laugh".equals(wc.st)) {
        if (wc.t == 1) ev(S, "laugh");
        if (wc.t > (mad ? 50 : 70)) {
          wc.st = "spit";
          wc.t = 0;
          wc.n = 0;
        }
      } else if ("spit".equals(wc.st)) {
        int every = mad ? 18 : 25, shots = mad ? 5 : 3;
        if (wc.t % every == 10 && wc.n < shots) {
          wc.n++;
          ArrayList<Player> pl = alive(S);
          Player t = pl.isEmpty() ? null : pl.get((int) (rnd() * pl.size()));
          double tx = t != null ? t.x + t.vx * 20 : 200;
          Ent bl = new Ent("blob");
          bl.x = 374; bl.y = 182; bl.hasY = true; bl.vx = (tx - 374) / 53.0d; bl.vy = -4.2d;
          S.ents.add(bl);
          ev(S, "spit");
        }
        if (wc.t > every * shots + 20) {
          wc.st = "flush";
          wc.t = 0;
        }
      } else if ("flush".equals(wc.st)) {
        if (wc.t == 1) ev(S, "flush");
        if (wc.t == 40 || (mad && wc.t == 78)) {
          Ent wv = new Ent("wave");
          wv.x = 366; wv.vx = -2.8d;
          S.ents.add(wv);
          S.shake = 6;
        }
        if (wc.t > 105) {
          wc.st = "tired";
          wc.t = 0;
        }
      } else if ("tired".equals(wc.st)) {
        if (wc.t > (mad ? 100 : 130)) {
          wc.st = "laugh";
          wc.t = 0;
        }
      } else if ("ouch".equals(wc.st)) {
        if (wc.t > 35) {
          wc.st = "laugh";
          wc.t = 0;
        }
      }
      boolean lidOpen = "spit".equals(wc.st) || "tired".equals(wc.st);
      chat(S, "z_wc", null, true);
      if (S.v.roll != 0 && S.v.paper < 150) S.v.paper = Math.min(150, S.v.paper + 2.5d);
      for (Player p : humans(S)) {
        if (S.v.roll == 0 && bites(p, new Box(ROLL_X - 6, 190, 12, 12))) {
          S.v.roll = 1;
          ev(S, "unroll");
          chat(S, "z_roll", p.id);
          continue;
        }
        if (bites(p, new Box(370, 176, 28, 40))) {
          if (lidOpen && wc.inv <= 0) {
            wc.hp = Math.max(0, wc.hp - power(p));
            wc.inv = 30;
            wc.st = "ouch";
            wc.t = 0;
            S.shake = 8;
            ev(S, "bosshit", wc.x, SIM_G - 44, power(p));
            if (wc.hp <= 0) {
              for (int i = S.ents.size() - 1; i >= 0; i--) {
                if (!"wc".equals(S.ents.get(i).type)) S.ents.remove(i);
              }
              complete(S);
              return;
            }
          } else {
            ev(S, "clang");
          }
        }
      }
      for (Ent e : S.ents) {
        if ("blob".equals(e.type)) {
          e.x += e.vx;
          e.y += e.vy;
          e.vy += 0.18d;
          if (e.y >= SIM_G - 3) {
            e.dead = true;
            ev(S, "splash");
          }
          for (Player p : humans(S)) {
            if (p.down == 0 && hit(pbox(p), new Box(e.x - 4, e.y - 4, 8, 8))) {
              if (hurt(S, p, -1)) e.dead = true;
            }
          }
        } else if ("wave".equals(e.type)) {
          e.x += e.vx;
          if (e.x < -20) e.dead = true;
          for (Player p : humans(S)) {
            if (p.down == 0 && hit(pbox(p), new Box(e.x - 7, SIM_G - 13, 14, 13))) hurt(S, p, -1);
          }
        }
      }
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        if (S.ents.get(i).dead) S.ents.remove(i);
      }
    }
  };
  SC.put("bath", bath);

  SceneDef bed = new SceneDef() {
    {
      id = "bed"; intro = "bed"; outro = "bedout"; next = "chase"; chapter = 4;
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.noise = 0;
      S.v.ph = "snore";
      S.v.pt = 170;
      S.v.mum = 0;
      S.v.d.add(new BedDuck(140, 0));
      S.v.d.add(new BedDuck(215, 0));
      S.v.d.add(new BedDuck(285, 0));
      pow(S, "gold", 304, SIM_G);
    }
    Goal goal(GameState S) {
      return new Goal("g_bed");
    }
    double maxX(GameState S) {
      return 342;
    }
    void update(GameState S) {
      SceneVars v = S.v;
      if (--v.pt <= 0) {
        if ("snore".equals(v.ph)) {
          v.ph = "stir";
          v.pt = 40;
          ev(S, "huh");
        } else if ("stir".equals(v.ph)) {
          v.ph = "listen";
          v.pt = 80;
        } else {
          v.ph = "snore";
          v.pt = 110 + rnd() * 70;
          v.mum = (v.mum + 1) % 4;
        }
      }
      if ("snore".equals(v.ph) && S.tick % 70 == 0) ev(S, "snore");
      ArrayList<Player> hs = alive(S);
      boolean moving = false;
      for (Player p : hs) if (Math.abs(p.vx) > 0.2d || !p.g) { moving = true; break; }
      if ("listen".equals(v.ph) && moving) v.noise += 2.4d;
      v.noise = Math.max(0, v.noise - 0.12d);
      for (BedDuck d : v.d) {
        if (d.cd > 0) {
          d.cd--;
          continue;
        }
        for (Player p : hs) {
          if (p.g && Math.abs(p.x - d.x) < 6) {
            v.noise += 40;
            d.cd = 50;
            ev(S, "squeak");
            chat(S, "z_duck", p.id);
            break;
          }
        }
      }
      S.hint = "snore".equals(v.ph) ? "h_walk" : "h_still";
      if (v.noise >= 100) {
        v.noise = 0;
        v.ph = "snore";
        v.pt = 170;
        ev(S, "alarm");
        say(S, "m_caught");
        S.shake = 10;
        for (Player p : hs) {
          if (p.gold <= 0) p.hp--;
          p.inv = 90;
          p.x = 30 + p.id * 22;
          p.y = SIM_G;
          p.vy = 0;
          if (p.hp <= 0) {
            p.down = 1;
            ev(S, "down");
          }
        }
        for (Player p : S.players) {
          if (p.ai) {
            p.x = 52;
            p.y = SIM_G;
          }
        }
        return;
      }
      for (Player p : hs) {
        if (p.x >= 338) {
          complete(S);
          break;
        }
      }
    }
  };
  SC.put("bed", bed);

  SceneDef chase = new SceneDef() {
    {
      id = "chase"; next = "arena"; chapter = 4; running = true;
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.dist = 0;
      S.v.sp = 100;
      S.v.thr = 0;
      S.v.pw = 0;
      for (Player p : S.players) p.x = 90 + p.id * 26;
    }
    Goal goal(GameState S) {
      return new Goal("g_chase", S.v.dist / CHASE_LEN);
    }
    double minX(GameState S) { return 10; }
    double maxX(GameState S) { return 300; }
    void update(GameState S) {
      SceneVars v = S.v;
      double prog = v.dist / CHASE_LEN;
      v.dist += 2;
      if (v.thr > 0) v.thr--;
      if (v.dist >= CHASE_LEN) {
        complete(S);
        return;
      }
      chat(S, "z_chase", null, true);
      if (v.pw == 0 && v.dist >= 2600) {
        v.pw = 1;
        pow(S, "brain", SIM_W + 10, SIM_G - 34, false, -2, 0);
      }
      if (--v.sp <= 0 && prog < 0.95d) {
        v.sp = 105 - 45 * prog + rnd() * 30;
        double r = rnd();
        ArrayList<Player> al = alive(S);
        Player t = al.isEmpty() ? null : al.get(0);
        if (r < 0.3d) {
          Ent lg = new Ent("log");
          lg.x = SIM_W + 12;
          S.ents.add(lg);
        } else if (r < 0.55d) {
          Ent pl = new Ent("pillow");
          pl.x = 424; pl.y = SIM_G - 22; pl.hasY = true; pl.vx = -3.4d; pl.vy = -1.5d;
          S.ents.add(pl);
          v.thr = 16;
          ev(S, "throw");
        } else if (r < 0.8d || prog < 0.15d) {
          double tx = (t != null ? t.x : 150) - 20;
          Ent lm = new Ent("lamp");
          lm.x = 424; lm.y = SIM_G - 24; lm.hasY = true; lm.vx = (tx - 424) / 60.0d; lm.vy = -5;
          S.ents.add(lm);
          v.thr = 16;
          ev(S, "throw");
        } else {
          Ent cb = new Ent("cbat");
          cb.x = SIM_W + 10; cb.y = SIM_G - 34; cb.hasY = true;
          S.ents.add(cb);
        }
      }
      for (Ent e : S.ents) {
        Box box = null;
        if ("log".equals(e.type)) {
          e.x -= 2;
          box = new Box(e.x - 7, SIM_G - 9, 14, 9);
        } else if ("fire".equals(e.type)) {
          e.x -= 2;
          e.t++;
          box = new Box(e.x - 6, SIM_G - 10, 12, 10);
        } else if ("cbat".equals(e.type)) {
          e.x -= 3.6d;
          box = new Box(e.x - 6, e.y - 4, 12, 8);
        } else if ("pillow".equals(e.type)) {
          e.x += e.vx;
          e.y += e.vy;
          e.vy += 0.2d;
          if (e.y >= SIM_G - 4) {
            e.y = SIM_G - 4;
            e.vy = -2.6d;
          }
          box = new Box(e.x - 6, e.y - 4, 12, 8);
        } else if ("lamp".equals(e.type)) {
          e.x += e.vx;
          e.y += e.vy;
          e.vy += 0.18d;
          if (e.y >= SIM_G - 4) {
            e.type = "fire";
            e.t = 0;
            ev(S, "smash");
            continue;
          }
          box = new Box(e.x - 4, e.y - 4, 8, 8);
        }
        if (box == null) continue;
        if (e.x < -20) {
          e.dead = true;
          continue;
        }
        for (Player p : humans(S)) {
          if (p.down == 0 && hit(pbox(p), box)) {
            if (hurt(S, p, -1)) {
              p.kb = -4;
              p.stun = 20;
              if ("pillow".equals(e.type) || "cbat".equals(e.type) || "lamp".equals(e.type)) e.dead = true;
            }
          }
        }
      }
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        if (S.ents.get(i).dead) S.ents.remove(i);
      }
    }
  };
  SC.put("chase", chase);

  SceneDef arena = new SceneDef() {
    {
      id = "arena"; intro = "arena"; outro = "turn"; next = "giant"; chapter = 5;
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.sun = 0;
      S.v.burn = false;
      S.v.hasCrowd = true;
      S.v.cheer = 0;
      S.v.boo = 0;
      S.v.wave = 0;
      Ent th = new Ent("thief");
      th.x = 400; th.y = SIM_G; th.hasY = true; th.vx = 0; th.vy = 0; th.g = true; th.face = -1;
      th.hp = 1000; th.st = "run"; th.t = 0; th.n = 0; th.inv = 0; th.hits = 0; th.stomp = false;
      S.ents.add(th);
      pow(S, "chick", 456, SIM_G);
    }
    Goal goal(GameState S) {
      return new Goal("g_arena");
    }
    void update(GameState S) {
      SceneVars v = S.v;
      Ent th = findEnt(S, "thief");
      v.sun += 1.0d / SUN_FRAMES;
      crowd(v);
      if (v.sun >= 1 && !v.burn) {
        v.burn = true;
        ev(S, "burn");
        for (Player p : humans(S)) {
          if (p.down == 0) {
            p.hp = 0;
            p.down = 1;
          }
        }
      }
      if (th == null) return;
      int ph = th.hp > 700 ? 1 : th.hp > 350 ? 2 : 3;
      Player tg = nearest(S, th.x);
      th.t++;
      if (th.inv > 0) th.inv--;
      double d = tg != null ? th.x - tg.x : 200;
      if ("run".equals(th.st)) {
        int dir = d >= 0 ? 1 : -1;
        th.vx = Math.abs(d) < 110 ? dir * (ph == 1 ? 1.7d : 1.9d) : 0;
        th.face = th.vx != 0 ? dir : -dir;
        boolean cornered = (th.x < 26 && dir < 0) || (th.x > SIM_W - 26 && dir > 0);
        if (cornered && Math.abs(d) < 60 && th.g) {
          th.vy = -6.4d;
          th.g = false;
          th.vx = -dir * 3.2d;
          th.st = "leap";
          ev(S, "jump");
        } else if (th.t > (ph == 1 ? 110 : 80) && th.g) {
          th.st = "atk";
          th.t = 0;
          th.n = 0;
          th.vx = 0;
        }
      } else if ("leap".equals(th.st)) {
        if (th.g) {
          th.st = "run";
          th.vx = 0;
        }
      } else if ("atk".equals(th.st)) {
        th.vx = 0;
        th.face = d >= 0 ? -1 : 1;
        int L = ph == 1 ? 55 : ph == 2 ? 50 : 70, cnt = ph == 3 ? 2 : 3;
        double tx = tg != null ? tg.x : 240;
        if (th.t % L == 25 && th.n < cnt) {
          if (ph == 1) {
            Ent rk = new Ent("rock");
            rk.x = th.x; rk.y = th.y - 22; rk.hasY = true; rk.vx = (tx - th.x) / 55.0d; rk.vy = -4.6d;
            S.ents.add(rk);
            ev(S, "throw");
          } else if (ph == 2) {
            Ent fb = new Ent("fball");
            fb.x = th.x + th.face * 8; fb.y = SIM_G - 8; fb.hasY = true; fb.vx = th.face * 3; fb.t = 0;
            S.ents.add(fb);
            ev(S, "fire");
          } else if (th.n % 2 == 0) {
            th.vy = -7;
            th.g = false;
            th.stomp = true;
            ev(S, "jump");
          } else {
            for (int o : new int[] { -44, 0, 44 }) {
              Ent rk = new Ent("rock");
              rk.x = th.x; rk.y = th.y - 22; rk.hasY = true; rk.vx = (tx + o - th.x) / 55.0d; rk.vy = -4.6d;
              S.ents.add(rk);
            }
            ev(S, "throw");
          }
          th.n++;
        }
        if (th.n >= cnt && th.t % L == L - 1) {
          th.st = "pant";
          th.t = 0;
          th.hits = 0;
        }
      } else if ("pant".equals(th.st)) {
        th.vx = 0;
        if (th.t > (ph == 1 ? 160 : ph == 2 ? 130 : 105) || th.hits >= 2) {
          th.st = "run";
          th.t = 0;
        }
      }
      th.x = Math.max(16, Math.min(SIM_W - 16, th.x + th.vx));
      th.vy += 0.32d;
      th.y += th.vy;
      if (th.y >= SIM_G) {
        th.y = SIM_G;
        th.vy = 0;
        if (!th.g && th.stomp) {
          th.stomp = false;
          S.shake = 10;
          ev(S, "thud", th.x, SIM_G, 2);
          Ent s1 = new Ent("shock"); s1.x = th.x - 8; s1.vx = -2.6d;
          Ent s2 = new Ent("shock"); s2.x = th.x + 8; s2.vx = 2.6d;
          S.ents.add(s1);
          S.ents.add(s2);
        }
        th.g = true;
      }
      for (Player p : humans(S)) {
        if (th.inv <= 0 && bites(p, new Box(th.x - 5, th.y - 26, 10, 26))) {
          th.hp -= 60 * power(p);
          th.inv = 35;
          th.hits++;
          S.shake = 6;
          ev(S, "bosshit", th.x, th.y - 34, 60 * power(p));
          v.cheer = 50;
          th.x = Math.max(16, Math.min(SIM_W - 16, th.x + p.face * 6));
          if (th.hp <= 0) {
            th.hp = 0;
            for (int i = S.ents.size() - 1; i >= 0; i--) {
              if (!"thief".equals(S.ents.get(i).type)) S.ents.remove(i);
            }
            complete(S);
            return;
          }
          if (th.hits >= 2 && th.g) {
            int away = (th.x - p.x >= 0 ? 1 : -1) * (th.x > SIM_W - 80 ? -1 : th.x < 80 ? -1 : 1);
            th.vy = -6.2d;
            th.g = false;
            th.vx = away * 3;
            th.st = "leap";
            th.t = 0;
            th.hits = 0;
            th.stomp = false;
          }
        }
      }
      for (Ent e : S.ents) {
        Box box = null;
        if ("rock".equals(e.type)) {
          e.x += e.vx;
          e.y += e.vy;
          e.vy += 0.18d;
          if (e.y >= SIM_G - 3) {
            e.dead = true;
            ev(S, "thud", e.x, SIM_G, 1);
          }
          box = new Box(e.x - 4, e.y - 4, 8, 8);
        } else if ("fball".equals(e.type)) {
          e.x += e.vx;
          e.t++;
          box = new Box(e.x - 5, e.y - 5, 10, 10);
        } else if ("shock".equals(e.type)) {
          e.x += e.vx;
          box = new Box(e.x - 6, SIM_G - 10, 12, 10);
        }
        if (box == null) continue;
        if (e.x < -20 || e.x > SIM_W + 20) e.dead = true;
        for (Player p : humans(S)) {
          if (p.down == 0 && hit(pbox(p), box)) {
            if (hurt(S, p, e.vx < 0 ? -1 : 1) && "rock".equals(e.type)) e.dead = true;
          }
        }
      }
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        if (S.ents.get(i).dead) S.ents.remove(i);
      }
    }
  };
  SC.put("arena", arena);

  SceneDef giant = new SceneDef() {
    {
      id = "giant"; outro = "ending"; chapter = 5;
    }
    void init(GameState S) {
      S.v = new SceneVars();
      S.v.isOpen = false;
      S.v.sun = S.sun0;
      S.v.burn = false;
      S.v.hasCrowd = true;
      S.v.dt = 90;
      S.v.ws = "w_h1";
      S.v.wsT = 150;
      S.v.wt = 0;
      S.v.cheer = 0;
      S.v.boo = 0;
      S.v.wave = 0;
      Ent g = new Ent("giant");
      g.x = 380; g.face = -1; g.hp = 1000; g.st = "roar"; g.t = 0; g.inv = 0; g.cd = 160;
      g.bites = 0; g.walk = 0; g.mv = false; g.fx = 0; g.tx = 0;
      S.ents.add(g);
    }
    Goal goal(GameState S) {
      Ent g = findEnt(S, "giant");
      return new Goal(g != null && "down".equals(g.st) ? "g_giant2" : "g_giant");
    }
    void update(GameState S) {
      SceneVars v = S.v;
      Ent g = findEnt(S, "giant");
      v.sun += 1.0d / SUN_FRAMES;
      if (v.sun >= 1 && !v.burn) {
        v.burn = true;
        ev(S, "burn");
        for (Player p : humans(S)) {
          if (p.down == 0) {
            p.hp = 0;
            p.down = 1;
          }
        }
      }
      if (v.wsT > 0) v.wsT--;
      if (v.wt > 0) v.wt--;
      crowd(v);
      if (g == null) return;
      if ("walk".equals(g.st)) chat(S, "z_giant", null, true);
      int ph = g.hp > 700 ? 1 : g.hp > 350 ? 2 : 3;
      Player tg = nearest(S, g.x);
      g.t++;
      if (g.inv > 0) g.inv--;
      g.mv = false;
      ArrayList<Ent> ducks = new ArrayList<Ent>();
      for (Ent e : S.ents) if ("duck".equals(e.type) && !"fly".equals(e.st)) ducks.add(e);
      Ent under = null;
      for (Ent d : ducks) {
        if ("ground".equals(d.st) && Math.abs(d.x - g.x) < 20 && (d.k != 0 || Math.abs(d.vx) < 1)) {
          under = d;
          break;
        }
      }

      if ("walk".equals(g.st)) {
        double d = tg != null ? tg.x - g.x : 0;
        if (Math.abs(d) > 2) g.face = d > 0 ? 1 : -1;
        if (tg != null && Math.abs(d) > 6) {
          g.x += g.face * G_SPEED[ph];
          g.walk += G_SPEED[ph];
          g.mv = true;
        }
        g.cd -= tg != null && Math.abs(d) < 70 ? 3 : 1;
        if (under != null && duckUnder(S, g, under)) {
          // slips
        } else if (g.cd <= 0 && tg != null) {
          double ad = Math.abs(d);
          if (ad < 18 || ad > 110 || rnd() < 0.4d) {
            g.st = "stomp";
            g.t = 0;
          } else {
            g.st = "fist";
            g.t = 0;
            g.tx = clampD(tg.x, 12, SIM_W - 12);
            g.face = d >= 0 ? 1 : -1;
          }
          if (rnd() < 0.5d) wcSay(S, "w_h4");
        }
      } else if ("stomp".equals(g.st)) {
        if (g.t == STOMP_UP) {
          if (under != null && duckUnder(S, g, under)) {
            // foot comes down on a kicked duck
          } else {
            S.shake = 12;
            ev(S, "thud", g.x + g.face * 8, SIM_G, 3);
            ev(S, "rumble");
            Ent s1 = new Ent("shock"); s1.x = g.x - 20; s1.vx = -2.4d;
            Ent s2 = new Ent("shock"); s2.x = g.x + 20; s2.vx = 2.4d;
            S.ents.add(s1);
            S.ents.add(s2);
            ArrayList<Player> pl = alive(S);
            int n = ph == 1 ? 2 : 3;
            ArrayList<Double> xs = new ArrayList<Double>();
            for (int i = 0; i < n; i++) {
              double x = 0;
              for (int k = 0; k < 6; k++) {
                x = clampD(i < pl.size() ? pl.get(i).x + (rnd() - 0.5d) * 50 : 30 + rnd() * 420, 12, SIM_W - 12);
                boolean ok = true;
                for (double o : xs) if (Math.abs(o - x) <= 28) { ok = false; break; }
                if (ok) break;
              }
              xs.add(x);
              Ent st = new Ent("stone");
              st.x = x; st.y = 108; st.hasY = true; st.vy = -2.5d;
              S.ents.add(st);
            }
            for (Player p : humans(S)) {
              if (p.down == 0 && p.y > SIM_G - 20 && Math.abs(p.x - (g.x + g.face * 6)) < 18) {
                hurt(S, p, p.x < g.x ? -1 : 1);
              }
            }
          }
        }
        if ("stomp".equals(g.st) && g.t >= STOMP_UP + 28) toWalk(g, ph);
      } else if ("fist".equals(g.st)) {
        if (g.t < FIST_UP - 8) {
          double want = clampD(g.tx - g.face * REACH, 24, SIM_W - 24);
          g.x += clampD(want - g.x, -2, 2);
        }
        g.fx = g.x + g.face * REACH;
        if (under != null && duckUnder(S, g, under)) {
          // slips
        } else {
          if (g.t == FIST_UP) {
            S.shake = 10;
            ev(S, "thud", g.fx, SIM_G, 2);
            for (Player p : humans(S)) {
              if (p.down == 0 && p.y > SIM_G - 30 && Math.abs(p.x - g.fx) < 15) {
                hurt(S, p, p.x < g.fx ? -1 : 1);
              }
            }
          }
          if (g.t >= FIST_UP + 30) toWalk(g, ph);
        }
      } else if ("slip".equals(g.st)) {
        double[] r = lieRange(g);
        g.x += g.face * 0.8d;
        g.x += clampD(clampD(g.x, r[0], r[1]) - g.x, -1.5d, 1.5d);
        if (g.t >= 36) {
          g.st = "down";
          g.t = 0;
          g.bites = 0;
          S.shake = 14;
          ev(S, "thud", g.x - g.face * 10, SIM_G, 4);
        }
      } else if ("down".equals(g.st)) {
        if (g.t >= STUN || (g.bites >= MAX_BITES && g.inv <= 15)) {
          g.st = "getup";
          g.t = 0;
          wcSay(S, "w_up");
        }
      } else if ("getup".equals(g.st)) {
        if (g.t >= 45) {
          g.st = "roar";
          g.t = 0;
        }
      } else if ("roar".equals(g.st)) {
        if (g.t == 1) {
          ev(S, "roar");
          S.shake = 20;
        }
        if (g.t >= 6 && g.t <= 40) {
          for (Player p : S.players) {
            if (p.down == 0 && Math.abs(p.x - g.x) < 230) p.kb = (p.x < g.x ? -1 : 1) * 3;
          }
          for (Ent d : ducks) {
            if ("ground".equals(d.st) && Math.abs(d.x - g.x) < 40) d.vx = (d.x < g.x ? -1 : 1) * 3;
          }
        }
        if (g.t >= 70) toWalk(g, ph);
      }
      if (!"slip".equals(g.st) && !"down".equals(g.st)) g.x = clampD(g.x, 24, SIM_W - 24);

      if ("walk".equals(g.st) && g.mv && g.t > 30) {
        for (Player p : humans(S)) {
          if (p.down == 0 && hit(pbox(p), new Box(g.x - 15, SIM_G - 48, 30, 48))) {
            int dir = p.x < g.x ? -1 : 1;
            if (hurt(S, p, dir)) p.kb = dir * 4.5d;
          }
        }
      }

      boolean down = "down".equals(g.st);
      Box body = down
        ? new Box(g.x + (g.face > 0 ? -36 : -48), SIM_G - 36, 84, 36)
        : new Box(g.x - 20, SIM_G - 112, 40, 112);
      for (Player p : humans(S)) {
        boolean kicked = false;
        for (Ent d : ducks) {
          if ("ground".equals(d.st) && bites(p, new Box(d.x - 5, SIM_G - 10, 10, 10))) {
            d.vx = p.face * 4.6d;
            d.k = 1;
            ev(S, "quack");
            kicked = true;
            break;
          }
        }
        if (kicked) continue;
        if (down && bites(p, headBox(g))) {
          if (g.inv <= 0 && g.bites < MAX_BITES) {
            g.hp -= 60 * power(p);
            g.inv = 35;
            g.bites++;
            S.shake = 6;
            ev(S, "bosshit", g.x - g.face * 48, SIM_G - 30, 60 * power(p));
            v.cheer = 50;
            if (g.hp <= 0) {
              g.hp = 0;
              for (int i = S.ents.size() - 1; i >= 0; i--) {
                if (!"giant".equals(S.ents.get(i).type)) S.ents.remove(i);
              }
              complete(S);
              return;
            }
          }
        } else if (bites(p, body)) {
          ev(S, "clang");
        }
      }

      if (ducks.isEmpty() && --v.dt <= 0) {
        v.dt = DUCK_EVERY[ph];
        double tx = 0;
        for (int k = 0; k < 8; k++) {
          tx = 40 + rnd() * 400;
          if (Math.abs(tx - g.x) > 80) break;
        }
        double T = 56.0d, x0 = WC_X - 8, y0 = WC_Y - 30;
        double vx = (tx - x0) / T, vy = (SIM_G - y0 - 0.1d * T * T) / T;
        boolean standing = "walk".equals(g.st) || "stomp".equals(g.st) || "fist".equals(g.st) || "roar".equals(g.st);
        boolean hurtOne = false;
        for (Player p : humans(S)) if (p.down == 0 && p.hp < 3) { hurtOne = true; break; }
        boolean anyPow = findEnt(S, "pow") != null;
        if (!standing && hurtOne && !anyPow && rnd() < 0.5d) {
          pow(S, "brain", x0, y0, true, vx, vy);
          v.dt = 60;
          wcSay(S, "w_brain");
        } else {
          Ent dk = new Ent("duck");
          dk.x = x0; dk.y = y0; dk.hasY = true; dk.vx = vx; dk.vy = vy; dk.st = "air"; dk.t = 0; dk.k = 0;
          S.ents.add(dk);
          wcSay(S, "w_duck");
        }
        ev(S, "throw");
        v.wt = 24;
      } else if (v.wsT <= 0 && rnd() < 0.004d) {
        wcSay(S, HECKLE[(int) (rnd() * HECKLE.length)]);
      }

      for (Ent e : S.ents) {
        Box box = null;
        if ("duck".equals(e.type)) {
          e.t++;
          if ("air".equals(e.st)) {
            e.x += e.vx;
            e.y += e.vy;
            e.vy += 0.2d;
            if (e.y >= SIM_G) {
              e.y = SIM_G;
              e.st = "ground";
              e.vx *= 0.3d;
              ev(S, "pop");
            }
          } else if ("ground".equals(e.st)) {
            e.x += e.vx;
            e.vx *= 0.975d;
            if (Math.abs(e.vx) < 0.05d) e.vx = 0;
            if ((e.x < 8 && e.vx < 0) || (e.x > SIM_W - 8 && e.vx > 0)) e.vx = -e.vx * 0.6d;
            e.x = clampD(e.x, 6, SIM_W - 6);
          } else {
            e.x += e.vx;
            e.y += e.vy;
            e.vy += 0.25d;
            if (e.t > 60) e.dead = true;
          }
        } else if ("stone".equals(e.type)) {
          e.y += e.vy;
          e.vy += 0.16d;
          if (e.y >= SIM_G - 4) {
            e.dead = true;
            ev(S, "thud", e.x, SIM_G, 1);
          }
          box = new Box(e.x - 5, e.y - 5, 10, 10);
        } else if ("shock".equals(e.type)) {
          e.x += e.vx;
          if (e.x < -20 || e.x > SIM_W + 20) e.dead = true;
          box = new Box(e.x - 6, SIM_G - 10, 12, 10);
        }
        if (box == null) continue;
        for (Player p : humans(S)) {
          if (p.down == 0 && hit(pbox(p), box)) {
            int dir = e.vx < 0 ? -1 : e.vx > 0 ? 1 : (p.x < e.x ? -1 : 1);
            if (hurt(S, p, dir) && "stone".equals(e.type)) e.dead = true;
          }
        }
      }
      for (int i = S.ents.size() - 1; i >= 0; i--) {
        if (S.ents.get(i).dead) S.ents.remove(i);
      }

      boolean anyGroundDuck = false;
      for (Ent d : ducks) if ("ground".equals(d.st)) { anyGroundDuck = true; break; }
      if (down) S.hint = "h_head";
      else if ("stomp".equals(g.st) && g.t < STOMP_UP + 20) S.hint = "h_stomp";
      else if ("fist".equals(g.st) && g.t < FIST_UP + 5) S.hint = "h_fist";
      else S.hint = anyGroundDuck ? "h_kick" : "h_wait";
    }
  };
  SC.put("giant", giant);
}

GameState newGame(int players, String scene) {
  initScenes();
  GameState S = new GameState();
  S.two = players == 2;
  S.players[1].ai = !S.two;
  startScene(S, scene != null ? scene : "field", true);
  return S;
}

void startScene(GameState S, String id, boolean first) {
  initScenes();
  if ("giant".equals(id) && "arena".equals(S.scene)) {
    S.sun0 = Math.min(SUN_CAP, S.v != null ? S.v.sun : 0);
  }
  S.scene = id;
  S.ents.clear();
  S.v = new SceneVars();
  S.hint = null;
  S.msg = null;
  S.msgT = 0;
  S.talk = null;
  S.mode = "play";
  S.overT = 0;
  S.downT = 0;
  S.cut = null;
  for (Player p : S.players) {
    boolean ai = p.ai;
    int gold = first ? p.gold : 0;
    int chick = first ? p.chick : 0;
    p.reset(p.id);
    p.ai = ai;
    p.gold = gold;
    p.chick = chick;
  }
  SceneDef sc = SC.get(id);
  sc.init(S);
  ev(S, "scene");
  if (first && sc.intro != null) startCut(S, sc.intro, "play");
}

void startCut(GameState S, String id, String after) {
  S.cut = new CutState(id, 0, 0, after);
  S.mode = "cut";
  S.hint = null;
}

void complete(GameState S) {
  if (!"play".equals(S.mode)) return;
  SceneDef sc = SC.get(S.scene);
  ev(S, "win");
  if (sc.outro != null) startCut(S, sc.outro, sc.next != null ? "next" : "end");
  else startScene(S, sc.next, true);
}

boolean pressed(GameState S, InputState[] inputs) {
  boolean any = false;
  for (int i = 0; i < S.players.length; i++) {
    Player p = S.players[i];
    InputState inp = (!p.ai && inputs != null && i < inputs.length && inputs[i] != null) ? inputs[i] : ZERO_INP;
    PrevPress pp = S.pp[i];
    if ((inp.jump && !pp.j) || (inp.act && !pp.a)) any = true;
    pp.j = inp.jump;
    pp.a = inp.act;
  }
  return any;
}

void stepCut(GameState S, InputState[] inputs) {
  CutState c = S.cut;
  CutStep[] steps = CUTS.get(c.id);
  CutStep st = steps[c.i];
  c.t++;
  if (c.t == 1) {
    if (st.fx != null) ev(S, st.fx);
    if (st.shake) S.shake = 24;
    if (st.card > 0) ev(S, "card");
  }
  boolean press = pressed(S, inputs);
  boolean adv = false;
  if (st.card > 0) adv = (press && c.t > 30) || c.t > 210;
  else if (press && c.t > 8) {
    if (c.t < st.len * 1.2d + 6) c.t = 100000;
    else adv = true;
  }
  if (!adv) return;
  c.i++;
  c.t = 0;
  if (c.i < steps.length) return;
  S.cut = null;
  for (Player p : S.players) {
    p.pj = true;
    p.pa = true;
  }
  if ("play".equals(c.after)) S.mode = "play";
  else if ("next".equals(c.after)) startScene(S, SC.get(S.scene).next, true);
  else {
    S.mode = "end";
    S.endT = 0;
    ev(S, "end");
  }
}

InputState aiInput(GameState S, Player p) {
  Player l = S.players[0];
  if (l.down > 0) return ZERO_INP;
  double d = l.x - l.face * 20 - p.x;
  int mx = Math.abs(d) > 5 ? (d > 0 ? 1 : -1) : 0;
  boolean j = false;
  if (p.g) {
    if (l.g && l.y < p.y - 10 && Math.abs(l.x - p.x) < 70) j = true;
    if (mx != 0 && p.blk) j = true;
    if (l.jumped && Math.abs(d) < 40) j = true;
  }
  return new InputState(mx, j && !p.pj, false);
}

void stepPlayer(GameState S, Player p, InputState inp, SceneDef sc) {
  p.jumped = false;
  if (p.inv > 0) p.inv--;
  if (p.gold > 0) p.gold--;
  if (p.chick > 0) p.chick--;
  if (p.down > 0) {
    p.idle = 0;
    p.vx = 0;
    p.vy += 0.32d;
    p.y = Math.min(SIM_G, p.y + p.vy);
    return;
  }
  boolean jp = inp.jump && !p.pj, ap = inp.act && !p.pa;
  p.pj = inp.jump;
  p.pa = inp.act;
  int mx = Math.max(-1, Math.min(1, inp.mx));
  p.idle = (!p.ai && mx == 0 && !inp.jump && !inp.act && p.g && calm(S, p)) ? (p.idle + 1) % IDLE_END : 0;
  if (p.idle == IDLE_END - 1) chat(S, "z_head", p.id);
  if (p.stun > 0) {
    p.stun--;
    mx = 0;
  }
  p.vx = mx * (p.gold > 0 ? 2.1d : 1.5d) + p.kb;
  p.kb *= 0.85d;
  if (Math.abs(p.kb) < 0.1d) p.kb = 0;
  if (mx != 0) p.face = mx > 0 ? 1 : -1;
  if (sc.running && mx == 0) p.face = 1;
  if (jp && p.g) {
    p.vy = -5.4d;
    p.g = false;
    p.jumped = true;
    ev(S, "jump");
  }
  if (ap && !p.ai) {
    if (!(sc.hasInteract() && sc.interact(S, p)) && p.bite <= 0) {
      p.bite = 20;
      p.bh = false;
      ev(S, "bite");
    }
  }
  if (!"play".equals(S.mode)) return;
  if (p.bite > 0) p.bite--;

  double nx = p.x + p.vx;
  p.blk = false;
  for (Box s : sc.solids) {
    if (p.y > s.y + 1 && p.y - 26 < s.y + s.h && nx + 5 > s.x && nx - 5 < s.x + s.w) {
      nx = p.x < s.x + s.w / 2.0d ? s.x - 5 : s.x + s.w + 5;
      p.blk = true;
    }
  }
  double lo = sc.minX(S);
  double hi = sc.maxX(S);
  p.x = Math.max(lo, Math.min(hi, nx));

  double oy = p.y;
  boolean wasG = p.g;
  p.vy = Math.min(6, p.vy + 0.32d);
  double fall = p.vy;
  p.y += p.vy;
  p.g = false;
  if (p.y >= SIM_G) {
    p.y = SIM_G;
    p.vy = 0;
    p.g = true;
  }
  if (p.vy >= 0) {
    for (Box s : sc.solids) {
      if (oy <= s.y + 0.01d && p.y >= s.y && p.x + 5 > s.x && p.x - 5 < s.x + s.w) {
        p.y = s.y;
        p.vy = 0;
        p.g = true;
      }
    }
    for (Box s : sc.plats) {
      if (oy <= s.y + 0.01d && p.y >= s.y && p.x + 5 > s.x && p.x - 5 < s.x + s.w) {
        p.y = s.y;
        p.vy = 0;
        p.g = true;
      }
    }
  }
  if (p.g && !wasG && fall > 2) ev(S, "land", p.x, p.y, p.id);
}

void stepPows(GameState S) {
  for (Ent e : S.ents) {
    if (!"pow".equals(e.type)) continue;
    e.t++;
    e.x += e.vx;
    if (e.air) {
      e.y += e.vy;
      e.vy += 0.2d;
      if (e.y >= SIM_G) {
        e.y = SIM_G;
        e.air = false;
        e.vx = 0;
        e.vy = 0;
      }
    }
    if (e.x < -20 || e.x > SIM_W + 30) {
      e.dead = true;
      continue;
    }
    for (Player p : humans(S)) {
      if (p.down > 0 || !hit(pbox(p), new Box(e.x - 6, e.y - 12, 12, 12))) continue;
      if ("brain".equals(e.kind)) {
        if (p.hp >= 3) continue;
        p.hp++;
        ev(S, "pick");
        chat(S, "z_brain", p.id);
      } else if ("gold".equals(e.kind)) {
        p.gold = GOLD_T;
        ev(S, "power");
        chat(S, "z_gold", p.id);
      } else {
        p.chick = CHICK_T;
        ev(S, "power");
        chat(S, "z_chick", p.id);
      }
      e.dead = true;
      break;
    }
  }
  for (int i = S.ents.size() - 1; i >= 0; i--) {
    Ent e = S.ents.get(i);
    if ("pow".equals(e.type) && e.dead) S.ents.remove(i);
  }
}

void step(GameState S, InputState[] inputs) {
  if (S.paused) return;
  S.tick++;
  if (S.shake > 0) S.shake--;
  if (S.msgT > 0) S.msgT--;
  if ("cut".equals(S.mode)) {
    stepCut(S, inputs);
    return;
  }
  if ("end".equals(S.mode)) {
    S.endT++;
    return;
  }
  if ("over".equals(S.mode)) {
    S.overT++;
    if (pressed(S, inputs) && S.overT > 45) startScene(S, S.scene, false);
    return;
  }
  SceneDef sc = SC.get(S.scene);
  for (Player p : S.players) {
    InputState inp = p.ai ? aiInput(S, p) : (inputs != null && p.id < inputs.length && inputs[p.id] != null ? inputs[p.id] : ZERO_INP);
    stepPlayer(S, p, inp, sc);
    if (!"play".equals(S.mode)) return;
  }
  sc.update(S);
  if (!"play".equals(S.mode) || !sc.id.equals(S.scene)) return;
  stepPows(S);
  if (S.talk != null && (--S.talk.t <= 0 || S.msgT > 0 || isUrgent(S.hint))) S.talk = null;
  if (S.talkCd > 0) S.talkCd--;

  ArrayList<Player> hs = humans(S);
  ArrayList<Player> up = alive(S);
  for (Player p : hs) {
    if (p.down > 0) {
      p.down++;
      if (!up.isEmpty() && p.down > 240 && !S.v.burn) {
        p.down = 0;
        p.hp = 2;
        p.inv = 120;
        ev(S, "pick");
      }
    }
  }
  if (up.isEmpty()) {
    if (++S.downT > 50) {
      S.mode = "over";
      S.overT = 0;
      S.overWhy = S.v.burn ? "sun" : "";
      ev(S, "over");
    }
    return;
  }
  if (S.v.isOpen) {
    for (Player p : up) {
      if (p.x >= SIM_W - 7) {
        complete(S);
        break;
      }
    }
  }
}

void skip(GameState S, int dir) {
  int idx = -1;
  for (int i = 0; i < ORDER.length; i++) if (ORDER[i].equals(S.scene)) idx = i;
  int nextIdx = idx + dir;
  if (nextIdx < 0) return;
  if (nextIdx >= ORDER.length) {
    startCut(S, "ending", "end");
    return;
  }
  startScene(S, ORDER[nextIdx], true);
}

// JSON round-trip helpers for testing plain-data state integrity
void checkFinite(double d, String name) {
  if (Double.isNaN(d) || Double.isInfinite(d)) throw new RuntimeException("Bad number in " + name + ": " + d);
}

JSONObject stateToJson(GameState S) {
  JSONObject j = new JSONObject();
  j.setInt("tick", S.tick);
  j.setString("mode", S.mode);
  j.setString("scene", S.scene);
  j.setInt("evN", S.evN);
  j.setString("msg", S.msg);
  j.setInt("msgT", S.msgT);
  j.setString("hint", S.hint);
  j.setInt("shake", S.shake);
  j.setInt("overT", S.overT);
  j.setString("overWhy", S.overWhy);
  j.setInt("endT", S.endT);
  j.setInt("downT", S.downT);
  j.setBoolean("paused", S.paused);
  j.setBoolean("two", S.two);
  checkFinite(S.sun0, "sun0");
  j.setDouble("sun0", S.sun0);
  j.setInt("talkCd", S.talkCd);

  if (S.cut != null) {
    JSONObject c = new JSONObject();
    c.setString("id", S.cut.id);
    c.setInt("i", S.cut.i);
    c.setInt("t", S.cut.t);
    c.setString("after", S.cut.after);
    j.setJSONObject("cut", c);
  } else j.setJSONObject("cut", null);

  if (S.talk != null) {
    JSONObject t = new JSONObject();
    t.setInt("who", S.talk.who);
    t.setString("k", S.talk.k);
    t.setInt("t", S.talk.t);
    j.setJSONObject("talk", t);
  } else j.setJSONObject("talk", null);

  JSONObject said = new JSONObject();
  for (String k : S.said.keySet()) said.setInt(k, S.said.get(k));
  j.setJSONObject("said", said);

  JSONArray pls = new JSONArray();
  for (int i = 0; i < S.players.length; i++) {
    Player p = S.players[i];
    checkFinite(p.x, "p.x"); checkFinite(p.y, "p.y"); checkFinite(p.vx, "p.vx"); checkFinite(p.vy, "p.vy"); checkFinite(p.kb, "p.kb");
    JSONObject pj = new JSONObject();
    pj.setInt("id", p.id); pj.setDouble("x", p.x); pj.setDouble("y", p.y); pj.setDouble("vx", p.vx); pj.setDouble("vy", p.vy);
    pj.setInt("face", p.face); pj.setBoolean("g", p.g); pj.setInt("hp", p.hp); pj.setInt("inv", p.inv); pj.setInt("bite", p.bite);
    pj.setBoolean("bh", p.bh); pj.setInt("down", p.down); pj.setInt("carry", p.carry); pj.setDouble("kb", p.kb); pj.setInt("stun", p.stun);
    pj.setBoolean("pj", p.pj); pj.setBoolean("pa", p.pa); pj.setBoolean("ai", p.ai); pj.setBoolean("blk", p.blk); pj.setBoolean("jumped", p.jumped);
    pj.setInt("gold", p.gold); pj.setInt("chick", p.chick); pj.setInt("idle", p.idle);
    pls.setJSONObject(i, pj);
  }
  j.setJSONArray("players", pls);

  JSONArray pps = new JSONArray();
  for (int i = 0; i < S.pp.length; i++) {
    JSONObject ppj = new JSONObject();
    ppj.setBoolean("j", S.pp[i].j);
    ppj.setBoolean("a", S.pp[i].a);
    pps.setJSONObject(i, ppj);
  }
  j.setJSONArray("pp", pps);

  JSONArray evs = new JSONArray();
  for (int i = 0; i < S.evs.size(); i++) {
    Ev e = S.evs.get(i);
    JSONObject ej = new JSONObject();
    ej.setInt("n", e.n);
    ej.setString("s", e.s);
    if (e.x != null) ej.setInt("x", e.x);
    if (e.y != null) ej.setInt("y", e.y);
    if (e.v != null) ej.setInt("v", e.v);
    evs.setJSONObject(i, ej);
  }
  j.setJSONArray("evs", evs);

  JSONArray ents = new JSONArray();
  for (int i = 0; i < S.ents.size(); i++) {
    Ent e = S.ents.get(i);
    checkFinite(e.x, "e.x"); checkFinite(e.y, "e.y"); checkFinite(e.vx, "e.vx"); checkFinite(e.vy, "e.vy");
    checkFinite(e.by, "e.by"); checkFinite(e.cd, "e.cd"); checkFinite(e.tx, "e.tx"); checkFinite(e.ty, "e.ty");
    checkFinite(e.walk, "e.walk"); checkFinite(e.fx, "e.fx");
    JSONObject ej = new JSONObject();
    ej.setString("type", e.type); ej.setString("kind", e.kind);
    ej.setDouble("x", e.x); ej.setDouble("y", e.y); ej.setDouble("vx", e.vx); ej.setDouble("vy", e.vy);
    ej.setBoolean("hasY", e.hasY); ej.setBoolean("air", e.air); ej.setInt("t", e.t); ej.setDouble("by", e.by);
    ej.setInt("dir", e.dir); ej.setInt("stN", e.stN); ej.setString("st", e.st); ej.setDouble("cd", e.cd);
    ej.setDouble("tx", e.tx); ej.setDouble("ty", e.ty); ej.setInt("tt", e.tt); ej.setBoolean("dead", e.dead);
    ej.setInt("hp", e.hp); ej.setInt("inv", e.inv); ej.setInt("n", e.n); ej.setInt("face", e.face);
    ej.setBoolean("g", e.g); ej.setInt("hits", e.hits); ej.setBoolean("stomp", e.stomp);
    ej.setInt("bites", e.bites); ej.setDouble("walk", e.walk); ej.setBoolean("mv", e.mv);
    ej.setDouble("fx", e.fx); ej.setInt("k", e.k);
    ents.setJSONObject(i, ej);
  }
  j.setJSONArray("ents", ents);

  SceneVars v = S.v;
  checkFinite(v.spawn, "v.spawn"); checkFinite(v.rat, "v.rat"); checkFinite(v.paper, "v.paper");
  checkFinite(v.noise, "v.noise"); checkFinite(v.pt, "v.pt"); checkFinite(v.dist, "v.dist");
  checkFinite(v.sp, "v.sp"); checkFinite(v.sun, "v.sun"); checkFinite(v.dt, "v.dt");
  JSONObject vj = new JSONObject();
  vj.setBoolean("open", v.isOpen); vj.setInt("gate", v.gate); vj.setInt("got", v.got); vj.setDouble("spawn", v.spawn);
  vj.setBoolean("key", v.key); vj.setInt("lit", v.lit); vj.setDouble("rat", v.rat); vj.setInt("doneT", v.doneT);
  vj.setInt("roll", v.roll); vj.setDouble("paper", v.paper); vj.setDouble("noise", v.noise);
  vj.setString("ph", v.ph); vj.setDouble("pt", v.pt); vj.setInt("mum", v.mum);
  vj.setDouble("dist", v.dist); vj.setDouble("sp", v.sp); vj.setInt("thr", v.thr); vj.setInt("pw", v.pw);
  vj.setDouble("sun", v.sun); vj.setBoolean("burn", v.burn); vj.setBoolean("hasCrowd", v.hasCrowd);
  vj.setInt("cheer", v.cheer); vj.setInt("boo", v.boo); vj.setInt("wave", v.wave);
  vj.setDouble("dt", v.dt); vj.setString("ws", v.ws); vj.setInt("wsT", v.wsT); vj.setInt("wt", v.wt);

  JSONArray scArr = new JSONArray();
  for (int i = 0; i < v.sc.size(); i++) {
    Scrap s = v.sc.get(i);
    JSONObject sj = new JSONObject();
    sj.setDouble("x", s.x); sj.setDouble("y", s.y); sj.setInt("got", s.got);
    scArr.setJSONObject(i, sj);
  }
  vj.setJSONArray("sc", scArr);

  JSONArray cArr = new JSONArray();
  for (int i = 0; i < v.c.size(); i++) {
    Candle c = v.c.get(i);
    JSONObject cj = new JSONObject();
    cj.setDouble("x", c.x); cj.setDouble("y", c.y); cj.setInt("lit", c.lit);
    cArr.setJSONObject(i, cj);
  }
  vj.setJSONArray("c", cArr);

  JSONArray dArr = new JSONArray();
  for (int i = 0; i < v.d.size(); i++) {
    BedDuck d = v.d.get(i);
    JSONObject dj = new JSONObject();
    dj.setDouble("x", d.x); dj.setInt("cd", d.cd);
    dArr.setJSONObject(i, dj);
  }
  vj.setJSONArray("d", dArr);

  j.setJSONObject("v", vj);
  return j;
}

GameState stateFromJson(JSONObject j) {
  GameState S = new GameState();
  S.tick = j.getInt("tick");
  S.mode = j.isNull("mode") ? null : j.getString("mode");
  S.scene = j.isNull("scene") ? null : j.getString("scene");
  S.evN = j.getInt("evN");
  S.msg = j.isNull("msg") ? null : j.getString("msg");
  S.msgT = j.getInt("msgT");
  S.hint = j.isNull("hint") ? null : j.getString("hint");
  S.shake = j.getInt("shake");
  S.overT = j.getInt("overT");
  S.overWhy = j.getString("overWhy");
  S.endT = j.getInt("endT");
  S.downT = j.getInt("downT");
  S.paused = j.getBoolean("paused");
  S.two = j.getBoolean("two");
  S.sun0 = j.getDouble("sun0");
  S.talkCd = j.getInt("talkCd");

  if (!j.isNull("cut")) {
    JSONObject c = j.getJSONObject("cut");
    S.cut = new CutState(c.getString("id"), c.getInt("i"), c.getInt("t"), c.getString("after"));
  }
  if (!j.isNull("talk")) {
    JSONObject t = j.getJSONObject("talk");
    S.talk = new Talk(t.getInt("who"), t.getString("k"), t.getInt("t"));
  }
  JSONObject said = j.getJSONObject("said");
  for (Object ko : said.keys()) {
    String k = (String) ko;
    S.said.put(k, said.getInt(k));
  }

  JSONArray pls = j.getJSONArray("players");
  for (int i = 0; i < 2; i++) {
    JSONObject pj = pls.getJSONObject(i);
    Player p = S.players[i];
    p.id = pj.getInt("id"); p.x = pj.getDouble("x"); p.y = pj.getDouble("y"); p.vx = pj.getDouble("vx"); p.vy = pj.getDouble("vy");
    p.face = pj.getInt("face"); p.g = pj.getBoolean("g"); p.hp = pj.getInt("hp"); p.inv = pj.getInt("inv"); p.bite = pj.getInt("bite");
    p.bh = pj.getBoolean("bh"); p.down = pj.getInt("down"); p.carry = pj.getInt("carry"); p.kb = pj.getDouble("kb"); p.stun = pj.getInt("stun");
    p.pj = pj.getBoolean("pj"); p.pa = pj.getBoolean("pa"); p.ai = pj.getBoolean("ai"); p.blk = pj.getBoolean("blk"); p.jumped = pj.getBoolean("jumped");
    p.gold = pj.getInt("gold"); p.chick = pj.getInt("chick"); p.idle = pj.getInt("idle");
  }

  JSONArray pps = j.getJSONArray("pp");
  for (int i = 0; i < 2; i++) {
    JSONObject ppj = pps.getJSONObject(i);
    S.pp[i].j = ppj.getBoolean("j");
    S.pp[i].a = ppj.getBoolean("a");
  }

  JSONArray evs = j.getJSONArray("evs");
  for (int i = 0; i < evs.size(); i++) {
    JSONObject ej = evs.getJSONObject(i);
    Ev e = new Ev(ej.getInt("n"), ej.getString("s"));
    if (ej.hasKey("x") && !ej.isNull("x")) e.x = ej.getInt("x");
    if (ej.hasKey("y") && !ej.isNull("y")) e.y = ej.getInt("y");
    if (ej.hasKey("v") && !ej.isNull("v")) e.v = ej.getInt("v");
    S.evs.add(e);
  }

  JSONArray ents = j.getJSONArray("ents");
  for (int i = 0; i < ents.size(); i++) {
    JSONObject ej = ents.getJSONObject(i);
    Ent e = new Ent(ej.getString("type"));
    e.kind = ej.getString("kind");
    e.x = ej.getDouble("x"); e.y = ej.getDouble("y"); e.vx = ej.getDouble("vx"); e.vy = ej.getDouble("vy");
    e.hasY = ej.getBoolean("hasY"); e.air = ej.getBoolean("air"); e.t = ej.getInt("t"); e.by = ej.getDouble("by");
    e.dir = ej.getInt("dir"); e.stN = ej.getInt("stN"); e.st = ej.getString("st"); e.cd = ej.getDouble("cd");
    e.tx = ej.getDouble("tx"); e.ty = ej.getDouble("ty"); e.tt = ej.getInt("tt"); e.dead = ej.getBoolean("dead");
    e.hp = ej.getInt("hp"); e.inv = ej.getInt("inv"); e.n = ej.getInt("n"); e.face = ej.getInt("face");
    e.g = ej.getBoolean("g"); e.hits = ej.getInt("hits"); e.stomp = ej.getBoolean("stomp");
    e.bites = ej.getInt("bites"); e.walk = ej.getDouble("walk"); e.mv = ej.getBoolean("mv");
    e.fx = ej.getDouble("fx"); e.k = ej.getInt("k");
    S.ents.add(e);
  }

  JSONObject vj = j.getJSONObject("v");
  SceneVars v = S.v;
  v.isOpen = vj.getBoolean("open"); v.gate = vj.getInt("gate"); v.got = vj.getInt("got"); v.spawn = vj.getDouble("spawn");
  v.key = vj.getBoolean("key"); v.lit = vj.getInt("lit"); v.rat = vj.getDouble("rat"); v.doneT = vj.getInt("doneT");
  v.roll = vj.getInt("roll"); v.paper = vj.getDouble("paper"); v.noise = vj.getDouble("noise");
  v.ph = vj.getString("ph"); v.pt = vj.getDouble("pt"); v.mum = vj.getInt("mum");
  v.dist = vj.getDouble("dist"); v.sp = vj.getDouble("sp"); v.thr = vj.getInt("thr"); v.pw = vj.getInt("pw");
  v.sun = vj.getDouble("sun"); v.burn = vj.getBoolean("burn"); v.hasCrowd = vj.getBoolean("hasCrowd");
  v.cheer = vj.getInt("cheer"); v.boo = vj.getInt("boo"); v.wave = vj.getInt("wave");
  v.dt = vj.getDouble("dt"); v.ws = vj.isNull("ws") ? null : vj.getString("ws"); v.wsT = vj.getInt("wsT"); v.wt = vj.getInt("wt");

  JSONArray scArr = vj.getJSONArray("sc");
  for (int i = 0; i < scArr.size(); i++) {
    JSONObject sj = scArr.getJSONObject(i);
    Scrap s = new Scrap(sj.getDouble("x"), sj.getDouble("y"));
    s.got = sj.getInt("got");
    v.sc.add(s);
  }
  JSONArray cArr = vj.getJSONArray("c");
  for (int i = 0; i < cArr.size(); i++) {
    JSONObject cj = cArr.getJSONObject(i);
    v.c.add(new Candle(cj.getDouble("x"), cj.getDouble("y"), cj.getInt("lit")));
  }
  JSONArray dArr = vj.getJSONArray("d");
  for (int i = 0; i < dArr.size(); i++) {
    JSONObject dj = dArr.getJSONObject(i);
    v.d.add(new BedDuck(dj.getDouble("x"), dj.getInt("cd")));
  }
  return S;
}
