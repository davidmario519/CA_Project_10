class GuitarTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;

  int last = -1;
  String base;

  GuitarTrigger(PApplet app) {
    jazz      = new SoundFile(app, base + "/jazz/jazz guitar.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop/hiphop guitar.mp3");
    cinematic = new SoundFile(app, base + "/cinematic/cinematic guitar.mp3");
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
