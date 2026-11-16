// De Donkere Nacht Remake - Processing 4 (Java mode) port
// Main sketch tab: setup, game loop, menus, window scaling, and CLI modes.

final int SIM_W = 480, SIM_H = 270, SIM_G = 216;
final double STEP_MS = 1000.0d / 60.0d;
final String[] MENU = { "m_solo", "m_local", "m_chapter", "m_lang", "m_music", "m_controls" };

// Saved settings & progress
String saveLang = "nl";
int saveCh = 1;
String[] saveDev = { "kb1", "kb2" };
boolean saveMusic = true;

// App state
int appTick = 0;
double accMs = 0;
long lastFrameMs = 0;
String appMode = "title"; // title, controls, play, pause
String roleMode = "solo"; // solo, local
GameState S = null;
int lastEv = 0;
int menuSel = 0, pauseSel = 0, ctrlSel = 0, chSel = 1;

HashMap<String, String> curTx() {
  HashMap<String, String> m = TEXT.get(saveLang);
  return m != null ? m : TEXT.get("nl");
}

void storeSettings() {
  // Implemented with saveJSONObject in Stage C
}

void playSfx(String name) {
  // Implemented in Audio.pde in Stage C
}

void setMusicOn(boolean on) {
  // Implemented in Audio.pde in Stage C
}

void startGame(String r, int players, String scene) {
  roleMode = r;
  String sc = scene != null ? scene : CHAPTERS[Math.max(0, Math.min(CHAPTERS.length - 1, chSel - 1))];
  S = newGame(players, sc);
  lastEv = S.evN;
  appMode = "play";
}

void toTitle() {
  S = null;
  appMode = "title";
  roleMode = "solo";
  menuSel = 0;
  chSel = Math.min(chSel, saveCh);
}

void settings() {
  size(SIM_W * 2, SIM_H * 2);
  noSmooth();
}

void setup() {
  if (args != null && args.length > 0 && "test".equals(args[0])) {
    surface.setVisible(false);
    runSmokeTests();
    return;
  }
  if (args != null && args.length >= 2 && "shots".equals(args[0])) {
    surface.setVisible(false);
    initDraw();
    runShotsMode(args[1]);
    return;
  }
  surface.setTitle("De Donkere Nacht");
  surface.setResizable(true);
  frameRate(60);
  initDraw();
  lastFrameMs = millis();
}

void draw() {
  if (!drawReady) {
    background(5, 5, 13);
    return;
  }
  long now = millis();
  long dt = Math.max(0, now - lastFrameMs);
  lastFrameMs = now;
  accMs += Math.min(100.0d, (double) dt);
  int n = 0;
  while (accMs >= STEP_MS && n < 5) {
    accMs -= STEP_MS;
    tickApp();
    n++;
  }
  if (n == 5) accMs = 0;

  renderApp();
  syncFramePg();

  // Nearest-neighbour scaling to the window with aspect-ratio black bars
  background(0);
  noSmooth();
  float s = min((float) width / SIM_W, (float) height / SIM_H);
  int dw = Math.max(1, (int) Math.floor(SIM_W * s));
  int dh = Math.max(1, (int) Math.floor(SIM_H * s));
  int dx = (width - dw) / 2;
  int dy = (height - dh) / 2;
  image(framePg, dx, dy, dw, dh);
}

void tickApp() {
  appTick++;
  MenuInput m = inputTick();
  if ("title".equals(appMode)) tickTitle(m);
  else if ("controls".equals(appMode)) tickControls(m);
  else if ("pause".equals(appMode)) tickPause(m);
  else if ("play".equals(appMode)) tickPlay(m);
}

