// ==============================================
// MotionReceiver.pde — raw iPhone sensor listener
// ==============================================

class MotionReceiver {

  float ax, ay, az;
  float gx, gy, gz;
  float pitch, roll, yaw;

  MotionReceiver() {}

  void onOsc(OscMessage m) {

    if (m.checkAddrPattern("/accel")) {
      ax = m.get(0).floatValue();
      ay = m.get(1).floatValue();
      az = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/gyro")) {
      gx = m.get(0).floatValue();
      gy = m.get(1).floatValue();
      gz = m.get(2).floatValue();
    }

    if (m.checkAddrPattern("/gravity")) {
      pitch = m.get(0).floatValue();
      roll  = m.get(1).floatValue();
      yaw   = m.get(2).floatValue();
    }
  }

  // === Feature extraction ===
  float getForce() { return abs(ax) + abs(ay) + abs(az); }
  float getGyroSwing() { return abs(gx) + abs(gy) + abs(gz); }
  float getShakeComplexity() { return noise(frameCount*0.03); }
  float getSmoothness() { return 1.0 - getGyroSwing(); }
  float getGravityTilt() { return abs(pitch) + abs(roll); }
}