// Effects and ambience for De Donkere Nacht 2: dust, sparks, damage numbers, and the small things that move
// in every scene. Drawing only: nothing here changes the game rules.

final int FX_MAX = 150;

class FxParticle {
  boolean on = false;
  double x = 0, y = 0, vx = 0, vy = 0, g = 0, drag = 1.0d;
  int life = 0, max = 1, s = 1;
  double grow = 0, sway = 0, ph = 0;
  String[] cols = null;
  boolean front = true;
}

class FxOpts {
  double g = 0;
  double drag = 1.0d;
  int s = 1;
  double grow = 0;
  double sway = 0;
  boolean back = false;
}

class DmgNum {
  boolean on = false;
  double x = 0, y = 0;
  int t = 0;
  String s = "";
}

class FxCrow {
  String st = "sit";
  double x = 147, y = 198;
  int t = 0;
}

class FxStar {
  int x, y, ph, per;
  FxStar(int x, int y, int ph, int per) {
    this.x = x; this.y = y; this.ph = ph; this.per = per;
  }
}

class FxFly {
  int x, y, ph;
  FxFly(int x, int y, int ph) {
    this.x = x; this.y = y; this.ph = ph;
  }
}

FxParticle[] fxPool = new FxParticle[FX_MAX];
int fxNext = 0;
DmgNum[] fxNums = new DmgNum[6];
int fxNumNext = 0;
int fxSeen = -1;
int fxFreeze = 0;
int[] fxSquashT = { 0, 0 };
boolean[] fxLastBh = { false, false };
int[] fxDipT = { 0, 0, 0, 0, 0, 0, 0, 0 };

GameState fxLastState = null;
String fxScene = "";
int fxLastTick = 0;
FxCrow fxCrow = new FxCrow();
int fxGStep = -1;

ArrayList<FxStar> fxStars = null;
ArrayList<FxFly> fxFlies = null;
CanvasBuf fxHills = null;
CanvasBuf fxSky = null;
CanvasBuf fxSkyFrom = null;

String[] fadeCols(int r, int g, int b, double a) {
  double[] m = { 1.0d, 0.7d, 0.45d, 0.2d };
  String[] out = new String[4];
  for (int i = 0; i < 4; i++) {
    out[i] = "rgba(" + r + "," + g + "," + b + "," + String.format(java.util.Locale.US, "%.2f", a * m[i]) + ")";
  }
  return out;
}

final String[] C_DUST = fadeCols(196, 170, 140, 0.8d);
final String[] C_SAND = fadeCols(232, 206, 156, 0.85d);
final String[] C_SMOKE = fadeCols(160, 160, 172, 0.45d);
final String[] C_STEAM = fadeCols(236, 242, 255, 0.3d);
final String[] C_SPARK = { "#ffffff", "#fff4a0", "#f8d040", "#e89020" };
final String[] C_SWEAT = fadeCols(150, 210, 255, 0.95d);
final String[] C_SPLASH = fadeCols(170, 215, 255, 0.85d);
final String[] C_LEAF = { "#3a9a2a", "#4a9a2a", "#7a8a2a", "#8a6a2a" };
final String[] C_CHIP = fadeCols(150, 144, 130, 0.95d);

void fxSpawn(double x, double y, double vx, double vy, double life, String[] cols, FxOpts o) {
  if (fxPool[0] == null) {
    for (int i = 0; i < FX_MAX; i++) fxPool[i] = new FxParticle();
  }
  FxParticle p = fxPool[fxNext];
  fxNext = (fxNext + 1) % FX_MAX;
  p.on = true;
  p.x = x; p.y = y; p.vx = vx; p.vy = vy;
  p.life = p.max = Math.max(1, (int) Math.round(life));
  p.cols = cols;
  p.g = o != null ? o.g : 0;
  p.drag = o != null ? o.drag : 1.0d;
  p.s = o != null ? o.s : 1;
  p.grow = o != null ? o.grow : 0;
  p.sway = o != null ? o.sway : 0;
  p.ph = Math.random() * 6.0d;
  p.front = o == null || !o.back;
}

