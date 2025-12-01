import ddf.minim.*;
import ddf.minim.analysis.*;

// Vocal visualizer helper (no global setup/draw)
class VocalViz {

  PApplet p;
  float smoothZ = 10;
  float smoothShift = 5;

  color[] colors;

  VocalViz(PApplet p) {
    this.p = p;
    // simple grayscale gradient for clean lines
    colors = new color[] {
      p.color(240),
      p.color(210),
      p.color(180),
      p.color(140),
      p.color(100)
    };
  }

  void setPalette(color[] newColors) {
    if (newColors == null || newColors.length == 0) return;
    colors = newColors;
  }

  // Draw ribbons using the provided AudioPlayer + FFT (already wired to the player).
  // yOffset: baseline from the top of the window where the ribbons start.
  void draw(AudioPlayer vocal, ddf.minim.analysis.FFT fft, float yOffset) {

    if (vocal == null || !vocal.isPlaying() || fft == null) return;

    fft.forward(vocal.mix);

    float vol = vocal.mix.level();
    float targetZ = PApplet.map(vol, 0, 0.1f, 6, 16); // fewer layers
    smoothZ = p.lerp(smoothZ, targetZ, 0.05f);

    int lowBand = 5;
    int highBand = 20;
    float freqEnergy = 0;
    for (int i = lowBand; i <= highBand; i++) {
      freqEnergy += fft.getBand(i);
    }
    freqEnergy /= (highBand - lowBand + 1);
    float targetShift = PApplet.map(freqEnergy, 0, 5, 4, 6);
    smoothShift = p.lerp(smoothShift, targetShift, 0.05f);

    for (int z = 0; z < (int)smoothZ; z++) {
      float layerOffset = z * 1.3f;
      for (int x = 0; x < p.width; x += 3) {
        float wave = p.sin((p.frameCount + x*1.2f + z*smoothShift) * 0.018f) * (30 + vol*60);
        float bump = p.cos(x*0.04f + z*0.2f) * 8;
        float y = yOffset + layerOffset + wave + bump;

        float cIndex = PApplet.map(z, 0, smoothZ-1, 0, colors.length-1);
        int low = p.floor(cIndex);
        int high = p.min(colors.length-1, p.ceil(cIndex));
        float blend = cIndex - low;

        p.stroke(p.lerpColor(colors[low], colors[high], blend));
        p.strokeWeight(1.6f);
        p.point(x, y);
      }
    }
  }
}
