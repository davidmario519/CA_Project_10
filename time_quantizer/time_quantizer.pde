import processing.sound.*;

int bpm = 120;
int quantization = 4; // 1마디(4박자) 단위
int msPerBeat;

long referenceTime;
int currentBeat = 0;
int lastCheckedBeat = -1;

Clip[] clips = new Clip[9];

void setup() {
  size(800, 600);

  msPerBeat = 60000 / bpm;
  referenceTime = millis();

  String[] fileNames = {
    "hiphop drum.mp3", "hiphop guitar.mp3", "hiphop vocal.mp3",
    "jazz drum.mp3", "jazz guitar.mp3", "jazz vocal.mp3",
    "funk drum.mp3", "funk guitar.mp3", "funk vocal.mp3"
  };

  String[] displayNames = {
    "HipHop D", "HipHop G", "HipHop V",
    "Jazz D", "Jazz G", "Jazz V",
    "Funk D", "Funk G", "Funk V"
  };

  int[] lengths = {
    16, 16, 8,
    16, 16, 32,
    16, 16, 16
  };

  // 클립 생성
  for (int i = 0; i < clips.length; i++) {
    SoundFile file = new SoundFile(this, fileNames[i]);

    // i % 3을 통해 이 클립이 몇 번째 악기(열)인지 저장
    // 0: Drum, 1: Guitar, 2: Vocal
    int colIndex = i % 3;

    clips[i] = new Clip(file, lengths[i], displayNames[i], colIndex, i);
  }

  textSize(16);
  textAlign(CENTER, CENTER);
}

void draw() {
  background(30);

  int beatNow = (int)((millis() - referenceTime) / msPerBeat);

  if (beatNow > lastCheckedBeat) {
    onGlobalBeat(beatNow);
    lastCheckedBeat = beatNow;
  }

  drawUI(beatNow);
}

// ---------------------------------------------------------
// [핵심 로직 변경] 박자마다 실행되는 함수
// ---------------------------------------------------------
void onGlobalBeat(int beat) {
  boolean isQuantizedPoint = (beat % quantization == 0);

  if (isQuantizedPoint) {
    // 모든 클립을 순회하며 '대기(Queue)' 상태인 녀석을 찾습니다.
    for (Clip c : clips) {
      if (c.isQueued) {

        // 1. 이 클립이 속한 악기 라인(Column)의 다른 클립들을 모두 끕니다.
        stopOthersInColumn(c.colIndex, c.id);

        // 2. 그리고 자신을 재생합니다.
        c.launch();
      }
    }
  }
}

// 같은 악기 라인(col)에 있는 다른 클립들을 강제로 끄는 함수
void stopOthersInColumn(int col, int exceptionId) {
  for (Clip c : clips) {
    // 같은 컬럼(악기)이면서 && 지금 켜지려는 녀석(exception)이 아닌 경우
    if (c.colIndex == col && c.id != exceptionId) {
      if (c.isPlaying) {
        c.stop(); // 즉시 정지
      }
      c.isQueued = false; // 혹시 대기 중이었다면 대기 취소
    }
  }
}
// ---------------------------------------------------------

void mousePressed() {
  int cols = 3;
  int w = width / cols;
  int h = height / 3;

  int col = mouseX / w;
  int row = mouseY / h;
  int index = row * cols + col;

  if (index >= 0 && index < clips.length) {
    clips[index].trigger();
  }
}

class Clip {
  SoundFile sound;
  boolean isPlaying = false;
  boolean isQueued = false;
  int lengthInBeats;
  String name;
  int colIndex; // 0:Drum, 1:Guitar, 2:Vocal
  int id;       // 자신의 고유 번호

  Clip(SoundFile s, int len, String n, int col, int id) {
    this.sound = s;
    this.lengthInBeats = len;
    this.name = n;
    this.colIndex = col;
    this.id = id;
  }

  // 마우스 클릭 시
  void trigger() {
    if (isPlaying) {
      // 이미 재생 중인걸 누르면 -> 정지 (여기서 즉시 끌지, 박자에 맞춰 끌지 선택 가능)
      // 현재는 즉시 정지로 구현 (Ableton도 정지 버튼 누르면 즉시 꺼지는 모드 존재)
      stop();
    } else {
      // 꺼져 있거나 다른게 켜져 있다면 -> "나 킬거야" 라고 예약
      isQueued = true;
    }
  }

  // 실제 재생 시작 (onGlobalBeat에서 호출)
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

void drawUI(int currentBeat) {
  int cols = 3;
  int w = width / cols;
  int h = height / 3;

  for (int i = 0; i < clips.length; i++) {
    int x = (i % cols) * w;
    int y = (i / cols) * h;

    if (clips[i].isPlaying) {
      fill(0, 255, 100);
    } else if (clips[i].isQueued) {
      if (frameCount % 15 < 7) fill(255, 200, 0);
      else fill(200, 150, 0);
    } else {
      fill(60);
    }

    stroke(0);
    rect(x, y, w, h);

    fill(255);
    text(clips[i].name + "\n(" + clips[i].lengthInBeats + ")", x + w/2, y + h/2);
  }

  fill(0, 150);
  rect(0, 0, width, 40);
  fill(255);
  // text("Global Beat: " + currentBeat + " (Bar: " + (currentBeat/4 + 1) + ")", width/2, 20);

  if (currentBeat % quantization == 0) {
    fill(255, 50, 50);
    ellipse(width - 30, 20, 15, 15);
  }
}
