// ==============================================
// Feature_MP.pde
// MPHandReceiver raw → Guitar 모델용 126개 feature 벡터
// ==============================================

class MPFeatureExtractor {
  MPHandReceiver hand;

  MPFeatureExtractor(MPHandReceiver hand) {
    this.hand = hand;
  }

  // Guitar 모델 입력 126개: 좌/우 손 랜드마크 x,y,z 좌표
  float[] buildGuitarInputs() {
    if (hand == null || !hand.hasData) return new float[0];
    return hand.features; // 126개 특징 전체를 그대로 반환
  }
}
