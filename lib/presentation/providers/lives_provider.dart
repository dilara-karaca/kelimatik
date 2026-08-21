import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/lives_state.dart';
import 'dependency_providers.dart';

final livesProvider =
    NotifierProvider<LivesNotifier, LivesState>(LivesNotifier.new);

class LivesNotifier extends Notifier<LivesState> {
  Timer? _ticker;

  @override
  LivesState build() {
    ref.onDispose(() => _ticker?.cancel());
    final loaded = ref.read(livesRepositoryProvider).load().refreshed();
    _ensureTicker(loaded);
    // Persist refreshed value so offline gains are saved.
    Future.microtask(() async {
      try {
        await _persist(loaded);
      } catch (_) {
        // Cloud sync may fail offline; local cache already holds [loaded].
      }
    });
    return loaded;
  }

  void _ensureTicker(LivesState lives) {
    _ticker?.cancel();
    if (lives.isFull) {
      _ticker = null;
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final next = state.refreshed();
    if (next.current != state.current ||
        next.regenStartedAt != state.regenStartedAt) {
      state = next;
      unawaited(_persist(next));
    } else {
      state = next.copyWithClock(DateTime.now());
    }
    if (next.isFull) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _persist(LivesState lives, {bool critical = false}) async {
    try {
      await ref.read(livesRepositoryProvider).save(lives);
    } catch (_) {
      if (critical) rethrow;
    }
  }

  Future<LivesState> loseLife() async {
    final previous = state;
    final next = state.loseOne();
    state = next;
    _ensureTicker(next);
    try {
      await _persist(next, critical: true);
    } catch (_) {
      state = previous;
      _ensureTicker(previous);
      rethrow;
    }
    return next;
  }

  /// Grants +1 life (rewarded ad). No-op when already full.
  Future<LivesState> gainLife() async {
    final previous = state;
    final next = state.gainOne();
    if (next.current == previous.current) return next;
    state = next;
    _ensureTicker(next);
    try {
      await _persist(next, critical: true);
    } catch (_) {
      state = previous;
      _ensureTicker(previous);
      rethrow;
    }
    return next;
  }

  void refresh() {
    final next = state.refreshed();
    state = next;
    _ensureTicker(next);
    unawaited(_persist(next));
  }
}
