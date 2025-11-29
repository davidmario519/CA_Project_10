// =========================================
// 6_Main_Controller.pde
// 전체 파이프라인 Controller
// - feature vector
// - ML input/output
// - Debug UI
// =========================================

// ========== ML 입력 개수 설정 ==========
final int NUM_DRUM_FEATURES   = 5;   // force, gyro, shake, smooth, gravity
final int NUM_GUITAR_FEATURES = 4;   // Mediapipe 4개
final int NUM_VOCAL_FEATURES  = 4;   // FaceOSC 4개 (추후 추가)

final int NUM_INPUTS =
  NUM_DRUM_FEATURES +
  NUM_GUITAR_FEATURES +
  NUM_VOCAL_FEATURES;

// Offset
final int DRUM_OFFSET   = 0;
final int GUITAR_OFFSET = DRUM_OFFSET + NUM_DRUM_FEATURES;
final int VOCAL_OFFSET  = GUITAR_OFFSET + NUM_GUITAR_FEATURES;

// Input vector (전체 ML 입력)
float[] inputVector = new float[NUM_INPUTS];

// Wekinator Output (genre)
int drumGenre   = 0;
int guitarGenre = 0;
int vocalGenre  = 0;

String[] GENRE_NAMES = { "Jazz", "HipHop", "Cinematic" };

// ==================================================
// 초기화
// ==================================================
void initInputVector() {
  for (int i = 0; i < NUM_INPUTS; i++) inputVector[i] = 0;
}

// ==================================================
// 센서값 → Feature Vector 업데이트
// ==================================================
void updateFeaturesFromSensors() {

  // -------------------------
  // Drum Features (MotionReceiver 기반)
  // -------------------------

  inputVector[DRUM_OFFSET + 0] = motion.getForce();           // 힘 (HipHop)
  inputVector[DRUM_OFFSET + 1] = motion.getGyroSwing();       // 회전량 (Jazz)
  inputVector[DRUM_OFFSET + 2] = motion.getShakeComplexity(); // 진동 패턴 (Cinematic)
  inputVector[DRUM_OFFSET + 3] = motion.getSmoothness();      // 부드러움
  inputVector[DRUM_OFFSET + 4] = motion.getGravityTilt();     // 기울기

  // -------------------------
  // Guitar Features → (추후 Mediapipe 파일에서 업데이트)
  // -------------------------
  // inputVector[GUARD_OFFSET + 0~3] ...

  // -------------------------
  // Vocal Features → (FaceOSC 입력 후 업데이트)
  // -------------------------
  // inputVector[VOCAL_OFFSET + 0~3] ...
}

// ==================================================
// Wekinator로 Input 전송
// ==================================================
void sendInputsToWekinator() {

  OscMessage msg = new OscMessage("/wek/inputs");

  for (int i = 0; i < NUM_INPUTS; i++) {
    msg.add(inputVector[i]);
  }

  osc.send(msg, wek);
}

// ==================================================
// Wekinator Output 처리
// ==================================================
void handleWekinatorOutput(OscMessage m) {

  if (m.arguments().length >= 3) {

    drumGenre   = constrain(round(m.get(0).floatValue()), 0, 2);
    guitarGenre = constrain(round(m.get(1).floatValue()), 0, 2);
    vocalGenre  = constrain(round(m.get(2).floatValue()), 0, 2);
  }
}

// ==================================================
// Debug UI
// ==================================================
void drawDebugUI() {
  fill(255);
  textSize(18);
  textAlign(LEFT);

  text("=== Trio Loop ML Debug ===", 30, 20);

  text("Drum Features:", 30, 70);
  text("Force: "           + nf(inputVector[0],1,2), 60, 100);
  text("GyroSwing: "       + nf(inputVector[1],1,2), 60, 130);
  text("ShakeComplexity: " + nf(inputVector[2],1,2), 60, 160);
  text("Smoothness: "      + nf(inputVector[3],1,2), 60, 190);
  text("GravityTilt: "     + nf(inputVector[4],1,2), 60, 220);

  text("Drum Genre Output: " + GENRE_NAMES[drumGenre], 30, 260);
}
