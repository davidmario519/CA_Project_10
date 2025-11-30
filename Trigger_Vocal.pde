class VocalTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;

  int last = -1;
  String base;

  VocalTrigger(PApplet app) {
    base = app.sketchPath("src/sound src");
    jazz      = new SoundFile(app, base + "/jazz/jazz vocal.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop/hiphop vocal.mp3");
    cinematic = new SoundFile(app, base + "/cinematic/cinematic vocal.mp3");
  }

  void trigger(int genre) {
    if (genre == last) return;
    last = genre;
    stopAll();

    if (genre == 0) jazz.play();
    else if (genre == 1) hiphop.play();
    else if (genre == 2) cinematic.play();
  }

  void stopAll() {
    if (jazz != null) jazz.stop();
    if (hiphop != null) hiphop.stop();
    if (cinematic != null) cinematic.stop();
  }
}
