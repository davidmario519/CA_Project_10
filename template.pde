/**
 * Trio Loop Machine – ML Template (for Wekinator)
 * 
 * 입력: 
 *   - 드럼  : 스마트폰 (MotionSender)
 *   - 기타  : MediaPipe 손(운지)
 *   - 보컬  : FaceOSC 입모양
 *
 * 역할:
 *   1) 세 입력의 수치를 하나의 feature vector로 만들어서 Wekinator에 보냄 (/wek/inputs)
 *   2) Wekinator에서 장르 분류 결과 3개(드럼/기타/보컬)를 받음 (/wek/outputs)
 *   3) 현재 장르 상태를 화면에 표시 (나중에 여기서 사운드/그래픽 트리거)
 *
 * !! 중요 !!
 *  - 아래의 TODO 부분에 실제 센서 값(운지 좌표, 입모양, 스마트폰 가속도 등)을 넣으면 됨.
 *  - 이 스케치는 "학습/테스트"를 위한 기본 틀. 
 *    사운드 루프 재생 코드는 나중에 이 장르 결과(drumGenre, guitarGenre, vocalGenre)에 붙이면 됨.
 */

import oscP5.*;
import netP5.*;

OscP5 osc;          // Wekinator에서 오는 메시지 받기
NetAddress wek;     // Wekinator로 입력 보내기

// -----------------------------
// 1. 입력(Feature) 개수 정의
// -----------------------------
// 드럼: 내려치는 횟수, 가속도, 텀 등 예시 3개 (원하면 수정 가능)
final int NUM_DRUM_FEATURES   = 3;

// 기타: 운지법에서 뽑을 특징 예시 (x,y 좌표 평균, 코드 인덱스 등) 임의로 4개
final int NUM_GUITAR_FEATURES = 4;

// 보컬: 입모양(입폭, 입높이, 턱 각도 등) 예시 4개
final int NUM_VOCAL_FEATURES  = 4;

// 전체 입력 벡터 길이
final int NUM_INPUTS = NUM_DRUM_FEATURES + NUM_GUITAR_FEATURES + NUM_VOCAL_FEATURES;

// 각 악기별 feature가 inputVector 안에서 시작하는 인덱스
final int DRUM_OFFSET   = 0;
final int GUITAR_OFFSET = DRUM_OFFSET + NUM_DRUM_FEATURES;
final int VOCAL_OFFSET  = GUITAR_OFFSET + NUM_GUITAR_FEATURES;

// Wekinator로 보낼 입력 벡터
float[] inputVector = new float[NUM_INPUTS];

// -----------------------------
// 2. 출력(장르) 정의
// -----------------------------
// Wekinator에서 출력 3개를 보내도록 설정:
// output 1: 드럼 장르 (0=재즈, 1=힙합, 2=시네마틱)
// output 2: 기타 장르 (0=재즈, 1=힙합, 2=시네마틱)
// output 3: 보컬 장르 (0=재즈, 1=힙합, 2=시네마틱)

int drumGenre   = 0;
int guitarGenre = 0;
int vocalGenre  = 0;

String[] GENRE_NAMES = { "Jazz", "HipHop", "Cinematic" };

// -----------------------------
// 3. 기본 세팅
// -----------------------------
void setup() {
  size(900, 600);
  surface.setTitle("Trio Loop Machine – ML Template");

  // Wekinator에서 오는 출력 메시지 받을 포트 (기본: 12000)
  osc = new OscP5(this, 12000);

  // Wekinator로 입력 보낼 주소/포트 (기본: 6448)
  wek = new NetAddress("127.0.0.1", 6448);
  
  // 초기화 (지금은 전부 0)
  for (int i = 0; i < NUM_INPUTS; i++) {
    inputVector[i] = 0;
  }
}

// -----------------------------
// 4. 메인 루프
// -----------------------------
void draw() {
  background(20);
  fill(255);
  
  // 1) 센서에서 값 받아서 inputVector 갱신
  updateFeaturesFromSensors();
  
  // 2) Wekinator로 입력 전송
  sendInputsToWekinator();
  
  // 3) 디버그용 UI 출력
  drawDebugUI();
}

