import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart';
import '../game/audio_service.dart';
import '../game/score_storage.dart';
import '../theme/app_theme.dart';
import '../theme/theme_notifier.dart';
import 'game_board.dart';
import 'score_board.dart';
import 'overlay_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameState _state = GameState.initial(0);
  final _audio = AudioService();
  bool _muted = false;

  Offset? _panStart;
  Offset _panCurrent = Offset.zero;
  static const double _minSwipeDist = 18.0;

  @override
  void initState() {
    super.initState();
    _audio.init();
    _loadBestScore();
  }

  Future<void> _loadBestScore() async {
    final best = await ScoreStorage.loadBest();
    if (mounted) {
      setState(() => _state = GameState.initial(best));
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _onSwipe(SwipeDirection dir) {
    final prev = _state;
    final next = prev.swipe(dir);
    if (identical(prev, next)) return;

    setState(() => _state = next);
    _triggerHaptic(next);

    if (next.bestScore > prev.bestScore) {
      ScoreStorage.saveBest(next.bestScore);
    }

    if (next.status == GameStatus.won) {
      _audio.play(SoundEvent.win);
    } else if (next.status == GameStatus.over) {
      _audio.play(SoundEvent.over);
    } else if (next.mergedTiles.isNotEmpty) {
      _audio.play(SoundEvent.merge);
    } else {
      _audio.play(SoundEvent.slide);
      Future.delayed(const Duration(milliseconds: 55), () {
        _audio.play(SoundEvent.spawn);
      });
    }
  }

  void _triggerHaptic(GameState next) {
    if (next.status == GameStatus.won) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 110), HapticFeedback.heavyImpact);
      Future.delayed(const Duration(milliseconds: 220), HapticFeedback.heavyImpact);
    } else if (next.status == GameStatus.over) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 160), HapticFeedback.mediumImpact);
    } else if (next.mergedTiles.isNotEmpty) {
      final maxVal = next.mergedTiles.map((t) => t.value).reduce(max);
      if (maxVal >= 1024) {
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 90), HapticFeedback.mediumImpact);
      } else if (maxVal >= 128) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 70), HapticFeedback.selectionClick);
      }
    } else {
      HapticFeedback.selectionClick();
    }
  }

  void _restart() => setState(() => _state = _state.restart(_state.bestScore));
  void _continueGame() => setState(() => _state = _state.continueGame());

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = (screenWidth - 32).clamp(280.0, 480.0);

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            _panStart = d.localPosition;
            _panCurrent = d.localPosition;
          },
          onPanUpdate: (d) => _panCurrent = d.localPosition,
          onPanEnd: (d) {
            final start = _panStart;
            if (start == null) return;
            _panStart = null;

            final delta = _panCurrent - start;
            final vel = d.velocity.pixelsPerSecond;
            final dx = delta.dx.abs() > 6 ? delta.dx : vel.dx / 22;
            final dy = delta.dy.abs() > 6 ? delta.dy : vel.dy / 22;

            if (dx.abs() < _minSwipeDist && dy.abs() < _minSwipeDist) return;
            if (dx.abs() > dy.abs()) {
              _onSwipe(dx > 0 ? SwipeDirection.right : SwipeDirection.left);
            } else {
              _onSwipe(dy > 0 ? SwipeDirection.down : SwipeDirection.up);
            }
          },
          child: Stack(
            children: [
              _buildMainContent(boardSize, theme),
              if (_state.status == GameStatus.won)
                SparkIgnitedOverlay(
                  onContinue: _continueGame,
                  onRestart: _restart,
                ),
              if (_state.status == GameStatus.over)
                GameOverOverlay(score: _state.score, onRestart: _restart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(double boardSize, AppTheme theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(theme),
          const SizedBox(height: 18),
          ScoreBoard(score: _state.score, bestScore: _state.bestScore),
          const SizedBox(height: 18),
          _buildHint(theme),
          const SizedBox(height: 14),
          GameBoard(state: _state, size: boardSize),
        ],
      ),
    );
  }

  Widget _buildHeader(AppTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 로고
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(theme.logoIcon, color: theme.accent, size: 20),
        ),
        const SizedBox(width: 8),
        // 타이틀
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'BitMerge',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: theme.accent,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: theme.accent.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                TextSpan(
                  text: ':2048 ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: theme.logoLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: theme.accentWarm,
                    shadows: [
                      Shadow(
                        color: theme.accentWarm.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 음소거 버튼
        _MuteButton(
          muted: _muted,
          onTap: () => setState(() {
            _muted = !_muted;
            _audio.toggleMute();
          }),
        ),
        const SizedBox(width: 6),
        // 테마 선택 버튼
        _ThemeButton(
          onTap: () => _showThemeSelector(context),
        ),
        const SizedBox(width: 6),
        // NEW GAME 버튼
        _NewGameButton(onTap: _restart),
      ],
    );
  }

  Widget _buildHint(AppTheme theme) {
    return Text(
      theme.hintText,
      style: TextStyle(
        fontSize: 10,
        color: theme.textMuted,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _ThemeSelector(
        onThemeSelected: (theme) {
          ThemeScope.notifierOf(context).setTheme(theme);
          _audio.setProfile(theme.soundProfile);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── 음소거 버튼 ──────────────────────────────────────────────────────────────

class _MuteButton extends StatelessWidget {
  final bool muted;
  final VoidCallback onTap;
  const _MuteButton({required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final color = muted ? theme.textMuted : theme.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: muted
              ? theme.surface
              : theme.accent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          boxShadow: muted
              ? []
              : [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}

// ─── 테마 선택 버튼 ───────────────────────────────────────────────────────────

class _ThemeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ThemeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.accentPop.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.accentPop.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.accentPop.withValues(alpha: 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(Icons.palette_outlined, color: theme.accentPop, size: 18),
      ),
    );
  }
}

// ─── NEW GAME 버튼 ────────────────────────────────────────────────────────────

class _NewGameButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NewGameButton({required this.onTap});

  @override
  State<_NewGameButton> createState() => _NewGameButtonState();
}

class _NewGameButtonState extends State<_NewGameButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.rotate(
          angle: _ctrl.value * 2 * 3.14159,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _pressed
                ? theme.accent.withValues(alpha: 0.25)
                : theme.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withValues(alpha: _pressed ? 0.4 : 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(Icons.refresh_rounded, color: theme.accent, size: 18),
        ),
      ),
    );
  }
}

// ─── 테마 선택 바텀 시트 ──────────────────────────────────────────────────────

class _ThemeSelector extends StatelessWidget {
  final void Function(AppTheme) onThemeSelected;
  const _ThemeSelector({required this.onThemeSelected});

  @override
  Widget build(BuildContext context) {
    final current = ThemeScope.of(context);

    return Container(
      decoration: BoxDecoration(
        color: current.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: current.accent.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 드래그 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: current.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Choose Theme',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: current.textPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...AppTheme.all.map((theme) => _ThemeCard(
                theme: theme,
                isSelected: theme.id == current.id,
                onTap: () => onThemeSelected(theme),
              )),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = ThemeScope.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accent.withValues(alpha: 0.15)
              : current.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.accent
                : current.textMuted.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.accent.withValues(alpha: 0.2),
                    blurRadius: 12,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // 이모지
            Text(
              theme.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 12),
            // 이름 + 설명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.displayName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? theme.accent : current.textPrimary,
                    ),
                  ),
                  Text(
                    theme.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: current.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // 색상 스와치
            Row(
              children: [
                theme.accent,
                theme.accentAlt,
                theme.accentPop,
                theme.accentWarm,
              ]
                  .map((c) => Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: c.withValues(alpha: 0.4),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 10),
            // 선택 표시
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? theme.accent : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? theme.accent
                      : current.textMuted.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
