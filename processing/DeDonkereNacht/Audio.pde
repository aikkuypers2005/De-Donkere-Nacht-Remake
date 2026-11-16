// Music (Night of Chaos) and synthesized chip-style sound effects, matching src/audio.js.
// Uses javax.sound.sampled only. Audio failures are caught and never crash the game.

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.Clip;
import javax.sound.sampled.FloatControl;

final int SFX_RATE = 22050;
final AudioFormat SFX_FORMAT = new AudioFormat(SFX_RATE, 16, 1, true, false);

HashMap<String, byte[]> sfxBuffers = new HashMap<String, byte[]>();
HashMap<String, Clip> sfxClips = new HashMap<String, Clip>();
Clip musicClip = null;
boolean audioInitialized = false;
boolean audioEnabled = true;

class SfxTone {
  String type;
  double f0, f1, dur, vol, delay;
  SfxTone(String type, double f0, double f1, double dur, double vol, double delay) {
    this.type = type; this.f0 = f0; this.f1 = f1; this.dur = dur; this.vol = vol; this.delay = delay;
  }
}

class SfxNoise {
  double dur, vol, delay, freq;
  SfxNoise(double dur, double vol, double delay, double freq) {
    this.dur = dur; this.vol = vol; this.delay = delay; this.freq = freq;
  }
}

class SfxBuilder {
  ArrayList<SfxTone> tones = new ArrayList<SfxTone>();
  ArrayList<SfxNoise> noises = new ArrayList<SfxNoise>();

  SfxBuilder tone(String type, double f0, double f1, double dur, double vol) {
    return tone(type, f0, f1, dur, vol, 0.0d);
  }

  SfxBuilder tone(String type, double f0, double f1, double dur, double vol, double delay) {
    tones.add(new SfxTone(type, f0, f1, dur, vol, delay));
    return this;
  }

  SfxBuilder noise(double dur, double vol) {
    return noise(dur, vol, 0.0d, 1200.0d);
  }

  SfxBuilder noise(double dur, double vol, double delay, double freq) {
    noises.add(new SfxNoise(dur, vol, delay, freq));
    return this;
  }

  byte[] build() {
    double maxEnd = 0.05d;
    for (SfxTone t : tones) maxEnd = Math.max(maxEnd, t.delay + t.dur + 0.02d);
    for (SfxNoise n : noises) maxEnd = Math.max(maxEnd, n.delay + n.dur + 0.02d);
    int totalSamples = Math.max(1, (int) Math.ceil(maxEnd * SFX_RATE));
    double[] mix = new double[totalSamples];

    for (SfxTone t : tones) {
      int s0 = Math.max(0, (int) Math.round(t.delay * SFX_RATE));
      int len = Math.max(1, (int) Math.round(t.dur * SFX_RATE));
      double fStart = Math.max(20.0d, t.f0);
      double fEnd = Math.max(20.0d, t.f1);
      double vStart = Math.max(0.001d, t.vol);
      double phase = 0.0d;
      for (int i = 0; i < len && s0 + i < totalSamples; i++) {
        double u = i / (double) len;
        double freq = fStart * Math.pow(fEnd / fStart, u);
        double gain = vStart * Math.pow(0.001d / vStart, u);
        double w = 0.0d;
        if ("square".equals(t.type)) w = phase < 0.5d ? 1.0d : -1.0d;
        else if ("sawtooth".equals(t.type)) w = 2.0d * phase - 1.0d;
        else if ("triangle".equals(t.type)) w = 1.0d - 4.0d * Math.abs(phase - 0.5d);
        else w = Math.sin(2.0d * Math.PI * phase);
        mix[s0 + i] += w * gain * 0.35d;
        phase += freq / SFX_RATE;
        phase -= Math.floor(phase);
      }
    }

    long nSeed = 1234567L;
    for (SfxNoise n : noises) {
      int s0 = Math.max(0, (int) Math.round(n.delay * SFX_RATE));
      int len = Math.max(1, (int) Math.round(n.dur * SFX_RATE));
      double fc = n.freq > 0 ? n.freq : 1200.0d;
      double rc = 1.0d / (2.0d * Math.PI * fc);
      double dt = 1.0d / SFX_RATE;
      double alpha = dt / (rc + dt);
      double lp = 0.0d;
      for (int i = 0; i < len && s0 + i < totalSamples; i++) {
        nSeed = (nSeed * 16807L) % 2147483647L;
        double white = ((nSeed / 2147483647.0d) * 2.0d - 1.0d) * (1.0d - i / (double) len);
        lp = lp + alpha * (white - lp);
        mix[s0 + i] += lp * n.vol * 0.35d;
      }
    }

    byte[] out = new byte[totalSamples * 2];
    for (int i = 0; i < totalSamples; i++) {
      double clamped = Math.max(-1.0d, Math.min(1.0d, mix[i]));
      short s = (short) Math.round(clamped * 32767.0d);
      out[i * 2] = (byte) (s & 0xFF);
      out[i * 2 + 1] = (byte) ((s >>> 8) & 0xFF);
    }
    return out;
  }
}

