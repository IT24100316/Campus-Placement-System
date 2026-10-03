import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../profile/data/student_profile_models.dart';
import '../../../profile/data/student_profile_service.dart';
import '../widgets/dashboard_components.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenApplications,
    required this.onExploreJobs,
  });

  final ValueChanged<int> onNavigate;
  final ValueChanged<int> onOpenApplications;
  final VoidCallback onExploreJobs;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final StudentProfileService _profileService = StudentProfileService();
  final ApiService _apiService = ApiService();

  StudentProfileResponse? _profile;
  List<Map<String, dynamic>> _applications = const [];
  bool _isLoadingProfile = true;
  bool _isLoadingApplications = true;
  String? _profileError;
  String? _applicationsError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([_loadProfile(), _loadApplications()]);
  }

  Future<void> _loadProfile() async {
    final token = StudentSession.token;
    if (token == null || token.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _profileError = 'Sign in again to load your profile.';
          _isLoadingProfile = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await _profileService.loadProfile(bearerToken: token);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoadingProfile = false;
        });
      }
    } on StudentProfileException catch (error) {
      if (mounted) {
        setState(() {
          _profileError = error.message;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileError = 'Unable to load your profile. Please try again.';
          _isLoadingProfile = false;
        });
      }
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoadingApplications = true;
      _applicationsError = null;
    });

    try {
      final applications = await _apiService.getApplications();
      if (mounted) {
        setState(() {
          _applications = applications;
          _isLoadingApplications = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _applicationsError = 'Unable to load your applications. Please try again.';
          _isLoadingApplications = false;
        });
      }
    }
  }

  String get _headerGreeting {
    final profileName = _profile?.fullName.trim() ?? '';
    final sessionName = StudentSession.fullName?.trim() ?? '';
    final name = profileName.isNotEmpty ? profileName : sessionName;

    if (name.isEmpty) {
      return 'Welcome';
    }

    final hour = DateTime.now().hour;
    final salutation = hour >= 5 && hour < 12
        ? 'Good morning'
        : hour >= 12 && hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    return '$salutation, $name';
  }

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
                    _Header(
                      greeting: _headerGreeting,
                      onNotificationsTap: () => _showPlaceholder(context, 'Notifications'),
                    ),
                    const SizedBox(height: 24),
                    _NextStepCard(
                      profile: _profile,
                      applicationCount: _applications.length,
                      isLoading: _isLoadingProfile || _isLoadingApplications,
                      errorMessage: _profileError ?? _applicationsError,
                      onRetry: _loadDashboardData,
                      onCompleteProfile: () => widget.onNavigate(1),
                      onManageCv: () => widget.onNavigate(1),
                      onExploreJobs: widget.onExploreJobs,
                      onViewApplications: () => widget.onOpenApplications(0),
                    ),
                    const SizedBox(height: 28),
                    const DashboardSectionTitle(title: 'Application status'),
                    const SizedBox(height: 12),
                    _ApplicationStatusPanel(
                      applications: _applications,
                      isLoading: _isLoadingApplications,
                      errorMessage: _applicationsError,
                      onRetry: _loadApplications,
                      onOpenApplications: widget.onOpenApplications,
                    ),
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
                        QuickActionItem(icon: Icons.assignment_outlined, label: 'View Applications', onTap: () => widget.onOpenApplications(0)),
                        QuickActionItem(icon: Icons.person_outline, label: 'Update Profile', onTap: () => widget.onNavigate(3)),
                        QuickActionItem(icon: Icons.upload_file_outlined, label: 'Manage CV', onTap: () => widget.onNavigate(1)),
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
                          DashboardEventItem(icon: Icons.schedule_outlined, title: 'CV verification deadline', dateTime: 'Oct 21, 5:00 PM', iconColor: const Color(0xFFDC2626), badge: 'Deadline', badgeColor: const Color(0xFFFEE2E2), badgeTextColor: const Color(0xFFB91C1C), onTap: () => widget.onNavigate(1)),
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

class _ApplicationStatusPanel extends StatelessWidget {
  const _ApplicationStatusPanel({
    required this.applications,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onOpenApplications,
  });

  final List<Map<String, dynamic>> applications;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<int> onOpenApplications;

