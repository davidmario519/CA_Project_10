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
MLInputClient mlIn;

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
float forceNorm = constrain(motion.getForce() / 2.0, 0, 1);  // 기존 /5
float gyroNorm  = constrain(motion.getGyroSwing() / 10.0, 0, 1); // 기존 /20
float shakeNorm = constrain(motion.getShakeComplexity(), 0, 1);
float smoothNorm = constrain(motion.getSmoothness(), 0, 1);
float gravityNorm = constrain(motion.getGravityTilt(), 0, 1);
println("feat norm", forceNorm, gyroNorm, shakeNorm, smoothNorm, gravityNorm);


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

  // 드럼 5개
  float[] drumInputs = new float[NUM_DRUM_FEATURES];
  for (int i = 0; i < NUM_DRUM_FEATURES; i++) drumInputs[i] = inputVector[DRUM_OFFSET + i];
  mlIn.sendInputs(drumInputs, wekDrum);

  // 기타 4개 (값 준비되면 업데이트)
  float[] guitarInputs = new float[NUM_GUITAR_FEATURES];
  for (int i = 0; i < NUM_GUITAR_FEATURES; i++) guitarInputs[i] = inputVector[GUITAR_OFFSET + i];
  mlIn.sendInputs(guitarInputs, wekGuitar);

  // 보컬 4개 (값 준비되면 업데이트)
  float[] vocalInputs = new float[NUM_VOCAL_FEATURES];
  for (int i = 0; i < NUM_VOCAL_FEATURES; i++) vocalInputs[i] = inputVector[VOCAL_OFFSET + i];
  mlIn.sendInputs(vocalInputs, wekVocal);
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

void handleWekinatorOutputValues(int d, int g, int v) {
  if (d >= 0) drumGenre   = d;
  if (g >= 0) guitarGenre = g;
  if (v >= 0) vocalGenre  = v;

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
