import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../theme/spark_theme.dart';
import 'spark_tile.dart';

class GameBoard extends StatelessWidget {
  final GameState state;
  final double size;

  const GameBoard({super.key, required this.state, required this.size});

  @override
  Widget build(BuildContext context) {
    final cellSize = (size - 16) / 4; // 16 = 패딩

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: SparkTheme.boardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SparkTheme.neonBlue.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: SparkTheme.neonBlue.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // 빈 셀 배경
          _buildEmptyCells(cellSize),
          // 실제 타일
          ..._buildTiles(cellSize),
        ],
      ),
    );
  }

  Widget _buildEmptyCells(double cellSize) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
      ),
      itemCount: 16,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: SparkTheme.cellBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: SparkTheme.neonBlue.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTiles(double cellSize) {
    final tiles = <Widget>[];

    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        final value = state.board[r][c];
        if (value == 0) continue;

        // 머지된 타일인지 확인
        final isMerged = state.mergedTiles.any(
          (t) => t.row == r && t.col == c && t.value == value,
        );

        // 새 타일인지 확인
        final isNew = state.tiles.any(
          (t) => t.row == r && t.col == c && t.isNew,
        );

        final top = r * cellSize + 6;
        final left = c * cellSize + 6;

        tiles.add(
          AnimatedPositioned(
            key: ValueKey('tile_${r}_${c}_$value'),
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            top: top,
            left: left,
            width: cellSize,
            height: cellSize,
            child: SparkTile(
              value: value,
              isNew: isNew,
              isMerged: isMerged,
            ),
          ),
        );
      }
    }

    return tiles;
  }
}
