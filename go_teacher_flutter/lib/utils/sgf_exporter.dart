import '../models/game_models.dart';
import 'sgf_utils.dart';

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
  sb.write('FF[4]');
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

  // 结果字段：优先使用传入的 result，其次使用 state.result
  String? finalResult;
  if (result != null && result.isNotEmpty) {
    finalResult = result;
  } else if (state.result != null && state.result!.isNotEmpty) {
    finalResult = _convertToSgfResult(state.result!, state.winner);
  }

  if (finalResult != null && finalResult.isNotEmpty) {
    sb.write('RE[$finalResult]');
  }

  // 手顺节点
  for (int i = 0; i < state.moves.length; i++) {
    final move = state.moves[i];
    final color = move.color == GoStone.black ? 'B' : 'W';
    final coord = coordToSgf(move.x, move.y, state.boardSize);
    sb.write(';$color[$coord]');
  }

  sb.write(')');
  return sb.toString();
}

/// 将中文结果描述转换为 SGF 标准结果格式
/// SGF RE 字段格式：B+R（黑胜认输）、W+R（白胜认输）、B+8.5（黑胜8.5目）、W+8.5
String _convertToSgfResult(String result, String? winner) {
  if (winner == null) return result;

  if (result.contains('认输')) {
    return winner == 'black' ? 'B+R' : 'W+R';
  }

  if (result.contains('和棋')) {
    return '0';
  }

  // 提取目数
  final match = RegExp(r'([\d.]+)\s*目').firstMatch(result);
  if (match != null) {
    final margin = match.group(1)!;
    return '${winner == 'black' ? 'B' : 'W'}+$margin';
  }

  return result;
}

/// 根据终局类型和结果生成 SGF RE 字段
String generateSgfResult(EndGameType endGameType, String winner, [double? margin]) {
  switch (endGameType) {
    case EndGameType.resign:
      return '${winner == 'black' ? 'B' : 'W'}+R';
    case EndGameType.scoring:
      if (margin != null) {
        return '${winner == 'black' ? 'B' : 'W'}+${margin.toStringAsFixed(1)}';
      }
      return '${winner == 'black' ? 'B' : 'W'}+';
    case EndGameType.noMoves:
      if (margin != null) {
        return '${winner == 'black' ? 'B' : 'W'}+${margin.toStringAsFixed(1)}';
      }
      return '${winner == 'black' ? 'B' : 'W'}+';
  }
}
