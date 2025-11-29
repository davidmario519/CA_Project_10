import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress wek;

// 클래스들
MotionReceiver motion;

// ML 변수들 (template에서 선언한 것 그대로 사용)
PFont kor;

// -----------------------------
// 메인 setup() — 모든 초기화
// -----------------------------
void setup() {
  size(900, 600);

  kor = createFont("DXPnM-KSCpc-EUC-H.ttf", 24, true);
  textFont(kor);
  surface.setTitle("Trio Loop Machine – Main");

  // MotionReceiver 생성
  motion = new MotionReceiver();

  // Wekinator 입/출력 포트 (입력: 6448, 출력: 12000)
  osc = new OscP5(this, 12000);
  wek = new NetAddress("127.0.0.1", 6448);

  // template 안의 inputVector 초기화 함수 호출 (필요하면)
  initInputVector();
}

// -----------------------------
// 메인 draw()
// -----------------------------
void draw() {
  background(20);

  // 1) 센서 → feature vector 업데이트 (template에 있는 함수)
  updateFeaturesFromSensors();

  // 2) Wekinator로 보내기 (template 함수)
  sendInputsToWekinator();

  // 3) 디버그 UI 표시 (template 함수)
  drawDebugUI();
}

// -----------------------------
// OSC 이벤트 처리
// -----------------------------
void oscEvent(OscMessage m) {

  // MotionSender 값 먼저 처리
  motion.onOsc(m);

  // Wekinator 출력 받기
  if (m.checkAddrPattern("/wek/outputs")) {
    handleWekinatorOutput(m); // template 쪽에 함수로 분리해둘 수 있음
  }
}
