import processing.sound.*;
import ddf.minim.*;
import ddf.minim.analysis.*;

// 별도 창에서 드럼/기타/보컬 루프를 시각화하는 보조 PApplet
// CA_Project_10.pde의 장르 변화를 받아 트랙을 교체한다.
class InstrumentVisualizerWindow extends PApplet {

  // DRUM
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
  color bg = color(0);

  // GUITAR
  Minim minim;
  AudioPlayer guitar;
  String[] guitarTracks = { "cinematic/cinematic guitar.mp3", "hiphop/hiphop guitar.mp3", "jazz/jazz guitar.mp3" };
  int guitarTrackIndex = 0;
  color[][] guitarPalettes;
  color[] guitarColors;
  int numStrings = 5;

  // VOCAL
  AudioPlayer vocal;
  String[] vocalTracks = { "cinematic/cinematic vocal.mp3", "hiphop/hiphop vocal.mp3", "jazz/jazz vocal.mp3" };
  int vocalTrackIndex = 0;
  color[][] vocalPalettes;
  color[] vocalColors;
  float middle;
  float shift = 5;
  float zCount = 10;
  float smoothShift = 5;
  float smoothZCount = 10;

  void settings() {
    size(800, 800);
  }

  void setup() {
    frameRate(30);
    noStroke();
    background(bg);

    // DRUM INIT
    drumCinematic = new SoundFile(this, "data/cinematic/cinematic drum.mp3");
    drumHiphop    = new SoundFile(this, "data/hiphop/hiphop drum.mp3");
    drumJazz      = new SoundFile(this, "data/jazz/jazz drum.mp3");
    currentDrum = drumCinematic;
    currentDrum.loop();
    drumAmp = new Amplitude(this);
    drumAmp.input(currentDrum);
    drumFFT = new FFT(this, 512);
    drumFFT.input(currentDrum);

    // MINIM INIT
    minim = new Minim(this);

    // GUITAR INIT
    guitarPalettes = new color[][] {
      { color(0, 60, 200), color(0, 110, 230), color(50, 150, 255), color(120, 200, 255), color(190, 240, 255) },
      { color(90, 0, 150), color(130, 30, 170), color(170, 60, 200), color(210, 90, 230), color(240, 130, 255) },
      { color(255, 200, 0), color(255, 220, 50), color(255, 235, 90), color(255, 245, 140), color(255, 255, 200) }
    };
    guitarColors = guitarPalettes[guitarTrackIndex];
    loadGuitar(guitarTrackIndex);

    // VOCAL INIT
    middle = height/6;
    vocalPalettes = new color[][] {
      { color(2, 40, 100), color(5, 30, 90), color(8, 20, 95), color(10, 10, 100), color(0, 0, 100) },
      { color(80, 95, 100), color(70, 95, 100), color(60, 95, 100), color(50, 95, 100), color(40, 95, 100) },
      { color(10, 85, 100), color(15, 80, 100), color(20, 75, 100), color(25, 70, 100), color(30, 65, 95) }
    };
    vocalColors = vocalPalettes[vocalTrackIndex];
    loadVocal(vocalTrackIndex);
  }

