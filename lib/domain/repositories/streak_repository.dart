abstract class StreakRepository {
  int loadBest();

  Future<void> saveBest(int value);
}
