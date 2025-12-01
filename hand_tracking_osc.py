import os
import tempfile

# GPU 없는 환경에서 Mediapipe가 실패하지 않도록 GPU 사용 비활성화
os.environ.setdefault("MEDIAPIPE_DISABLE_GPU", "1")

# Matplotlib/Fontconfig 캐시 경로 오류 회피용 임시 디렉터리
if "MPLCONFIGDIR" not in os.environ:
    os.environ["MPLCONFIGDIR"] = tempfile.mkdtemp(prefix="mpl-cache-")
if "XDG_CACHE_HOME" not in os.environ:
    os.environ["XDG_CACHE_HOME"] = tempfile.mkdtemp(prefix="font-cache-")

import cv2
import mediapipe as mp
import numpy as np
from pythonosc import udp_client

# --- [설정] ---
# 기본: Processing에서 듣는 포트/주소로 송신 → Processing이 Wekinator(6449)로 전달
IP = "127.0.0.1"
PORT = 7000
OSC_ADDR = "/hand/features"  # Processing/Input_MPReceiverOSC.pde가 기대하는 주소

# --- [초기화] ---
client = udp_client.SimpleUDPClient(IP, PORT)

mp_hands = mp.solutions.hands
mp_drawing = mp.solutions.drawing_utils
hands = mp_hands.Hands(
    max_num_hands=2, min_detection_confidence=0.7, min_tracking_confidence=0.5
)

# 사용자 설정 유지: 웹캠 2번, AVFOUNDATION 백엔드 사용
cap = cv2.VideoCapture(0, cv2.CAP_AVFOUNDATION)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)

print(f"Start Sending OSC to {IP}:{PORT}...")
print("Inputs: 두 손 랜드마크 전체 (좌 21점 x,y,z + 우 21점 x,y,z = 126 floats)")
print("Press 'q' to quit.")

# 21개 랜드마크를 x,y,z로 평탄화
def flatten_landmarks(hand_landmarks):
    flat = []
    for lm in hand_landmarks.landmark:
        flat.extend([lm.x, lm.y, lm.z])
    return flat

while cap.isOpened():
    success, image = cap.read()
    if not success:
        continue

    image.flags.writeable = False
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image)

    image.flags.writeable = True
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    if results.multi_hand_landmarks and len(results.multi_hand_landmarks) >= 1:
        hands_landmarks = results.multi_hand_landmarks

        # 손목 x 좌표로 좌/우 손 정렬
        if len(hands_landmarks) == 1:
            left_hand = hands_landmarks[0]
            right_hand = hands_landmarks[0]
        else:
            h1 = hands_landmarks[0]
            h2 = hands_landmarks[1]
            if h1.landmark[0].x < h2.landmark[0].x:
                left_hand, right_hand = h1, h2
            else:
                left_hand, right_hand = h2, h1

        # 좌/우 손 랜드마크 전체를 평탄화하여 하나의 벡터로 전송 (고정 길이 126)
        left_flat = flatten_landmarks(left_hand)
        right_flat = flatten_landmarks(right_hand)
        features = left_flat + right_flat
        if len(features) < 126:
            features.extend([0.0] * (126 - len(features)))

        client.send_message(OSC_ADDR, features)

        # --- [시각화] ---
        h, w, c = image.shape
        for hand_lms in [left_hand, right_hand]:
            mp_drawing.draw_landmarks(image, hand_lms, mp_hands.HAND_CONNECTIONS)

        info_text = f"Sent {len(features)} floats (2 hands landmarks)"
        cv2.putText(
            image,
            info_text,
            (10, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (255, 255, 255),
            2,
        )

    cv2.imshow("Hand Tracking for Sound Space", image)

    if cv2.waitKey(5) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
