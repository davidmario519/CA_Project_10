class DrumTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;

  int last = -1;
  String base;

  DrumTrigger(PApplet app) {
    // 오디오는 src/sound src/ 아래에 있으니 절대경로로 지정해 로딩 실패를 막는다
    base = app.sketchPath("src/sound src");
    jazz      = new SoundFile(app, base + "/jazz/jazz drum.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop/hiphop drum.mp3");
    cinematic = new SoundFile(app, base + "/cinematic/cinematic drum.mp3");
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
