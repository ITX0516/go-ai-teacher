import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/go_board.dart';
import '../services/game_service.dart';
import '../models/game_models.dart';

class PuzzleDetailPage extends StatefulWidget {
  final Puzzle puzzle;

  const PuzzleDetailPage({super.key, required this.puzzle});

  @override
  State<PuzzleDetailPage> createState() => _PuzzleDetailPageState();
}

class _PuzzleDetailPageState extends State<PuzzleDetailPage> {
  late List<List<int>> _currentBoard;
  late List<MoveRecord> _currentMoves;
  String? _feedback;
  bool _isCorrect = false;
  int? _selectedX;
  int? _selectedY;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    final puzzle = widget.puzzle;
    final board = List.generate(puzzle.boardSize, (_) => List.filled(puzzle.boardSize, 0));
    final moves = <MoveRecord>[];
    for (final stone in puzzle.initialStones) {
      board[stone.y][stone.x] = stone.color;
      moves.add(stone);
    }
    setState(() {
      _currentBoard = board;
      _currentMoves = moves;
      _feedback = null;
      _isCorrect = false;
      _selectedX = null;
      _selectedY = null;
    });
  }

  void _selectMove(int x, int y) {
    if (_isCorrect) return;
    if (_currentBoard[y][x] != 0) return;
    setState(() {
      _selectedX = x;
      _selectedY = y;
    });
  }

  Future<void> _confirmMove() async {
    if (_selectedX == null || _selectedY == null) return;
    final x = _selectedX!;
    final y = _selectedY!;

    final letter = String.fromCharCode(x < 8 ? 65 + x : 65 + x + 1);
    final moveStr = '$letter${widget.puzzle.boardSize - y}';

    final board = List.generate(_currentBoard.length, (i) => List<int>.from(_currentBoard[i]));
    board[y][x] = 1;
    setState(() {
      _selectedX = null;
      _selectedY = null;
      _currentBoard = board;
      _currentMoves = [..._currentMoves, MoveRecord(x: x, y: y, color: 1, move: moveStr)];
    });

    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final result = await api.checkPuzzleAnswer(widget.puzzle.id, moveStr);
      setState(() {
        _feedback = result['explanation'];
        _isCorrect = result['correct'];
      });
    } catch (e) {
      setState(() {
        _feedback = '检查答案时出错: $e';
        _isCorrect = false;
      });
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

  void _showSolution() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('题目解析'),
        content: Text(widget.puzzle.solution),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _difficultyLabel(String d) {
    switch (d) {
      case 'beginner':
        return '入门';
      case 'intermediate':
        return '中级';
      case 'advanced':
        return '高级';
      default:
        return d;
    }
  }

  String _categoryLabel(String c) {
    switch (c) {
      case 'life_death':
        return '死活题';
      case 'capture':
        return '吃子技巧';
      case 'joseki':
        return '定式';
      default:
        return c;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        title: Text(widget.puzzle.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPuzzleInfo(),
            const SizedBox(height: 16),
            GoBoard(
              boardSize: widget.puzzle.boardSize,
              board: _currentBoard,
              moves: _currentMoves,
              onTap: _selectMove,
              selectedX: _selectedX,
              selectedY: _selectedY,
              selectedColor: 1,
            ),
            const SizedBox(height: 12),
            if (_selectedX != null && _selectedY != null) _buildConfirmBar(),
            const SizedBox(height: 12),
            if (_feedback != null) _buildFeedback(),
            const SizedBox(height: 16),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _difficultyColor(widget.puzzle.difficulty),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _difficultyLabel(widget.puzzle.difficulty),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _categoryLabel(widget.puzzle.category),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.puzzle.description,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmBar() {
    final letter = String.fromCharCode(_selectedX! < 8 ? 65 + _selectedX! : 65 + _selectedX! + 1);
    final moveLabel = '$letter${widget.puzzle.boardSize - _selectedY!}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE67E22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked, color: Colors.black),
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
              backgroundColor: const Color(0xFF8B4513),
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

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _isCorrect ? '回答正确！' : '还需努力',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _feedback ?? '',
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _resetBoard,
            icon: const Icon(Icons.refresh),
            label: const Text('重置'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showSolution,
            icon: const Icon(Icons.lightbulb),
            label: const Text('查看答案'),
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
      ],
    );
  }
}
