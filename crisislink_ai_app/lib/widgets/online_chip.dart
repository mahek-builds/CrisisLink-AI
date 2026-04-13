import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OnlineChip extends StatelessWidget {
  const OnlineChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF071A10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.wifi_rounded, color: AppTheme.success, size: 16),
          SizedBox(width: 8),
          Text(
            'Online',
            style: TextStyle(
              color: Color(0xFFB4F7CF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
