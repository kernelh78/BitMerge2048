import 'dart:math';

enum SwipeDirection { up, down, left, right }

enum GameStatus { playing, won, over }

class TileData {
  final int value;
  final int row;
  final int col;
  final String id;
  final bool isNew;
  final bool isMerged;

  TileData({
    required this.value,
    required this.row,
    required this.col,
    required this.isNew,
    this.isMerged = false,
  }) : id = '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';

  // ID를 보존하는 내부 생성자 (슬라이드 이동 시 사용)
  TileData._withId({
    required this.id,
    required this.value,
    required this.row,
    required this.col,
    this.isNew = false,
    this.isMerged = false,
  });

  TileData copyWith({
    int? value,
    int? row,
    int? col,
    bool? isNew,
    bool? isMerged,
  }) {
    return TileData._withId(
      id: id, // ID 보존
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      isNew: isNew ?? false,
      isMerged: isMerged ?? this.isMerged,
    );
  }
}

class GameState {
  final List<List<int>> board;
  final int score;
  final int bestScore;
  final GameStatus status;
  final List<TileData> tiles;
  final List<TileData> mergedTiles;

  const GameState({
    required this.board,
    required this.score,
    required this.bestScore,
    required this.status,
    required this.tiles,
    required this.mergedTiles,
  });

  static GameState initial(int bestScore) {
    final board = List.generate(4, (_) => List.filled(4, 0));
    final state = GameState(
      board: board,
      score: 0,
      bestScore: bestScore,
      status: GameStatus.playing,
      tiles: [],
      mergedTiles: [],
    );
    return state._spawnTile()._spawnTile();
  }

