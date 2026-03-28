import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';

class ScoreBoard extends StatefulWidget {
  final int score;
  final int bestScore;

  const ScoreBoard({super.key, required this.score, required this.bestScore});

  @override
  State<ScoreBoard> createState() => _ScoreBoardState();
}

class _ScoreBoardState extends State<ScoreBoard> {
  int? _delta;

  @override
  void didUpdateWidget(ScoreBoard old) {
    super.didUpdateWidget(old);
    if (widget.score > old.score) {
      _delta = widget.score - old.score;
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _delta = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ScoreBox(label: 'SCORE', value: widget.score, delta: _delta),
        const SizedBox(width: 12),
        _ScoreBox(label: 'BEST', value: widget.bestScore),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  final String label;
  final int value;
  final int? delta;

  const _ScoreBox({required this.label, required this.value, this.delta});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.06),
            blurRadius: 12,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textMuted,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  value.toString(),
                  key: ValueKey(value),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: theme.accent,
                    shadows: [
                      Shadow(
                        color: theme.accent.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (delta != null)
            Positioned(
              top: 0,
              child: _FloatingDelta(delta: delta!),
            ),
        ],
      ),
    );
  }
}

class _FloatingDelta extends StatefulWidget {
  final int delta;
  const _FloatingDelta({required this.delta});

  @override
  State<_FloatingDelta> createState() => _FloatingDeltaState();
}

class _FloatingDeltaState extends State<_FloatingDelta>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.4, 1.0)),
    );
    _offset = Tween<double>(begin: 0.0, end: -20.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => Transform.translate(
        offset: Offset(0, _offset.value),
        child: Opacity(
          opacity: _opacity.value,
          child: Text(
            '+${widget.delta}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.accentAlt,
              shadows: [
                Shadow(color: theme.accentAlt, blurRadius: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
