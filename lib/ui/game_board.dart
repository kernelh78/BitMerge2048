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
    return state.tiles.map((tile) {
      final top = tile.row * cellSize + 6;
      final left = tile.col * cellSize + 6;

      return AnimatedPositioned(
        key: ValueKey(tile.id), // ID 기반 키: 같은 타일이면 Flutter가 위치 변화를 감지해 애니메이션
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
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
