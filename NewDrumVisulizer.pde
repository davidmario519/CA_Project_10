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

  // Draw using a Minim AudioPlayer and FFT
  void draw(AudioPlayer drum, ddf.minim.analysis.FFT fft, float yOffset) {
    if (drum == null || !drum.isPlaying() || fft == null) return;

    float level = drum.mix.level();
    float bass = fft.getBand(1)*10 + fft.getBand(2)*10 + fft.getBand(3)*10;

    float targetAmp = p.map(bass, 0, 5, 40, 180); // Adjusted mapping for minim's scale
    smoothAmp = p.lerp(smoothAmp, targetAmp, 0.08f);

    // fade for a subtle trail at the drum band
    p.noStroke();
    p.fill(0, 0, 0, 45);
    p.rect(0, yOffset - 140, p.width, 280);

    float binW = p.width / (float)bins;
    
    p.stroke(barCol);
    p.fill(fillCol, 180);
    for (int i = 0; i < bins; i++) {
      int fftIndex = (int)PApplet.map(i, 0, bins-1, 0, fft.specSize()-1);
      float energy = fft.getBand(fftIndex) * 8 + bass * 0.6f + smoothAmp * 0.2f;
      float h = PApplet.constrain(energy, 0, 220);
      float x = i * binW;
      float top = yOffset - h;
      p.rect(x, top, binW * 0.9f, h);
      // mirror for silhouette feel
      p.rect(x, yOffset, binW * 0.9f, h * 0.55f);
    }
  }
}
