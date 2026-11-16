// Drawing for De Donkere Nacht 2: pixel sprites, backgrounds, scenes, cutscenes and HUD.
// Everything is drawn into a 480x270 integer pixel buffer (and copied to a 480x270 PGraphics) with whole pixels only.

import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;

final int[] OUT_RGB = { 12, 10, 22 };

class CanvasBuf {
  int w, h;
  int[] px;

  CanvasBuf(int w, int h) {
    this.w = Math.max(1, w);
    this.h = Math.max(1, h);
    this.px = new int[this.w * this.h];
  }

  void clear() {
    java.util.Arrays.fill(px, 0);
  }
}

class Sprite {
  CanvasBuf cv;
  int ox, oy;

  Sprite(CanvasBuf cv, int ox, int oy) {
    this.cv = cv;
    this.ox = ox;
    this.oy = oy;
  }
}

interface SpriteBuilder {
  void build(Painter P);
}

class Painter {
  CanvasBuf cv;
  int ox, oy;

  Painter(CanvasBuf cv, int ox, int oy) {
    this.cv = cv;
    this.ox = ox;
    this.oy = oy;
  }

  void rect(double x, double y, double pw, double ph, String col) {
    bufRect(cv, (int) Math.round(x + ox), (int) Math.round(y + oy), (int) Math.round(pw), (int) Math.round(ph), parseCol(col), 1.0d, 0, 0, cv.w, cv.h);
  }

  void disc(double cx, double cy, int r, String col) {
    bufDisc(cv, cx + ox, cy + oy, r, parseCol(col), 1.0d, 0, 0, cv.w, cv.h);
  }
}

class ZPal {
  String body, dark, skin, sdark, hat, band;
  ZPal(String body, String dark, String gleam, String sdark, String hat, String band) {
    this.body = body; this.dark = dark; this.skin = gleam; this.sdark = sdark; this.hat = hat; this.band = band;
  }
}

class ZOpts {
  ZPal pal = null;
  boolean squat = false;
  int bob = 0;
  int hb = 0;
  int[][] legs = null;
  boolean nohead = false;
  int mouth = 0;
  boolean blink = false;
  boolean armUp = false;
  int arm = 8;
  int as = 0;
  int arm2 = 0;

  ZOpts copyWithPal(ZPal p) {
    ZOpts o = new ZOpts();
    o.pal = p; o.squat = squat; o.bob = bob; o.hb = hb; o.legs = legs;
    o.nohead = nohead; o.mouth = mouth; o.blink = blink; o.armUp = armUp;
    o.arm = arm; o.as = as; o.arm2 = arm2;
    return o;
  }
}

class TOpts {
  String skin, sdark;
  boolean pl = false;
  int bob = 0;
  int[][] legs = null;
  boolean roll = false;
  String arms = "";
  boolean look = false;
  int mouth = 0;
  int ih = 0;
  int swing = 0;

  TOpts copyWith(String sk, String sd, boolean p) {
    TOpts o = new TOpts();
    o.skin = sk; o.sdark = sd; o.pl = p; o.bob = bob; o.legs = legs;
    o.roll = roll; o.arms = arms; o.look = look; o.mouth = mouth; o.ih = ih; o.swing = swing;
    return o;
  }
}

class GOpts {
  int lean = 0, bob = 0, dip = 0, hx = 0, hy = 0, mouth = 0;
  int[] lf = { 0, 0 };
  int[] lb = { 0, 0 };
  String arm = "";
}

class CrowdSeat {
  int x, y, s, ph;
  boolean f;
  CrowdSeat(int x, int y, int s, int ph, boolean f) {
    this.x = x; this.y = y; this.s = s; this.ph = ph; this.f = f;
  }
}

CanvasBuf frameBuf = new CanvasBuf(SIM_W, SIM_H);
PGraphics framePg = null;
double ctxAlpha = 1.0d;
int ctxTx = 0, ctxTy = 0;
int clipX0 = 0, clipY0 = 0, clipX1 = SIM_W, clipY1 = SIM_H;

double[] alphaStack = new double[8];
int[] txStack = new int[8];
int[] tyStack = new int[8];
int[] cx0Stack = new int[8];
int[] cy0Stack = new int[8];
int[] cx1Stack = new int[8];
int[] cy1Stack = new int[8];
int ctxDepth = 0;

HashMap<String, Integer> colCache = new HashMap<String, Integer>();
HashMap<String, Sprite> SPR = new HashMap<String, Sprite>();
HashMap<String, Sprite> WHITE = new HashMap<String, Sprite>();
HashMap<String, CanvasBuf> BG = new HashMap<String, CanvasBuf>();
HashMap<String, CanvasBuf> builtBg = new HashMap<String, CanvasBuf>();
HashMap<String, CanvasBuf> NW = null;
HashMap<String, CanvasBuf> NWH = null;
CanvasBuf darkCv = null;
ArrayList<CrowdSeat> CROWD = null;

Font awtPsSmall = null;
Font awtPsBig = null;
Font awtVt = null;
Graphics2D measureG2 = null;
HashMap<String, CanvasBuf> tcache = new HashMap<String, CanvasBuf>();
boolean drawReady = false;

final ZPal[] ZC = {
  new ZPal("#29c44c", "#1b8a36", "#63d97d", "#3fae5a", "#17171f", "#c0302a"),
  new ZPal("#64c44c", "#479438", "#a2dc7c", "#7ab85c", "#d8c070", "#9a7a2c")
};

final ZPal[] ZG = {
  new ZPal("#e8b830", "#b8861c", "#f8dc78", "#d8b048", "#7a5810", "#fff0a0"),
  new ZPal("#f0c840", "#c09020", "#fce488", "#dcb850", "#c89a30", "#8a6414")
};

final String TH_SUIT = "#f07a18", TH_DARK = "#b85a10", TH_SKIN = "#8a5a3a", TH_SDARK = "#6a4028";
final String TH1_SKIN = "#7e8a3a", TH1_SDARK = "#5e6a28";
final String TH2_SKIN = "#8cc43c", TH2_SDARK = "#6a9a2c";

final String GC_SKIN = "#8cc43c", GC_SD = "#6a9a2c", GC_DEEP = "#4a7420", GC_LT = "#b4e06a";
final String GC_SUIT = "#f07a18", GC_SU2 = "#b85a10", GC_SU3 = "#8a3e08";
final String GC_TOOTH = "#f4f0d8", GC_EYE = "#f4f0a0", GC_MOUTH = "#3a0a0a", GC_TONGUE = "#e8507c";
final String GC_PL = "#f4efe0", GC_PL2 = "#d4c4a8", GC_HAIR = "#2a2a18", GC_NAIL = "#e8e0a0";

void ctxSave() {
  alphaStack[ctxDepth] = ctxAlpha;
  txStack[ctxDepth] = ctxTx;
  tyStack[ctxDepth] = ctxTy;
  cx0Stack[ctxDepth] = clipX0;
  cy0Stack[ctxDepth] = clipY0;
  cx1Stack[ctxDepth] = clipX1;
  cy1Stack[ctxDepth] = clipY1;
  ctxDepth++;
}

void ctxRestore() {
  if (ctxDepth <= 0) return;
  ctxDepth--;
  ctxAlpha = alphaStack[ctxDepth];
  ctxTx = txStack[ctxDepth];
  ctxTy = tyStack[ctxDepth];
  clipX0 = cx0Stack[ctxDepth];
  clipY0 = cy0Stack[ctxDepth];
  clipX1 = cx1Stack[ctxDepth];
  clipY1 = cy1Stack[ctxDepth];
}

void ctxReset() {
  ctxDepth = 0;
  ctxAlpha = 1.0d;
  ctxTx = 0;
  ctxTy = 0;
  clipX0 = 0;
  clipY0 = 0;
  clipX1 = SIM_W;
  clipY1 = SIM_H;
}

int parseCol(String col) {
  if (col == null || col.isEmpty()) return 0xFFFFFFFF;
  Integer cached = colCache.get(col);
  if (cached != null) return cached;
  int res = 0xFFFFFFFF;
  if (col.charAt(0) == '#') {
    int n = Integer.parseInt(col.substring(1), 16);
    if (col.length() == 4) {
      int r = ((n >> 8) & 15) * 17;
      int g = ((n >> 4) & 15) * 17;
      int b = (n & 15) * 17;
      res = (255 << 24) | (r << 16) | (g << 8) | b;
    } else {
      res = (255 << 24) | (n & 0xFFFFFF);
    }
  } else if (col.startsWith("rgba(")) {
    String inner = col.substring(5, col.length() - 1);
    String[] parts = inner.split(",");
    int r = Integer.parseInt(parts[0].trim());
    int g = Integer.parseInt(parts[1].trim());
    int b = Integer.parseInt(parts[2].trim());
    double a = Double.parseDouble(parts[3].trim());
    int ai = Math.max(0, Math.min(255, (int) Math.round(a * 255.0d)));
    res = (ai << 24) | ((r & 255) << 16) | ((g & 255) << 8) | (b & 255);
  }
  colCache.put(col, res);
  return res;
}

int blendPixel(int dst, int src, int sa) {
  if (sa >= 255) return (0xFF << 24) | (src & 0xFFFFFF);
  if (sa <= 0) return dst;
  int da = (dst >>> 24) & 255;
  int sr = (src >>> 16) & 255, sg = (src >>> 8) & 255, sb = src & 255;
  if (da == 0) {
    return (sa << 24) | (sr << 16) | (sg << 8) | sb;
  }
  int dr = (dst >>> 16) & 255, dg = (dst >>> 8) & 255, db = dst & 255;
  int inv = 255 - sa;
  int outA = sa + (da * inv + 127) / 255;
  int r = (sr * sa + dr * inv + 127) / 255;
  int g = (sg * sa + dg * inv + 127) / 255;
  int b = (sb * sa + db * inv + 127) / 255;
  return (outA << 24) | (r << 16) | (g << 8) | b;
}

void bufRect(CanvasBuf buf, int x, int y, int w, int h, int argb, double extraAlpha, int cx0, int cy0, int cx1, int cy1) {
  int sa = (argb >>> 24) & 255;
  if (extraAlpha < 1.0d) sa = (int) Math.round(sa * Math.max(0.0d, Math.min(1.0d, extraAlpha)));
  if (sa <= 0 || w <= 0 || h <= 0) return;
  int x0 = Math.max(cx0, Math.max(0, x));
  int y0 = Math.max(cy0, Math.max(0, y));
  int x1 = Math.min(cx1, Math.min(buf.w, x + w));
  int y1 = Math.min(cy1, Math.min(buf.h, y + h));
  if (x1 <= x0 || y1 <= y0) return;
  int solid = (0xFF << 24) | (argb & 0xFFFFFF);
  int[] px = buf.px;
  int bw = buf.w;
  if (sa >= 255) {
    for (int py = y0; py < y1; py++) {
      int row = py * bw;
      java.util.Arrays.fill(px, row + x0, row + x1, solid);
    }
  } else {
    for (int py = y0; py < y1; py++) {
      int row = py * bw;
      for (int pxIdx = row + x0; pxIdx < row + x1; pxIdx++) {
        px[pxIdx] = blendPixel(px[pxIdx], argb, sa);
      }
    }
  }
}

void bufDisc(CanvasBuf buf, double cx, double cy, int r, int argb, double extraAlpha, int cx0, int cy0, int cx1, int cy1) {
  for (int dy = -r; dy <= r; dy++) {
    int dx = (int) Math.floor(Math.sqrt(r * r - dy * dy) + 0.5d);
    bufRect(buf, (int) Math.round(cx - dx), (int) Math.round(cy + dy), dx * 2 + 1, 1, argb, extraAlpha, cx0, cy0, cx1, cy1);
  }
}

void drawImageBuf(CanvasBuf dst, CanvasBuf src, int dx, int dy, boolean flip, double extraAlpha, int scale) {
  if (src == null) return;
  int sc = Math.max(1, scale);
  int sw = src.w, sh = src.h;
  int dw = sw * sc, dh = sh * sc;
  int x0 = Math.max(clipX0, Math.max(0, dx));
  int y0 = Math.max(clipY0, Math.max(0, dy));
  int x1 = Math.min(clipX1, Math.min(dst.w, dx + dw));
  int y1 = Math.min(clipY1, Math.min(dst.h, dy + dh));
  if (x1 <= x0 || y1 <= y0) return;
  int[] spx = src.px;
  int[] dpx = dst.px;
  int dstW = dst.w;
  for (int py = y0; py < y1; py++) {
    int sy = (py - dy) / sc;
    int srow = sy * sw;
    int drow = py * dstW;
    for (int px = x0; px < x1; px++) {
      int sx = (px - dx) / sc;
      if (flip) sx = sw - 1 - sx;
      int c = spx[srow + sx];
      int sa = (c >>> 24) & 255;
      if (sa == 0) continue;
      if (extraAlpha < 1.0d) sa = (int) Math.round(sa * Math.max(0.0d, Math.min(1.0d, extraAlpha)));
      if (sa <= 0) continue;
      dpx[drow + px] = blendPixel(dpx[drow + px], c, sa);
    }
  }
}

void R(double x, double y, double w, double h, String col) {
  bufRect(frameBuf, (int) Math.round(x) + ctxTx, (int) Math.round(y) + ctxTy, (int) Math.round(w), (int) Math.round(h), parseCol(col), ctxAlpha, clipX0, clipY0, clipX1, clipY1);
}

void disc(CanvasBuf c2, double cx, double cy, int r, String col) {
  boolean isMain = (c2 == frameBuf);
  bufDisc(c2, cx + (isMain ? ctxTx : 0), cy + (isMain ? ctxTy : 0), r, parseCol(col), isMain ? ctxAlpha : 1.0d,
    isMain ? clipX0 : 0, isMain ? clipY0 : 0, isMain ? clipX1 : c2.w, isMain ? clipY1 : c2.h);
}

// ---------------------------------------------------------------- text
void initFonts() {
  if (awtPsSmall != null) return;
  try {
    File psFile = dataFile("PressStart2P-Regular.ttf");
    File vtFile = dataFile("VT323-Regular.ttf");
    Font basePs = Font.createFont(Font.TRUETYPE_FONT, psFile);
    Font baseVt = Font.createFont(Font.TRUETYPE_FONT, vtFile);
    awtPsSmall = basePs.deriveFont(Font.PLAIN, 8f);
    awtPsBig = basePs.deriveFont(Font.PLAIN, 64f);
    awtVt = baseVt.deriveFont(Font.PLAIN, 20f);
  } catch (Exception e) {
    awtPsSmall = new Font("Monospaced", Font.BOLD, 8);
    awtPsBig = new Font("Monospaced", Font.BOLD, 64);
    awtVt = new Font("Monospaced", Font.PLAIN, 16);
  }
  BufferedImage tmp = new BufferedImage(4, 4, BufferedImage.TYPE_INT_ARGB);
  measureG2 = tmp.createGraphics();
}

int measure(String str, String font) {
  if (str == null || str.isEmpty()) return 0;
  initFonts();
  Font f = "ps".equals(font) ? awtPsSmall : awtVt;
  return (int) Math.ceil(measureG2.getFontMetrics(f).stringWidth(str));
}

CanvasBuf textImg(String str, String font, String col) {
  String key = font + col + str;
  CanvasBuf cv = tcache.get(key);
  if (cv != null) return cv;
  if (tcache.size() > 900) tcache.clear();
  initFonts();
  boolean isPs = "ps".equals(font);
  int fh = isPs ? 10 : 20;
  int fbase = isPs ? 9 : 15;
  int w = Math.max(1, measure(str, font) + 2);
  cv = new CanvasBuf(w, fh);
  int rgb = parseCol(col) & 0xFFFFFF;
  int solid = (255 << 24) | rgb;

  int z = isPs ? 8 : 1;
  BufferedImage bc = new BufferedImage(w * z, fh * z, BufferedImage.TYPE_INT_ARGB);
  Graphics2D b = bc.createGraphics();
  b.setFont(isPs ? awtPsBig : awtVt);
  b.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_OFF);
  b.setColor(java.awt.Color.WHITE);
  b.drawString(str, z, fbase * z);
  b.dispose();

  int half = z >> 1;
  int bw = bc.getWidth();
  int[] src = bc.getRGB(0, 0, bw, bc.getHeight(), null, 0, bw);
  for (int y = 0; y < fh; y++) {
    for (int x = 0; x < w; x++) {
      int a = (src[(y * z + half) * bw + (x * z + half)] >>> 24) & 255;
      if (a >= 128) {
        cv.px[y * w + x] = solid;
      }
    }
  }
  tcache.put(key, cv);
  return cv;
}

int T(String str, double x, double y, String col, String font, int align, int scale, boolean shadow) {
  if (str == null || str.isEmpty()) return 0;
  String f = (font != null && !font.isEmpty()) ? font : "vt";
  int sc = scale > 0 ? scale : 1;
  String c = (col != null && !col.isEmpty()) ? col : "#ffffff";
  CanvasBuf img = textImg(str, f, c);
  int w = img.w * sc;
  int dx = (int) Math.round(align == 1 ? x - w / 2.0d : align == 2 ? x - w : x);
  int dy = (int) Math.round(y);
  if (shadow) {
    CanvasBuf sh = textImg(str, f, "#0c0a16");
    drawImageBuf(frameBuf, sh, dx + sc + ctxTx, dy + sc + ctxTy, false, ctxAlpha, sc);
  }
  drawImageBuf(frameBuf, img, dx + ctxTx, dy + ctxTy, false, ctxAlpha, sc);
  return w;
}

