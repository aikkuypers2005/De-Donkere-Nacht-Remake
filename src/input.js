// Keyboard, mouse and controller. Every device is turned into the same three actions:
// walk (mx), jump and bite/use (act).
(function () {
  const DDN = window.DDN, I = DDN.input = {};
  const keys = {};
  const mouse = { l: false, r: false, m: false, up: 0, down: 0 };
  let typed = [], cheats = [], prevMenu = {}, prevPadAny = false;
  I.DEVICES = ['kb1', 'kb2', 'mouse', 'pad0', 'pad1'];
  I.onFirst = null;                       // called on the first key or click (browsers need that to start sound)

  const BLOCK = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space', 'Enter', 'Tab', 'Backspace'];
  window.addEventListener('keydown', e => {
    if (I.onFirst) { I.onFirst(); }
    if (!keys[e.code]) {
      if (e.key.length === 1 || e.key === 'Backspace') typed.push(e.key);
      if (e.shiftKey && e.code === 'KeyX') cheats.push(1);      // the 2016 cheats
      if (e.shiftKey && e.code === 'KeyB') cheats.push(-1);
    }
    keys[e.code] = true;
    if (BLOCK.includes(e.code)) e.preventDefault();
  });
  window.addEventListener('keyup', e => { keys[e.code] = false; });
  window.addEventListener('blur', () => { for (const k in keys) keys[k] = false; mouse.l = mouse.r = mouse.m = false; });
  window.addEventListener('mousedown', e => {
    if (I.onFirst) I.onFirst();
    if (e.button === 0) mouse.l = true; else if (e.button === 1) mouse.m = true; else if (e.button === 2) mouse.r = true;
    if (e.button === 1) e.preventDefault();
  });
  window.addEventListener('mouseup', e => {
    if (e.button === 0) mouse.l = false; else if (e.button === 1) mouse.m = false; else if (e.button === 2) mouse.r = false;
  });
  window.addEventListener('contextmenu', e => e.preventDefault());
  window.addEventListener('wheel', e => { if (e.deltaY < 0) mouse.up = 6; else if (e.deltaY > 0) mouse.down = 6; }, { passive: true });

  function pads() {
    const list = navigator.getGamepads ? navigator.getGamepads() : [];
    const out = [];
    for (const g of list) if (g && g.connected) out.push(g);
    return out;
  }
  function btn(g, i) { return !!(g && g.buttons[i] && g.buttons[i].pressed); }
  function padState(g) {
    if (!g) return { mx: 0, jump: false, act: false };
    const ax = g.axes[0] || 0;
    const mx = btn(g, 14) ? -1 : btn(g, 15) ? 1 : Math.abs(ax) > 0.35 ? Math.sign(ax) : 0;
    return { mx, jump: btn(g, 0), act: btn(g, 2) || btn(g, 5) || btn(g, 7) };   // cross, square (or R1/R2)
  }
  I.padCount = () => pads().length;

  I.poll = function (dev) {
    if (dev === 'kb1') return { mx: (keys.KeyD ? 1 : 0) - (keys.KeyA ? 1 : 0), jump: !!(keys.KeyW || keys.Space), act: !!(keys.KeyF || keys.KeyE) };
    if (dev === 'kb2') return { mx: (keys.ArrowRight ? 1 : 0) - (keys.ArrowLeft ? 1 : 0), jump: !!keys.ArrowUp, act: !!(keys.Enter || keys.NumpadEnter || keys.ShiftRight) };
    if (dev === 'mouse') return { mx: (mouse.r ? 1 : 0) - (mouse.l ? 1 : 0), jump: mouse.up > 0, act: mouse.m || mouse.down > 0 };
    if (dev === 'pad0') return padState(pads()[0]);
    if (dev === 'pad1') return padState(pads()[1]);
    return { mx: 0, jump: false, act: false };
  };
  // Everything at once, for playing alone and for online.
  I.pollAll = function () {
    const out = { mx: 0, jump: false, act: false };
    for (const d of I.DEVICES) {
      const s = I.poll(d);
      if (s.mx && !out.mx) out.mx = s.mx;
      out.jump = out.jump || s.jump; out.act = out.act || s.act;
    }
    return out;
  };

  // Once per game step: menu presses (only the moment a button goes down).
  I.tick = function () {
    if (mouse.up > 0) mouse.up--;
    if (mouse.down > 0) mouse.down--;
    const ps = pads();
    const any = f => ps.some(f);
    const now = {
      up: !!(keys.ArrowUp || keys.KeyW) || any(g => btn(g, 12) || (g.axes[1] || 0) < -0.6),
      down: !!(keys.ArrowDown || keys.KeyS) || any(g => btn(g, 13) || (g.axes[1] || 0) > 0.6),
      left: !!(keys.ArrowLeft || keys.KeyA) || any(g => btn(g, 14) || (g.axes[0] || 0) < -0.6),
      right: !!(keys.ArrowRight || keys.KeyD) || any(g => btn(g, 15) || (g.axes[0] || 0) > 0.6),
      ok: !!(keys.Enter || keys.NumpadEnter || keys.Space) || any(g => btn(g, 0)),
      back: !!keys.Escape || any(g => btn(g, 1)),
      pause: !!keys.Escape || any(g => btn(g, 9))
    };
    const padAny = any(g => g.buttons.some(b => b.pressed));
    if (padAny && !prevPadAny && I.onFirst) I.onFirst();
    prevPadAny = padAny;
    const m = {};
    for (const k in now) m[k] = now[k] && !prevMenu[k];
    prevMenu = now;
    m.typed = typed; typed = [];
    m.cheat = cheats.length ? cheats.shift() : 0;
    return m;
  };
})();
