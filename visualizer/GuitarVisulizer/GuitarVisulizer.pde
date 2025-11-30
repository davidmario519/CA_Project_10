/* 
  GUITAR STRING WAVEFORM VISUAL (Processing Java Version)
  -------------------------------------------------------
  Based on your p5.js example — fully converted.

  ✔ Audio-reactive vibrating guitar strings
  ✔ Uses 3 sound files:
        "cinematic guitar.mp3"
        "hiphop guitar.mp3"
        "jazz guitar.mp3"
  ✔ Press keys:
        1 = Cinematic
        2 = Hip-hop
        3 = Jazz
*/

import ddf.minim.*;
import ddf.minim.analysis.*;

// -------------------- AUDIO --------------------
Minim minim;
AudioPlayer guitar;
FFT fft;

// Track names
String[] guitarTracks = {
  "cinematic guitar.mp3",
  "hiphop guitar.mp3",
  "jazz guitar.mp3"
};

int currentTrack = 0;


// -------------------- VISUAL SETTINGS --------------------
color[][] instrumentPalettes;
color[] colors;
int numStrings = 5;


void setup() {
  size(800, 200);
  noFill();
  minim = new Minim(this);

  // -------------------- COLOR PALETTES --------------------
  instrumentPalettes = new color[][] {
    
    // TRACK 1 = BLUE GRADIENT
    {
      color(0, 60, 200),
      color(0, 110, 230),
      color(50, 150, 255),
      color(120, 200, 255),
      color(190, 240, 255)
    },
    
    // TRACK 2 = PURPLE GRADIENT
    {
      color(90, 0, 150),
      color(130, 30, 170),
      color(170, 60, 200),
      color(210, 90, 230),
      color(240, 130, 255)
    },
    
    // TRACK 3 = YELLOW GRADIENT
    {
      color(255, 200, 0),
      color(255, 220, 50),
      color(255, 235, 90),
      color(255, 245, 140),
      color(255, 255, 200)
    }
  };

  // Set initial color set
  colors = instrumentPalettes[currentTrack];

  loadTrack(currentTrack);

  fft = new FFT(guitar.bufferSize(), guitar.sampleRate());
}



void draw() {
  background(0);

  fft.forward(guitar.mix);
  float[] waveform = guitar.mix.toArray();

  for (int i = 0; i < numStrings; i++) {
    beginShape();
    
    for (int x = 0; x < width; x += 8) {

      int index = int(map(x, 0, width, 0, waveform.length-1));
      float waveHeight = map(waveform[index], -1, 1, -80, 80);

      float y = height/2 + waveHeight + i * 18;

      float cIndex = map(y, 0, height, 0, colors.length-1);

      int low = floor(cIndex);
      int high = min(colors.length-1, ceil(cIndex));
      float blendAmount = cIndex - floor(cIndex);

      stroke( lerpColor(colors[low], colors[high], blendAmount) );
      strokeWeight(2);

      vertex(x, y);
    }
    endShape();
  }
}



// -------------------- LOAD TRACKS --------------------
void loadTrack(int index) {
  if (guitar != null) guitar.close();
  guitar = minim.loadFile(guitarTracks[index], 2048);
  guitar.loop();

  // Update colors when instrument changes
  colors = instrumentPalettes[index];
}



// -------------------- KEY CONTROL --------------------
void keyPressed() {
  if (key == '1') { currentTrack = 0; loadTrack(0); }
  if (key == '2') { currentTrack = 1; loadTrack(1); }
  if (key == '3') { currentTrack = 2; loadTrack(2); }
}



// -------------------- CLEAN EXIT --------------------
void stop() {
  guitar.close();
  minim.stop();
  super.stop();
}