int T(String str, double x, double y, String col, String font, int align, int scale) {
  return T(str, x, y, col, font, align, scale, true);
}

int T(String str, double x, double y, String col, String font, int align) {
  return T(str, x, y, col, font, align, 1, true);
}

int T(String str, double x, double y, String col, String font) {
  return T(str, x, y, col, font, 0, 1, true);
}

String[] wrap(String str, String font, int maxW) {
  if (str == null || str.isEmpty()) return new String[0];
  String[] words = str.split(" ");
  ArrayList<String> lines = new ArrayList<String>();
  String line = "";
  for (String w : words) {
    String t = !line.isEmpty() ? line + " " + w : w;
    if (measure(t, font) > maxW && !line.isEmpty()) {
      lines.add(line);
      line = w;
    } else {
      line = t;
    }
  }
  if (!line.isEmpty()) lines.add(line);
  return lines.toArray(new String[0]);
}

// ---------------------------------------------------------------- sprites
void make(String key, int w, int h, int ox, int oy, SpriteBuilder fn, boolean outline) {
  CanvasBuf cv = new CanvasBuf(w + 2, h + 2);
  Painter P = new Painter(cv, ox + 1, oy + 1);
  fn.build(P);
  if (outline) {
    int cw = cv.w, ch = cv.h;
    int[] s = cv.px.clone();
    int outCol = (255 << 24) | (OUT_RGB[0] << 16) | (OUT_RGB[1] << 8) | OUT_RGB[2];
    for (int y = 0; y < ch; y++) {
      for (int x = 0; x < cw; x++) {
        if (((s[y * cw + x] >>> 24) & 255) == 0) {
          boolean adj =
            (x > 0 && ((s[y * cw + (x - 1)] >>> 24) & 255) > 0) ||
            (x + 1 < cw && ((s[y * cw + (x + 1)] >>> 24) & 255) > 0) ||
            (y > 0 && ((s[(y - 1) * cw + x] >>> 24) & 255) > 0) ||
            (y + 1 < ch && ((s[(y + 1) * cw + x] >>> 24) & 255) > 0);
          if (adj) cv.px[y * cw + x] = outCol;
        }
      }
    }
  }
  SPR.put(key, new Sprite(cv, ox + 1, oy + 1));
}

void make(String key, int w, int h, int ox, int oy, SpriteBuilder fn) {
  make(key, w, h, ox, oy, fn, true);
}

void blit(String key, double x, double y, boolean flip, double alpha, int scale) {
  Sprite s = SPR.get(key);
  if (s == null) return;
  int ix = (int) Math.round(x) + ctxTx;
  int iy = (int) Math.round(y) + ctxTy;
  int sc = Math.max(1, scale);
  int dx = flip ? ix - (s.cv.w - s.ox) * sc : ix - s.ox * sc;
  int dy = iy - s.oy * sc;
  drawImageBuf(frameBuf, s.cv, dx, dy, flip, ctxAlpha * alpha, sc);
}

void blit(String key, double x, double y, boolean flip, double alpha) {
  blit(key, x, y, flip, alpha, 1);
}

void blit(String key, double x, double y, boolean flip) {
  blit(key, x, y, flip, 1.0d, 1);
}

void blit(String key, double x, double y) {
  blit(key, x, y, false, 1.0d, 1);
}

void blitWhite(String key, double x, double y, boolean flip) {
  Sprite w = WHITE.get(key);
  if (w == null) {
    Sprite s = SPR.get(key);
    if (s == null) return;
    CanvasBuf cv = new CanvasBuf(s.cv.w, s.cv.h);
    for (int i = 0; i < s.cv.px.length; i++) {
      int a = (s.cv.px[i] >>> 24) & 255;
      if (a > 0) cv.px[i] = (a << 24) | 0xFFFFFF;
    }
    w = new Sprite(cv, s.ox, s.oy);
    WHITE.put(key, w);
  }
  SPR.put("_w", w);
  blit("_w", x, y, flip);
}

void blitWhite(String key, double x, double y) {
  blitWhite(key, x, y, false);
}

void zHead(Painter P, int id, ZPal c, int b, int mouth, boolean blink) {
  P.rect(-4, -29 + b, 8, 10, c.skin);
  P.rect(-5, -28 + b, 10, 8, c.skin);
  P.rect(-5, -28 + b, 2, 8, c.sdark);
  P.rect(-4, -29 + b, 2, 1, c.sdark);
  if (blink) P.rect(1, -24 + b, 3, 1, "#1a4a22");
  else {
    P.rect(1, -26 + b, 3, 3, "#f6f6e4");
    P.rect(3, -25 + b, 1, 1, "#111");
  }
  if (mouth == 3) {
    P.rect(0, -23 + b, 6, 4, "#3a0a0a");
    P.rect(1, -23 + b, 1, 1, "#fff");
    P.rect(4, -23 + b, 1, 1, "#fff");
    P.rect(1, -20 + b, 1, 1, "#fff");
    P.rect(4, -20 + b, 1, 1, "#fff");
  } else if (mouth == 4) {
    P.rect(0, -22 + b, 5, 2, "#3a0a0a");
    P.rect(0, -22 + b, 5, 1, "#fff");
  } else if (mouth == 2) {
    P.rect(1, -23 + b, 3, 3, "#3a0a0a");
  } else if (mouth != 0) {
    P.rect(0, -22 + b, 5, 2, "#3a0a0a");
    P.rect(1, -22 + b, 1, 1, "#fff");
    P.rect(3, -22 + b, 1, 1, "#fff");
  } else {
    P.rect(1, -21 + b, 4, 1, "#1a4a22");
  }
  P.rect(-7, -30 + b, 14, 2, c.hat);
  P.rect(-4, -30 + b - (id != 0 ? 3 : 4), 8, id != 0 ? 3 : 4, c.hat);
  P.rect(-4, -31 + b, 8, 1, c.band);
  if (id == 1) P.rect(-6, -36 + b, 2, 5, "#f4f4f4");
}

void zombie(Painter P, int id, ZOpts o) {
  ZPal c = o.pal != null ? o.pal : ZC[id];
  int sq = o.squat ? 2 : 0;
  int b = o.bob + sq;
  int[][] legs = o.legs != null ? o.legs : new int[][] { { -4, 0 }, { 1, 0 } };
  for (int[] leg : legs) {
    int lx = leg[0], up = leg[1];
    P.rect(lx, -6 - up + sq, 3, 6 - sq, c.dark);
    P.rect(lx, -1 - up, 4, 1, "#22222a");
  }
  P.rect(-5, -18 + b, 10, 13, c.body);
  P.rect(-5, -18 + b, 2, 13, c.dark);
  P.rect(-3, -5 + b, 2, 1, c.body);
  P.rect(2, -5 + b, 2, 1, c.body);
  if (id == 0) {
    P.rect(-3, -17 + b, 2, 2, c.band);
    P.rect(-1, -15 + b, 2, 2, c.band);
    P.rect(1, -13 + b, 2, 2, c.band);
    P.rect(3, -11 + b, 2, 2, c.band);
  } else {
    P.rect(-5, -10 + b, 10, 2, c.hat);
    P.rect(-1, -10 + b, 2, 2, c.band);
  }
  P.rect(-6, -19 + b, 12, 2, "#ebe8da");
  if (!o.nohead) zHead(P, id, c, b + o.hb, o.mouth, o.blink);
  if (o.armUp) {
    P.rect(3, -25 + b, 2, 8, c.body);
    P.rect(2, -27 + b, 3, 2, c.skin);
    P.rect(-7, -23 + b, 2, 6, c.dark);
    P.rect(-8, -25 + b, 3, 2, c.sdark);
    return;
  }
  int al = o.arm > 0 ? o.arm : 8;
  int as = o.as;
  if (o.arm2 > 0) {
    P.rect(3, -13 + b, o.arm2, 2, c.dark);
    P.rect(3 + o.arm2, -14 + b, 2, 3, c.sdark);
  }
  P.rect(3, -16 + b + as, al, 2, c.body);
  P.rect(3 + al, -17 + b + as, 2, 3, c.skin);
}

void zombieDown(Painter P, int id, ZPal pal) {
  ZPal c = pal != null ? pal : ZC[id];
  P.rect(-12, -6, 14, 6, c.body);
  P.rect(-12, -6, 14, 2, c.dark);
  P.rect(2, -9, 9, 9, c.skin);
  P.rect(6, -6, 2, 1, "#111");
  P.rect(8, -6, 1, 1, "#111");
  P.rect(7, -7, 1, 3, "#111");
  P.rect(-17, -3, 5, 3, c.dark);
  P.rect(12, -4, 8, 2, c.hat);
  P.rect(14, -7, 5, 3, c.hat);
}

void thief(Painter P, TOpts o) {
  int b = o.bob;
  String sk = o.skin != null ? o.skin : TH_SKIN;
  String sd = o.sdark != null ? o.sdark : TH_SDARK;
  int[][] legs = o.legs != null ? o.legs : new int[][] { { -4, 0 }, { 1, 0 } };
  for (int[] leg : legs) {
    int lx = leg[0], up = leg[1];
    P.rect(lx, -7 - up, 3, 7, TH_DARK);
    P.rect(lx, -1 - up, 4, 1, "#3a2418");
  }
  if (o.roll) {
    P.rect(-9, -24 + b, 3, 14, "#dccaa0");
    P.rect(-9, -24 + b, 3, 1, "#a08860");
    P.rect(-9, -11 + b, 3, 1, "#a08860");
  }
  P.rect(-5, -19 + b, 10, 12, TH_SUIT);
  P.rect(-5, -19 + b, 2, 12, TH_DARK);
  P.rect(-1, -19 + b, 1, 12, TH_DARK);
  if (o.pl) {
    P.rect(-8, -12 + b, 4, 4, "#ffffff");
    P.rect(-7, -11 + b, 2, 2, "#e4d4bc");
  }
  P.rect(-4, -28 + b, 8, 9, sk);
  P.rect(-3, -29 + b, 6, 1, sk);
  P.rect(-4, -28 + b, 2, 9, sd);
  if ("ouch".equals(o.arms)) {
    P.rect(1, -27 + b, 3, 3, "#fff");
    P.rect(2, -26 + b, 1, 1, "#111");
  } else if (o.look) {
    P.rect(-4, -26 + b, 2, 2, "#fff");
    P.rect(-4, -25 + b, 1, 1, "#111");
  } else {
    P.rect(1, -26 + b, 2, 2, "#fff");
    P.rect(2, -25 + b, 1, 1, "#111");
  }
  if (o.look) P.rect(-4, -21 + b, 2, 1, "#4a2a1a");
  else if (o.mouth != 0) P.rect(1, -22 + b, 3, 2, "#3a0a0a");
  else P.rect(1, -21 + b, 3, 1, "#4a2a1a");

  if ("up".equals(o.arms)) {
    P.rect(-7, -27 + b, 2, 9, TH_SUIT);
    P.rect(5, -27 + b, 2, 9, TH_SUIT);
    P.rect(-7, -29 + b, 2, 2, sk);
    P.rect(5, -29 + b, 2, 2, sk);
  } else if ("stumble".equals(o.arms)) {
    P.rect(5, -24 + b, 2, 7, TH_SUIT);
    P.rect(6, -26 + b, 2, 2, sk);
    P.rect(-8, -20 + b, 2, 6, TH_SUIT);
    P.rect(-9, -21 + b, 2, 2, sk);
  } else if ("throw".equals(o.arms)) {
    P.rect(-7, -18 + b, 2, 7, TH_SUIT);
    P.rect(5, -28 + b, 2, 10, TH_SUIT);
    P.rect(5, -30 + b, 3, 2, sk);
  } else if ("knee".equals(o.arms)) {
    P.rect(-6, -17 + b, 2, 8, TH_SUIT);
    P.rect(4, -17 + b, 2, 8, TH_SUIT);
    P.rect(8, -27 + b, 1, 2, "#8fd0ff");
    P.rect(9, -22 + b, 1, 2, "#8fd0ff");
  } else if ("ouch".equals(o.arms)) {
    P.rect(-7, -18 + b, 2, 6, TH_SUIT);
    P.rect(-8, -12 + b, 3, 2, sk);
    P.rect(5, -27 + b, 2, 9, TH_SUIT);
    P.rect(5, -29 + b, 2, 2, sk);
  } else if ("itch".equals(o.arms)) {
    P.rect(5, -18 + b, 2, 7, TH_SUIT);
    P.rect(-7, -18 + b, 2, 5, TH_SUIT);
    P.rect(-8, -13 + b + o.ih, 3, 2, sk);
    if (o.ih != 0) {
      P.rect(-10, -15 + b, 1, 1, "#ffffff");
      P.rect(-11, -11 + b, 1, 1, "#ffffff");
    }
  } else {
    P.rect(-7, -18 + b + o.swing, 2, 7, TH_SUIT);
    P.rect(5, -18 + b - o.swing, 2, 7, TH_SUIT);
  }
}

void gFist(Painter P, double x, double y, boolean back) {
  String sk = back ? GC_SD : GC_SKIN, sd = back ? GC_DEEP : GC_SD;
  P.rect(x, y, 13, 12, sk);
  P.rect(x, y + 9, 13, 3, sd);
  P.rect(x, y, 2, 12, sd);
  P.rect(x + 4, y + 1, 1, 4, sd);
  P.rect(x + 7, y + 1, 1, 4, sd);
  P.rect(x + 10, y + 1, 1, 4, sd);
}

void gLeg(Painter P, int x, int up, boolean back) {
  String sk = back ? GC_SD : GC_SKIN, sd = back ? GC_DEEP : GC_SD, su = back ? GC_SU2 : GC_SUIT, s2 = back ? GC_SU3 : GC_SU2;
  P.rect(x, -46 - up, 13, 28, su);
  P.rect(x, -46 - up, 3, 28, s2);
  P.rect(x + 2, -16 - up, 9, 10, sk);
  P.rect(x + 2, -16 - up, 2, 10, sd);
  P.rect(x, -7 - up, 18, 7, sk);
  P.rect(x, -2 - up, 18, 2, sd);
  P.rect(x, -7 - up, 2, 7, sd);
  P.rect(x + 12, -6 - up, 1, 3, sd);
  P.rect(x + 15, -6 - up, 1, 3, sd);
  P.rect(x + 16, -7 - up, 2, 1, GC_NAIL);
  P.rect(x + 1, -18 - up, 3, 2, su);
  P.rect(x + 7, -18 - up, 4, 3, su);
  P.rect(x + 5, -18 - up, 1, 1, s2);
}

void gHead(Painter P, int hx, int hy, int mouth) {
  P.rect(-4 + hx, -92 + hy, 18, 6, GC_SD);
  P.rect(-8 + hx, -112 + hy, 24, 22, GC_SKIN);
  P.rect(-6 + hx, -114 + hy, 20, 2, GC_SKIN);
  P.rect(16 + hx, -108 + hy, 2, 14, GC_SKIN);
  P.rect(-8 + hx, -112 + hy, 4, 22, GC_SD);
  P.rect(-6 + hx, -114 + hy, 3, 2, GC_SD);
  P.rect(-3 + hx, -104 + hy, 4, 7, GC_SD);
  P.rect(-2 + hx, -103 + hy, 2, 5, GC_DEEP);
  P.rect(1 + hx, -117 + hy, 1, 3, GC_HAIR);
  P.rect(4 + hx, -118 + hy, 1, 4, GC_HAIR);
  P.rect(7 + hx, -117 + hy, 1, 3, GC_HAIR);
  P.rect(5 + hx, -109 + hy, 12, 2, GC_DEEP);
  P.rect(13 + hx, -110 + hy, 4, 1, GC_DEEP);
  if (mouth == 3) {
    P.rect(8 + hx, -108 + hy, 6, 5, GC_EYE);
    P.rect(11 + hx, -106 + hy, 2, 2, "#111");
  } else {
    P.rect(9 + hx, -106 + hy, 5, 3, GC_EYE);
    P.rect(12 + hx, -105 + hy, 2, 2, "#111");
  }
  P.rect(4 + hx, -94 + hy, 15, 4, GC_SKIN);
  if (mouth == 2) {
    P.rect(6 + hx, -100 + hy, 13, 10, GC_MOUTH);
    P.rect(8 + hx, -93 + hy, 9, 2, GC_TONGUE);
    P.rect(7 + hx, -100 + hy, 2, 2, GC_TOOTH);
    P.rect(16 + hx, -100 + hy, 2, 2, GC_TOOTH);
    P.rect(9 + hx, -92 + hy, 2, 2, GC_TOOTH);
    P.rect(14 + hx, -92 + hy, 2, 2, GC_TOOTH);
    P.rect(4 + hx, -90 + hy, 15, 3, GC_SKIN);
  } else if (mouth == 3) {
    P.rect(10 + hx, -98 + hy, 6, 5, GC_MOUTH);
  } else if (mouth == 1) {
    P.rect(7 + hx, -98 + hy, 12, 3, GC_MOUTH);
    P.rect(8 + hx, -98 + hy, 10, 1, GC_TOOTH);
  } else {
    P.rect(8 + hx, -97 + hy, 10, 2, GC_MOUTH);
    P.rect(9 + hx, -99 + hy, 2, 2, GC_TOOTH);
    P.rect(15 + hx, -99 + hy, 2, 2, GC_TOOTH);
  }
  P.rect(15 + hx, -104 + hy, 5, 6, GC_SD);
  P.rect(16 + hx, -105 + hy, 3, 1, GC_SKIN);
}

