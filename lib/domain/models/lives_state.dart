import '../../core/constants/app_constants.dart';

/// Persisted lives with offline regeneration support.
class LivesState {
  const LivesState({
    required this.current,
    this.regenStartedAt,
    this.now,
  });

  final int current;

  /// Wall-clock time when the current missing-life regen cycle started.
  final DateTime? regenStartedAt;

  /// Injectable "now" for UI countdown (defaults to DateTime.now).
  final DateTime? now;

  static const full = LivesState(current: AppConstants.maxLives);

  bool get isEmpty => current <= 0;
  bool get isFull => current >= AppConstants.maxLives;
  bool get canPlay => current > 0;

  DateTime get _now => now ?? DateTime.now();

  /// Time remaining until the next life is restored. Null when full.
  Duration? get timeUntilNextLife {
    if (isFull) return null;
    final anchor = regenStartedAt;
    if (anchor == null) return AppConstants.lifeRegenDuration;
    final elapsed = _now.difference(anchor);
    final remaining = AppConstants.lifeRegenDuration - elapsed;
    if (remaining.isNegative) return Duration.zero;
    return remaining;
  }

  String get nextLifeCountdownLabel {
    final remaining = timeUntilNextLife;
    if (remaining == null) return '';
    final totalSeconds = remaining.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Applies offline regeneration based on wall clock.
  LivesState refreshed([DateTime? at]) {
    final clock = at ?? DateTime.now();
    final clamped = current.clamp(0, AppConstants.maxLives).toInt();

    if (clamped >= AppConstants.maxLives) {
      return LivesState(current: AppConstants.maxLives, now: clock);
    }

    // Not full but missing an anchor — start a fresh regen cycle.
    if (regenStartedAt == null) {
      return LivesState(
        current: clamped,
        regenStartedAt: clock,
        now: clock,
      );
    }

    final elapsed = clock.difference(regenStartedAt!);
    if (elapsed.isNegative) {
      return LivesState(
        current: clamped,
        regenStartedAt: regenStartedAt,
        now: clock,
      );
    }

    final gained = elapsed.inMilliseconds ~/
        AppConstants.lifeRegenDuration.inMilliseconds;
    if (gained <= 0) {
      return LivesState(
        current: clamped,
        regenStartedAt: regenStartedAt,
        now: clock,
      );
    }

    final nextCurrent =
        (clamped + gained).clamp(0, AppConstants.maxLives).toInt();
    if (nextCurrent >= AppConstants.maxLives) {
      return LivesState(current: AppConstants.maxLives, now: clock);
    }

    final leftoverMs = elapsed.inMilliseconds %
        AppConstants.lifeRegenDuration.inMilliseconds;
    // leftover 0 means the cycle completed exactly — next cycle starts now.
    return LivesState(
      current: nextCurrent,
      regenStartedAt: clock.subtract(Duration(milliseconds: leftoverMs)),
      now: clock,
    );
  }

  LivesState loseOne([DateTime? at]) {
    final clock = at ?? DateTime.now();
    final refreshedState = refreshed(clock);
    if (refreshedState.current <= 0) return refreshedState;

    final next = refreshedState.current - 1;
    final anchor = refreshedState.regenStartedAt ?? clock;
    return LivesState(
      current: next,
      regenStartedAt: next < AppConstants.maxLives ? anchor : null,
      now: clock,
    );
  }

  /// Adds one life (e.g. rewarded ad). Caps at [AppConstants.maxLives].
  LivesState gainOne([DateTime? at]) {
    final clock = at ?? DateTime.now();
    final refreshedState = refreshed(clock);
    if (refreshedState.isFull) return refreshedState;

    final next = refreshedState.current + 1;
    if (next >= AppConstants.maxLives) {
      return LivesState(current: AppConstants.maxLives, now: clock);
    }

    return LivesState(
      current: next,
      regenStartedAt: refreshedState.regenStartedAt ?? clock,
      now: clock,
    );
  }

  LivesState copyWithClock(DateTime clock) {
    return LivesState(
      current: current,
      regenStartedAt: regenStartedAt,
      now: clock,
    );
  }

  factory LivesState.fromJson(Map<String, dynamic> json) {
    final regenRaw = json['regenStartedAt'] as int?;
    return LivesState(
      current: (json['current'] as int?) ?? AppConstants.maxLives,
      regenStartedAt: regenRaw == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(regenRaw),
    ).refreshed();
  }

  Map<String, dynamic> toJson() => {
        'current': current,
        'regenStartedAt': regenStartedAt?.millisecondsSinceEpoch,
      };
}
