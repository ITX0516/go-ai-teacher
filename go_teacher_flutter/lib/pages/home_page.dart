import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              _buildLearningProgress(context),
              const SizedBox(height: 24),
              _buildTodayPuzzle(context),
              const SizedBox(height: 24),
              _buildAchievements(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF2D5016), Color(0xFF4A7C28)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '欢迎回来，围棋爱好者',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 4),
              Text(
                '今日已连续学习 3 天 🔥',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD700),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.emoji_events, size: 16, color: Color(0xFF8B4513)),
              SizedBox(width: 4),
              Text(
                'Lv.5',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快速开始',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.play_circle_fill,
                title: 'AI 对弈',
                subtitle: '与AI老师下棋',
                color: const Color(0xFF2D5016),
                onTap: () {
                  Navigator.pushNamed(context, '/play');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.psychology,
                title: '死活题',
                subtitle: '每日一练',
                color: const Color(0xFF8B4513),
                onTap: () {
                  Navigator.pushNamed(context, '/puzzles');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.auto_awesome,
                title: '棋谱复盘',
                subtitle: 'AI 深度分析',
                color: const Color(0xFF1E3A5F),
                onTap: () {
                  Navigator.pushNamed(context, '/review');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.menu_book,
                title: '课程学习',
                subtitle: '分级教学',
                color: const Color(0xFF6B4423),
                onTap: () {
                  Navigator.pushNamed(context, '/courses');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLearningProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '学习进度',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                '查看详情',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProgressItem(
                icon: Icons.sports_esports,
                value: '12',
                label: '对弈局数',
                color: const Color(0xFF2D5016),
              ),
              _ProgressItem(
                icon: Icons.check_circle,
                value: '48',
                label: '解题数量',
                color: const Color(0xFF8B4513),
              ),
              _ProgressItem(
                icon: Icons.timer,
                value: '5.5h',
                label: '学习时长',
                color: const Color(0xFF1E3A5F),
              ),
              _ProgressItem(
                icon: Icons.local_fire_department,
                value: '3',
                label: '连续天数',
                color: const Color(0xFFE67E22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Container(
                      width: constraints.maxWidth * 0.35,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2D5016), Color(0xFF4A7C28)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '距离 Lv.6 还需 650 XP',
                style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
              ),
              Text(
                '350/1000 XP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D5016),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayPuzzle(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E7), Color(0xFFFFE4B5)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: _MiniBoardPainter(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '每日一题',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '中级死活题：倒扑的妙用',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '黑先，利用倒扑技巧吃子',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA0522D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements(BuildContext context) {
    final achievements = [
      ('🏆', '初出茅庐', '完成第一局对弈'),
      ('🔥', '坚持不懈', '连续学习7天'),
      ('🧩', '解题达人', '解决100道死活题'),
      ('⭐', '棋艺精进', '等级达到10级'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '成就徽章',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: achievements.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final (icon, title, desc) = achievements[index];
              final unlocked = index < 2;
              return Container(
                width: 80,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: unlocked
                            ? const Color(0xFFFFD700)
                            : const Color(0xFFCBD5E0),
                        boxShadow: unlocked
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(icon, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: unlocked
                            ? const Color(0xFF2D3748)
                            : const Color(0xFFA0AEC0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFA0AEC0),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _ProgressItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF718096),
          ),
        ),
      ],
    );
  }
}

class _MiniBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFDEB887);
    canvas.drawRect(Offset.zero & size, paint);

    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.5;

    final cellSize = size.width / 8;
    for (int i = 0; i < 9; i++) {
      final p = i * cellSize;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), linePaint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), linePaint);
    }

    final blackPaint = Paint()..color = Colors.black;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final whiteBorder = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final stoneR = cellSize * 0.4;

    canvas.drawCircle(Offset(2 * cellSize, 2 * cellSize), stoneR, blackPaint);
    canvas.drawCircle(Offset(3 * cellSize, 2 * cellSize), stoneR, whitePaint);
    canvas.drawCircle(Offset(3 * cellSize, 2 * cellSize), stoneR, whiteBorder);
    canvas.drawCircle(Offset(5 * cellSize, 3 * cellSize), stoneR, blackPaint);
    canvas.drawCircle(Offset(4 * cellSize, 4 * cellSize), stoneR, whitePaint);
    canvas.drawCircle(Offset(4 * cellSize, 4 * cellSize), stoneR, whiteBorder);
    canvas.drawCircle(Offset(2 * cellSize, 5 * cellSize), stoneR, blackPaint);
    canvas.drawCircle(Offset(6 * cellSize, 5 * cellSize), stoneR, whitePaint);
    canvas.drawCircle(Offset(6 * cellSize, 5 * cellSize), stoneR, whiteBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