void gArmBack(Painter P, int X, int Y, String arm) {
  int sx = -18 + X, sy = -84 + Y;
  if ("out".equals(arm)) {
    P.rect(sx - 8, sy - 2, 12, 9, GC_SU3);
    P.rect(sx - 20, sy - 8, 14, 8, GC_SD);
    gFist(P, sx - 32, sy - 18, true);
  } else {
    P.rect(sx - 5, sy + 2, 10, 14, GC_SU3);
    P.rect(sx - 4, sy + 16, 8, 20, GC_SD);
    gFist(P, sx - 7, sy + 34, true);
  }
}

void gArm(Painter P, int X, int Y, String arm) {
  int sx = 10 + X, sy = -84 + Y;
  if ("up".equals(arm)) {
    P.rect(sx, sy - 4, 11, 12, GC_SUIT);
    P.rect(sx, sy - 4, 2, 12, GC_SU2);
    P.rect(sx + 1, sy - 26, 9, 22, GC_SKIN);
    P.rect(sx + 1, sy - 26, 2, 22, GC_SD);
    gFist(P, sx - 1, sy - 38, false);
  } else if ("down".equals(arm)) {
    for (int i = 0; i < 8; i++) P.rect(sx + 1 + i * 1.5d, sy + i * 8, 10, 10, i < 2 ? GC_SUIT : GC_SKIN);
    P.rect(sx + 1, sy, 2, 16, GC_SU2);
    gFist(P, REACH - 6, -12, false);
  } else if ("out".equals(arm)) {
    P.rect(sx, sy, 11, 10, GC_SUIT);
    P.rect(sx + 8, sy - 6, 14, 8, GC_SKIN);
    P.rect(sx + 8, sy - 6, 14, 2, GC_LT);
    gFist(P, sx + 20, sy - 16, false);
  } else {
    P.rect(sx, sy, 11, 14, GC_SUIT);
    P.rect(sx, sy, 2, 14, GC_SU2);
    P.rect(sx + 7, sy + 14, 3, 2, GC_SUIT);
    P.rect(sx + 1, sy + 14, 9, 22, GC_SKIN);
    P.rect(sx + 1, sy + 14, 2, 22, GC_SD);
    gFist(P, sx - 1, sy + 34, false);
  }
}

void gTorso(Painter P, int X, int Y) {
  P.rect(-20 + X, -86 + Y, 38, 44, GC_SUIT);
  P.rect(18 + X, -78 + Y, 4, 30, GC_SUIT);
  P.rect(22 + X, -70 + Y, 2, 16, GC_SUIT);
  P.rect(-23 + X, -56 + Y, 4, 14, GC_SUIT);
  P.rect(-20 + X, -86 + Y, 4, 44, GC_SU2);
  P.rect(-23 + X, -56 + Y, 2, 14, GC_SU2);
  P.rect(-18 + X, -44 + Y, 38, 2, GC_SU2);
  P.rect(-14 + X, -88 + Y, 30, 3, GC_SU2);
  P.rect(5 + X, -85 + Y, 1, 26, GC_SU2);
  P.rect(6 + X, -58 + Y, 12, 9, GC_SKIN);
  P.rect(8 + X, -60 + Y, 7, 2, GC_SKIN);
  P.rect(7 + X, -49 + Y, 9, 1, GC_SKIN);
  P.rect(12 + X, -54 + Y, 2, 1, GC_DEEP);
  P.rect(-12 + X, -78 + Y, 6, 4, GC_SKIN);
  P.rect(-11 + X, -79 + Y, 3, 1, GC_SKIN);
  P.rect(-6 + X, -52 + Y, 4, 3, GC_SKIN);
  P.rect(-26 + X, -54 + Y, 7, 8, GC_PL);
  P.rect(-25 + X, -52 + Y, 4, 4, GC_PL2);
  P.rect(-26 + X, -54 + Y, 7, 1, "#ffffff");
}

void giant(Painter P, GOpts o) {
  int X = o.lean, Y = o.bob + o.dip;
  int[] lf = o.lf != null ? o.lf : new int[] { 0, 0 };
  int[] lb = o.lb != null ? o.lb : new int[] { 0, 0 };
  gArmBack(P, X, Y, o.arm);
  gLeg(P, -16 + lb[0], lb[1], true);
  gLeg(P, 1 + lf[0], lf[1], false);
  gTorso(P, X, Y);
  gHead(P, X + o.hx, Y + o.hy, o.mouth);
  gArm(P, X, Y, o.arm);
}

void giantSlip(Painter P) {
  gLeg(P, -14, 0, true);
  P.rect(-4, -52, 28, 12, GC_SUIT);
  P.rect(-4, -42, 28, 2, GC_SU2);
  P.rect(22, -51, 10, 9, GC_SKIN);
  P.rect(31, -62, 7, 20, GC_SKIN);
  P.rect(31, -62, 2, 20, GC_SD);
  P.rect(32, -64, 2, 2, GC_SKIN);
  P.rect(35, -64, 2, 2, GC_SKIN);
  P.rect(36, -60, 2, 1, GC_NAIL);
  P.rect(-46, -98, 8, 18, GC_SD);
  gFist(P, -50, -110, true);
  for (int i = 0; i < 8; i++) {
    P.rect(-20 - i * 2, -50 - i * 6, 38, 7, GC_SUIT);
    P.rect(-20 - i * 2, -50 - i * 6, 4, 7, GC_SU2);
  }
  P.rect(-2, -64, 10, 7, GC_SKIN);
  P.rect(3, -61, 2, 1, GC_DEEP);
  P.rect(-26, -54, 7, 8, GC_PL);
  P.rect(-25, -52, 4, 4, GC_PL2);
  gHead(P, -18, 4, 3);
  P.rect(-2, -96, 9, 20, GC_SKIN);
  P.rect(-2, -96, 2, 20, GC_SD);
  gFist(P, -4, -108, false);
  P.rect(-34, -122, 1, 2, "#8fd0ff");
  P.rect(6, -120, 1, 2, "#8fd0ff");
  P.rect(10, -114, 1, 2, "#8fd0ff");
}

void giantLie(Painter P) {
  P.rect(6, -22, 28, 12, GC_SU2);
  P.rect(32, -24, 9, 12, GC_SD);
  P.rect(38, -40, 7, 18, GC_SD);
  P.rect(38, -42, 2, 2, GC_SD);
  P.rect(42, -42, 2, 2, GC_SD);
  P.rect(-30, -4, 20, 4, GC_SD);
  P.rect(-38, -26, 46, 24, GC_SUIT);
  P.rect(-34, -32, 38, 6, GC_SUIT);
  P.rect(-28, -36, 26, 4, GC_SUIT);
  P.rect(-22, -38, 14, 2, GC_SUIT);
  P.rect(-38, -6, 46, 4, GC_SU2);
  P.rect(-38, -26, 3, 20, GC_SU2);
  P.rect(-18, -37, 10, 5, GC_SKIN);
  P.rect(-14, -35, 2, 1, GC_DEEP);
  P.rect(-32, -22, 5, 4, GC_SKIN);
  P.rect(-4, -29, 4, 3, GC_SKIN);
  P.rect(2, -4, 8, 4, GC_PL);
  P.rect(4, -18, 30, 12, GC_SUIT);
  P.rect(4, -8, 30, 2, GC_SU2);
  P.rect(32, -20, 10, 13, GC_SKIN);
  P.rect(40, -38, 8, 20, GC_SKIN);
  P.rect(40, -38, 2, 20, GC_SD);
  P.rect(41, -40, 2, 2, GC_SKIN);
  P.rect(45, -40, 2, 2, GC_SKIN);
  P.rect(45, -36, 2, 1, GC_NAIL);
  P.rect(-26, -10, 24, 8, GC_SKIN);
  P.rect(-26, -10, 24, 2, GC_LT);
  P.rect(-4, -11, 10, 9, GC_SKIN);
  P.rect(5, -10, 3, 2, GC_SKIN);
  P.rect(5, -6, 3, 2, GC_SKIN);
  P.rect(-38, -16, 6, 10, GC_SD);
  P.rect(-60, -22, 24, 22, GC_SKIN);
  P.rect(-62, -20, 2, 18, GC_SKIN);
  P.rect(-60, -4, 24, 4, GC_SD);
  P.rect(-50, -13, 4, 6, GC_SD);
  P.rect(-49, -12, 2, 4, GC_DEEP);
  P.rect(-66, -15, 4, 1, GC_HAIR);
  P.rect(-67, -12, 5, 1, GC_HAIR);
  P.rect(-66, -9, 4, 1, GC_HAIR);
  P.rect(-57, -26, 5, 4, GC_EYE);
  int[][] xEye = { { -56, -26 }, { -54, -26 }, { -55, -25 }, { -56, -24 }, { -54, -24 } };
  for (int[] xy : xEye) P.rect(xy[0], xy[1], 1, 1, "#111");
  P.rect(-50, -28, 5, 6, GC_SD);
  P.rect(-49, -29, 3, 1, GC_SKIN);
  P.rect(-44, -25, 6, 3, GC_MOUTH);
  P.rect(-43, -28, 3, 3, GC_TONGUE);
  P.rect(-44, -25, 1, 1, GC_TOOTH);
  P.rect(-40, -25, 1, 1, GC_TOOTH);
  P.rect(-38, -24, 3, 4, GC_SKIN);
}

void giantSit(Painter P) {
  P.rect(-36, -10, 12, 6, GC_SD);
  P.rect(-32, -50, 8, 40, GC_SD);
  P.rect(-4, -16, 32, 12, GC_SU2);
  P.rect(26, -14, 10, 12, GC_SD);
  P.rect(34, -20, 7, 20, GC_SD);
  P.rect(0, -14, 32, 12, GC_SUIT);
  P.rect(0, -4, 32, 2, GC_SU2);
  P.rect(28, -12, 10, 12, GC_SKIN);
  P.rect(37, -18, 7, 18, GC_SKIN);
  P.rect(37, -18, 2, 18, GC_SD);
  P.rect(42, -20, 2, 2, GC_SKIN);
  P.rect(-24, -62, 38, 50, GC_SUIT);
  P.rect(14, -54, 4, 30, GC_SUIT);
  P.rect(-24, -62, 4, 50, GC_SU2);
  P.rect(-18, -64, 30, 3, GC_SU2);
  P.rect(2, -40, 10, 8, GC_SKIN);
  P.rect(6, -37, 2, 1, GC_DEEP);
  P.rect(-12, -54, 5, 3, GC_SKIN);
  gHead(P, -4, 28, 3);
  P.rect(-12, -86, 4, 3, GC_LT);
  P.rect(8, -62, 9, 12, GC_SUIT);
  P.rect(6, -80, 9, 20, GC_SKIN);
  P.rect(6, -80, 2, 20, GC_SD);
  gFist(P, -2, -92, false);
}

void mkZombie(String k, String name, final int id, final ZPal pal, final ZOpts base) {
  final ZOpts o = base.copyWithPal(pal);
  make(k + name, 30, 40, 9, 39, new SpriteBuilder() {
    public void build(Painter P) { zombie(P, id, o); }
  });
}

void mkThief(String set, String name, final String sk, final String sd, final boolean pl, final TOpts base) {
  final TOpts o = base.copyWith(sk, sd, pl);
  make("t" + set + "_" + name, 24, 34, 11, 33, new SpriteBuilder() {
    public void build(Painter P) { thief(P, o); }
  });
}

void mkGiant(String name, final GOpts o) {
  make("g_" + name, 104, 136, 52, 134, new SpriteBuilder() {
    public void build(Painter P) { giant(P, o); }
  });
}

