// Sound: the original theme (Night of Chaos) as music, and small chip-style effects made in code.
(function () {
  const DDN = window.DDN, A = DDN.audio = { music: true };
  let ac = null, el = null, master = null;

  A.unlock = function () {
    if (!ac) {
      const AC = window.AudioContext || window.webkitAudioContext;
      if (!AC) return;
      ac = new AC();
      master = ac.createGain(); master.gain.value = 0.25; master.connect(ac.destination);
    }
    if (ac.state === 'suspended') ac.resume();
    if (!el) {
      el = new Audio('assets/night-of-chaos.wav');
      el.loop = true; el.volume = 0.3; el.preload = 'auto';
    }
    if (A.music && el.paused) el.play().catch(() => {});
  };
  A.setMusic = function (on) {
    A.music = on;
    if (!el) return;
    if (on) el.play().catch(() => {}); else el.pause();
  };

  function tone(type, f0, f1, dur, vol, delay) {
    const t = ac.currentTime + (delay || 0), o = ac.createOscillator(), g = ac.createGain();
    o.type = type; o.frequency.setValueAtTime(f0, t); o.frequency.exponentialRampToValueAtTime(Math.max(20, f1), t + dur);
    g.gain.setValueAtTime(vol, t); g.gain.exponentialRampToValueAtTime(0.001, t + dur);
    o.connect(g); g.connect(master); o.start(t); o.stop(t + dur + 0.02);
  }
  function noise(dur, vol, delay, freq) {
    const t = ac.currentTime + (delay || 0), n = Math.floor(ac.sampleRate * dur);
    const buf = ac.createBuffer(1, n, ac.sampleRate), d = buf.getChannelData(0);
    for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * (1 - i / n);
    const s = ac.createBufferSource(), g = ac.createGain(), f = ac.createBiquadFilter();
    s.buffer = buf; f.type = 'lowpass'; f.frequency.value = freq || 1200; g.gain.value = vol;
    s.connect(f); f.connect(g); g.connect(master); s.start(t);
  }
  const SFX = {
    jump: () => tone('square', 260, 520, 0.12, 0.25),
    bite: () => { tone('square', 200, 80, 0.08, 0.3); noise(0.06, 0.3, 0.02, 2500); },
    hurt: () => { tone('sawtooth', 300, 60, 0.25, 0.4); noise(0.15, 0.3); },
    down: () => { tone('square', 300, 40, 0.6, 0.4); },
    pick: () => { tone('square', 660, 660, 0.06, 0.25); tone('square', 990, 990, 0.1, 0.25, 0.06); },
    hit: () => { noise(0.12, 0.5, 0, 900); tone('square', 120, 60, 0.1, 0.3); },
    clang: () => { tone('triangle', 900, 700, 0.08, 0.3); },
    door: () => { tone('square', 180, 90, 0.2, 0.3); tone('square', 520, 780, 0.2, 0.25, 0.2); },
    pop: () => { tone('square', 500, 100, 0.1, 0.3); },
    caw: () => { tone('sawtooth', 700, 400, 0.12, 0.3); tone('sawtooth', 650, 350, 0.12, 0.3, 0.14); },
    flame: () => { noise(0.25, 0.3, 0, 3000); },
    light: () => { noise(0.15, 0.3, 0, 3000); tone('triangle', 520, 1040, 0.25, 0.3, 0.05); },
    laugh: () => { for (let i = 0; i < 5; i++) tone('square', 500 - i * 30, 420 - i * 30, 0.07, 0.25, i * 0.09); },
    spit: () => { tone('sine', 600, 200, 0.12, 0.35); },
    splash: () => { noise(0.15, 0.25, 0, 1800); },
    flush: () => { noise(0.9, 0.45, 0, 700); tone('sine', 200, 60, 0.9, 0.2); },
    bosshit: () => { tone('square', 150, 50, 0.2, 0.45); noise(0.15, 0.4, 0, 1500); },
    huh: () => { tone('triangle', 300, 420, 0.18, 0.35); },
    snore: () => { tone('sawtooth', 70, 55, 0.5, 0.15); },
    squeak: () => { tone('square', 1200, 1700, 0.08, 0.3); tone('square', 1700, 1100, 0.1, 0.3, 0.08); },
    alarm: () => { for (let i = 0; i < 3; i++) tone('square', 880, 660, 0.15, 0.35, i * 0.16); },
    throw: () => { tone('triangle', 300, 600, 0.12, 0.2); },
    smash: () => { noise(0.2, 0.4, 0, 4000); },
    fire: () => { noise(0.3, 0.35, 0, 2200); tone('sawtooth', 220, 110, 0.25, 0.2); },
    thud: () => { tone('sine', 110, 40, 0.18, 0.5); },
    burn: () => { noise(1.2, 0.5, 0, 3000); tone('sawtooth', 600, 60, 1.2, 0.3); },
    roar: () => { tone('sawtooth', 150, 55, 0.9, 0.4); tone('square', 110, 45, 0.9, 0.2); noise(0.8, 0.35, 0, 600); },
    quack: () => { tone('square', 720, 480, 0.07, 0.22); tone('square', 680, 420, 0.09, 0.22, 0.09); },
    rumble: () => { noise(0.6, 0.35, 0, 350); },
    grow: () => { for (let i = 0; i < 8; i++) tone('square', 110 + i * 45, 150 + i * 45, 0.11, 0.22, i * 0.11); },
    shine: () => { [784, 988, 1175, 1568].forEach((f, i) => tone('triangle', f, f, 0.35, 0.2, i * 0.12)); },
    crumble: () => { noise(1.1, 0.4, 0, 1400); noise(0.7, 0.3, 0.4, 700); },
    over: () => { tone('square', 330, 330, 0.18, 0.3); tone('square', 262, 262, 0.18, 0.3, 0.2); tone('square', 196, 196, 0.4, 0.3, 0.4); },
    win: () => { [523, 659, 784, 1047].forEach((f, i) => tone('square', f, f, 0.12, 0.25, i * 0.1)); },
    card: () => { tone('triangle', 196, 196, 0.5, 0.35); tone('triangle', 294, 294, 0.7, 0.3, 0.15); },
    end: () => { [392, 523, 659, 784, 1047].forEach((f, i) => tone('triangle', f, f, 0.3, 0.3, i * 0.18)); },
    move: () => tone('square', 440, 440, 0.04, 0.15),
    ok: () => { tone('square', 520, 780, 0.1, 0.2); }
  };
  A.sfx = function (name) {
    if (!ac || ac.state !== 'running' || !SFX[name]) return;
    try { SFX[name](); } catch (e) { /* sound is never worth crashing for */ }
  };
})();
