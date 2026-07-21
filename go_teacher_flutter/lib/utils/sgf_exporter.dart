import '../models/game_models.dart';

/// 将 GameState 导出为 SGF 格式字符串
/// SGF 坐标规则：列 a-s（小写，不跳 I），行 a-s（0=顶部）
/// 例：Q16 = B[qd]（q=第17列，d=第4行）
String gameToSgf(GameState state, {
  String? gameName,
  String? playerBlack,
  String? playerWhite,
  String? result,
}) {
  final sb = StringBuffer();
  sb.write('(;GM[1]');
  sb.write('SZ[${state.boardSize}]');
  sb.write('KM[${state.komi.toStringAsFixed(1)}]');

  if (gameName != null && gameName.isNotEmpty) {
    sb.write('GN[$gameName]');
  }
  if (playerBlack != null && playerBlack.isNotEmpty) {
    sb.write('PB[$playerBlack]');
  }
  if (playerWhite != null && playerWhite.isNotEmpty) {
    sb.write('PW[$playerWhite]');
  }
  if (result != null && result.isNotEmpty) {
    sb.write('RE[$result]');
  }

  // 手顺节点
  for (int i = 0; i < state.moves.length; i++) {
    final move = state.moves[i];
    final color = move.color == GoStone.black ? 'B' : 'W';
    final coord = _coordToSgf(move.x, move.y, state.boardSize);
    sb.write(';$color[$coord]');
  }

  // 当前手数标记（加在最后一个节点上，如果无手则加在根节点）
  final currentMoveNum = state.moves.length;
  if (state.moves.isNotEmpty) {
    sb.write('C[当前手数：$currentMoveNum]');
  } else {
    sb.write('C[当前手数：0]');
  }

  sb.write(')');
  return sb.toString();
}

/// 将坐标转为 SGF 坐标（2个小写字母）
String _coordToSgf(int x, int y, int boardSize) {
  // pass
  if (x < 0 || y < 0) {
    return 'tt';
  }
  // SGF: a=0, b=1, ..., s=18 (不跳 I)
  final sx = String.fromCharCode('a'.codeUnitAt(0) + x);
  final sy = String.fromCharCode('a'.codeUnitAt(0) + y);
  return '$sx$sy';
}
