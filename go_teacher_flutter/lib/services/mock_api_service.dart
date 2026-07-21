import 'dart:math' as math;
import '../models/game_models.dart';
import '../models/analysis_data.dart';
import 'go_engine.dart';
import 'game_service.dart';
import 'deepseek_service.dart';

class MockApiService implements GameService {
  final Map<String, GoEngine> _games = {};
  final math.Random _rand = math.Random();
  final DeepSeekService? _deepSeek;

  MockApiService({String? deepSeekApiKey})
      : _deepSeek = deepSeekApiKey != null && deepSeekApiKey.isNotEmpty
            ? DeepSeekService(apiKey: deepSeekApiKey)
            : null;

  Future<GameState> newGame(String gameId, {int boardSize = 19, double komi = 6.5}) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final engine = GoEngine(boardSize: boardSize, komi: komi);
    _games[gameId] = engine;
    return engine.toGameState();
  }

  Future<GameState> getGame(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    return engine.toGameState();
  }

  Future<Map<String, dynamic>> playMove(String gameId, int x, int y, int color) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');

    final success = engine.placeStone(x, y, color);
    if (!success) throw Exception('Invalid move');

    final analysis = _generateAnalysis(engine);

    return {
      'game': engine.toGameState(),
      'analysis': analysis,
    };
  }

  Future<Map<String, dynamic>> aiMove(String gameId, int color, {String difficulty = 'medium'}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');

    int aiLevel = 1;
    if (difficulty == 'easy') aiLevel = 0;
    if (difficulty == 'hard') aiLevel = 2;

    final ai = SimpleAI(level: aiLevel);
    final move = ai.chooseMove(engine, color);

    if (move == null) {
      engine.pass();
      return {
        'move': 'pass',
        'x': -1,
        'y': -1,
        'game': engine.toGameState(),
        'analysis': _generateAnalysis(engine),
      };
    }

    final (x, y) = move;
    engine.placeStone(x, y, color);
    final moveStr = engine.moveToString(x, y);
    final analysis = _generateAnalysis(engine);

    return {
      'move': moveStr,
      'x': x,
      'y': y,
      'game': engine.toGameState(),
      'analysis': analysis,
    };
  }

  Future<GameState> undoMove(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');

    engine.undo();
    engine.undo();

    return engine.toGameState();
  }

  Future<GameState> resign(String gameId, int color) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    engine.resignAction(color);
    return engine.toGameState();
  }

  Future<Map<String, dynamic>> pass(String gameId, int color) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    engine.pass();
    final gameState = engine.toGameState();
    final shouldEndGame = engine.consecutivePasses >= 2;
    return {
      'game': gameState,
      'shouldEndGame': shouldEndGame,
    };
  }

  Future<bool> hasLegalMoves(String gameId, int color) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    return engine.hasLegalMoves(color);
  }

  Future<Map<String, dynamic>> getScoringData(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    return {
      'board': engine.board,
      'territoryMap': engine.getTerritoryMap(),
      'boardSize': engine.boardSize,
    };
  }

  Future<ScoringResult> confirmDeadStones(String gameId, List<(int, int)> deadStones) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    return engine.calculateScore(deadStones);
  }

  Future<AnalysisResult> analyze(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final engine = _games[gameId];
    if (engine == null) throw Exception('Game not found');
    return _generateAnalysis(engine);
  }

  Future<Explanation> explainMove(
    String gameId,
    String move,
    int moveNumber,
    double winRateChange,
    String sgf, {
    double? winRate,
    double? scoreLead,
    String? currentTurn,
    List<Map<String, String>>? areas,
  }) async {
    if (_deepSeek != null) {
      try {
        final text = await _deepSeek!.explainMove(move, moveNumber, winRateChange, sgf);
        return Explanation(
          move: move,
          explanation: text,
          level: 'great',
          tips: '由 DeepSeek AI 提供讲解',
        );
      } catch (e) {
        // Fall through to mock
      }
    }

    await Future.delayed(const Duration(milliseconds: 400));

    final explanations = [
      '这步棋是一手好棋，它在巩固自身地盘的同时，也对对方的棋子形成了压力。棋理上讲，围棋讲究"攻守兼备"，这步棋正是这一原则的体现。',
      '这步棋走得不错，属于稳健型的下法。虽然不是最激进的选择，但胜在稳妥，符合"先为不可胜，以待敌之可胜"的围棋思想。',
      '这手棋很有想法！它瞄准了对方棋形的弱点，同时扩展了自己的势力范围。建议后续继续保持这种进攻性的姿态。',
      '这步棋稍微有些缓，建议考虑更积极的下法。在围棋中，主动出击往往比被动防守更有利。可以尝试打入或浅消对方的模样。',
      '这是一步常识性的好棋，符合围棋的基本棋理。在布局阶段，占据角地和大场是优先考虑的方向，这步棋正好体现了这一点。',
    ];

    final levels = ['good', 'excellent', 'ok', 'doubtful', 'great'];
    final tips = [
      '小贴士：下棋时多考虑"这步棋之后对方会怎么应"，棋力会提升很快。',
      '小贴士：记住"金角银边草肚皮"，布局阶段优先占角。',
      '小贴士：遇到复杂局面时，先冷静判断形势，再决定策略。',
    ];

    return Explanation(
      move: move,
      explanation: explanations[_rand.nextInt(explanations.length)],
      level: levels[_rand.nextInt(levels.length)],
      tips: tips[_rand.nextInt(tips.length)],
    );
  }

  Future<String> askQuestion(String gameId, String gameSgf, String question) async {
    if (_deepSeek != null) {
      try {
        return await _deepSeek!.askQuestion(question, gameSgf);
      } catch (e) {
        // Fall through to mock
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final q = question.toLowerCase();
    if (q.contains('为什么') || q.contains('why')) {
      return '这是一个很好的问题！在围棋中，每一步棋都有其背后的棋理。简单来说，这步棋的主要目的是：1）巩固自身的棋形；2）扩张地盘；3）对对方施加压力。围棋讲究"宁失数子，勿失一先"，掌握主动权是取胜的关键。建议你在实战中多体会每一步棋的意图，棋力会快速提升的！';
    } else if (q.contains('怎么') || q.contains('how')) {
      return '要提高这方面的能力，我的建议是：1）多做死活题，培养计算能力；2）研究职业棋谱，学习高手的思路；3）在实战中勇于尝试，不怕犯错；4）下完棋后认真复盘，总结经验。坚持这些方法，棋力一定会有显著提升！';
    } else if (q.contains('规则') || q.contains('rule')) {
      return '围棋的基本规则其实很简单：1）黑先白后，轮流落子；2）棋子落在交叉点上；3）被围住的棋子要被提掉；4）不能下在没有气的位置（自杀）；5）打劫需要隔一手才能提回；6）最后数子或数目决定胜负。掌握了这些基本规则就可以下棋了，更深入的规则可以在实战中慢慢学习。';
    } else {
      return '你的问题很有意思！关于这盘棋的局势，我认为当前的关键是把握好大场和急所的关系。围棋中有句话叫"急所胜过大场"，意思是关系到双方棋子死活或厚薄的要点比单纯围空更重要。建议你重点关注棋形的要点，这将是决定棋局走向的关键因素。';
    }
  }

  Future<List<Puzzle>> getPuzzles({String? category, String? difficulty}) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final allPuzzles = _getAllPuzzles();

    if (category != null && category.isNotEmpty) {
      allPuzzles.removeWhere((p) => p.category != category);
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      allPuzzles.removeWhere((p) => p.difficulty != difficulty);
    }

    return allPuzzles;
  }

  Future<Puzzle> getPuzzle(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final puzzles = _getAllPuzzles();
    final puzzle = puzzles.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Puzzle not found'),
    );
    return puzzle;
  }

  Future<Map<String, dynamic>> checkPuzzleAnswer(String id, String move) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final puzzles = _getAllPuzzles();
    final puzzle = puzzles.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Puzzle not found'),
    );

    final isCorrect = puzzle.correctMoves.contains(move.toUpperCase());

    if (isCorrect) {
      return {
        'correct': true,
        'explanation': '答对了！${puzzle.solution} 这道题考察的是你的计算能力，能够答对说明你对这类棋形已经有了很好的理解。继续保持！',
      };
    } else {
      return {
        'correct': false,
        'explanation': '这步棋还不是最佳选择。${puzzle.solution} 建议你仔细观察棋形，找出对方棋形的弱点，然后再试试看。记住：遇到死活题时，先找要点，再算变化。',
      };
    }
  }

  Future<String> gameSummary(String sgf, String result) async {
    if (_deepSeek != null) {
      try {
        return await _deepSeek!.gameSummary(sgf, result);
      } catch (e) {
        // Fall through to mock
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));
    return '''这是一局精彩的对局！以下是 AI 老师的复盘总结：

**整体评价：**
本局双方展现了不错的实力，布局阶段各有章法，中盘战斗激烈，官子阶段也有不少值得学习的地方。

**优点：**
1. 布局阶段占据了不错的大场，方向感良好
2. 战斗中能够抓住对手的失误，体现了一定的战斗力
3. 棋形整体比较工整，没有明显的恶手

**需要改进的地方：**
1. 中盘阶段有几步棋略显保守，可以考虑更积极的下法
2. 对于厚势的利用还不够充分，"厚势不围空"的理念需要加深理解
3. 官子阶段还有提升空间，注意先手官子的价值

**学习建议：**
建议你重点加强中盘战斗力和形势判断能力。可以多做一些中盘战的题目，同时在实战中养成每步棋都思考"对方最好的应手是什么"的习惯。

继续努力，棋力一定会更上一层楼！ 🔥''';
  }

  Future<AnalysisData> analyzeGame(List<MoveRecord> moves, int boardSize, int color) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final winrate = 0.45 + _rand.nextDouble() * 0.15;
    final bestMoves = ['D17', 'R4', 'D4', 'R17', 'K10'];
    final bestMove = bestMoves[_rand.nextInt(bestMoves.length)];

    final candidateMoves = <CandidateMove>[];
    for (int i = 0; i < 5; i++) {
      candidateMoves.add(CandidateMove(
        move: bestMoves[i],
        winrate: winrate + (5 - i) * 0.015 - _rand.nextDouble() * 0.01,
        scoreLead: (winrate - 0.5) * 20 + _rand.nextDouble() * 5 - 2.5,
        visits: 100 - i * 15 + _rand.nextInt(20),
      ));
    }

    return AnalysisData(
      winrate: winrate,
      bestMove: bestMove,
      scoreLead: (winrate - 0.5) * 20,
      candidateMoves: candidateMoves,
    );
  }

  AnalysisResult _generateAnalysis(GoEngine engine) {
    final moveNum = engine.moves.length;
    final baseWinRate = 50.0 + math.sin(moveNum / 10) * 10 + _rand.nextDouble() * 5 - 2.5;
    final winRate = baseWinRate.clamp(5.0, 95.0);

    final topMoves = <TopMove>[];
    final ai = SimpleAI(level: 2);
    final candidates = <(int, int)>[];

    for (int y = 0; y < engine.boardSize; y++) {
      for (int x = 0; x < engine.boardSize; x++) {
        if (engine.board[y][x] == GoStone.empty) {
          candidates.add((x, y));
        }
      }
    }

    final scored = <_MoveScore>[];
    for (final (x, y) in candidates) {
      final testBoard = engine.board.map((row) => List<int>.from(row)).toList();
      final testEngine = GoEngine(boardSize: engine.boardSize, komi: engine.komi);
      testEngine.board = testBoard;
      if (testEngine.placeStone(x, y, engine.currentPlayer)) {
        final score = ai.evaluateMove(testEngine, x, y, engine.currentPlayer);
        scored.add(_MoveScore(x, y, score, engine.moveToString(x, y)));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final topCount = math.min(5, scored.length);
    for (int i = 0; i < topCount; i++) {
      final ms = scored[i];
      final wr = winRate + (topCount - i) * 3 + _rand.nextDouble() * 2;
      topMoves.add(TopMove(
        move: ms.moveStr,
        winRate: wr.clamp(1.0, 99.0),
        scoreLead: (wr - 50) * 0.3,
        visits: 1000 - i * 150 + _rand.nextInt(100),
        policy: 0.5 - i * 0.08,
      ));
    }

    return AnalysisResult(
      winRate: winRate,
      scoreLead: (winRate - 50) * 0.3,
      topMoves: topMoves,
      moveNumber: moveNum,
    );
  }

  List<Puzzle> _getAllPuzzles() {
    return [
      Puzzle(
        id: 'puzzle_001',
        title: '入门死活：直三',
        difficulty: 'beginner',
        category: 'life_death',
        description: '黑先，如何走活这块棋？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 2, y: 5, color: 1, move: 'C4'),
          MoveRecord(x: 3, y: 5, color: 1, move: 'D4'),
          MoveRecord(x: 4, y: 5, color: 1, move: 'E4'),
          MoveRecord(x: 2, y: 4, color: 1, move: 'C5'),
          MoveRecord(x: 4, y: 4, color: 1, move: 'E5'),
          MoveRecord(x: 2, y: 3, color: 1, move: 'C6'),
          MoveRecord(x: 3, y: 3, color: 1, move: 'D6'),
          MoveRecord(x: 4, y: 3, color: 1, move: 'E6'),
          MoveRecord(x: 1, y: 6, color: 2, move: 'B3'),
          MoveRecord(x: 5, y: 6, color: 2, move: 'F3'),
          MoveRecord(x: 1, y: 2, color: 2, move: 'B7'),
          MoveRecord(x: 5, y: 2, color: 2, move: 'F7'),
          MoveRecord(x: 1, y: 4, color: 2, move: 'B5'),
          MoveRecord(x: 5, y: 4, color: 2, move: 'F5'),
        ],
        correctMoves: ['D5'],
        solution: '要点在D5位。黑下在D5后形成两个眼位，这块棋就活了。直三的死活要点在中间那一格，记住"直三中间一点活"。',
      ),
      Puzzle(
        id: 'puzzle_002',
        title: '吃子技巧：抱吃',
        difficulty: 'beginner',
        category: 'capture',
        description: '黑先，如何吃掉白子？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 3, y: 3, color: 1, move: 'D6'),
          MoveRecord(x: 4, y: 3, color: 2, move: 'E6'),
          MoveRecord(x: 3, y: 4, color: 2, move: 'D5'),
          MoveRecord(x: 2, y: 4, color: 1, move: 'C5'),
          MoveRecord(x: 2, y: 3, color: 1, move: 'C6'),
        ],
        correctMoves: ['E5'],
        solution: '黑下E5位可以形成抱吃，白子无处可逃。抱吃是围棋中最基本的吃子方法之一，关键是封住对方逃跑的方向。',
      ),
      Puzzle(
        id: 'puzzle_003',
        title: '中级死活：刀把五',
        difficulty: 'intermediate',
        category: 'life_death',
        description: '黑先，如何做活？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 1, y: 5, color: 1, move: 'B4'),
          MoveRecord(x: 2, y: 5, color: 1, move: 'C4'),
          MoveRecord(x: 3, y: 5, color: 1, move: 'D4'),
          MoveRecord(x: 4, y: 5, color: 1, move: 'E4'),
          MoveRecord(x: 1, y: 4, color: 1, move: 'B5'),
          MoveRecord(x: 4, y: 4, color: 1, move: 'E5'),
          MoveRecord(x: 1, y: 3, color: 1, move: 'B6'),
          MoveRecord(x: 2, y: 3, color: 1, move: 'C6'),
          MoveRecord(x: 3, y: 3, color: 1, move: 'D6'),
          MoveRecord(x: 4, y: 3, color: 1, move: 'E6'),
          MoveRecord(x: 0, y: 2, color: 2, move: 'A7'),
          MoveRecord(x: 0, y: 4, color: 2, move: 'A5'),
          MoveRecord(x: 0, y: 6, color: 2, move: 'A3'),
          MoveRecord(x: 5, y: 2, color: 2, move: 'F7'),
          MoveRecord(x: 5, y: 4, color: 2, move: 'F5'),
          MoveRecord(x: 5, y: 6, color: 2, move: 'F3'),
        ],
        correctMoves: ['C5'],
        solution: '刀把五的要点在C5位（刀柄处）。黑下C5后可以确保做出两个眼。刀把五是常见的死活棋形，记住要点在刀柄一侧。',
      ),
      Puzzle(
        id: 'puzzle_004',
        title: '吃子技巧：征子',
        difficulty: 'intermediate',
        category: 'capture',
        description: '黑先，能否征掉白子？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 4, y: 4, color: 2, move: 'E5'),
          MoveRecord(x: 3, y: 4, color: 1, move: 'D5'),
          MoveRecord(x: 4, y: 3, color: 1, move: 'E6'),
          MoveRecord(x: 2, y: 6, color: 1, move: 'C3'),
          MoveRecord(x: 5, y: 2, color: 1, move: 'F7'),
        ],
        correctMoves: ['D3'],
        solution: '黑下D3位开始征子。由于右下角没有白子接应，白棋最终会被征吃。征子是围棋中重要的吃子技巧，需要计算到尽头，并且注意对方是否有接应子。',
      ),
      Puzzle(
        id: 'puzzle_005',
        title: '星定式：小飞挂',
        difficulty: 'beginner',
        category: 'joseki',
        description: '白小飞挂角，黑应如何应对？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 6, y: 6, color: 1, move: 'G3'),
          MoveRecord(x: 4, y: 6, color: 2, move: 'E3'),
        ],
        correctMoves: ['G5', 'F5'],
        solution: '黑下G5位（尖顶）或F5位（小飞）都是常见的应手。尖顶后白一般会长，黑再拆边，这是最基本的星位定式之一。小飞应则更加灵活多变。',
      ),
      Puzzle(
        id: 'puzzle_006',
        title: '高级死活：大猪嘴',
        difficulty: 'advanced',
        category: 'life_death',
        description: '黑先，如何杀白？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 5, y: 1, color: 2, move: 'F8'),
          MoveRecord(x: 6, y: 1, color: 2, move: 'G8'),
          MoveRecord(x: 7, y: 1, color: 2, move: 'H8'),
          MoveRecord(x: 5, y: 2, color: 2, move: 'F7'),
          MoveRecord(x: 7, y: 2, color: 2, move: 'H7'),
          MoveRecord(x: 5, y: 3, color: 2, move: 'F6'),
          MoveRecord(x: 6, y: 3, color: 2, move: 'G6'),
          MoveRecord(x: 7, y: 3, color: 2, move: 'H6'),
          MoveRecord(x: 4, y: 1, color: 1, move: 'E8'),
          MoveRecord(x: 8, y: 1, color: 1, move: 'J8'),
          MoveRecord(x: 4, y: 2, color: 1, move: 'E7'),
          MoveRecord(x: 8, y: 2, color: 1, move: 'J7'),
          MoveRecord(x: 4, y: 3, color: 1, move: 'E6'),
          MoveRecord(x: 4, y: 4, color: 1, move: 'E5'),
          MoveRecord(x: 5, y: 4, color: 1, move: 'F5'),
          MoveRecord(x: 6, y: 4, color: 1, move: 'G5'),
          MoveRecord(x: 7, y: 4, color: 1, move: 'H5'),
          MoveRecord(x: 8, y: 4, color: 1, move: 'J5'),
        ],
        correctMoves: ['G7'],
        solution: '大猪嘴的杀棋要点是G7位（扳）。黑先扳，白点后黑再打吃，形成劫杀。这是经典的死活棋形，记住"大猪嘴扳点死"的口诀。',
      ),
      Puzzle(
        id: 'puzzle_007',
        title: '吃子技巧：倒扑',
        difficulty: 'intermediate',
        category: 'capture',
        description: '黑先，如何利用倒扑吃子？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 3, y: 4, color: 1, move: 'D5'),
          MoveRecord(x: 4, y: 4, color: 2, move: 'E5'),
          MoveRecord(x: 5, y: 4, color: 2, move: 'F5'),
          MoveRecord(x: 4, y: 3, color: 2, move: 'E6'),
          MoveRecord(x: 5, y: 3, color: 2, move: 'F6'),
          MoveRecord(x: 3, y: 2, color: 1, move: 'D7'),
          MoveRecord(x: 6, y: 3, color: 1, move: 'G6'),
          MoveRecord(x: 2, y: 4, color: 1, move: 'C5'),
          MoveRecord(x: 4, y: 2, color: 1, move: 'E7'),
          MoveRecord(x: 5, y: 2, color: 1, move: 'F7'),
          MoveRecord(x: 6, y: 2, color: 1, move: 'G7'),
        ],
        correctMoves: ['D3'],
        solution: '黑下D3位形成倒扑。白如果提掉黑棋，黑可以在反方向提回更多的白子。倒扑是一种巧妙的吃子技巧，利用了对方提子后露出的断点。',
      ),
      Puzzle(
        id: 'puzzle_008',
        title: '小目定式：小飞挂',
        difficulty: 'intermediate',
        category: 'joseki',
        description: '白小飞挂小目，黑应如何应对？',
        boardSize: 9,
        initialStones: [
          MoveRecord(x: 6, y: 5, color: 1, move: 'G4'),
          MoveRecord(x: 4, y: 6, color: 2, move: 'E3'),
        ],
        correctMoves: ['F4', 'G3'],
        solution: '黑下F4位（一间低夹）或G3位（飞压）都是常见的定式选择。一间低夹比较积极主动，飞压则取外势。选择哪种取决于你的布局策略。',
      ),
    ];
  }

  String _engineToSgf(GoEngine engine) {
    final letters = 'ABCDEFGHJKLMNOPQRST';
    final size = engine.boardSize;
    var sgf = '(;GM[1]FF[4]SZ[$size]';
    for (var i = 0; i < engine.moves.length; i++) {
      final move = engine.moves[i];
      final color = move.color == GoStone.black ? 'B' : 'W';
      final cx = move.x < size ? letters[move.x] : '';
      final cy = move.y < size ? String.fromCharCode(97 + size - 1 - move.y) : '';
      sgf += ';$color[$cx$cy]';
    }
    sgf += ')';
    return sgf;
  }
}

class _MoveScore {
  final int x;
  final int y;
  final int score;
  final String moveStr;

  _MoveScore(this.x, this.y, this.score, this.moveStr);
}
