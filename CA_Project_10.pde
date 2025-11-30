// ==============================================
// 6_CA_Project_10.pde — MAIN ENTRY
// Using WekiInputHelper (input helper)
// ==============================================

import oscP5.*;
import netP5.*;
import wekinator.*;
import processing.sound.*;

WekiInputHelper helper;   // Wekinator input helper
OscP5 osc;                // For OUTPUT only

MotionReceiver motion;    // Raw sensor → feature 계산
DrumTrigger drumTrigger;  // Output trigger

PFont kor;

// ----------------------------------------------
// setup()
// ----------------------------------------------
void setup() {

  size(900, 600);
  kor = createFont("DXPnM-KSCpc-EUC-H.ttf", 24, true);
  textFont(kor);
  surface.setTitle("Trio Loop Machine – WekiInputHelper Mode");

  // 1) OUTPUT 수신 포트 먼저 열기
  //    → adresses: /wek/outputs
  osc = new OscP5(this, 9000);

  // 2) iPhone에서 보내는 raw 센서 포트(4886)를 helper가 수신
  helper = new WekiInputHelper(this, 4886);

  // 3) helper에 입력(feature) 5개 등록
  helper.addInput("force");
  helper.addInput("gyroSwing");
  helper.addInput("shake");
  helper.addInput("smooth");
  helper.addInput("gravity");

  // 4) raw 센서 클래스
  motion = new MotionReceiver();

  // 5) 사운드 트리거 (output listener)
  drumTrigger = new DrumTrigger(this);

  println("=== WekiInputHelper Mode Ready ===");
}

// ----------------------------------------------
// draw()
// ----------------------------------------------
void draw() {
  background(20);

  // 1) raw sensor → feature 계산
  float force   = motion.getForce();
  float gyro    = motion.getGyroSwing();
  float shake   = motion.getShakeComplexity();
  float smooth  = motion.getSmoothness();
  float gravity = motion.getGravityTilt();

  // 2) helper에 feature 값을 보내기 (이게 핵심!)
  helper.setInputValue(0, force);
  helper.setInputValue(1, gyro);
  helper.setInputValue(2, shake);
  helper.setInputValue(3, smooth);
  helper.setInputValue(4, gravity);

  // 3) Wekinator로 입력 전송
  helper.sendInputs();

  // 4) 디버그 UI
  fill(255);
  text("Force: " + nfs(force,1,3), 30,80);
  text("GyroSwing: " + nfs(gyro,1,3), 30,110);
  text("Shake: " + nfs(shake,1,3), 30,140);
  text("Smooth: " + nfs(smooth,1,3), 30,170);
  text("Gravity: " + nfs(gravity,1,3), 30,200);
}

// ----------------------------------------------
// OSC Event – receive Wekinator output
// ----------------------------------------------
void oscEvent(OscMessage m) {

  // iPhone raw 센서
  if (m.checkAddrPattern("/accel") ||
      m.checkAddrPattern("/gyro") ||
      m.checkAddrPattern("/gravity")) {
    motion.onOsc(m);
    return;
  }

  // Wekinator output
  if (m.checkAddrPattern("/wek/outputs")) {
    drumTrigger.onOsc(m);
    return;
  }

  println("RX", m.addrPattern(), m.arguments().length);
}
