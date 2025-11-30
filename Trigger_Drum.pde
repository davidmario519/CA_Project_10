// ==============================================
// DrumTrigger.pde
// ==============================================

class DrumTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;

  int lastGenre = -1;

  DrumTrigger(PApplet app) {

    jazz      = new SoundFile(app, "src/sound src/jazz/jazz drum.mp3");
    hiphop    = new SoundFile(app, "src/sound src/hiphop/hiphop drum.mp3");
    cinematic = new SoundFile(app, "src/sound src/cinematic/cinematic drum.mp3");

    println("[DrumTrigger] Ready");
  }

  void onOsc(OscMessage m) {
    if (!m.checkAddrPattern("/wek/outputs")) return;
    if (m.arguments().length < 1) return;

    int genre = constrain(round(m.get(0).floatValue()), 0, 2);
    println("[OUTPUT] Drum genre =", genre);

    trigger(genre);
  }

  void trigger(int g) {
    if (g == lastGenre) return;
    lastGenre = g;

    stopAll();
    if (g == 0) jazz.play();
    else if (g == 1) hiphop.play();
    else if (g == 2) cinematic.play();
  }

  void stopAll() {
    if (jazz != null) jazz.stop();
    if (hiphop != null) hiphop.stop();
    if (cinematic != null) cinematic.stop();
  }
}
