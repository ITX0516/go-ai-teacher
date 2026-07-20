import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/go_board.dart';
import '../widgets/win_rate_bar.dart';
import '../widgets/ai_suggestion.dart';
import '../services/game_service.dart';
import '../models/game_models.dart';
import '../models/analysis_data.dart';

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  final String _gameId = 'game_${DateTime.now().millisecondsSinceEpoch}';
  GameState? _gameState;
  AnalysisResult? _analysis;
  AnalysisData? _katagoAnalysis;
  bool _isLoading = false;
  bool _isAiThinking = false;
  bool _isAnalyzing = false;
  String _difficulty = 'medium';
  int _playerColor = 1;
  bool _showHints = false;
  bool _showAnalysis = false;
  String? _explanation;
  final TextEditingController _questionController = TextEditingController();
  int? _selectedX;
  int? _selectedY;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  Future<void> _initGame() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final game = await api.newGame(_gameId, boardSize: 19, komi: 6.5);
      setState(() => _gameState = game);
      if (_playerColor == 2) {
        await _makeAiMove();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectMove(int x, int y) {
    if (_gameState == null || _isAiThinking) return;
    if (_gameState!.currentPlayer != _playerColor) return;
    if (_gameState!.board[y][x] != 0) return;
    setState(() {
      _selectedX = x;
      _selectedY = y;
    });
  }

  Future<void> _confirmMove() async {
    if (_selectedX == null || _selectedY == null) return;
    final x = _selectedX!;
    final y = _selectedY!;
    setState(() {
      _selectedX = null;
      _selectedY = null;
      _isLoading = true;
    });
    try {
      final api = context.read<GameService>();
      final result = await api.playMove(_gameId, x, y, _playerColor);
      setState(() {
        _gameState = result['game'];
        _analysis = result['analysis'];
      });
      await _runKataGoAnalysis();
      await Future.delayed(const Duration(milliseconds: 300));
      await _makeAiMove();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _cancelSelection() {
    setState(() {
      _selectedX = null;
      _selectedY = null;
    });
  }

  Future<void> _makeAiMove() async {
    if (_gameState == null) return;
    setState(() => _isAiThinking = true);
    try {
      final api = context.read<GameService>();
      final aiColor = 3 - _playerColor;
      final result = await api.aiMove(_gameId, aiColor, difficulty: _difficulty);
      setState(() {
        _gameState = result['game'];
        _analysis = result['analysis'];
      });
      await _runKataGoAnalysis();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isAiThinking = false);
    }
  }

  Future<void> _runKataGoAnalysis() async {
    if (_gameState == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final api = context.read<GameService>();
      final analysis = await api.analyzeGame(
        _gameState!.moves,
        _gameState!.boardSize,
        _gameState!.currentPlayer,
      );
      setState(() => _katagoAnalysis = analysis);
    } catch (e) {
      setState(() => _katagoAnalysis = null);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _undoMove() async {
    if (_gameState == null) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final game = await api.undoMove(_gameId);
      setState(() => _gameState = game);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resign() async {
    if (_gameState == null || _gameState!.result != null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认认输'),
        content: const Text('确定要投子认输吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('认输'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final game = await api.resign(_gameId, _playerColor);
      setState(() => _gameState = game);
      _showResultDialog();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultDialog() {
    if (_gameState?.result == null) return;
    final isWin = _gameState!.winner == (_playerColor == 1 ? 'black' : 'white');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
              color: isWin ? Colors.amber : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(isWin ? '你赢了！' : '再接再厉'),
          ],
        ),
        content: Text(_gameState!.result!),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initGame();
            },
            child: const Text('再来一局'),
          ),
        ],
      ),
    );
  }

  Future<void> _explainLastMove() async {
    if (_gameState == null || _gameState!.moves.isEmpty) return;
    final lastMove = _gameState!.moves.last;
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final exp = await api.explainMove(
        _gameId,
        lastMove.move,
        _gameState!.moves.length,
        -2.5,
        '布局阶段',
      );
      setState(() => _explanation = exp.explanation);
      _showExplanationDialog();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showExplanationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF8B4513)),
            SizedBox(width: 8),
            Text('AI 老师讲解'),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(_explanation ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('明白了'),
          ),
        ],
      ),
    );
  }

  Future<void> _askQuestion() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('向 AI 老师提问'),
        content: TextField(
          controller: _questionController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '例如：这步棋为什么好？',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final q = _questionController.text;
              if (q.isEmpty) return;
              setState(() => _isLoading = true);
              try {
                final api = context.read<GameService>();
                final answer = await api.askQuestion(_gameId, '', q);
                setState(() => _explanation = answer);
                _showExplanationDialog();
              } catch (e) {
                _showError(e.toString());
              } finally {
                setState(() => _isLoading = false);
              }
              _questionController.clear();
            },
            child: const Text('提问'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016),
        title: const Text('AI 对弈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _askQuestion,
          ),
        ],
      ),
      body: _isLoading && _gameState == null
          ? const Center(child: CircularProgressIndicator())
          : _gameState == null
              ? const Center(child: Text('加载失败'))
              : _buildGameBody(),
      floatingActionButton: _gameState != null
          ? FloatingActionButton(
              onPressed: _runKataGoAnalysis,
              tooltip: 'AI分析',
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              child: _isAnalyzing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.analytics),
            )
          : null,
    );
  }

  Widget _buildGameBody() {
    final lastMove = _gameState!.moves.isNotEmpty ? _gameState!.moves.last : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPlayerInfo(),
          const SizedBox(height: 12),
          _buildAnalysisSection(),
          const SizedBox(height: 12),
          GoBoard(
            boardSize: _gameState!.boardSize,
            board: _gameState!.board,
            moves: _gameState!.moves,
            onTap: _selectMove,
            lastMoveX: lastMove?.x,
            lastMoveY: lastMove?.y,
            hintMoves: _showHints && _analysis != null
                ? _analysis!.topMoves.map((m) => m.move).toList()
                : null,
            moveWinRates: _showHints && _analysis != null
                ? {for (var m in _analysis!.topMoves) m.move: m.winRate}
                : null,
            selectedX: _selectedX,
            selectedY: _selectedY,
            selectedColor: _playerColor,
          ),
          const SizedBox(height: 12),
          if (_selectedX != null && _selectedY != null) _buildConfirmBar(),
          const SizedBox(height: 12),
          _buildGameInfo(),
          const SizedBox(height: 12),
          if (_showAnalysis && _analysis != null) _buildAnalysisPanel(),
          const SizedBox(height: 12),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    if (_isAnalyzing) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_katagoAnalysis == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'AI分析暂不可用',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        WinRateBar(
          winrate: _katagoAnalysis!.winrate,
          currentColor: _gameState!.currentPlayer,
        ),
        const SizedBox(height: 8),
        AISuggestion(
          analysis: _katagoAnalysis!,
          currentColor: _gameState!.currentPlayer,
        ),
      ],
    );
  }

  Widget _buildConfirmBar() {
    final letter = String.fromCharCode(_selectedX! < 8 ? 65 + _selectedX! : 65 + _selectedX! + 1);
    final moveLabel = '$letter${_gameState!.boardSize - _selectedY!}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE67E22)),
      ),
      child: Row(
        children: [
          Icon(Icons.radio_button_checked, color: _playerColor == 1 ? Colors.black : Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '已选 $moveLabel，确认落子？',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF8B4513),
              ),
            ),
          ),
          TextButton(
            onPressed: _cancelSelection,
            child: const Text('取消'),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: _isLoading ? null : _confirmMove,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('确认落子'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gameState!.currentPlayer == 1 ? const Color(0xFFE8F5E9) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gameState!.currentPlayer == 1
                    ? const Color(0xFF2D5016)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _playerColor == 1 ? '你' : 'AI 老师',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_analysis != null)
                        Text(
                          '黑胜率 ${_analysis!.winRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isAiThinking && _gameState!.currentPlayer != _playerColor)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _gameState!.currentPlayer == 2 ? const Color(0xFFFFF3E0) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gameState!.currentPlayer == 2
                    ? const Color(0xFF8B4513)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _playerColor == 2 ? '你' : 'AI 老师',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_analysis != null)
                        Text(
                          '贴目 ${_gameState!.komi}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_isAiThinking && _gameState!.currentPlayer == _playerColor)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _infoItem('手数', '${_gameState!.moves.length}'),
        _infoItem('贴目', '${_gameState!.komi}'),
        _infoItem('难度', _difficultyLabel),
      ],
    );
  }

  String get _difficultyLabel {
    switch (_difficulty) {
      case 'easy':
        return '入门';
      case 'medium':
        return '业余';
      case 'hard':
        return '职业';
      default:
        return '业余';
    }
  }

  Widget _infoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
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
          const Text(
            'AI 分析',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ..._analysis!.topMoves.take(3).map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        alignment: Alignment.center,
                        child: Text(
                          m.move,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5016),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 8,
                              width: (m.winRate / 100) * 200,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2D5016), Color(0xFF4A7C28)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${m.winRate.toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _controlButton(
                icon: Icons.undo,
                label: '悔棋',
                onTap: _undoMove,
                color: const Color(0xFF718096),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _controlButton(
                icon: Icons.lightbulb,
                label: _showHints ? '隐藏提示' : '显示提示',
                onTap: () => setState(() => _showHints = !_showHints),
                color: const Color(0xFFE67E22),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _controlButton(
                icon: Icons.analytics,
                label: _showAnalysis ? '隐藏分析' : 'AI分析',
                onTap: () => setState(() => _showAnalysis = !_showAnalysis),
                color: const Color(0xFF1E3A5F),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _controlButton(
                icon: Icons.flag,
                label: '认输',
                onTap: _resign,
                color: Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _explainLastMove,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 老师讲解这步棋'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text(
              '选择执棋：',
              style: TextStyle(fontSize: 14, color: Color(0xFF4A5568)),
            ),
            const SizedBox(width: 8),
            _colorSelector(1, '执黑'),
            const SizedBox(width: 8),
            _colorSelector(2, '执白'),
            const Spacer(),
            DropdownButton<String>(
              value: _difficulty,
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('入门')),
                DropdownMenuItem(value: 'medium', child: Text('业余')),
                DropdownMenuItem(value: 'hard', child: Text('职业')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _difficulty = v);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorSelector(int color, String label) {
    final selected = _playerColor == color;
    return GestureDetector(
      onTap: () {
        setState(() => _playerColor = color);
        _initGame();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2D5016) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2D5016)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color == 1 ? Colors.black : Colors.white,
                border: color == 2 ? Border.all(color: Colors.grey) : null,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : const Color(0xFF2D5016),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
