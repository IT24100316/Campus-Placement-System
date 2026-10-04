import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class GlobalAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const GlobalAppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'CampusAI Portal',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Autonomous Placement',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Badge(
            backgroundColor: Colors.red,
            child: Icon(Icons.notifications_none),
          ),
          color: AppColors.textSecondaryLight,
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 16, left: 4),
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified, color: AppColors.primary, size: 14),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
