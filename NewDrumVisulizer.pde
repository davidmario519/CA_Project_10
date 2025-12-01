class DrumVisualizer {

  PApplet p;
  float smoothAmp = 50;
  int bins = 48;
  color barCol = 90;
  color fillCol = 50;

  DrumVisualizer(PApplet p) {
    this.p = p;
  }

  void setColors(color bar, color fill) {
    barCol = bar;
    fillCol = fill;
  }

  // volume: amplitude value from Amplitude.analyze(); fft should be wired to the same sound source.
  void draw(float volume, processing.sound.FFT fft, float yOffset) {
    if (fft == null) return;

    fft.analyze();
    float bass = fft.spectrum[1]*10 + fft.spectrum[2]*10 + fft.spectrum[3]*10;

    float targetAmp = p.map(bass, 0, 0.5f, 40, 180);
    smoothAmp = p.lerp(smoothAmp, targetAmp, 0.08f);

    // fade for a subtle trail at the drum band
    p.noStroke();
    p.fill(0, 0, 0, 45);
    p.rect(0, yOffset - 140, p.width, 280);

    float binW = p.width / (float)bins;
    int fftSize = fft.spectrum.length;

    p.stroke(barCol);
    p.fill(fillCol, 180);
    for (int i = 0; i < bins; i++) {
      int idx = (int)PApplet.map(i, 0, bins-1, 0, fftSize-1);
      float energy = fft.spectrum[idx] * 8 + bass * 0.6f + smoothAmp * 0.2f;
      float h = PApplet.constrain(energy, 0, 220);
      float x = i * binW;
      float top = yOffset - h;
      p.rect(x, top, binW * 0.9f, h);
      // mirror for silhouette feel
      p.rect(x, yOffset, binW * 0.9f, h * 0.55f);
    }
  }
}
