// ==============================================
// Input_FaceReceiverOSC.pde
// FaceOSC → Processing 입력 전용 클래스
// - raw 얼굴 파라미터를 저장만 한다
// - Feature_Face 에서 이 값들로 ML feature 계산
// ==============================================

class FaceReceiver {

  // FaceOSC raw values
  float mouthW = 0;
  float mouthH = 0;

  float eyeL = 0;
  float eyeR = 0;

  float browL = 0;
  float browR = 0;

  float headX = 0;
  float headY = 0;
  float headScale = 1;

  FaceReceiver() {}

  // OSC 입력 처리
  void onOsc(OscMessage m) {

    // === Mouth ===
    if (m.checkAddrPattern("/gesture/mouth/width")) {
      mouthW = m.get(0).floatValue();
    }
    if (m.checkAddrPattern("/gesture/mouth/height")) {
      mouthH = m.get(0).floatValue();
    }

    // === Eyes ===
    if (m.checkAddrPattern("/gesture/eye/left")) {
      eyeL = m.get(0).floatValue();
    }
    if (m.checkAddrPattern("/gesture/eye/right")) {
      eyeR = m.get(0).floatValue();
    }

    // === Eyebrows ===
    if (m.checkAddrPattern("/gesture/eyebrow/left")) {
      browL = m.get(0).floatValue();
    }
    if (m.checkAddrPattern("/gesture/eyebrow/right")) {
      browR = m.get(0).floatValue();
    }

    // === Head Pose ===
    if (m.checkAddrPattern("/pose/position")) {
      headX = m.get(0).floatValue();
      headY = m.get(1).floatValue();
    }
    if (m.checkAddrPattern("/pose/scale")) {
      headScale = m.get(0).floatValue();
    }
  }
}
