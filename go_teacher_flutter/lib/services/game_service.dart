import '../models/game_models.dart';
import '../models/analysis_data.dart';

abstract class GameService {
  Future<GameState> newGame(String gameId, {int boardSize = 19, double komi = 6.5});
  Future<GameState> getGame(String gameId);
  Future<Map<String, dynamic>> playMove(String gameId, int x, int y, int color);
  Future<Map<String, dynamic>> aiMove(String gameId, int color, {String difficulty = 'medium'});
  Future<GameState> undoMove(String gameId);

  /// 停一手（Pass）
  /// 返回更新后的 GameState 和是否触发终局（连续两次Pass）
  Future<Map<String, dynamic>> pass(String gameId, int color);

  /// 认输
  Future<GameState> resign(String gameId, int color);

  /// 检查指定方是否有合法落子点
  Future<bool> hasLegalMoves(String gameId, int color);

  /// 获取数棋数据（领地分布）
  /// 返回 territoryMap: 0=无主, 1=黑领地, 2=白领地
  Future<Map<String, dynamic>> getScoringData(String gameId);

  /// 确认死子并计算最终分数
  /// deadStones: 用户标记的死子坐标列表 [(x, y), ...]
  Future<ScoringResult> confirmDeadStones(String gameId, List<(int, int)> deadStones);

  Future<AnalysisResult> analyze(String gameId);
  Future<Explanation> explainMove(String gameId, String move, int moveNumber, double winRateChange, String sgf, {
    double? winRate,
    double? scoreLead,
    String? currentTurn,
    List<Map<String, String>>? areas,
  });
  Future<String> askQuestion(String gameId, String gameSgf, String question);
  Future<List<Puzzle>> getPuzzles({String? category, String? difficulty});
  Future<Puzzle> getPuzzle(String id);
  Future<Map<String, dynamic>> checkPuzzleAnswer(String id, String move);
  Future<String> gameSummary(String sgf, String result);
  Future<AnalysisData> analyzeGame(List<MoveRecord> moves, int boardSize, int color);
}
