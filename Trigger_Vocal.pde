class VocalTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile funk;

  int last = -1;
  String base = "data"; // 오디오 파일이 있는 기본 폴더
  String[] labels;

  // 보컬 전용: 2단계 구조 (Classifier + Continuous)
  int current = REST;          // 화면 표시용 현재 상태
  boolean ready = true;        // Classifier가 Rest일 때 true
  int activeStartMillis = 0;   // 입을 연 시점 기록
  int minActiveDuration = 500; // ms: 최소 0.5초 이상 입을 열어야 반응

  VocalTrigger(PApplet app) {

    jazz      = new SoundFile(app, base + "/jazz vocal.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop vocal.mp3");
    funk = new SoundFile(app, base + "/funk vocal.mp3");
    labels = GENRE_NAMES;
  }

  // classifier(1=Rest, 2=Active), continuous(0.25/0.50/0.75 근처)
  void onOsc(float classifierVal, float continuousVal) {
    int cls = mapClassifier(classifierVal);
    if (cls == REST) {
      ready = true;
      last = REST;       // 입을 닫았다가 다시 열면 같은 continuous여도 재생 허용
      activeStartMillis = 0; // 타이머 리셋
      if (VOCAL_DEBUG) println("[VOCAL] REST (hold last)");
      return;
    }

    if (cls != ACTIVE) return; // 모호하면 무시

    // 입 연 지 0.5초 미만이면 무시 (짧게 열었다 닫는 것 필터)
    if (activeStartMillis == 0) {
      activeStartMillis = millis();
      return;
    }
    if (millis() - activeStartMillis < minActiveDuration) return;

    int genre = mapGenre(continuousVal);
    if (genre < 0) return;     // 모호한 continuous 구간

    // ready == true면 직전에 입을 닫았다가 다시 연 상태 → 같은 장르라도 재트리거 허용
    if (ready || genre != current) {
      current = genre;
      trigger(genre);
      ready = false;             // 다시 입을 닫을 때까지 잠금
      if (VOCAL_DEBUG) println("[VOCAL TRIGGER] " + label(genre));
    }
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

  int getCurrentGenre() {
    return current;
  }

  // Classifier: 1 → Rest, 2 → Active
  int mapClassifier(float v) {
    if (v >= 0.5 && v <= 1.5) return REST;
    if (v >= 1.5 && v <= 2.5) return ACTIVE;
    return UNKNOWN;
  }

  // Continuous: strict window
  int mapGenre(float v) {
    if (v >= 0.15 && v <= 0.35) return 0; // Jazz ~0.25
    if (v >= 0.40 && v <= 0.60) return 1; // HipHop ~0.50
    if (v >= 0.65 && v <= 0.85) return 2; // Cinematic ~0.75
    return UNKNOWN;
  }

  String label(int idx) {
    if (idx == REST) return "Rest";
    if (labels == null || idx < 0 || idx >= labels.length) return "Unknown";
    return labels[idx];
  }

  static final int REST = -1;
  static final int ACTIVE = 10;
  static final int UNKNOWN = -2;
}
