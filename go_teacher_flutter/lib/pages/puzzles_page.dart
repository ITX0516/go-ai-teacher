import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/game_models.dart';
import 'puzzle_detail_page.dart';

class PuzzlesPage extends StatefulWidget {
  const PuzzlesPage({super.key});

  @override
  State<PuzzlesPage> createState() => _PuzzlesPageState();
}

class _PuzzlesPageState extends State<PuzzlesPage> {
  List<Puzzle> _puzzles = [];
  bool _isLoading = true;
  String _selectedCategory = 'life_death';
  String _selectedDifficulty = '';

  final categories = const [
    ('life_death', '死活题', '🧩'),
    ('capture', '吃子技巧', '⚔️'),
    ('joseki', '定式', '📐'),
  ];

  final difficulties = const [
    ('', '全部'),
    ('beginner', '入门'),
    ('intermediate', '中级'),
    ('advanced', '高级'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPuzzles();
  }

  Future<void> _loadPuzzles() async {
    setState(() => _isLoading = true);
    try {
      final api = context.read<GameService>();
      final puzzles = await api.getPuzzles(
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
      );
      setState(() => _puzzles = puzzles);
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

  void _selectPuzzle(Puzzle puzzle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PuzzleDetailPage(puzzle: puzzle),
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
        title: const Text('死活题训练'),
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          _buildDifficultyFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildPuzzleList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: categories.map((cat) {
          final selected = _selectedCategory == cat.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = cat.$1);
                _loadPuzzles();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF8B4513) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF8B4513) : const Color(0xFFD7CCC8),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(cat.$3, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      cat.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : const Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultyFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: difficulties.map((d) {
          final selected = _selectedDifficulty == d.$1;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDifficulty = d.$1);
              _loadPuzzles();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF8B4513) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B4513)),
              ),
              child: Text(
                d.$2,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : const Color(0xFF8B4513),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPuzzleList() {
    if (_puzzles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('暂无题目'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _puzzles.length,
      itemBuilder: (context, index) {
        final puzzle = _puzzles[index];
        return GestureDetector(
          onTap: () => _selectPuzzle(puzzle),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _difficultyColor(puzzle.difficulty).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _difficultyColor(puzzle.difficulty),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        puzzle.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        puzzle.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF718096),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor(puzzle.difficulty),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _difficultyLabel(puzzle.difficulty),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
