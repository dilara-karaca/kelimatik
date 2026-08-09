import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Light press feedback: scale 1 → [pressedScale] → 1 without changing layout.
///
/// Uses a [Listener] so existing InkWell/GestureDetector taps and ripples keep
/// working. Pass [onTap] only when the child is purely visual.
class AnimatedPressable extends StatefulWidget {
  const AnimatedPressable({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = AppConstants.pressScale,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double pressedScale;
  final HitTestBehavior behavior;

  @override
  State<AnimatedPressable> createState() => _AnimatedPressableState();
}

class _AnimatedPressableState extends State<AnimatedPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = (!widget.enabled || !_pressed) ? 1.0 : widget.pressedScale;

    Widget child = AnimatedScale(
      scale: scale,
      duration: _pressed
          ? AppConstants.pressInDuration
          : AppConstants.pressOutDuration,
      curve: _pressed
          ? AppConstants.pressInCurve
          : AppConstants.pressOutCurve,
      child: AnimatedOpacity(
        opacity: (!widget.enabled)
            ? 1
            : (_pressed ? AppConstants.pressOpacity : 1),
        duration: _pressed
            ? AppConstants.pressInDuration
            : AppConstants.pressOutDuration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );

    child = Listener(
      behavior: widget.behavior,
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: child,
    );

    if (widget.onTap != null) {
      child = GestureDetector(
        behavior: widget.behavior,
        onTap: widget.enabled ? widget.onTap : null,
        child: child,
      );
    }

    return child;
  }
}
