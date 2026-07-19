import 'package:flutter/material.dart';
import '../models/game_models.dart';

class GoBoard extends StatelessWidget {
  final int boardSize;
  final List<List<int>> board;
  final List<MoveRecord> moves;
  final Function(int x, int y)? onTap;
  final double? padding;
  final bool showCoordinates;
  final bool showMoveNumbers;
  final int? lastMoveX;
  final int? lastMoveY;
  final List<String>? hintMoves;
  final Map<String, double>? moveWinRates;
  final int? selectedX;
  final int? selectedY;
  final int? selectedColor;

  const GoBoard({
    super.key,
    required this.boardSize,
    required this.board,
    required this.moves,
    this.onTap,
    this.padding,
    this.showCoordinates = true,
    this.showMoveNumbers = false,
    this.lastMoveX,
    this.lastMoveY,
    this.hintMoves,
    this.moveWinRates,
    this.selectedX,
    this.selectedY,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final coordSize = showCoordinates ? size * 0.045 : 0.0;
        final boardAreaSize = size - coordSize * 2;
        final pad = padding ?? boardAreaSize * 0.025;
        final actualBoardSize = boardAreaSize - pad * 2;
        final cellSize = actualBoardSize / (boardSize - 1);
        final stoneSize = cellSize * 0.95;
        final boardLeft = coordSize + pad;
        final boardTop = coordSize + pad;

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerUp: (event) {
            if (onTap == null) return;
            final dx = event.localPosition.dx - boardLeft;
            final dy = event.localPosition.dy - boardTop;
            final x = (dx / cellSize).round();
            final y = (dy / cellSize).round();
            if (x >= 0 && x < boardSize && y >= 0 && y < boardSize) {
              onTap!(x, y);
            }
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFE8C88B),
                  const Color(0xFFDDB26E),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (showCoordinates) _buildCoordinates(size, coordSize, cellSize, boardLeft, boardTop),
                Positioned(
                  left: boardLeft,
                  top: boardTop,
                  child: SizedBox(
                    width: actualBoardSize,
                    height: actualBoardSize,
                    child: CustomPaint(
                      size: Size(actualBoardSize, actualBoardSize),
                      painter: _BoardPainter(
                        boardSize: boardSize,
                        cellSize: cellSize,
                      ),
                    ),
                  ),
                ),
                ..._buildStones(boardLeft, boardTop, cellSize, stoneSize),
                if (selectedX != null && selectedY != null && selectedColor != null)
                  _buildSelectedStone(boardLeft, boardTop, cellSize, stoneSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoordinates(double size, double coordSize, double cellSize, double boardLeft, double boardTop) {
    final letters = _generateLetters(boardSize);
    return Stack(
      children: [
        for (int i = 0; i < boardSize; i++)
          Positioned(
            left: boardLeft + i * cellSize - coordSize / 2,
            top: 0,
            child: SizedBox(
              width: coordSize,
              height: coordSize,
              child: Center(
                child: Text(
                  letters[i],
                  style: TextStyle(
                    fontSize: coordSize * 0.55,
                    color: const Color(0xFF5D4037),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        for (int i = 0; i < boardSize; i++)
          Positioned(
            left: 0,
            top: boardTop + i * cellSize - coordSize / 2,
            child: SizedBox(
              width: coordSize,
              height: coordSize,
              child: Center(
                child: Text(
                  '${boardSize - i}',
                  style: TextStyle(
                    fontSize: coordSize * 0.55,
                    color: const Color(0xFF5D4037),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<String> _generateLetters(int count) {
    final letters = <String>[];
    for (int i = 0; i < count; i++) {
      int code = i;
      if (code >= 8) code++;
      letters.add(String.fromCharCode(65 + code));
    }
    return letters;
  }

  List<Widget> _buildStones(double boardLeft, double boardTop, double cellSize, double stoneSize) {
    final widgets = <Widget>[];

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        final stone = board[y][x];
        if (stone == 0) continue;

        final left = boardLeft + x * cellSize - stoneSize / 2;
        final top = boardTop + y * cellSize - stoneSize / 2;

        final moveIndex = moves.indexWhere((m) => m.x == x && m.y == y);
        final moveNum = moveIndex >= 0 ? moveIndex + 1 : null;

        final isLastMove = lastMoveX == x && lastMoveY == y;

        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: _buildStone(stone, stoneSize, moveNum, isLastMove),
          ),
        );
      }
    }

    if (hintMoves != null) {
      for (final move in hintMoves!) {
        final coord = _moveToCoord(move);
        if (coord != null) {
          final left = boardLeft + coord.$1 * cellSize - stoneSize / 2;
          final top = boardTop + coord.$2 * cellSize - stoneSize / 2;
          final winRate = moveWinRates?[move];
          widgets.add(
            Positioned(
              left: left,
              top: top,
              child: _buildHintStone(stoneSize, winRate),
            ),
          );
        }
      }
    }

    return widgets;
  }

  Widget _buildStone(int color, double size, int? moveNum, bool isLastMove) {
    final isBlack = color == 1;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.35),
          radius: 0.75,
          colors: isBlack
              ? [
                  const Color(0xFF666666),
                  const Color(0xFF1A1A1A),
                  const Color(0xFF000000),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF5F5F5),
                  const Color(0xFFE0E0E0),
                ],
          stops: isBlack ? [0.0, 0.5, 1.0] : [0.0, 0.7, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(1.5, 2.5),
          ),
        ],
        border: isBlack
            ? null
            : Border.all(color: const Color(0xFFBDBDBD), width: 0.8),
      ),
      child: Center(
        child: isLastMove
            ? Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBlack ? Colors.white : Colors.red,
                  border: Border.all(
                    color: isBlack ? Colors.black : Colors.red.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              )
            : (showMoveNumbers && moveNum != null
                ? Text(
                    '$moveNum',
                    style: TextStyle(
                      fontSize: size * 0.32,
                      fontWeight: FontWeight.bold,
                      color: isBlack ? Colors.white : Colors.black,
                    ),
                  )
                : null),
      ),
    );
  }

  Widget _buildSelectedStone(double boardLeft, double boardTop, double cellSize, double stoneSize) {
    final isBlack = selectedColor == 1;
    final left = boardLeft + selectedX! * cellSize - stoneSize / 2;
    final top = boardTop + selectedY! * cellSize - stoneSize / 2;
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: stoneSize,
        height: stoneSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isBlack ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
          border: Border.all(
            color: isBlack ? Colors.black : Colors.grey[600]!,
            width: 2.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHintStone(double size, double? winRate) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4CAF50).withValues(alpha: 0.55),
        border: Border.all(color: const Color(0xFF2E7D32), width: 2),
      ),
      child: Center(
        child: winRate != null
            ? Text(
                '${winRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  (int, int)? _moveToCoord(String move) {
    if (move.isEmpty || move == 'pass') return null;
    final letter = move[0].toUpperCase();
    int x = letter.codeUnitAt(0) - 65;
    if (letter.codeUnitAt(0) >= 73) x--;
    final yStr = move.substring(1);
    final yInt = int.tryParse(yStr);
    if (yInt == null) return null;
    final y = boardSize - yInt;
    if (x < 0 || x >= boardSize || y < 0 || y >= boardSize) return null;
    return (x, y);
  }
}

class _BoardPainter extends CustomPainter {
  final int boardSize;
  final double cellSize;

  _BoardPainter({required this.boardSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF2D1810)
      ..strokeWidth = 0.8;

    final boldLinePaint = Paint()
      ..color = const Color(0xFF2D1810)
      ..strokeWidth = 1.5;

    for (int i = 0; i < boardSize; i++) {
      final y = i * cellSize;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i == 0 || i == boardSize - 1 ? boldLinePaint : linePaint,
      );
      final x = i * cellSize;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        i == 0 || i == boardSize - 1 ? boldLinePaint : linePaint,
      );
    }

    final starPoints = _getStarPoints(boardSize);
    final starPaint = Paint()..color = const Color(0xFF2D1810);
    for (final point in starPoints) {
      final x = point.$1 * cellSize;
      final y = point.$2 * cellSize;
      canvas.drawCircle(Offset(x, y), cellSize * 0.12, starPaint);
    }
  }

  List<(int, int)> _getStarPoints(int size) {
    if (size == 19) {
      return const [
        (3, 3), (9, 3), (15, 3),
        (3, 9), (9, 9), (15, 9),
        (3, 15), (9, 15), (15, 15),
      ];
    } else if (size == 13) {
      return const [
        (3, 3), (9, 3),
        (6, 6),
        (3, 9), (9, 9),
      ];
    } else if (size == 9) {
      return const [
        (2, 2), (6, 2),
        (4, 4),
        (2, 6), (6, 6),
      ];
    }
    return [];
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
