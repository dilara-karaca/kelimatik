import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_characters.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../navigation/app_navigation.dart';
import '../providers/catalog_providers.dart';
import '../providers/main_tab_provider.dart';
import '../widgets/app_error_view.dart';
import '../widgets/motion/motion.dart';
import '../widgets/playful_background.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  static const _padTop = 10.0;
  static const _padBottom = 28.0;
  static const _separator = 8.0;
  static const _topRowHeight = 88.0;
  static const _normalRowHeight = 64.0;
  static const _leagueTabIndex = 3;

  final _scrollController = ScrollController();
  int _scrollToken = 0;
  bool _pendingReveal = false;

  @override
  void initState() {
    super.initState();
    // Embedded tab may already be selected on first paint after data loads.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!widget.embedded || ref.read(mainTabIndexProvider) == _leagueTabIndex) {
        _pendingReveal = true;
        _tryRevealCurrentUser();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _rowHeight(LeaderboardEntry entry) =>
      entry.rank <= 3 ? _topRowHeight : _normalRowHeight;

  double _offsetForIndex(List<LeaderboardEntry> entries, int index) {
    var offset = _padTop;
    for (var i = 0; i < index; i++) {
      offset += _rowHeight(entries[i]) + _separator;
    }
    return offset;
  }

  Duration _durationForIndex(int index) {
    // Longer for deeper ranks so the list visibly flies past.
    final ms = (700 + index * 14).clamp(700, 4200);
    return Duration(milliseconds: ms);
  }

  Future<void> _tryRevealCurrentUser() async {
    if (!_pendingReveal) return;
    final async = ref.read(leaderboardProvider);
    final entries = async.asData?.value;
    if (entries == null || entries.isEmpty) return;

    final index = entries.indexWhere((e) => e.isCurrentUser);
    if (index < 0) {
      _pendingReveal = false;
      return;
    }

    // Wait until the list is attached and measurable.
    for (var attempt = 0; attempt < 12; attempt++) {
      if (!mounted) return;
      if (_scrollController.hasClients) break;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    if (!mounted || !_scrollController.hasClients) return;

    _pendingReveal = false;
    final token = ++_scrollToken;

    // Always start from the top so ranks 1 → N feel intentional.
    _scrollController.jumpTo(0);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted || token != _scrollToken || !_scrollController.hasClients) {
      return;
    }

    if (index <= 2) {
      // Already near the top — gentle nudge only.
      return;
    }

    final viewport = _scrollController.position.viewportDimension;
    final raw = _offsetForIndex(entries, index) - viewport * 0.28;
    final target = raw.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      target,
      duration: _durationForIndex(index),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(leaderboardProvider);
    await ref.read(leaderboardProvider.future);
    if (!mounted) return;
    _pendingReveal = true;
    unawaited(_tryRevealCurrentUser());
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(leaderboardProvider);

    if (widget.embedded) {
      ref.listen<int>(mainTabIndexProvider, (previous, next) {
        if (next == _leagueTabIndex && previous != _leagueTabIndex) {
          _pendingReveal = true;
          unawaited(_tryRevealCurrentUser());
        }
      });
    }

    ref.listen(leaderboardProvider, (previous, next) {
      if (next.hasValue && (previous?.hasValue != true || previous?.value != next.value)) {
        if (!widget.embedded ||
            ref.read(mainTabIndexProvider) == _leagueTabIndex) {
          _pendingReveal = true;
          unawaited(_tryRevealCurrentUser());
        }
      }
    });

    final body = SafeArea(
      bottom: !widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.embedded ? 20 : 8, 8, 20, 4),
            child: Row(
              children: [
                if (!widget.embedded)
                  IconButton(
                    onPressed: () => AppNavigation.popRoute(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                Text('Sıralama', style: AppTypography.brand(fontSize: 24)),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => AppErrorView.fromError(
                e,
                onRetry: () {
                  ref.invalidate(leaderboardProvider);
                },
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.accent,
                    onRefresh: _refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            'Henüz sıralama yok.\nOynayarak XP kazan!',
                            textAlign: TextAlign.center,
                            style: AppTypography.title(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _refresh,
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      _padTop,
                      16,
                      _padBottom,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: _separator),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final row = SizedBox(
                        height: _rowHeight(entry),
                        child: entry.rank <= 3
                            ? _TopRankRow(entry: entry)
                            : _NormalRankRow(entry: entry),
                      );
                      return SoftListAppear(
                        index: index,
                        child: row,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: widget.embedded ? body : PlayfulBackground(child: body),
    );
  }
}

/// Ranks 1–3: medal + larger character + username (Duolingo-style).
class _TopRankRow extends StatelessWidget {
  const _TopRankRow({required this.entry});

  final LeaderboardEntry entry;

  ({Color light, Color deep}) get _medal => switch (entry.rank) {
        1 => (light: const Color(0xFFFFC43A), deep: const Color(0xFFE39B00)),
        2 => (light: const Color(0xFFC5CDD8), deep: const Color(0xFF7E8796)),
        _ => (light: const Color(0xFFE09A5E), deep: const Color(0xFFB86B35)),
      };

  @override
  Widget build(BuildContext context) {
    final tones = _medal;
    final highlighted = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.4)
              : tones.light.withValues(alpha: 0.65),
          width: highlighted ? 1.6 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _MedalBadge(
            rank: entry.rank,
            light: tones.light,
            deep: tones.deep,
          ),
          const SizedBox(width: 12),
          _CharacterAvatar(
            characterId: entry.characterId,
            size: entry.rank == 1 ? 54 : 48,
            ringColor: tones.light,
            highlight: highlighted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.primaryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.score} XP',
                  style: AppTypography.title(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDeep,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ranks 4+: rank number + character + username + score.
class _NormalRankRow extends StatelessWidget {
  const _NormalRankRow({required this.entry});

  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final highlighted = entry.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.10)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: AppTypography.body(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CharacterAvatar(
            characterId: entry.characterId,
            size: 44,
            highlight: highlighted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.primaryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.score}',
            style: AppTypography.score(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalBadge extends StatelessWidget {
  const _MedalBadge({
    required this.rank,
    required this.light,
    required this.deep,
  });

  final int rank;
  final Color light;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, deep],
        ),
        boxShadow: [
          BoxShadow(
            color: deep.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: AppTypography.body(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 17,
        ),
      ),
    );
  }
}

class _CharacterAvatar extends StatelessWidget {
  const _CharacterAvatar({
    required this.characterId,
    required this.size,
    this.highlight = false,
    this.ringColor,
  });

  final String? characterId;
  final double size;
  final bool highlight;
  final Color? ringColor;

  @override
  Widget build(BuildContext context) {
    final id = characterId;
    final valid = id != null && AppCharacters.isValidId(id);
    final ring = ringColor ??
        (highlight ? AppColors.accent : const Color(0xFFE2E5EA));

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: ring,
          width: highlight || ringColor != null ? 2.4 : 1.5,
        ),
      ),
      child: ClipOval(
        child: ColoredBox(
          color: const Color(0xFFF3F5F8),
          child: valid
              ? Image.asset(
                  AppCharacters.assetFor(id),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.55),
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => _fallback(),
                )
              : _fallback(),
        ),
      ),
    );
  }

  Widget _fallback() {
    return Icon(
      Icons.person_rounded,
      size: size * 0.45,
      color: AppColors.textSecondary,
    );
  }
}
