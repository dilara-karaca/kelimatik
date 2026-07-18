abstract class FavoritesRepository {
  Set<int> loadIds();

  Future<void> toggle(int wordId);

  Future<void> setFavorite(int wordId, bool favorite);

  bool isFavorite(int wordId);
}
