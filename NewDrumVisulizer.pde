import processing.sound.*;

// Drum visualizer helper (no global setup/draw to avoid conflicts)
class DrumVisualizer {

  PApplet p;
  float smoothFreq = 10;
  float smoothAmp = 50;

  float w = 20;
  float h = 20;

  DrumVisualizer(PApplet p) {
    this.p = p;
  }

  // volume: amplitude value from Amplitude.analyze(); fft should be wired to the same sound source.
  void draw(float volume, FFT fft, float yOffset) {
    if (fft == null) return;

    fft.analyze();
    float bass = fft.spectrum[1]*10 + fft.spectrum[2]*10 + fft.spectrum[3]*10;

    float targetAmp = p.map(bass, 0, 0.5f, 20, 100);
    float targetFreq = p.map(volume, 0, 0.1f, 5, 25);

    smoothAmp = p.lerp(smoothAmp, targetAmp, 0.1f);
    smoothFreq = p.lerp(smoothFreq, targetFreq, 0.05f);

    float totalWidth = 33 * w;
    float xOffset = (p.width - totalWidth)/2;

    p.fill(0, 0, 50, 40);
    p.rect(0, 0, p.width*2, p.height*2);

    for (int i = 0; i < 33; i++) {
      float x = xOffset + i * w;

      p.fill(220, 255, 255, 255);
      p.rect(x, yOffset + p.sin((p.frameCount+i*3)/smoothFreq)*(smoothAmp*1), w, h, 50);

      for (int xLayer = 1; xLayer < 8; xLayer++) {
        p.fill(230-(xLayer*40), 255, 255, 255-(xLayer*32));
        p.rect(x, (yOffset-(xLayer*20)) + p.sin((p.frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13f))), 
             w*(1-(xLayer*0.075f)), h*(1-(xLayer*0.075f)), 25-(xLayer*3.5f));

        p.fill(230-(xLayer*40), 255, 255, 255-(xLayer*32));
        p.rect(x, (yOffset+(xLayer*20)) + p.sin((p.frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13f))), 
             w*(1-(xLayer*0.075f)), h*(1-(xLayer*0.075f)), 25-(xLayer*3.5f));

        p.fill(255, 230-(xLayer*20), 255, 15);
        p.rect(x+10, (yOffset-(xLayer*20)) + p.cos((p.frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13f))), 
             w*(xLayer*0.125f), h*(xLayer*0.125f), 25-(xLayer*3.5f));

        p.fill(255, 200-(xLayer*20), 255, 15);
        p.rect(x+10, (yOffset+(xLayer*20)) + p.cos((p.frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13f))), 
             w*(xLayer*0.125f), h*(xLayer*0.125f), 25-(xLayer*3.5f));
      }
    }
  }
}
