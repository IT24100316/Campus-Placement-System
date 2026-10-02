import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../widgets/dashboard_components.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenApplications,
  });

  final ValueChanged<int> onNavigate;
  final ValueChanged<int> onOpenApplications;

  void _showPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label will be available soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final pagePadding = width < 360 ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pagePadding, 18, pagePadding, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _Header(onNotificationsTap: () => _showPlaceholder(context, 'Notifications')),
                    const SizedBox(height: 24),
                    _ReadinessCard(onProfileTap: () => onNavigate(3)),
                    const SizedBox(height: 28),
                    const DashboardSectionTitle(title: 'Application status'),
                    const SizedBox(height: 12),
                    _ApplicationStatusPanel(onOpenApplications: onOpenApplications),
                    const SizedBox(height: 28),
                    const DashboardSectionTitle(title: 'Quick actions'),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: width < 360 ? 1.52 : 1.7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        QuickActionItem(icon: Icons.assignment_outlined, label: 'View Applications', onTap: () => onOpenApplications(0)),
                        QuickActionItem(icon: Icons.person_outline, label: 'Update Profile', onTap: () => onNavigate(3)),
                        QuickActionItem(icon: Icons.upload_file_outlined, label: 'Manage CV', onTap: () => onNavigate(1)),
                        QuickActionItem(icon: Icons.notifications_none_rounded, label: 'View Notifications', onTap: () => _showPlaceholder(context, 'Notifications')),
                      ],
                    ),
                    const SizedBox(height: 28),
                    DashboardSectionTitle(title: 'Upcoming events', actionLabel: 'View all', onAction: () => _showPlaceholder(context, 'All events')),
                    const SizedBox(height: 4),
                    _SurfaceCard(
                      child: Column(
                        children: [
                          DashboardEventItem(icon: Icons.video_call_outlined, title: 'ABC Tech - Technical interview', dateTime: 'Today, 2:30 PM', iconColor: const Color(0xFF2563EB), badge: 'Today', badgeColor: const Color(0xFFDBEAFE), badgeTextColor: const Color(0xFF1D4ED8), onTap: () => _showPlaceholder(context, 'Interview details')),
                          const Divider(height: 1, color: AppColors.borderLight),
                          DashboardEventItem(icon: Icons.groups_outlined, title: 'Placement readiness workshop', dateTime: 'Thu, 10:00 AM', iconColor: const Color(0xFF7C3AED), badge: 'Workshop', badgeColor: const Color(0xFFF3E8FF), badgeTextColor: const Color(0xFF7E22CE), onTap: () => _showPlaceholder(context, 'Workshop details')),
                          const Divider(height: 1, color: AppColors.borderLight),
                          DashboardEventItem(icon: Icons.assignment_late_outlined, title: 'Apex Systems assessment', dateTime: 'Oct 18, 9:00 AM', iconColor: const Color(0xFFD97706), badge: 'Upcoming', badgeColor: const Color(0xFFFFF7E6), badgeTextColor: const Color(0xFFB45309), onTap: () => _showPlaceholder(context, 'Assessment details')),
                          const Divider(height: 1, color: AppColors.borderLight),
                          DashboardEventItem(icon: Icons.schedule_outlined, title: 'CV verification deadline', dateTime: 'Oct 21, 5:00 PM', iconColor: const Color(0xFFDC2626), badge: 'Deadline', badgeColor: const Color(0xFFFEE2E2), badgeTextColor: const Color(0xFFB91C1C), onTap: () => onNavigate(1)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const DashboardSectionTitle(title: 'Recent activity'),
                    const SizedBox(height: 12),
                    _SurfaceCard(
                      child: const Column(
                        children: [
                          DashboardActivityItem(icon: Icons.star_rounded, message: 'You were shortlisted by ABC Tech', time: '35 minutes ago', iconColor: Color(0xFFF59E0B)),
                          DashboardActivityItem(icon: Icons.check_circle_outline_rounded, message: 'Your profile was updated successfully', time: 'Yesterday', iconColor: Color(0xFF10B981)),
                          DashboardActivityItem(icon: Icons.calendar_month_outlined, message: 'New interview schedule received', time: '2 days ago', iconColor: Color(0xFF2563EB), isLast: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationStatusPanel extends StatefulWidget {
  const _ApplicationStatusPanel({required this.onOpenApplications});

  final ValueChanged<int> onOpenApplications;

  @override
  State<_ApplicationStatusPanel> createState() => _ApplicationStatusPanelState();
}

class _ApplicationStatusPanelState extends State<_ApplicationStatusPanel> {
  bool _isLoading = true;
  _ApplicationCounts _counts = const _ApplicationCounts();

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final applications = await ApiService().getApplications();
      final actionRequired = applications.where((application) {
        final status = application['status'];
        return status == 'Admin_Approved' || status == 'Company_Scheduled';
      }).length;
      final pending = applications.where((application) {
        final status = application['status'];
        return status == 'Pending' || status == 'Agent_Evaluated';
      }).length;
      final history = applications.where((application) {
        final status = application['status'];
        return status == 'Student_Accepted' || status == 'Rejected' || status == 'Archived';
      }).length;

      if (mounted) {
        setState(() {
          _counts = _ApplicationCounts(
            actionRequired: actionRequired,
            pending: pending,
            history: history,
          );
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : _counts.isEmpty
          ? const _ApplicationsEmptyState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final useColumn = constraints.maxWidth < 420;
                final children = [
                  _ApplicationCountButton(
                    label: 'Action Required',
                    count: _counts.actionRequired,
                    onTap: () => widget.onOpenApplications(0),
                  ),
                  _ApplicationCountButton(
                    label: 'Pending',
                    count: _counts.pending,
                    onTap: () => widget.onOpenApplications(1),
                  ),
                  _ApplicationCountButton(
                    label: 'History',
                    count: _counts.history,
                    onTap: () => widget.onOpenApplications(2),
                  ),
                ];

                if (useColumn) {
                  return Column(
                    children: [
                      children[0],
                      const Divider(height: 1, color: AppColors.borderLight),
                      children[1],
                      const Divider(height: 1, color: AppColors.borderLight),
                      children[2],
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: children[0]),
                    const SizedBox(
                      height: 44,
                      child: VerticalDivider(width: 1, color: AppColors.borderLight),
                    ),
                    Expanded(child: children[1]),
                    const SizedBox(
                      height: 44,
                      child: VerticalDivider(width: 1, color: AppColors.borderLight),
                    ),
                    Expanded(child: children[2]),
                  ],
                );
              },
            ),
    );
  }
}

class _ApplicationCounts {
  const _ApplicationCounts({
    this.actionRequired = 0,
    this.pending = 0,
    this.history = 0,
  });

  final int actionRequired;
  final int pending;
  final int history;

  bool get isEmpty => actionRequired + pending + history == 0;
}

class _ApplicationCountButton extends StatelessWidget {
  const _ApplicationCountButton({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationsEmptyState extends StatelessWidget {
  const _ApplicationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        children: [
          Text(
            'No applications yet',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Submit your CV and apply for opportunities to track your application status here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onNotificationsTap});

  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning, Ryan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight, letterSpacing: -0.6)),
              const SizedBox(height: 4),
              const Text("Here's your placement overview", style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationsTap,
              style: IconButton.styleFrom(backgroundColor: Colors.white, fixedSize: const Size(44, 44)),
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimaryLight),
            ),
            Positioned(right: 8, top: 7, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
          ],
        ),
        const SizedBox(width: 8),
        const CircleAvatar(radius: 22, backgroundColor: AppColors.primary, child: Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17))),
      ],
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.onProfileTap});

  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x334F46E5), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Placement readiness', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)), child: const Text('72% complete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(borderRadius: BorderRadius.circular(10), child: const LinearProgressIndicator(value: 0.72, minHeight: 8, backgroundColor: Color(0x4DFFFFFF), valueColor: AlwaysStoppedAnimation(Colors.white))),
          const SizedBox(height: 18),
          const _ReadinessRow(icon: Icons.person_outline_rounded, label: 'Profile details', value: 'Complete', isComplete: true),
          const SizedBox(height: 10),
          const _ReadinessRow(icon: Icons.description_outlined, label: 'CV', value: 'Needs review', isComplete: false),
          const SizedBox(height: 10),
          const _ReadinessRow(icon: Icons.verified_user_outlined, label: 'Eligibility', value: 'Verified', isComplete: true),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton(onPressed: onProfileTap, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Update profile', style: TextStyle(fontWeight: FontWeight.w800)))),
        ],
      ),
    );
  }
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.icon, required this.label, required this.value, required this.isComplete});

  final IconData icon;
  final String label;
  final String value;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))),
        Icon(isComplete ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A), size: 17),
        const SizedBox(width: 5),
        Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x0A111827), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}
