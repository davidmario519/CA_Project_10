class CombinedVisualizer {

  PApplet p;
  VocalVisualizer vocal;
  GuitarVisualizer guitar;
  DrumVisualizer drum;

  CombinedVisualizer(PApplet p) {
    this.p = p;
    vocal = new VocalVisualizer(p);
    guitar = new GuitarVisualizer(p);
    drum = new DrumVisualizer(p);
  }

  void drawAll(AudioPlayer voc, FFT vocFFT,
               AudioPlayer git,
               float drumAmp, FFT drumFFT) {

    vocal.draw(voc, vocFFT, 80);
    guitar.draw(git);
    drum.draw(drumAmp, drumFFT, p.height * 0.75f);
  }
}