void fxParticles(boolean front) {
  if (fxPool[0] == null) return;
  for (FxParticle p : fxPool) {
    if (!p.on || p.front != front) continue;
    if (--p.life <= 0) {
      p.on = false;
      continue;
    }
    p.vx *= p.drag;
    p.vy = p.vy * p.drag + p.g;
    p.x += p.vx + (p.sway != 0 ? Math.sin(p.life / 12.0d + p.ph) * p.sway : 0);
    p.y += p.vy;
    double k = 1.0d - p.life / (double) p.max;
    int s = Math.max(1, (int) Math.round(p.s + p.grow * k));
    R(p.x - (s >> 1), p.y - (s >> 1), s, s, p.cols[Math.min(3, (int) (k * 4.0d))]);
  }
}

void fxClearParticles() {
  if (fxPool[0] == null) return;
  for (FxParticle p : fxPool) p.on = false;
}

boolean fxSandy(String id) {
  return "arena".equals(id) || "giant".equals(id);
}

void fxDust(double x, double y, int n, String id) {
  FxOpts o = new FxOpts();
  o.grow = 2; o.drag = 0.9d;
  for (int i = 0; i < n; i++) {
    fxSpawn(x + (Math.random() - 0.5d) * 10.0d, y - 1, (Math.random() - 0.5d) * 1.4d, -Math.random() * 0.7d, 16 + Math.random() * 12, fxSandy(id) ? C_SAND : C_DUST, o);
  }
}

void fxBurst(double x, double y, int size, String id) {
  int n = 4 + size * 4;
  FxOpts o1 = new FxOpts();
  o1.grow = 3; o1.drag = 0.92d; o1.g = -0.01d;
  for (int i = 0; i < n; i++) {
    fxSpawn(x + (Math.random() - 0.5d) * size * 12.0d, y - 1, (Math.random() - 0.5d) * size * 1.3d, -Math.random() * size * 0.5d, 24 + Math.random() * 16, fxSandy(id) ? C_SAND : C_DUST, o1);
  }
  if (size >= 3) {
    FxOpts o2 = new FxOpts();
    o2.g = 0.22d; o2.s = 2;
    for (int i = 0; i < size * 2; i++) {
      fxSpawn(x + (Math.random() - 0.5d) * 30.0d, y - 2, (Math.random() - 0.5d) * 3.0d, -2.0d - Math.random() * 2.5d, 30, C_CHIP, o2);
    }
  }
}

void fxSparks(double x, double y, int n) {
  FxOpts o = new FxOpts();
  o.drag = 0.82d;
  for (int i = 0; i < n; i++) {
    double a = Math.random() * 6.28d;
    double sp = 1.0d + Math.random() * 1.6d;
    fxSpawn(x, y, Math.cos(a) * sp, Math.sin(a) * sp, 8 + Math.random() * 8, C_SPARK, o);
  }
}

void fxEvents(GameState S) {
  if (fxNums[0] == null) {
    for (int i = 0; i < fxNums.length; i++) fxNums[i] = new DmgNum();
  }
  if (fxSeen < 0 || S.evN < fxSeen) fxSeen = S.evN;
  for (Ev e : S.evs) {
    if (e.n <= fxSeen) continue;
    fxSeen = e.n;
    if (e.x == null || e.y == null) continue;
    if ("land".equals(e.s)) {
      fxDust(e.x, e.y, 5, S.scene);
      if (e.v != null && (e.v == 0 || e.v == 1)) fxSquashT[e.v] = 6;
      Box[] plats = SC.get(S.scene).plats;
      for (int i = 0; i < plats.length && i < fxDipT.length; i++) {
        Box pl = plats[i];
        if (e.y == (int) pl.y && e.x > pl.x - 5 && e.x < pl.x + pl.w + 5) fxDipT[i] = 12;
      }
    } else if ("bosshit".equals(e.s)) {
      DmgNum n = fxNums[fxNumNext];
      fxNumNext = (fxNumNext + 1) % fxNums.length;
      n.on = true;
      n.x = e.x;
      n.y = e.y;
      n.t = 0;
      n.s = "-" + (e.v != null && e.v != 0 ? e.v : 1);
      fxSparks(e.x, e.y + 8, 10);
      fxFreeze = 3;
    } else if ("thud".equals(e.s)) {
      fxBurst(e.x, e.y, e.v != null && e.v != 0 ? e.v : 1, S.scene);
    }
  }
}

