import 'package:flutter/material.dart';

/// 底部 Tab 栏（聊天/AI老师）
class BottomTabBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabChanged;

  const BottomTabBar({
    super.key,
    required this.activeIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _tabItem('聊天', 0, Icons.chat_bubble_outline),
          _tabItem('AI老师', 1, Icons.school_outlined),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index, IconData icon) {
    final isActive = activeIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? const Color(0xFF2D5016) : const Color(0xFF9E9E9E),
            ),
            const SizedBox(height: 2),
            Stack(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? const Color(0xFF2D5016) : const Color(0xFF9E9E9E),
                  ),
                ),
                if (isActive)
                  Positioned(
                    bottom: -3,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5016),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