void buildAllSfx() {
  if (!sfxBuffers.isEmpty()) return;
  sfxBuffers.put("jump", new SfxBuilder().tone("square", 260, 520, 0.12d, 0.25d).build());
  sfxBuffers.put("bite", new SfxBuilder().tone("square", 200, 80, 0.08d, 0.3d).noise(0.06d, 0.3d, 0.02d, 2500).build());
  sfxBuffers.put("hurt", new SfxBuilder().tone("sawtooth", 300, 60, 0.25d, 0.4d).noise(0.15d, 0.3d).build());
  sfxBuffers.put("down", new SfxBuilder().tone("square", 300, 40, 0.6d, 0.4d).build());
  sfxBuffers.put("pick", new SfxBuilder().tone("square", 660, 660, 0.06d, 0.25d).tone("square", 990, 990, 0.1d, 0.25d, 0.06d).build());
  sfxBuffers.put("hit", new SfxBuilder().noise(0.12d, 0.5d, 0, 900).tone("square", 120, 60, 0.1d, 0.3d).build());
  sfxBuffers.put("clang", new SfxBuilder().tone("triangle", 900, 700, 0.08d, 0.3d).build());
  sfxBuffers.put("door", new SfxBuilder().tone("square", 180, 90, 0.2d, 0.3d).tone("square", 520, 780, 0.2d, 0.25d, 0.2d).build());
  sfxBuffers.put("pop", new SfxBuilder().tone("square", 500, 100, 0.1d, 0.3d).build());
  sfxBuffers.put("caw", new SfxBuilder().tone("sawtooth", 700, 400, 0.12d, 0.3d).tone("sawtooth", 650, 350, 0.12d, 0.3d, 0.14d).build());
  sfxBuffers.put("flame", new SfxBuilder().noise(0.25d, 0.3d, 0, 3000).build());
  sfxBuffers.put("light", new SfxBuilder().noise(0.15d, 0.3d, 0, 3000).tone("triangle", 520, 1040, 0.25d, 0.3d, 0.05d).build());
  {
    SfxBuilder b = new SfxBuilder();
    for (int i = 0; i < 5; i++) b.tone("square", 500 - i * 30, 420 - i * 30, 0.07d, 0.25d, i * 0.09d);
    sfxBuffers.put("laugh", b.build());
  }
  sfxBuffers.put("spit", new SfxBuilder().tone("sine", 600, 200, 0.12d, 0.35d).build());
  sfxBuffers.put("splash", new SfxBuilder().noise(0.15d, 0.25d, 0, 1800).build());
  sfxBuffers.put("flush", new SfxBuilder().noise(0.9d, 0.45d, 0, 700).tone("sine", 200, 60, 0.9d, 0.2d).build());
  sfxBuffers.put("bosshit", new SfxBuilder().tone("square", 150, 50, 0.2d, 0.45d).noise(0.15d, 0.4d, 0, 1500).build());
  sfxBuffers.put("huh", new SfxBuilder().tone("triangle", 300, 420, 0.18d, 0.35d).build());
  sfxBuffers.put("snore", new SfxBuilder().tone("sawtooth", 70, 55, 0.5d, 0.15d).build());
  sfxBuffers.put("squeak", new SfxBuilder().tone("square", 1200, 1700, 0.08d, 0.3d).tone("square", 1700, 1100, 0.1d, 0.3d, 0.08d).build());
  {
    SfxBuilder b = new SfxBuilder();
    for (int i = 0; i < 3; i++) b.tone("square", 880, 660, 0.15d, 0.35d, i * 0.16d);
    sfxBuffers.put("alarm", b.build());
  }
  sfxBuffers.put("throw", new SfxBuilder().tone("triangle", 300, 600, 0.12d, 0.2d).build());
  sfxBuffers.put("smash", new SfxBuilder().noise(0.2d, 0.4d, 0, 4000).build());
  sfxBuffers.put("fire", new SfxBuilder().noise(0.3d, 0.35d, 0, 2200).tone("sawtooth", 220, 110, 0.25d, 0.2d).build());
  sfxBuffers.put("thud", new SfxBuilder().tone("sine", 110, 40, 0.18d, 0.5d).build());
  sfxBuffers.put("burn", new SfxBuilder().noise(1.2d, 0.5d, 0, 3000).tone("sawtooth", 600, 60, 1.2d, 0.3d).build());
  sfxBuffers.put("roar", new SfxBuilder().tone("sawtooth", 150, 55, 0.9d, 0.4d).tone("square", 110, 45, 0.9d, 0.2d).noise(0.8d, 0.35d, 0, 600).build());
  sfxBuffers.put("quack", new SfxBuilder().tone("square", 720, 480, 0.07d, 0.22d).tone("square", 680, 420, 0.09d, 0.22d, 0.09d).build());
  sfxBuffers.put("rumble", new SfxBuilder().noise(0.6d, 0.35d, 0, 350).build());
  {
    SfxBuilder b = new SfxBuilder();
    for (int i = 0; i < 8; i++) b.tone("square", 110 + i * 45, 150 + i * 45, 0.11d, 0.22d, i * 0.11d);
    sfxBuffers.put("grow", b.build());
  }
  {
    SfxBuilder b = new SfxBuilder();
    int[] fs = { 784, 988, 1175, 1568 };
    for (int i = 0; i < fs.length; i++) b.tone("triangle", fs[i], fs[i], 0.35d, 0.2d, i * 0.12d);
    sfxBuffers.put("shine", b.build());
  }
  sfxBuffers.put("crumble", new SfxBuilder().noise(1.1d, 0.4d, 0, 1400).noise(0.7d, 0.3d, 0.4d, 700).build());
  {
    SfxBuilder b = new SfxBuilder();
    int[] fs = { 523, 784, 1047, 1568 };
    for (int i = 0; i < fs.length; i++) b.tone("square", fs[i], fs[i] * 1.02d, 0.08d, 0.22d, i * 0.06d);
    sfxBuffers.put("power", b.build());
  }
  sfxBuffers.put("shriek", new SfxBuilder().tone("square", 1400, 2200, 0.15d, 0.25d).tone("square", 2200, 1300, 0.2d, 0.25d, 0.15d).build());
  {
    SfxBuilder b = new SfxBuilder();
    for (int i = 0; i < 6; i++) b.noise(0.06d, 0.2d, i * 0.07d, 2500);
    sfxBuffers.put("unroll", b.build());
  }
  sfxBuffers.put("over", new SfxBuilder().tone("square", 330, 330, 0.18d, 0.3d).tone("square", 262, 262, 0.18d, 0.3d, 0.2d).tone("square", 196, 196, 0.4d, 0.3d, 0.4d).build());
  {
    SfxBuilder b = new SfxBuilder();
    int[] fs = { 523, 659, 784, 1047 };
    for (int i = 0; i < fs.length; i++) b.tone("square", fs[i], fs[i], 0.12d, 0.25d, i * 0.1d);
    sfxBuffers.put("win", b.build());
  }
  sfxBuffers.put("card", new SfxBuilder().tone("triangle", 196, 196, 0.5d, 0.35d).tone("triangle", 294, 294, 0.7d, 0.3d, 0.15d).build());
  {
    SfxBuilder b = new SfxBuilder();
    int[] fs = { 392, 523, 659, 784, 1047 };
    for (int i = 0; i < fs.length; i++) b.tone("triangle", fs[i], fs[i], 0.3d, 0.3d, i * 0.18d);
    sfxBuffers.put("end", b.build());
  }
  sfxBuffers.put("move", new SfxBuilder().tone("square", 440, 440, 0.04d, 0.15d).build());
  sfxBuffers.put("ok", new SfxBuilder().tone("square", 520, 780, 0.1d, 0.2d).build());
}

