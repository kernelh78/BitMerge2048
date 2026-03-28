import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../theme/theme_notifier.dart';
import 'spark_tile.dart';

class GameBoard extends StatelessWidget {
  final GameState state;
  final double size;

  const GameBoard({super.key, required this.state, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeScope.of(context);
    final cellSize = (size - 16) / 4;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.boardBg,
        borderRadius: BorderRadius.circular(theme.boardRadius),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: theme.isDark ? 0.08 : 0.12),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          _buildEmptyCells(theme),
          ..._buildTiles(cellSize, theme),
        ],
      ),
    );
  }

  Widget _buildEmptyCells(theme) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
      ),
      itemCount: 16,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: theme.cellBg,
          borderRadius: BorderRadius.circular(theme.tileRadius - 2),
          border: Border.all(
            color: theme.accent.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTiles(double cellSize, theme) {
    return state.tiles.map((tile) {
      final top = tile.row * cellSize + 6;
      final left = tile.col * cellSize + 6;

      return AnimatedPositioned(
        key: ValueKey(tile.id),
        duration: theme.slideDuration,
        curve: theme.slideCurve,
        top: top,
        left: left,
        width: cellSize,
        height: cellSize,
        child: SparkTile(
          value: tile.value,
          isNew: tile.isNew,
          isMerged: tile.isMerged,
        ),
      );
    }).toList();
  }
}
