class GuitarTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;

  int last = -1;
  String base = "data"; // 오디오 파일이 있는 기본 폴더
  String[] labels;

  int current = REST;          // 화면 표시용 현재 상태
  boolean ready = true;        // output1이 REST(1)일 때 true로 풀림

  static final int REST = -1;
  static final int UNKNOWN = -2;
  static final int ACTIVE = 10;

  GuitarTrigger(PApplet app) {
    jazz      = new SoundFile(app, base + "/jazz/jazz guitar.mp3");
    hiphop    = new SoundFile(app, base + "/hiphop/hiphop guitar.mp3");
    cinematic = new SoundFile(app, base + "/cinematic/cinematic guitar.mp3");
    labels = GENRE_NAMES;
  }

  // classifierVal: output1 (1=오른손 펴기/REST, 2=스트록 직후 상태)
  // genreVal:      output2 (class 1/2/3 → 장르)
  void onOsc(float classifierVal, float genreVal) {
    int cls = mapClassifier(classifierVal);

    // REST 상태: 장르 유지, 다음 ACTIVE 때 재트리거 허용
    if (cls == REST) {
      ready = true;
      if (GUITAR_DEBUG) println("[GUITAR] REST (hold last)");
      return;
    }

    if (cls != ACTIVE) return; // 모호 구간 무시

    int genre = mapGenre(genreVal);
    if (genre < 0) return;     // 장르 값이 모호하면 무시

    // ready면 직전 REST를 거친 상태 → 같은 장르라도 다시 트리거 허용
    if (ready || genre != current) {
      current = genre;
      trigger(genre);
      ready = false;           // 다시 REST가 올 때까지 잠금
      if (GUITAR_DEBUG) println("[GUITAR TRIGGER] " + label(genre));
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

  // output1: 1 → REST(손 펴기), 2 → ACTIVE(스트록 후)
  int mapClassifier(float v) {
    if (v >= 0.5 && v <= 1.5) return REST;
    if (v >= 1.5 && v <= 2.5) return ACTIVE;
    return UNKNOWN;
  }

  // output2: class 1/2/3 → 장르 매핑
  int mapGenre(float v) {
    if (v >= 0.5 && v <= 1.5) return 0; // class1 → Jazz
    if (v >= 1.5 && v <= 2.5) return 1; // class2 → HipHop
    if (v >= 2.5 && v <= 3.5) return 2; // class3 → Cinematic
    return UNKNOWN;
  }

  String label(int idx) {
    if (idx == REST) return "Rest";
    if (labels == null || idx < 0 || idx >= labels.length) return "Unknown";
    return labels[idx];
  }
}
