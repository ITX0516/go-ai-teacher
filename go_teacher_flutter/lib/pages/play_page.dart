import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/go_board.dart';
import '../widgets/win_rate_bar.dart';
import '../widgets/game_info_bar.dart';
import '../widgets/bottom_tab_bar.dart';
import '../widgets/floating_game_buttons.dart';
import '../widgets/ai_chat_panel.dart';
import '../services/game_service.dart';
import '../services/chat_service.dart';
import '../models/game_models.dart';
import '../models/analysis_data.dart';
import '../utils/sgf_exporter.dart';
import 'score_page.dart';
import 'end_game_page.dart';

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
  int _activeTab = 1; // 0=聊天, 1=AI老师
  Duration _userTime = const Duration(minutes: 10);
  Duration _aiTime = const Duration(minutes: 10);

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
      });
      await _runKataGoAnalysis();
      // 检查AI是否有合法落子
      await _checkAndMakeAiMove();
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

  Future<void> _checkAndMakeAiMove() async {
    if (_gameState == null || _gameState!.result != null) return;
    final aiColor = 3 - _playerColor;
    try {
      final api = context.read<GameService>();
      final hasMoves = await api.hasLegalMoves(_gameId, aiColor);
      if (!hasMoves) {
        // AI无棋可下，提示
        _showNoMovesDialog(aiColor);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await _makeAiMove();
    } catch (e) {
      // 降级：直接尝试AI落子
      await _makeAiMove();
    }
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
      });
      await _runKataGoAnalysis();
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isAiThinking = false);
    }
  }

  AnalysisResult _convertKataGoToAnalysis(AnalysisData data) {
    return AnalysisResult(
      winRate: data.winrate * 100,
      scoreLead: data.scoreLead,
      topMoves: data.candidateMoves.take(5).map((c) => TopMove(
        move: c.move,
        winRate: c.winrate * 100,
        scoreLead: c.scoreLead,
        visits: c.visits,
        policy: 0.3,
      )).toList(),
      moveNumber: 0,
    );
  }

  Future<void> _runKataGoAnalysis() async {
    if (_gameState == null) return;
    setState(() => _isAnalyzing = true);
    try {
      final api = context.read<GameService>();
      final analysisData = await api.analyzeGame(
        _gameState!.moves,
        _gameState!.boardSize,
        _gameState!.currentPlayer,
      );
      setState(() {
        _katagoAnalysis = analysisData;
        _analysis = _convertKataGoToAnalysis(analysisData);
      });
    } catch (e) {
      setState(() {
        _katagoAnalysis = null;
        _analysis = null;
      });
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

  Future<void> _passMove() async {
    if (_gameState == null || _isAiThinking) return;
    if (_gameState!.currentPlayer != _playerColor) return;
    if (_gameState!.result != null) return;

    final passCount = _gameState!.consecutivePasses;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认停一手'),
        content: Text(passCount == 1
            ? '对方已停一手，你再停一手将触发数棋。\n确定要停一手吗？'
            : '确定要停一手（虚着）吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('停一手'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final result = await api.pass(_gameId, _playerColor);
      setState(() {
        _gameState = result['game'];
      });

      final shouldEndGame = result['shouldEndGame'] as bool? ?? false;
      if (shouldEndGame) {
        // 双方各Pass一次，弹出申请数棋
        _showScoringDialog();
        return;
      }

      // AI回合
      await _checkAndMakeAiMoveAfterPass();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkAndMakeAiMoveAfterPass() async {
    if (_gameState == null || _gameState!.result != null) return;
    final aiColor = 3 - _playerColor;
    try {
      final api = context.read<GameService>();
      final hasMoves = await api.hasLegalMoves(_gameId, aiColor);
      if (!hasMoves) {
        _showNoMovesDialog(aiColor);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      // AI也选择Pass或落子
      final result = await api.aiMove(_gameId, aiColor, difficulty: _difficulty);
      setState(() {
        _gameState = result['game'];
      });
      await _runKataGoAnalysis();

      // 检查是否触发了双方Pass
      if (_gameState!.consecutivePasses >= 2) {
        _showScoringDialog();
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showScoringDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.calculate, color: Color(0xFF2D5016)),
            SizedBox(width: 8),
            Text('申请数棋'),
          ],
        ),
        content: const Text('双方都已停一手，是否进入数棋模式判定胜负？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _continuePlaying();
            },
            child: const Text('继续对局'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enterScoringMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
            ),
            child: const Text('申请数棋'),
          ),
        ],
      ),
    );
  }

  void _continuePlaying() {
    // 重置连续Pass计数（实际上通过继续落子自动重置）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('继续对局，Pass计数将在下次落子时重置')),
    );
  }

  void _enterScoringMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScorePage(
          gameId: _gameId,
          gameState: _gameState!,
          playerColor: _playerColor,
        ),
      ),
    ).then((result) {
      if (result is ScoringResult) {
        // 数棋完成，进入终局页
        _navigateToEndGame(result);
      }
    });
  }

  void _showNoMovesDialog(int color) {
    final colorName = color == GoStone.black ? '黑方' : '白方';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('无棋可下'),
          ],
        ),
        content: Text('$colorName已无合法落子点，是否进入数棋模式？'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enterScoringMode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
            ),
            child: const Text('数棋'),
          ),
        ],
      ),
    );
  }

  Future<void> _resign() async {
    if (_gameState == null || _gameState!.result != null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.flag, color: Colors.red),
            SizedBox(width: 8),
            Text('确认认输'),
          ],
        ),
        content: const Text('确定要投子认输吗？认输后将直接结束本局。'),
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
      _navigateToEndGame(null);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEndGame(ScoringResult? scoringResult) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EndGamePage(
          gameState: _gameState!,
          playerColor: _playerColor,
          gameId: _gameId,
          scoringResult: scoringResult,
        ),
      ),
    );
  }

  Future<void> _explainLastMove() async {
    if (_gameState == null || _gameState!.moves.isEmpty) return;
    final lastMove = _gameState!.moves.last;
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final sgf = gameToSgf(
        _gameState!,
        playerBlack: '玩家',
        playerWhite: 'AI老师',
      );
      debugPrint('===== AI 讲解 SGF =====');
      debugPrint(sgf);
      debugPrint('=======================');

      final areas = <Map<String, String>>[];
      if (_katagoAnalysis != null) {
        areas.add({
          'location': '全局形势',
          'desc': '当前胜率 ${(_katagoAnalysis!.winrate * 100).toStringAsFixed(1)}%，目差 ${_katagoAnalysis!.scoreLead.toStringAsFixed(1)} 目',
        });
      }

      final exp = await api.explainMove(
        _gameId,
        lastMove.move,
        _gameState!.moves.length,
        -2.5,
        sgf,
        winRate: _katagoAnalysis != null ? _katagoAnalysis!.winrate * 100 : null,
        scoreLead: _katagoAnalysis?.scoreLead,
        currentTurn: _gameState!.currentPlayer == GoStone.black ? '黑棋' : '白棋',
        areas: areas.isNotEmpty ? areas : null,
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            tooltip: '更多操作',
            onSelected: (value) {
              switch (value) {
                case 'pass':
                  _passMove();
                  break;
                case 'undo':
                  _undoMove();
                  break;
                case 'hint':
                  setState(() => _showHints = !_showHints);
                  break;
                case 'explain':
                  _explainLastMove();
                  break;
                case 'black':
                  if (_playerColor != 1) {
                    setState(() => _playerColor = 1);
                    _initGame();
                  }
                  break;
                case 'white':
                  if (_playerColor != 2) {
                    setState(() => _playerColor = 2);
                    _initGame();
                  }
                  break;
                case 'easy':
                  setState(() => _difficulty = 'easy');
                  break;
                case 'medium':
                  setState(() => _difficulty = 'medium');
                  break;
                case 'hard':
                  setState(() => _difficulty = 'hard');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'pass', child: Text('停一手 (Pass)')),
              const PopupMenuItem(value: 'undo', child: Text('悔棋')),
              PopupMenuItem(
                value: 'hint',
                child: Text(_showHints ? '隐藏提示' : '显示提示'),
              ),
              const PopupMenuItem(value: 'explain', child: Text('AI 老师讲解这步棋')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'black', child: Text('执黑')),
              const PopupMenuItem(value: 'white', child: Text('执白')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'easy', child: Text('难度：入门')),
              const PopupMenuItem(value: 'medium', child: Text('难度：业余')),
              const PopupMenuItem(value: 'hard', child: Text('难度：职业')),
            ],
          ),
        ],
      ),
      body: _isLoading && _gameState == null
          ? const Center(child: CircularProgressIndicator())
          : _gameState == null
              ? const Center(child: Text('加载失败'))
              : _buildGameBody(),
    );
  }

  Widget _buildGameBody() {
    final lastMove = _gameState!.moves.isNotEmpty ? _gameState!.moves.last : null;
    final screenHeight = MediaQuery.of(context).size.height;
    // 棋盘至少保留 45% 屏幕高度
    final minBoardHeight = screenHeight * 0.45;

    return Column(
      children: [
        // 顶部：对局信息栏（野狐风格）
        GameInfoBar(
          userName: _playerColor == 1 ? '你' : 'AI老师',
          userRank: '业余3段',
          userTime: _userTime,
          aiName: _playerColor == 2 ? '你' : 'AI老师',
          aiRank: '职业九段',
          aiTime: _aiTime,
          moveCount: _gameState!.moves.length,
          currentPlayer: _gameState!.currentPlayer,
        ),
        // 中间：棋盘 + 浮动按钮 + 辅助信息（可滚动）
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minBoardHeight),
                  child: Stack(
                    children: [
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
                      FloatingGameButtons(
                        unreadAnalysisCount:
                            context.watch<ChatService>().unreadAnalysisCount,
                        onAnalysisTap: () {
                          context.read<ChatService>().clearAnalysisCount();
                          _showAnalysisPanel();
                        },
                        onHintTap: () =>
                            setState(() => _showHints = !_showHints),
                        isHintActive: _showHints,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildAnalysisSection(),
                const SizedBox(height: 8),
                if (_selectedX != null && _selectedY != null) ...[
                  _buildConfirmBar(),
                  const SizedBox(height: 8),
                ],
                _buildGameInfo(),
                const SizedBox(height: 8),
                if (_showAnalysis && _analysis != null) ...[
                  _buildAnalysisPanel(),
                  const SizedBox(height: 8),
                ],
                _buildControls(),
              ],
            ),
          ),
        ),
        // 底部：聊天 / AI老师 Tab 栏
        BottomTabBar(
          activeIndex: _activeTab,
          onTabChanged: (index) {
            setState(() => _activeTab = index);
            if (index == 1) {
              // AI老师 tab
              _showAnalysisPanel();
            } else if (index == 0) {
              // 聊天 tab：同样打开面板查看历史聊天
              _showAnalysisPanel();
            }
          },
        ),
      ],
    );
  }

  /// 弹出 AI 老师聊天面板（DraggableScrollableSheet）
  void _showAnalysisPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.45,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        builder: (context, scrollController) => AiChatPanel(
          gameId: _gameId,
          getSgf: () => gameToSgf(
            _gameState!,
            playerBlack: '玩家',
            playerWhite: 'AI老师',
          ),
          getKataGoData: () => _buildKataGoPayload(),
        ),
      ),
    );
  }

  /// 把当前 KataGo 分析结果打包成后端需要的字段
  /// 后端字段：moveNumber, winrate, winrateChange, bestMove, scoreLead, currentPlayer, candidateMoves
  /// 如果没有 KataGo 数据返回 null（不传 kataGoData 字段）
  Map<String, dynamic>? _buildKataGoPayload() {
    final k = _katagoAnalysis;
    final gs = _gameState;
    if (k == null) return null;
    final moveNumber = gs?.moves.length ?? 0;
    final currentPlayer = gs != null
        ? (gs.currentPlayer == 1 ? 'black' : 'white')
        : 'black';
    return <String, dynamic>{
      'moveNumber': moveNumber,
      'winrate': k.winrate,
      'bestMove': k.bestMove,
      'scoreLead': k.scoreLead,
      'currentPlayer': currentPlayer,
      'candidateMoves': k.candidateMoves.map((c) => {
            'move': c.move,
            'winrate': c.winrate,
          }).toList(),
    };
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

    return WinRateBar(
      winrate: _katagoAnalysis!.winrate,
      currentColor: _gameState!.currentPlayer,
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

  Widget _buildGameInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _infoItem('手数', '${_gameState!.moves.length}'),
        _infoItem('贴目', '${_gameState!.komi}'),
        _infoItem('难度', _difficultyLabel),
        if (_gameState!.consecutivePasses > 0)
          _infoItem('停手', '${_gameState!.consecutivePasses}/2'),
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
    final canShowScoring = _gameState!.consecutivePasses >= 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          // 认输
          Expanded(
            child: _controlButton(
              icon: Icons.flag,
              label: '认输',
              onTap: _resign,
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          // 数棋（仅在 consecutivePasses>=2 时高亮）
          Expanded(
            child: _controlButton(
              icon: Icons.calculate,
              label: canShowScoring
                  ? '数棋(${_gameState!.consecutivePasses}/2)'
                  : '数棋',
              onTap: canShowScoring
                  ? _enterScoringMode
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('需要双方各停一手后才能数棋')),
                      );
                    },
              color: canShowScoring
                  ? const Color(0xFF2D5016)
                  : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 8),
          // 形势（toggle _showAnalysis）
          Expanded(
            child: _controlButton(
              icon: Icons.analytics,
              label: _showAnalysis ? '隐藏形势' : '形势',
              onTap: () => setState(() => _showAnalysis = !_showAnalysis),
              color: const Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(width: 8),
          // 更多（显示 AI 老师面板）
          Expanded(
            child: _controlButton(
              icon: Icons.more_horiz,
              label: '更多',
              onTap: _showAnalysisPanel,
              color: const Color(0xFF8B4513),
            ),
          ),
        ],
      ),
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
}
