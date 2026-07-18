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
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final coordSize = showCoordinates ? size * 0.05 : 0.0;
        final boardPixelSize = size - coordSize * 2;
        final cellSize = boardPixelSize / (boardSize - 1);
        final stoneSize = cellSize * 0.95;
        final pad = padding ?? cellSize * 0.3;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFDEB887),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (showCoordinates) _buildCoordinates(size, coordSize, cellSize, pad),
              Positioned(
                left: coordSize + pad,
                top: coordSize + pad,
                child: SizedBox(
                  width: boardPixelSize - pad * 2,
                  height: boardPixelSize - pad * 2,
                  child: CustomPaint(
                    size: Size(boardPixelSize - pad * 2, boardPixelSize - pad * 2),
                    painter: _BoardPainter(
                      boardSize: boardSize,
                      cellSize: (boardPixelSize - pad * 2) / (boardSize - 1),
                    ),
                  ),
                ),
              ),
              ..._buildStones(boardPixelSize, cellSize, stoneSize, coordSize, pad),
              if (onTap != null)
                Positioned(
                  left: coordSize + pad,
                  top: coordSize + pad,
                  child: GestureDetector(
                    onTapUp: (details) {
                      final localDx = details.localPosition.dx;
                      final localDy = details.localPosition.dy;
                      final x = (localDx / cellSize).round();
                      final y = (localDy / cellSize).round();
                      if (x >= 0 && x < boardSize && y >= 0 && y < boardSize) {
                        onTap!(x, y);
                      }
                    },
                    child: SizedBox(
                      width: boardPixelSize - pad * 2,
                      height: boardPixelSize - pad * 2,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCoordinates(double size, double coordSize, double cellSize, double pad) {
    final letters = _generateLetters(boardSize);
    return Stack(
      children: [
        for (int i = 0; i < boardSize; i++)
          Positioned(
            left: coordSize + pad + i * cellSize - coordSize / 2,
            top: 0,
            child: SizedBox(
              width: coordSize,
              height: coordSize,
              child: Center(
                child: Text(
                  letters[i],
                  style: TextStyle(
                    fontSize: coordSize * 0.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        for (int i = 0; i < boardSize; i++)
          Positioned(
            left: 0,
            top: coordSize + pad + i * cellSize - coordSize / 2,
            child: SizedBox(
              width: coordSize,
              height: coordSize,
              child: Center(
                child: Text(
                  '${boardSize - i}',
                  style: TextStyle(
                    fontSize: coordSize * 0.5,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
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

  List<Widget> _buildStones(double boardPixelSize, double cellSize, double stoneSize, double coordSize, double pad) {
    final widgets = <Widget>[];

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        final stone = board[y][x];
        if (stone == 0) continue;

        final left = coordSize + pad + x * cellSize - stoneSize / 2;
        final top = coordSize + pad + y * cellSize - stoneSize / 2;

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
          final left = coordSize + pad + coord.$1 * cellSize - stoneSize / 2;
          final top = coordSize + pad + coord.$2 * cellSize - stoneSize / 2;
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
          center: Alignment(-0.3, -0.3),
          radius: 0.8,
          colors: isBlack
              ? [
                  Colors.grey[700]!,
                  Colors.black,
                ]
              : [
                  Colors.white,
                  Colors.grey[300]!,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(1, 2),
          ),
        ],
        border: isBlack
            ? null
            : Border.all(color: Colors.grey[400]!, width: 0.5),
      ),
      child: Center(
        child: isLastMove
            ? Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBlack ? Colors.red : Colors.red,
                ),
              )
            : (showMoveNumbers && moveNum != null
                ? Text(
                    '$moveNum',
                    style: TextStyle(
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.bold,
                      color: isBlack ? Colors.white : Colors.black,
                    ),
                  )
                : null),
      ),
    );
  }

  Widget _buildHintStone(double size, double? winRate) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withValues(alpha: 0.5),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Center(
        child: winRate != null
            ? Text(
                '${winRate.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: size * 0.3,
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
    final y = boardSize - int.tryParse(yStr)!;
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
      ..color = Colors.black
      ..strokeWidth = 0.5;

    final boldLinePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

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
    final starPaint = Paint()..color = Colors.black;
    for (final point in starPoints) {
      final x = point.$1 * cellSize;
      final y = point.$2 * cellSize;
      canvas.drawCircle(Offset(x, y), cellSize * 0.1, starPaint);
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
