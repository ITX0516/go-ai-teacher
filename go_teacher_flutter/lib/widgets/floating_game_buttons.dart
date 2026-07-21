import 'package:flutter/material.dart';

/// 右侧浮动按钮组件
/// 包含"分析"和"提示"两个圆形半透明按钮
class FloatingGameButtons extends StatelessWidget {
  final int unreadAnalysisCount;
  final VoidCallback onAnalysisTap;
  final VoidCallback onHintTap;
  final bool isHintActive;

  const FloatingGameButtons({
    super.key,
    required this.unreadAnalysisCount,
    required this.onAnalysisTap,
    required this.onHintTap,
    this.isHintActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      top: 0,
      bottom: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 分析按钮
          Stack(
            children: [
              _circleButton(
                icon: Icons.search,
                color: const Color(0xFF1E88E5),
                onTap: onAnalysisTap,
              ),
              if (unreadAnalysisCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadAnalysisCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 提示按钮
          _circleButton(
            icon: Icons.lightbulb,
            color: isHintActive
                ? const Color(0xFFFF9800)
                : const Color(0xFF9C27B0),
            onTap: onHintTap,
            isActive: isHintActive,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: isActive ? 0.9 : 0.6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
