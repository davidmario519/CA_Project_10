// Wekinator 출력 전담
class MLOutputClient {
  MLOutputListener listener;

  MLOutputClient(MLOutputListener listener) {
    this.listener = listener;
  }

  void onOsc(OscMessage m) {

    if (!m.checkAddrPattern("/wek/outputs")) return;

    // 단일 output 이므로 arg 하나만 받으면 된다.
    if (m.arguments().length < 1) return;

    int drum = constrain(round(m.get(0).floatValue()), 0, 2);

    println("WEK OUT (single model): ", drum);

    if (listener != null) {
      // 나머지는 dummy placeholder
      listener.onWekinatorOutput(drum, -1, -1);
    }
  }
}

interface MLOutputListener {
  void onWekinatorOutput(int drum, int guitar, int vocal);
}
