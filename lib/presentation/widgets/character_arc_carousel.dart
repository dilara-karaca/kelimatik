import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_characters.dart';
import '../../core/constants/app_constants.dart';

/// Three-slot character picker: [prev small] [selected large] [next small].
///
/// Only neighbors of the selected index are laid out; [ClipRect] hides anything
/// outside the viewport so the rest of the roster never appears on screen.
class CharacterArcCarousel extends StatefulWidget {
  const CharacterArcCarousel({
    super.key,
    required this.characterIds,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 280,
  });

  final List<String> characterIds;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double height;

  @override
  State<CharacterArcCarousel> createState() => _CharacterArcCarouselState();
}

class _CharacterArcCarouselState extends State<CharacterArcCarousel>
    with SingleTickerProviderStateMixin {
  static const double _sideScale = 0.68;
  static const double _sideOpacity = 0.42;
  static const double _sideRotation = 0.08;
  /// How far a full step sits from center, as a fraction of width.
  static const double _slotSpread = 0.34;
  /// Extra downward offset for side slots (arc feel).
  static const double _sideDrop = 0.10;
  /// Characters farther than this from [_page] are not built.
  static const double _buildRadius = 1.55;

  late double _page;
  late final AnimationController _snapController;
  Animation<double>? _snapAnimation;
  double _dragDx = 0;

  int get _lastIndex => math.max(0, widget.characterIds.length - 1);

  @override
  void initState() {
    super.initState();
    _page = widget.selectedIndex.toDouble().clamp(0, _lastIndex.toDouble());
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        final anim = _snapAnimation;
        if (anim == null) return;
        setState(() => _page = anim.value);
      });
  }

  @override
  void didUpdateWidget(covariant CharacterArcCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        !_snapController.isAnimating) {
      _page = widget.selectedIndex.toDouble().clamp(0, _lastIndex.toDouble());
    }
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_snapController.isAnimating) {
      _snapController.stop();
    }
    _dragDx += details.delta.dx;
    setState(() {
      // Finger left → next character (page increases).
      _page -= details.delta.dx / 220;
      _page = _page.clamp(0, _lastIndex.toDouble());
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final from = widget.selectedIndex.toDouble();
    var target = from;

    // One step only: velocity or drag distance decides direction.
    if (velocity.abs() > 280) {
      target = from + (velocity < 0 ? 1 : -1);
    } else if (_dragDx.abs() > 48) {
      target = from + (_dragDx < 0 ? 1 : -1);
    } else {
      target = _page.roundToDouble();
      // Still limit to a single step from the committed selection.
      if ((target - from).abs() > 1) {
        target = from + (target > from ? 1 : -1);
      }
    }

    target = target.clamp(0, _lastIndex.toDouble());
    _dragDx = 0;
    _animateTo(target);
  }

  void _animateTo(double target) {
    target = target.clamp(0, _lastIndex.toDouble());
    _snapAnimation = Tween<double>(begin: _page, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: AppConstants.pageCurve),
    );
    _snapController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      final index = target.round().clamp(0, _lastIndex);
      setState(() => _page = index.toDouble());
      if (index != widget.selectedIndex) {
        widget.onSelected(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.characterIds;
    if (ids.isEmpty) {
      return SizedBox(height: widget.height);
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final centerX = w / 2;
              final centerY = h * 0.46;
              final baseSize = math.min(w * 0.52, h * 0.88);
              final slotX = w * _slotSpread;

              final items = <_SlotItem>[];
              for (var i = 0; i < ids.length; i++) {
                final t = i - _page;
                if (t.abs() > _buildRadius) continue;

                final absT = t.abs().clamp(0.0, 1.0);
                final scale = 1.0 - (1.0 - _sideScale) * absT;
                final opacity = 1.0 - (1.0 - _sideOpacity) * absT;
                // Soft falloff past the side slots so exit/enter stay clipped.
                final edgeFade = t.abs() <= 1
                    ? 1.0
                    : (1.0 - (t.abs() - 1) / (_buildRadius - 1)).clamp(0.0, 1.0);
                final visualScale =
                    scale * AppCharacters.displayScaleFor(ids[i]);
                // Only nudge the placeholder when it's the focus; side slots
                // already get _sideDrop and looked too low with a fixed offset.
                final yOffset = h *
                    AppCharacters.displayYOffsetFor(ids[i]) *
                    (1.0 - absT);

                items.add(
                  _SlotItem(
                    index: i,
                    id: ids[i],
                    x: centerX + t * slotX,
                    y: centerY + absT * h * _sideDrop + yOffset,
                    scale: visualScale,
                    opacity: opacity * edgeFade,
                    rotation: t.clamp(-1.0, 1.0) * _sideRotation,
                    z: (100 - (t.abs() * 40)).round(),
                  ),
                );
              }
              items.sort((a, b) => a.z.compareTo(b.z));

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final item in items)
                    Positioned(
                      left: item.x - (baseSize * item.scale) / 2,
                      top: item.y - (baseSize * item.scale) / 2,
                      width: baseSize * item.scale,
                      height: baseSize * item.scale,
                      child: IgnorePointer(
                        ignoring: item.index !=
                            _page.round().clamp(0, _lastIndex),
                        child: GestureDetector(
                          onTap: () {
                            final delta = item.index - widget.selectedIndex;
                            if (delta == 0) return;
                            // Tap side slot → advance exactly one step that way.
                            final step = delta > 0 ? 1 : -1;
                            _animateTo(
                              (widget.selectedIndex + step)
                                  .toDouble()
                                  .clamp(0, _lastIndex.toDouble()),
                            );
                          },
                          child: Opacity(
                            opacity: item.opacity,
                            child: Transform.rotate(
                              angle: item.rotation,
                              child: Image.asset(
                                AppCharacters.assetFor(item.id),
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                gaplessPlayback: true,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SlotItem {
  const _SlotItem({
    required this.index,
    required this.id,
    required this.x,
    required this.y,
    required this.scale,
    required this.opacity,
    required this.rotation,
    required this.z,
  });

  final int index;
  final String id;
  final double x;
  final double y;
  final double scale;
  final double opacity;
  final double rotation;
  final int z;
}
