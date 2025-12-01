class VocalTrigger {

  String[] labels;

  // 보컬 전용: 2단계 구조 (Classifier + Continuous)
  int current = REST;          // 화면 표시용 현재 상태
  boolean ready = true;        // Classifier가 Rest일 때 true
  int activeStartMillis = 0;   // 입을 연 시점 기록
  int minActiveDuration = 500; // ms: 최소 0.5초 이상 입을 열어야 반응

  VocalTrigger(PApplet app) {
    labels = GENRE_NAMES;
  }

  // classifier(1=Rest, 2=Active), continuous(0.25/0.50/0.75 근처)
  void onOsc(float classifierVal, float continuousVal) {
    int cls = mapClassifier(classifierVal);
    if (cls == REST) {
      ready = true;
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
    if (loopQuantizer != null) {
      loopQuantizer.queueClip(2, genre); // Column 2 for Vocal
    }
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
    if (v >= 0.65 && v <= 0.85) return 2; // funk ~0.75
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
