// MotionReceiver.pde
// 스마트폰 MotionSender → Processing OSC 입력 전용 클래스

class MotionReceiver {

  float ax, ay, az;   // acceleration
  float gx, gy, gz;   // gravity
  float rx, ry, rz;   // gyro

  MotionReceiver() {
    // 생성자
  }

  // OSC 메시지를 받아서 내부 변수에 저장
  void onOsc(OscMessage m) {

    if (m.checkAddrPattern("/accel")) {
      ax = m.get(0).floatValue();
      ay = m.get(1).floatValue();
      az = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/gravity")) {
      gx = m.get(0).floatValue();
      gy = m.get(1).floatValue();
      gz = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/gyro")) {
      rx = m.get(0).floatValue();
      ry = m.get(1).floatValue();
      rz = m.get(2).floatValue();
    }
  }
}