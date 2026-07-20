import 'package:flutter/material.dart';

class WinRateBar extends StatelessWidget {
  final double winrate;
  final int currentColor;

  const WinRateBar({
    super.key,
    required this.winrate,
    required this.currentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blackWinRate = currentColor == 1 ? winrate : 1 - winrate;
    final whiteWinRate = 1 - blackWinRate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _playerIndicator(Colors.black, '黑'),
              const SizedBox(width: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    return SizedBox(
                      height: 16,
                      child: Stack(
                        children: [
                          Container(
                            height: 16,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Container(
                            height: 16,
                            width: maxWidth * blackWinRate,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.onSurface,
                                  theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          Positioned(
                            left: maxWidth * blackWinRate,
                            child: Container(
                              height: 16,
                              width: maxWidth * whiteWinRate,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey[300]!,
                                    Colors.grey[200]!,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              _playerIndicator(Colors.white, '白'),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '黑 ${(blackWinRate * 100).toStringAsFixed(0)}% | 白 ${(whiteWinRate * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerIndicator(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: color == Colors.white ? Border.all(color: Colors.grey) : null,
            boxShadow: [
              if (color == Colors.black)
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(1, 1),
                ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}