void buildSprites() {
  for (int id = 0; id < 2; id++) {
    final int zid = id;
    for (String look : new String[] { "", "g" }) {
      String k = "z" + id + look + "_";
      final ZPal pal = !look.isEmpty() ? ZG[id] : null;
      ZOpts o;
      o = new ZOpts(); mkZombie(k, "idle0", id, pal, o);
      o = new ZOpts(); o.bob = 1; o.legs = new int[][] { { -4, 0 }, { 1, 0 } }; mkZombie(k, "idle1", id, pal, o);
      o = new ZOpts(); o.blink = true; mkZombie(k, "blink0", id, pal, o);
      o = new ZOpts(); o.bob = 1; o.blink = true; mkZombie(k, "blink1", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -6, 1 }, { 2, 0 } }; o.as = -1; mkZombie(k, "w0", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -5, 0 }, { 1, 0 } }; o.bob = 1; o.hb = 1; mkZombie(k, "w1", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -4, 0 }, { 0, 1 } }; o.bob = 1; o.as = 1; mkZombie(k, "w2", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -3, 0 }, { 3, 1 } }; o.as = 1; mkZombie(k, "w3", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -4, 0 }, { 2, 0 } }; o.bob = 1; o.hb = 1; mkZombie(k, "w4", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -5, 1 }, { 1, 0 } }; o.bob = 1; o.as = -1; mkZombie(k, "w5", id, pal, o);
      o = new ZOpts(); o.legs = new int[][] { { -5, 2 }, { 2, 3 } }; o.arm = 9; mkZombie(k, "jump", id, pal, o);
      o = new ZOpts(); o.squat = true; o.as = 1; o.legs = new int[][] { { -5, 0 }, { 2, 0 } }; mkZombie(k, "land", id, pal, o);
      o = new ZOpts(); o.mouth = 1; o.arm = 12; o.arm2 = 10; o.legs = new int[][] { { -5, 0 }, { 2, 0 } }; mkZombie(k, "bite", id, pal, o);
      o = new ZOpts(); o.mouth = 3; o.arm = 12; o.arm2 = 10; o.legs = new int[][] { { -5, 0 }, { 2, 0 } }; mkZombie(k, "biteo", id, pal, o);
      o = new ZOpts(); o.mouth = 4; o.arm = 11; o.arm2 = 9; o.legs = new int[][] { { -5, 0 }, { 2, 0 } }; mkZombie(k, "bitec", id, pal, o);
      o = new ZOpts(); o.mouth = 2; o.armUp = true; o.legs = new int[][] { { -6, 1 }, { 3, 0 } }; mkZombie(k, "hurt", id, pal, o);
      make(k + "down", 40, 12, 18, 11, new SpriteBuilder() {
        public void build(Painter P) { zombieDown(P, zid, pal); }
      });
    }
    String k = "z" + id + "_";
    make(k + "headless", 30, 40, 9, 39, new SpriteBuilder() {
      public void build(Painter P) {
        ZOpts o = new ZOpts(); o.nohead = true;
        zombie(P, zid, o);
      }
    });
    make(k + "head", 16, 20, 8, 19, new SpriteBuilder() {
      public void build(Painter P) { zHead(P, zid, ZC[zid], 19, 0, false); }
    });
    make(k + "icon", 12, 12, 6, 11, new SpriteBuilder() {
      public void build(Painter P) {
        ZPal c = ZC[zid];
        P.rect(-4, -8, 8, 8, c.skin);
        P.rect(1, -6, 2, 2, "#fff");
        P.rect(2, -5, 1, 1, "#111");
        P.rect(-6, -9, 12, 2, c.hat);
        P.rect(-3, -11, 6, 2, c.hat);
      }
    });
  }

  String[][] tsets = {
    { "", TH_SKIN, TH_SDARK, "0" },
    { "p", TH_SKIN, TH_SDARK, "1" },
    { "p1", TH1_SKIN, TH1_SDARK, "1" },
    { "p2", TH2_SKIN, TH2_SDARK, "1" }
  };
  for (String[] ts : tsets) {
    String set = ts[0], sk = ts[1], sd = ts[2];
    boolean pl = "1".equals(ts[3]);
    TOpts o;
    o = new TOpts(); o.legs = new int[][] { { -6, 1 }, { 3, 0 } }; o.swing = 2; o.roll = true; mkThief(set, "r0", sk, sd, pl, o);
    o = new TOpts(); o.bob = 1; o.roll = true; mkThief(set, "r1", sk, sd, pl, o);
    o = new TOpts(); o.legs = new int[][] { { -2, 0 }, { 3, 2 } }; o.swing = -2; o.roll = true; mkThief(set, "r2", sk, sd, pl, o);
    o = new TOpts(); o.bob = 1; o.roll = true; mkThief(set, "r3", sk, sd, pl, o);
    o = new TOpts(); o.roll = true; mkThief(set, "stand", sk, sd, pl, o);
    o = new TOpts(); o.bob = 2; o.arms = "knee"; o.mouth = 1; o.roll = true; mkThief(set, "pant", sk, sd, pl, o);
    o = new TOpts(); o.arms = "throw"; o.mouth = 1; o.roll = true; mkThief(set, "throw", sk, sd, pl, o);
    o = new TOpts(); o.arms = "up"; o.mouth = 1; o.roll = true; mkThief(set, "scared", sk, sd, pl, o);
    o = new TOpts(); o.arms = "up"; o.mouth = 1; mkThief(set, "scared2", sk, sd, pl, o);
    o = new TOpts(); o.arms = "ouch"; o.mouth = 1; o.legs = new int[][] { { -5, 2 }, { 2, 3 } }; o.roll = true; mkThief(set, "ouch", sk, sd, pl, o);
    o = new TOpts(); o.arms = "itch"; o.mouth = 1; o.bob = 1; o.roll = true; mkThief(set, "itch0", sk, sd, pl, o);
    o = new TOpts(); o.arms = "itch"; o.mouth = 1; o.bob = 2; o.ih = 1; o.roll = true; mkThief(set, "itch1", sk, sd, pl, o);
    o = new TOpts(); o.legs = new int[][] { { -6, 1 }, { 3, 0 } }; o.swing = 2; o.roll = true; o.look = true; mkThief(set, "r0l", sk, sd, pl, o);
    o = new TOpts(); o.bob = 1; o.roll = true; o.look = true; mkThief(set, "r1l", sk, sd, pl, o);
    o = new TOpts(); o.legs = new int[][] { { -2, 0 }, { 3, 2 } }; o.swing = -2; o.roll = true; o.look = true; mkThief(set, "r2l", sk, sd, pl, o);
    o = new TOpts(); o.bob = 1; o.roll = true; o.look = true; mkThief(set, "r3l", sk, sd, pl, o);
    o = new TOpts(); o.arms = "stumble"; o.mouth = 1; o.legs = new int[][] { { -6, 2 }, { 2, 0 } }; o.bob = 1; o.roll = true; mkThief(set, "stumble", sk, sd, pl, o);
  }

  GOpts go;
  go = new GOpts(); go.lf = new int[] { 2, 0 }; go.lb = new int[] { -2, 0 }; mkGiant("b0", go);
  go = new GOpts(); go.lf = new int[] { 2, 0 }; go.lb = new int[] { -2, 0 }; go.bob = 1; mkGiant("b1", go);
  go = new GOpts(); go.lf = new int[] { 4, 0 }; go.lb = new int[] { -4, 0 }; mkGiant("w0", go);
  go = new GOpts(); go.lf = new int[] { 0, 5 }; go.bob = -1; mkGiant("w1", go);
  go = new GOpts(); go.lf = new int[] { -4, 0 }; go.lb = new int[] { 4, 0 }; mkGiant("w2", go);
  go = new GOpts(); go.lb = new int[] { 0, 5 }; go.bob = -1; mkGiant("w3", go);
  go = new GOpts(); go.lf = new int[] { 7, 22 }; go.lb = new int[] { -3, 0 }; go.arm = "out"; go.mouth = 1; mkGiant("footup", go);
  go = new GOpts(); go.lf = new int[] { 7, 0 }; go.lb = new int[] { -4, 0 }; go.bob = 3; go.mouth = 2; mkGiant("stomp", go);
  go = new GOpts(); go.lf = new int[] { 4, 0 }; go.lb = new int[] { -5, 0 }; go.arm = "up"; go.mouth = 1; mkGiant("fistup", go);
  go = new GOpts(); go.lf = new int[] { 6, 0 }; go.lb = new int[] { -6, 0 }; go.arm = "down"; go.lean = 8; go.dip = 6; go.mouth = 2; mkGiant("fistdown", go);
  go = new GOpts(); go.lf = new int[] { 5, 0 }; go.lb = new int[] { -5, 0 }; go.arm = "out"; go.mouth = 2; go.hy = -2; mkGiant("roar", go);
  make("g_slip", 104, 136, 52, 134, new SpriteBuilder() { public void build(Painter P) { giantSlip(P); } });
  make("g_getup", 104, 136, 52, 134, new SpriteBuilder() { public void build(Painter P) { giantSit(P); } });
  make("g_lie", 132, 52, 68, 50, new SpriteBuilder() { public void build(Painter P) { giantLie(P); } });
  make("g_dust", 112, 36, 56, 34, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(-46, -6, 92, 6, "#7e8064"); P.rect(-38, -12, 76, 6, "#8e9070"); P.rect(-28, -18, 56, 6, "#9ea07e");
      P.rect(-16, -23, 32, 5, "#aeb08c"); P.rect(-8, -26, 16, 3, "#bcbe9a");
      int[][] pts = { { -36, -8 }, { -20, -15 }, { 6, -10 }, { 24, -14 }, { 34, -5 }, { -6, -20 }, { 12, -21 } };
      for (int i = 0; i < pts.length; i++) P.rect(pts[i][0], pts[i][1], 2, 1, i % 2 != 0 ? GC_SD : "#6e7056");
      P.rect(-24, -15, 10, 3, GC_SUIT); P.rect(-22, -13, 4, 2, GC_SU2); P.rect(14, -9, 12, 3, GC_SU2);
      P.rect(16, -10, 6, 1, GC_SUIT); P.rect(-40, -5, 8, 2, GC_SUIT);
      P.rect(28, -15, 1, 3, GC_HAIR); P.rect(30, -16, 1, 4, GC_HAIR); P.rect(32, -15, 1, 3, GC_HAIR);
      P.rect(-5, -31, 10, 6, GC_PL); P.rect(-2, -29, 4, 2, GC_PL2); P.rect(-5, -31, 10, 1, "#ffffff");
    }
  });
  make("stone", 12, 10, 6, 5, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(-5, -4, 10, 8, "#9a9488"); P.rect(-5, -4, 10, 2, "#bab4a6"); P.rect(-5, -4, 2, 8, "#7a7468"); P.rect(1, 0, 3, 1, "#6a6458");
    }
  });
  make("plaster", 10, 7, 5, 3, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(-5, -3, 10, 7, "#f4efe0"); P.rect(-2, -1, 4, 3, "#d4c4a8"); P.rect(-4, -2, 1, 1, "#d4c4a8"); P.rect(3, 2, 1, 1, "#d4c4a8");
    }
  });

  make("pu_brain", 12, 9, 6, 9, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(-5, -8, 10, 7, "#f09ab0"); P.rect(-4, -9, 8, 1, "#f09ab0"); P.rect(-6, -6, 12, 4, "#f09ab0"); P.rect(-5, -2, 10, 1, "#c8607e");
      P.rect(-3, -7, 1, 3, "#c8607e"); P.rect(0, -8, 1, 2, "#c8607e"); P.rect(2, -6, 1, 3, "#c8607e"); P.rect(-1, -4, 3, 1, "#c8607e"); P.rect(-4, -8, 2, 1, "#ffd0dc");
    }
  });
  make("pu_gold", 10, 13, 5, 13, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(-4, -8, 8, 8, "#9aa0ac"); P.rect(-4, -8, 2, 8, "#6a707c"); P.rect(-4, -9, 8, 2, "#f8d040"); P.rect(1, -7, 1, 3, "#f8d040"); P.rect(-1, -5, 4, 3, "#f8d040");
      P.rect(2, -13, 1, 5, "#8a5a2c"); P.rect(1, -10, 3, 2, "#f8d040");
    }
  });
  make("pu_chick", 17, 15, 9, 14, new SpriteBuilder() {
    public void build(Painter P) {
      String Wh = "#f8f6f0", Y = "#f0a020", Rd = "#e02828";
      P.rect(-5, -9, 9, 6, Wh); P.rect(-6, -8, 11, 4, Wh); P.rect(-4, -3, 7, 1, Wh);
      P.rect(-7, -11, 3, 4, Wh); P.rect(-8, -12, 2, 2, Wh);
      P.rect(2, -12, 4, 4, Wh); P.rect(2, -13, 3, 1, Rd); P.rect(3, -14, 1, 1, Rd);
      P.rect(6, -11, 2, 1, Y); P.rect(4, -11, 1, 1, "#111"); P.rect(5, -9, 1, 2, Rd);
      P.rect(-3, -8, 5, 3, "#d8d4cc"); P.rect(-2, -8, 4, 1, "#ebe7df");
      P.rect(-2, -2, 1, 2, Y); P.rect(1, -2, 1, 2, Y); P.rect(-3, 0, 2, 1, Y); P.rect(1, 0, 2, 1, Y);
    }
  });
  make("chick_i", 11, 10, 5, 10, new SpriteBuilder() {
    public void build(Painter P) {
      String Wh = "#f8f6f0";
      P.rect(-4, -6, 7, 5, Wh); P.rect(-5, -7, 2, 3, Wh); P.rect(1, -9, 3, 4, Wh); P.rect(4, -7, 2, 1, "#f0a020");
      P.rect(2, -10, 2, 1, "#e02828"); P.rect(3, -8, 1, 1, "#111"); P.rect(-2, -5, 3, 2, "#d0cbc0"); P.rect(-1, -1, 1, 1, "#f0a020"); P.rect(1, -1, 1, 1, "#f0a020");
    }
  });

  for (int gi = 0; gi < 3; gi++) {
    final boolean grun = gi > 0;
    final boolean gf = gi == 2;
    make("gnome" + gi, 14, 21, 7, 20, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-4 + (grun && gf ? 1 : 0), -2 - (grun && !gf ? 1 : 0), 3, 2, "#5a3a1a");
        P.rect(1 - (grun && gf ? 1 : 0), -2 - (grun && gf ? 1 : 0), 3, 2, "#5a3a1a");
        P.rect(-4, -9, 8, 7, "#3a6ac8"); P.rect(-4, -9, 2, 7, "#2a4a98"); P.rect(-4, -6, 8, 1, "#2a2a2a");
        P.rect(-3, -12, 6, 5, "#f4f4f4"); P.rect(-2, -14, 4, 3, "#f0c8a0"); P.rect(1, -13, 2, 1, "#e89070"); P.rect(1, -14, 1, 1, "#111");
        P.rect(-3, -16, 6, 2, "#d82828"); P.rect(-2, -18, 4, 2, "#d82828"); P.rect(-1, -20, 2, 2, "#d82828");
        if (grun) {
          P.rect(-6, -14, 2, 5, "#3a6ac8"); P.rect(4, -14, 2, 5, "#3a6ac8");
          P.rect(-6, -15, 2, 1, "#f0c8a0"); P.rect(4, -15, 2, 1, "#f0c8a0");
          P.rect(0, -11, 2, 2, "#3a0a0a"); P.rect(1, -15, 2, 2, "#fff"); P.rect(2, -14, 1, 1, "#111");
        }
      }
    });
  }

  make("poster", 62, 50, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 0, 62, 50, "#e8d8a8"); P.rect(0, 0, 62, 1, "#c8b480"); P.rect(0, 49, 62, 1, "#b8a070"); P.rect(61, 0, 1, 50, "#c8b480"); P.rect(54, 44, 8, 6, "#d0bc88");
      P.rect(24, 15, 13, 14, TH_SKIN); P.rect(24, 15, 3, 14, TH_SDARK); P.rect(31, 19, 3, 3, "#fff"); P.rect(32, 20, 1, 1, "#111"); P.rect(31, 25, 4, 1, "#4a2a1a");
      P.rect(20, 29, 21, 6, TH_SUIT); P.rect(20, 29, 21, 1, TH_DARK);
      P.rect(12, 39, 38, 2, "#8a7650"); P.rect(17, 43, 28, 1, "#8a7650"); P.rect(30, 1, 2, 2, "#c03030");
    }
  });

  for (int ri = 0; ri < 2; ri++) {
    final boolean full = ri == 1;
    make("roll" + ri, 14, 13, 7, 6, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-6, -1, 2, 4, "#b8bcc8"); P.rect(-6, -1, 12, 1, "#d8dce8");
        if (full) { P.rect(-4, -5, 8, 8, "#f8f8f8"); P.rect(-4, -5, 8, 1, "#ffffff"); P.rect(2, 3, 3, 3, "#f8f8f8"); }
        P.rect(-1, -2, 2, 2, "#c8b090");
      }
    });
  }

  for (int s = 0; s < 3; s++) {
    for (int m = 0; m < 3; m++) {
      final int shape = s, mood = m;
      make("ghost" + s + m, 12, 17, 6, 16, new SpriteBuilder() {
        public void build(Painter P) {
          String c = shape == 1 ? "#e4f4ec" : shape == 2 ? "#ece4ff" : "#e4ecff", k = "#3a3a5a";
          int top = shape == 2 ? -14 : shape == 1 ? -8 : -10, hw = shape == 1 ? 3 : 4;
          P.rect(-hw + 1, top, hw * 2 - 2, -top - 1, c); P.rect(-hw, top + 2, hw * 2, -top - 3, c);
          if (shape == 2) P.rect(-1, top - 1, 2, 1, c);
          for (int x = -hw; x < hw; x += 3) P.rect(x, -2, 2, 2, c);
          int ey = top + (shape == 2 ? 4 : 2);
          if (mood == 1) {
            P.rect(-hw - 1, top - 1, 1, 4, c); P.rect(hw, top - 1, 1, 4, c);
            P.rect(-2, ey, 1, 1, k); P.rect(1, ey, 1, 1, k); P.rect(-1, ey + 2, 2, 2, k);
          } else if (mood == 2) {
            P.rect(-2, ey, 1, 1, k); P.rect(2, ey, 1, 1, k); P.rect(-2, ey + 1, 1, 1, k); P.rect(1, ey + 1, 1, 1, k);
            P.rect(-2, ey + 3, 4, 1, k); P.rect(-2, ey + 4, 1, 1, k); P.rect(1, ey + 4, 1, 1, k);
          } else {
            P.rect(-2, ey, 1, 2, k); P.rect(1, ey, 1, 2, k); P.rect(-1, ey + 3, 2, 1, k);
          }
        }
      }, false);
    }
  }

  for (int bi = 0; bi < 2; bi++) {
    final boolean up = bi == 0;
    make("bat" + bi, 20, 12, 10, 7, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-2, -3, 5, 6, "#4a3568"); P.rect(-2, -5, 1, 2, "#4a3568"); P.rect(2, -5, 1, 2, "#4a3568");
        P.rect(-1, -2, 1, 1, "#ff4040"); P.rect(1, -2, 1, 1, "#ff4040");
        if (up) { P.rect(-8, -6, 6, 2, "#5c4480"); P.rect(3, -6, 6, 2, "#5c4480"); P.rect(-6, -4, 4, 2, "#4a3568"); P.rect(3, -4, 4, 2, "#4a3568"); }
        else { P.rect(-8, 0, 6, 2, "#5c4480"); P.rect(3, 0, 6, 2, "#5c4480"); P.rect(-6, -2, 4, 2, "#4a3568"); P.rect(3, -2, 4, 2, "#4a3568"); }
      }
    });
  }

  for (int ci = 0; ci < 2; ci++) {
    final boolean up = ci == 0;
    make("crow" + ci, 20, 14, 9, 8, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-5, -3, 9, 5, "#20202a"); P.rect(3, -6, 4, 4, "#20202a"); P.rect(7, -5, 2, 1, "#e8a820"); P.rect(5, -5, 1, 1, "#fff");
        P.rect(-8, -2, 3, 2, "#20202a");
        if (up) P.rect(-3, -8, 6, 5, "#34343f"); else P.rect(-3, 0, 6, 4, "#34343f");
      }
    });
  }

  for (int rti = 0; rti < 2; rti++) {
    final boolean f = rti == 1;
    make("rat" + rti, 18, 8, 9, 7, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-5, -5, 9, 4, "#7c7c86"); P.rect(3, -6, 4, 4, "#7c7c86"); P.rect(4, -8, 2, 2, "#c08a98"); P.rect(6, -4, 1, 1, "#111"); P.rect(7, -3, 1, 1, "#e08aa0");
        P.rect(-9, -3, 4, 1, "#c08a98"); P.rect(f ? -4 : -3, -1, 2, 1, "#55555e"); P.rect(f ? 2 : 1, -1, 2, 1, "#55555e");
      }
    });
  }

  String[][] wcs = { { "wc_closed", "" }, { "wc_open", "open" }, { "wc_tired", "tired" }, { "wc_hurt", "hurt" } };
  for (String[] wci : wcs) {
    final String face = wci[1];
    make(wci[0], 30, 48, 15, 47, new SpriteBuilder() {
      public void build(Painter P) {
        String w = "#f4f4f8", s = "#c9cfdc";
        P.rect(-6, -8, 12, 8, w); P.rect(-6, -8, 3, 8, s); P.rect(-8, -2, 16, 2, s);
        P.rect(-12, -20, 24, 12, w); P.rect(-11, -8, 22, 1, s); P.rect(-12, -20, 3, 12, s);
        P.rect(-13, -22, 26, 3, w); P.rect(-13, -20, 26, 1, s);
        if (face.isEmpty()) { P.rect(-13, -26, 26, 4, w); P.rect(-13, -23, 26, 1, s); P.rect(-11, -27, 22, 1, w); return; }
        P.rect(-8, -17, 16, 5, "#7ec8f0"); P.rect(-6, -16, 4, 1, "#d8f2ff");
        P.rect(-10, -46, 20, 24, w); P.rect(-11, -44, 22, 20, w); P.rect(-11, -44, 2, 20, s); P.rect(-8, -47, 16, 1, w);
        String k = "#16161e";
        if ("open".equals(face)) {
          P.rect(-7, -41, 5, 6, k); P.rect(-6, -40, 3, 4, "#fff"); P.rect(-5, -39, 2, 2, k);
          P.rect(2, -41, 5, 6, k); P.rect(3, -40, 3, 4, "#fff"); P.rect(3, -39, 2, 2, k);
          P.rect(-8, -44, 4, 1, k); P.rect(4, -44, 4, 1, k);
          P.rect(-8, -33, 16, 2, k); P.rect(-7, -31, 14, 3, k); P.rect(-5, -28, 10, 1, k); P.rect(-3, -30, 6, 2, "#e8507c");
        } else if ("tired".equals(face)) {
          P.rect(-7, -39, 5, 1, k); P.rect(2, -39, 5, 1, k); P.rect(-6, -38, 3, 1, k); P.rect(3, -38, 3, 1, k);
          P.rect(-4, -31, 8, 3, k); P.rect(-2, -29, 4, 2, "#e8507c"); P.rect(8, -43, 1, 2, "#7ec8f0"); P.rect(9, -38, 1, 2, "#7ec8f0");
        } else {
          P.rect(-7, -41, 1, 1, k); P.rect(-6, -40, 1, 1, k); P.rect(-5, -39, 1, 1, k); P.rect(-4, -38, 1, 1, k);
          P.rect(-4, -41, 1, 1, k); P.rect(-7, -38, 1, 1, k); P.rect(-5, -40, 1, 1, k); P.rect(-6, -39, 1, 1, k);
          P.rect(3, -41, 1, 1, k); P.rect(4, -40, 1, 1, k); P.rect(5, -39, 1, 1, k); P.rect(6, -38, 1, 1, k);
          P.rect(6, -41, 1, 1, k); P.rect(3, -38, 1, 1, k); P.rect(5, -40, 1, 1, k); P.rect(4, -39, 1, 1, k);
          P.rect(-5, -31, 10, 1, k); P.rect(-6, -30, 2, 1, k); P.rect(4, -30, 2, 1, k);
        }
      }
    });
  }

  make("blob", 8, 8, 4, 4, new SpriteBuilder() {
    public void build(Painter P) { P.disc(0, 0, 3, "#5db4f0"); P.rect(-1, -2, 2, 1, "#d8f2ff"); }
  });
  for (int wi = 0; wi < 2; wi++) {
    final int wf = wi * 2;
    make("wave" + wi, 16, 14, 8, 14, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-7, -9, 14, 9, "#3f8fe0"); P.rect(-5, -12, 9, 3, "#3f8fe0"); P.rect(-7 + wf, -13, 5, 2, "#eaf6ff");
        P.rect(-8, -10, 3, 2, "#eaf6ff"); P.rect(-4 + wf, -8, 6, 1, "#8fc8ff"); P.rect(-6, -4, 8, 1, "#2a6ab8");
      }
    });
  }
  make("rock", 8, 8, 4, 4, new SpriteBuilder() {
    public void build(Painter P) { P.disc(0, 0, 3, "#8a8a92"); P.rect(-2, -2, 2, 2, "#b4b4bc"); P.rect(1, 1, 2, 1, "#5e5e66"); }
  });
  make("pillow", 12, 8, 6, 4, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-6, -3, 12, 7, "#f0f0f6"); P.rect(-6, 2, 12, 2, "#c4c8d8"); P.rect(-5, -4, 10, 1, "#f0f0f6"); }
  });
  make("lamp", 8, 10, 4, 5, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-3, -5, 6, 5, "#f4d848"); P.rect(-2, -6, 4, 1, "#f4d848"); P.rect(-1, 0, 2, 4, "#7a5a30"); P.rect(-3, 4, 6, 1, "#7a5a30"); }
  });
  make("log", 16, 10, 8, 10, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-7, -9, 14, 9, "#7a4a22"); P.rect(-7, -9, 14, 2, "#9a6432"); P.rect(-7, -8, 2, 7, "#c89860"); P.rect(-1, -5, 4, 1, "#5a3414"); P.rect(3, -3, 3, 1, "#5a3414"); }
  });
  make("shock", 14, 10, 7, 10, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-5, -4, 10, 4, "#d8c090"); P.rect(-3, -8, 6, 4, "#e8d8b0"); P.rect(-6, -2, 3, 2, "#b89868"); P.rect(2, -9, 2, 2, "#e8d8b0"); }
  });
  int[] foffs = { 0, 1, -1 };
  for (int fi = 0; fi < 3; fi++) {
    final int ff = foffs[fi];
    make("fire" + fi, 12, 14, 6, 13, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-4, -6, 8, 6, "#f06018"); P.rect(-3, -9 - ff, 6, 4, "#f06018"); P.rect(-1 - ff, -12, 3, 3, "#f06018");
        P.rect(-2, -5, 5, 5, "#f8b020"); P.rect(-1, -8, 3, 3, "#f8b020"); P.rect(-1, -3, 2, 3, "#fff4b0");
      }
    }, false);
  }
  make("duck", 9, 8, 4, 8, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-4, -4, 8, 4, "#f8d820"); P.rect(0, -8, 4, 4, "#f8d820"); P.rect(4, -6, 2, 1, "#f08020"); P.rect(2, -7, 1, 1, "#111"); }
  });
  for (int si = 0; si < 2; si++) {
    final int sf = si;
    make("scrap" + si, 8, 8, 4, 4, new SpriteBuilder() {
      public void build(Painter P) { P.rect(-3, -3 + sf, 5, 2, "#f07a18"); P.rect(-1, -1, 4, 2, "#f07a18"); P.rect(0, 1 - sf, 3, 2, "#b85a10"); }
    });
  }
  make("key", 10, 6, 5, 3, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-5, -3, 4, 5, "#f8d040"); P.rect(-4, -2, 2, 3, "#7a5a10"); P.rect(-1, -1, 6, 2, "#f8d040"); P.rect(3, 1, 1, 2, "#f8d040"); P.rect(1, 1, 1, 1, "#f8d040"); }
  });
  make("heart", 7, 6, 0, 0, new SpriteBuilder() {
    public void build(Painter P) { P.rect(0, 0, 3, 3, "#e8304a"); P.rect(4, 0, 3, 3, "#e8304a"); P.rect(0, 1, 7, 3, "#e8304a"); P.rect(1, 4, 5, 1, "#e8304a"); P.rect(2, 5, 3, 1, "#e8304a"); P.rect(1, 1, 1, 1, "#ffb0b8"); }
  });
  make("heart0", 7, 6, 0, 0, new SpriteBuilder() {
    public void build(Painter P) { P.rect(0, 0, 3, 3, "#3a3040"); P.rect(4, 0, 3, 3, "#3a3040"); P.rect(0, 1, 7, 3, "#3a3040"); P.rect(1, 4, 5, 1, "#3a3040"); P.rect(2, 5, 3, 1, "#3a3040"); }
  });
  make("roll", 14, 6, 7, 6, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-7, -5, 14, 5, "#dccaa0"); P.rect(-7, -5, 2, 5, "#a08860"); P.rect(5, -5, 2, 5, "#a08860"); P.rect(-4, -4, 8, 1, "#f0e4c4"); }
  });
  make("sun", 9, 9, 4, 4, new SpriteBuilder() {
    public void build(Painter P) { P.disc(0, 0, 3, "#f8c830"); P.rect(-1, -1, 2, 2, "#fff0a0"); }
  });

  make("tomb", 14, 16, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 3, 14, 13, "#8a8e9a"); P.rect(2, 0, 10, 3, "#8a8e9a"); P.rect(1, 1, 12, 2, "#8a8e9a");
      P.rect(0, 3, 2, 13, "#646876"); P.rect(4, 5, 6, 1, "#4a4e5a"); P.rect(6, 3, 2, 6, "#4a4e5a"); P.rect(3, 11, 8, 1, "#646876");
    }
  });
  make("tomb2", 16, 22, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 10, 16, 12, "#8a8e9a"); P.rect(0, 10, 2, 12, "#646876"); P.rect(6, 0, 4, 10, "#a0a4b0");
      P.rect(3, 3, 10, 3, "#a0a4b0"); P.rect(4, 14, 8, 1, "#4a4e5a"); P.rect(4, 17, 6, 1, "#4a4e5a");
    }
  });
  make("crate", 18, 18, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 0, 18, 18, "#9a6a34"); P.rect(0, 0, 18, 2, "#c08a48"); P.rect(0, 16, 18, 2, "#6a4420");
      P.rect(0, 0, 2, 18, "#6a4420"); P.rect(16, 0, 2, 18, "#6a4420"); P.rect(3, 3, 12, 1, "#6a4420"); P.rect(3, 8, 12, 1, "#6a4420"); P.rect(3, 13, 12, 1, "#6a4420");
    }
  });
  make("crate2", 22, 34, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      for (int oy : new int[] { 0, 17 }) {
        P.rect(0, oy, 22, 17, "#9a6a34"); P.rect(0, oy, 22, 2, "#c08a48"); P.rect(0, oy + 15, 22, 2, "#6a4420");
        P.rect(0, oy, 2, 17, "#6a4420"); P.rect(20, oy, 2, 17, "#6a4420"); P.rect(3, oy + 3, 2, 11, "#6a4420"); P.rect(17, oy + 3, 2, 11, "#6a4420"); P.rect(5, oy + 8, 12, 1, "#6a4420");
      }
    }
  });
  make("dresser", 36, 24, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 0, 36, 24, "#6a3a1c"); P.rect(0, 0, 36, 2, "#9a5a2c"); P.rect(2, 4, 32, 8, "#84482a"); P.rect(2, 14, 32, 8, "#84482a");
      P.rect(16, 7, 4, 2, "#e8c860"); P.rect(16, 17, 4, 2, "#e8c860"); P.rect(0, 22, 4, 2, "#3a1c0c"); P.rect(32, 22, 4, 2, "#3a1c0c");
    }
  });
  make("chair", 22, 20, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 0, 22, 20, "#7a4424"); P.rect(0, 0, 22, 3, "#a8643a"); P.rect(0, 3, 2, 17, "#4a2410");
      P.rect(20, 3, 2, 17, "#4a2410"); P.rect(9, 8, 4, 4, "#e8c860"); P.rect(2, 17, 18, 3, "#4a2410");
    }
  });
  make("shelf", 38, 44, 0, 0, new SpriteBuilder() {
    public void build(Painter P) {
      P.rect(0, 0, 38, 44, "#5a3018"); P.rect(0, 0, 38, 2, "#8a5028"); P.rect(2, 4, 34, 11, "#2a1408"); P.rect(2, 17, 34, 11, "#2a1408"); P.rect(2, 30, 34, 12, "#2a1408");
      String[] cols = { "#b83a3a", "#3a6ab8", "#3a9a5a", "#c8a030", "#8a4ab0", "#c86a30" };
      for (int r = 0; r < 3; r++) for (int i = 0; i < 9; i++) {
        int hh = 7 + ((i * 3 + r) % 4);
        P.rect(3 + i * 3 + (r == 1 ? 2 : 0), 4 + r * 13 + (11 - hh) + (r == 2 ? 1 : 0), 2, hh, cols[(i + r * 2) % 6]);
      }
    }
  });
  make("table", 30, 20, 15, 20, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-15, -20, 30, 3, "#8a5028"); P.rect(-13, -17, 3, 17, "#5a3018"); P.rect(10, -17, 3, 17, "#5a3018"); P.rect(-13, -8, 26, 2, "#5a3018"); }
  });
  make("candle", 6, 10, 3, 10, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-1, -8, 3, 6, "#f0ead0"); P.rect(0, -9, 1, 1, "#333"); P.rect(-3, -2, 7, 2, "#b89030"); }
  });
  make("branch", 46, 8, 0, 0, new SpriteBuilder() {
    public void build(Painter P) { P.rect(0, 0, 46, 4, "#6a4424"); P.rect(0, 0, 46, 1, "#8a5c34"); P.rect(2, 4, 10, 2, "#2f9a2a"); P.rect(20, 4, 8, 2, "#2f9a2a"); P.rect(34, 4, 10, 2, "#2f9a2a"); P.rect(6, 6, 4, 1, "#1f7a22"); P.rect(38, 6, 4, 1, "#1f7a22"); }
  });
  make("door", 22, 40, 11, 40, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-11, -40, 22, 40, "#3a1c0c"); P.rect(-9, -38, 18, 38, "#5a2c14"); P.rect(-7, -36, 6, 14, "#4a2410"); P.rect(1, -36, 6, 14, "#4a2410"); P.rect(-7, -19, 6, 16, "#4a2410"); P.rect(1, -19, 6, 16, "#4a2410"); P.rect(5, -20, 2, 2, "#e8c860"); }
  });
  for (int gti = 0; gti <= 3; gti++) {
    final int st = gti;
    make("gate" + gti, 16, 48, 2, 48, new SpriteBuilder() {
      public void build(Painter P) {
        String k = "#3a3e4c", l = "#6a7084";
        if (st == 0) { P.rect(-2, -4, 16, 3, k); P.rect(0, -6, 2, 2, l); P.rect(5, -6, 2, 2, l); P.rect(10, -6, 2, 2, l); return; }
        P.rect(-1, -46, 3, 46, k); P.rect(-1, -48, 3, 2, l);
        int lean = st == 3 ? 0 : st == 2 ? 1 : 2;
        for (int i = 0; i < 3; i++) {
          int x = 4 + i * 3;
          if (st == 1 && i == 1) continue;
          P.rect(x + (lean != 0 && i != 0 ? lean : 0), -42 + i * lean, 1, 42 - i * lean, l);
          P.rect(x - 1 + (lean != 0 && i != 0 ? lean : 0), -44 + i * lean, 3, 2, l);
        }
        P.rect(2, -36, 11, 1, k); P.rect(2, -10, 11, 1, k);
        if (st < 3) P.rect(6, -22, 3, 2, "#c0302a");
      }
    });
  }
  for (final String bst : new String[] { "sleep", "awake", "empty" }) {
    make("bed_" + bst, 96, 44, 48, 44, new SpriteBuilder() {
      public void build(Painter P) {
        P.rect(-46, -14, 92, 6, "#7a4a24"); P.rect(-44, -8, 4, 8, "#5a3214"); P.rect(40, -8, 4, 8, "#5a3214");
        P.rect(40, -34, 6, 22, "#7a4a24"); P.rect(40, -36, 6, 2, "#a06a38"); P.rect(-46, -22, 4, 10, "#7a4a24");
        P.rect(-42, -19, 82, 6, "#e8e8f0"); P.rect(26, -24, 14, 6, "#ffffff"); P.rect(26, -19, 14, 1, "#c4c8d8");
        if ("empty".equals(bst)) { P.rect(-42, -21, 50, 4, "#5a78c0"); P.rect(-10, -24, 16, 4, "#5a78c0"); P.rect(-42, -18, 60, 4, "#4868b0"); return; }
        P.rect(12, -29, 14, 4, "#dccaa0"); P.rect(12, -29, 2, 4, "#a08860");
        if ("sleep".equals(bst)) {
          P.rect(-42, -25, 62, 8, "#5a78c0"); P.rect(-38, -27, 50, 2, "#5a78c0"); P.rect(-42, -18, 62, 4, "#4868b0");
          P.rect(24, -32, 9, 8, TH_SKIN); P.rect(24, -32, 9, 2, TH_SDARK); P.rect(28, -28, 3, 1, "#111"); P.rect(27, -25, 3, 1, "#4a2a1a");
          P.rect(18, -24, 6, 4, TH_SUIT);
        } else {
          P.rect(-42, -24, 46, 7, "#5a78c0"); P.rect(-42, -18, 46, 4, "#4868b0");
          P.rect(6, -34, 10, 16, TH_SUIT); P.rect(6, -34, 2, 16, TH_DARK);
          P.rect(7, -43, 8, 9, TH_SKIN); P.rect(7, -43, 2, 9, TH_SDARK); P.rect(8, -41, 3, 3, "#fff"); P.rect(8, -40, 1, 1, "#111"); P.rect(9, -36, 3, 2, "#3a0a0a");
          P.rect(0, -32, 6, 2, TH_SUIT);
        }
      }
    });
  }
  make("grave", 22, 6, 11, 2, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-9, -1, 18, 4, "#1a0e0c"); P.rect(-11, -2, 5, 3, "#8a4a38"); P.rect(6, -2, 5, 3, "#8a4a38"); P.rect(-7, 2, 14, 1, "#3a1c16"); }
  }, false);
  make("rope", 6, 22, 3, 22, new SpriteBuilder() {
    public void build(Painter P) { P.rect(-1, -20, 2, 20, "#c8a030"); P.rect(-2, -22, 4, 3, "#e8c860"); P.rect(-3, -2, 6, 2, "#8a6a20"); }
  });
}

