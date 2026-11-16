// Keyboard, mouse and controller input. Every device is turned into the same three actions:
// walk (mx), jump and bite/use (act).
// Controller support uses Jamepad (SDL2 GameController with PS5/PS4/Xbox mappings in code/jamepad.jar)
// loaded defensively so the game still compiles and runs if the library or native DLL is missing.

import java.awt.event.KeyEvent;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.Method;

final String[] DEVICES = { "kb1", "kb2", "mouse", "pad0", "pad1" };

HashMap<Integer, Boolean> keysDown = new HashMap<Integer, Boolean>();
boolean shiftHeld = false;
boolean mouseL = false, mouseR = false, mouseM = false;
int mouseUp = 0, mouseDown = 0;
ArrayList<Integer> cheatQueue = new ArrayList<Integer>();
HashMap<String, Boolean> prevMenu = new HashMap<String, Boolean>();

// Jamepad reflection handles
boolean padInitTried = false;
boolean padLibraryLoaded = false;
Object padManager = null;
Method padUpdateMethod = null;
Method padGetStateMethod = null;
Class<?> padStateClass = null;
Field fConnected, fLeftX, fLeftY, fRightTrig;
Field fA, fB, fX, fRb, fStart, fDpadUp, fDpadDown, fDpadLeft, fDpadRight;
Object[] padStates = new Object[2];
Object[] injectedPadStates = null; // for automated testing of controller mappings

class MenuInput {
  boolean up, down, left, right, ok, back, pause;
  int cheat;
}

void initControllers() {
  if (padInitTried) return;
  padInitTried = true;
  try {
    Class<?> mgrClass = Class.forName("com.studiohartman.jamepad.ControllerManager");
    padStateClass = Class.forName("com.studiohartman.jamepad.ControllerState");
    padManager = mgrClass.getDeclaredConstructor().newInstance();
    Method initMethod = mgrClass.getMethod("initSDLGamepad");
    padUpdateMethod = mgrClass.getMethod("update");
    padGetStateMethod = mgrClass.getMethod("getState", int.class);
    initMethod.invoke(padManager);

    fConnected = padStateClass.getField("isConnected");
    fLeftX = padStateClass.getField("leftStickX");
    fLeftY = padStateClass.getField("leftStickY");
    fRightTrig = padStateClass.getField("rightTrigger");
    fA = padStateClass.getField("a");
    fB = padStateClass.getField("b");
    fX = padStateClass.getField("x");
    fRb = padStateClass.getField("rb");
    fStart = padStateClass.getField("start");
    fDpadUp = padStateClass.getField("dpadUp");
    fDpadDown = padStateClass.getField("dpadDown");
    fDpadLeft = padStateClass.getField("dpadLeft");
    fDpadRight = padStateClass.getField("dpadRight");
    padLibraryLoaded = true;
  } catch (Throwable t) {
    padLibraryLoaded = false;
    padManager = null;
  }
}

void refreshPads() {
  if (injectedPadStates != null) {
    padStates[0] = injectedPadStates.length > 0 ? injectedPadStates[0] : null;
    padStates[1] = injectedPadStates.length > 1 ? injectedPadStates[1] : null;
    return;
  }
  initControllers();
  if (!padLibraryLoaded || padManager == null) return;
  try {
    padUpdateMethod.invoke(padManager);
    padStates[0] = padGetStateMethod.invoke(padManager, 0);
    padStates[1] = padGetStateMethod.invoke(padManager, 1);
  } catch (Throwable t) {
    padStates[0] = null;
    padStates[1] = null;
  }
}

boolean isPadConnected(Object cs) {
  if (cs == null || fConnected == null) return false;
  try {
    return fConnected.getBoolean(cs);
  } catch (Throwable t) {
    return false;
  }
}

int padCount() {
  refreshPads();
  int c = 0;
  for (Object cs : padStates) if (isPadConnected(cs)) c++;
  return c;
}

InputState readPadState(Object cs) {
  if (!isPadConnected(cs)) return new InputState(0, false, false);
  try {
    boolean dLeft = fDpadLeft.getBoolean(cs);
    boolean dRight = fDpadRight.getBoolean(cs);
    float lx = fLeftX.getFloat(cs);
    int mx = dLeft ? -1 : dRight ? 1 : Math.abs(lx) > 0.35f ? (lx > 0 ? 1 : -1) : 0;
    boolean jump = fA.getBoolean(cs); // Cross
    boolean act = fX.getBoolean(cs) || fRb.getBoolean(cs) || fRightTrig.getFloat(cs) > 0.4f; // Square (or R1/R2)
    return new InputState(mx, jump, act);
  } catch (Throwable t) {
    return new InputState(0, false, false);
  }
}

InputState pollPad(int idx) {
  if (idx < 0 || idx >= padStates.length) return new InputState(0, false, false);
  return readPadState(padStates[idx]);
}

boolean padMenuBtn(String which) {
  for (Object cs : padStates) {
    if (!isPadConnected(cs)) continue;
    try {
      if ("up".equals(which) && (fDpadUp.getBoolean(cs) || fLeftY.getFloat(cs) > 0.6f)) return true;
      if ("down".equals(which) && (fDpadDown.getBoolean(cs) || fLeftY.getFloat(cs) < -0.6f)) return true;
      if ("left".equals(which) && (fDpadLeft.getBoolean(cs) || fLeftX.getFloat(cs) < -0.6f)) return true;
      if ("right".equals(which) && (fDpadRight.getBoolean(cs) || fLeftX.getFloat(cs) > 0.6f)) return true;
      if ("ok".equals(which) && fA.getBoolean(cs)) return true; // Cross
      if ("back".equals(which) && fB.getBoolean(cs)) return true; // Circle
      if ("pause".equals(which) && fStart.getBoolean(cs)) return true; // Options
    } catch (Throwable t) {
      // ignore
    }
  }
  return false;
}

boolean isKey(int code) {
  Boolean b = keysDown.get(code);
  return b != null && b;
}

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
  refreshPads();

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
