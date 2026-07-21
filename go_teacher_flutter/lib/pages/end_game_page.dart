import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_service.dart';
import '../models/game_models.dart';
import '../utils/sgf_exporter.dart';

class EndGamePage extends StatelessWidget {
  final GameState gameState;
  final ScoringResult? scoringResult;
  final int playerColor;
  final String gameId;

  const EndGamePage({
    super.key,
    required this.gameState,
    required this.playerColor,
    required this.gameId,
    this.scoringResult,
  });

  @override
  Widget build(BuildContext context) {
    final isWin = gameState.winner == (playerColor == 1 ? 'black' : 'white');
    final isDraw = gameState.winner == 'draw';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        title: const Text('对局结束'),
        backgroundColor: const Color(0xFF2D5016),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 胜负图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDraw
                    ? Colors.grey[300]
                    : (isWin ? Colors.amber[100] : Colors.blueGrey[100]),
              ),
              child: Icon(
                isDraw
                    ? Icons.handshake
                    : (isWin ? Icons.emoji_events : Icons.sentiment_dissatisfied),
                size: 56,
                color: isDraw
                    ? Colors.grey
                    : (isWin ? Colors.amber : Colors.blueGrey),
              ),
            ),
            const SizedBox(height: 24),
            // 胜负标题
            Text(
              isDraw ? '和棋' : (isWin ? '恭喜获胜！' : '再接再厉'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDraw
                    ? Colors.grey
                    : (isWin ? const Color(0xFF2D5016) : const Color(0xFF718096)),
              ),
            ),
            const SizedBox(height: 12),
            // 结果详情
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    gameState.result ?? '对局结束',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (scoringResult != null) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildScoreDetail(scoringResult!),
                  ] else if (gameState.endGameType == EndGameType.resign) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildResignDetail(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            // 操作按钮
            _buildActionButtons(context, isWin),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDetail(ScoringResult r) {
    return Column(
      children: [
        _detailRow('黑方', '${r.blackStones} 子 + ${r.blackTerritory} 目 = ${r.blackScore.toStringAsFixed(1)}', Colors.black),
        const SizedBox(height: 8),
        _detailRow('白方', '${r.whiteStones} 子 + ${r.whiteTerritory} 目 + ${r.komi.toStringAsFixed(1)} 贴目 = ${r.whiteScore.toStringAsFixed(1)}', const Color(0xFF8B4513)),
        const SizedBox(height: 8),
        _detailRow('胜负差', '${r.margin.toStringAsFixed(1)} 目', const Color(0xFF2D5016)),
      ],
    );
  }

  Widget _buildResignDetail() {
    return Column(
      children: [
        _detailRow(
          '终局方式',
          '认输',
          const Color(0xFF718096),
        ),
        const SizedBox(height: 8),
        _detailRow(
          '总手数',
          '${gameState.moves.length} 手',
          const Color(0xFF718096),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF718096))),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isWin) {
    return Column(
      children: [
        // 返回首页
        SizedBox(
          width: double.infinity,
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 保存棋谱
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _saveSgf(context),
            icon: const Icon(Icons.save_alt),
            label: const Text('保存棋谱（导出SGF）'),
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
        // AI复盘
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startAiReview(context),
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI 复盘'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
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

  void _saveSgf(BuildContext context) {
    final sgfResult = scoringResult != null
        ? generateSgfResult(
            gameState.endGameType ?? EndGameType.scoring,
            gameState.winner ?? 'draw',
            scoringResult!.margin,
          )
        : generateSgfResult(
            EndGameType.resign,
            gameState.winner ?? 'draw',
          );

    final sgf = gameToSgf(
      gameState,
      playerBlack: playerColor == 1 ? '玩家' : 'AI老师',
      playerWhite: playerColor == 2 ? '玩家' : 'AI老师',
      result: sgfResult,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('棋谱已生成（SGF格式）'),
        action: SnackBarAction(
          label: '查看',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('SGF 棋谱'),
                content: SingleChildScrollView(
                  child: SelectableText(sgf),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _startAiReview(BuildContext context) {
    // 导航到复盘页面
    Navigator.pushNamed(context, '/review', arguments: {
      'gameState': gameState,
      'gameId': gameId,
    });
  }
}