boolean fxHold() {
  if (fxFreeze > 0) {
    fxFreeze--;
    return true;
  }
  return false;
}

boolean fxSquash(int id) {
  return id >= 0 && id < fxSquashT.length && fxSquashT[id] > 0;
}

int fxDip(int i) {
  if (i < 0 || i >= fxDipT.length) return 0;
  return fxDipT[i] > 6 ? 2 : fxDipT[i] > 0 ? 1 : 0;
}

void fxEnter(GameState S) {
  if (S == fxLastState && S.scene.equals(fxScene) && S.tick >= fxLastTick) {
    fxLastTick = S.tick;
    return;
  }
  fxLastState = S;
  fxScene = S.scene;
  fxLastTick = S.tick;
  fxGStep = -1;
  fxFreeze = 0;
  fxCrow = new FxCrow();
  fxClearParticles();
  if (fxNums[0] != null) {
    for (DmgNum n : fxNums) n.on = false;
  }
  for (int i = 0; i < fxDipT.length; i++) fxDipT[i] = 0;
}

void fxInit() {
  for (int i = 0; i < FX_MAX; i++) fxPool[i] = new FxParticle();
  for (int i = 0; i < fxNums.length; i++) fxNums[i] = new DmgNum();
  for (int oi = 0; oi < 2; oi++) {
    final boolean up = oi == 0;
    make("owl" + oi, 14, 10, 7, 6, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-3, -3, 6, 6, "#6a4a2a"); P.rect(-2, -5, 4, 2, "#6a4a2a");
        P.rect(-2, -4, 1, 1, "#f8d040"); P.rect(1, -4, 1, 1, "#f8d040"); P.rect(0, -3, 1, 1, "#c89020");
        if (up) { P.rect(-7, -5, 4, 2, "#5a3a1a"); P.rect(3, -5, 4, 2, "#5a3a1a"); }
        else { P.rect(-7, 0, 4, 2, "#5a3a1a"); P.rect(3, 0, 4, 2, "#5a3a1a"); }
      }
    });
  }
  long seed = 11L;
  fxStars = new ArrayList<FxStar>();
  for (int i = 0; i < 18; i++) {
    seed = (seed * 16807L) % 2147483647L; int x = 60 + (int) Math.floor((seed / 2147483647.0d) * 410);
    seed = (seed * 16807L) % 2147483647L; int y = 8 + (int) Math.floor((seed / 2147483647.0d) * 130);
    seed = (seed * 16807L) % 2147483647L; int ph = (int) Math.floor((seed / 2147483647.0d) * 200);
    seed = (seed * 16807L) % 2147483647L; int per = 90 + (int) Math.floor((seed / 2147483647.0d) * 120);
    fxStars.add(new FxStar(x, y, ph, per));
  }
  fxFlies = new ArrayList<FxFly>();
  for (int i = 0; i < 9; i++) {
    seed = (seed * 16807L) % 2147483647L; int x = 20 + (int) Math.floor((seed / 2147483647.0d) * 440);
    seed = (seed * 16807L) % 2147483647L; int y = 110 + (int) Math.floor((seed / 2147483647.0d) * 85);
    seed = (seed * 16807L) % 2147483647L; int ph = (int) Math.floor((seed / 2147483647.0d) * 150);
    fxFlies.add(new FxFly(x, y, ph));
  }
  fxHills = new CanvasBuf(640, 60);
  for (int i = 0; i < 6; i++) {
    seed = (seed * 16807L) % 2147483647L; int dx = (int) Math.floor((seed / 2147483647.0d) * 30);
    seed = (seed * 16807L) % 2147483647L; int rad = 40 + (int) Math.floor((seed / 2147483647.0d) * 25);
    disc(fxHills, 50 + i * 110 + dx, 60 + 20, rad, i % 2 != 0 ? "#141a34" : "#18203c");
  }
}