  void draw() {
    background(bg);

    // VOCAL TOP
    if (vocal != null && vocal.isPlaying()) {
      float vol = vocal.mix.level();
      float targetZ = map(vol, 0, 0.1, 8, 22);
      smoothZCount = lerp(smoothZCount, targetZ, 0.05);
      float vocalYOffset = 45;
      for (int z = 0; z < int(smoothZCount); z++) {
        for (int x = 0; x < width; x += 4) {
          float wave = sin((frameCount + x + z*smoothShift) * 0.025) * (50 + vol*80);
          float bump = cos(x*0.05) * 10;
          float y = middle + wave + bump + vocalYOffset;
          float cIndex = map(z, 0, smoothZCount-1, 0, vocalColors.length-1);
          int low = floor(cIndex);
          int high = min(vocalColors.length-1, ceil(cIndex));
          float blend = cIndex - low;
          fill(lerpColor(vocalColors[low], vocalColors[high], blend));
          ellipse(x, y, 3, 3);
        }
      }
    }

    // GUITAR MID
    if (guitar != null && guitar.isPlaying()) {
      pushStyle();
      float guitarYOffset = -40;
      float[] waveform = guitar.mix.toArray();
      for (int i = 0; i < numStrings; i++) {
        beginShape();
        for (int x = 0; x < width; x += 8) {
          int index = int(map(x, 0, width, 0, waveform.length-1));
          float waveHeight = map(waveform[index], -1, 1, -40, 40);
          float y = height/2 + waveHeight + i * 12 + guitarYOffset;
          float cIndex = map(y, 0, height, 0, guitarColors.length-1);
          int low = floor(cIndex);
          int high = min(guitarColors.length-1, ceil(cIndex));
          float blendAmount = cIndex - low;
          stroke( lerpColor(guitarColors[low], guitarColors[high], blendAmount) );
          strokeWeight(2);
          vertex(x, y);
        }
        endShape();
      }
      popStyle();
    }

    // DRUM BOTTOM
    fill(0, 0, 50, 40);
    rect(0, 0, width*2, height*2);
    drumFFT.analyze();
    float bass = drumFFT.spectrum[1]*10 + drumFFT.spectrum[2]*10 + drumFFT.spectrum[3]*10;
    float volume = drumAmp.analyze();
    float targetAmp = map(bass, 0, 0.5, 15, 80);
    float targetFreq = map(volume, 0, 0.1, 5, 25);
    smoothAmp = lerp(smoothAmp, targetAmp, 0.1);
    smoothFreq = lerp(smoothFreq, targetFreq, 0.05);
    float totalWidth = 33 * w;
    float xOffset = (width - totalWidth)/2;
    float drumYOffset = height * 0.78;
    for (int i = 0; i < 33; i++) {
      float x = xOffset + i * w;
      fill(220, 255, 255, 255);
      rect(x, drumYOffset + sin((frameCount+i*3)/smoothFreq)*(smoothAmp*1), w, h, 50);
      for (int xLayer = 1; xLayer < 8; xLayer++) {
        fill(230-(xLayer*40), 255, 255, 255-(xLayer*32));
        rect(x, drumYOffset-(xLayer*20) + sin((frameCount+i*3)/smoothFreq)*(smoothAmp*(1-(xLayer*0.13))), 
             w*(1-(xLayer*0.075)), h*(1-(xLayer*0.075)), 25-(xLayer*3.5));
        fill(230-(xLayer*40), 255, 255, 255-(xLayer*32));
        rect(x, drumYOffset+(xLayer*20) + sin((frameCount+i*3)/smoothFreq)*(smoothAmp*(1-(xLayer*0.13))), 
             w*(1-(xLayer*0.075)), h*(1-(xLayer*0.075)), 25-(xLayer*3.5));
        fill(255, 230-(xLayer*20), 255, 15);
        rect(x+10, drumYOffset-(xLayer*20) + cos((frameCount+i*3)/smoothFreq)*(smoothAmp*(1-(xLayer*0.13))), 
             w*(xLayer*0.125), h*(xLayer*0.125), 25-(xLayer*3.5));
        fill(255, 200-(xLayer*20), 255, 15);
        rect(x+10, drumYOffset+(xLayer*20) + cos((frameCount+i*3)/smoothFreq)*(smoothAmp*(1-(xLayer*0.13))), 
             w*(xLayer*0.125), h*(xLayer*0.125), 25-(xLayer*3.5));
      }
    }
  }

  // 외부에서 호출: 장르 0/1/2 설정
  void setDrum(int genre) { switchDrum(genre); }
  void setGuitar(int genre) { loadGuitar(genre); }
  void setVocal(int genre) { loadVocal(genre); }

  void switchDrum(int genre) {
    SoundFile next = null;
    if (genre == 0) next = drumJazz;
    else if (genre == 1) next = drumHiphop;
    else if (genre == 2) next = drumCinematic;
    if (next == null || next == currentDrum) return;
    if (currentDrum != null) currentDrum.stop();
    currentDrum = next;
    currentDrum.loop();
    drumAmp.input(currentDrum);
    drumFFT.input(currentDrum);
  }

  void loadGuitar(int index) {
    if (index < 0 || index >= guitarTracks.length) return;
    if (guitar != null) guitar.close();
    guitar = minim.loadFile("data/" + guitarTracks[index], 2048);
    guitar.loop();
    guitarColors = guitarPalettes[index];
  }

  void loadVocal(int index) {
    if (index < 0 || index >= vocalTracks.length) return;
    if (vocal != null) vocal.close();
    vocal = minim.loadFile("data/" + vocalTracks[index], 2048);
    vocal.loop();
    vocalColors = vocalPalettes[index];
    smoothZCount = zCount;
    smoothShift = shift;
  }

  public void stop() {
    if (currentDrum != null) currentDrum.stop();
    if (guitar != null) guitar.close();
    if (vocal != null) vocal.close();
    if (minim != null) minim.stop();
    super.stop();
  }
}
