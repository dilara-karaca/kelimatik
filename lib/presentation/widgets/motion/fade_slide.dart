import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// One-shot fade + subtle slide-in. Plays once when first inserted (or when
/// [play] flips to true). Safe for tab shells — pass [play] only on first open.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppConstants.entranceDuration,
    this.offset = const Offset(0, 0.04),
    this.curve = AppConstants.pageCurve,
    this.play = true,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;
  final bool play;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.play) {
      _schedulePlay();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant FadeSlideIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_started && widget.play && !oldWidget.play) {
      _schedulePlay();
    }
  }

  void _schedulePlay() {
    _started = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Fade + slight vertical slide for [AnimatedSwitcher] / page content swaps.
Widget softFadeSlideTransition(Widget child, Animation<double> animation) {
  final curved = CurvedAnimation(
    parent: animation,
    curve: AppConstants.pageCurve,
    reverseCurve: AppConstants.pageReverseCurve,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.03),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}
