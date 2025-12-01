import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer vocal;
FFT fft;

// Tracks
String[] vocalTracks = {
  "cinematic vocal.mp3",
  "hiphop vocal.mp3",
  "jazz vocal.mp3"
};
int currentTrack = 0;

// Ribbon visual settings
float middle;
float shift = 5;
float zCount = 10;  // start with fewer layers for better visibility

// Colors per track
color[][] palettes;
color[] colors;

// For smoothing music influence
float smoothShift = 5;
float smoothZCount = 10;

void setup() {
  size(800, 200);
  colorMode(HSB, 100);
  noStroke();
  
  middle = height/2;

  minim = new Minim(this);

  // Vocal color palettes
  palettes = new color[][] {
    { color(2, 40, 100), color(5, 30, 90), color(8, 20, 95), color(10, 10, 100), color(0, 0, 100) },   // Cinematic
    { color(80, 95, 100), color(70, 95, 100), color(60, 95, 100), color(50, 95, 100), color(40, 95, 100) }, // Hip-hop
    { color(10, 85, 100), color(15, 80, 100), color(20, 75, 100), color(25, 70, 100), color(30, 65, 95) }  // Jazz
  };
  colors = palettes[currentTrack];

  loadTrack(currentTrack);

  fft = new FFT(vocal.bufferSize(), vocal.sampleRate());
}

void draw() {
  background(0);

  if (vocal == null || !vocal.isPlaying()) return;

  fft.forward(vocal.mix);

  // -------------------- MUSIC-DRIVEN PARAMETERS --------------------
  float vol = vocal.mix.level();
  // Subtle, amplified mapping for visual clarity
  float targetZ = map(vol, 0, 0.1, 8, 22); // fewer layers start, max slightly higher
  smoothZCount = lerp(smoothZCount, targetZ, 0.05);

  // Low-mid frequencies modulate layer spacing
  int lowBand = 5;
  int highBand = 20;
  float freqEnergy = 0;
  for (int i = lowBand; i <= highBand; i++) {
    freqEnergy += fft.getBand(i);
  }
  freqEnergy /= (highBand - lowBand + 1);
  float targetShift = map(freqEnergy, 0, 5, 4, 6);
  smoothShift = lerp(smoothShift, targetShift, 0.05);

  // -------------------- DRAW RIBBONS --------------------
  for (int z = 0; z < int(smoothZCount); z++) {
    for (int x = 0; x < width; x += 2) {
      float wave = sin((frameCount + x + z*smoothShift) * 0.025) * (35 + vol*50); // slightly higher base for visibility
      float bump = cos(x*0.05) * 10;
      float y = middle + wave + bump;

      // gradient based on layer
      float cIndex = map(z, 0, smoothZCount-1, 0, colors.length-1);
      int low = floor(cIndex);
      int high = min(colors.length-1, ceil(cIndex));
      float blend = cIndex - low;

      fill(lerpColor(colors[low], colors[high], blend));
      ellipse(x, y, 3, 3);
    }
  }
}

void loadTrack(int index) {
  if (index < 0 || index >= vocalTracks.length) return;

  if (vocal != null) vocal.close();
  vocal = minim.loadFile(vocalTracks[index], 2048);
  vocal.loop();

  colors = palettes[index];

  // Reset smoothed values for new track
  smoothZCount = zCount;
  smoothShift = shift;
}

void keyPressed() {
  if (key == '1') { currentTrack = 0; loadTrack(0); }
  if (key == '2') { currentTrack = 1; loadTrack(1); }
  if (key == '3') { currentTrack = 2; loadTrack(2); }
}

void stop() {
  if (vocal != null) vocal.close();
  minim.stop();
  super.stop();
}
