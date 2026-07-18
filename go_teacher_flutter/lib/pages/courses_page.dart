import 'package:flutter/material.dart';

class CoursesPage extends StatelessWidget {
  const CoursesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final courses = [
      _Course(
        title: '入门篇：认识围棋',
        level: '入门',
        lessons: 12,
        duration: '2小时',
        icon: '🌱',
        color: const Color(0xFF4CAF50),
        progress: 0.8,
      ),
      _Course(
        title: '基础篇：吃子技巧',
        level: '入门',
        lessons: 15,
        duration: '3小时',
        icon: '⚔️',
        color: const Color(0xFF2196F3),
        progress: 0.3,
      ),
      _Course(
        title: '进阶篇：死活基础',
        level: '初级',
        lessons: 20,
        duration: '4小时',
        icon: '🧩',
        color: const Color(0xFFFF9800),
        progress: 0.0,
      ),
      _Course(
        title: '布局入门',
        level: '初级',
        lessons: 18,
        duration: '3.5小时',
        icon: '🗺️',
        color: const Color(0xFF9C27B0),
        progress: 0.0,
      ),
      _Course(
        title: '定式大全',
        level: '中级',
        lessons: 30,
        duration: '6小时',
        icon: '📐',
        color: const Color(0xFFF44336),
        progress: 0.0,
      ),
      _Course(
        title: '中盘作战',
        level: '中级',
        lessons: 25,
        duration: '5小时',
        icon: '⚡',
        color: const Color(0xFF795548),
        progress: 0.0,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B4423),
        title: const Text('围棋课程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLearningPath(),
            const SizedBox(height: 24),
            _buildSectionTitle('推荐课程'),
            const SizedBox(height: 12),
            ...courses.map((c) => _CourseCard(course: c)),
            const SizedBox(height: 24),
            _buildLevelProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningPath() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D5016), Color(0xFF4A7C28)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '个性化学习路径',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '根据你的水平，AI老师为你定制了专属学习计划，按顺序学习效果最佳',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(height: 12),
                Text(
                  '当前：入门篇 · 第8课',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🎯', style: TextStyle(fontSize: 36)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const Text(
          '查看全部',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B4423),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgress() {
    final levels = [
      ('入门', 5, 5, true),
      ('初级', 2, 5, false),
      ('中级', 0, 5, false),
      ('高级', 0, 5, false),
    ];

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
            '等级进度',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: levels.map((l) {
                final (name, current, total, active) = l;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$current/$total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: active ? const Color(0xFF2D5016) : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 30 * (current / total).clamp(0.2, 1),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF2D5016)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? const Color(0xFF2D3748) : Colors.grey,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Course {
  final String title;
  final String level;
  final int lessons;
  final String duration;
  final String icon;
  final Color color;
  final double progress;

  _Course({
    required this.title,
    required this.level,
    required this.lessons,
    required this.duration,
    required this.icon,
    required this.color,
    required this.progress,
  });
}

class _CourseCard extends StatelessWidget {
  final _Course course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: course.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(course.icon, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: course.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.level,
                          style: TextStyle(
                            fontSize: 10,
                            color: course.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.play_circle_outline, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        '${course.lessons}课',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.timer, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        course.duration,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 4,
                            width: constraints.maxWidth * course.progress,
                            decoration: BoxDecoration(
                              color: course.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
