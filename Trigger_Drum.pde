// ==============================================
// DrumTrigger.pde
// Wekinator Drum 장르(0=Jazz,1=HipHop,2=Cinematic)별로 샘플 재생
// ==============================================

class DrumTrigger {

  SoundFile jazz;
  SoundFile hiphop;
  SoundFile cinematic;
  int lastGenre = -1;

  DrumTrigger(PApplet app) {
    jazz = new SoundFile(app, "src/sound src/jazz/jazz drum.mp3");
    hiphop = new SoundFile(app, "src/sound src/hiphop/hiphop drum.mp3");
    cinematic = new SoundFile(app, "src/sound src/cinematic/cinematic drum.mp3");
  }

  void trigger(int genre) {
    if (genre == lastGenre) return; // 같은 장르 반복 재생 방지
    lastGenre = genre;
    stopAll();

    if (genre == 0 && jazz != null) {
      jazz.play();
    } else if (genre == 1 && hiphop != null) {
      hiphop.play();
    } else if (genre == 2 && cinematic != null) {
      cinematic.play();
    }
  }

  void stopAll() {
    if (jazz != null) jazz.stop();
    if (hiphop != null) hiphop.stop();
    if (cinematic != null) cinematic.stop();
  }
}
