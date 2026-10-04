import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../applications/presentation/screens/applications_tracking_screen.dart';
import '../../../jobs/presentation/screens/job_feed_screen.dart';
import '../../../profile/presentation/screens/resume_hub_screen.dart';
import '../../../profile/presentation/screens/profile_settings_screen.dart';
import '../../data/student_notification_service.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final _service = StudentNotificationService();
  late Future<List<StudentNotification>> _notifications = _service.load();

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    if (mounted) setState(() => _notifications = _service.load());
  }

  Future<void> _open(StudentNotification notification) async {
    if (!notification.isRead) await _service.markRead(notification.id);
    if (!mounted) return;
    final destination = notification.destination;
    if (destination == 'applications') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ApplicationsTrackingScreen(),
      ));
    } else if (destination == 'jobs') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const JobFeedScreen(),
      ));
    } else if (destination == 'resume') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ResumeHubScreen(),
      ));
    } else if (destination == 'profile') {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const ProfileSettingsScreen(),
      ));
    }
    if (mounted) setState(() => _notifications = _service.load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
          ],
        ),
        body: FutureBuilder<List<StudentNotification>>(
          future: _notifications,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(() => _notifications = _service.load()),
                  child: const Text('Unable to load notifications. Try again.'),
                ),
              );
            }
            final notifications = snapshot.data ?? const [];
            if (notifications.isEmpty) {
              return const Center(
                child: Text('You are all caught up. No notifications yet.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Material(
                  color: notification.isRead ? Colors.white : const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    leading: Icon(_iconFor(notification.type), color: AppColors.primary),
                    title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(notification.message),
                    trailing: notification.isRead ? null : const Icon(Icons.circle, size: 10, color: AppColors.primary),
                    onTap: () => _open(notification),
                  ),
                );
              },
            );
          },
        ),
      );

  IconData _iconFor(String type) => switch (type) {
        'interview' => Icons.event_available_outlined,
        'action_required' => Icons.priority_high_rounded,
        'application_received' => Icons.task_alt_outlined,
        'password_updated' => Icons.lock_outline_rounded,
        'cv_uploaded' => Icons.upload_file_outlined,
        'cv_replacement_available' => Icons.update_outlined,
        'profile_complete' => Icons.person_check_outlined,
        'resume_complete' => Icons.description_outlined,
        _ => Icons.notifications_outlined,
      };
}
