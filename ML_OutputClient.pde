// Wekinator 출력 전담
class MLOutputClient {
  MLOutputListener listener;

  MLOutputClient(MLOutputListener listener) {
    this.listener = listener;
  }

  void onOsc(OscMessage m) {
    if (!m.checkAddrPattern("/wek/outputs") || m.arguments().length < 3) return;

    int drum   = constrain(round(m.get(0).floatValue()), 0, 2);
    int guitar = constrain(round(m.get(1).floatValue()), 0, 2);
    int vocal  = constrain(round(m.get(2).floatValue()), 0, 2);

    if (listener != null) listener.onWekinatorOutput(drum, guitar, vocal);
  }
}

interface MLOutputListener {
  void onWekinatorOutput(int drum, int guitar, int vocal);
}
