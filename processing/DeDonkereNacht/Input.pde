// Keyboard, mouse and controller input. Every device is turned into the same three actions:
// walk (mx), jump and bite/use (act).

import java.awt.event.KeyEvent;

final String[] DEVICES = { "kb1", "kb2", "mouse", "pad0", "pad1" };

HashMap<Integer, Boolean> keysDown = new HashMap<Integer, Boolean>();
boolean shiftHeld = false;
boolean mouseL = false, mouseR = false, mouseM = false;
int mouseUp = 0, mouseDown = 0;
ArrayList<Integer> cheatQueue = new ArrayList<Integer>();
HashMap<String, Boolean> prevMenu = new HashMap<String, Boolean>();

class MenuInput {
  boolean up, down, left, right, ok, back, pause;
  int cheat;
}

boolean isKey(int code) {
  Boolean b = keysDown.get(code);
  return b != null && b;
}

int padCount() {
  return pollControllerCount();
}

InputState pollPad(int idx) {
  return pollControllerState(idx);
}

boolean padMenuBtn(String which) {
  return pollControllerMenu(which);
}

// Default controller hooks (overridden/populated in Controller/Audio stage C)
int pollControllerCount() { return 0; }
InputState pollControllerState(int idx) { return new InputState(0, false, false); }
boolean pollControllerMenu(String which) { return false; }

InputState pollDevice(String dev) {
  if ("kb1".equals(dev)) {
    int mx = (isKey(KeyEvent.VK_D) ? 1 : 0) - (isKey(KeyEvent.VK_A) ? 1 : 0);
    boolean jump = isKey(KeyEvent.VK_W) || isKey(KeyEvent.VK_SPACE);
    boolean act = isKey(KeyEvent.VK_F) || isKey(KeyEvent.VK_E);
    return new InputState(mx, jump, act);
  }
  if ("kb2".equals(dev)) {
    int mx = (isKey(KeyEvent.VK_RIGHT) ? 1 : 0) - (isKey(KeyEvent.VK_LEFT) ? 1 : 0);
    boolean jump = isKey(KeyEvent.VK_UP);
    boolean act = isKey(KeyEvent.VK_ENTER);
    return new InputState(mx, jump, act);
  }
  if ("mouse".equals(dev)) {
    int mx = (mouseR ? 1 : 0) - (mouseL ? 1 : 0);
    boolean jump = mouseUp > 0;
    boolean act = mouseM || mouseDown > 0;
    return new InputState(mx, jump, act);
  }
  if ("pad0".equals(dev)) return pollPad(0);
  if ("pad1".equals(dev)) return pollPad(1);
  return new InputState(0, false, false);
}

InputState pollAllDevices() {
  InputState out = new InputState(0, false, false);
  for (String d : DEVICES) {
    InputState s = pollDevice(d);
    if (s.mx != 0 && out.mx == 0) out.mx = s.mx;
    out.jump = out.jump || s.jump;
    out.act = out.act || s.act;
  }
  return out;
}

MenuInput inputTick() {
  if (mouseUp > 0) mouseUp--;
  if (mouseDown > 0) mouseDown--;

  HashMap<String, Boolean> now = new HashMap<String, Boolean>();
  now.put("up", isKey(KeyEvent.VK_UP) || isKey(KeyEvent.VK_W) || padMenuBtn("up"));
  now.put("down", isKey(KeyEvent.VK_DOWN) || isKey(KeyEvent.VK_S) || padMenuBtn("down"));
  now.put("left", isKey(KeyEvent.VK_LEFT) || isKey(KeyEvent.VK_A) || padMenuBtn("left"));
  now.put("right", isKey(KeyEvent.VK_RIGHT) || isKey(KeyEvent.VK_D) || padMenuBtn("right"));
  now.put("ok", isKey(KeyEvent.VK_ENTER) || isKey(KeyEvent.VK_SPACE) || padMenuBtn("ok"));
  now.put("back", isKey(KeyEvent.VK_ESCAPE) || padMenuBtn("back"));
  now.put("pause", isKey(KeyEvent.VK_ESCAPE) || padMenuBtn("pause"));

  MenuInput m = new MenuInput();
  m.up = now.get("up") && !Boolean.TRUE.equals(prevMenu.get("up"));
  m.down = now.get("down") && !Boolean.TRUE.equals(prevMenu.get("down"));
  m.left = now.get("left") && !Boolean.TRUE.equals(prevMenu.get("left"));
  m.right = now.get("right") && !Boolean.TRUE.equals(prevMenu.get("right"));
  m.ok = now.get("ok") && !Boolean.TRUE.equals(prevMenu.get("ok"));
  m.back = now.get("back") && !Boolean.TRUE.equals(prevMenu.get("back"));
  m.pause = now.get("pause") && !Boolean.TRUE.equals(prevMenu.get("pause"));
  prevMenu = now;
  m.cheat = !cheatQueue.isEmpty() ? cheatQueue.remove(0) : 0;
  return m;
}

void keyPressed(processing.event.KeyEvent e) {
  int c = keyCode;
  if (key == ESC) {
    key = 0;
    c = KeyEvent.VK_ESCAPE;
  }
  if (c == KeyEvent.VK_SHIFT) shiftHeld = true;
  boolean wasDown = isKey(c);
  if (!wasDown) {
    if ((shiftHeld || e.isShiftDown()) && c == KeyEvent.VK_X) cheatQueue.add(1);
    if ((shiftHeld || e.isShiftDown()) && c == KeyEvent.VK_B) cheatQueue.add(-1);
  }
  keysDown.put(c, true);
}

void keyReleased(processing.event.KeyEvent e) {
  int c = keyCode;
  if (key == ESC) c = KeyEvent.VK_ESCAPE;
  if (c == KeyEvent.VK_SHIFT) shiftHeld = false;
  keysDown.put(c, false);
}

void mousePressed() {
  if (mouseButton == LEFT) mouseL = true;
  else if (mouseButton == CENTER) mouseM = true;
  else if (mouseButton == RIGHT) mouseR = true;
}

void mouseReleased() {
  if (mouseButton == LEFT) mouseL = false;
  else if (mouseButton == CENTER) mouseM = false;
  else if (mouseButton == RIGHT) mouseR = false;
}

void mouseWheel(processing.event.MouseEvent event) {
  float count = event.getCount();
  if (count < 0) mouseUp = 6;
  else if (count > 0) mouseDown = 6;
}
