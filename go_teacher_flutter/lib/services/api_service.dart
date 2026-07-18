import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_models.dart';

class ApiService {
  final String baseUrl;
  final http.Client _client;

  ApiService({this.baseUrl = 'http://localhost:8080'}) : _client = http.Client();

  factory ApiService.withClient(http.Client client, {String baseUrl = 'http://localhost:8080'}) {
    return ApiService._internal(baseUrl, client);
  }

  ApiService._internal(this.baseUrl, this._client);

  Future<GameState> newGame(String gameId, {int boardSize = 19, double komi = 6.5}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'board_size': boardSize, 'komi': komi}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GameState.fromJson(data['game']);
    }
    throw Exception('Failed to create game: ${response.body}');
  }

  Future<GameState> getGame(String gameId) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/games/$gameId'));
    if (response.statusCode == 200) {
      return GameState.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get game');
  }

  Future<Map<String, dynamic>> playMove(String gameId, int x, int y, int color) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/move'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'x': x, 'y': y, 'color': color}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'game': GameState.fromJson(data['game']),
        'analysis': AnalysisResult.fromJson(data['analysis']),
      };
    }
    throw Exception('Failed to play move: ${response.body}');
  }

  Future<Map<String, dynamic>> aiMove(String gameId, int color, {String difficulty = 'medium'}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/ai-move'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'color': color, 'difficulty': difficulty}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'move': data['move'],
        'x': data['x'],
        'y': data['y'],
        'game': GameState.fromJson(data['game']),
        'analysis': AnalysisResult.fromJson(data['analysis']),
      };
    }
    throw Exception('Failed to get AI move: ${response.body}');
  }

  Future<GameState> undoMove(String gameId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/undo'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return GameState.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to undo move');
  }

  Future<AnalysisResult> analyze(String gameId) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/games/$gameId/analyze'));
    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to analyze');
  }

  Future<Explanation> explainMove(String gameId, String move, int moveNumber, double winRateChange, String context) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/explain'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'move_number': moveNumber,
        'move': move,
        'win_rate_change': winRateChange,
        'context': context,
      }),
    );
    if (response.statusCode == 200) {
      return Explanation.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get explanation');
  }

  Future<String> askQuestion(String gameId, String gameSgf, String question) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/$gameId/ask'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'game_sgf': gameSgf, 'question': question}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['answer'] ?? '';
    }
    throw Exception('Failed to get answer');
  }

  Future<List<Puzzle>> getPuzzles({String? category, String? difficulty}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (difficulty != null) params['difficulty'] = difficulty;
    final uri = Uri.parse('$baseUrl/api/puzzles').replace(queryParameters: params);
    final response = await _client.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['puzzles'] ?? [];
      return list.map((e) => Puzzle.fromJson(e)).toList();
    }
    throw Exception('Failed to get puzzles');
  }

  Future<Puzzle> getPuzzle(String id) async {
    final response = await _client.get(Uri.parse('$baseUrl/api/puzzles/$id'));
    if (response.statusCode == 200) {
      return Puzzle.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get puzzle');
  }

  Future<Map<String, dynamic>> checkPuzzleAnswer(String id, String move) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/puzzles/$id/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'move': move}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to check answer');
  }

  Future<String> gameSummary(String sgf, String result) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/api/games/summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sgf': sgf, 'result': result}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['summary'] ?? '';
    }
    throw Exception('Failed to get summary');
  }
}
