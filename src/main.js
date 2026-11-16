// De Donkere Nacht 2 - the p5.js sketch: setup, game loop, menus.
(function () {
  const DDN = window.DDN, sim = DDN.sim, D = DDN.draw, I = DDN.input, A = DDN.audio, N = DDN.net;
  const W = sim.W, H = sim.H, G = sim.G;
  const STEP = 1000 / 60;
  const q = new URLSearchParams(location.search);

  // ------------------------------------------------------------ saved settings
  const save = { lang: 'nl', ch: 1, dev: ['kb1', 'kb2'], music: true };
  try { Object.assign(save, JSON.parse(localStorage.getItem('ddn2') || '{}')); } catch (e) { /* no saved settings */ }
  if (q.get('lang')) save.lang = q.get('lang') === 'en' ? 'en' : 'nl';
  function store() { try { localStorage.setItem('ddn2', JSON.stringify(save)); } catch (e) { /* private window */ } }
  const tx = () => DDN.TEXT[save.lang];

  // ------------------------------------------------------------ state
  let ready = false, t = 0, acc = 0;
  let app = 'title';            // title, controls, host, join, play, pause
  let role = 'solo';            // solo, local, host, guest
  let S = null, lastEv = 0, sel = 0, psel = 0, csel = 0, chSel = save.ch, joinCode = '', notice = '', noticeT = 0;
  let remote = { mx: 0, jump: false, act: false };

  A.music = save.music;
  I.onFirst = () => A.unlock();
  N.onData = d => {
    if (d.k === 'i') remote = d;
    else if (d.k === 's' && (app === 'join' || role === 'guest')) { S = d.S; if (app === 'join') { app = 'play'; role = 'guest'; lastEv = S.evN; } }
    else if (d.k === 'bye') toTitle();
  };

  function start(r, players, scene) {
    role = r;
    S = sim.newGame({ players, scene: scene || sim.CHAPTERS[chSel - 1] });
    lastEv = S.evN; app = 'play';
  }
  function toTitle(msg) {
    if (role === 'host') N.send({ k: 'bye' });
    N.close(); S = null; app = 'title'; role = 'solo'; sel = 0; chSel = Math.min(chSel, save.ch);
    if (msg) { notice = msg; noticeT = 300; }
  }

  // ------------------------------------------------------------ p5
  window.setup = function () {
    pixelDensity(1);
    const c = createCanvas(W, H);
    noSmooth(); frameRate(60);
    c.elt.id = 'game';
    fit();
    D.init(drawingContext);
    const fonts = document.fonts ? Promise.all([document.fonts.load("8px 'Press Start 2P'"), document.fonts.load("16px 'VT323'")]) : Promise.resolve();
    fonts.catch(() => {}).then(() => {
      D.clearText(); ready = true;
      if (q.get('scene') && sim.SC[q.get('scene')]) {
        start(q.get('p') === '2' ? 'local' : 'solo', q.get('p') === '2' ? 2 : 1, q.get('scene'));
        // test links: ?nocut=1 skips the cutscene, ?cut=name&i=2 shows one cutscene line
        if (q.get('nocut')) { S.cut = null; S.mode = 'play'; }
        if (q.get('end')) { S.cut = null; S.mode = 'end'; S.endT = 0; }
        if (q.get('cut') && DDN.CUTS[q.get('cut')]) {
          // a scene's outro carries on as in the real game (?scene=arena&cut=turn&i=6 leads into the giant)
          const sc = sim.SC[S.scene], id = q.get('cut');
          S.cut = { id, i: Math.max(0, Math.min(DDN.CUTS[id].length - 1, Number(q.get('i')) || 0)), t: 0, after: id === sc.outro ? (sc.next ? 'next' : 'end') : 'play' };
          S.mode = 'cut';
        }
        // ?hp=60 sets the boss's leven, ?sun=0.9 the sunrise, ?stun=1 puts the giant on his back
        const boss = S.ents.find(e => e.type === 'thief' || e.type === 'giant');
        if (boss && q.get('hp')) boss.hp = Math.max(1, Math.min(1000, Math.round(Number(q.get('hp'))) || 1000));
        if (q.get('sun') && typeof S.v.sun === 'number') S.v.sun = Math.max(0, Math.min(0.99, Number(q.get('sun')) || 0));
        if (q.get('stun') && boss && boss.type === 'giant') { boss.st = 'down'; boss.t = 0; boss.bites = 0; }
        // ?gold=1 and ?chick=1 give player 1 that power-up, ?talk=z_key shows a speech bubble, ?idle=1 starts the head gag
        if (q.get('gold')) S.players[0].gold = sim.GOLD_T;
        if (q.get('chick')) S.players[0].chick = sim.CHICK_T;
        if (q.get('talk') && DDN.TEXT.nl[q.get('talk')]) S.talk = { who: 0, k: q.get('talk'), t: 100000 };
        if (q.get('idle')) S.players[0].idle = sim.IDLE_GAG - 30;
      }
    });
  };
  function fit() {
    const s = Math.min(window.innerWidth / W, window.innerHeight / H);
    const el = document.getElementById('game');
    if (!el) return;
    el.style.width = Math.floor(W * s) + 'px';
    el.style.height = Math.floor(H * s) + 'px';
  }
  window.windowResized = fit;

  window.draw = function () {
    if (!ready) { D.R(0, 0, W, H, '#05050d'); return; }
    acc += Math.min(100, deltaTime);
    let n = 0;
    while (acc >= STEP && n < 5) { acc -= STEP; tick(); n++; }
    if (n === 5) acc = 0;
    render();
  };

  // ------------------------------------------------------------ one game step
  function tick() {
    t++;
    const m = I.tick();
    if (noticeT > 0) noticeT--;
    if (app === 'title') tickTitle(m);
    else if (app === 'controls') tickControls(m);
    else if (app === 'host') tickHost(m);
    else if (app === 'join') tickJoin(m);
    else if (app === 'pause') tickPause(m);
    else if (app === 'play') tickPlay(m);
  }

  function tickPlay(m) {
    if ((role === 'host' || role === 'guest') && N.status === 'lost') { toTitle(tx().net_lost); return; }
    if (m.pause) { app = 'pause'; psel = 0; A.sfx('move'); if (role === 'host') { S.paused = true; N.send({ k: 's', S }); } return; }
    if (role === 'guest') {
      const inp = I.pollAll();
      N.send({ k: 'i', mx: inp.mx, jump: inp.jump, act: inp.act });
    } else {
      const inputs = role === 'solo' ? [I.pollAll()] : role === 'local' ? [I.poll(save.dev[0]), I.poll(save.dev[1])] : [I.pollAll(), remote];
      if (m.cheat) sim.skip(S, m.cheat);
      sim.step(S, inputs);
      if (role === 'host' && t % 2 === 0) N.send({ k: 's', S });
      const ch = sim.SC[S.scene].chapter;
      if (ch > save.ch) { save.ch = ch; store(); }
    }
    if (!S) return;
    for (const e of S.evs) if (e.n > lastEv) { A.sfx(e.s); lastEv = e.n; }
    if (S.mode === 'end' && S.endT > 180 && m.ok && role !== 'guest') toTitle();
  }

  function tickPause(m) {
    if (role === 'guest' && S) for (const e of S.evs) if (e.n > lastEv) lastEv = e.n;
    if (m.up || m.down) { psel = 1 - psel; A.sfx('move'); }
    if (m.pause || m.back || (m.ok && psel === 0)) { app = 'play'; if (role === 'host') S.paused = false; A.sfx('ok'); return; }
    if (m.ok && psel === 1) toTitle();
  }

  const MENU = ['m_solo', 'm_local', 'm_host', 'm_join', 'm_chapter', 'm_lang', 'm_music', 'm_controls'];
  function tickTitle(m) {
    if (m.up) { sel = (sel + MENU.length - 1) % MENU.length; A.sfx('move'); }
    if (m.down) { sel = (sel + 1) % MENU.length; A.sfx('move'); }
    const k = MENU[sel], side = m.left ? -1 : m.right ? 1 : 0;
    if (k === 'm_chapter' && side) { chSel = Math.max(1, Math.min(save.ch, chSel + side)); A.sfx('move'); }
    if (k === 'm_lang' && (side || m.ok)) { save.lang = save.lang === 'nl' ? 'en' : 'nl'; store(); A.sfx('ok'); return; }
    if (k === 'm_music' && (side || m.ok)) { save.music = !save.music; A.setMusic(save.music); store(); A.sfx('ok'); return; }
    if (!m.ok) return;
    A.sfx('ok');
    if (k === 'm_solo') start('solo', 1);
    else if (k === 'm_local') start('local', 2);
    else if (k === 'm_host') { app = 'host'; N.host(); }
    else if (k === 'm_join') { app = 'join'; joinCode = ''; N.close(); }
    else if (k === 'm_controls') { app = 'controls'; csel = 0; }
    else if (k === 'm_chapter') start('solo', 1);
  }

  function tickControls(m) {
    if (m.back) { app = 'title'; store(); return; }
    if (m.up || m.down) { csel = 1 - csel; A.sfx('move'); }
    const side = m.left ? -1 : m.right || m.ok ? 1 : 0;
    if (side) {
      const n = I.DEVICES.length;
      let i = I.DEVICES.indexOf(save.dev[csel]);
      do { i = (i + side + n) % n; } while (I.DEVICES[i] === save.dev[1 - csel]);
      save.dev[csel] = I.DEVICES[i]; store(); A.sfx('move');
    }
  }

  function tickHost(m) {
    if (m.back) { toTitle(); return; }
    if (N.status === 'error' || N.status === 'lost') { toTitle(tx().net_err); return; }
    if (N.status === 'ready' && m.ok) { A.sfx('ok'); start('host', 2); N.send({ k: 's', S }); }
  }

  function tickJoin(m) {
    if (m.back) { toTitle(); return; }
    if (N.status === 'error' || N.status === 'lost') { toTitle(tx().net_err); return; }
    if (N.status !== '') return;                       // connecting or connected: wait for the host
    for (const ch of m.typed) {
      if (ch === 'Backspace') joinCode = joinCode.slice(0, -1);
      else if (/^[a-zA-Z]$/.test(ch) && joinCode.length < 4) joinCode += ch.toUpperCase();
    }
    // with a controller: up/down changes the last letter, right adds one, left removes one
    const abc = 'ABCDEFGHJKLMNPRSTUVWXYZ';
    if (!m.typed.length) {
      if (m.right && joinCode.length < 4) joinCode += 'A';
      if (m.left) joinCode = joinCode.slice(0, -1);
      if ((m.up || m.down) && joinCode.length) {
        const i = (abc.indexOf(joinCode.slice(-1)) + (m.up ? 1 : -1) + abc.length) % abc.length;
        joinCode = joinCode.slice(0, -1) + abc[i];
      }
    }
    if (m.ok && joinCode.length === 4) { A.sfx('ok'); N.join(joinCode); }
  }

  // ------------------------------------------------------------ drawing the menus
  function render() {
    drawingContext.imageSmoothingEnabled = false;
    if (app === 'play' || app === 'pause') {
      if (!S) { D.R(0, 0, W, H, '#05050d'); return; }
      D.render(S, save.lang, t);
      if (app === 'pause' || (S.paused && role === 'guest')) drawPause();
      return;
    }
    D.bg('field');
    D.R(0, 0, W, H, 'rgba(6,6,20,0.45)');
    D.blit('grave', 30, G); D.blit('grave', 52, G); D.blit('tomb2', 420, 194);
    D.blit('z0_idle' + (Math.floor(t / 30) % 2), 40, G);
    D.blit('z1_idle' + (Math.floor(t / 30 + 1) % 2), 64, G);
    if (app === 'title') drawTitle();
    else if (app === 'controls') drawControls();
    else if (app === 'host') drawHost();
    else if (app === 'join') drawJoin();
    D.credit(tx(), t, 222);
  }

  function drawTitle() {
    const x = tx();
    D.T(x.title, 242, 22, '#c0302a', 'ps', 1, 2, false);
    D.T(x.title, 240, 20, '#ffffff', 'ps', 1, 2);
    D.T(x.sub, 240, 40, '#cfd6ff', 'vt', 1);
    MENU.forEach((k, i) => {
      let s = x[k];
      if (k === 'm_chapter') s = x.m_chapter + ': ' + (chSel > 1 ? '< ' : '  ') + chSel + ' ' + x['ch' + chSel] + (chSel < save.ch ? ' >' : '  ');
      if (k === 'm_music') s = x.m_music + ': ' + (save.music ? x.on : x.off);
      const on = i === sel;
      D.T((on ? '> ' : '') + s + (on ? ' <' : ''), 240, 62 + i * 16, on ? '#f8d040' : '#ffffff', 'vt', 1);
    });
    if (noticeT > 0) D.T(notice, 240, 192, '#ff8080', 'vt', 1);
    D.T(x.nav, 240, 248, '#9a94b8', 'vt', 1);
  }

  function drawControls() {
    const x = tx();
    D.T(x.c_head, 240, 14, '#ffffff', 'ps', 1, 2);
    const rows = [['', x.c_move, x.c_jump, x.c_bite, x.c_pause]];
    for (const [name, key] of [[x.t_kb1, 'c_kb1'], [x.t_kb2, 'c_kb2'], [x.t_mouse, 'c_mouse'], [x.t_pad, 'c_pad']]) rows.push([name].concat(x[key].split('|')));
    const cx = [10, 100, 228, 330, 420];
    rows.forEach((r, i) => r.forEach((s, j) => D.T(s, cx[j], 38 + i * 16, i === 0 ? '#f8d040' : j === 0 ? '#63d97d' : '#ffffff', 'vt')));
    D.T(x.c_note, 240, 122, '#cfd6ff', 'vt', 1);
    for (let i = 0; i < 2; i++) {
      const on = csel === i;
      D.T((on ? '> ' : '') + (i ? x.p2dev : x.p1dev) + ':  < ' + x['d_' + save.dev[i]] + ' >', 240, 148 + i * 16, on ? '#f8d040' : '#ffffff', 'vt', 1);
    }
    D.T('Controllers: ' + I.padCount(), 240, 186, '#9a94b8', 'vt', 1);
    D.T(x.back, 240, 250, '#9a94b8', 'vt', 1);
  }

  function drawHost() {
    const x = tx();
    D.T(x.host_head, 240, 24, '#ffffff', 'ps', 1);
    D.T(x.host_code, 240, 64, '#cfd6ff', 'vt', 1);
    D.T(N.status === 'opening' ? '....' : N.code, 240, 88, '#f8d040', 'ps', 1, 4);
    D.T(N.status === 'ready' ? x.host_ready : x.host_wait + (N.status === 'wait' ? ['', '.', '..'][Math.floor(t / 30) % 3] : ''), 240, 150, N.status === 'ready' ? '#63d97d' : '#ffffff', 'vt', 1);
    D.T(x.back, 240, 252, '#9a94b8', 'vt', 1);
  }

  function drawJoin() {
    const x = tx();
    D.T(x.join_head, 240, 24, '#ffffff', 'ps', 1);
    D.T(x.join_code, 240, 64, '#cfd6ff', 'vt', 1);
    const shown = (joinCode + '____').slice(0, 4);
    D.T(shown, 240, 88, '#f8d040', 'ps', 1, 4);
    if (N.status === 'opening') D.T(x.join_go, 240, 150, '#ffffff', 'vt', 1);
    else if (N.status === 'ready') D.T(x.join_ok, 240, 150, '#63d97d', 'vt', 1);
    D.T(x.back, 240, 252, '#9a94b8', 'vt', 1);
  }

  function drawPause() {
    const x = tx();
    D.R(0, 0, W, H, 'rgba(6,4,14,0.75)');
    D.T(x.paused, 240, 84, '#ffffff', 'ps', 1, 2);
    if (app === 'pause') {
      [x.resume, x.tomenu].forEach((s, i) => D.T((psel === i ? '> ' : '') + s + (psel === i ? ' <' : ''), 240, 124 + i * 18, psel === i ? '#f8d040' : '#ffffff', 'vt', 1));
    }
    D.credit(x, t, 222);
  }

  // If the host's tab is hidden the browser stops the game loop, so pause for both players.
  document.addEventListener('visibilitychange', () => {
    if (document.hidden && role === 'host' && app === 'play' && S) { app = 'pause'; psel = 0; S.paused = true; N.send({ k: 's', S }); }
  });

  // for testing in the browser console
  DDN.dbg = { get S() { return S; }, get app() { return app; }, start, sim };
})();
