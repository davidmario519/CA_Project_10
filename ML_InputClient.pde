// Wekinator 입력 전송 담당 (타겟 NetAddress를 호출 시 지정)
class MLInputClient {
  OscP5 osc;

  MLInputClient(OscP5 osc) {
    this.osc = osc;
  }

  void sendInputs(float[] inputs, NetAddress target) {
    OscMessage msg = new OscMessage("/wek/inputs");
    for (int i = 0; i < inputs.length; i++) {
      msg.add(inputs[i]);
    }
    osc.send(msg, target);
  }
}
