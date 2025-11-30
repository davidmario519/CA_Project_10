// ==============================================
// 6_CA_Project_10.pde — MAIN ENTRY
// 전체 실행 흐름 컨트롤
// ==============================================

import oscP5.*;
import netP5.*;
import processing.sound.*;

OscP5 osc;
NetAddress wekDrum;
NetAddress wekGuitar;
NetAddress wekVocal;

// Layer Classes
MotionReceiver motion;
DrumTrigger drumTrigger;
MLOutputClient mlOut;

// Font
PFont kor;

// ----------------------------------------------
// setup()
// ----------------------------------------------
void setup() {

  size(900, 600);

  kor = createFont("DXPnM-KSCpc-EUC-H.ttf", 24, true);
  textFont(kor);

  surface.setTitle("Trio Loop Machine – MAIN");

  // Drum 사운드 트리거
  drumTrigger = new DrumTrigger(this);

  // Wekinator Output 리스너 (드럼/기타/보컬 모두 갱신)
  mlOut = new MLOutputClient(new MLOutputListener() {
    public void onWekinatorOutput(int drum, int g, int v) {
      handleWekinatorOutputValues(drum, g, v);
    }
  });

  // MotionReceiver 생성
  motion = new MotionReceiver();

  // OSC 수신 (MotionSender + 모든 Wekinator 출력 동일 포트 4886)
  osc = new OscP5(this, 4886);

  // Wekinator 입력 포트 (드럼/기타/보컬 개별)
  wekDrum   = new NetAddress("127.0.0.1", 6448);
  wekGuitar = new NetAddress("127.0.0.1", 6450);
  wekVocal  = new NetAddress("127.0.0.1", 6452);

  // Controller 초기화
  mlIn = new MLInputClient(osc);
  initInputVector();
}

// ----------------------------------------------
// draw()
// ----------------------------------------------
void draw() {

  background(20);

  // Input Layer → Feature Layer
  updateFeaturesFromSensors();

  // Send to Wekinator
  sendInputsToWekinator();

  // Debug
  drawDebugUI();
}

// ----------------------------------------------
// OSC Event Handler
// ----------------------------------------------
void oscEvent(OscMessage m) {

  String addr = m.addrPattern();

  // 1) Smartphone MotionSender (raw sensor)
  if (addr.equals("/accel") || addr.equals("/gyro") || addr.equals("/gravity")) {
    motion.onOsc(m);
    return;
  }

  // 2) Wekinator input 에코/컨트롤 무시
  if (addr.equals("/wek/inputs")) return;
  if (addr.startsWith("/wekinator/control")) return;

  // 3) Wekinator OUTPUT (모델별 주소 포함)
  if (addr.equals("/wek/outputs") ||
      addr.equals("/wek/drum_out") ||
      addr.equals("/wek/guitar_out") ||
      addr.equals("/wek/vocal_out")) {
    mlOut.onOsc(m);
    return;
  }

  // 4) Debugging
  println("RX", addr, m.arguments().length);
}
