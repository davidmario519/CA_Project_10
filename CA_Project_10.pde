// =======================================================
// Trio Loop – B 방식 (iOS Wekinator App direct input)
// MotionReceiver 제거 + 스마트폰 벡터 자동 수신
// =======================================================

import processing.sound.*;
import oscP5.*;
import netP5.*;

// OSC
OscP5 oscIn;

// 3개의 Wekinator 모델
NetAddress drumWek;
NetAddress guitarWek;
NetAddress vocalWek;

// 스마트폰에서 받을 input vector (동적 크기)
float[] inputVector = new float[0];   
int numInputs = 0;

// Output results
int drumGenre = 0;
int guitarGenre = 0;
int vocalGenre = 0;

String[] GENRE_NAMES = { "Jazz", "HipHop", "Cinematic" };

// Wekinator 출력 시작값: 보통 1(1,2,3)이나 환경에 따라 0 또는 2일 수 있음
int WEK_BASE_VALUE = 1; // 필요 시 0 또는 2로 조정

// Audio triggers
DrumTrigger drumTrigger;
GuitarTrigger guitarTrigger;
VocalTrigger vocalTrigger;

void setup() {
  size(900, 600);
  pixelDensity(1);   // 고해상도 경고 제거
  surface.setTitle("Trio Loop – B 방식 (3 Wekinator Models - Direct Input)");

  // iPhone → Processing RAW input
  oscIn = new OscP5(this, 4886);

  // Processing → 3 Wekinator models
  drumWek   = new NetAddress("127.0.0.1", 6448);
  guitarWek = new NetAddress("127.0.0.1", 6449);
  vocalWek  = new NetAddress("127.0.0.1", 6450);

  // Receive outputs
  new OscP5(this, 9000).plug(this, "onDrumOut",   "/drumOut");
  new OscP5(this, 9001).plug(this, "onGuitarOut", "/guitarOut");
  new OscP5(this, 9002).plug(this, "onVocalOut",  "/vocalOut");

  // Prepare audio triggers
  drumTrigger   = new DrumTrigger(this);
  guitarTrigger = new GuitarTrigger(this);
  vocalTrigger  = new VocalTrigger(this);
}

void draw() {
  background(20);
  sendInputsToAllModels();
  drawDebug();
}

// =======================================================
// 스마트폰에서 직접 오는 /wek/inputs 메시지를 받기
// =======================================================
void oscEvent(OscMessage m) {

  println("ANY OSC RECEIVED:", m.addrPattern());

  if (m.checkAddrPattern("/wek/inputs")) {

    numInputs = m.arguments().length;

    // inputVector 크기 자동 조정
    if (inputVector.length != numInputs) {
      inputVector = new float[numInputs];
    }

    for (int i = 0; i < numInputs; i++) {
      inputVector[i] = m.get(i).floatValue();
    }

    println("SMARTPHONE INPUT VECTOR:", java.util.Arrays.toString(inputVector));
  }
}

// =======================================================
// 3개의 Wekinator 모델로 inputVector 전송
// =======================================================
void sendInputsToAllModels() {

  if (numInputs == 0) return; // 아직 입력 없음 → 전송 안함

  OscMessage msg = new OscMessage("/wek/inputs");
  for (int i = 0; i < numInputs; i++) {
    msg.add(inputVector[i]);
  }

  oscIn.send(msg, drumWek);
  oscIn.send(msg, guitarWek);
  oscIn.send(msg, vocalWek);
}

// =======================================================
// 3 Output Handlers
// =======================================================
// ===========================
// DRUM Output 안정화 (25프레임 버퍼)
// ===========================
int currentDrum = 0;
int pendingDrum = 0;
int pendingDrumCount = 0;
int drumThreshold = 25;

public void onDrumOut(float v) {
  int raw = mapWekOutputToIndex(v);   // base 값 보정 후 0-based

  if (raw == pendingDrum) {
    pendingDrumCount++;
    if (pendingDrumCount >= drumThreshold) {
      if (raw != currentDrum) {
        currentDrum = raw;
        println("[DRUM CONFIRMED] → " + genreLabel(currentDrum));
        if (drumTrigger != null) drumTrigger.trigger(currentDrum);
      }
    }
  } else {
    pendingDrum = raw;
    pendingDrumCount = 1;
  }

  drumGenre = currentDrum;
}

// ===========================
// GUITAR Output 안정화 (25프레임 버퍼)
// ===========================
int currentGuitar = 0;
int pendingGuitar = 0;
int pendingGuitarCount = 0;
int guitarThreshold = 25;

public void onGuitarOut(float v) {
  int raw = mapWekOutputToIndex(v);

  if (raw == pendingGuitar) {
    pendingGuitarCount++;
    if (pendingGuitarCount >= guitarThreshold) {
      if (raw != currentGuitar) {
        currentGuitar = raw;
        println("[GUITAR CONFIRMED] → " + genreLabel(currentGuitar));
        if (guitarTrigger != null) guitarTrigger.trigger(currentGuitar);
      }
    }
  } else {
    pendingGuitar = raw;
    pendingGuitarCount = 1;
  }

  guitarGenre = currentGuitar;
}

// ===========================
// VOCAL Output 안정화 (25프레임 버퍼)
// ===========================
int currentVocal = 0;
int pendingVocal = 0;
int pendingVocalCount = 0;
int vocalThreshold = 25;

public void onVocalOut(float v) {
  int raw = mapWekOutputToIndex(v);

  if (raw == pendingVocal) {
    pendingVocalCount++;
    if (pendingVocalCount >= vocalThreshold) {
      if (raw != currentVocal) {
        currentVocal = raw;
        println("[VOCAL CONFIRMED] → " + genreLabel(currentVocal));
        if (vocalTrigger != null) vocalTrigger.trigger(currentVocal);
      }
    }
  } else {
    pendingVocal = raw;
    pendingVocalCount = 1;
  }

  vocalGenre = currentVocal;
}

// Guard against invalid indexes coming from OSC
int clampGenreIndex(int value) {
  return constrain(value, 0, GENRE_NAMES.length - 1);
}

int mapWekOutputToIndex(float v) {
  int zeroBased = round(v) - WEK_BASE_VALUE; // base 값을 빼서 0-based로 변환
  return clampGenreIndex(zeroBased);
}

String genreLabel(int idx) {
  if (idx < 0 || idx >= GENRE_NAMES.length) return "Unknown";
  return GENRE_NAMES[idx];
}

// =======================================================
// Debug UI
// =======================================================
void drawDebug() {

  fill(255);
  textSize(18);

  text("=== SmartPhone Input Vector ===", 30, 60);
  for (int i = 0; i < numInputs; i++) {
    text("Input " + i + ": " + inputVector[i], 30, 90 + i * 20);
  }

  text("DRUM OUT : " + genreLabel(drumGenre), 30, 300);
  text("GUITAR OUT : " + genreLabel(guitarGenre), 30, 330);
  text("VOCAL OUT  : " + genreLabel(vocalGenre), 30, 360);
}
