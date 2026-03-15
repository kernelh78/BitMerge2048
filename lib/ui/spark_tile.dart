import 'package:flutter/material.dart';
import '../theme/spark_theme.dart';

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

  @override
  void initState() {
    super.initState();

    if (widget.isNew) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 220),
      );
      _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
      );
    } else if (widget.isMerged) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
      // 쾌감 있는 팝: 크게 튀었다가 살짝 눌렸다 안정
      _scaleAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.04), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    } else {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 180),
      );
      _scaleAnim = ConstantTween<double>(1.0).animate(_controller);
    }

    _controller.forward();
  }

  @override
  void didUpdateWidget(SparkTile old) {
    super.didUpdateWidget(old);
    if (widget.isMerged && !old.isMerged) {
      _controller.duration = const Duration(milliseconds: 300);
      _scaleAnim = TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.88), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.04), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: _buildTile(),
    );
  }

  Widget _buildTile() {
    final glowColor = SparkTheme.tileGlow(widget.value);
    final borderColor = SparkTheme.tileBorder(widget.value);

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SparkTheme.tileColor(widget.value),
        borderRadius: BorderRadius.circular(6),
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
          _CircuitOverlay(value: widget.value),
          Center(
            child: Text(
              widget.value.toString(),
              style: TextStyle(
                fontSize: SparkTheme.tileFontSize(widget.value),
                fontWeight: FontWeight.w800,
                color: SparkTheme.tileTextColor(widget.value),
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: SparkTheme.tileGlow(widget.value),
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
}

/// 회로기판 패턴 오버레이
class _CircuitOverlay extends StatelessWidget {
  final int value;

  const _CircuitOverlay({required this.value});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _CircuitPainter(
          color: SparkTheme.tileBorder(value).withValues(alpha: 0.15),
          seed: value,
        ),
      ),
    );
  }
}

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

    // 회로 라인 패턴 (seed 기반으로 타일마다 다른 느낌)
    final w = size.width;
    final h = size.height;

    // 코너 도트
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    const r = 2.0;
    canvas.drawCircle(Offset(r + 4, r + 4), r, dotPaint);
    canvas.drawCircle(Offset(w - r - 4, r + 4), r, dotPaint);
    canvas.drawCircle(Offset(r + 4, h - r - 4), r, dotPaint);
    canvas.drawCircle(Offset(w - r - 4, h - r - 4), r, dotPaint);

    // 수평/수직 라인
    if (seed >= 8) {
      canvas.drawLine(Offset(r + 4, r + 4), Offset(w * 0.35, r + 4), paint);
      canvas.drawLine(
          Offset(w - r - 4, r + 4), Offset(w * 0.65, r + 4), paint);
      canvas.drawLine(Offset(r + 4, h - r - 4),
          Offset(w * 0.35, h - r - 4), paint);
    }

    if (seed >= 32) {
      canvas.drawLine(Offset(r + 4, r + 4), Offset(r + 4, h * 0.3), paint);
      canvas.drawLine(
          Offset(w - r - 4, r + 4), Offset(w - r - 4, h * 0.3), paint);
    }

    if (seed >= 128) {
      // 중앙 십자 패턴
      canvas.drawLine(Offset(w * 0.5, h * 0.1), Offset(w * 0.5, h * 0.35), paint);
      canvas.drawLine(Offset(w * 0.1, h * 0.5), Offset(w * 0.35, h * 0.5), paint);
      canvas.drawLine(Offset(w * 0.65, h * 0.5), Offset(w * 0.9, h * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.seed != seed;
}
