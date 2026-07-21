import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/game_models.dart';

class ScorePage extends StatefulWidget {
  final String gameId;
  final GameState gameState;
  final int playerColor;

  const ScorePage({
    super.key,
    required this.gameId,
    required this.gameState,
    required this.playerColor,
  });

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  List<List<int>>? _territoryMap;
  List<(int, int)> _deadStones = [];
  bool _isLoading = false;
  ScoringResult? _result;

  @override
  void initState() {
    super.initState();
    _loadScoringData();
  }

  Future<void> _loadScoringData() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final data = await api.getScoringData(widget.gameId);
      setState(() {
        _territoryMap = (data['territoryMap'] as List)
            .map((row) => (row as List).map((e) => e as int).toList())
            .toList();
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleDeadStone(int x, int y) {
    if (_result != null) return;
    if (widget.gameState.board[y][x] == GoStone.empty) return;

    setState(() {
      final index = _deadStones.indexWhere((s) => s.$1 == x && s.$2 == y);
      if (index >= 0) {
        _deadStones.removeAt(index);
      } else {
        _deadStones.add((x, y));
      }
    });
  }

  Future<void> _confirmDeadStones() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final result = await api.confirmDeadStones(widget.gameId, _deadStones);
      setState(() => _result = result);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_result != null ? '数棋结果' : '数棋中 - 请点击死子'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: _result == null,
      ),
      body: _isLoading && _territoryMap == null
          ? const Center(child: CircularProgressIndicator())
          : _result != null
              ? _buildResultView()
              : _buildScoringView(),
    );
  }

  Widget _buildScoringView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFFFF8E7),
          child: Column(
            children: [
              const Text(
                '数棋模式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '点击棋盘上的死子进行标记（已标记 ${_deadStones.length} 个）',
                style: const TextStyle(color: Color(0xFF718096), fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _legendItem(Colors.black54, '黑领地'),
                  const SizedBox(width: 16),
                  _legendItem(Colors.white70, '白领地'),
                  const SizedBox(width: 16),
                  _legendItem(Colors.red, '死子标记'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildScoringBoard(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _confirmDeadStones,
              icon: const Icon(Icons.check_circle),
              label: const Text('确认死子，计算结果'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.grey),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildScoringBoard() {
    final boardSize = widget.gameState.boardSize;
    final board = widget.gameState.board;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        final cellSize = size / (boardSize + 1);
        final stoneSize = cellSize * 0.9;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8C88B), Color(0xFFDDB26E)],
            ),
          ),
          child: Stack(
            children: [
              // 棋盘线
              CustomPaint(
                size: Size(size, size),
                painter: _ScoringBoardPainter(
                  boardSize: boardSize,
                  cellSize: cellSize,
                ),
              ),
              // 领地着色
              if (_territoryMap != null)
                ..._buildTerritoryOverlay(cellSize),
              // 棋子
              ..._buildStones(board, cellSize, stoneSize),
              // 死子标记
              ..._buildDeadStoneMarks(cellSize, stoneSize),
              // 点击区域
              _buildTapLayer(cellSize),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTerritoryOverlay(double cellSize) {
    final widgets = <Widget>[];
    final boardSize = widget.gameState.boardSize;
    final offset = cellSize / 2;

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        final territory = _territoryMap![y][x];
        if (territory == GoStone.empty) continue;

        final left = offset + x * cellSize - cellSize / 2;
        final top = offset + y * cellSize - cellSize / 2;

        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: Container(
              width: cellSize,
              height: cellSize,
              color: territory == GoStone.black
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.5),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildStones(List<List<int>> board, double cellSize, double stoneSize) {
    final widgets = <Widget>[];
    final boardSize = widget.gameState.boardSize;
    final offset = cellSize / 2;

    for (int y = 0; y < boardSize; y++) {
      for (int x = 0; x < boardSize; x++) {
        final stone = board[y][x];
        if (stone == GoStone.empty) continue;

        final left = offset + x * cellSize - stoneSize / 2;
        final top = offset + y * cellSize - stoneSize / 2;

        widgets.add(
          Positioned(
            left: left,
            top: top,
            child: Container(
              width: stoneSize,
              height: stoneSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.35, -0.35),
                  colors: stone == GoStone.black
                      ? [const Color(0xFF666666), const Color(0xFF1A1A1A), Colors.black]
                      : [Colors.white, const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
                ),
                border: stone == GoStone.white
                    ? Border.all(color: const Color(0xFFBDBDBD), width: 0.8)
                    : null,
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  List<Widget> _buildDeadStoneMarks(double cellSize, double stoneSize) {
    final widgets = <Widget>[];
    final offset = cellSize / 2;

    for (final (x, y) in _deadStones) {
      final left = offset + x * cellSize - stoneSize / 2;
      final top = offset + y * cellSize - stoneSize / 2;

      widgets.add(
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: stoneSize,
            height: stoneSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: const Center(
              child: Icon(
                Icons.close,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildTapLayer(double cellSize) {
    final boardSize = widget.gameState.boardSize;
    final offset = cellSize / 2;

    return GestureDetector(
      onTapUp: (details) {
        final dx = details.localPosition.dx - offset;
        final dy = details.localPosition.dy - offset;
        final x = (dx / cellSize).round();
        final y = (dy / cellSize).round();
        if (x >= 0 && x < boardSize && y >= 0 && y < boardSize) {
          _toggleDeadStone(x, y);
        }
      },
      behavior: HitTestBehavior.translucent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
      ),
    );
  }

  Widget _buildResultView() {
    final r = _result!;
    final isPlayerWin = r.winner == (widget.playerColor == 1 ? 'black' : 'white');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(
            isPlayerWin ? Icons.emoji_events : Icons.sentiment_dissatisfied,
            size: 64,
            color: isPlayerWin ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            r.resultString,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
          const SizedBox(height: 32),
          _buildScoreCard(r),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/',
                    (route) => false,
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('返回首页'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5016),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 导出SGF并返回
                    Navigator.pop(context, _result);
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('保存棋谱'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(ScoringResult r) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _scoreRow('黑方子数', '${r.blackStones}', Colors.black),
            const Divider(),
            _scoreRow('黑方领地', '${r.blackTerritory}', Colors.black54),
            const Divider(),
            _scoreRow('黑方总分', r.blackScore.toStringAsFixed(1), const Color(0xFF2D5016)),
            const SizedBox(height: 16),
            _scoreRow('白方子数', '${r.whiteStones}', Colors.grey),
            const Divider(),
            _scoreRow('白方领地', '${r.whiteTerritory}', Colors.grey[400]!),
            const Divider(),
            _scoreRow('贴目', r.komi.toStringAsFixed(1), Colors.orange),
            const Divider(),
            _scoreRow('白方总分', r.whiteScore.toStringAsFixed(1), const Color(0xFF8B4513)),
          ],
        ),
      ),
    );
  }

  Widget _scoreRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Color(0xFF4A5568))),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ScoringBoardPainter extends CustomPainter {
  final int boardSize;
  final double cellSize;

  _ScoringBoardPainter({required this.boardSize, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF2D1810)
      ..strokeWidth = 0.8;

    final offset = cellSize / 2;

    for (int i = 0; i < boardSize; i++) {
      final pos = offset + i * cellSize;
      canvas.drawLine(Offset(offset, pos), Offset(offset + (boardSize - 1) * cellSize, pos), linePaint);
      canvas.drawLine(Offset(pos, offset), Offset(pos, offset + (boardSize - 1) * cellSize), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}