  @override
  Widget build(BuildContext context) {
    final counts = _ApplicationCounts.fromApplications(applications);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLoading
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
          : errorMessage != null
          ? _DashboardLoadError(message: errorMessage!, onRetry: onRetry)
          : counts.isEmpty
          ? const _ApplicationsEmptyState()
          : LayoutBuilder(
              builder: (context, constraints) {
                final useColumn = constraints.maxWidth < 420;
                final countButtons = [
                  if (counts.actionRequired > 0)
                    _ApplicationCountButton(
                      label: 'Action Required',
                      count: counts.actionRequired,
                      onTap: () => onOpenApplications(0),
                    ),
                  if (counts.pending > 0)
                    _ApplicationCountButton(
                      label: 'Pending',
                      count: counts.pending,
                      onTap: () => onOpenApplications(1),
                    ),
                  if (counts.history > 0)
                    _ApplicationCountButton(
                      label: 'History',
                      count: counts.history,
                      onTap: () => onOpenApplications(2),
                    ),
                ];

                if (useColumn) {
                  return Column(
                    children: [
                      for (var index = 0; index < countButtons.length; index++) ...[
                        countButtons[index],
                        if (index < countButtons.length - 1)
                          const Divider(height: 1, color: AppColors.borderLight),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    for (var index = 0; index < countButtons.length; index++) ...[
                      Expanded(child: countButtons[index]),
                      if (index < countButtons.length - 1)
                        const SizedBox(
                          height: 44,
                          child: VerticalDivider(
                            width: 1,
                            color: AppColors.borderLight,
                          ),
                        ),
                    ],
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

  factory _ApplicationCounts.fromApplications(
    List<Map<String, dynamic>> applications,
  ) {
    return _ApplicationCounts(
      actionRequired: applications.where((application) {
        final status = application['status'];
        return status == 'Admin_Approved' || status == 'Company_Scheduled';
      }).length,
      pending: applications.where((application) {
        final status = application['status'];
        return status == 'Pending' || status == 'Agent_Evaluated';
      }).length,
      history: applications.where((application) {
        final status = application['status'];
        return status == 'Student_Accepted' ||
            status == 'Rejected' ||
            status == 'Archived';
      }).length,
    );
  }
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
  const _Header({required this.greeting, required this.onNotificationsTap});

  final String greeting;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight, letterSpacing: -0.6)),
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
      ],
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.profile,
    required this.applicationCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onCompleteProfile,
    required this.onManageCv,
    required this.onExploreJobs,
    required this.onViewApplications,
  });

  final StudentProfileResponse? profile;
  final int applicationCount;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onCompleteProfile;
  final VoidCallback onManageCv;
  final VoidCallback onExploreJobs;
  final VoidCallback onViewApplications;

  @override
  Widget build(BuildContext context) {
    final readiness = _ReadinessSnapshot.fromProfile(
      profile: profile,
      applicationCount: applicationCount,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), AppColors.primaryDark, Color(0xFF5B21B6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0x667C8CFF)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -46,
              right: -30,
              child: Container(
                width: 142,
                height: 142,
                decoration: const BoxDecoration(
                  color: Color(0x14FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: isLoading
                  ? const SizedBox(
                      height: 132,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : errorMessage != null
                  ? _DashboardLoadError(
                      message: errorMessage!,
                      onRetry: onRetry,
                      isDark: true,
                    )
                  : _NextStepContent(
                      readiness: readiness,
                      onCompleteProfile: onCompleteProfile,
                      onManageCv: onManageCv,
                      onExploreJobs: onExploreJobs,
                      onViewApplications: onViewApplications,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextStepContent extends StatelessWidget {
  const _NextStepContent({
    required this.readiness,
    required this.onCompleteProfile,
    required this.onManageCv,
    required this.onExploreJobs,
    required this.onViewApplications,
  });

  final _ReadinessSnapshot readiness;
  final VoidCallback onCompleteProfile;
  final VoidCallback onManageCv;
  final VoidCallback onExploreJobs;
  final VoidCallback onViewApplications;

  @override
  Widget build(BuildContext context) {
    final nextStep = readiness.nextStep(
      onCompleteProfile: onCompleteProfile,
      onManageCv: onManageCv,
      onExploreJobs: onExploreJobs,
      onViewApplications: onViewApplications,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: Color(0xFFE0E7FF),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 3),
                child: Text(
                  'Your next step',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${readiness.overallProgress}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                  ),
                ),
                const Text(
                  'READY',
                  style: TextStyle(
                    color: Color(0xFFC7D2FE),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          nextStep.message,
          style: const TextStyle(
            color: Color(0xFFE0E7FF),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: readiness.overallProgress / 100,
            minHeight: 6,
            backgroundColor: const Color(0x3DFFFFFF),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFC7D2FE)),
          ),
        ),
        const SizedBox(height: 16),
        _ProgressRow(
          label: 'Profile completion',
          value: '${readiness.completedProfileFields} of ${_ReadinessSnapshot.requiredProfileFieldCount} required fields',
          isComplete: readiness.isProfileComplete,
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          label: 'CV status',
          value: readiness.hasCv ? 'CV available' : 'CV not uploaded',
          isComplete: readiness.hasCv,
        ),
        const SizedBox(height: 8),
        _ProgressRow(
          label: 'Applications submitted',
          value: '${readiness.applicationCount} submitted',
          isComplete: readiness.applicationCount > 0,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: nextStep.onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primaryDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              nextStep.actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.isComplete,
  });

  final String label;
  final String value;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
          color: isComplete ? const Color(0xFFBBF7D0) : const Color(0xFFC7D2FE),
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFFDDE5FF),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadinessSnapshot {
  const _ReadinessSnapshot({
    required this.completedProfileFields,
    required this.hasCv,
    required this.applicationCount,
  });

  // These 16 checks exactly match the backend's registration requirements:
  // identity/contact (full name, phone), education (university, academic
  // status, degree, study year, GPA, graduation date), career goals (desired
  // title, primary domain, objectives), and preferences (skills, tools,
  // internship type, lecture schedule, and preferred locations).
  static const requiredProfileFieldCount = 16;

  final int completedProfileFields;
  final bool hasCv;
  final int applicationCount;

  bool get isProfileComplete => completedProfileFields == requiredProfileFieldCount;

  int get overallProgress {
    final completedChecks = completedProfileFields + (hasCv ? 1 : 0) + (applicationCount > 0 ? 1 : 0);
    return ((completedChecks / (requiredProfileFieldCount + 2)) * 100).round();
  }

  factory _ReadinessSnapshot.fromProfile({
    required StudentProfileResponse? profile,
    required int applicationCount,
  }) {
    if (profile == null) {
      return _ReadinessSnapshot(
        completedProfileFields: 0,
        hasCv: false,
        applicationCount: applicationCount,
      );
    }

    final today = DateTime.now();
    final graduationDate = profile.expectedGraduationDate;
    final completedFields = [
      _hasText(profile.fullName),
      _hasText(profile.phone),
      _hasText(profile.universityName),
      _hasText(profile.academicStatus),
      _hasText(profile.degreeProgram),
      profile.currentYearOfStudy >= 1 && profile.currentYearOfStudy <= 8,
      profile.gpa >= 0 && profile.gpa <= 4,
      graduationDate != null &&
          DateTime(graduationDate.year, graduationDate.month, graduationDate.day).isAfter(
            DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1)),
          ),
      _hasText(profile.desiredJobTitle),
      _hasText(profile.primaryDomain),
      _hasText(profile.careerObjectivesSummary),
      profile.skills.any(_hasText),
      profile.toolsAndTechnologies.any(_hasText),
      profile.internshipType.any(_hasText),
      _hasText(profile.lectureScheduleType),
      profile.preferredLocations.any(_hasText),
    ].where((isComplete) => isComplete).length;

    return _ReadinessSnapshot(
      completedProfileFields: completedFields,
      hasCv: _hasText(profile.cvPdfUrl),
      applicationCount: applicationCount,
    );
  }

  _NextStep nextStep({
    required VoidCallback onCompleteProfile,
    required VoidCallback onManageCv,
    required VoidCallback onExploreJobs,
    required VoidCallback onViewApplications,
  }) {
    if (!isProfileComplete) {
      return _NextStep(
        message: 'Complete your profile to unlock CV upload and placement registration.',
        actionLabel: 'Complete profile',
        onPressed: onCompleteProfile,
      );
    }
    if (!hasCv) {
      return _NextStep(
        message: 'Upload your CV to complete your placement readiness.',
        actionLabel: 'Manage CV',
        onPressed: onManageCv,
      );
    }
    if (applicationCount == 0) {
      return _NextStep(
        message: 'Your profile and CV are ready. Explore available opportunities.',
        actionLabel: 'Explore jobs',
        onPressed: onExploreJobs,
      );
    }
    return _NextStep(
      message: 'You are ready and have $applicationCount application${applicationCount == 1 ? '' : 's'} submitted.',
      actionLabel: 'View applications',
      onPressed: onViewApplications,
    );
  }

  static bool _hasText(String value) => value.trim().isNotEmpty;
}

class _NextStep {
  const _NextStep({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({
    required this.message,
    required this.onRetry,
    this.isDark = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: TextStyle(
            color: isDark ? const Color(0xFFE0E7FF) : AppColors.textSecondaryLight,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Retry'),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white : AppColors.primary,
            padding: EdgeInsets.zero,
          ),
        ),
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
