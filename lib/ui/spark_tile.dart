import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';

class SparkTile extends StatefulWidget {
  final int value;
  final bool isNew;
  final bool isMerged;

  const SparkTile({
    super.key,
    required this.value,
    this.isNew = false,
    this.isMerged = false,
  });

  @override
  State<SparkTile> createState() => _SparkTileState();
}

class _SparkTileState extends State<SparkTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _animSetup = false;

  @override
  void initState() {
    super.initState();
    // 컨트롤러는 여기서, 실제 애니메이션 파라미터는 didChangeDependencies에서
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = ConstantTween<double>(1.0).animate(_controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animSetup) {
      _animSetup = true;
      final theme = ThemeScope.of(context);
      _setupInitialAnim(theme);
      _controller.forward();
    }
  }

  void _setupInitialAnim(AppTheme theme) {
    if (widget.isNew) {
      _controller.duration = theme.spawnDuration;
      _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: theme.spawnCurve),
      );
    } else if (widget.isMerged) {
      _controller.duration = theme.mergeDuration;
      _scaleAnim = _buildMergeAnim(
          theme.mergeScalePeak, theme.mergeScaleDip, theme.mergeScaleBounce);
    } else {
      _controller.duration = const Duration(milliseconds: 1);
      _scaleAnim = ConstantTween<double>(1.0).animate(_controller);
    }
  }

  Animation<double> _buildMergeAnim(double peak, double dip, double bounce) {
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: peak), weight: 22),
      TweenSequenceItem(tween: Tween(begin: peak, end: dip), weight: 28),
      TweenSequenceItem(tween: Tween(begin: dip, end: bounce), weight: 28),
      TweenSequenceItem(tween: Tween(begin: bounce, end: 1.0), weight: 22),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(SparkTile old) {
    super.didUpdateWidget(old);
    if (widget.isMerged && !old.isMerged) {
      final theme = ThemeScope.of(context);
      _controller.duration = theme.mergeDuration;
      _scaleAnim = _buildMergeAnim(
          theme.mergeScalePeak, theme.mergeScaleDip, theme.mergeScaleBounce);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: _buildTile(theme),
    );
  }

  Widget _buildTile(AppTheme theme) {
    final glowColor = theme.tileGlow(widget.value);
    final borderColor = theme.tileBorder(widget.value);
    final gradient = theme.tileGradient(widget.value);

    return Container(
      margin: EdgeInsets.all(theme.tileMargin),
      decoration: BoxDecoration(
        color: gradient == null ? theme.tileColor(widget.value) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(theme.tileRadius),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: widget.value >= 512 ? 16 : 8,
            spreadRadius: widget.value >= 512 ? 2 : 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildOverlay(theme),
          Center(
            child: Text(
              widget.value.toString(),
              style: TextStyle(
                fontSize: theme.tileFontSize(widget.value),
                fontWeight: FontWeight.w800,
                color: theme.tileTextColor(widget.value),
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: theme.tileGlow(widget.value),
                    blurRadius: widget.value >= 64 ? 12 : 6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(AppTheme theme) {
    final color =
        theme.tileBorder(widget.value).withValues(alpha: theme.tileOverlayAlpha);
    switch (theme.tileOverlayStyle) {
      case TileOverlayStyle.circuit:
        return Positioned.fill(
          child: CustomPaint(
            painter: _CircuitPainter(color: color, seed: widget.value),
          ),
        );
      case TileOverlayStyle.floral:
        return Positioned.fill(
          child: CustomPaint(
            painter: _FloralPainter(color: color, seed: widget.value),
          ),
        );
      case TileOverlayStyle.dots:
        return Positioned.fill(
          child: CustomPaint(
            painter: _DotsPainter(color: color, seed: widget.value),
          ),
        );
    }
  }
}

// ─── Neon Circuit: 회로기판 패턴 ─────────────────────────────────────────────

class _CircuitPainter extends CustomPainter {
  final Color color;
  final int seed;

  _CircuitPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    const r = 2.0;

    canvas.drawCircle(Offset(r + 4, r + 4), r, dotPaint);
    canvas.drawCircle(Offset(w - r - 4, r + 4), r, dotPaint);
    canvas.drawCircle(Offset(r + 4, h - r - 4), r, dotPaint);
    canvas.drawCircle(Offset(w - r - 4, h - r - 4), r, dotPaint);

    if (seed >= 8) {
      canvas.drawLine(Offset(r + 4, r + 4), Offset(w * 0.35, r + 4), paint);
      canvas.drawLine(
          Offset(w - r - 4, r + 4), Offset(w * 0.65, r + 4), paint);
      canvas.drawLine(
          Offset(r + 4, h - r - 4), Offset(w * 0.35, h - r - 4), paint);
    }
    if (seed >= 32) {
      canvas.drawLine(Offset(r + 4, r + 4), Offset(r + 4, h * 0.3), paint);
      canvas.drawLine(
          Offset(w - r - 4, r + 4), Offset(w - r - 4, h * 0.3), paint);
    }
    if (seed >= 128) {
      canvas.drawLine(
          Offset(w * 0.5, h * 0.1), Offset(w * 0.5, h * 0.35), paint);
      canvas.drawLine(
          Offset(w * 0.1, h * 0.5), Offset(w * 0.35, h * 0.5), paint);
      canvas.drawLine(
          Offset(w * 0.65, h * 0.5), Offset(w * 0.9, h * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.seed != seed;
}

// ─── Cherry Bloom: 꽃잎 패턴 ─────────────────────────────────────────────────

class _FloralPainter extends CustomPainter {
  final Color color;
  final int seed;

  _FloralPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    const r = 2.5;

    void drawPetal(Offset center) {
      canvas.drawCircle(center, r, paint);
      if (seed >= 8) {
        canvas.drawCircle(center + const Offset(5, 0), r * 0.7, paint);
        canvas.drawCircle(center + const Offset(0, 5), r * 0.7, paint);
      }
    }

    drawPetal(Offset(r + 5, r + 5));
    drawPetal(Offset(w - r - 5, r + 5));
    drawPetal(Offset(r + 5, h - r - 5));
    drawPetal(Offset(w - r - 5, h - r - 5));

    if (seed >= 64) {
      final strokePaint = Paint()
        ..color = color
        ..strokeWidth = 0.9
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(Offset(w / 2, h / 2), w * 0.18, strokePaint);
    }
    if (seed >= 256) {
      for (int i = 0; i < 6; i++) {
        final angle = i * pi / 3;
        final cx = w / 2 + cos(angle) * w * 0.22;
        final cy = h / 2 + sin(angle) * h * 0.22;
        canvas.drawCircle(Offset(cx, cy), r * 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FloralPainter old) => old.seed != seed;
}

// ─── Pastel Dream: 소프트 도트 패턴 ──────────────────────────────────────────

class _DotsPainter extends CustomPainter {
  final Color color;
  final int seed;

  _DotsPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final rng = Random(seed);

    final count = seed >= 512
        ? 8
        : seed >= 64
            ? 5
            : seed >= 8
                ? 3
                : 2;

    for (int i = 0; i < count; i++) {
      final x = 6 + rng.nextDouble() * (w - 12);
      final y = 6 + rng.nextDouble() * (h - 12);
      final r = 1.5 + rng.nextDouble() * 2.0;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.seed != seed;
}
