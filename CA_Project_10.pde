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
int drumGenre = -1;
int guitarGenre = -1;
int vocalGenre = -1;

String[] GENRE_NAMES = { "Jazz", "HipHop", "Funk" };

// Wekinator 출력 시작값: 보통 1(1,2,3)이나 환경에 따라 0 또는 2일 수 있음
final int FACE_OSC_PORT = 8338;
final int HAND_OSC_PORT = 7000;
boolean FACE_DEBUG = false;
boolean HAND_DEBUG = false;
boolean VOCAL_DEBUG = true;   // Vocal 파이프라인 디버그 로그

// Audio triggers
DrumTrigger drumTrigger;
GuitarTrigger guitarTrigger;
VocalTrigger vocalTrigger;
TimeQuantizer loopQuantizer;

// FaceOSC 입력 + feature
FaceReceiver faceReceiver;
FaceFeatureExtractor faceFeatures;
float[] vocalInputs = new float[0];

// MediaPipe 손 입력 + feature
MPHandReceiver handReceiver;
MPFeatureExtractor handFeatures;
float[] guitarInputs = new float[0];

// 개별 수신용 OscP5 인스턴스 보관 (경고 제거용)
OscP5 faceOsc;
OscP5 handOsc;

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
  faceOsc = new OscP5(this, FACE_OSC_PORT); // FaceOSC 입력
  handOsc = new OscP5(this, HAND_OSC_PORT); // MediaPipe 손 입력

  faceReceiver = new FaceReceiver();
  faceFeatures = new FaceFeatureExtractor(faceReceiver);

  handReceiver = new MPHandReceiver();
  handFeatures = new MPFeatureExtractor(handReceiver);

  // Prepare audio triggers
  drumTrigger   = new DrumTrigger(this);
  guitarTrigger = new GuitarTrigger(this);
  vocalTrigger  = new VocalTrigger(this);

  // 박자 정렬 루프 매니저
  loopQuantizer = new TimeQuantizer(this, GENRE_NAMES);
}

void draw() {
  background(20);
  sendDrumInputs();
  updateAndSendVocalInputs();
  updateAndSendGuitarInputs();
  if (loopQuantizer != null) loopQuantizer.update();
  drawDebug();
}

// =======================================================
// 스마트폰에서 직접 오는 /wek/inputs 메시지를 받기
// =======================================================
void oscEvent(OscMessage m) {

  if (m.checkAddrPattern("/wek/inputs")) {

    numInputs = m.arguments().length;

    // inputVector 크기 자동 조정
    if (inputVector.length != numInputs) {
      inputVector = new float[numInputs];
    }

    for (int i = 0; i < numInputs; i++) {
      inputVector[i] = m.get(i).floatValue();
    }
  }

  if (faceReceiver != null) faceReceiver.onOsc(m);
  if (handReceiver != null) handReceiver.onOsc(m);
}

// =======================================================
// 스마트폰 → Drum Wekinator 전송
// =======================================================
void sendDrumInputs() {

  if (numInputs == 0) return; // 아직 입력 없음 → 전송 안함

  OscMessage msg = new OscMessage("/wek/inputs");
  for (int i = 0; i < numInputs; i++) {
    msg.add(inputVector[i]);
  }

  oscIn.send(msg, drumWek);
}

// FaceOSC → Vocal Wekinator 입력 전송
void updateAndSendVocalInputs() {
  if (faceFeatures == null) return;

  float[] tmp = faceFeatures.buildVocalInputs();
  if (tmp == null || tmp.length == 0) return;

  vocalInputs = tmp;

  OscMessage msg = new OscMessage("/wek/inputs");
  for (int i = 0; i < vocalInputs.length; i++) {
    msg.add(vocalInputs[i]);
  }
  oscIn.send(msg, vocalWek);

  if (FACE_DEBUG) {
    println("FaceOSC features →", java.util.Arrays.toString(vocalInputs));
  }
}

// MediaPipe → Guitar Wekinator 입력 전송
void updateAndSendGuitarInputs() {
  if (handFeatures == null) return;

  float[] tmp = handFeatures.buildGuitarInputs();
  if (tmp == null || tmp.length == 0) return;

  guitarInputs = tmp;

  OscMessage msg = new OscMessage("/wek/inputs");
  for (int i = 0; i < guitarInputs.length; i++) {
    msg.add(guitarInputs[i]);
  }
  oscIn.send(msg, guitarWek);

  if (HAND_DEBUG) {
    println("Hand features →", java.util.Arrays.toString(guitarInputs));
  }
}

// =======================================================
// 3 Output Handlers (경량 래퍼: 안정화/매핑은 Trigger 클래스에 위임)
public void onDrumOut(float v) {
  if (drumTrigger != null) {
    int prev = drumGenre;
    drumTrigger.onOsc(v);
    drumGenre = drumTrigger.getCurrentGenre();
    if (loopQuantizer != null && drumGenre >= 0 && drumGenre != prev) {
      loopQuantizer.queueClip(0, drumGenre);
    }
  }
}

public void onGuitarOut(float v) {
  if (guitarTrigger != null) {
    int prev = guitarGenre;
    guitarTrigger.onOsc(v);
    guitarGenre = guitarTrigger.getCurrentGenre();
    if (loopQuantizer != null && guitarGenre >= 0 && guitarGenre != prev) {
      loopQuantizer.queueClip(1, guitarGenre);
    }
  }
}

public void onVocalOut(float classifierVal, float continuousVal) {
  if (vocalTrigger != null) {
    if (VOCAL_DEBUG) {
      println("[VOCAL OUT RAW] cls=" + classifierVal + " cont=" + continuousVal);
    }
    vocalTrigger.onOsc(classifierVal, continuousVal);
    int prev = vocalGenre;
    vocalGenre = vocalTrigger.getCurrentGenre();
    if (loopQuantizer != null && vocalGenre >= 0 && vocalGenre != prev) {
      loopQuantizer.queueClip(2, vocalGenre);
    }
    if (VOCAL_DEBUG) {
      println("[VOCAL STATE] current=" + genreLabel(vocalGenre));
    }
  }
}

String genreLabel(int idx) {
  if (idx == -1) return "Rest";
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

  if (loopQuantizer != null) {
    text("LOOP DRUM  : " + loopQuantizer.playingLabel(0), 30, 420);
    text("LOOP GUITAR: " + loopQuantizer.playingLabel(1), 30, 450);
    text("LOOP VOCAL : " + loopQuantizer.playingLabel(2), 30, 480);
    text("BEAT #" + loopQuantizer.currentBeat() + " (q=" + loopQuantizer.quantization + ", bpm=" + loopQuantizer.bpm + ")", 30, 510);
    // 오른쪽에 간단한 루프 선택 UI
    loopQuantizer.drawUI(520, 80, 330, 300);
    text("Click grid to queue loop (per instrument column)", 520, 410);
  }
}

// 마우스 클릭으로 루프 큐잉 UI 제어
void mousePressed() {
  if (loopQuantizer != null) {
    loopQuantizer.handleClick(mouseX, mouseY, 520, 80, 330, 300);
  }
}
