import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Shared top-left identity for authenticated student tabs.
class AuthenticatedBrandHeader extends StatelessWidget {
  const AuthenticatedBrandHeader({
    super.key,
    this.primaryColor = AppColors.primary,
    this.titleColor = AppColors.textPrimaryLight,
    this.subtitleColor = AppColors.textSecondaryLight,
  });

  final Color primaryColor;
  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.layers, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CampusAI Portal',
              style: TextStyle(
                color: titleColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Autonomous Placement',
              style: TextStyle(color: subtitleColor, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}
