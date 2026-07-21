import 'dart:math' as math;
import '../models/game_models.dart';

class GoEngine {
  final int boardSize;
  late List<List<int>> board;
  final List<MoveRecord> moves = [];
  final double komi;
  int currentPlayer = GoStone.black;
  int consecutivePasses = 0;
  String? result;
  String? winner;
  EndGameType? endGameType;
  final List<String> _boardHistory = [];

  GoEngine({this.boardSize = 19, this.komi = 6.5}) {
    board = List.generate(boardSize, (_) => List.filled(boardSize, GoStone.empty));
  }

  String moveToString(int x, int y) {
    final letter = String.fromCharCode(x < 8 ? 65 + x : 65 + x + 1);
    return '$letter${boardSize - y}';
  }

  bool placeStone(int x, int y, int color) {
    if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) return false;
    if (board[y][x] != GoStone.empty) return false;

    final originalBoard = _copyBoard(board);

    board[y][x] = color;

    final opponent = color == GoStone.black ? GoStone.white : GoStone.black;

    final neighbors = _getNeighbors(x, y);
    for (final (nx, ny) in neighbors) {
      if (board[ny][nx] == opponent) {
        final group = _getGroup(nx, ny);
        if (_countLiberties(group) == 0) {
          for (final (gx, gy) in group) {
            board[gy][gx] = GoStone.empty;
          }
        }
      }
    }

    final ownGroup = _getGroup(x, y);
    if (_countLiberties(ownGroup) == 0) {
      board = originalBoard;
      return false;
    }

    final boardKey = _boardToString();
    if (_boardHistory.contains(boardKey)) {
      board = originalBoard;
      return false;
    }

    _boardHistory.add(boardKey);

    moves.add(MoveRecord(
      x: x,
      y: y,
      color: color,
      move: moveToString(x, y),
    ));

    currentPlayer = opponent;
    consecutivePasses = 0;

