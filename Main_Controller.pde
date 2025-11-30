// =========================================
// 6_Main_Controller (WekiInputHelper 기반)
// =========================================

import wekinator.*;
import oscP5.*;
import netP5.*;

OscP5 osc;
WekiInputHelper weki;

// Output ports
final int PORT_DRUM_OUT   = 9000;
final int PORT_GUITAR_OUT = 9001;
final int PORT_VOCAL_OUT  = 9002;

// Genres
int drumGenre = 0;
int guitarGenre = 0;
int vocalGenre = 0;

String[] GENRE_NAMES = { "Jazz", "HipHop", "Cinematic" };

// ----------------------------------------
// setup()
// ----------------------------------------
void setup() {

  size(900, 600);
  background(0);

  // 1) RAW 수신 포트
  int RAW_PORT = 4886;

  // 2) Helper 시작
  weki = new WekiInputHelper(this, RAW_PORT);

  // RAW 입력 등록
  weki.addIncomingOSC("/accel",   "ax", "ay", "az");
  weki.addIncomingOSC("/gyro",    "gx", "gy", "gz");
  weki.addIncomingOSC("/gravity", "rx", "ry", "rz");

  // Helper가 계산해서 만들 feature 5개
  weki.addInput("force");
  weki.addInput("gyro");
  weki.addInput("shake");
  weki.addInput("smooth");
  weki.addInput("tilt");

  // Wekinator input 포트 = 단 1개!
  weki.setWekinatorHost("127.0.0.1", 6448);

  // Wekinator output 수신
  osc = new OscP5(this, PORT_DRUM_OUT);
  osc.plug(this, "onDrumOut",   "/drumOut");

  osc.plug(this, "onGuitarOut", "/guitarOut");
  osc.startListening(PORT_GUITAR_OUT);

  osc.plug(this, "onVocalOut", "/vocalOut");
  osc.startListening(PORT_VOCAL_OUT);
}

// ----------------------------------------
// draw() — feature 계산 + Helper 전송
// ----------------------------------------
void draw() {

  background(20);

  updateFeatures();
  weki.sendInputs();

  drawDebugUI();
}

// ----------------------------------------
// RAW → Feature 계산
// ----------------------------------------
void updateFeatures() {

  float ax = weki.getValue("ax");
  float ay = weki.getValue("ay");
  float az = weki.getValue("az");

  float gx = weki.getValue("gx");
  float gy = weki.getValue("gy");
  float gz = weki.getValue("gz");

  float rx = weki.getValue("rx");

  // Feature definitions
  float force =   (abs(ax)+abs(ay)+abs(az)) / 4.0;
  float gyro  =   (abs(gx)+abs(gy)+abs(gz)) / 12.0;
  float shake =   abs(ax - ay) * 0.3;
  float smooth =  1.0 - shake;
  float tilt   =  abs(rx) / 9.8;

  weki.setInput("force", constrain(force,0,1));
  weki.setInput("gyro", constrain(gyro,0,1));
  weki.setInput("shake", constrain(shake,0,1));
  weki.setInput("smooth", constrain(smooth,0,1));
  weki.setInput("tilt", constrain(tilt,0,1));
}

// ----------------------------------------
// Output handlers
// ----------------------------------------
public void onDrumOut(float v) {
  drumGenre = round(v);
  println("DRUM →", drumGenre);
}

public void onGuitarOut(float v) {
  guitarGenre = round(v);
  println("GUITAR →", guitarGenre);
}

public void onVocalOut(float v) {
  vocalGenre = round(v);
  println("VOCAL →", vocalGenre);
}

// ----------------------------------------
// Debug UI
// ----------------------------------------
void drawDebugUI() {

  fill(255);
  textSize(20);

  text("force   : " + nf(weki.getInput("force"),1,4), 30, 80);
  text("gyro    : " + nf(weki.getInput("gyro"),1,4), 30, 110);
  text("shake   : " + nf(weki.getInput("shake"),1,4), 30, 140);
  text("smooth  : " + nf(weki.getInput("smooth"),1,4), 30, 170);
  text("tilt    : " + nf(weki.getInput("tilt"),1,4), 30, 200);

  text("DRUM OUT: " + GENRE_NAMES[drumGenre], 30, 260);
  text("GUITAR OUT: " + guitarGenre, 30, 290);
  text("VOCAL OUT: " + vocalGenre, 30, 320);
}
