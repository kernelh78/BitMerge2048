import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/game_state.dart';
import '../game/audio_service.dart';
import '../game/score_storage.dart';
import '../theme/spark_theme.dart';
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

  // 스와이프: 위치 델타 기반 (속도 기반보다 훨씬 안정적)
  Offset? _panStart;
  Offset _panCurrent = Offset.zero;
  static const double _minSwipeDist = 18.0; // 화면 픽셀

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

    // 변화 없으면 무시
    if (identical(prev, next)) return;

    setState(() => _state = next);
    _triggerHaptic(next);

    if (next.bestScore > prev.bestScore) {
      ScoreStorage.saveBest(next.bestScore);
    }

    // 사운드 (fire-and-forget, UI 블로킹 없음)
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
      // 승리: 강하게 세 번 연타
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 110), HapticFeedback.heavyImpact);
      Future.delayed(const Duration(milliseconds: 220), HapticFeedback.heavyImpact);
    } else if (next.status == GameStatus.over) {
      // 게임 오버: 강하게 → 중간으로 끝맺음
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 160), HapticFeedback.mediumImpact);
    } else if (next.mergedTiles.isNotEmpty) {
      final maxVal = next.mergedTiles.map((t) => t.value).reduce(max);
      if (maxVal >= 1024) {
        // 대합체: 강하게 → 중간 더블펀치
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 90), HapticFeedback.mediumImpact);
      } else if (maxVal >= 128) {
        // 중합체: 묵직한 한 방
        HapticFeedback.mediumImpact();
      } else {
        // 소합체: 가벼운 클릭 + 잔진동
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 70), HapticFeedback.selectionClick);
      }
    } else {
      // 슬라이드만: 선명한 클릭감
      HapticFeedback.selectionClick();
    }
  }

  void _restart() {
    setState(() => _state = _state.restart(_state.bestScore));
  }

  void _continueGame() {
    setState(() => _state = _state.continueGame());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boardSize = (screenWidth - 32).clamp(280.0, 480.0);

    return Scaffold(
      backgroundColor: SparkTheme.background,
      body: SafeArea(
        // GestureDetector가 Stack 전체를 감싸야 버튼 위에서도 스와이프가 누락되지 않음
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            _panStart = d.localPosition;
            _panCurrent = d.localPosition;
          },
          onPanUpdate: (d) {
            _panCurrent = d.localPosition;
          },
          onPanEnd: (d) {
            final start = _panStart;
            if (start == null) return;
            _panStart = null;

            final delta = _panCurrent - start;
            final vel = d.velocity.pixelsPerSecond;

            // 델타가 작을 경우 속도로 보완 (빠른 플릭 누락 방지)
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
              _buildMainContent(boardSize),
              if (_state.status == GameStatus.won)
                SparkIgnitedOverlay(
                  onContinue: _continueGame,
                  onRestart: _restart,
                ),
              if (_state.status == GameStatus.over)
                GameOverOverlay(
                  score: _state.score,
                  onRestart: _restart,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(double boardSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildHeader(),
          const SizedBox(height: 18),
          ScoreBoard(
            score: _state.score,
            bestScore: _state.bestScore,
          ),
          const SizedBox(height: 18),
          _buildHint(),
          const SizedBox(height: 14),
          GameBoard(state: _state, size: boardSize),
        ],
      ),
    );
  }

  /// 헤더: [⚡ 로고 + 타이틀] ........... [↺ NEW GAME]
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 로고
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: SparkTheme.neonBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: SparkTheme.neonBlue.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: SparkTheme.neonBlue.withValues(alpha: 0.3),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.bolt, color: SparkTheme.neonBlue, size: 20),
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
                    color: SparkTheme.neonBlue,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: SparkTheme.neonBlue.withValues(alpha: 0.6),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
                const TextSpan(
                  text: ':2048 ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SparkTheme.textPrimary,
                  ),
                ),
                TextSpan(
                  text: 'Spark',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: SparkTheme.neonGold,
                    shadows: [
                      Shadow(
                        color: SparkTheme.neonGold.withValues(alpha: 0.6),
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
        const SizedBox(width: 8),
        // NEW GAME 버튼
        _NewGameButton(onTap: _restart),
      ],
    );
  }

  Widget _buildHint() {
    return Text(
      'SWIPE TO MERGE  •  REACH 2048',
      style: TextStyle(
        fontSize: 10,
        color: SparkTheme.textMuted,
        letterSpacing: 2.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// 음소거 토글 버튼
class _MuteButton extends StatelessWidget {
  final bool muted;
  final VoidCallback onTap;
  const _MuteButton({required this.muted, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = muted ? SparkTheme.textMuted : SparkTheme.neonBlue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: muted
              ? SparkTheme.surface
              : SparkTheme.neonBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: muted
              ? []
              : [
                  BoxShadow(
                    color: SparkTheme.neonBlue.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Icon(
          muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          color: color,
          size: 20,
        ),
      ),
    );
  }
}

/// 헤더 오른쪽의 NEW GAME 버튼
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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) {
          final spin = _ctrl.value * 2 * 3.14159;
          return Transform.rotate(
            angle: spin,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _pressed
                ? SparkTheme.neonBlue.withValues(alpha: 0.25)
                : SparkTheme.neonBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: SparkTheme.neonBlue.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: SparkTheme.neonBlue
                    .withValues(alpha: _pressed ? 0.4 : 0.15),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: SparkTheme.neonBlue,
            size: 20,
          ),
        ),
      ),
    );
  }
}