void tickPlay(MenuInput m) {
  if (m.pause) {
    appMode = "pause";
    pauseSel = 0;
    playSfx("move");
    return;
  }
  InputState[] inputs = "solo".equals(roleMode)
    ? new InputState[] { pollAllDevices() }
    : new InputState[] { pollDevice(saveDev[0]), pollDevice(saveDev[1]) };
  if (m.cheat != 0) skip(S, m.cheat);
  step(S, inputs);
  int ch = SC.get(S.scene).chapter;
  if (ch > saveCh) {
    saveCh = ch;
    chSel = Math.max(chSel, saveCh);
    storeSettings();
  }
  for (Ev e : S.evs) {
    if (e.n > lastEv) {
      playSfx(e.s);
      lastEv = e.n;
    }
  }
  if ("end".equals(S.mode) && S.endT > 180 && m.ok) toTitle();
}

void tickPause(MenuInput m) {
  if (m.up || m.down) {
    pauseSel = 1 - pauseSel;
    playSfx("move");
  }
  if (m.pause || m.back || (m.ok && pauseSel == 0)) {
    appMode = "play";
    playSfx("ok");
    return;
  }
  if (m.ok && pauseSel == 1) toTitle();
}

void tickTitle(MenuInput m) {
  if (m.up) {
    menuSel = (menuSel + MENU.length - 1) % MENU.length;
    playSfx("move");
  }
  if (m.down) {
    menuSel = (menuSel + 1) % MENU.length;
    playSfx("move");
  }
  String k = MENU[menuSel];
  int side = m.left ? -1 : m.right ? 1 : 0;
  if ("m_chapter".equals(k) && side != 0) {
    chSel = Math.max(1, Math.min(saveCh, chSel + side));
    playSfx("move");
  }
  if ("m_lang".equals(k) && (side != 0 || m.ok)) {
    saveLang = "nl".equals(saveLang) ? "en" : "nl";
    storeSettings();
    playSfx("ok");
    return;
  }
  if ("m_music".equals(k) && (side != 0 || m.ok)) {
    saveMusic = !saveMusic;
    setMusicOn(saveMusic);
    storeSettings();
    playSfx("ok");
    return;
  }
  if (!m.ok) return;
  playSfx("ok");
  if ("m_solo".equals(k)) startGame("solo", 1, null);
  else if ("m_local".equals(k)) startGame("local", 2, null);
  else if ("m_controls".equals(k)) {
    appMode = "controls";
    ctrlSel = 0;
  } else if ("m_chapter".equals(k)) {
    startGame("solo", 1, null);
  }
}

void tickControls(MenuInput m) {
  if (m.back) {
    appMode = "title";
    storeSettings();
    return;
  }
  if (m.up || m.down) {
    ctrlSel = 1 - ctrlSel;
    playSfx("move");
  }
  int side = m.left ? -1 : (m.right || m.ok) ? 1 : 0;
  if (side != 0) {
    int n = DEVICES.length;
    int i = 0;
    for (int j = 0; j < n; j++) if (DEVICES[j].equals(saveDev[ctrlSel])) i = j;
    do {
      i = (i + side + n) % n;
    } while (DEVICES[i].equals(saveDev[1 - ctrlSel]));
    saveDev[ctrlSel] = DEVICES[i];
    storeSettings();
    playSfx("move");
  }
}

void renderApp() {
  ctxReset();
  if ("play".equals(appMode) || "pause".equals(appMode)) {
    if (S == null) {
      R(0, 0, SIM_W, SIM_H, "#05050d");
      return;
    }
    renderGame(S, saveLang, appTick);
    if ("pause".equals(appMode)) drawPauseScreen();
    return;
  }
  bg("field");
  R(0, 0, SIM_W, SIM_H, "rgba(6,6,20,0.45)");
  blit("grave", 30, SIM_G);
  blit("grave", 52, SIM_G);
  blit("tomb2", 420, 194);
  blit("z0_idle" + ((appTick / 30) % 2), 40, SIM_G);
  blit("z1_idle" + (((appTick / 30) + 1) % 2), 64, SIM_G);
  fxTitle(appTick);
  if ("title".equals(appMode)) drawTitleScreen();
  else if ("controls".equals(appMode)) drawControlsScreen();
  credit(curTx(), appTick, 222);
}

