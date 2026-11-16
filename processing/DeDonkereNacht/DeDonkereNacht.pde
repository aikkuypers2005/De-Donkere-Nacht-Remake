// De Donkere Nacht Remake - Processing 4 (Java mode) port
// Main sketch tab: entry point, command-line modes, and main loop.

GameState S = null;
String appMode = "title";
String saveLang = "nl";

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
  surface.setTitle("De Donkere Nacht");
  surface.setResizable(true);
  frameRate(60);
  initScenes();
  S = newGame(1, "field");
}

void draw() {
  background(5, 5, 13);
  if (S != null) {
    // Stage A placeholder box drawing
    pushMatrix();
    float sc = min((float) width / SIM_W, (float) height / SIM_H);
    translate((width - SIM_W * sc) / 2.0, (height - SIM_H * sc) / 2.0);
    scale(sc);
    fill(10, 10, 36);
    noStroke();
    rect(0, 0, SIM_W, SIM_G);
    fill(118, 59, 46);
    rect(0, SIM_G, SIM_W, SIM_H - SIM_G);
    for (Player p : S.players) {
      fill(p.id == 0 ? color(41, 196, 76) : color(100, 196, 76));
      rect((float) (p.x - 5), (float) (p.y - 26), 10, 26);
    }
    fill(255);
    text(tr(saveLang, "title"), 20, 24);
    popMatrix();
  }
}
