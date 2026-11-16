// Online co-op. One browser hosts and runs the game; the other joins with a 4-letter room code.
// PeerJS connects the two browsers directly (WebRTC).
(function () {
  const DDN = window.DDN, N = DDN.net = { status: '', code: '', onData: null };
  const PREFIX = 'ddn2-room-';
  let peer = null, conn = null;

  function wire(c) {
    conn = c;
    c.on('open', () => { N.status = 'ready'; });
    c.on('data', d => { if (N.onData) N.onData(d); });
    c.on('close', () => { if (N.status !== '') N.status = 'lost'; });
    c.on('error', () => { N.status = 'lost'; });
  }
  function newCode() {
    const abc = 'ABCDEFGHJKLMNPRSTUVWXYZ';
    let s = '';
    for (let i = 0; i < 4; i++) s += abc[(Math.random() * abc.length) | 0];
    return s;
  }

  N.host = function () {
    N.close();
    if (typeof Peer === 'undefined') { N.status = 'error'; return; }
    N.code = newCode(); N.status = 'opening';
    peer = new Peer(PREFIX + N.code);
    peer.on('open', () => { N.status = 'wait'; });
    peer.on('connection', c => { if (!conn) wire(c); else c.close(); });
    peer.on('error', e => {
      if (e.type === 'unavailable-id') N.host();           // code already in use: pick another
      else if (N.status !== 'ready') N.status = 'error';
    });
  };
  N.join = function (code) {
    N.close();
    if (typeof Peer === 'undefined') { N.status = 'error'; return; }
    N.code = code; N.status = 'opening';
    peer = new Peer();
    peer.on('open', () => wire(peer.connect(PREFIX + code, { serialization: 'json', reliable: true })));
    peer.on('error', () => { if (N.status !== 'ready') N.status = 'error'; });
  };
  N.send = function (obj) { if (conn && conn.open) conn.send(obj); };
  N.close = function () {
    N.status = '';
    try { if (conn) conn.close(); } catch (e) { /* already closed */ }
    try { if (peer) peer.destroy(); } catch (e) { /* already closed */ }
    conn = null; peer = null;
  };
})();
