import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/theme/app_typography.dart';
import 'app_icon.dart';

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
    // Stay inside feedback windows (correct 500ms / wrong 1000ms).
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    // Avoid Curves.easeOutBack — overshoot outside [0,1] breaks TweenSequence.
    _bounce = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.05), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 0.99), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.99, end: 1), weight: 25),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOutCubic),
    );

    // Subtle shake — enough feedback without shaking the screen.
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4, end: 4), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 2), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 1),
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

  String? get _badgeAsset {
    switch (widget.visualState) {
      case WordCardVisualState.correct:
        return AppIcons.correct;
      case WordCardVisualState.wrong:
        return AppIcons.wrong;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
              scale: feedbackScale,
              child: child,
            ),
          );
        },
        child: AnimatedScale(
          scale: _pressed ? AppConstants.pressScale : 1,
          duration: _pressed
              ? AppConstants.pressInDuration
              : AppConstants.pressOutDuration,
          curve: _pressed
              ? AppConstants.pressInCurve
              : AppConstants.pressOutCurve,
          child: AnimatedOpacity(
            opacity: _pressed ? AppConstants.pressOpacity : 1,
            duration: _pressed
                ? AppConstants.pressInDuration
                : AppConstants.pressOutDuration,
            child: AnimatedContainer(
              duration: AppConstants.cardSwap,
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
                          duration: const Duration(milliseconds: 160),
                          opacity: _badgeAsset == null ? 0 : 1,
                          child: AnimatedScale(
                            scale: _badgeAsset == null ? 0.6 : 1,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: AppIcon(
                              _badgeAsset ?? AppIcons.correct,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: AnimatedDefaultTextStyle(
                            duration: AppConstants.cardSwap,
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
        ),
      ),
    );
  }
}
