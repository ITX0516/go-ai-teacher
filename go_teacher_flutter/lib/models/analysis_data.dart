class AnalysisData {
  final double winrate;
  final String bestMove;
  final double scoreLead;
  final List<CandidateMove> candidateMoves;

  AnalysisData({
    required this.winrate,
    required this.bestMove,
    required this.scoreLead,
    required this.candidateMoves,
  });

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    final movesJson = json['candidateMoves'] as List? ?? [];
    final candidateMoves = movesJson
        .map((m) => CandidateMove.fromJson(m as Map<String, dynamic>))
        .toList();

    return AnalysisData(
      winrate: (json['winrate'] ?? 0.5).toDouble(),
      bestMove: json['bestMove'] ?? '',
      scoreLead: (json['scoreLead'] ?? 0).toDouble(),
      candidateMoves: candidateMoves,
    );
  }
}

class CandidateMove {
  final String move;
  final double winrate;
  final double scoreLead;
  final int visits;

  CandidateMove({
    required this.move,
    required this.winrate,
    required this.scoreLead,
    required this.visits,
  });

  factory CandidateMove.fromJson(Map<String, dynamic> json) {
    return CandidateMove(
      move: json['move'] ?? '',
      winrate: (json['winrate'] ?? 0).toDouble(),
      scoreLead: (json['scoreLead'] ?? 0).toDouble(),
      visits: json['visits'] ?? 0,
    );
  }
}