void drawTitleScreen() {
  HashMap<String, String> x = curTx();
  T(x.get("title"), 242, 22, "#c0302a", "ps", 1, 2, false);
  T(x.get("title"), 240, 20, "#ffffff", "ps", 1, 2);
  T(x.get("sub"), 240, 40, "#cfd6ff", "vt", 1);
  for (int i = 0; i < MENU.length; i++) {
    String k = MENU[i];
    String s = x.get(k);
    if ("m_chapter".equals(k)) {
      s = x.get("m_chapter") + ": " + (chSel > 1 ? "< " : "  ") + chSel + " " + x.get("ch" + chSel) + (chSel < saveCh ? " >" : "  ");
    }
    if ("m_music".equals(k)) {
      s = x.get("m_music") + ": " + (saveMusic ? x.get("on") : x.get("off"));
    }
    boolean on = i == menuSel;
    T((on ? "> " : "") + s + (on ? " <" : ""), 240, 74 + i * 18, on ? "#f8d040" : "#ffffff", "vt", 1);
  }
  T(x.get("nav"), 240, 248, "#9a94b8", "vt", 1);
}

void drawControlsScreen() {
  HashMap<String, String> x = curTx();
  T(x.get("c_head"), 240, 14, "#ffffff", "ps", 1, 2);
  String[][] rows = new String[5][];
  rows[0] = new String[] { "", x.get("c_move"), x.get("c_jump"), x.get("c_bite"), x.get("c_pause") };
  String[][] defs = {
    { x.get("t_kb1"), "c_kb1" },
    { x.get("t_kb2"), "c_kb2" },
    { x.get("t_mouse"), "c_mouse" },
    { x.get("t_pad"), "c_pad" }
  };
  for (int r = 0; r < 4; r++) {
    String[] parts = x.get(defs[r][1]).split("\\|", -1);
    rows[r + 1] = new String[] {
      defs[r][0],
      parts.length > 0 ? parts[0] : "",
      parts.length > 1 ? parts[1] : "",
      parts.length > 2 ? parts[2] : "",
      parts.length > 3 ? parts[3] : ""
    };
  }
  int[] cx = { 10, 100, 228, 330, 420 };
  for (int i = 0; i < rows.length; i++) {
    for (int j = 0; j < rows[i].length; j++) {
      T(rows[i][j], cx[j], 38 + i * 16, i == 0 ? "#f8d040" : j == 0 ? "#63d97d" : "#ffffff", "vt");
    }
  }
  T(x.get("c_note"), 240, 122, "#cfd6ff", "vt", 1);
  for (int i = 0; i < 2; i++) {
    boolean on = ctrlSel == i;
    String label = i != 0 ? x.get("p2dev") : x.get("p1dev");
    T((on ? "> " : "") + label + ":  < " + x.get("d_" + saveDev[i]) + " >", 240, 148 + i * 16, on ? "#f8d040" : "#ffffff", "vt", 1);
  }
  T("Controllers: " + padCount(), 240, 186, "#9a94b8", "vt", 1);
  T(x.get("back"), 240, 250, "#9a94b8", "vt", 1);
}

void drawPauseScreen() {
  HashMap<String, String> x = curTx();
  R(0, 0, SIM_W, SIM_H, "rgba(6,4,14,0.75)");
  T(x.get("paused"), 240, 84, "#ffffff", "ps", 1, 2);
  String[] items = { x.get("resume"), x.get("tomenu") };
  for (int i = 0; i < 2; i++) {
    boolean on = pauseSel == i;
    T((on ? "> " : "") + items[i] + (on ? " <" : ""), 240, 124 + i * 18, on ? "#f8d040" : "#ffffff", "vt", 1);
  }
  credit(x, appTick, 222);
}