void fxArenaSky(double sun) {
  CanvasBuf bgCv = BG.get("arena");
  if (bgCv == null) return;
  if (fxSkyFrom != bgCv) {
    fxSkyFrom = bgCv;
    int w = bgCv.w, h = 130;
    fxSky = new CanvasBuf(w, h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        int c = bgCv.px[y * w + x];
        int r = (c >>> 16) & 255, g = (c >>> 8) & 255, b = c & 255;
        if (b > r + 6 && r + g + b < 300) {
          double k = y / (double) h;
          int gr = (int) Math.round(150 + 70 * k);
          int bl = (int) Math.round(100 + 40 * k);
          fxSky.px[y * w + x] = (255 << 24) | (248 << 16) | (gr << 8) | bl;
        }
      }
    }
  }
  if (sun <= 0) return;
  drawImageBuf(frameBuf, fxSky, ctxTx, ctxTy, false, ctxAlpha * Math.min(1.0d, sun) * 0.5d, 1);
}

void fxDrawStars(int t) {
  if (fxStars == null) return;
  for (FxStar s : fxStars) {
    boolean on = (t + s.ph) % s.per < s.per * 0.55d;
    R(s.x, s.y, 1, 1, on ? "#ffffff" : "#6a70a0");
    if (on && (t + s.ph) % s.per < 12) {
      R(s.x - 1, s.y, 3, 1, "rgba(255,255,255,0.5)");
      R(s.x, s.y - 1, 1, 3, "rgba(255,255,255,0.5)");
    }
  }
}

void fxGraveHand(int t, int x, int base) {
  int c = t % 760;
  if (c >= 200) return;
  double up = c < 30 ? c / 30.0d : c > 170 ? (200 - c) / 30.0d : 1.0d;
  int h = (int) Math.round(up * 7.0d);
  if (h <= 0) return;
  R(x, base - h, 2, h, "#6a8a5a");
  if (h >= 6) {
    int w = (c / 14) % 2;
    R(x - 1, base - h - 3, 4, 3, "#7a9a6a");
    R(x - 1 + w, base - h - 5, 1, 2, "#7a9a6a");
    R(x + 1 + w, base - h - 6, 1, 3, "#7a9a6a");
    R(x + 3, base - h - 3 - w, 1, 2, "#7a9a6a");
  }
}

void fxSitCrow(double x, double y, boolean flip) {
  blit("crow1", x, y, flip);
}

void fxMist(int t) {
  for (int i = 0; i < 6; i++) {
    int y = 190 + i * 4;
    double sp = 0.15d + i * 0.05d;
    int w = 70 + i * 12;
    for (int j = 0; j < 3; j++) {
      R(((t * sp + i * 131 + j * 240) % 720.0d) - 120.0d, y, w, 3, "rgba(190,200,240,0.09)");
    }
  }
}

void fxClipR(double x, double y, double w, double h, double x0, double y0, double x1, double y1, String col) {
  double a = Math.max(x, x0), b = Math.max(y, y0), c = Math.min(x + w, x1), d = Math.min(y + h, y1);
  if (c > a && d > b) R(a, b, c - a, d - b, col);
}

Player fxNearestZombie(GameState S, double x) {
  Player best = null;
  for (Player p : S.players) {
    if (p.down == 0 && (best == null || Math.abs(p.x - x) < Math.abs(best.x - x))) best = p;
  }
  return best;
}

