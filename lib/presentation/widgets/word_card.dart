import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_typography.dart';

enum WordCardVisualState { idle, correct, wrong, dimmed }

class WordCard extends StatefulWidget {
  const WordCard({
    super.key,
    required this.text,
    required this.onTap,
    required this.enabled,
    required this.visualState,
  });

  final String text;
  final VoidCallback onTap;
  final bool enabled;
  final WordCardVisualState visualState;

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _bounceController;
  late final AnimationController _shakeController;
  late final Animation<double> _bounce;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    // Avoid Curves.easeOutBack here — it overshoots outside [0,1] and
    // TweenSequence asserts (red error flash), especially on rapid taps.
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.07), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 0.98), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.98, end: 1), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );

    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: 0), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant WordCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled && !widget.enabled && _pressed) {
      _setPressed(false);
    }

    if (oldWidget.visualState != widget.visualState) {
      if (widget.visualState == WordCardVisualState.correct) {
        _bounceController.forward(from: 0);
      } else if (widget.visualState == WordCardVisualState.wrong) {
        _shakeController.forward(from: 0);
      } else if (widget.visualState == WordCardVisualState.idle) {
        _bounceController.reset();
        _shakeController.reset();
      }
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    if (!widget.enabled) return;
    widget.onTap();
  }

  Color get _fill {
    switch (widget.visualState) {
      case WordCardVisualState.correct:
        return AppColors.correctSoft;
      case WordCardVisualState.wrong:
        return AppColors.wrongSoft;
      case WordCardVisualState.dimmed:
        return AppColors.surface.withValues(alpha: 0.55);
      case WordCardVisualState.idle:
        return AppColors.surfaceElevated;
    }
  }

  Color get _borderColor {
    switch (widget.visualState) {
      case WordCardVisualState.correct:
        return AppColors.correct.withValues(alpha: 0.35);
      case WordCardVisualState.wrong:
        return AppColors.wrong.withValues(alpha: 0.35);
      case WordCardVisualState.dimmed:
        return AppColors.divider;
      case WordCardVisualState.idle:
        return AppColors.cardIdleBorder;
    }
  }

  Color get _textColor {
    switch (widget.visualState) {
      case WordCardVisualState.correct:
        return AppColors.correct;
      case WordCardVisualState.wrong:
        return AppColors.wrong;
      case WordCardVisualState.dimmed:
        return AppColors.textSecondary.withValues(alpha: 0.55);
      case WordCardVisualState.idle:
        return AppColors.textPrimary;
    }
  }

  IconData? get _badgeIcon {
    switch (widget.visualState) {
      case WordCardVisualState.correct:
        return Icons.check_rounded;
      case WordCardVisualState.wrong:
        return Icons.close_rounded;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pressScale = _pressed ? 0.95 : 1.0;

    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounce, _shake]),
        builder: (context, child) {
          final feedbackScale =
              widget.visualState == WordCardVisualState.correct
                  ? _bounce.value
                  : 1.0;
          return Transform.translate(
            offset: Offset(
              widget.visualState == WordCardVisualState.wrong
                  ? _shake.value
                  : 0,
              0,
            ),
            child: Transform.scale(
              scale: pressScale * feedbackScale,
              child: child,
            ),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _fill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _handleTap,
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              borderRadius: BorderRadius.circular(20),
              splashColor: AppColors.accent.withValues(alpha: 0.08),
              highlightColor: AppColors.accent.withValues(alpha: 0.04),
              child: Stack(
                children: [
                  Positioned(
                    top: 14,
                    right: 16,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _badgeIcon == null ? 0 : 1,
                      child: Icon(
                        _badgeIcon ?? Icons.circle,
                        color: _textColor,
                        size: 22,
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: AppTypography.word(color: _textColor),
                        child: Text(
                          widget.text,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
