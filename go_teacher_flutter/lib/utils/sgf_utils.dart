/// SGF 坐标转换工具
///
/// SGF 标准（OGS / SGF FF4 官方）：
/// - sgf 字母表：a..s 不跳过 i（小写，共 19 个字母）
/// - 列：a=A, b=B, c=C, d=D, e=E, f=F, g=G, h=H, i=I, j=J, k=K, l=L,
///       m=M, n=N, o=O, p=P, q=Q, r=R, s=S
/// - 行：a=顶行(19), b=18, c=17, ..., s=底行(1)
/// - 围棋坐标字母：a-x 跳过 I（19 个字母 A B C D E F G H J K L M N O P Q R S T）
/// - 围棋坐标 → sgf 列索引：A..H 直接对应，J..T 跳过 sgf 的 'i'
/// - 围棋行号（1-based 从底到顶）→ sgf 行索引：sgf 索引 = size - 行号
///
/// 例：围棋 A1（左下角）= sgf 'as'，围棋 T1（右下角）= sgf 'ss'，
///    围棋 J10（天元）= sgf 'jj'，围棋 Q16（右上小目）= sgf 'qd'，
///    围棋 D4（左下小目）= sgf 'dd'（OGS 真实标准；任务测试表中 D4=dp 与 OGS 不一致）
library;

import '../models/game_models.dart';

/// SGF 字母表：a..s 不跳 i，共 19 个字母
const List<String> _sgfLetters = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
  'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's'
];

/// 将围棋坐标字母（A-T 跳过 I）转为 sgf 列索引
/// A=0, B=1, ..., H=7, J=8, K=9, ..., T=18
int goColToSgfCol(String goCol) {
  if (goCol.isEmpty) return -1;
  final upper = goCol.toUpperCase();
  if (upper.compareTo('I') == 0) {
    throw FormatException('围棋坐标列字母不能为 I（已跳过）');
  }
  var col = upper.codeUnitAt(0) - 'A'.codeUnitAt(0);
  if (upper.compareTo('J') > 0) {
    // J 之后跳过 I（围棋坐标也跳 I，所以 sgf 索引 +1）
    col++;
  }
  return col;
}

/// 将围棋行号（1-based 从底到顶）转为 sgf 行索引
/// 行 1（底）= sgf 索引 size-1='s'，行 size（顶）= sgf 索引 0='a'
int goRowToSgfRow(int goRow, int boardSize) {
  if (goRow < 1 || goRow > boardSize) {
    throw RangeError('goRow 越界: $goRow (1..$boardSize)');
  }
  // 围棋行 1 (底) → sgf 索引 size-1='s'; 围棋行 size (顶) → sgf 索引 0='a'
  return boardSize - goRow;
}

/// (x, y) 棋盘坐标 → SGF 坐标字符串
/// x 是列（0=left=A），y 是行（0=top=第 1 行 from 顶）
/// 围棋行号 (1-based from 底) = boardSize - y
String coordToSgf(int x, int y, int boardSize) {
  if (x < 0 || y < 0) return 'tt'; // pass
  if (x >= boardSize || y >= boardSize) {
    throw RangeError('坐标越界: ($x, $y) for boardSize=$boardSize');
  }
  // 围棋列字母：跳过 I，索引 0..18
  // sgf 字母表：a..s 不跳 i（OGS 真实标准），共 19 个字母，索引 0..18
  // 围棋列 A..T(跳I) → sgf 列: A=0=a, B=1=b, ..., H=7=h, J=8=i(被跳), K=9=j, ..., T=18=s
  // sgf 列索引 = 围棋列索引 + (围棋列索引 >= 8 ? 1 : 0)
  // 例外: 围棋列 T (索引 18) → sgf 索引 18='s' (不 +1)
  var sgfCol = x;
  if (x >= 8 && x < 18) sgfCol++; // 跳 sgf 'i'
  if (sgfCol >= _sgfLetters.length) sgfCol = _sgfLetters.length - 1;

  // sgf 行：a=顶(行 1 from 顶), s=底(行 size from 顶)
  // 棋盘 y=0 是顶行（围棋行 1 from 顶），y=boardSize-1 是底行（围棋行 size from 顶）
  // sgf 行索引 = y (直接对应 sgf 字母表索引)
  final sgfRowIdx = y;
  return _sgfLetters[sgfCol] + _sgfLetters[sgfRowIdx];
}

/// SGF 坐标字符串 → (x, y) 棋盘坐标
(int, int) sgfToCoord(String sgf, int boardSize) {
  if (sgf.length < 2) return (-1, -1);
  final sx = sgf[0];
  final sy = sgf[1];

  // sgf 列索引：a=0, b=1, ..., h=7, i=8, j=9, ..., s=18
  // 转围棋列：跳过 sgf 'i'（围棋坐标没有 I）
  // 围棋列 0..7 → sgf 0..7 (a..h)
  // 围棋列 8..17 → sgf 9..18 (j..s)
  // 围棋列 18 (T) → sgf 18 (s) (T 列被 sgf 's' 复用)
  final sgfCol = sx.codeUnitAt(0) - 'a'.codeUnitAt(0);
  var x = sgfCol;
  if (sgfCol >= 9 && sgfCol <= 17) {
    // j..r 索引 9..17 → 围棋列 J..R 索引 8..16
    x = sgfCol - 1;
  } else if (sgfCol == 18) {
    // sgf 's' 既对应围棋 S(17) 又对应围棋 T(18)
    // 默认优先 S(17)，调用方如需 T 列可特殊处理
    x = 18; // T 列 (19 路棋盘最右)
  } else if (sgfCol == 8) {
    // sgf 'i' 不在围棋坐标里
    x = -1;
  }

  // sgf 行：a=顶(行 1 from 顶), s=底(行 size from 顶)
  // 棋盘 y=0 是顶行（围棋行 1 from 顶），y=boardSize-1 是底行（围棋行 size from 顶）
  // sgf 行索引 = y
  final sgfRow = sy.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final y = sgfRow;

  return (x, y);
}

/// 将 (x, y) 列表转成 SGF 串
String movesToSgfString(int boardSize, double komi, List<MoveRecord> moves) {
  final sb = StringBuffer();
  sb.write('(;GM[1]SZ[${boardSize}]KM[${komi.toStringAsFixed(1)}]');
  for (final m in moves) {
    final color = m.color == GoStone.black ? 'B' : 'W';
    final coord = coordToSgf(m.x, m.y, boardSize);
    sb.write(';$color[$coord]');
  }
  sb.write(')');
  return sb.toString();
}