// ---------------------------------------------------------------- backgrounds
void quantize(CanvasBuf c, int step) {
  for (int i = 0; i < c.px.length; i++) {
    int p = c.px[i];
    int a = (p >>> 24) & 255;
    int r = Math.min(255, (int) Math.round(((p >>> 16) & 255) / (double) step) * step);
    int g = Math.min(255, (int) Math.round(((p >>> 8) & 255) / (double) step) * step);
    int b = Math.min(255, (int) Math.round((p & 255) / (double) step) * step);
    c.px[i] = (a << 24) | (r << 16) | (g << 8) | b;
  }
}

BufferedImage pimgToBuffered(PImage img) {
  img.loadPixels();
  BufferedImage bi = new BufferedImage(img.width, img.height, BufferedImage.TYPE_INT_ARGB);
  bi.setRGB(0, 0, img.width, img.height, img.pixels, 0, img.width);
  return bi;
}

HashMap<String, CanvasBuf> buildPainting(BufferedImage nwBi, boolean hole) {
  HashMap<String, CanvasBuf> out = new HashMap<String, CanvasBuf>();
  Object[][] sizes = { { "big", 150, 97 }, { "small", 84, 54 } };
  for (Object[] sz : sizes) {
    String name = (String) sz[0];
    int w = (Integer) sz[1], h = (Integer) sz[2];
    BufferedImage dst = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);
    Graphics2D g2 = dst.createGraphics();
    g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
    g2.drawImage(nwBi, 0, 0, w, h, null);
    g2.dispose();
    CanvasBuf cv = new CanvasBuf(w, h);
    dst.getRGB(0, 0, w, h, cv.px, 0, w);
    quantize(cv, 20);
    if (hole) {
      int x0 = (int) Math.round(w * 0.4d), x1 = (int) Math.round(w * 0.7d), y0 = (int) Math.round(h * 0.28d);
      bufRect(cv, x0, y0, x1 - x0, h - y0, parseCol("#120d0a"), 1.0d, 0, 0, w, h);
      int edge = parseCol("#e8dcc0");
      for (int y = y0; y < h; y += 3) {
        bufRect(cv, x0 - 1, y, 1, 2, edge, 1.0d, 0, 0, w, h);
        bufRect(cv, x1, y + 1, 1, 2, edge, 1.0d, 0, 0, w, h);
      }
      for (int x = x0; x < x1; x += 3) {
        bufRect(cv, x, y0 - 1, 2, 1, edge, 1.0d, 0, 0, w, h);
      }
    }
    out.put(name, cv);
  }
  return out;
}

