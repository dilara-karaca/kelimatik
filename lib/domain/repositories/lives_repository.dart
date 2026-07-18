import '../models/lives_state.dart';

abstract class LivesRepository {
  LivesState load();

  Future<void> save(LivesState state);
}
