// ==============================================
// 6_CA_Project_10.pde — MAIN ENTRY
// 전체 실행 흐름 컨트롤
// ==============================================

import oscP5.*;
import netP5.*;
import processing.sound.*;

OscP5 osc;
OscP5 oscDrumOut;
OscP5 oscGuitarOut;
OscP5 oscVocalOut;
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

  // Wekinator Output 리스너
  mlOut = new MLOutputClient(new MLOutputListener() {
    public void onWekinatorOutput(int drum, int guitar, int vocal) {
      handleWekinatorOutputValues(drum, guitar, vocal);
    }
  });

  // MotionReceiver 생성
  motion = new MotionReceiver();

  // OSC 수신 (MotionSender 포트: 4886)
  osc = new OscP5(this, 4886);
  // Wekinator 모델별 입력 포트
  wekDrum   = new NetAddress("127.0.0.1", 6448);
  wekGuitar = new NetAddress("127.0.0.1", 6450);
  wekVocal  = new NetAddress("127.0.0.1", 6452);

  // Wekinator 모델별 출력 수신 포트
  oscDrumOut   = new OscP5(this, 12001);
  oscGuitarOut = new OscP5(this, 12002);
  oscVocalOut  = new OscP5(this, 12003);

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
  
  // if (m.checkAddrPattern("/wek/inputs")) return; // 디버그용
  // 수신 패턴 로그
  println("RAW", m.addrPattern(), m.arguments().length);
  String tt = m.typetag();
  for (int i = 0; i < m.arguments().length; i++) {
    char t = (tt != null && tt.length() > i) ? tt.charAt(i) : '?';
    if (t == 'f') {
      println("  arg" + i + " (float): " + m.get(i).floatValue());
    } else if (t == 'i') {
      println("  arg" + i + " (int): " + m.get(i).intValue());
    } else if (t == 's') {
      println("  arg" + i + " (str): " + m.get(i).stringValue());
    } else {
      println("  arg" + i + " (" + t + "): " + m.get(i));
    }
  }


  // 수신 패턴 로그 (주소/인자 수 확인용)
  println("RX", m.addrPattern(), m.arguments().length);

  // Smartphone Motion Receiver
  motion.onOsc(m);

  if (m.checkAddrPattern("/accel")) {
    println("ACC:", motion.ax, motion.ay, motion.az);
  }

  if (m.checkAddrPattern("/gyro")) {
    println("GYRO:", motion.rx, motion.ry, motion.rz);
  }

  if (m.checkAddrPattern("/gravity")) {
    println("GRAV:", motion.gx, motion.gy, motion.gz);
  }

  // Wekinator Output (모델별 포트 분기)
  if (m.checkAddrPattern("/wek/outputs")) {
    NetAddress src = m.netAddress();
    int port = (src != null) ? src.port() : -1;

    if (port == 12001) {
      handleDrumOutput(m);
    } else if (port == 12002) {
      handleGuitarOutput(m);
    } else if (port == 12003) {
      handleVocalOutput(m);
    } else {
      // 알 수 없는 포트 → 기본 핸들러
      mlOut.onOsc(m);
    }
  }

}