void loadImages() {
  Object[][] bgs = {
    { "field", 0.758d }, { "forest", 0.755d }, { "house", 0.755d },
    { "hall", 0.805d }, { "bath", 0.777d }, { "bed", 0.777d }, { "arena", 0.781d }
  };
  for (Object[] entry : bgs) {
    String id = (String) entry[0];
    double gf = (Double) entry[1];
    PImage pimg = loadImage(id + ".jpg");
    if (pimg == null) continue;
    BufferedImage srcBi = pimgToBuffered(pimg);
    double h = Math.max(SIM_H, SIM_G / gf);
    double w = h * pimg.width / (double) pimg.height;
    BufferedImage dst = new BufferedImage(SIM_W, SIM_H, BufferedImage.TYPE_INT_ARGB);
    Graphics2D g2 = dst.createGraphics();
    g2.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
    g2.drawImage(srcBi, (int) Math.round((SIM_W - w) / 2.0d), 0, (int) Math.round(w), (int) Math.round(h), null);
    g2.dispose();
    CanvasBuf cv = new CanvasBuf(SIM_W, SIM_H);
    dst.getRGB(0, 0, SIM_W, SIM_H, cv.px, 0, SIM_W);
    quantize(cv, 12);
    BG.put(id, cv);
  }
  PImage nwPimg = loadImage("nachtwacht.png");
  if (nwPimg != null) {
    BufferedImage nwBi = pimgToBuffered(nwPimg);
    NW = buildPainting(nwBi, false);
    NWH = buildPainting(nwBi, true);
  }
  builtBg.clear();
}

void drawFrameOn(CanvasBuf c, int x, int y, CanvasBuf img) {
  int w = img != null ? img.w : 84, h = img != null ? img.h : 54;
  bufRect(c, x - 4, y - 4, w + 8, h + 8, parseCol("#6a4a10"), 1.0d, 0, 0, c.w, c.h);
  bufRect(c, x - 3, y - 3, w + 6, h + 6, parseCol("#d8b040"), 1.0d, 0, 0, c.w, c.h);
  bufRect(c, x - 3, y - 3, w + 6, 1, parseCol("#f4dc80"), 1.0d, 0, 0, c.w, c.h);
  bufRect(c, x - 3, y - 3, 1, h + 6, parseCol("#f4dc80"), 1.0d, 0, 0, c.w, c.h);
  bufRect(c, x - 1, y - 1, w + 2, h + 2, parseCol("#6a4a10"), 1.0d, 0, 0, c.w, c.h);
  if (img != null) {
    for (int py = 0; py < h; py++) {
      System.arraycopy(img.px, py * w, c.px, (y + py) * c.w + x, w);
    }
  } else {
    bufRect(c, x, y, w, h, parseCol("#2a1c10"), 1.0d, 0, 0, c.w, c.h);
  }
}

CanvasBuf buildMuseum(boolean hole) {
  CanvasBuf cv = new CanvasBuf(SIM_W, SIM_H);
  bufRect(cv, 0, 0, SIM_W, SIM_H, parseCol("#1a2230"), 1.0d, 0, 0, SIM_W, SIM_H);
  for (int y = 0; y < SIM_G; y += 12) {
    bufRect(cv, 0, y, SIM_W, 12, parseCol(y % 24 != 0 ? "#1c2534" : "#18202c"), 1.0d, 0, 0, SIM_W, SIM_H);
  }
  for (int i = 0; i < 9; i++) {
    bufRect(cv, 70 + i * 9, 30 + i * 18, 60, 18, parseCol("#243044"), 1.0d, 0, 0, SIM_W, SIM_H);
  }
  bufRect(cv, 0, SIM_G - 14, SIM_W, 14, parseCol("#0e1420"), 1.0d, 0, 0, SIM_W, SIM_H);
  bufRect(cv, 0, SIM_G, SIM_W, SIM_H - SIM_G, parseCol("#2c2420"), 1.0d, 0, 0, SIM_W, SIM_H);
  for (int y = SIM_G; y < SIM_H; y += 9) {
    bufRect(cv, 0, y, SIM_W, 1, parseCol("#3a302a"), 1.0d, 0, 0, SIM_W, SIM_H);
    for (int x = (y * 7) % 40; x < SIM_W; x += 40) {
      bufRect(cv, x, y, 1, 9, parseCol("#3a302a"), 1.0d, 0, 0, SIM_W, SIM_H);
    }
  }
  bufRect(cv, 0, SIM_G, SIM_W, 2, parseCol("#4a4034"), 1.0d, 0, 0, SIM_W, SIM_H);
  HashMap<String, CanvasBuf> set = hole ? NWH : NW;
  drawFrameOn(cv, 165, 60, set != null ? set.get("big") : null);
  bufRect(cv, 215, 166, 50, 7, parseCol("#d8b040"), 1.0d, 0, 0, SIM_W, SIM_H);
  bufRect(cv, 217, 168, 46, 3, parseCol("#3a2a10"), 1.0d, 0, 0, SIM_W, SIM_H);
  return cv;
}

void bg(String id) {
  if ("museum".equals(id) || "museum2".equals(id)) {
    if (!builtBg.containsKey(id)) builtBg.put(id, buildMuseum("museum2".equals(id)));
    drawImageBuf(frameBuf, builtBg.get(id), ctxTx, ctxTy, false, ctxAlpha, 1);
    blit("rope", 150, SIM_G);
    blit("rope", 330, SIM_G);
    R(151, SIM_G - 15, 178, 1, "#a02030");
    return;
  }
  CanvasBuf cv = BG.get(id);
  if (cv != null) drawImageBuf(frameBuf, cv, ctxTx, ctxTy, false, ctxAlpha, 1);
  else {
    R(0, 0, SIM_W, SIM_G, "#0a0a24");
    R(0, SIM_G, SIM_W, SIM_H - SIM_G, "#763b2e");
  }
}

void flame(double x, double y, int t, boolean small) {
  int f = (t / 5) % 3;
  if (small) {
    R(x - 1, y - 4 - (f == 1 ? 1 : 0), 3, 4 + (f == 1 ? 1 : 0), "#f8a020");
    R(x, y - 3, 1, 3, "#fff4b0");
  } else {
    blit("fire" + f, x, y);
  }
}

void hallDecor(SceneVars v, int t, boolean lit) {
  blit("door", 14, SIM_G);
  blit("door", 464, SIM_G);
  CanvasBuf sm = NWH != null ? NWH.get("small") : null;
  int fx = 203, fy = 96;
  int fw = sm != null ? sm.w : 84, fh = sm != null ? sm.h : 54;
  R(fx - 4, fy - 4, fw + 8, fh + 8, "#6a4a10");
  R(fx - 3, fy - 3, fw + 6, fh + 6, "#d8b040");
  R(fx - 3, fy - 3, fw + 6, 1, "#f4dc80");
  R(fx - 3, fy - 3, 1, fh + 6, "#f4dc80");
  R(fx - 1, fy - 1, fw + 2, fh + 2, "#6a4a10");
  if (sm != null) drawImageBuf(frameBuf, sm, fx + ctxTx, fy + ctxTy, false, ctxAlpha, 1);
  else R(fx, fy, fw, fh, "#2a1c10");

  blit("table", 60, SIM_G);
  ArrayList<Candle> cs;
  if (v != null && !v.c.isEmpty()) cs = v.c;
  else {
    cs = new ArrayList<Candle>();
    cs.add(new Candle(60, 192, 1));
    cs.add(new Candle(168, 152, 1));
    cs.add(new Candle(312, 182, 1));
    cs.add(new Candle(398, 130, 1));
  }
  for (Box s : SC.get("hall").solids) blit(s.k, s.x, s.y);
  for (int i = 0; i < cs.size(); i++) {
    Candle c = cs.get(i);
    if (i > 0) {
      R(c.x - 4, c.y + 2, 9, 2, "#8a6a20");
      R(c.x - 1, c.y + 4, 2, 5, "#8a6a20");
    }
    blit("candle", c.x, c.y + 4);
    if (c.lit != 0 || lit) flame(c.x, c.y - 5, t + i * 7, true);
  }
}

void punchDisc(CanvasBuf c, double cx, double cy, int r, double k) {
  double mult = 1.0d - k;
  int icx = (int) Math.round(cx), icy = (int) Math.round(cy);
  for (int dy = -r; dy <= r; dy++) {
    int py = icy + dy;
    if (py < 0 || py >= c.h) continue;
    int dx = (int) Math.floor(Math.sqrt(r * r - dy * dy) + 0.5d);
    int x0 = Math.max(0, icx - dx), x1 = Math.min(c.w - 1, icx + dx);
    int row = py * c.w;
    for (int px = x0; px <= x1; px++) {
      int p = c.px[row + px];
      int a = (int) Math.round(((p >>> 24) & 255) * mult);
      c.px[row + px] = (a << 24) | (p & 0xFFFFFF);
    }
  }
}

void darknessHole(CanvasBuf c, double x, double y, int r, int t) {
  int fl = (int) Math.round(Math.sin(t * 0.13d + x * 0.7d) * 1.4d + Math.sin(t * 0.37d + y) * 0.9d);
  punchDisc(c, x, y, r + fl, 0.4d);
  punchDisc(c, x, y, (int) Math.round(r * 0.72d), 0.5d);
  punchDisc(c, x, y, (int) Math.round(r * 0.45d), 0.8d);
}

void darkness(GameState S, int t) {
  SceneVars v = S.v;
  if (darkCv == null) darkCv = new CanvasBuf(SIM_W, SIM_H);
  int baseA = Math.max(0, Math.min(255, (int) Math.round((0.94d - v.lit * 0.2d) * 255.0d)));
  int baseCol = (baseA << 24) | (4 << 16) | (4 << 8) | 14;
  java.util.Arrays.fill(darkCv.px, baseCol);
  for (Candle k : v.c) if (k.lit != 0) darknessHole(darkCv, k.x, k.y, 46, t);
  for (Player p : S.players) darknessHole(darkCv, p.x, p.y - 16, p.carry > 0 ? 36 : 15, t);
  drawImageBuf(frameBuf, darkCv, ctxTx, ctxTy, false, ctxAlpha, 1);
}

void chaseBack(SceneVars v) {
  double d = v.dist;
  for (int i = 0; i < 8; i++) {
    double x = (((i * 97 - d * 0.35d) % 620.0d) + 620.0d) % 620.0d - 70.0d;
    R(x + 9, SIM_G - 44, 5, 44, "#161a2c");
    disc(frameBuf, x + 11, SIM_G - 50, 14, "#161a2c");
  }
  for (int i = 0; i < 7; i++) {
    double x = (((i * 80 - d) % 560.0d) + 560.0d) % 560.0d - 40.0d;
    R(x, SIM_G - 14, 3, 14, "#4a2c20");
    R(x - 1, SIM_G - 15, 5, 2, "#6a4030");
    R(x + 3, SIM_G - 10, 77, 1, "#3a2018");
  }
  for (int i = 0; i < 26; i++) {
    double x = (((i * 53 - d) % 520.0d) + 520.0d) % 520.0d - 20.0d;
    int y = SIM_G + 6 + (i * 37) % 44;
    R(x, y, 4 + (i % 3) * 2, 1, i % 2 != 0 ? "#5e2e24" : "#8a4a3a");
  }
}

String zPose(GameState S, Player p) {
  if (p.down > 0) return "down";
  if (p.inv > 0 && Math.abs(p.kb) > 0.3d) return "hurt";
  if (p.bite > 0) return p.bite > 13 ? "biteo" : "bitec";
  if (!p.g) return "jump";
  if (fxSquash(p.id)) return "land";
  boolean run = SC.containsKey(S.scene) && SC.get(S.scene).running;
  if (Math.abs(p.vx) > 0.2d || run) return "w" + ((S.tick / 5) % 6);
  return (((S.tick + p.id * 53) % 200 < 7) ? "blink" : "idle") + ((S.tick / 30 + p.id) % 2);
}

void headGag(Player p, int gt) {
  boolean f = p.face < 0;
  String k = "z" + p.id + "_";
  double hx = p.x, hy = p.y - 19;
  if (gt < 24) {
    double q = gt / 24.0d;
    hx = p.x + p.face * q * 10.0d;
    hy = p.y - 19 + Math.round(19.0d * q * q);
  } else if (gt < 70) {
    hx = p.x + p.face * 10;
    hy = p.y - (gt < 32 ? Math.round(Math.sin((gt - 24) / 8.0d * Math.PI) * 4.0d) : 0);
  } else {
    double q = (gt - 70) / 30.0d;
    hx = p.x + p.face * 10.0d * (1.0d - q);
    hy = p.y - Math.round(19.0d * q);
  }
  blit(k + "headless", p.x, p.y, f);
  blit(k + "head", hx, hy, f);
}

void drawPlayers(GameState S, int t) {
  for (Player p : S.players) {
    if (p.inv > 0 && p.down == 0 && (t / 10) % 2 != 0) continue;
    String pose = zPose(S, p);
    int gt = p.idle - IDLE_GAG;
    boolean gold = p.gold > 0 && !"down".equals(pose) && (p.gold > 120 || (t / 10) % 2 != 0);
    if (gt >= 0 && gt < 100 && (pose.startsWith("idle") || pose.startsWith("blink"))) headGag(p, gt);
    else blit("z" + p.id + (gold ? "g" : "") + "_" + pose, p.x, p.y, p.face < 0);
    if (gold) {
      for (int i = 0; i < 3; i++) {
        double sx = p.x + ((t * 7 + i * 37) % 22) - 11;
        double sy = p.y - 6 - ((t * 3 + i * 19) % 28);
        R(sx, sy, 1, 1, "#fff8c0");
        if ((t + i * 5) % 12 < 4) {
          R(sx - 1, sy, 3, 1, "#fff8c0");
          R(sx, sy - 1, 1, 3, "#fff8c0");
        }
      }
    }
    if (p.chick > 0 && p.down == 0 && (p.chick > 120 || (t / 10) % 2 != 0) && !(gt >= 0 && gt < 100) && !"hurt".equals(pose)) {
      int al = pose.startsWith("bite") ? 12 : "jump".equals(pose) ? 9 : 8;
      int b = "idle1".equals(pose) || "blink1".equals(pose) || "land".equals(pose) ? 1 : 0;
      blit("pu_chick", p.x + p.face * (5 + al), p.y - 3 + b, p.face < 0);
    }
    if (p.carry > 0 && (p.carry > 120 || (t / 10) % 2 != 0)) flame(p.x + p.face * 12, p.y - 17, t, false);
    if (p.down > 0 && S.two) T(String.valueOf(Math.max(0, (int) Math.ceil((240 - p.down) / 60.0d))), p.x, p.y - 26, "#ffffff", "ps", 1);
  }
}

