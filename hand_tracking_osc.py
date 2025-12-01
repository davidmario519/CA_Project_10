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
print("Inputs: [Width, Height, CenterX, CenterY]")
print("Press 'q' to quit.")

while cap.isOpened():
    success, image = cap.read()
    if not success:
        continue

    image.flags.writeable = False
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
    results = hands.process(image)

    image.flags.writeable = True
    image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

    if results.multi_hand_landmarks and len(results.multi_hand_landmarks) == 2:
        h1 = results.multi_hand_landmarks[0]
        h2 = results.multi_hand_landmarks[1]

        h, w, c = image.shape

        def get_coord(landmark):
            return int(landmark.x * w), int(landmark.y * h)

        # 왼쪽/오른쪽 손 정렬
        if h1.landmark[0].x < h2.landmark[0].x:
            left_hand = h1
            right_hand = h2
        else:
            left_hand = h2
            right_hand = h1

        # 랜드마크 추출
        left_thumb = left_hand.landmark[4]
        left_index = left_hand.landmark[8]
        right_thumb = right_hand.landmark[4]
        right_index = right_hand.landmark[8]

        # 픽셀 좌표 변환
        li_px = get_coord(left_thumb)
        lm_px = get_coord(left_index)
        ri_px = get_coord(right_thumb)
        rm_px = get_coord(right_index)

        # 수직 정렬 함수
        def split_vertical(p_top, p_bottom, coord_top, coord_bottom):
            if p_top.y > p_bottom.y:
                return p_bottom, p_top, coord_bottom, coord_top
            return p_top, p_bottom, coord_top, coord_bottom

        left_top, left_bottom, left_top_px, left_bottom_px = split_vertical(
            left_thumb, left_index, li_px, lm_px
        )
        right_top, right_bottom, right_top_px, right_bottom_px = split_vertical(
            right_thumb, right_index, ri_px, rm_px
        )

        # --- [Feature 1: 가로 폭 (Width)] ---
        left_avg_x = (left_thumb.x + left_index.x) / 2.0
        right_avg_x = (right_thumb.x + right_index.x) / 2.0
        norm_width = abs(right_avg_x - left_avg_x)

        # --- [Feature 2: 세로 높이 (Height)] ---
        left_height = abs(left_bottom.y - left_top.y)
        right_height = abs(right_bottom.y - right_top.y)
        norm_height = (left_height + right_height) / 2.0

        # --- [Feature 3 & 4: 중심점 (Position X, Y)] ---
        # 사각형의 중심 좌표를 0.0 ~ 1.0 사이 값으로 계산
        norm_center_x = (left_avg_x + right_avg_x) / 2.0

        # y축은 네 점의 평균을 사용하여 중심을 잡음
        norm_center_y = (
            left_top.y + left_bottom.y + right_top.y + right_bottom.y
        ) / 4.0

        # OSC 전송 (4개 값: 가로, 세로, 중심X, 중심Y)
        client.send_message(
            OSC_ADDR, [norm_width, norm_height, norm_center_x, norm_center_y]
        )

        # --- [시각화] ---
        # 중심점 픽셀 변환
        center_x_pixel = int(norm_center_x * w)
        center_y_pixel = int(norm_center_y * h)

        rect_points = np.array(
            [left_top_px, right_top_px, right_bottom_px, left_bottom_px], dtype=np.int32
        )
        cv2.polylines(image, [rect_points], True, (0, 255, 0), 2)
        cv2.circle(
            image, (center_x_pixel, center_y_pixel), 8, (0, 255, 255), -1
        )  # 노란색 중심점

        # 정보 표시 (X, Y 추가됨)
        info_text = f"W:{norm_width:.2f} H:{norm_height:.2f} X:{norm_center_x:.2f} Y:{norm_center_y:.2f}"
        cv2.putText(
            image,
            info_text,
            (10, 30),
            cv2.FONT_HERSHEY_SIMPLEX,
            0.7,
            (255, 255, 255),
            2,
        )

        mp_drawing.draw_landmarks(image, left_hand, mp_hands.HAND_CONNECTIONS)
        mp_drawing.draw_landmarks(image, right_hand, mp_hands.HAND_CONNECTIONS)

    cv2.imshow("Hand Tracking for Sound Space", image)

    if cv2.waitKey(5) & 0xFF == ord("q"):
        break

cap.release()
cv2.destroyAllWindows()
