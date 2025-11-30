//--------------------------------------------------
// MotionReceiverOSC.pde
// 여러 종류의 OSC 센서 앱을 모두 지원하게 만든 버전
//--------------------------------------------------

class MotionReceiver {

  // Raw sensors
  float ax, ay, az;         // accel
  float gx, gy, gz;         // gyro
  float pitch, roll, yaw;   // orientation

  MotionReceiver() {}

  void onOsc(OscMessage m) {

    // ================================
    // 1) Accel
    // ================================
    if (m.checkAddrPattern("/accel")) {      // Processing MotionSender
      ax = m.get(0).floatValue();
      ay = m.get(1).floatValue();
      az = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/acc")) {        // Kiwi iOS app
      ax = m.get(0).floatValue();
      ay = m.get(1).floatValue();
      az = m.get(2).floatValue();
    }

    // ================================
    // 2) Gyro
    // ================================
    if (m.checkAddrPattern("/gyro")) {       // Kiwi + Processing
      gx = m.get(0).floatValue();
      gy = m.get(1).floatValue();
      gz = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/gyroscope")) {  // 일부 앱
      gx = m.get(0).floatValue();
      gy = m.get(1).floatValue();
      gz = m.get(2).floatValue();
    }

    // ================================
    // 3) Orientation (Attitude)
    // ================================
    if (m.checkAddrPattern("/gravity")) {    // Processing MotionSender
      pitch = m.get(0).floatValue();
      roll  = m.get(1).floatValue();
      yaw   = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/att")) {       // Kiwi iOS app (pitch,roll,yaw)
      pitch = m.get(0).floatValue();
      roll  = m.get(1).floatValue();
      yaw   = m.get(2).floatValue();
    }

    // Debug log
    if (frameCount % 30 == 0) {
      println("[OSC]", m.addrPattern(), 
              "ACC:", ax, ay, az,
              "GYRO:", gx, gy, gz,
              "ATT:", pitch, roll, yaw);
    }
  }

  // =======================================================
  // Feature functions (그대로 사용)
  // =======================================================
  float getForce() { return abs(ax) + abs(ay) + abs(az); }
  float getGyroSwing() { return abs(gx) + abs(gy) + abs(gz); }
  float getShakeComplexity() { return noise(frameCount*0.1)*0.5; }
  float getSmoothness() { return 1.0 - getGyroSwing(); }
  float getGravityTilt() { return abs(pitch) + abs(roll); }
}