ArrayList<CrowdSeat> crowdSeats() {
  if (CROWD != null) return CROWD;
  CROWD = new ArrayList<CrowdSeat>();
  long[] seed = { 7L };
  int[] rows = { 170, 151, 133 };
  for (int row = 0; row < rows.length; row++) {
    int y = rows[row];
    seed[0] = (seed[0] * 16807L) % 2147483647L;
    int x = 10 + row * 7 + (int) Math.floor((seed[0] / 2147483647.0d) * 8);
    while (x < SIM_W - 6) {
      seed[0] = (seed[0] * 16807L) % 2147483647L;
      double r1 = seed[0] / 2147483647.0d;
      if (r1 >= 0.18d) {
        seed[0] = (seed[0] * 16807L) % 2147483647L;
        double r2 = seed[0] / 2147483647.0d;
        int s = 0;
        if (r2 < 0.22d) s = 1;
        else {
          seed[0] = (seed[0] * 16807L) % 2147483647L;
          double r3 = seed[0] / 2147483647.0d;
          if (r3 < 0.28d) s = 2;
        }
        seed[0] = (seed[0] * 16807L) % 2147483647L;
        int dy = (int) Math.floor((seed[0] / 2147483647.0d) * 3);
        seed[0] = (seed[0] * 16807L) % 2147483647L;
        int ph = (int) Math.floor((seed[0] / 2147483647.0d) * 120);
        seed[0] = (seed[0] * 16807L) % 2147483647L;
        boolean f = (seed[0] / 2147483647.0d) < 0.5d;
        CROWD.add(new CrowdSeat(x, y + dy, s, ph, f));
      }
      seed[0] = (seed[0] * 16807L) % 2147483647L;
      x += 15 + (int) Math.floor((seed[0] / 2147483647.0d) * 20);
    }
  }
  return CROWD;
}

void ghosts(GameState S, HashMap<String, String> tx, int t) {
  SceneVars v = S.v;
  double wavePos = v.wave > 0 ? (150 - v.wave) / 150.0d * (SIM_W + 60) - 30 : -999;
  ArrayList<CrowdSeat> seats = crowdSeats();
  for (int i = 0; i < seats.size(); i++) {
    CrowdSeat c = seats.get(i);
    if ("giant".equals(S.scene) && c.x > WC_X - 24) continue;
    boolean inWave = Math.abs(c.x - wavePos) < 24;
    int mood = v.boo > 0 ? 2 : (v.cheer > 0 || inWave) ? 1 : 0;
    int up = inWave ? 5 : v.cheer > 0 ? (((t / 5) + i) % 2) * 2 : (((t + c.ph * 7) / 45) % 3 == 0 ? 1 : 0);
    blit("ghost" + c.s + mood, c.x, c.y - up, c.f, 0.55d);
  }
  if (v.cheer > 0) {
    T(tx.get("cheer"), 110, 104, "#e4ecff", "ps", 1);
    T(tx.get("cheer"), 330, 112, "#e4ecff", "ps", 1);
  } else if (v.boo > 0) {
    T(tx.get("boo"), 130, 106, "#e4ecff", "ps", 1);
    T(tx.get("boo"), 310, 110, "#e4ecff", "ps", 1);
  }
}

void drawShadow(double x, int w, double a) {
  String c = "rgba(30,10,6," + String.format(java.util.Locale.US, "%.2f", a) + ")";
  R(x - w / 2.0d, SIM_G - 1, w, 5, c);
  R(x - w / 2.0d + 3, SIM_G - 2, w - 6, 7, c);
}

void drawScene(GameState S, int t, HashMap<String, String> tx) {
  SceneVars v = S.v;
  String id = S.scene;
  SceneDef sc = SC.get(id);
  bg("chase".equals(id) ? "field" : "giant".equals(id) ? "arena" : id);
  fxBack(S, t);
  if ("chase".equals(id)) chaseBack(v);
  if ("arena".equals(id) || "giant".equals(id)) ghosts(S, tx, t);
  if ("field".equals(id)) {
    blit("grave", 30, SIM_G);
    blit("grave", 52, SIM_G);
    blit("gate" + Math.max(0, v.gate), 398, SIM_G);
  }
  if ("hall".equals(id)) hallDecor(v, t, false);
  else for (Box s : sc.solids) blit(s.k, s.x, s.y);
  for (int i = 0; i < sc.plats.length; i++) {
    Box p = sc.plats[i];
    blit("branch", p.x, p.y + fxDip(i));
  }
  if ("forest".equals(id)) {
    for (Scrap s : v.sc) {
      if (s.got == 0) {
        blit("scrap" + ((t / 12) % 2), s.x, s.y + Math.round(Math.sin(t / 15.0d + s.x) * 1.5d));
      }
    }
  }
  if ("house".equals(id) && v.key && (t / 20) % 2 != 0) T("v", DOOR, 150, "#f8d040", "ps", 1);
  if ("bath".equals(id)) {
    blit(v.roll != 0 ? "roll0" : "roll1", ROLL_X, 198);
    if (v.roll != 0) {
      R(ROLL_X + 1, 201, 3, SIM_G - 201, "#f4f4f4");
      int len = (int) Math.round(v.paper);
      R(ROLL_X + 4 - len, SIM_G - 2, len, 2, "#f4f4f4");
      for (int x = ROLL_X - 4; x > ROLL_X + 4 - len; x -= 8) R(x, SIM_G - 2, 1, 2, "#c8ccd8");
    }
  }
  if ("bed".equals(id)) {
    blit("poster", 300, 68);
    T(tx.get("wanted"), 331, 70, "#7a2010", "ps", 1, 1, false);
    for (BedDuck d : v.d) blit("duck", d.x, SIM_G - (d.cd > 40 ? 1 : 0));
    blit("listen".equals(v.ph) ? "bed_awake" : "bed_sleep", 392, SIM_G);
    if ("snore".equals(v.ph)) {
      for (int i = 0; i < 3; i++) {
        double ph = (t / 80.0d + i / 3.0d) % 1.0d;
        ctxAlpha = Math.sin(ph * Math.PI) * 0.7d;
        T("Z", 420 + Math.round(ph * 14), 172 - Math.round(ph * 32), "#e8ecff", "ps", 0, 1, false);
      }
      ctxAlpha = 1.0d;
      String s = tx.get("s_" + v.mum);
      if (s != null) {
        int w = textImg(s, "vt", "#2a2a5a").w;
        T(s, Math.min(400.0d, SIM_W - 4 - w / 2.0d), 126, "#2a2a5a", "vt", 1, 1, false);
      }
    } else if ("stir".equals(v.ph)) T("?", 418, 158, "#f8d040", "ps", 0, 2);
    else T("!", 418, 150, "#ff4040", "ps", 0, 2);
  }
  if ("chase".equals(id)) {
    String k = v.thr > 8 ? "throw" : v.thr > 0 ? "stumble" : "r" + ((t / 5) % 4) + (t % 280 < 50 ? "l" : "");
    blit("tp_" + k, 432, SIM_G, v.thr > 8);
    if (t % 420 < 80) {
      String[] shouts = { "t_go", "t_help", "t_mama" };
      bubble(432, SIM_G - 34, tx.get(shouts[(t / 420) % 3]));
    }
  }
  if ("giant".equals(id)) {
    blit("wc_open", WC_X + (v.wsT > 0 ? (t / 4) % 2 : 0), WC_Y - (v.wt > 0 ? 3 : 0));
    blit("roll", 22, SIM_G);
    for (Ent e : S.ents) {
      if ("stone".equals(e.type)) {
        drawShadow(e.x, 8 + (int) Math.round(Math.max(0.0d, Math.min(1.0d, (e.y - 50.0d) / (SIM_G - 50.0d))) * 8.0d), 0.5d);
      } else if ("giant".equals(e.type) && "fist".equals(e.st) && e.t < FIST_UP) {
        double k = e.t / (double) FIST_UP;
        int w = 16 + (int) Math.round(k * 14);
        drawShadow(e.fx, w, 0.3d + 0.3d * k);
        if (e.t > FIST_UP - 16 && (t / 10) % 2 != 0) {
          R(e.fx - w / 2.0d, SIM_G - 2, 2, 7, "#e8304a");
          R(e.fx + w / 2.0d - 2, SIM_G - 2, 2, 7, "#e8304a");
        }
      }
    }
  }

  for (Ent e : S.ents) {
    boolean a = (t / 10) % 2 != 0;
    if ("bat".equals(e.type) || "cbat".equals(e.type)) {
      blit("bat" + ((t / 5) % 2), e.x, e.y);
    } else if ("crow".equals(e.type)) {
      if (e.inv > 0 && a) continue;
      blit("crow" + ((t / 7) % 2), e.x, e.y, e.dir < 0);
      if (e.hp > 0) blit("key", e.x + e.dir * 8, e.y + 3);
    } else if ("key".equals(e.type)) {
      blit("key", e.x, e.y + Math.round(Math.sin(t / 8.0d)));
    } else if ("pow".equals(e.type)) {
      int bob = (e.air || e.vx != 0) ? 0 : (int) Math.round(Math.sin(t / 10.0d + e.x) * 1.5d) - 1;
      if ("chick".equals(e.kind)) blit("pu_chick", e.x, e.y + bob);
      else blit("pu_" + e.kind, e.x, e.y + bob);
      if (((int) Math.floor((t + e.x) / 16.0d)) % 3 == 0) R(e.x + 4, e.y - 15 + bob, 1, 1, "#ffffff");
    } else if ("gnome".equals(e.type)) {
      blit("run".equals(e.st) ? "gnome" + (1 + (t / 4) % 2) : "gnome0", e.x, SIM_G, e.dir < 0);
      if ("run".equals(e.st) && e.t < 50) T("!", e.x, SIM_G - 36, "#ffffff", "ps", 1);
    } else if ("rat".equals(e.type)) {
      blit("rat" + ((t / 4) % 2), e.x, SIM_G, e.dir < 0);
    } else if ("wc".equals(e.type)) {
      boolean isOpen = "spit".equals(e.st) || "tired".equals(e.st);
      int sx = ("laugh".equals(e.st) || "flush".equals(e.st)) ? (t / 3) % 2 : 0;
      String key = "ouch".equals(e.st) ? "wc_hurt" : "tired".equals(e.st) ? "wc_tired" : isOpen ? "wc_open" : "wc_closed";
      if (e.inv >= 28) blitWhite(key, e.x + sx, SIM_G);
      else if (!(e.inv > 0 && a)) blit(key, e.x + sx, SIM_G);
      if ("laugh".equals(e.st)) {
        String[] laughs = { "HA", "HA HA", "HA HA HA" };
        T(laughs[(e.t / 12) % 3], e.x - 4, 150 - ((t / 6) % 2), "#ffffff", "ps", 1);
      }
      if ("flush".equals(e.st) && e.t < 40) {
        for (int i = 0; i < 3; i++) R(e.x - 14 - i * 5 - (t % 6), SIM_G - 4 - i * 3, 3, 1, "#7ec8f0");
        T("!", e.x, 154, "#7ec8f0", "ps", 1, 2);
      }
    } else if ("blob".equals(e.type)) {
      blit("blob", e.x, e.y);
    } else if ("wave".equals(e.type) || "shock".equals(e.type)) {
      blit("wave".equals(e.type) ? "wave" + ((t / 6) % 2) : "shock", e.x, SIM_G, e.vx > 0);
    } else if ("rock".equals(e.type)) {
      blit("rock", e.x, e.y);
    } else if ("pillow".equals(e.type)) {
      blit("pillow", e.x, e.y);
    } else if ("lamp".equals(e.type)) {
      blit("lamp", e.x, e.y);
    } else if ("log".equals(e.type)) {
      blit("log", e.x, SIM_G);
    } else if ("fire".equals(e.type)) {
      blit("fire" + ((t / 5) % 3), e.x, SIM_G);
    } else if ("fball".equals(e.type)) {
      blit("fire" + ((t / 4) % 3), e.x, e.y + 6);
    } else if ("thief".equals(e.type)) {
      boolean flash = e.inv >= 33;
      if (e.inv > 0 && a && !flash) continue;
      String set = "tp" + (e.hp > 700 ? "" : e.hp > 350 ? "1" : "2") + "_";
      String k = "stand";
      if ("pant".equals(e.st)) k = "itch" + ((t / 6) % 2);
      else if (!e.g) k = "scared";
      else if ("atk".equals(e.st)) k = (e.t % 55) > 15 && (e.t % 55) < 35 ? "throw" : "stand";
      else if (Math.abs(e.vx) > 0.1d) k = "r" + ((t / 5) % 4);
      if (flash) blitWhite(set + k, e.x, e.y, e.face < 0);
      else blit(set + k, e.x, e.y, e.face < 0);
      if ("pant".equals(e.st)) T("...", e.x, e.y - 44, "#ffffff", "ps", 1);
    } else if ("giant".equals(e.type)) {
      String k = "w0";
      if ("walk".equals(e.st)) k = e.mv ? "w" + (((int) Math.floor(e.walk / 6.0d)) % 4) : "b" + ((t / 40) % 2);
      else if ("stomp".equals(e.st)) k = e.t < STOMP_UP ? "footup" : "stomp";
      else if ("fist".equals(e.st)) k = e.t < FIST_UP ? "fistup" : "fistdown";
      else if ("slip".equals(e.st)) k = "slip";
      else if ("down".equals(e.st)) k = "lie";
      else if ("getup".equals(e.st)) k = "getup";
      else if ("roar".equals(e.st)) k = "roar";
      if ("down".equals(e.st) && e.inv >= 33) blitWhite("g_" + k, e.x, SIM_G, e.face < 0);
      else if (!("down".equals(e.st) && e.inv > 0 && e.inv < 25 && a)) blit("g_" + k, e.x, SIM_G, e.face < 0);
      if ("down".equals(e.st)) {
        double hx = e.x - e.face * 48;
        for (int i = 0; i < 3; i++) {
          double an = t / 9.0d + i * 2.1d;
          R(hx + Math.cos(an) * 12.0d - 1, SIM_G - 36 + Math.sin(an) * 3.0d, 3, 3, "#f8d040");
        }
        for (int i = 0; i < MAX_BITES; i++) R(hx - 12 + i * 5, SIM_G - 46, 3, 3, i < e.bites ? "#3a3040" : "#ffffff");
      }
    } else if ("duck".equals(e.type)) {
      blit("duck", e.x, "ground".equals(e.st) ? SIM_G : e.y, "fly".equals(e.st) ? ((t / 4) % 2 == 0) : e.vx < 0);
    } else if ("stone".equals(e.type)) {
      blit("stone", e.x, e.y);
    }
  }
  drawPlayers(S, t);
  fxFront(S, t, tx);
  if ("hall".equals(id)) darkness(S, t);
  if ("arena".equals(id) || "giant".equals(id)) {
    R(0, 0, SIM_W, SIM_H, "rgba(255,150,60," + String.format(java.util.Locale.US, "%.3f", Math.min(1.0d, v.sun) * 0.32d) + ")");
  }
}

// ---------------------------------------------------------------- HUD
void bar(double x, double y, double w, double h, double f, String col, String back) {
  R(x - 1, y - 1, w + 2, h + 2, "#0c0a16");
  R(x, y, w, h, back != null ? back : "#2a2438");
  R(x, y, Math.round(w * Math.max(0.0d, Math.min(1.0d, f))), h, col);
}

void bar(double x, double y, double w, double h, double f, String col) {
  bar(x, y, w, h, f, col, null);
}

void label(String s, double x, double y, String col, String font, int align) {
  if (s == null || s.isEmpty()) return;
  int w = textImg(s, font, col).w;
  double lx = align == 1 ? x - w / 2.0d : align == 2 ? x - w : x;
  if ("vt".equals(font)) R(lx - 4, y + 2, w + 7, 17, "rgba(8,8,20,0.55)");
  else R(lx - 3, y - 1, w + 5, 11, "rgba(8,8,20,0.55)");
  T(s, x, y, col, font, align);
}

void bubble(double x, double top, String s) {
  if (s == null || s.isEmpty()) return;
  String[] lines = wrap(s, "vt", 138);
  int maxLineW = 0;
  for (String l : lines) maxLineW = Math.max(maxLineW, measure(l, "vt"));
  int w = Math.min(150, maxLineW + 10);
  int h = lines.length * 13 + 6;
  int bx = (int) Math.round(Math.max(4.0d, Math.min(SIM_W - 4 - w, x - w / 2.0d)));
  int by = (int) Math.round(Math.max(40.0d, top - 6 - h));
  R(bx - 1, by - 1, w + 2, h + 2, "#0c0a16");
  R(bx, by, w, h, "#f4f4ec");
  int px = (int) Math.round(Math.max(bx + 3.0d, Math.min(bx + w - 6.0d, x - 1.0d)));
  R(px - 1, by + h + 1, 5, 1, "#0c0a16");
  R(px, by + h, 3, 1, "#f4f4ec");
  R(px, by + h + 1, 3, 1, "#f4f4ec");
  R(px + 1, by + h + 2, 1, 2, "#0c0a16");
  for (int i = 0; i < lines.length; i++) {
    T(lines[i], bx + 5, by - 2 + i * 13, "#1a1a24", "vt", 0, 1, false);
  }
}

