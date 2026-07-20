import '../models/game_models.dart';
import '../models/analysis_data.dart';

abstract class GameService {
  Future<GameState> newGame(String gameId, {int boardSize = 19, double komi = 6.5});
  Future<GameState> getGame(String gameId);
  Future<Map<String, dynamic>> playMove(String gameId, int x, int y, int color);
  Future<Map<String, dynamic>> aiMove(String gameId, int color, {String difficulty = 'medium'});
  Future<GameState> undoMove(String gameId);
  Future<GameState> resign(String gameId, int color);
  Future<AnalysisResult> analyze(String gameId);
  Future<Explanation> explainMove(String gameId, String move, int moveNumber, double winRateChange, String context);
  Future<String> askQuestion(String gameId, String gameSgf, String question);
  Future<List<Puzzle>> getPuzzles({String? category, String? difficulty});
  Future<Puzzle> getPuzzle(String id);
  Future<Map<String, dynamic>> checkPuzzleAnswer(String id, String move);
  Future<String> gameSummary(String sgf, String result);
  Future<AnalysisData> analyzeGame(List<MoveRecord> moves, int boardSize, int color);
}
