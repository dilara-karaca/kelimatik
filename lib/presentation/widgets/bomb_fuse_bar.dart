import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_icons.dart';
import '../../core/utils/bomb_fuse.dart';
import 'app_icon.dart';

/// Bomb + horizontal rope fuse. Burns right-to-left over 5 seconds.
class BombFuseBar extends StatefulWidget {
  const BombFuseBar({
    super.key,
    required this.cycle,
    required this.deadline,
    required this.pausedMs,
    required this.exploding,
    required this.frozen,
    required this.onExplosionFinished,
  });

  /// Increments when the fuse resets to full (new question after a correct).
  final int cycle;
  final DateTime? deadline;
  final int pausedMs;
  final bool exploding;
  final bool frozen;
  final VoidCallback onExplosionFinished;

  @override
  State<BombFuseBar> createState() => _BombFuseBarState();
}

class _BombFuseBarState extends State<BombFuseBar>
    with TickerProviderStateMixin {
  late final AnimationController _progress;
  late final AnimationController _explosion;
  var _notifiedExplosion = false;

  static const _bombSize = 52.0;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: AppConstants.bombQuestionDuration,
    );
    _explosion = AnimationController(
      vsync: this,
      duration: AppConstants.bombExplosionDuration,
    );
    _explosion.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_notifiedExplosion) {
        _notifiedExplosion = true;
        widget.onExplosionFinished();
      }
    });
    _syncFromWidget();
  }

  @override
  void didUpdateWidget(BombFuseBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.exploding && !oldWidget.exploding) {
      _progress.value = 1;
      _notifiedExplosion = false;
      _explosion.forward(from: 0);
      return;
    }
    if (widget.cycle != oldWidget.cycle) {
      _explosion.stop();
      _explosion.value = 0;
      _notifiedExplosion = false;
      _progress.duration = AppConstants.bombQuestionDuration;
      if (widget.frozen) {
        _progress.value = 0;
      } else {
        _progress.forward(from: 0);
      }
      return;
    }
    if (widget.frozen && !oldWidget.frozen) {
      _progress.stop();
      return;
    }
    if (widget.deadline == null && oldWidget.deadline != null) {
      _progress.stop();
      return;
    }
    if (widget.deadline != null &&
        oldWidget.deadline == null &&
        !widget.frozen &&
        !widget.exploding) {
      _resumeFromDeadline();
    }
  }

  void _syncFromWidget() {
    if (widget.exploding) {
      _progress.value = 1;
      _explosion.value = 0;
      _notifiedExplosion = false;
      _explosion.forward(from: 0);
      return;
    }
    if (widget.deadline != null) {
      _resumeFromDeadline();
      return;
    }
    if (widget.pausedMs > 0) {
      final total = AppConstants.bombQuestionDuration.inMilliseconds;
      _progress.value = (1.0 - widget.pausedMs / total).clamp(0.0, 1.0);
    } else {
      _progress.value = 0;
    }
  }

  void _resumeFromDeadline() {
    final remaining = widget.deadline!.difference(DateTime.now());
    final total = AppConstants.bombQuestionDuration.inMilliseconds;
    final elapsed = (total - remaining.inMilliseconds).clamp(0, total);
    final t = elapsed / total;
    _progress.duration = AppConstants.bombQuestionDuration;
    if (widget.frozen) {
      _progress.value = t;
      return;
    }
    _progress.forward(from: t);
  }

  @override
  void dispose() {
    _progress.dispose();
    _explosion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 58,
        child: AnimatedBuilder(
          animation: Listenable.merge([_progress, _explosion]),
          builder: (context, _) {
            final remaining = BombFuse.remainingFraction(_progress.value);
            final boom = _explosion.value;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: _bombSize * 0.62,
                  right: 2,
                  top: 0,
                  bottom: 0,
                  child: CustomPaint(
                    painter: _FusePainter(
                      remaining: remaining,
                      flicker: _progress.value,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: _bombSize,
                    height: _bombSize,
                    child: _BombVisual(
                      explosion: boom,
                      exploding: widget.exploding || boom > 0,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BombVisual extends StatelessWidget {
  const _BombVisual({
    required this.explosion,
    required this.exploding,
  });

  final double explosion;
  final bool exploding;

  @override
  Widget build(BuildContext context) {
    final hideBomb = exploding && explosion > 0.28;
    final flash = exploding
        ? (explosion < 0.22
            ? (explosion / 0.22)
            : (1.0 - ((explosion - 0.22) / 0.35)).clamp(0.0, 1.0))
        : 0.0;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (!hideBomb)
          Opacity(
            opacity: exploding ? (1.0 - (explosion / 0.28).clamp(0.0, 1.0)) : 1,
            child: Transform.scale(
              scale: exploding ? 1 + explosion * 0.35 : 1,
              child: const AppIcon(AppIcons.bombMode, size: 48),
            ),
          ),
        if (exploding)
          CustomPaint(
            size: const Size(52, 52),
            painter: _ExplosionPainter(t: explosion, flash: flash),
          ),
      ],
    );
  }
}

class _FusePainter extends CustomPainter {
  _FusePainter({
    required this.remaining,
    required this.flicker,
  });

  final double remaining;
  final double flicker;

  @override
  void paint(Canvas canvas, Size size) {
    final fuseH = 8.0;
    final midY = size.height / 2;
    final maxW = size.width;
    final tipX = (maxW * remaining).clamp(0.0, maxW);
    if (tipX < 1.2) {
      if (remaining > 0) _drawSpark(canvas, Offset(1, midY), flicker);
      return;
    }

    final rect = RRect.fromLTRBR(
      0,
      midY - fuseH / 2,
      tipX,
      midY + fuseH / 2,
      Radius.circular(fuseH / 2),
    );

    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, midY - fuseH / 2),
        Offset(0, midY + fuseH / 2),
        const [
          Color(0xFFE9D4A4),
          Color(0xFFC4A36A),
          Color(0xFF8A5A2B),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRRect(rect, fill);

    // Darken the neck near the bomb so it reads as a real wick, not a bar.
    final neck = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(math.min(18, tipX), 0),
        [
          const Color(0xFF2B2B2B),
          const Color(0xFF2B2B2B).withValues(alpha: 0),
        ],
      );
    canvas.drawRRect(rect, neck);

    canvas.save();
    canvas.clipRRect(rect);
    final braidDark = Paint()
      ..color = const Color(0xFF5C3B18).withValues(alpha: 0.42)
      ..strokeWidth = 1.55
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    final braidLight = Paint()
      ..color = const Color(0xFFF6E7C3).withValues(alpha: 0.38)
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    const step = 5.0;
    for (var x = -fuseH; x < tipX + fuseH; x += step) {
      canvas.drawLine(
        Offset(x, midY + fuseH / 2),
        Offset(x + fuseH, midY - fuseH / 2),
        braidDark,
      );
      canvas.drawLine(
        Offset(x + 2.4, midY + fuseH / 2),
        Offset(x + 2.4 + fuseH, midY - fuseH / 2),
        braidLight,
      );
    }
    // Top highlight — tube volume.
    final highlight = Paint()
      ..color = const Color(0xFFFFF6DC).withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(4, midY - fuseH / 2 + 1.6),
      Offset(tipX - 4, midY - fuseH / 2 + 1.6),
      highlight,
    );
    canvas.restore();

    _drawSpark(canvas, Offset(tipX, midY), flicker);
  }

  void _drawSpark(Canvas canvas, Offset tip, double t) {
    final pulse = 0.82 + 0.18 * math.sin(t * math.pi * 18);
    final radius = 8.5 * pulse;

    final glow = Paint()
      ..shader = ui.Gradient.radial(
        tip,
        radius * 2.1,
        [
          const Color(0xCCFF9A1F),
          const Color(0x66FF6A00),
          const Color(0x00FF6A00),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawCircle(tip, radius * 2.1, glow);

    final core = Paint()
      ..shader = ui.Gradient.radial(
        tip,
        radius,
        const [
          Color(0xFFFFFFF0),
          Color(0xFFFFE066),
          Color(0xFFFF7A00),
        ],
        const [0.0, 0.35, 1.0],
      );
    canvas.drawCircle(tip, radius, core);

    final ray = Paint()
      ..color = const Color(0xFFFFF3C4)
      ..strokeWidth = 1.35
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = t * 12 + i * math.pi / 3;
      final len = 5.5 + 2.2 * math.sin(t * 20 + i);
      canvas.drawLine(
        tip,
        tip + Offset(math.cos(a), math.sin(a)) * len,
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FusePainter oldDelegate) {
    return oldDelegate.remaining != remaining || oldDelegate.flicker != flicker;
  }
}

class _ExplosionPainter extends CustomPainter {
  _ExplosionPainter({required this.t, required this.flash});

  final double t;
  final double flash;

  static const _dirs = <Offset>[
    Offset(1, 0),
    Offset(0.71, 0.71),
    Offset(0, 1),
    Offset(-0.71, 0.71),
    Offset(-1, 0),
    Offset(-0.71, -0.71),
    Offset(0, -1),
    Offset(0.71, -0.71),
    Offset(0.45, 0.89),
    Offset(-0.89, 0.45),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    if (flash > 0) {
      final flashPaint = Paint()
        ..shader = ui.Gradient.radial(
          c,
          36,
          [
            Color.fromARGB((255 * flash).round(), 255, 250, 230),
            Color.fromARGB((180 * flash).round(), 255, 140, 20),
            const Color(0x00FF8A00),
          ],
          const [0.0, 0.4, 1.0],
        );
      canvas.drawCircle(c, 36, flashPaint);
    }

    final travel = 8.0 + t * 28;
    final fade = (1.0 - t).clamp(0.0, 1.0);
    for (var i = 0; i < _dirs.length; i++) {
      final p = c + _dirs[i] * travel * (0.7 + (i % 3) * 0.18);
      final r = (5.5 - t * 3.2) * (i.isEven ? 1.0 : 0.7);
      final color = i.isEven
          ? Color.fromARGB((220 * fade).round(), 255, 120, 20)
          : Color.fromARGB((200 * fade).round(), 255, 210, 70);
      canvas.drawCircle(p, r.clamp(0.8, 6), Paint()..color = color);
    }

    if (t < 0.55) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - t / 0.55)
        ..color = Color.fromARGB(((1 - t / 0.55) * 180).round(), 255, 160, 40);
      canvas.drawCircle(c, 10 + t * 42, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.flash != flash;
  }
}