void drawHud(GameState S, HashMap<String, String> tx, int t) {
  SceneDef sc = SC.get(S.scene);
  SceneVars v = S.v;
  int y = 6;
  for (Player p : S.players) {
    if (p.ai) continue;
    blit("z" + p.id + "_icon", 12, y + 9);
    for (int i = 0; i < 3; i++) blit(i < p.hp ? "heart" : "heart0", 22 + i * 9, y + 1);
    boolean boss = "arena".equals(S.scene) || "giant".equals(S.scene);
    int step = boss ? 25 : 32, bw = boss ? 10 : 16;
    int px = boss ? 424 : 54;
    Object[][] pows = {
      { "gold", p.gold, GOLD_T, "#f8d040" },
      { "chick", p.chick, CHICK_T, "#f4f0e8" }
    };
    for (Object[] pw : pows) {
      String kind = (String) pw[0];
      int left = (Integer) pw[1];
      int max = (Integer) pw[2];
      String col = (String) pw[3];
      if (left <= 0) continue;
      if (left > 120 || (t / 10) % 2 != 0) {
        if ("chick".equals(kind)) blit("chick_i", px + 4, y + 10);
        else blit("pu_gold", px + 3, y + 11);
        bar(px + 10, y + 4, bw, 3, left / (double) max, col);
      }
      px += step;
    }
    y += 13;
  }
  Goal g = sc.goal(S);
  String goalText = tx.get(g.k) + (g.of > 0 ? "  " + g.n + "/" + g.of : "");
  int gy = 5;
  if ("arena".equals(S.scene) || "giant".equals(S.scene)) {
    Ent th = findEnt(S, "thief");
    if (th == null) th = findEnt(S, "giant");
    int hp = th != null ? th.hp : 0;
    bar(60, 6, 360, 6, hp / 1000.0d, "#e8304a");
    label(tx.get("leven") + " " + hp, 240, 14, "#ffffff", "ps", 1);
    bar(180, 30, 120, 3, v.sun, "#f8c830");
    blit("sun", 180 + Math.round(120.0d * Math.min(1.0d, v.sun)), 31);
    label(tx.get("sun"), 176, 26, "#f8c830", "ps", 2);
    gy = 36;
  }
  label(goalText, 240, gy, "#ffffff", "vt", 1);
  if (g.bar != null) {
    bar(170, 28, 140, 4, g.bar, "#f07a18");
    label(tx.get("dist"), 316, 25, "#f07a18", "ps", 0);
  }
  if ("bed".equals(S.scene)) {
    bar(180, 28, 120, 5, v.noise / 100.0d, v.noise > 60 ? "#e8304a" : "#f8c830");
    label(tx.get("noise"), 176, 26, "#ffffff", "ps", 2);
  }
  if ("giant".equals(S.scene)) {
    Ent gEnt = findEnt(S, "giant");
    if (gEnt != null && "roar".equals(gEnt.st) && gEnt.t < 55) {
      T(tx.get("roar"), Math.max(80.0d, Math.min(SIM_W - 80.0d, gEnt.x)), SIM_G - 134 + ((t / 3) % 2), "#ffffff", "ps", 1, 2);
    }
    if (v.wsT > 0 && v.ws != null && tx.get(v.ws) != null) {
      String s = tx.get(v.ws);
      int w = textImg(s, "vt", "#7ec8f0").w + 1;
      T(s, Math.min(WC_X + w / 2.0d, SIM_W - 4.0d), 58, "#7ec8f0", "vt", 2);
    }
  }
  if (S.msgT > 0 && S.msg != null) label(tx.get(S.msg), 240, 62, "#f8d040", "vt", 1);
  boolean flushing = false;
  for (Ent e : S.ents) if ("wc".equals(e.type) && "flush".equals(e.st) && e.t < 60) { flushing = true; break; }
  if (S.talk != null && "play".equals(S.mode) && !flushing && S.talk.who >= 0 && S.talk.who < S.players.length && tx.get(S.talk.k) != null) {
    Player p = S.players[S.talk.who];
    bubble(p.x, p.y - 34, tx.get(S.talk.k));
  }
  if (S.hint != null && tx.get(S.hint) != null) {
    String s = tx.get(S.hint);
    int w = measure(s, "vt");
    boolean hot = "h_still".equals(S.hint);
    R(240 - w / 2.0d - 6, 248, w + 12, 18, hot ? "rgba(160,20,30,0.85)" : "rgba(8,8,20,0.7)");
    T(s, 240, 246, hot && (t / 10) % 2 != 0 ? "#ffd0d0" : "#ffffff", "vt", 1);
  }
}

// ---------------------------------------------------------------- cutscenes
void drawCut(GameState S, HashMap<String, String> tx, int t) {
  CutState c = S.cut;
  CutStep st = CUTS.get(c.id)[c.i];
  if (st.card > 0) {
    R(0, 0, SIM_W, SIM_H, "#07060e");
    ctxAlpha = Math.min(1.0d, c.t / 25.0d);
    T(tx.get("chapter") + " " + st.card, 240, 96, "#9a94b8", "ps", 1, 1, false);
    T(tx.get("ch" + st.card), 240, 116, "#ffffff", "ps", 1, 2);
    R(160, 144, 160, 1, "#c0302a");
    blit("z0_idle0", 226, 190);
    blit("z1_idle0", 248, 190);
    ctxAlpha = 1.0d;
    return;
  }
  String base = "hall_lit".equals(st.bg) ? "hall" : "arena_dawn".equals(st.bg) ? "arena" : st.bg;
  bg(base);
  if ("hall_lit".equals(st.bg)) hallDecor(null, t, true);
  if ("field".equals(st.bg)) {
    blit("grave", 30, SIM_G);
    blit("grave", 52, SIM_G);
    blit("tomb", 140, 200);
    blit("tomb2", 245, 194);
    blit("gate3", 398, SIM_G);
  }
  if ("house".equals(st.bg)) {
    for (Box s : SC.get("house").solids) blit(s.k, s.x, s.y);
  }
  if ("arena_dawn".equals(st.bg)) {
    R(0, 0, SIM_W, SIM_H, "rgba(255,150,60,0.3)");
  }
  int[] spx = null;
  for (CutActor a : st.a) {
    String kind = a.kind, pose = a.pose, look = a.look;
    int x = a.x;
    boolean flip = a.flip;
    boolean speaks = ("z1".equals(st.who) && "z0".equals(kind)) ||
                     ("z2".equals(st.who) && "z1".equals(kind)) ||
                     ("t".equals(st.who) && ("thief".equals(kind) || ("bed".equals(kind) && "awake".equals(pose)))) ||
                     ("wc".equals(st.who) && ("wc".equals(kind) || "wcs".equals(kind))) ||
                     ("g".equals(st.who) && ("giant".equals(kind) || "grow".equals(kind)));
    if ("z0".equals(kind) || "z1".equals(kind)) {
      if ("rise".equals(pose)) {
        double up = Math.max(0.0d, 34.0d - c.t * 0.6d);
        ctxSave();
        clipY1 = SIM_G;
        blit(kind + "_idle0", x + (up > 0 ? (t / 3) % 2 : 0), SIM_G + up, flip);
        ctxRestore();
      } else {
        blit(kind + "_" + ("bite".equals(pose) ? "bite" : "idle" + ((t / 30) % 2)), x, SIM_G, flip);
      }
      if (speaks) spx = new int[] { x, SIM_G - 44 };
    } else if ("thief".equals(kind)) {
      boolean away = "run".equals(pose) || "flee".equals(pose);
      String k = "run".equals(pose) ? "r" + ((t / 5) % 4) : ("flee".equals(pose) || "giveup".equals(pose)) ? "scared2" : "itch".equals(pose) ? "itch" + ((t / 6) % 2) : pose;
      double dx = away ? Math.min("flee".equals(pose) ? 220.0d : 60.0d, c.t * 1.8d) : 0;
      double dy = "flee".equals(pose) ? (t / 4) % 2 : "ouch".equals(pose) ? Math.round(Math.abs(Math.sin(c.t / 7.0d)) * 8.0d) : 0;
      blit("t" + (look != null ? look : "") + "_" + k, x + dx, SIM_G - dy, flip);
      if (speaks) spx = new int[] { x, SIM_G - 40 };
    } else if ("giant".equals(kind) || "grow".equals(kind)) {
      boolean big = "giant".equals(kind) || c.t > 100 || ((int) Math.floor(c.t / Math.max(10.0d, 20.0d - c.t / 10.0d))) % 2 == 1;
      String k = "walk".equals(pose) ? "w" + ((t / 8) % 4) : (pose != null && !pose.isEmpty() ? pose : "w0");
      int head = x + (flip ? 48 : -48);
      if (!big) blit("tp2_itch" + ((t / 6) % 2), x, SIM_G, flip);
      else blit("g_" + k, x, SIM_G, flip);
      if (big && "lie".equals(k)) {
        for (int i = 0; i < 3; i++) {
          double an = t / 9.0d + i * 2.1d;
          R(head + Math.cos(an) * 12.0d - 1, SIM_G - 36 + Math.sin(an) * 3.0d, 3, 3, "#f8d040");
        }
      }
      if (big && "dust".equals(k)) {
        for (int i = 0; i < 10; i++) {
          double py = SIM_G - 6 - ((c.t * 0.4d + i * 11) % 60.0d);
          double px = x - 40 + ((i * 23) % 80) + Math.round(Math.sin((c.t + i * 20) / 15.0d) * 3.0d);
          R(px, py, 2, 2, i % 3 != 0 ? "#aeb08c" : GC_SKIN);
        }
      }
      if (speaks) spx = "lie".equals(k) ? new int[] { head, SIM_G - 44 } : new int[] { x, SIM_G - 128 };
    } else if ("wcs".equals(kind)) {
      int j = "laugh".equals(pose) ? (t / 4) % 2 : 0;
      blit("wc_" + ("laugh".equals(pose) ? "open" : pose), x, WC_Y - j);
      if (speaks) spx = new int[] { x, WC_Y - 58 };
    } else if ("beam".equals(kind)) {
      int end = Math.min(SIM_G, c.t * 5);
      for (int y = 0; y < end; y += 2) {
        double bx = x + (SIM_G - y) * 0.6d;
        R(bx - 10, y, 20, 2, "rgba(255,236,150,0.38)");
        R(bx - 4, y, 8, 2, "rgba(255,250,220,0.5)");
      }
    } else if ("wc".equals(kind)) {
      boolean laughs = "laugh".equals(pose) || "plaster".equals(pose);
      int j = laughs ? (t / 4) % 2 : 0;
      blit("wc_" + (laughs ? "open" : pose), x, SIM_G - j);
      if ("plaster".equals(pose)) {
        R(x - 54, SIM_G - 80, 20, 16, "#d8b040");
        R(x - 52, SIM_G - 78, 16, 12, "#2a1c10");
        blit("plaster", x - 44, SIM_G - 72);
      }
      if (speaks) spx = new int[] { x, SIM_G - 56 };
    } else if ("bed".equals(kind)) {
      blit("bed_" + pose, 392, SIM_G);
      if ("sleep".equals(pose)) {
        int k = (t / 20) % 3;
        for (int i = 0; i <= k; i++) T("Z", 420 + i * 8, 170 - i * 10, "#ffffff", "ps");
      }
      if (speaks) spx = new int[] { 400, SIM_G - 52 };
    } else if ("roll".equals(kind)) {
      blit("roll", x, SIM_G);
    }
  }
  if (spx != null) {
    int b = (t / 10) % 2;
    R(spx[0] - 2, spx[1] + b, 5, 2, "#f8d040");
    R(spx[0] - 1, spx[1] + 2 + b, 3, 1, "#f8d040");
    R(spx[0], spx[1] + 3 + b, 1, 1, "#f8d040");
  }

  R(0, 256, SIM_W, 14, "#07060e");
  R(8, 8, 464, 70, "rgba(10,10,26,0.93)");
  R(8, 8, 464, 1, "#ebe8da");
  R(8, 77, 464, 1, "#ebe8da");
  R(8, 8, 1, 70, "#ebe8da");
  R(471, 8, 1, 70, "#ebe8da");
  String who = tx.get("who_" + st.who);
  String full = tx.get(st.k);
  int ty = 12;
  if (who != null && !who.isEmpty()) {
    String wc = "t".equals(st.who) ? "#f07a18" : "wc".equals(st.who) ? "#7ec8f0" : "g".equals(st.who) ? GC_LT : "#63d97d";
    T(who, 18, 13, wc, "ps");
    ty = 22;
  }
  String[] lines = wrap(full, "vt", 440);
  int left = (int) Math.floor(c.t / 1.2d);
  for (int i = 0; i < lines.length; i++) {
    if (left <= 0) break;
    String ln = lines[i];
    String sub = ln.substring(0, Math.min(ln.length(), left));
    T(sub, 18, ty + i * 16, (who != null && !who.isEmpty()) ? "#ffffff" : "#cfd6ff", "vt");
    left -= ln.length() + 1;
  }
  if (c.t / 1.2d >= full.length() && (t / 20) % 2 != 0) T("> " + tx.get("next"), 462, 66, "#f8d040", "ps", 2);
}

void drawEnd(GameState S, HashMap<String, String> tx, int t) {
  R(0, 0, SIM_W, SIM_H, "#05050d");
  for (int i = 0; i < 60; i++) R((i * 131) % SIM_W, (i * 71) % 180, 1, 1, i % 3 != 0 ? "#6a6a90" : "#ffffff");
  disc(frameBuf, 240, 96, 58, "#1c4a9a");
  disc(frameBuf, 232, 88, 50, "#2a62c0");
  R(206, 70, 30, 18, "#2f9a4a");
  R(214, 88, 18, 14, "#2f9a4a");
  R(250, 96, 28, 20, "#2f9a4a");
  R(262, 76, 16, 12, "#2f9a4a");
  R(222, 120, 14, 10, "#2f9a4a");
  R(196, 100, 20, 4, "#e8f0ff");
  R(244, 62, 26, 4, "#e8f0ff");
  R(256, 128, 22, 3, "#e8f0ff");
  T(tx.get("end1"), 240, 84, "#ffffff", "ps", 1, 3);
  ctxAlpha = Math.min(1.0d, S.endT / 120.0d);
  T(tx.get("end2"), 240, 170, "#cfd6ff", "vt", 1);
  T(tx.get("end3"), 240, 194, "#63d97d", "ps", 1);
  T(tx.get("end4"), 240, 204, "#9a94b8", "vt", 1);
  ctxAlpha = 1.0d;
  blit("z0_idle" + ((t / 30) % 2), 60, 246);
  blit("z1_idle" + (((t / 30) + 1) % 2), 420, 246, true);
  if (S.endT > 180 && (t / 25) % 2 != 0) T(tx.get("end5"), 240, 226, "#f8d040", "vt", 1);
}

void credit(HashMap<String, String> tx, int t, int y) {
  String s = tx.get("credit");
  int w = measure(s, "vt");
  T(s, (t % (SIM_W + w)) - w, y, "#787878", "vt");
}

void initDraw() {
  if (drawReady) return;
  initScenes();
  initFonts();
  buildSprites();
  loadImages();
  fxInit();
  if (framePg == null) {
    framePg = createGraphics(SIM_W, SIM_H);
    framePg.noSmooth();
  }
  drawReady = true;
}

void syncFramePg() {
  if (framePg == null) {
    framePg = createGraphics(SIM_W, SIM_H);
    framePg.noSmooth();
  }
  framePg.beginDraw();
  framePg.loadPixels();
  System.arraycopy(frameBuf.px, 0, framePg.pixels, 0, SIM_W * SIM_H);
  framePg.updatePixels();
  framePg.endDraw();
}

void renderGame(GameState S, String lang, int t) {
  HashMap<String, String> tx = TEXT.get(lang);
  if (tx == null) tx = TEXT.get("nl");
  ctxReset();
  fxEvents(S);
  if (fxHold()) return;
  if ("end".equals(S.mode)) {
    drawEnd(S, tx, t);
    credit(tx, t, 250);
    return;
  }
  ctxSave();
  if (S.shake > 0) {
    int amp = Math.min(3, (int) Math.ceil(S.shake / 5.0d));
    ctxTx += (int) Math.round((Math.random() - 0.5d) * amp);
    ctxTy += (int) Math.round((Math.random() - 0.5d) * 2.0d * amp);
  }
  if ("cut".equals(S.mode)) {
    drawCut(S, tx, t);
    ctxRestore();
    return;
  }
  drawScene(S, t, tx);
  ctxRestore();
  drawHud(S, tx, t);
  if ("over".equals(S.mode)) {
    R(0, 0, SIM_W, SIM_H, "rgba(6,4,14,0.72)");
    boolean sun = "sun".equals(S.overWhy);
    T(sun ? tx.get("over_sun") : tx.get("over"), 240, 104, sun ? "#f8c830" : "#e8304a", "ps", 1, 2);
    if (S.overT > 45 && (t / 25) % 2 != 0) T(tx.get("over_hint"), 240, 140, "#ffffff", "vt", 1);
  }
}