void initAudio() {
  if (audioInitialized) return;
  audioInitialized = true;
  try {
    buildAllSfx();
    if (!audioEnabled) return;
    File wav = dataFile("night-of-chaos.wav");
    if (wav != null && wav.exists()) {
      AudioInputStream ais = AudioSystem.getAudioInputStream(wav);
      musicClip = AudioSystem.getClip();
      Clip.class.getMethod("open", AudioInputStream.class).invoke(musicClip, ais);
      if (musicClip.isControlSupported(FloatControl.Type.MASTER_GAIN)) {
        FloatControl gain = (FloatControl) musicClip.getControl(FloatControl.Type.MASTER_GAIN);
        gain.setValue(Math.max(gain.getMinimum(), Math.min(gain.getMaximum(), -10.0f)));
      }
      if (saveMusic) {
        musicClip.loop(Clip.LOOP_CONTINUOUSLY);
      }
    }
  } catch (Throwable e) {
    // Never let audio failure crash the game
  }
}

void setMusicOn(boolean on) {
  if (!audioEnabled) return;
  try {
    if (musicClip == null) return;
    if (on) {
      musicClip.loop(Clip.LOOP_CONTINUOUSLY);
    } else {
      musicClip.stop();
    }
  } catch (Throwable e) {
    // Ignore audio errors
  }
}

void playSfx(String name) {
  if (!audioEnabled || name == null) return;
  try {
    buildAllSfx();
    byte[] pcm = sfxBuffers.get(name);
    if (pcm == null) return;
    Clip clip = sfxClips.get(name);
    if (clip == null) {
      clip = AudioSystem.getClip();
      Clip.class.getMethod("open", AudioFormat.class, byte[].class, int.class, int.class)
        .invoke(clip, SFX_FORMAT, pcm, 0, pcm.length);
      sfxClips.put(name, clip);
    }
    if (clip.isRunning()) clip.stop();
    clip.setFramePosition(0);
    clip.start();
  } catch (Throwable e) {
    // Sound is never worth crashing for
  }
}
