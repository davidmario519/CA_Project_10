class GuitarTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;

  int last = -1;
  String base = "data"; // 오디오 파일이 있는 기본 폴더
  String[] labels;

  int current = REST;
  int pending = REST;
  int pendingCount = 0;
  int threshold = 35;
  int minHoldTime = 700;       // ms lock after change
  int lastChangeMillis = 0;
  boolean ready = true;        // REST 이후에만 새 트리거 허용

  static final int REST = -1;
  static final int UNKNOWN = -2;

  GuitarTrigger(PApplet app) {
    jazz      = new SoundFile(app, base + "/jazz guitar.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop guitar.mp3");
    cinematic = new SoundFile(app, base + "/cinematic guitar.mp3");
    labels = GENRE_NAMES;
  }

  void onOsc(float v) {
    int raw = mapToIndexWithHysteresis(v);
    if (raw == UNKNOWN) {
      pending = -1;
      pendingCount = 0;
      return;
    }

    if (raw == pending) {
      pendingCount++;
      if (pendingCount >= threshold) {
        if (raw != current) {
          if (canChange()) {
            current = raw;
            lastChangeMillis = millis();
            if (current == REST) {
              ready = true;
              println("[GUITAR REST] ready");
              stopAll();
            } else if (ready) {
              println("[GUITAR CONFIRMED] → " + label(current));
              trigger(current);
              ready = false;
            }
          }
        }
      }
    } else {
      pending = raw;
      pendingCount = 1;
    }
  }

  void trigger(int genre) {
    if (genre == last) return;
    last = genre;

    // 루프 매니저가 있으면 위임
    if (loopQuantizer != null) {
      stopAll();
      loopQuantizer.queueClip(1, genre);
      return;
    }

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

  int getCurrentGenre() {
    return current;
  }

  boolean canChange() {
    return (millis() - lastChangeMillis) > minHoldTime;
  }

  int mapToIndexWithHysteresis(float v) {
    // 유지 구간
    if (current == REST && v >= 0.00 && v <= 0.12) return REST;
    if (current == 0 && v >= 0.12 && v <= 0.33) return 0; // Jazz
    if (current == 1 && v >= 0.38 && v <= 0.62) return 1; // HipHop
    if (current == 2 && v >= 0.60 && v <= 0.88) return 2; // Cinematic

    // 진입 구간 (strict)
    if (v >= 0.00 && v <= 0.10) return REST;
    if (v >= 0.15 && v <= 0.30) return 0;
    if (v >= 0.40 && v <= 0.60) return 1;
    if (v >= 0.65 && v <= 0.85) return 2;

    return UNKNOWN;
  }

  String label(int idx) {
    if (idx == REST) return "Rest";
    if (labels == null || idx < 0 || idx >= labels.length) return "Unknown";
    return labels[idx];
  }
}