    return true;
  }

  void pass() {
    consecutivePasses++;
    final opponent = currentPlayer == GoStone.black ? GoStone.white : GoStone.black;
    moves.add(MoveRecord(
      x: -1,
      y: -1,
      color: currentPlayer,
      move: 'pass',
    ));
    currentPlayer = opponent;
  }

  void resignAction(int color) {
    if (result != null) return;
    winner = color == GoStone.black ? 'white' : 'black';
    final loserName = color == GoStone.black ? '黑方' : '白方';
    final winnerName = winner == 'black' ? '黑方' : '白方';
    result = '$loserName认输，$winnerName胜';
    endGameType = EndGameType.resign;
  }

  void undo() {
    if (moves.isEmpty) return;

    final lastMove = moves.removeLast();
    if (lastMove.move != 'pass') {
      consecutivePasses = 0;
    }
    currentPlayer = lastMove.color;

    board = List.generate(boardSize, (_) => List.filled(boardSize, GoStone.empty));
    _boardHistory.clear();

    for (final move in moves) {
      if (move.move == 'pass') {
        consecutivePasses++;
        continue;
      }
      board[move.y][move.x] = move.color;

      final opponent = move.color == GoStone.black ? GoStone.white : GoStone.black;
      final neighbors = _getNeighbors(move.x, move.y);
      for (final (nx, ny) in neighbors) {
        if (board[ny][nx] == opponent) {
          final group = _getGroup(nx, ny);
          if (_countLiberties(group) == 0) {
            for (final (gx, gy) in group) {
              board[gy][gx] = GoStone.empty;
            }
          }
        }
      }

      _boardHistory.add(_boardToString());
    }
  }

  /// 检查指定方是否有合法落子点
  bool hasLegalMoves(int color) {
    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        if (board[y][x] == GoStone.empty && _isValidMove(x, y, color)) {
          return true;
        }
      }
    }
    return false;
  }

  /// 检查是否为合法落子（不修改棋盘）
  bool _isValidMove(int x, int y, int color) {
    final originalBoard = _copyBoard(board);

    board[y][x] = color;
    final opponent = color == GoStone.black ? GoStone.white : GoStone.black;

    bool captured = false;
    for (final (nx, ny) in _getNeighbors(x, y)) {
      if (board[ny][nx] == opponent) {
        final group = _getGroup(nx, ny);
        if (_countLiberties(group) == 0) {
          captured = true;
          for (final (gx, gy) in group) {
            board[gy][gx] = GoStone.empty;
          }
        }
      }
    }

    final ownGroup = _getGroup(x, y);
    final hasLiberty = _countLiberties(ownGroup) > 0;

    board = originalBoard;

    if (!hasLiberty && !captured) return false;

    // 检查打劫
    final testBoard = _copyBoard(board);
    testBoard[y][x] = color;
    for (final (nx, ny) in _getNeighbors(x, y)) {
      if (testBoard[ny][nx] == opponent) {
        final group = _getGroupOnBoard(testBoard, nx, ny);
        if (_countLibertiesOnBoard(testBoard, group) == 0) {
          for (final (gx, gy) in group) {
            testBoard[gy][gx] = GoStone.empty;
          }
        }
      }
    }
    final boardKey = testBoard.map((row) => row.map((c) => c.toString()).join()).join('|');
    if (_boardHistory.contains(boardKey)) return false;

    return true;
  }

  List<(int, int)> _getGroupOnBoard(List<List<int>> testBoard, int x, int y) {
    final color = testBoard[y][x];
    if (color == GoStone.empty) return [];

    final group = <(int, int)>[];
    final visited = <String>{};
    final stack = <(int, int)>[(x, y)];

    while (stack.isNotEmpty) {
      final (cx, cy) = stack.removeLast();
      final key = '$cx,$cy';
      if (visited.contains(key)) continue;
      if (testBoard[cy][cx] != color) continue;

      visited.add(key);
      group.add((cx, cy));

      for (final (nx, ny) in _getNeighbors(cx, cy)) {
        if (!visited.contains('$nx,$ny')) {
          stack.add((nx, ny));
        }
      }
    }

    return group;
  }

  int _countLibertiesOnBoard(List<List<int>> testBoard, List<(int, int)> group) {
    final liberties = <String>{};
    for (final (x, y) in group) {
      for (final (nx, ny) in _getNeighbors(x, y)) {
        if (testBoard[ny][nx] == GoStone.empty) {
          liberties.add('$nx,$ny');
        }
      }
    }
    return liberties.length;
  }

  /// 获取领地分布图
  /// 返回二维数组：0=无主, 1=黑领地, 2=白领地
  List<List<int>> getTerritoryMap() {
    final territoryMap = List.generate(boardSize, (_) => List.filled(boardSize, GoStone.empty));
    final visited = List.generate(boardSize, (_) => List.filled(boardSize, false));

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        if (visited[y][x] || board[y][x] != GoStone.empty) continue;

        final territory = <(int, int)>[];
        final borders = <int>{};
        final stack = <(int, int)>[(x, y)];

        while (stack.isNotEmpty) {
          final (cx, cy) = stack.removeLast();
          if (visited[cy][cx]) continue;
          if (board[cy][cx] != GoStone.empty) {
            borders.add(board[cy][cx]);
            continue;
          }
          visited[cy][cx] = true;
          territory.add((cx, cy));

          for (final (nx, ny) in _getNeighbors(cx, cy)) {
            if (!visited[ny][nx]) {
              stack.add((nx, ny));
            }
          }
        }

        if (borders.length == 1) {
          final owner = borders.first;
          for (final (tx, ty) in territory) {
            territoryMap[ty][tx] = owner;
          }
        }
      }
    }

    return territoryMap;
  }

  /// 确认死子并计算最终分数
  /// deadStones: 用户标记的死子坐标列表
  ScoringResult calculateScore(List<(int, int)> deadStones) {
    // 复制棋盘并移除死子
    final scoringBoard = _copyBoard(board);
    int blackCaptured = 0;
    int whiteCaptured = 0;

    for (final (x, y) in deadStones) {
      if (scoringBoard[y][x] == GoStone.black) {
        scoringBoard[y][x] = GoStone.empty;
        whiteCaptured++;
      } else if (scoringBoard[y][x] == GoStone.white) {
        scoringBoard[y][x] = GoStone.empty;
        blackCaptured++;
      }
    }

    // 计算领地
    final territoryMap = List.generate(boardSize, (_) => List.filled(boardSize, GoStone.empty));
    final visited = List.generate(boardSize, (_) => List.filled(boardSize, false));

    int blackTerritory = 0;
    int whiteTerritory = 0;
    int blackStones = 0;
    int whiteStones = 0;

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        if (scoringBoard[y][x] == GoStone.black) blackStones++;
        if (scoringBoard[y][x] == GoStone.white) whiteStones++;
      }
    }

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        if (visited[y][x] || scoringBoard[y][x] != GoStone.empty) continue;

        final territory = <(int, int)>[];
        final borders = <int>{};
        final stack = <(int, int)>[(x, y)];

        while (stack.isNotEmpty) {
          final (cx, cy) = stack.removeLast();
          if (visited[cy][cx]) continue;
          if (scoringBoard[cy][cx] != GoStone.empty) {
            borders.add(scoringBoard[cy][cx]);
            continue;
          }
          visited[cy][cx] = true;
          territory.add((cx, cy));

          for (final (nx, ny) in _getNeighbors(cx, cy)) {
            if (!visited[ny][nx]) {
              stack.add((nx, ny));
            }
          }
        }

        if (borders.length == 1) {
          if (borders.first == GoStone.black) {
            blackTerritory += territory.length;
            for (final (tx, ty) in territory) {
              territoryMap[ty][tx] = GoStone.black;
            }
          } else if (borders.first == GoStone.white) {
            whiteTerritory += territory.length;
            for (final (tx, ty) in territory) {
              territoryMap[ty][tx] = GoStone.white;
            }
          }
        }
      }
    }

    // 中国规则：子数 + 领地
    final blackScore = (blackStones + blackTerritory).toDouble();
    final whiteScore = (whiteStones + whiteTerritory).toDouble() + komi;

    String resultWinner;
    double margin;
    String resultStr;

    if (blackScore > whiteScore) {
      resultWinner = 'black';
      margin = blackScore - whiteScore;
      resultStr = '黑胜 ${margin.toStringAsFixed(1)} 目';
    } else if (whiteScore > blackScore) {
      resultWinner = 'white';
      margin = whiteScore - blackScore;
      resultStr = '白胜 ${margin.toStringAsFixed(1)} 目';
    } else {
      resultWinner = 'draw';
      margin = 0;
      resultStr = '和棋';
    }

    // 更新引擎状态
    winner = resultWinner;
    result = resultStr;
    endGameType = EndGameType.scoring;

    return ScoringResult(
      blackStones: blackStones,
      whiteStones: whiteStones,
      blackTerritory: blackTerritory,
      whiteTerritory: whiteTerritory,
      komi: komi,
      blackScore: blackScore,
      whiteScore: whiteScore,
      winner: resultWinner,
      margin: margin,
      resultString: resultStr,
    );
  }

  List<(int, int)> _getNeighbors(int x, int y) {
    final result = <(int, int)>[];
    if (x > 0) result.add((x - 1, y));
    if (x < boardSize - 1) result.add((x + 1, y));
    if (y > 0) result.add((x, y - 1));
    if (y < boardSize - 1) result.add((x, y + 1));
    return result;
  }

  List<(int, int)> _getGroup(int x, int y) {
    final color = board[y][x];
    if (color == GoStone.empty) return [];

    final group = <(int, int)>[];
    final visited = <String>{};
    final stack = <(int, int)>[(x, y)];

    while (stack.isNotEmpty) {
      final (cx, cy) = stack.removeLast();
      final key = '$cx,$cy';
      if (visited.contains(key)) continue;
      if (board[cy][cx] != color) continue;

      visited.add(key);
      group.add((cx, cy));

      for (final (nx, ny) in _getNeighbors(cx, cy)) {
        if (!visited.contains('$nx,$ny')) {
          stack.add((nx, ny));
        }
      }
    }

    return group;
  }

  int _countLiberties(List<(int, int)> group) {
    final liberties = <String>{};
    for (final (x, y) in group) {
      for (final (nx, ny) in _getNeighbors(x, y)) {
        if (board[ny][nx] == GoStone.empty) {
          liberties.add('$nx,$ny');
        }
      }
    }
    return liberties.length;
  }

  List<List<int>> _copyBoard(List<List<int>> src) {
    return src.map((row) => List<int>.from(row)).toList();
  }

  String _boardToString() {
    return board.map((row) => row.map((c) => c.toString()).join()).join('|');
  }

  GameState toGameState() {
    return GameState(
      boardSize: boardSize,
      board: _copyBoard(board),
      moves: List.from(moves),
      komi: komi,
      currentPlayer: currentPlayer,
      result: result,
      winner: winner,
      consecutivePasses: consecutivePasses,
      endGameType: endGameType,
    );
  }
}

