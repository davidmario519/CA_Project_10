// =======================================================
// Trio Loop – B 방식 (iOS Wekinator App direct input)
// MotionReceiver 제거 + 스마트폰 벡터 자동 수신
// =======================================================

import oscP5.*;
import netP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

// OSC
OscP5 oscIn;

// Wekinator
NetAddress drumWek;
NetAddress guitarWek;
NetAddress vocalWek;

// Inputs
float[] inputVector = new float[0];   
int numInputs = 0;
FaceReceiver faceReceiver;
FaceFeatureExtractor faceFeatures;
float[] vocalInputs = new float[0];
MPHandReceiver handReceiver;
MPFeatureExtractor handFeatures;
float[] guitarInputs = new float[0];

// Outputs
int drumGenre = -1;
int guitarGenre = -1;
int vocalGenre = -1;

// Core Logic
String[] GENRE_NAMES = { "Jazz", "HipHop", "Funk" };
DrumTrigger drumTrigger;
GuitarTrigger guitarTrigger;
VocalTrigger vocalTrigger;
TimeQuantizer loopQuantizer;

// Audio & Visuals
Minim minim;
CombinedVisualizer comboViz;
// We need FFTs for each instrument channel
ddf.minim.analysis.FFT fftVocal;
ddf.minim.analysis.FFT fftGuitar;
ddf.minim.analysis.FFT fftDrum;

// OSC Ports and Debug Flags
final int FACE_OSC_PORT = 8338;
final int HAND_OSC_PORT = 7000;
boolean FACE_DEBUG = false;
boolean HAND_DEBUG = true;
boolean VOCAL_DEBUG = true;
boolean GUITAR_DEBUG = true;
boolean LOOP_DEBUG = true;

// 개별 수신용 OscP5 인스턴스 보관 (경고 제거용)
OscP5 faceOsc;
OscP5 handOsc;


void setup() {
  size(900, 600);
  pixelDensity(1);
  surface.setTitle("Trio Loop – Unified Audio Engine");

  // Central Audio Engine
  minim = new Minim(this);

  // OSC Input from devices
  oscIn = new OscP5(this, 4886); // iPhone
  faceOsc = new OscP5(this, FACE_OSC_PORT); // FaceOSC
  handOsc = new OscP5(this, HAND_OSC_PORT); // MediaPipe Hand

  // OSC Output to Wekinator
  drumWek   = new NetAddress("127.0.0.1", 6448);
  guitarWek = new NetAddress("127.0.0.1", 6449);
  vocalWek  = new NetAddress("127.0.0.1", 6450);

  // OSC Input from Wekinator
  new OscP5(this, 9000).plug(this, "onDrumOut",   "/drumOut");
  new OscP5(this, 9001).plug(this, "onGuitarOut", "/guitarOut");
  new OscP5(this, 9002).plug(this, "onVocalOut",  "/vocalOut");
  
  // Feature Extractors
  faceReceiver = new FaceReceiver();
  faceFeatures = new FaceFeatureExtractor(faceReceiver);
  handReceiver = new MPHandReceiver();
  handFeatures = new MPFeatureExtractor(handReceiver);
  
  // Visualizer
  comboViz = new CombinedVisualizer(this);
  
  // Triggers (no audio playback)
  drumTrigger   = new DrumTrigger(this);
  guitarTrigger = new GuitarTrigger(this);
  vocalTrigger  = new VocalTrigger(this);

  // Central Quantizer & Audio Player
  loopQuantizer = new TimeQuantizer(this, minim, GENRE_NAMES);
  
  // FFT objects are created here but connected to audio sources in drawVisuals
  // This assumes all clips have the same buffer size (e.g., 2048)
  fftVocal = new ddf.minim.analysis.FFT(2048, 44100);
  fftGuitar = new ddf.minim.analysis.FFT(2048, 44100);
  fftDrum = new ddf.minim.analysis.FFT(2048, 44100);
}

void draw() {
  background(0);
  drawVisuals();
  sendDrumInputs();
  updateAndSendVocalInputs();
  updateAndSendGuitarInputs();
  if (loopQuantizer != null) loopQuantizer.update();
  drawDebug();
}

