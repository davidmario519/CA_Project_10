import processing.sound.*;

SoundFile drumCinematic, drumHiphop, drumJazz;
SoundFile currentDrum;

Amplitude drumAmp;
FFT drumFFT;

float freq = 10;
float amp = 50;

float smoothFreq = 10;
float smoothAmp = 50;

float w = 20;
float h = 20;

void setup() {
  size(800, 450);
  background(0, 0, 50);
  rectMode(CENTER);
  noStroke();

  // Load drum files
  drumCinematic = new SoundFile(this, "cinematic drum.mp3");
  drumHiphop    = new SoundFile(this, "hiphop drum.mp3");
  drumJazz      = new SoundFile(this, "jazz drum.mp3");

  // Default drum
  currentDrum = drumCinematic;
  currentDrum.loop();

  // Audio analysis
  drumAmp = new Amplitude(this);
  drumAmp.input(currentDrum);

  drumFFT = new FFT(this, 512);
  drumFFT.input(currentDrum);
}

void draw() {
  // Semi-transparent background for trail effect
  fill(0, 0, 50, 40);
  rect(0, 0, width*2, height*2);

  // Analyze audio
  drumFFT.analyze();
  float bass = drumFFT.spectrum[1]*10 + drumFFT.spectrum[2]*10 + drumFFT.spectrum[3]*10;
  float volume = drumAmp.analyze();

  // Map audio to visual parameters
  float targetAmp = map(bass, 0, 0.5, 20, 100);      // bass controls amplitude
  float targetFreq = map(volume, 0, 0.1, 5, 25);     // volume controls frequency

  // Smooth transitions using lerp
  smoothAmp = lerp(smoothAmp, targetAmp, 0.1);
  smoothFreq = lerp(smoothFreq, targetFreq, 0.05);

  // Calculate horizontal offset to center waves
  float totalWidth = 33 * w;
  float xOffset = (width - totalWidth)/2;

  // Draw layered sine waves
  for (int i = 0; i < 33; i++) {
    float x = xOffset + i * w;

    // Middle blue
    fill(220, 255, 255, 255);
    rect(x, (height/2)+sin((frameCount+i*3)/smoothFreq)*(smoothAmp*1), w, h, 50);

    for (int xLayer = 1; xLayer < 8; xLayer++) {
      // Top blue
      fill(230-(xLayer*40), 255, 255, 255-(xLayer*32));
      rect(x, (height/2-(xLayer*20)) + sin((frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13))), 
           w*(1-(xLayer*0.075)), h*(1-(xLayer*0.075)), 25-(xLayer*3.5));

      // Bottom blue
      fill(230-(xLayer*40), 255, 255, 255-(xLayer*32));
      rect(x, (height/2+(xLayer*20)) + sin((frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13))), 
           w*(1-(xLayer*0.075)), h*(1-(xLayer*0.075)), 25-(xLayer*3.5));

      // Top purple
      fill(255, 230-(xLayer*20), 255, 15);
      rect(x+10, (height/2-(xLayer*20)) + cos((frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13))), 
           w*(xLayer*0.125), h*(xLayer*0.125), 25-(xLayer*3.5));

      // Bottom purple
      fill(255, 200-(xLayer*20), 255, 15);
      rect(x+10, (height/2+(xLayer*20)) + cos((frameCount+i*3)/smoothFreq) * (smoothAmp*(1-(xLayer*0.13))), 
           w*(xLayer*0.125), h*(xLayer*0.125), 25-(xLayer*3.5));
    }
  }
}

// Switch drums with keys
void keyPressed() {
  if (key == '1') { switchDrum(drumCinematic); }
  if (key == '2') { switchDrum(drumHiphop); }
  if (key == '3') { switchDrum(drumJazz); }
}

void switchDrum(SoundFile newDrum) {
  if (currentDrum != null) currentDrum.stop();
  currentDrum = newDrum;
  currentDrum.loop();
  drumAmp.input(currentDrum);
  drumFFT.input(currentDrum);
}