// ------------------------------------------------------
// 5. 센서 데이터 → feature vector로 옮기는 부분 (TODO 구간)
// ------------------------------------------------------
void updateFeaturesFromSensors() {
  // --------- (A) 드럼 – 스마트폰(MotionSender) ----------
  // TODO: 여기서 스마트폰(Motionsender)에서 받은 값들을 사용해서
  //       드럼 관련 feature를 채워 넣으면 됨.
  // 예시 변수 이름 (네가 실제 값 넣을 곳)
  float drumHitCount      = 0;   // ex) 최근 일정 시간 동안 내려친 횟수
  float drumAccelDown     = 0;   // ex) 아래 방향 가속도
  float drumHitInterval   = 0;   // ex) 평균 타격 간격

  // 위의 변수들을 0~1 등으로 정규화해서 inputVector에 넣기
  inputVector[DRUM_OFFSET + 0] = drumHitCount;
  inputVector[DRUM_OFFSET + 1] = drumAccelDown;
  inputVector[DRUM_OFFSET + 2] = drumHitInterval;

  // --------- (B) 기타 – 손(운지, MediaPipe) ----------
  // TODO: MediaPipe 손 좌표/각도 등을 이용해서 운지 특징 추출
  // 예시 변수 (실제 값으로 교체):
  float guitarChordIndex  = 0;   // 0=코드1, 1=코드2, ... 이런 식으로 인덱스화 가능
  float guitarFretSpread  = 0;   // 손가락 벌어진 정도
  float guitarHandHeight  = 0;   // y 위치 평균
  float guitarStrumEnergy = 0;   // 스트로크 세기 등

  inputVector[GUITAR_OFFSET + 0] = guitarChordIndex;
  inputVector[GUITAR_OFFSET + 1] = guitarFretSpread;
  inputVector[GUITAR_OFFSET + 2] = guitarHandHeight;
  inputVector[GUITAR_OFFSET + 3] = guitarStrumEnergy;

  // --------- (C) 보컬 – 얼굴(입모양, FaceOSC) ----------
  // TODO: FaceOSC에서 입/턱 관련 파라미터 가져오기
  // 예시 변수:
  float mouthWidth   = 0;   // 입 가로 길이
  float mouthHeight  = 0;   // 입 세로 열림 정도
  float jawOpen      = 0;   // 턱 열림
  float mouthRound   = 0;   // 입이 동그랗게 모이는 정도

  inputVector[VOCAL_OFFSET + 0] = mouthWidth;
  inputVector[VOCAL_OFFSET + 1] = mouthHeight;
  inputVector[VOCAL_OFFSET + 2] = jawOpen;
  inputVector[VOCAL_OFFSET + 3] = mouthRound;
}

// ----------------------------------------------
// 6. Wekinator로 입력 보내기 (/wek/inputs)
// ----------------------------------------------
void sendInputsToWekinator() {
  OscMessage msg = new OscMessage("/wek/inputs");

  for (int i = 0; i < NUM_INPUTS; i++) {
    msg.add(inputVector[i]);
  }

  osc.send(msg, wek);
}

// ----------------------------------------------------
// 7. Wekinator에서 온 출력 받기 (/wek/outputs)
//    - Wekinator에서 출력 3개(float)로 설정했다고 가정
// ----------------------------------------------------
void oscEvent(OscMessage m) {
  if (m.checkAddrPattern("/wek/outputs")) {
    // 출력 개수 확인
    int numArgs = m.arguments().length;
    if (numArgs >= 3) {
      // 분류 결과가 0,1,2 형태로 온다고 가정하고 int로 변환
      drumGenre   = constrain(round(m.get(0).floatValue()), 0, 2);
      guitarGenre = constrain(round(m.get(1).floatValue()), 0, 2);
      vocalGenre  = constrain(round(m.get(2).floatValue()), 0, 2);
    }
  }
}

// ----------------------------------------------
// 8. 화면에 현재 상태를 텍스트로 보여주는 부분
// ----------------------------------------------
void drawDebugUI() {
  textAlign(LEFT, TOP);
  textSize(20);
  text("Trio Loop Machine – ML Template", 30, 20);

  textSize(14);
  float y = 70;
  text("1) 현재 Input Vector (Wekinator로 전송 중)", 30, y); 
  y += 20;

  // 입력값 출력
  text("   [드럼 Features]", 40, y); 
  y += 18;
  for (int i = 0; i < NUM_DRUM_FEATURES; i++) {
    text("   D" + i + " : " + nf(inputVector[DRUM_OFFSET + i], 1, 3), 60, y);
    y += 16;
  }

  y += 6;
  text("   [기타 Features]", 40, y); 
  y += 18;
  for (int i = 0; i < NUM_GUITAR_FEATURES; i++) {
    text("   G" + i + " : " + nf(inputVector[GUITAR_OFFSET + i], 1, 3), 60, y);
    y += 16;
  }

  y += 6;
  text("   [보컬 Features]", 40, y); 
  y += 18;
  for (int i = 0; i < NUM_VOCAL_FEATURES; i++) {
    text("   V" + i + " : " + nf(inputVector[VOCAL_OFFSET + i], 1, 3), 60, y);
    y += 16;
  }

  // 장르 결과
  y += 16;
  text("2) 현재 Wekinator 장르 출력", 30, y);
  y += 20;

  text("   Drum   : " + GENRE_NAMES[drumGenre]   + "  (" + drumGenre   + ")", 40, y); y += 18;
  text("   Guitar : " + GENRE_NAMES[guitarGenre] + "  (" + guitarGenre + ")", 40, y); y += 18;
  text("   Vocal  : " + GENRE_NAMES[vocalGenre]  + "  (" + vocalGenre  + ")", 40, y); y += 18;

  y += 20;
  text("※ 실제 프로젝트에서는 위 장르 값에 따라 사운드 루프/그래픽(파동 등)을 연결하면 됨.", 30, y);
}
