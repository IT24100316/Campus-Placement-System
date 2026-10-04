import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'campus_ai_logo.dart';
import '../../features/notifications/data/student_notification_service.dart';
import '../../features/notifications/presentation/screens/notification_center_screen.dart';

class GlobalAppHeader extends StatefulWidget implements PreferredSizeWidget {
  const GlobalAppHeader({super.key});

  @override
  State<GlobalAppHeader> createState() => _GlobalAppHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _GlobalAppHeaderState extends State<GlobalAppHeader> {
  final _notificationService = StudentNotificationService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.unreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // A header must still render while a session is loading or unavailable.
    }
  }

  Future<void> _openNotificationCenter() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
    );
    _loadUnreadCount();
  }

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
            child: CampusAILogo(size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'CampusAI',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'STUDENT PORTAL',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Badge.count(
            count: _unreadCount,
            isLabelVisible: _unreadCount > 0,
            backgroundColor: Colors.red,
            child: const Icon(Icons.notifications_none),
          ),
          color: AppColors.textSecondaryLight,
          onPressed: _openNotificationCenter,
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

}

