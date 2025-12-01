// ==============================================
// Input_MPReceiverOSC.pde
// MediaPipe → Processing용 손 특징 126개 수신
// 기대 주소: "/hand/features" with 126 floats
// ==============================================

class MPHandReceiver {

  float[] features = new float[126]; // 126개의 float 데이터를 저장할 배열
  boolean hasData = false;

  void onOsc(OscMessage m) {
    if (!m.checkAddrPattern("/hand/features")) return;
    
    // 126개의 인자가 모두 들어왔는지 확인
    if (m.arguments() == null || m.arguments().length < 126) {
      //println("Warning: Received OSC message with < 126 arguments at /hand/features");
      return;
    }

    // 126개 float 값을 배열에 저장
    for (int i = 0; i < 126; i++) {
      features[i] = m.get(i).floatValue();
    }
    
    hasData = true;
  }
}
