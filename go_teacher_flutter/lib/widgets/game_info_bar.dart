import 'package:flutter/material.dart';

/// 顶部对局信息栏（野狐围棋风格）
class GameInfoBar extends StatelessWidget {
  final String userName;
  final String userRank;
  final Duration userTime;
  final String aiName;
  final String aiRank;
  final Duration aiTime;
  final int moveCount;
  final int currentPlayer;

  const GameInfoBar({
    super.key,
    required this.userName,
    required this.userRank,
    required this.userTime,
    required this.aiName,
    required this.aiRank,
    required this.aiTime,
    required this.moveCount,
    required this.currentPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final userActive = currentPlayer == 1;
    final aiActive = currentPlayer == 2;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：用户
          Expanded(
            child: _playerInfo(
              name: userName,
              rank: userRank,
              time: userTime,
              isActive: userActive,
              isBlack: true,
            ),
          ),
          // 中间：VS + 手数 + 行棋方
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '第 $moveCount 手',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF718096),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  currentPlayer == 1 ? '黑方行棋' : '白方行棋',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
              ),
            ],
          ),
          // 右侧：AI
          Expanded(
            child: _playerInfo(
              name: aiName,
              rank: aiRank,
              time: aiTime,
              isActive: aiActive,
              isBlack: false,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerInfo({
    required String name,
    required String rank,
    required Duration time,
    required bool isActive,
    required bool isBlack,
    bool alignEnd = false,
  }) {
    final minutes = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = time.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!alignEnd) _avatar(isBlack, isActive),
        if (!alignEnd) const SizedBox(width: 8),
        Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF2D5016) : const Color(0xFF4A5568),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    rank,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF8B4513)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '$minutes:$seconds',
              style: TextStyle(
                fontSize: 12,
                color: isActive ? Colors.red : const Color(0xFF9E9E9E),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        if (alignEnd) const SizedBox(width: 8),
        if (alignEnd) _avatar(isBlack, isActive),
      ],
    );
  }

  Widget _avatar(bool isBlack, bool isActive) {
    return Stack(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: isBlack
                  ? [const Color(0xFF666666), Colors.black]
                  : [Colors.white, const Color(0xFFE0E0E0)],
            ),
            border: isActive
                ? Border.all(color: const Color(0xFF2D5016), width: 2.5)
                : null,
          ),
        ),
        if (isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