void fxBack(GameState S, int t) {
  fxEnter(S);
  String id = S.scene;
  if ("field".equals(id)) {
    fxDrawStars(t);
    fxGraveHand(t, 300, 172);
    if ("sit".equals(fxCrow.st)) {
      fxSitCrow(fxCrow.x, fxCrow.y, true);
      for (Player p : S.players) {
        if (Math.abs(p.x - fxCrow.x) < 46) {
          fxCrow.st = "fly";
          fxCrow.t = 0;
          break;
        }
      }
    } else if (fxCrow.x < SIM_W + 20) {
      fxCrow.t++;
      fxCrow.x += 2.4d;
      fxCrow.y -= 1.5d - Math.min(1.0d, fxCrow.t / 60.0d);
      blit("crow" + ((fxCrow.t / 4) % 2), fxCrow.x, fxCrow.y, false);
    }
  } else if ("forest".equals(id)) {
    if (t % 260 < 8) {
      R(198, 132, 2, 1, "#4a3a10");
      R(203, 132, 2, 1, "#4a3a10");
    } else {
      R(198, 131, 2, 2, "#f8d040");
      R(203, 131, 2, 2, "#f8d040");
      R(199, 132, 1, 1, "#1a1206");
      R(204, 132, 1, 1, "#1a1206");
    }
    if (fxFlies != null) {
      for (FxFly f : fxFlies) {
        if ((t + f.ph) % 150 > 90) continue;
        int x = (int) Math.round(f.x + Math.sin(t / 97.0d + f.ph) * 26.0d);
        int y = (int) Math.round(f.y + Math.sin(t / 71.0d + f.ph * 2.0d) * 18.0d);
        R(x - 1, y - 1, 3, 3, "rgba(220,255,120,0.18)");
        R(x, y, 1, 1, "#e8ff80");
      }
    }
    if (Math.random() < 0.03d) {
      FxOpts o = new FxOpts();
      o.sway = 0.5d; o.back = true; o.s = 2;
      fxSpawn(Math.random() * SIM_W, 62 + Math.random() * 40, 0.15d, 0.3d + Math.random() * 0.2d, 420, C_LEAF, o);
    }
  } else if ("house".equals(id)) {
    R(450, 68, 13, 3, "#4a2418");
    R(452, 71, 9, 15, "#7a3a2a");
    R(452, 75, 9, 1, "#5a2a1a");
    R(452, 80, 9, 1, "#5a2a1a");
    R(456, 71, 1, 4, "#5a2a1a");
    if (t % 10 == 0) {
      FxOpts o = new FxOpts();
      o.grow = 5; o.back = true; o.s = 2;
      fxSpawn(456, 66, -0.12d - Math.random() * 0.1d, -0.32d - Math.random() * 0.1d, 140, C_SMOKE, o);
    }
    String k = "#121216";
    R(405, 79, 7, 6, k);
    R(402, 75, 5, 5, k);
    R(402, 74, 1, 1, k);
    R(406, 74, 1, 1, k);
    if (t % 300 > 8) {
      R(403, 77, 1, 1, "#f8e040");
      R(405, 77, 1, 1, "#f8e040");
    }
    for (int i = 0; i < 6; i++) {
      R(412 + i, 84 - i - Math.round(Math.sin(t / 25.0d + i * 0.7d) * i * 0.5d), 1, 1, k);
    }
    int c = t % 620;
    if (c < 90) {
      double sx = 386 + c * 0.45d;
      String col = "rgba(60,32,12,0.7)";
      fxClipR(sx - 3, 163, 6, 6, 397, 160, 414, 183, col);
      fxClipR(sx - 5, 169, 10, 14, 397, 160, 414, 183, col);
    }
  } else if ("hall".equals(id)) {
    R(105, 66, 14, 41, "#5a3018");
    R(107, 68, 10, 10, "#e8dcc0");
    R(111, 72, 2, 2, "#2a1a0a");
    R(112, 69, 1, 4, "#2a1a0a");
    R(112, 73, 3, 1, "#2a1a0a");
    double sec = (t / 60.0d) * Math.PI / 30.0d;
    R(112 + Math.round(Math.sin(sec) * 4.0d), 73 - Math.round(Math.cos(sec) * 4.0d), 1, 1, "#a02020");
    R(107, 80, 10, 24, "#1a0e06");
    double sw = Math.sin(t / 28.0d) * 3.0d;
    for (int y = 81; y < 97; y++) R(112 + Math.round(sw * (y - 81) / 16.0d), y, 1, 1, "#c8a040");
    R(111 + Math.round(sw), 97, 3, 3, "#e8c060");
    int sy = 40 + (int) Math.round((Math.sin(t / 90.0d) + 1.0d) * 22.0d);
    R(190, 0, 1, sy, "rgba(230,230,240,0.4)");
    R(188, sy, 5, 4, "#141414");
    R(186, sy + 1, 2, 1, "#141414");
    R(193, sy + 1, 2, 1, "#141414");
    R(186, sy + 3, 2, 1, "#141414");
    R(193, sy + 3, 2, 1, "#141414");
    R(189, sy + 1, 1, 1, "#e83030");
    R(191, sy + 1, 1, 1, "#e83030");
    R(318, 92, 22, 28, "#c89a30");
    R(320, 94, 18, 24, "#2a3a2a");
    R(323, 97, 12, 4, "#3a2410");
    R(324, 99, 10, 12, "#e8c8a0");
    R(323, 97, 2, 10, "#3a2410");
    R(325, 103, 3, 2, "#ffffff");
    R(330, 103, 3, 2, "#ffffff");
    Player z = fxNearestZombie(S, 329);
    int dx = z != null ? Math.max(0, Math.min(2, (int) Math.round((z.x - 329) / 60.0d) + 1)) : 1;
    int dy = (z != null && z.y > 120) ? 1 : 0;
    R(325 + dx, 103 + dy, 1, 1, "#111");
    R(330 + dx, 103 + dy, 1, 1, "#111");
    R(327, 108, 4, 1, "#8a4a3a");
    R(322, 111, 14, 3, "#ebe8da");
    R(321, 114, 16, 4, "#1a1a22");
  } else if ("bath".equals(id)) {
    int c = t % 120;
    if (c < 70) R(70, 149, 1, c > 40 ? 2 : 1, "rgba(170,215,255,0.9)");
    else if (c < 78) R(70, 149 + (c - 70), 1, 2, "rgba(170,215,255,0.9)");
    else if (c == 78) {
      FxOpts o = new FxOpts();
      o.g = 0.15d; o.back = true;
      for (int i = 0; i < 3; i++) fxSpawn(70, 157, (Math.random() - 0.5d) * 1.2d, -0.6d - Math.random() * 0.6d, 12, C_SPLASH, o);
    }
    if (t % 9 == 0) {
      FxOpts o = new FxOpts();
      o.grow = 5; o.back = true; o.s = 2;
      fxSpawn(142 + Math.random() * 80, 196 - Math.random() * 24, (Math.random() - 0.5d) * 0.2d, -0.25d - Math.random() * 0.15d, 170, C_STEAM, o);
    }
    blit("duck", 206, 205 + Math.round(Math.sin(t / 25.0d)), false, 0.5d);
  } else if ("bed".equals(id)) {
    for (int y = 112; y < SIM_G; y += 2) R(196 + Math.round((y - 112) * 0.35d), y, 88, 2, "rgba(150,170,255,0.08)");
    for (int i = 0; i < 14; i++) {
      double y = 112 + ((i * 59 + t * (0.08d + (i % 3) * 0.03d)) % 100.0d);
      double x = 196 + ((i * 37 + t * 0.12d) % 88.0d) + (y - 112) * 0.35d;
      R(Math.round(x), Math.round(y), 1, 1, "rgba(110,120,180,0.6)");
    }
    int[][] curtains = { { 188, 1 }, { 282, -1 } };
    for (int[] cur : curtains) {
      int x0 = cur[0], side = cur[1];
      R(x0 - 2, 72, 16, 2, "#4a2a18");
      for (int r = 0; r < 34; r++) {
        int sway = (int) Math.round(Math.sin(t / 50.0d + r / 9.0d) * (r / 12.0d));
        int w = 10 - (r / 9);
        R(side > 0 ? x0 + sway : x0 + 10 - w + sway, 74 + r, w, 1, r % 6 < 3 ? "#7a4a9a" : "#6a3a8a");
      }
    }
  } else if ("chase".equals(id)) {
    int off = (int) Math.round(-((S.v.dist * 0.12d) % 640.0d));
    if (fxHills != null) {
      drawImageBuf(frameBuf, fxHills, off + ctxTx, SIM_G - 82 + ctxTy, false, ctxAlpha, 1);
      drawImageBuf(frameBuf, fxHills, off + 640 + ctxTx, SIM_G - 82 + ctxTy, false, ctxAlpha, 1);
    }
    int c = t % 1100;
    if (c < 700) {
      blit("owl" + ((t / 8) % 2), SIM_W + 20 - c * 0.75d, 74 + Math.round(Math.sin(c / 20.0d) * 4.0d));
    }
  } else if ("arena".equals(id) || "giant".equals(id)) {
    fxArenaSky(S.v.sun);
    Object[][] flags = { { 70, 87, "#c03030" }, { 140, 100, "#3060c0" } };
    for (Object[] fl : flags) {
      int x = (Integer) fl[0], y = (Integer) fl[1];
      String col = (String) fl[2];
      R(x, y - 16, 1, 16, "#3a2a1a");
      for (int r = 0; r < 6; r++) {
        R(x + 1, y - 16 + r, 8 + Math.round(Math.sin(t / 9.0d - r * 0.7d) * 1.5d), 1, r % 2 != 0 ? col : "#e8e0c8");
      }
    }
    for (int x : new int[] { 40, 150, 330, 410 }) {
      R(x - 1, 184, 3, 8, "#3a2a1a");
      R(x - 3, 181, 7, 3, "#5a4a3a");
      int fh = 5 + (((t / 5) + x) % 3);
      R(x - 6, 174 - fh, 13, 13, "rgba(255,170,60,0.08)");
      R(x - 2, 181 - fh, 5, fh, "#f06018");
      R(x - 1, 182 - fh, 3, fh - 2, "#f8b020");
      R(x, 183 - fh, 1, fh - 3, "#fff4b0");
    }
  }
  fxParticles(false);
}

