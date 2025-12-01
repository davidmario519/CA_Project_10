# Creative Algorithm 2025-2 Project 10

## Python 환경
- 권장 버전: Python 3.9.25 (`/Users/yun-yejin/mp39_env`에 venv 존재)
- 주요 패키지: `opencv-python`, `mediapipe`, `numpy`, `python-osc`

### 인터프리터 선택 (IDE/에디터)
- Venv 위치: `/Users/yun-yejin/mp39_env`
- 인터프리터 경로: `/Users/yun-yejin/mp39_env/bin/python`
- VS Code 예시: `Cmd+Shift+P → Python: Select Interpreter → /Users/yun-yejin/mp39_env/bin/python` 선택
- 터미널에서 활성화: `source /Users/yun-yejin/mp39_env/bin/activate`

## 설정
1) 기존 venv 사용  
`source /Users/yun-yejin/mp39_env/bin/activate`

2) (옵션) 새 venv 만들기  
```
python -m venv .venv
source .venv/bin/activate
pip install -U pip
pip install opencv-python mediapipe numpy python-osc
```

## Hand Tracking → Wekinator
- 실행: `python hand_tracking_osc.py`
- 기능: 양손 검출 후 `/hand/features`로 4개 값 전송 `[Width, Height, CenterX, CenterY]`
- 기본 OSC 대상: `127.0.0.1:7000` (Processing에서 수신 → Wekinator로 중계). 다른 머신이면 `hand_tracking_osc.py` 상단의 `IP`, `PORT` 수정.
- macOS에서 카메라 권한 요청 시 허용 필요.

### 코드 설명 (`hand_tracking_osc.py`)
- OpenCV + MediaPipe Hands로 2손을 추적하고, 엄지/검지 끝의 위치를 사용해 특성 4개를 계산합니다.
  - `Width`: 두 손 중심의 x 차이 (0~1 정규화)
  - `Height`: 각 손 엄지-검지 세로 길이 평균 (0~1)
  - `CenterX`, `CenterY`: 두 손을 잇는 사각형 중심 (0~1)
- 위 4개 값을 OSC 메시지 `/wek/inputs`로 전송합니다.
- 화면에 랜드마크, 사각형, 중심점을 오버레이하여 확인할 수 있습니다. `q`로 종료.

### Wekinator 입력 설정 (이 스크립트를 입력으로)
- New Project → Inputs: `OSC`
- Listening port: `6449`
- Message: `/wek/inputs`
- Number of inputs: `4`
- 프로젝트 생성 후 `Start Listening`으로 값이 들어오는지 Input Monitor에서 확인.

### Wekinator 출력 → Processing 스케치
- Wekinator에서 Outputs를 Processing 스케치가 듣는 포트/주소로 설정하세요 (예: `Input_MPReceiverOSC.pde` 내 포트 확인).
- 메시지 이름도 스케치와 맞춰야 합니다(예: `/wek/out/...` 형태). Wekinator GUI의 Outputs 탭에서 포트와 메시지 템플릿을 설정한 뒤 `Start`로 송출.

## 전체 OSC/ML 흐름
- Drum 모델: 스마트폰 Motion Sender → Processing(포트 4886, `/wek/inputs`) → Wekinator(입력 6448 `/wek/inputs`, 출력 9000 `/drumOut`)
- Guitar 모델: MediaPipe 손 파이썬 → Processing(포트 7000, `/hand/features`) → Wekinator(입력 6449 `/wek/inputs`, 출력 9001 `/guitarOut`)
- Vocal 모델: FaceOSC → Processing(포트 8338, `/gesture/...`) → Wekinator(입력 6450 `/wek/inputs`, 출력 9002 `/vocalOut`)

## Wekinator 프로젝트별 설정
- Drum: Inputs 6448 `/wek/inputs` (스마트폰 벡터 크기 자동), Output to Processing 포트 9000 주소 `/drumOut`
- Guitar: Inputs 6449 `/wek/inputs` (손 특징 4개), Output to Processing 포트 9001 주소 `/guitarOut`
- Vocal: Inputs 6450 `/wek/inputs` (얼굴 특징 4개), Output to Processing 포트 9002 주소 `/vocalOut`

## Wekinator 설정 힌트
- New Project → Inputs: OSC, port `6448`, message `/wek/inputs`, 입력 개수 `4`
- Outputs: Processing 스케치에서 듣는 포트/메시지에 맞게 설정 후 Start Listening
