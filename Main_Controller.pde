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

  // 0~1 정규화 후 전송 (Wekinator 학습 안정화)
  float forceNorm   = constrain(motion.getForce() / 5.0, 0, 1);      // 힘 (HipHop)
  float gyroNorm    = constrain(motion.getGyroSwing() / 20.0, 0, 1); // 회전량 (Jazz)
  float shakeNorm   = constrain(motion.getShakeComplexity(), 0, 1);  // 진동 패턴 (Cinematic)
  float smoothNorm  = constrain(motion.getSmoothness(), 0, 1);       // 부드러움
  float gravityNorm = constrain(motion.getGravityTilt(), 0, 1);      // 기울기

  inputVector[DRUM_OFFSET + 0] = forceNorm;
  inputVector[DRUM_OFFSET + 1] = gyroNorm;
  inputVector[DRUM_OFFSET + 2] = shakeNorm;
  inputVector[DRUM_OFFSET + 3] = smoothNorm;
  inputVector[DRUM_OFFSET + 4] = gravityNorm;

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

  // Drum 모델로 5개 전송 (64048)
  OscMessage drumMsg = new OscMessage("/wek/inputs");
  for (int i = 0; i < NUM_DRUM_FEATURES; i++) drumMsg.add(inputVector[DRUM_OFFSET + i]);
  osc.send(drumMsg, wekDrum);

  // Guitar 모델로 4개 전송 (6450) — 현재 값이 없으면 0 유지
  OscMessage guitarMsg = new OscMessage("/wek/inputs");
  for (int i = 0; i < NUM_GUITAR_FEATURES; i++) guitarMsg.add(inputVector[GUITAR_OFFSET + i]);
  osc.send(guitarMsg, wekGuitar);

  // Vocal 모델로 4개 전송 (6452) — 현재 값이 없으면 0 유지
  OscMessage vocalMsg = new OscMessage("/wek/inputs");
  for (int i = 0; i < NUM_VOCAL_FEATURES; i++) vocalMsg.add(inputVector[VOCAL_OFFSET + i]);
  osc.send(vocalMsg, wekVocal);
}

// ==================================================
// Wekinator Output 처리
// ==================================================
void handleWekinatorOutput(OscMessage m) {

  if (m.arguments().length >= 3) {

    int d = constrain(round(m.get(0).floatValue()), 0, 2);
    int g = constrain(round(m.get(1).floatValue()), 0, 2);
    int v = constrain(round(m.get(2).floatValue()), 0, 2);
    handleWekinatorOutputValues(d, g, v);
  }
}

// 모델별 출력 핸들러 (1개 값 기준)
void handleDrumOutput(OscMessage m) {
  if (m.arguments().length >= 1) {
    int d = constrain(round(m.get(0).floatValue()), 0, 2);
    handleWekinatorOutputValues(d, guitarGenre, vocalGenre);
  }
}

void handleGuitarOutput(OscMessage m) {
  if (m.arguments().length >= 1) {
    int g = constrain(round(m.get(0).floatValue()), 0, 2);
    handleWekinatorOutputValues(drumGenre, g, vocalGenre);
  }
}

void handleVocalOutput(OscMessage m) {
  if (m.arguments().length >= 1) {
    int v = constrain(round(m.get(0).floatValue()), 0, 2);
    handleWekinatorOutputValues(drumGenre, guitarGenre, v);
  }
}

void handleWekinatorOutputValues(int d, int g, int v) {
  drumGenre   = d;
  guitarGenre = g;
  vocalGenre  = v;

  if (drumTrigger != null) {
    drumTrigger.trigger(drumGenre);
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
  text("Force: "           + nf(inputVector[0],1,4), 60, 100);
  text("GyroSwing: "       + nf(inputVector[1],1,4), 60, 130);
  text("ShakeComplexity: " + nf(inputVector[2],1,4), 60, 160);
  text("Smoothness: "      + nf(inputVector[3],1,4), 60, 190);
  text("GravityTilt: "     + nf(inputVector[4],1,4), 60, 220);

  text("Drum Genre Output: " + GENRE_NAMES[drumGenre], 30, 260);
}