class SimpleAI {
  final int level;
  final math.Random _rand = math.Random();

  SimpleAI({this.level = 1});

  (int, int)? chooseMove(GoEngine engine, int color) {
    final emptyPoints = <(int, int)>[];
    for (int y = 0; y < engine.boardSize; y++) {
      for (int x = 0; x < engine.boardSize; x++) {
        if (engine.board[y][x] == GoStone.empty) {
          emptyPoints.add((x, y));
        }
      }
    }

    if (emptyPoints.isEmpty) return null;

    if (level == 0) {
      return _randomMove(engine, color, emptyPoints);
    } else if (level == 1) {
      return _beginnerMove(engine, color, emptyPoints);
    } else {
      return _intermediateMove(engine, color, emptyPoints);
    }
  }

  (int, int)? _randomMove(GoEngine engine, int color, List<(int, int)> candidates) {
    final shuffled = List.from(candidates)..shuffle(_rand);
    for (final (x, y) in shuffled) {
      if (_isValidMove(engine, x, y, color)) {
        return (x, y);
      }
    }
    return null;
  }

  (int, int)? _beginnerMove(GoEngine engine, int color, List<(int, int)> candidates) {
    final scored = <_ScoredMove>[];
    for (final (x, y) in candidates) {
      if (!_isValidMove(engine, x, y, color)) continue;
      final score = _evaluateMove(engine, x, y, color);
      scored.add(_ScoredMove(x, y, score));
    }

    if (scored.isEmpty) return null;

    scored.sort((a, b) => b.score.compareTo(a.score));

    final topCount = (scored.length * 0.4).ceil();
    final topMoves = scored.take(topCount).toList();
    topMoves.shuffle(_rand);
    return (topMoves.first.x, topMoves.first.y);
  }

