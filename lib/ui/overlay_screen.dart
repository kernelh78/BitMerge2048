import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/theme_notifier.dart';

class SparkIgnitedOverlay extends StatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onRestart;

  const SparkIgnitedOverlay({
    super.key,
    required this.onContinue,
    required this.onRestart,
  });

  @override
  State<SparkIgnitedOverlay> createState() => _SparkIgnitedOverlayState();
}

class _SparkIgnitedOverlayState extends State<SparkIgnitedOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.82),
      child: Stack(
        children: [
          _ParticleField(colors: theme.particleColors),
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => Transform.scale(
                scale: _scale.value,
                child: child,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _glow,
                    builder: (ctx, child) => Text(
                      theme.winTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: theme.accentWarm,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: theme.accentWarm
                                .withValues(alpha: _glow.value),
                            blurRadius: 30 * _glow.value,
                          ),
                          Shadow(
                            color: theme.accentPop
                                .withValues(alpha: _glow.value * 0.6),
                            blurRadius: 50 * _glow.value,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    theme.winSubtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textMuted,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OverlayButton(
                        label: theme.continueLabel,
                        color: theme.accent,
                        onTap: widget.onContinue,
                      ),
                      const SizedBox(width: 16),
                      _OverlayButton(
                        label: theme.newGameLabel,
                        color: theme.accentPop,
                        onTap: widget.onRestart,
                      ),
                    ],
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

class GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;

  const GameOverOverlay({
    super.key,
    required this.score,
    required this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);

    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              theme.gameOverTitle,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: theme.accentAlt,
                letterSpacing: 3,
                shadows: [
                  Shadow(color: theme.accentAlt, blurRadius: 20),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No moves remaining',
              style: TextStyle(
                fontSize: 14,
                color: theme.textMuted,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Score: $score',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: theme.accentPop,
              ),
            ),
            const SizedBox(height: 32),
            _OverlayButton(
              label: theme.restartLabel,
              color: theme.accent,
              onTap: onRestart,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OverlayButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

// ─── 파티클 이펙트 (테마별 색상) ──────────────────────────────────────────────

class _ParticleField extends StatefulWidget {
  final List<Color> colors;
  const _ParticleField({required this.colors});

  @override
  State<_ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<_ParticleField>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _rebuildParticles();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  void _rebuildParticles() {
    final rng = Random();
    _particles = List.generate(
      40,
      (_) => _Particle(rng, widget.colors),
    );
  }

  @override
  void didUpdateWidget(_ParticleField old) {
    super.didUpdateWidget(old);
    if (old.colors != widget.colors) {
      _rebuildParticles();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) => CustomPaint(
        painter: _ParticlePainter(particles: _particles, t: _ctrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;
  final double phase;

  _Particle(Random rng, List<Color> colors)
      : x = rng.nextDouble(),
        y = rng.nextDouble(),
        speed = 0.1 + rng.nextDouble() * 0.3,
        size = 1 + rng.nextDouble() * 3,
        phase = rng.nextDouble(),
        color = colors[rng.nextInt(colors.length)];
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;

  _ParticlePainter({required this.particles, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final progress = (t * p.speed + p.phase) % 1.0;
      final y = (p.y - progress) % 1.0;
      final opacity = sin(progress * pi).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
