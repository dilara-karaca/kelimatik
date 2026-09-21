/// Bundled quiz SFX. Paths are Flutter asset keys (include `assets/`).
abstract final class AppSounds {
  static const String correct = 'assets/sounds/correct_sound.mp3';
  static const String incorrect = 'assets/sounds/incorrect_sound.mp3';
  static const String lastTenSeconds = 'assets/sounds/challenge_son10.m4a';
  static const String streak5 = 'assets/sounds/5streak.mp3';
  static const String fail = 'assets/sounds/fail.wav';

  static const List<String> all = [
    correct,
    incorrect,
    lastTenSeconds,
    streak5,
    fail,
  ];

  static String mimeType(String asset) {
    if (asset.endsWith('.wav')) return 'audio/wav';
    if (asset.endsWith('.m4a')) return 'audio/mp4';
    return 'audio/mpeg';
  }
}
