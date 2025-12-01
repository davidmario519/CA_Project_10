// TimeQuantizer: 박자(quantization)에 맞춰 루프를 교체/재생하는 매니저
// - 컬럼 0: Drum, 1: Guitar, 2: Vocal
// - 장르 인덱스는 GENRE_NAMES와 동일 순서 사용 (0=Jazz, 1=HipHop, 2=Funk)

class TimeQuantizer {

  PApplet app;
  int bpm = 120;         // 기본 BPM
  int quantization = 4;  // 몇 박마다 교체할지 (4면 1마디)

  int msPerBeat;
  long referenceTime;
  int lastCheckedBeat = -1;

  Clip[] clips = new Clip[9]; // 3장르 x 3컬럼

  String[] genreKeys = { "jazz", "hiphop", "funk" };
  String[] instKeys = { "drum", "guitar", "vocal" };
  String[] instShort = { "D", "G", "V" };
  String[] genreNames;

  // 루프 길이(beat) 추정값: 필요 시 조정 가능
  int[][] lengths = {
    { 16, 16, 16 }, // Jazz
    { 16, 16, 8  }, // HipHop
    { 16, 16, 16 }  // Funk
  };

  TimeQuantizer(PApplet app, String[] genreNames) {
    this.app = app;
    this.genreNames = genreNames;
    msPerBeat = 60000 / bpm;
    referenceTime = app.millis();

    int idx = 0;
    for (int g = 0; g < genreKeys.length; g++) {
      for (int c = 0; c < instKeys.length; c++) {
        String path = genreKeys[g] + "_" + instKeys[c] + ".mp3";
        String display = genreNames[g] + " " + instShort[c];
        int len = lengths[g][c];
        clips[idx] = new Clip(app, path, len, display, c, g, idx);
        idx++;
      }
    }
  }

  void setBpm(int bpm) {
    if (bpm <= 0) return;
    this.bpm = bpm;
    msPerBeat = 60000 / bpm;
    referenceTime = app.millis();
  }

  void setQuantization(int q) {
    if (q <= 0) return;
    quantization = q;
  }

  void update() {
    int beatNow = (int)((app.millis() - referenceTime) / msPerBeat);
    if (beatNow > lastCheckedBeat) {
      onGlobalBeat(beatNow);
      lastCheckedBeat = beatNow;
    }
  }

  void queueClip(int colIndex, int genreIndex) {
    if (colIndex < 0 || colIndex >= instKeys.length) return;
    if (genreIndex < 0 || genreIndex >= genreKeys.length) return;

    int idx = genreIndex * instKeys.length + colIndex;
    Clip c = clips[idx];
    if (c == null) return;

    // 이미 재생 중인 클립을 다시 클릭하면 해당 컬럼 전체를 정지
    if (c.isPlaying) {
      stopColumn(colIndex);
      return;
    }

    // 같은 컬럼에 대기 중인 다른 클립은 취소
    cancelQueuedInColumn(colIndex, idx);
    c.isQueued = true;
  }

  void stopColumn(int colIndex) {
    stopOthersInColumn(colIndex, -1);
  }

  String playingLabel(int colIndex) {
    for (Clip c : clips) {
      if (c.colIndex == colIndex && c.isPlaying) {
        return c.name;
      }
    }
    return "None";
  }

  // 내부: 박자 변화 시 호출
  void onGlobalBeat(int beat) {
    if (beat % quantization != 0) return;

    for (Clip c : clips) {
      if (c.isQueued) {
        stopOthersInColumn(c.colIndex, c.id);
        c.launch();
      }
    }
  }

  void stopOthersInColumn(int col, int exceptionId) {
    for (Clip c : clips) {
      if (c.colIndex == col && c.id != exceptionId) {
        if (c.isPlaying) c.stop();
        c.isQueued = false;
      }
    }
  }

  void cancelQueuedInColumn(int col, int exceptionId) {
    for (Clip c : clips) {
      if (c.colIndex == col && c.id != exceptionId) {
        c.isQueued = false;
      }
    }
  }

  // 디버그용: 현재 박자 반환
  int currentBeat() {
    return (int)((app.millis() - referenceTime) / msPerBeat);
  }

  // 키보드 매핑: qwe / asd / zxc → (genre row, instrument col)
  void handleKey(char keyChar) {
    char k = Character.toLowerCase(keyChar);
    char[][] map = {
      { 'q', 'w', 'e' }, // Jazz row
      { 'a', 's', 'd' }, // HipHop row
      { 'z', 'x', 'c' }  // Funk row
    };
    for (int r = 0; r < map.length; r++) {
      for (int c = 0; c < map[r].length; c++) {
        if (map[r][c] == k) {
          queueClip(c, r);
          return;
        }
      }
    }
  }

  // ---------------------------------------------------
  // 간단한 그리드 UI (x,y,w,h 영역 안에 3x3 버튼)
  // ---------------------------------------------------
  void drawUI(int x, int y, int w, int h) {
    int cols = instKeys.length;
    int rows = genreKeys.length;
    int cellW = w / cols;
    int cellH = h / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        int idx = r * cols + c;
        Clip cl = clips[idx];
        int px = x + c * cellW;
        int py = y + r * cellH;

        if (cl.isPlaying) {
          app.fill(0, 200, 100);
        } else if (cl.isQueued) {
          if (app.frameCount % 15 < 7) app.fill(255, 200, 0);
          else app.fill(200, 150, 0);
        } else {
          app.fill(60);
        }
        app.stroke(0);
        app.rect(px, py, cellW, cellH);

        app.fill(255);
        String label = genreNames[r] + " " + instShort[c];
        app.textAlign(app.CENTER, app.CENTER);
        app.text(label, px + cellW / 2, py + cellH / 2);
      }
    }
  }

  // UI 클릭 처리
  void handleClick(int mx, int my, int x, int y, int w, int h) {
    int cols = instKeys.length;
    int rows = genreKeys.length;
    if (mx < x || my < y || mx >= x + w || my >= y + h) return;

    int cellW = w / cols;
    int cellH = h / rows;
    int col = (mx - x) / cellW;
    int row = (my - y) / cellH;
    queueClip(col, row);
  }
}

class Clip {
  SoundFile sound;
  boolean isPlaying = false;
  boolean isQueued = false;
  int lengthInBeats;
  String name;
  int colIndex;
  int genreIndex;
  int id;

  Clip(PApplet app, String path, int len, String n, int col, int genre, int id) {
    this.sound = new SoundFile(app, path);
    this.lengthInBeats = len;
    this.name = n;
    this.colIndex = col;
    this.genreIndex = genre;
    this.id = id;
  }

  void launch() {
    isQueued = false;
    if (!isPlaying) {
      play();
    }
  }

  void play() {
    isPlaying = true;
    sound.loop();
    println(name + " -> Playing");
  }

  void stop() {
    isPlaying = false;
    isQueued = false;
    sound.stop();
    println(name + " -> Stopped");
  }
}
