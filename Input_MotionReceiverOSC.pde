// ==============================================
// 1_Input_MotionReceiverOSC.pde
// Smartphone MotionSender → Processing
// with smoothing + highfreq detection + timestamp
// ==============================================

class MotionReceiver {

  // Raw sensor values
  float ax, ay, az;
  float gx, gy, gz;
  float rx, ry, rz;

  // Smoothed values
  float sax, say, saz;
  float srx, sry, srz;

  // For vibration / cinematic detection
  float prevAccMag = 0;
  float highFreqScore = 0;

  // Timestamp (ms)
  long lastTimestamp = 0;

  // Smoothing factor
  float SMOOTH = 0.25;

  MotionReceiver() {}

  // -----------------------------
  // OSC 입력 처리
  // -----------------------------
  void onOsc(OscMessage m) {

    // Timestamp 업데이트
    lastTimestamp = millis();

    if (m.checkAddrPattern("/accel")) {
      ax = m.get(0).floatValue();
      ay = m.get(1).floatValue();
      az = m.get(2).floatValue();

      // Smooth accel
      sax = lerp(sax, ax, SMOOTH);
      say = lerp(say, ay, SMOOTH);
      saz = lerp(saz, az, SMOOTH);

      updateHighFreq();   // Cinematic 특징
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

      // Smooth gyro
      srx = lerp(srx, rx, SMOOTH);
      sry = lerp(sry, ry, SMOOTH);
      srz = lerp(srz, rz, SMOOTH);
    }
  }

  // -----------------------------
  // Cinematic 구분용 high-frequency score 계산
  // -----------------------------
  void updateHighFreq() {
    float mag = sqrt(sax*sax + say*say + saz*saz);
    float diff = abs(mag - prevAccMag);

    // diff가 클수록 high-frequency vibration
    highFreqScore = lerp(highFreqScore, diff, 0.6);

    prevAccMag = mag;
  }

  // -----------------------------
  // Feature 계산 함수들
  // -----------------------------
  float getForce() {
    return sqrt(sax*sax + say*say + saz*saz);      // HipHop 구분용
  }

  float getGyroSwing() {
    return sqrt(srx*srx + sry*sry + srz*srz);      // Jazz 구분용
  }

  float getShakeComplexity() {
    return highFreqScore;                           // Cinematic 구분용
  }

  float getSmoothness() {
    // 회전의 변동성이 낮을수록 부드럽다
    return 1.0 / (1.0 + getGyroSwing());
  }

  float getGravityTilt() {
    return abs(gy);                                 // 약간의 보조 신호
  }
}
