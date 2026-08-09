import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

/// Fade backdrop + light scale/fade for modal-like overlay panels.
///
/// [child] should be the dialog/card content only (not a full-screen barrier).
class SoftOverlayAppear extends StatefulWidget {
  const SoftOverlayAppear({
    super.key,
    required this.child,
    this.barrierColor = const Color(0x73000000),
    this.onBarrierTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 28),
  });

  final Widget child;
  final Color barrierColor;
  final VoidCallback? onBarrierTap;
  final EdgeInsetsGeometry padding;

  @override
  State<SoftOverlayAppear> createState() => _SoftOverlayAppearState();
}

class _SoftOverlayAppearState extends State<SoftOverlayAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.overlayAppear,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: AppConstants.pageCurve,
      reverseCurve: AppConstants.pageReverseCurve,
    );
    _scale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: AppConstants.pageCurve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, _) {
        final barrierAlpha = widget.barrierColor.a * _fade.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: widget.onBarrierTap,
              behavior: HitTestBehavior.opaque,
              child: ColoredBox(
                color: widget.barrierColor.withValues(alpha: barrierAlpha),
              ),
            ),
            Center(
              child: Padding(
                padding: widget.padding,
                child: FadeTransition(
                  opacity: _fade,
                  child: ScaleTransition(
                    scale: _scale,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
