class DrumTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile funk;

  int last = -1;
  String base = "data"; // 오디오 파일이 있는 기본 폴더
  String[] labels;

  // 안정화용 상태
  int current = UNKNOWN;
  int pending = UNKNOWN;
  int pendingCount = 0;
  int threshold = 35;          // frame-based stabilization
  int minHoldTime = 700;       // ms lock after change
  int lastChangeMillis = 0;    // last confirmed change time
  // 클래스 코드
  static final int UNKNOWN = -2;

  DrumTrigger(PApplet app) {
    jazz      = new SoundFile(app, base + "/jazz drum.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop drum.mp3");
    funk = new SoundFile(app, base + "/funk drum.mp3");
    labels = GENRE_NAMES;
  }

  void onOsc(float v) {
    int raw = mapToIndexWithHysteresis(v);
    if (raw == UNKNOWN) { // 모호 구간 → 대기
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
            println("[DRUM CONFIRMED] → " + label(current));
            trigger(current);
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

    // 루프 매니저가 있으면 거기에 위임 (박자에 맞춰 교체)
    if (loopQuantizer != null) {
      stopAll();
      loopQuantizer.queueClip(0, genre);
      return;
    }

    stopAll();

    if (genre == 0) jazz.play();
    else if (genre == 1) hiphop.play();
    else if (genre == 2) funk.play();
  }

  void stopAll() {
    if (jazz != null) jazz.stop();
    if (hiphop != null) hiphop.stop();
    if (funk != null) funk.stop();
  }

  int getCurrentGenre() {
    return current;
  }

  boolean canChange() {
    return (millis() - lastChangeMillis) > minHoldTime;
  }

  // 히스테리시스 + strict window (Rest 제거, 3개 구간)
  int mapToIndexWithHysteresis(float v) {
    // 유지 구간: 약간 넓게
    // Jazz: 화면이 위로 (값↓)
    // HipHop: 오른손 기준 화면을 앞(Z축)으로 90도 눕히고, X축 앞뒤로 기울고, Y축은 폰 옆면이 좌우를 향함
    // Funk: 화면이 아래(값↑)
    if (current == 0 && v >= 0.05 && v <= 0.35) return 0;
    if (current == 1 && v >= 0.35 && v <= 0.65) return 1;
    if (current == 2 && v >= 0.60 && v <= 0.95) return 2;

    // 진입 구간: 좁게
    if (v >= 0.10 && v <= 0.30) return 0;
    if (v >= 0.45 && v <= 0.55) return 1;
    if (v >= 0.75 && v <= 0.90) return 2;

    return UNKNOWN; // 모호
  }

  String label(int idx) {
    if (labels == null || idx < 0 || idx >= labels.length) return "Unknown";
    return labels[idx];
  }
}
