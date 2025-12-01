// ==============================================
// Feature_MP.pde
// MPHandReceiver raw → Guitar 모델용 4개 feature 벡터
// ==============================================

class MPFeatureExtractor {
  MPHandReceiver hand;

  MPFeatureExtractor(MPHandReceiver hand) {
    this.hand = hand;
  }

  // Guitar 모델 입력 4개: width, height, centerX, centerY
  float[] buildGuitarInputs() {
    if (hand == null || !hand.hasData) return new float[0];
    return new float[] { hand.width, hand.height, hand.centerX, hand.centerY };
  }
}
