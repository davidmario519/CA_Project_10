class GuitarVisualizer {

  PApplet p;
  color[] colors;

  GuitarVisualizer(PApplet p) {
    this.p = p;

    colors = new color[]{
      p.color(255, 200, 0),
      p.color(255, 220, 50),
      p.color(255, 235, 90),
      p.color(255, 245, 140),
      p.color(255, 255, 200)
    };
  }

  void draw(AudioPlayer guitar) {

    if (guitar == null || !guitar.isPlaying()) return;

    float[] wave = guitar.mix.toArray();

    for (int i = 0; i < 5; i++) {
      p.beginShape();
      for (int x = 0; x < p.width; x += 8) {

        int idx = (int)p.map(x, 0, p.width, 0, wave.length-1);
        float h = p.map(wave[idx], -1, 1, -40, 40);

        float y = p.height/2 + h + i * 15;

        float cIndex = p.map(y, 0, p.height, 0, colors.length-1);
        int low = p.floor(cIndex);
        int high = p.min(colors.length-1, p.ceil(cIndex));
        float blend = cIndex - low;

        p.stroke(p.lerpColor(colors[low], colors[high], blend));
        p.strokeWeight(2);

        p.vertex(x, y);
      }
      p.endShape();
    }
  }
}