void drawVisuals() {
  if (comboViz == null || loopQuantizer == null) return;

  // Get the currently playing audio for each instrument
  AudioPlayer vocalPlayer = loopQuantizer.getPlayingAudioPlayer(2); // 2: Vocal
  AudioPlayer guitarPlayer = loopQuantizer.getPlayingAudioPlayer(1); // 1: Guitar
  AudioPlayer drumPlayer = loopQuantizer.getPlayingAudioPlayer(0); // 0: Drum

  // Connect FFTs to the currently playing audio sources
  if (vocalPlayer != null) fftVocal.forward(vocalPlayer.mix);
  if (guitarPlayer != null) fftGuitar.forward(guitarPlayer.mix);
  if (drumPlayer != null) fftDrum.forward(drumPlayer.mix);

  // Draw the combined visualizer
  comboViz.drawAll(vocalPlayer, fftVocal, 
                   guitarPlayer, fftGuitar, 
                   drumPlayer, fftDrum,
                   vocalGenre, guitarGenre, drumGenre);
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

  // Pass messages to the appropriate receivers
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
    // if (visWindow != null && drumGenre >= 0 && drumGenre != prev) {
    //   visWindow.setDrum(drumGenre);
    }
  }


public void onGuitarOut(float classifierVal, float genreVal) {
  if (guitarTrigger != null) {
    if (GUITAR_DEBUG) {
      println("[GUITAR OUT RAW] cls=" + classifierVal + " genre=" + genreVal);
    }
    int prev = guitarGenre;
    guitarTrigger.onOsc(classifierVal, genreVal);
    guitarGenre = guitarTrigger.getCurrentGenre();
    if (loopQuantizer != null && guitarGenre >= 0 && guitarGenre != prev) {
      loopQuantizer.queueClip(1, guitarGenre);
    }
    // if (visWindow != null && guitarGenre >= 0 && guitarGenre != prev) {
    //   visWindow.setGuitar(guitarGenre);
    // }
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
    // if (visWindow != null && vocalGenre >= 0 && vocalGenre != prev) {
    //   visWindow.setVocal(vocalGenre);
    }
    if (VOCAL_DEBUG) {
      println("[VOCAL STATE] current=" + genreLabel(vocalGenre));
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

  // fill(255);
  // textSize(18);

  // text("=== SmartPhone Input Vector ===", 30, 60);
  // for (int i = 0; i < numInputs; i++) {
  //   text("Input " + i + ": " + inputVector[i], 30, 90 + i * 20);
  // }

  // text("DRUM OUT : " + genreLabel(drumGenre), 30, 300);
  // text("GUITAR OUT : " + genreLabel(guitarGenre), 30, 330);
  // text("VOCAL OUT  : " + genreLabel(vocalGenre), 30, 360);

  // if (loopQuantizer != null) {
  //   text("LOOP DRUM  : " + loopQuantizer.playingLabel(0), 30, 420);
  //   text("LOOP GUITAR: " + loopQuantizer.playingLabel(1), 30, 450);
  //   text("LOOP VOCAL : " + loopQuantizer.playingLabel(2), 30, 480);
  //   text("BEAT #" + loopQuantizer.currentBeat() + " (q=" + loopQuantizer.quantization + ", bpm=" + loopQuantizer.bpm + ")", 30, 510);
  // }
}

// 키로 루프 큐잉: qwe / asd / zxc
void keyPressed() {
  if (loopQuantizer != null) {
    loopQuantizer.handleKey(key);
  }

  // Also update genre state for visuals when keys are used
  char k = Character.toLowerCase(key);
  if (k == 'q') drumGenre = 0;
  if (k == 'w') drumGenre = 1;
  if (k == 'e') drumGenre = 2;

  if (k == 'a') guitarGenre = 0;
  if (k == 's') guitarGenre = 1;
  if (k == 'd') guitarGenre = 2;

  if (k == 'z') vocalGenre = 0;
  if (k == 'x') vocalGenre = 1;
  if (k == 'c') vocalGenre = 2;
}
