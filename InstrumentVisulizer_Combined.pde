import ddf.minim.*;
import ddf.minim.analysis.*;

class CombinedVisualizer {

  PApplet p;
  VocalViz vocal;
  GuitarVisualizer guitar;
  DrumVisualizer drum;
  color[][] vocalPalettes;
  color[][] guitarPalettes;
  color[][] drumPalettes; // [genre][2] -> bar, fill

  CombinedVisualizer(PApplet p) {
    this.p = p;
    vocal = new VocalViz(p);
    guitar = new GuitarVisualizer(p);
    drum = new DrumVisualizer(p);

    // Palettes per genre: 0=Jazz,1=HipHop,2=Funk
    vocalPalettes = new color[][] {
      { p.color(245), p.color(210), p.color(170), p.color(130), p.color(90) },   // Jazz: bright-to-dark gray
      { p.color(240), p.color(190), p.color(150), p.color(110), p.color(70) },   // HipHop: warm gray
      { p.color(230), p.color(205), p.color(170), p.color(140), p.color(100) }   // Funk: neutral gray
    };
    guitarPalettes = new color[][] {
      { p.color(70, 170, 255),  p.color(90, 190, 255),  p.color(120, 205, 255), p.color(170, 220, 255), p.color(215, 235, 255) }, // Jazz blue
      { p.color(255, 120, 120), p.color(240, 90, 90),   p.color(220, 70, 70),   p.color(200, 60, 60),   p.color(170, 50, 50) },   // HipHop red
      { p.color(120, 210, 140), p.color(100, 190, 120), p.color(80, 170, 105),  p.color(70, 150, 95),   p.color(60, 135, 80) }    // Funk green
    };
    drumPalettes = new color[][] {
      { p.color(120), p.color(70) },   // Jazz
      { p.color(200), p.color(120) },  // HipHop
      { p.color(90),  p.color(55) }    // Funk
    };
  }

  void drawAll(AudioPlayer voc, ddf.minim.analysis.FFT vocFFT,
               AudioPlayer git,
               float drumAmp, processing.sound.FFT drumFFT,
               int vocalGenre, int guitarGenre, int drumGenre) {

    applyPalettes(vocalGenre, guitarGenre, drumGenre);

    float guitarY = p.height * 0.70f;
    float drumY = p.height * 0.50f;
    float vocalY = p.height * 0.18f;

    vocal.draw(voc, vocFFT, vocalY);
    guitar.draw(git, guitarY);
    drum.draw(drumAmp, drumFFT, drumY);
  }

  void applyPalettes(int vGenre, int gGenre, int dGenre) {
    int vg = clampGenre(vGenre);
    int gg = clampGenre(gGenre);
    int dg = clampGenre(dGenre);

    vocal.setPalette(vocalPalettes[vg]);
    guitar.setPalette(guitarPalettes[gg]);
    drum.setColors(drumPalettes[dg][0], drumPalettes[dg][1]);
  }

  int clampGenre(int g) {
    if (g < 0 || g > 2) return 0;
    return g;
  }
}