void fxFront(GameState S, int t, HashMap<String, String> tx) {
  for (int i = 0; i < 2; i++) if (fxSquashT[i] > 0) fxSquashT[i]--;
  for (int i = 0; i < fxDipT.length; i++) if (fxDipT[i] > 0) fxDipT[i]--;
  for (Player p : S.players) {
    if (p.bh && !fxLastBh[p.id] && p.bite > 0) {
      int w = p.chick > 0 ? 34 : 17;
      fxSparks(p.x + p.face * w * 0.75d, p.y - 15, 6);
    }
    fxLastBh[p.id] = p.bh;
  }
  if ("giant".equals(S.scene)) {
    Ent g = findEnt(S, "giant");
    if (g != null && "walk".equals(g.st) && g.mv) {
      int k = ((int) Math.floor(g.walk / 6.0d)) % 4;
      if (k != fxGStep && (k == 0 || k == 2)) fxDust(g.x + g.face * (k == 0 ? 9 : -6), SIM_G, 4, "giant");
      fxGStep = k;
    }
  }
  if ("chase".equals(S.scene)) {
    if (t % 7 == 0) {
      FxOpts o = new FxOpts();
      o.grow = 2; o.drag = 0.97d;
      for (Player p : S.players) {
        if (p.down == 0) fxSpawn(p.x - 4, SIM_G - 1, -2.0d - Math.random() * 0.5d, -Math.random() * 0.4d, 20, C_DUST, o);
      }
      fxSpawn(428, SIM_G - 1, -2.0d - Math.random() * 0.5d, -Math.random() * 0.4d, 20, C_DUST, o);
    }
    if (t % 18 == 0) {
      FxOpts o = new FxOpts();
      o.g = 0.12d;
      fxSpawn(429, SIM_G - 27, -1.2d - Math.random(), -0.8d - Math.random() * 0.6d, 26, C_SWEAT, o);
    }
  }
  if ("field".equals(S.scene)) fxMist(t);
  fxParticles(true);
  for (DmgNum n : fxNums) {
    if (n == null || !n.on) continue;
    if (++n.t > 50) {
      n.on = false;
      continue;
    }
    ctxAlpha = Math.max(0.0d, 1.0d - n.t / 50.0d);
    T(n.s, n.x, Math.round(n.y - n.t * 0.5d), "#fff4a0", "ps", 1);
    ctxAlpha = 1.0d;
  }
}

void fxTitle(int t) {
  fxDrawStars(t);
  fxGraveHand(t, 300, 172);
  fxSitCrow(428, 192, (t / 240) % 2 == 0);
  fxMist(t);
}