  GameState _spawnTile() {
    final empty = <(int, int)>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r][c] == 0) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return this;

    final rng = Random();
    final (r, c) = empty[rng.nextInt(empty.length)];
    final value = rng.nextDouble() < 0.9 ? 2 : 4;

    final newBoard = _copyBoard();
    newBoard[r][c] = value;

    final newTile = TileData(value: value, row: r, col: c, isNew: true);
    final newTiles = [...tiles, newTile];

    return GameState(
      board: newBoard,
      score: score,
      bestScore: bestScore,
      status: status,
      tiles: newTiles,
      mergedTiles: mergedTiles,
    );
  }

  List<List<int>> _copyBoard() {
    return board.map((row) => List<int>.from(row)).toList();
  }

  GameState swipe(SwipeDirection direction) {
    if (status != GameStatus.playing) return this;

    // 현재 타일의 위치→ID 맵 (슬라이드 시 ID 보존용)
    final Map<(int, int), String> posToId = {
      for (final t in tiles) (t.row, t.col): t.id,
    };

    final newBoard = _copyBoard();
    int addedScore = 0;
    final newMergedTiles = <TileData>[];
    final Map<(int, int), String> slideIds = {}; // 새 위치 → 기존 ID

    switch (direction) {
      case SwipeDirection.left:
        for (int r = 0; r < 4; r++) {
          final result = _mergeLine(newBoard[r]);
          newBoard[r] = result.merged;
          addedScore += result.score;
          for (final tile in result.mergedPositions) {
            newMergedTiles.add(TileData(
              value: tile.$1, row: r, col: tile.$2, isNew: false, isMerged: true,
            ));
          }
          for (final (origIdx, newIdx) in result.moves) {
            final id = posToId[(r, origIdx)];
            if (id != null) slideIds[(r, newIdx)] = id;
          }
        }
      case SwipeDirection.right:
        for (int r = 0; r < 4; r++) {
          final reversed = newBoard[r].reversed.toList();
          final result = _mergeLine(reversed);
          newBoard[r] = result.merged.reversed.toList();
          addedScore += result.score;
          for (final tile in result.mergedPositions) {
            newMergedTiles.add(TileData(
              value: tile.$1, row: r, col: 3 - tile.$2, isNew: false, isMerged: true,
            ));
          }
          for (final (origIdx, newIdx) in result.moves) {
            final id = posToId[(r, 3 - origIdx)];
            if (id != null) slideIds[(r, 3 - newIdx)] = id;
          }
        }
      case SwipeDirection.up:
        for (int c = 0; c < 4; c++) {
          final col = [for (int r = 0; r < 4; r++) newBoard[r][c]];
          final result = _mergeLine(col);
          for (int r = 0; r < 4; r++) {
            newBoard[r][c] = result.merged[r];
          }
          addedScore += result.score;
          for (final tile in result.mergedPositions) {
            newMergedTiles.add(TileData(
              value: tile.$1, row: tile.$2, col: c, isNew: false, isMerged: true,
            ));
          }
          for (final (origIdx, newIdx) in result.moves) {
            final id = posToId[(origIdx, c)];
            if (id != null) slideIds[(newIdx, c)] = id;
          }
        }
      case SwipeDirection.down:
        for (int c = 0; c < 4; c++) {
          final col = [for (int r = 3; r >= 0; r--) newBoard[r][c]];
          final result = _mergeLine(col);
          for (int r = 3; r >= 0; r--) {
            newBoard[r][c] = result.merged[3 - r];
          }
          addedScore += result.score;
          for (final tile in result.mergedPositions) {
            newMergedTiles.add(TileData(
              value: tile.$1, row: 3 - tile.$2, col: c, isNew: false, isMerged: true,
            ));
          }
          for (final (origIdx, newIdx) in result.moves) {
            final id = posToId[(3 - origIdx, c)];
            if (id != null) slideIds[(3 - newIdx, c)] = id;
          }
        }
    }

    // 변화 없으면 무시
    bool changed = false;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (newBoard[r][c] != board[r][c]) {
          changed = true;
          break;
        }
      }
      if (changed) break;
    }
    if (!changed) return this;

    final newScore = score + addedScore;
    final newBest = max(bestScore, newScore);

    // ID를 보존하며 타일 리스트 재구성
    final newTiles = <TileData>[];
    newTiles.addAll(newMergedTiles); // 머지된 타일 (새 ID)

    final mergedPositionSet = {for (final t in newMergedTiles) (t.row, t.col)};
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (newBoard[r][c] != 0 && !mergedPositionSet.contains((r, c))) {
          final preservedId = slideIds[(r, c)];
          if (preservedId != null) {
            newTiles.add(TileData._withId(
              id: preservedId,
              value: newBoard[r][c],
              row: r,
              col: c,
            ));
          } else {
            newTiles.add(TileData(value: newBoard[r][c], row: r, col: c, isNew: false));
          }
        }
      }
    }

    var next = GameState(
      board: newBoard,
      score: newScore,
      bestScore: newBest,
      status: GameStatus.playing,
      tiles: newTiles,
      mergedTiles: newMergedTiles,
    );

    // 2048 달성 체크
    bool won = false;
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (newBoard[r][c] >= 2048) won = true;
      }
    }

    if (won) {
      return GameState(
        board: next.board,
        score: next.score,
        bestScore: next.bestScore,
        status: GameStatus.won,
        tiles: next.tiles,
        mergedTiles: next.mergedTiles,
      );
    }

    next = next._spawnTile();

    // 게임오버 체크
    if (!next._canMove()) {
      return GameState(
        board: next.board,
        score: next.score,
        bestScore: next.bestScore,
        status: GameStatus.over,
        tiles: next.tiles,
        mergedTiles: next.mergedTiles,
      );
    }

    return next;
  }

  _MergeResult _mergeLine(List<int> line) {
    // 원래 인덱스 추적
    final indexedPacked = <(int, int)>[]; // (origIdx, value)
    for (int i = 0; i < line.length; i++) {
      if (line[i] != 0) indexedPacked.add((i, line[i]));
    }

    final result = List.filled(4, 0);
    int score = 0;
    int pos = 0;
    final mergedPositions = <(int, int)>[];
    final moves = <(int, int)>[]; // (origIdx, newIdx) — 머지되지 않고 이동한 타일
    int i = 0;

    while (i < indexedPacked.length) {
      if (i + 1 < indexedPacked.length &&
          indexedPacked[i].$2 == indexedPacked[i + 1].$2) {
        final merged = indexedPacked[i].$2 * 2;
        result[pos] = merged;
        score += merged;
        mergedPositions.add((merged, pos));
        pos++;
        i += 2;
      } else {
        result[pos] = indexedPacked[i].$2;
        moves.add((indexedPacked[i].$1, pos));
        pos++;
        i++;
      }
    }

    return _MergeResult(
      merged: result,
      score: score,
      mergedPositions: mergedPositions,
      moves: moves,
    );
  }

  bool _canMove() {
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 4; c++) {
        if (board[r][c] == 0) return true;
        if (r < 3 && board[r][c] == board[r + 1][c]) return true;
        if (c < 3 && board[r][c] == board[r][c + 1]) return true;
      }
    }
    return false;
  }

  GameState restart(int savedBest) {
    return GameState.initial(max(bestScore, savedBest));
  }

  GameState continueGame() {
    return GameState(
      board: board,
      score: score,
      bestScore: bestScore,
      status: GameStatus.playing,
      tiles: tiles,
      mergedTiles: mergedTiles,
    );
  }
}

class _MergeResult {
  final List<int> merged;
  final int score;
  final List<(int, int)> mergedPositions;
  final List<(int, int)> moves; // (origIdx, newIdx) for non-merged tiles

  _MergeResult({
    required this.merged,
    required this.score,
    required this.mergedPositions,
    required this.moves,
  });
}
