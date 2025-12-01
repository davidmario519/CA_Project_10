import ddf.minim.*;
import ddf.minim.analysis.*;

class VocalVisualizer {

  PApplet p;
  float smoothZ = 10;
  float smoothShift = 5;

  color[] colors;

  VocalVisualizer(PApplet p) {
    this.p = p;
    // initialize after p is available
    colors = new color[] {
      p.color(10, 85, 100),
      p.color(15, 80, 100),
      p.color(20, 75, 100),
      p.color(25, 70, 100),
      p.color(30, 65, 95)
    };
  }

  void draw(AudioPlayer vocal, FFT fft, float yOffset) {

    if (vocal == null || !vocal.isPlaying()) return;

    float vol = vocal.mix.level();

    float targetZ = p.map(vol, 0, 0.1, 8, 22);
    smoothZ = p.lerp(smoothZ, targetZ, 0.05);

    for (int z = 0; z < (int)smoothZ; z++) {
      for (int x = 0; x < p.width; x += 3) {

        float wave = p.sin((p.frameCount + x + z*smoothShift) * 0.025f) * (50 + vol*80);
        float bump = p.cos(x * 0.05f) * 10;
        float y = yOffset + 40 + wave + bump;

        float cIndex = p.map(z, 0, smoothZ-1, 0, colors.length-1);
        int low = p.floor(cIndex);
        int high = p.min(colors.length-1, p.ceil(cIndex));
        float blend = cIndex - low;

        p.fill(p.lerpColor(colors[low], colors[high], blend));
        p.noStroke();
        p.ellipse(x, y, 3, 3);
      }
    }
  }
}
