import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/go_board.dart';
import '../services/game_service.dart';
import '../models/game_models.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final String _gameId = 'review_${DateTime.now().millisecondsSinceEpoch}';
  GameState? _fullGameState;
  GameState? _displayGameState;
  AnalysisResult? _analysis;
  int _currentMoveIndex = -1;
  bool _isLoading = true;
  String? _summary;
  bool _showSummary = false;

  final sampleMoves = [
    (15, 3, 1, 'Q16'),
    (3, 15, 2, 'D4'),
    (3, 3, 1, 'D16'),
    (15, 15, 2, 'Q4'),
    (16, 5, 1, 'R14'),
    (2, 14, 2, 'C5'),
  ];

  @override
  void initState() {
    super.initState();
    _initReview();
  }

  Future<void> _initReview() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      var game = await api.newGame(_gameId, boardSize: 19, komi: 6.5);

      for (final move in sampleMoves) {
        final result = await api.playMove(_gameId, move.$1, move.$2, move.$3);
        game = result['game'];
      }

      setState(() {
        _fullGameState = game;
        _displayGameState = game;
        _analysis = null;
        _currentMoveIndex = game.moves.length - 1;
      });

      _analyzePosition();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _analyzePosition() async {
    try {
      final api = context.read<GameService>();
      final result = await api.analyze(_gameId);
      if (mounted) {
        setState(() => _analysis = result);
      }
    } catch (_) {}
  }

  Future<void> _generateSummary() async {
    setState(() => _showSummary = true);
    try {
      final api = context.read<GameService>();
      final summary = await api.gameSummary('', '黑中盘胜');
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) {
        setState(() => _summary = '生成失败: $e');
      }
    }
  }

  void _goToMove(int index) {
    if (_fullGameState == null) return;
    if (index < -1 || index >= _fullGameState!.moves.length) return;

    final board = List.generate(_fullGameState!.boardSize, (_) => List.filled(_fullGameState!.boardSize, 0));
    final moves = <MoveRecord>[];
    for (int i = 0; i <= index; i++) {
      final m = _fullGameState!.moves[i];
      board[m.y][m.x] = m.color;
      moves.add(m);
    }

    setState(() {
      _currentMoveIndex = index;
      _displayGameState = GameState(
        boardSize: _fullGameState!.boardSize,
        board: board,
        moves: moves,
        komi: _fullGameState!.komi,
        currentPlayer: index % 2 == 0 ? 2 : 1,
      );
    });
  }

  void _handleBoardTap(int x, int y) {
    if (_displayGameState == null) return;
    final moveIndex = _displayGameState!.moves.indexWhere(
      (m) => m.x == x && m.y == y,
    );
    if (moveIndex >= 0) {
      _goToMove(moveIndex);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('点击已有棋子可跳转到对应手'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        title: const Text('棋谱复盘'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _generateSummary,
            tooltip: 'AI 总结',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_displayGameState == null) {
      return const Center(child: Text('加载失败'));
    }

    final lastMove = _currentMoveIndex >= 0 && _currentMoveIndex < _displayGameState!.moves.length
        ? _displayGameState!.moves[_currentMoveIndex]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWinRateBar(),
          const SizedBox(height: 12),
          GoBoard(
            boardSize: _displayGameState!.boardSize,
            board: _displayGameState!.board,
            moves: _displayGameState!.moves,
            showMoveNumbers: true,
            lastMoveX: lastMove?.x,
            lastMoveY: lastMove?.y,
            onTap: _handleBoardTap,
          ),
          const SizedBox(height: 16),
          _buildMoveControls(),
          const SizedBox(height: 12),
          _buildMoveSlider(),
          const SizedBox(height: 16),
          if (_analysis != null) _buildAnalysisPanel(),
          const SizedBox(height: 16),
          _buildMoveList(),
          if (_showSummary) _buildSummaryPanel(),
        ],
      ),
    );
  }

  Widget _buildWinRateBar() {
    final blackWR = _analysis?.winRate ?? 50.0;
    return Container(
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * (blackWR / 100),
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '${blackWR.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    '${(100 - blackWR).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _controlButton(Icons.first_page, '开局', () => _goToMove(-1)),
        const SizedBox(width: 8),
        _controlButton(Icons.chevron_left, '上一步', () {
          _goToMove(_currentMoveIndex - 1);
        }),
        const SizedBox(width: 8),
        _controlButton(Icons.chevron_right, '下一步', () {
          _goToMove(_currentMoveIndex + 1);
        }),
        const SizedBox(width: 8),
        _controlButton(Icons.last_page, '终局', () {
          _goToMove(_displayGameState!.moves.length - 1);
        }),
      ],
    );
  }

  Widget _controlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF718096))),
      ],
    );
  }

  Widget _buildMoveSlider() {
    final maxMoves = _displayGameState!.moves.length - 1;
    if (maxMoves < 0) return const SizedBox.shrink();

    return Column(
      children: [
        Slider(
          value: _currentMoveIndex.clamp(0, maxMoves).toDouble(),
          min: 0,
          max: maxMoves.toDouble(),
          divisions: maxMoves,
          label: '第 ${_currentMoveIndex + 1} 手',
          onChanged: (v) => _goToMove(v.toInt()),
          activeColor: const Color(0xFF1E3A5F),
        ),
        Text(
          '第 ${_currentMoveIndex + 1} 手 / 共 ${_displayGameState!.moves.length} 手',
          style: const TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel() {
    if (_analysis == null || _analysis!.topMoves.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF1E3A5F), size: 20),
              SizedBox(width: 8),
              Text(
                'AI 建议',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._analysis!.topMoves.take(3).map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        alignment: Alignment.center,
                        child: Text(
                          m.move,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E3A5F),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Container(
                                  height: 6,
                                  width: (m.winRate / 100) * 150,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1E3A5F), Color(0xFF3498DB)],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '胜率 ${m.winRate.toStringAsFixed(1)}% · 领先 ${m.scoreLead.toStringAsFixed(1)} 目',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF718096)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMoveList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '棋谱记录',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_displayGameState!.moves.length, (index) {
              final move = _displayGameState!.moves[index];
              final isSelected = index == _currentMoveIndex;
              final isBlack = move.color == 1;
              return GestureDetector(
                onTap: () => _goToMove(index),
                child: Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1E3A5F)
                        : isBlack
                            ? Colors.black
                            : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: isBlack || isSelected
                        ? null
                        : Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isBlack || isSelected ? Colors.white : Colors.black54,
                        ),
                      ),
                      Text(
                        move.move,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isBlack || isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5E9), Color(0xFFFFF8E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF8B4513)),
              SizedBox(width: 8),
              Text(
                'AI 老师复盘总结',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summary == null
              ? const Center(child: CircularProgressIndicator())
              : Text(
                  _summary!,
                  style: const TextStyle(fontSize: 14, height: 1.6),
                ),
        ],
      ),
    );
  }
}
