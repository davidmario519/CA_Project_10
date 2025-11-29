// ==============================================
// 6_CA_Project_10.pde — MAIN ENTRY
// 전체 실행 흐름 컨트롤
// ==============================================

import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress wek;

// Layer Classes
MotionReceiver motion;

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

  // MotionReceiver 생성
  motion = new MotionReceiver();

  // OSC (Wekinator Output 포트: 12000)
  osc = new OscP5(this, 12000);
  wek = new NetAddress("127.0.0.1", 6448);

  // Controller 초기화
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

  // Smartphone Motion Receiver
  motion.onOsc(m);

  // Wekinator Output
  if (m.checkAddrPattern("/wek/outputs")) {
    handleWekinatorOutput(m);
  }
}
