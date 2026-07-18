class GoStone {
  static const int empty = 0;
  static const int black = 1;
  static const int white = 2;
}

class MoveRecord {
  final int x;
  final int y;
  final int color;
  final String move;

  MoveRecord({
    required this.x,
    required this.y,
    required this.color,
    required this.move,
  });

  factory MoveRecord.fromJson(Map<String, dynamic> json) {
    return MoveRecord(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      color: json['color'] ?? 0,
      move: json['move'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'color': color,
      'move': move,
    };
  }
}

class GameState {
  final int boardSize;
  final List<List<int>> board;
  final List<MoveRecord> moves;
  final double komi;
  final int currentPlayer;
  final String? result;
  final String? winner;

  GameState({
    required this.boardSize,
    required this.board,
    required this.moves,
    required this.komi,
    required this.currentPlayer,
    this.result,
    this.winner,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    final boardJson = json['board'] as List;
    final board = boardJson
        .map((row) => (row as List).map((e) => e as int).toList())
        .toList();

    final movesJson = json['moves'] as List;
    final moves = movesJson
        .map((m) => MoveRecord.fromJson(m as Map<String, dynamic>))
        .toList();

    return GameState(
      boardSize: json['board_size'] ?? 19,
      board: board,
      moves: moves,
      komi: (json['komi'] ?? 6.5).toDouble(),
      currentPlayer: json['current'] ?? 1,
      result: json['result'],
      winner: json['winner'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'board_size': boardSize,
      'board': board,
      'moves': moves.map((m) => m.toJson()).toList(),
      'komi': komi,
      'current': currentPlayer,
      'result': result,
      'winner': winner,
    };
  }
}

class TopMove {
  final String move;
  final double winRate;
  final double scoreLead;
  final int visits;
  final double policy;

  TopMove({
    required this.move,
    required this.winRate,
    required this.scoreLead,
    required this.visits,
    required this.policy,
  });

  factory TopMove.fromJson(Map<String, dynamic> json) {
    return TopMove(
      move: json['move'] ?? '',
      winRate: (json['win_rate'] ?? 0).toDouble(),
      scoreLead: (json['score_lead'] ?? 0).toDouble(),
      visits: json['visits'] ?? 0,
      policy: (json['policy'] ?? 0).toDouble(),
    );
  }
}

class AnalysisResult {
  final double winRate;
  final double scoreLead;
  final List<TopMove> topMoves;
  final int moveNumber;

  AnalysisResult({
    required this.winRate,
    required this.scoreLead,
    required this.topMoves,
    required this.moveNumber,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final movesJson = json['top_moves'] as List? ?? [];
    final topMoves = movesJson
        .map((m) => TopMove.fromJson(m as Map<String, dynamic>))
        .toList();

    return AnalysisResult(
      winRate: (json['win_rate'] ?? 50).toDouble(),
      scoreLead: (json['score_lead'] ?? 0).toDouble(),
      topMoves: topMoves,
      moveNumber: json['move_number'] ?? 0,
    );
  }
}

class Explanation {
  final String move;
  final String explanation;
  final String level;
  final String? tips;

  Explanation({
    required this.move,
    required this.explanation,
    required this.level,
    this.tips,
  });

  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      move: json['move'] ?? '',
      explanation: json['explanation'] ?? '',
      level: json['level'] ?? 'good',
      tips: json['tips'],
    );
  }
}

class Puzzle {
  final String id;
  final String title;
  final String difficulty;
  final String category;
  final String description;
  final int boardSize;
  final List<MoveRecord> initialStones;
  final List<String> correctMoves;
  final String solution;

  Puzzle({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.category,
    required this.description,
    required this.boardSize,
    required this.initialStones,
    required this.correctMoves,
    required this.solution,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    final stonesJson = json['initial_stones'] as List? ?? [];
    final initialStones = stonesJson
        .map((m) => MoveRecord.fromJson(m as Map<String, dynamic>))
        .toList();

    final correctJson = json['correct_moves'] as List? ?? [];
    final correctMoves = correctJson.map((e) => e.toString()).toList();

    return Puzzle(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      difficulty: json['difficulty'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      boardSize: json['board_size'] ?? 9,
      initialStones: initialStones,
      correctMoves: correctMoves,
      solution: json['solution'] ?? '',
    );
  }
}

class UserProgress {
  final String userId;
  final int level;
  final int xp;
  final int gamesPlayed;
  final int gamesWon;
  final int puzzlesSolved;
  final int currentStreak;
  final int longestStreak;
  final List<String> achievements;

  UserProgress({
    required this.userId,
    required this.level,
    required this.xp,
    required this.gamesPlayed,
    required this.gamesWon,
    required this.puzzlesSolved,
    required this.currentStreak,
    required this.longestStreak,
    required this.achievements,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final achJson = json['achievements'] as List? ?? [];
    return UserProgress(
      userId: json['user_id'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      gamesPlayed: json['games_played'] ?? 0,
      gamesWon: json['games_won'] ?? 0,
      puzzlesSolved: json['puzzles_solved'] ?? 0,
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      achievements: achJson.map((e) => e.toString()).toList(),
    );
  }
}
