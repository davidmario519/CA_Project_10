class GuitarVisualizer {

  PApplet p;
  color[] colors;

  GuitarVisualizer(PApplet p) {
    this.p = p;

    // cool blue gradient for guitar (simplified)
    colors = new color[]{
      p.color(60, 150, 255),
      p.color(90, 180, 255),
      p.color(130, 200, 255),
      p.color(180, 220, 255),
      p.color(220, 235, 255)
    };
  }

  void setPalette(color[] newColors) {
    if (newColors == null || newColors.length == 0) return;
    colors = newColors;
  }

  void draw(AudioPlayer guitar, float baseY) {

    if (guitar == null || !guitar.isPlaying()) return;

    float[] wave = guitar.mix.toArray();

    for (int i = 0; i < 4; i++) {
      float thickness = 1.2f + i*0.3f;
      p.beginShape();
      for (int x = 0; x < p.width; x += 6) {

        int idx = (int)p.map(x, 0, p.width, 0, wave.length-1);
        float h = p.map(wave[idx], -1, 1, -35, 35);

        float y = baseY + h + i * 18 - 30;

        float cIndex = p.map(i, 0, 4, 0, colors.length-1);
        int low = p.floor(cIndex);
        int high = p.min(colors.length-1, p.ceil(cIndex));
        float blend = cIndex - low;

        p.stroke(p.lerpColor(colors[low], colors[high], blend));
        p.strokeWeight(thickness);

        p.vertex(x, y);

        // occasional nodes for visual interest
        if (x % 80 == 0) {
          p.point(x, y);
        }
      }
      p.endShape();
    }
  }
}
