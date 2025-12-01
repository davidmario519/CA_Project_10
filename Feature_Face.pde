// ==============================================
// Feature_Face.pde
// FaceReceiver raw 값 → Vocal 모델용 4개 feature 벡터 생성
// ==============================================

class FaceFeatureExtractor {

  FaceReceiver face;

  FaceFeatureExtractor(FaceReceiver face) {
    this.face = face;
  }

  // Vocal 모델 입력 4개 생성
  float[] buildVocalInputs() {
    if (face == null) return new float[0];

    float eyeAvg = (face.eyeL + face.eyeR) * 0.5;
    float browAvg = (face.browL + face.browR) * 0.5;

    return new float[] {
      face.mouthW,
      face.mouthH,
      eyeAvg,
      browAvg
    };
  }
}
