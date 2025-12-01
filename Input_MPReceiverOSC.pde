// ==============================================
// Input_MPReceiverOSC.pde
// MediaPipe → Processing용 손 특징 4개 수신
// 기대 주소: "/hand/features" with [width, height, centerX, centerY]
// ==============================================

class MPHandReceiver {

  float width = 0;
  float height = 0;
  float centerX = 0;
  float centerY = 0;
  boolean hasData = false;

  void onOsc(OscMessage m) {
    if (!m.checkAddrPattern("/hand/features")) return;
    if (m.arguments() == null || m.arguments().length < 4) return;

    width   = m.get(0).floatValue();
    height  = m.get(1).floatValue();
    centerX = m.get(2).floatValue();
    centerY = m.get(3).floatValue();
    hasData = true;
  }
}
