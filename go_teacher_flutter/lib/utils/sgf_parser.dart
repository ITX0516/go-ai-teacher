import '../models/game_models.dart';
import 'sgf_utils.dart';

/// 解析 SGF 字符串为 GameState
/// 支持 SZ（棋盘大小）、B/W（手顺）、AB/AW（初始摆子）、C（注释）
GameState sgfToGame(String sgf) {
  // 去除首尾空白
  final trimmed = sgf.trim();
  if (!trimmed.startsWith('(') || !trimmed.endsWith(')')) {
    throw FormatException('Invalid SGF: must start with ( and end with )');
  }

  // 提取内容（去掉最外层括号）
  var content = trimmed.substring(1, trimmed.length - 1);

  // 解析属性
  var boardSize = 19;
  var komi = 6.5;
  final initialStones = <MoveRecord>[];
  final moves = <MoveRecord>[];

  // 解析根节点属性（以 ; 分隔）
  // 先处理根节点的属性（在第一个 ; 之前的部分）
  final firstSemicolon = content.indexOf(';');
  String rootProps = '';
  String nodesStr = '';

  if (firstSemicolon == -1) {
    // 没有手顺节点，只有根属性
    rootProps = content;
  } else {
    rootProps = content.substring(0, firstSemicolon);
    nodesStr = content.substring(firstSemicolon);
  }

  // 解析根属性
  final rootAttrs = _parseProperties(rootProps);
  if (rootAttrs.containsKey('SZ')) {
    boardSize = int.tryParse(rootAttrs['SZ']!.first) ?? 19;
  }
  if (rootAttrs.containsKey('KM')) {
    komi = double.tryParse(rootAttrs['KM']!.first) ?? 6.5;
  }

  // 解析 AB（黑子初始摆子）和 AW（白子初始摆子）
  if (rootAttrs.containsKey('AB')) {
    for (final coord in rootAttrs['AB']!) {
      final (x, y) = sgfToCoord(coord, boardSize);
      initialStones.add(MoveRecord(x: x, y: y, color: GoStone.black, move: _coordToGtp(x, y, boardSize)));
    }
  }
  if (rootAttrs.containsKey('AW')) {
    for (final coord in rootAttrs['AW']!) {
      final (x, y) = sgfToCoord(coord, boardSize);
      initialStones.add(MoveRecord(x: x, y: y, color: GoStone.white, move: _coordToGtp(x, y, boardSize)));
    }
  }

  // 解析手顺节点 (;B[xx];W[xx]...)
  final nodeRegex = RegExp(r';([A-Z][a-zA-Z]?)\[([^\]]*)\]');
  final matches = nodeRegex.allMatches(nodesStr);

  for (final match in matches) {
    final propName = match.group(1)!;
    final propValue = match.group(2)!;

    if (propName == 'B' || propName == 'W') {
      final color = propName == 'B' ? GoStone.black : GoStone.white;
      if (propValue == '' || propValue == 'tt') {
        // pass
        moves.add(MoveRecord(x: -1, y: -1, color: color, move: 'pass'));
      } else {
        final (x, y) = sgfToCoord(propValue, boardSize);
        moves.add(MoveRecord(
          x: x,
          y: y,
          color: color,
          move: _coordToGtp(x, y, boardSize),
        ));
      }
    }
    // 忽略其他属性（如 C, N 等）
  }

  // 重建棋盘状态
  final board = List.generate(
    boardSize,
    (_) => List.generate(boardSize, (_) => GoStone.empty),
  );

  // 放置初始摆子
  for (final stone in initialStones) {
    if (stone.x >= 0 && stone.x < boardSize && stone.y >= 0 && stone.y < boardSize) {
      board[stone.y][stone.x] = stone.color;
    }
  }

  // 依次落子（简化版：不处理提子）
  for (final move in moves) {
    if (move.x >= 0 && move.x < boardSize && move.y >= 0 && move.y < boardSize) {
      board[move.y][move.x] = move.color;
    }
  }

  final currentPlayer = moves.isEmpty
      ? GoStone.black
      : (moves.last.color == GoStone.black ? GoStone.white : GoStone.black);

  return GameState(
    boardSize: boardSize,
    board: board,
    moves: moves,
    komi: komi,
    currentPlayer: currentPlayer,
  );
}

/// 解析 SGF 属性，返回 {属性名: [值列表]}
Map<String, List<String>> _parseProperties(String props) {
  final result = <String, List<String>>{};
  // 匹配 PropName[value] 或 PropName[value][value]...
  final regex = RegExp(r'([A-Z][a-zA-Z]?)\[([^\]]*)\]');
  final matches = regex.allMatches(props);

  for (final match in matches) {
    final name = match.group(1)!;
    final value = match.group(2)!;
    result.putIfAbsent(name, () => []).add(value);
  }

  return result;
}

/// SGF 坐标转 GTP 显示坐标（如 qd）
String _coordToGtp(int x, int y, int boardSize) {
  if (x < 0 || y < 0) return 'pass';
  const letters = 'ABCDEFGHJKLMNOPQRST';
  if (x >= letters.length) return 'pass';
  final gtpY = boardSize - y;
  return '${letters[x]}$gtpY';
}