  (int, int)? _intermediateMove(GoEngine engine, int color, List<(int, int)> candidates) {
    final scored = <_ScoredMove>[];
    for (final (x, y) in candidates) {
      if (!_isValidMove(engine, x, y, color)) continue;
      final score = _evaluateMoveAdvanced(engine, x, y, color);
      scored.add(_ScoredMove(x, y, score));
    }

    if (scored.isEmpty) return null;

    scored.sort((a, b) => b.score.compareTo(a.score));
    return (scored.first.x, scored.first.y);
  }

  bool _isValidMove(GoEngine engine, int x, int y, int color) {
    final testBoard = engine._copyBoard(engine.board);
    engine.board[y][x] = color;

    final opponent = color == GoStone.black ? GoStone.white : GoStone.black;
    bool captured = false;
    for (final (nx, ny) in engine._getNeighbors(x, y)) {
      if (engine.board[ny][nx] == opponent) {
        final group = engine._getGroup(nx, ny);
        if (engine._countLiberties(group) == 0) {
          captured = true;
          break;
        }
      }
    }

    final ownGroup = engine._getGroup(x, y);
    if (engine._countLiberties(ownGroup) == 0 && !captured) {
      engine.board = testBoard;
      return false;
    }

    engine.board = testBoard;
    return true;
  }

  int _evaluateMove(GoEngine engine, int x, int y, int color) {
    int score = 0;
    final opponent = color == GoStone.black ? GoStone.white : GoStone.black;

    for (final (nx, ny) in engine._getNeighbors(x, y)) {
      if (engine.board[ny][nx] == opponent) {
        score += 10;
      } else if (engine.board[ny][nx] == color) {
        score += 2;
      }
    }

    final center = engine.boardSize ~/ 2;
    final distToCenter = (x - center).abs() + (y - center).abs();
    score += (engine.boardSize - distToCenter);

    if (x == 0 || x == engine.boardSize - 1 || y == 0 || y == engine.boardSize - 1) {
      score -= 5;
    }

    return score;
  }

  int evaluateMove(GoEngine engine, int x, int y, int color) {
    return _evaluateMoveAdvanced(engine, x, y, color);
  }

  int _evaluateMoveAdvanced(GoEngine engine, int x, int y, int color) {
    int score = 0;
    final opponent = color == GoStone.black ? GoStone.white : GoStone.black;

    int captureValue = 0;
    for (final (nx, ny) in engine._getNeighbors(x, y)) {
      if (engine.board[ny][nx] == opponent) {
        final group = engine._getGroup(nx, ny);
        final liberties = engine._countLiberties(group);
        if (liberties == 1) {
          captureValue += group.length * 50;
        } else if (liberties == 2) {
          captureValue += group.length * 10;
        }
      }
    }
    score += captureValue;

    int ownLiberties = 0;
    for (final (nx, ny) in engine._getNeighbors(x, y)) {
      if (engine.board[ny][nx] == GoStone.empty) {
        ownLiberties++;
      } else if (engine.board[ny][nx] == color) {
        score += 5;
      }
    }
    score += ownLiberties * 3;

    final center = engine.boardSize ~/ 2;
    final distToCenter = (x - center).abs() + (y - center).abs();
    score += (engine.boardSize * 2 - distToCenter);

    if (x == 3 || x == engine.boardSize - 4 || y == 3 || y == engine.boardSize - 4) {
      score += 15;
    }

    return score;
  }
}

class _ScoredMove {
  final int x;
  final int y;
  final int score;

  _ScoredMove(this.x, this.y, this.score);
}
