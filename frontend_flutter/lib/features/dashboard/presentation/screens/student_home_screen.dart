import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../profile/data/student_profile_models.dart';
import '../../../profile/data/student_profile_service.dart';
import '../../../jobs/data/models/job_feed_model.dart';
import '../../../jobs/data/repositories/job_repository.dart';
import '../../../jobs/presentation/screens/job_details_screen.dart';
import '../widgets/dashboard_components.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenApplications,
    required this.onExploreJobs,
    required this.isActive,
  });

  final ValueChanged<int> onNavigate;
  final ValueChanged<int> onOpenApplications;
  final VoidCallback onExploreJobs;
  final bool isActive;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with WidgetsBindingObserver {
  final StudentProfileService _profileService = StudentProfileService();
  final ApiService _apiService = ApiService();
  final JobRepository _jobRepository = JobRepository();

  StudentProfileResponse? _profile;
  List<Map<String, dynamic>> _applications = const [];
  List<JobFeedModel> _latestJobs = const [];
  bool _isLoadingProfile = true;
  bool _isLoadingApplications = true;
  bool _isLoadingJobs = true;
  String? _profileError;
  String? _applicationsError;
  String? _jobsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshHomeData();
  }

  @override
  void didUpdateWidget(covariant StudentHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _refreshHomeData();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      _refreshHomeData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([_loadProfile(), _loadApplications()]);
  }

  void _refreshHomeData() {
    _loadDashboardData();
    _loadLatestJobs();
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

  Future<void> _loadLatestJobs() async {
    setState(() {
      _isLoadingJobs = true;
      _jobsError = null;
    });

    try {
      final result = await _jobRepository.fetchJobFeed(
        page: 1,
        pageSize: 50,
        sortBy: 'recent',
      );
      final now = DateTime.now();
      final openJobs = result.items
          .where(
            (job) =>
                job.jobId.trim().isNotEmpty &&
                job.jobTitle.trim().isNotEmpty &&
                job.companyName.trim().isNotEmpty &&
                job.applicationDeadline.toLocal().isAfter(now),
          )
          .toList()
        ..sort(
          (left, right) => right.createdAt.toLocal().compareTo(left.createdAt.toLocal()),
        );

      if (mounted) {
        setState(() {
          _latestJobs = openJobs.take(10).toList();
          _isLoadingJobs = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _jobsError = 'Unable to load opportunities. Please try again.';
          _isLoadingJobs = false;
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
            SliverToBoxAdapter(
              child: _Header(
                greeting: _headerGreeting,
                onNotificationsTap: () =>
                    _showPlaceholder(context, 'Notifications'),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(pagePadding, 20, pagePadding, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _NextStepCard(
                      profile: _profile,
                      applicationCount: _applications.length,
                      isLoading: _isLoadingProfile || _isLoadingApplications,
                      errorMessage: _profileError ?? _applicationsError,
                      onRetry: _loadDashboardData,
                      onCompleteProfile: () => widget.onNavigate(2),
                      onManageCv: () => widget.onNavigate(2),
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
                    const Text(
                      'CONTINUE EXPLORING',
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ContinueExploringSection(
                      profile: _profile,
                      applications: _applications,
                      isLoadingProfile: _isLoadingProfile,
                      profileError: _profileError,
                      isLoadingApplications: _isLoadingApplications,
                      applicationsError: _applicationsError,
                      onBrowseOpportunities: widget.onExploreJobs,
                      onViewApplications: () => widget.onOpenApplications(0),
                      onOpenProfile: () => widget.onNavigate(2),
                    ),
                    const SizedBox(height: 28),
                    DashboardSectionTitle(
                      title: 'Upcoming events',
                      actionLabel: 'View all',
                      onAction: () => widget.onOpenApplications(0),
                    ),
                    const SizedBox(height: 4),
                    _UpcomingEventsPanel(
                      applications: _applications,
                      isLoading: _isLoadingApplications,
                      errorMessage: _applicationsError,
                      onRetry: _loadApplications,
                      onOpenApplications: widget.onOpenApplications,
                    ),
                    const SizedBox(height: 28),
                    DashboardSectionTitle(
                      title: 'Opportunity spotlight',
                      actionLabel: 'Browse all jobs',
                      onAction: widget.onExploreJobs,
                    ),
                    const SizedBox(height: 12),
                    _OpportunitySpotlightPanel(
                      jobs: _latestJobs,
                      isLoading: _isLoadingJobs,
                      errorMessage: _jobsError,
                      onRetry: _loadLatestJobs,
                      onBrowseAll: widget.onExploreJobs,
                      onOpenJob: (job) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => JobDetailsScreen(jobId: job.jobId),
                          ),
                        );
                      },
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

class _ContinueExploringSection extends StatelessWidget {
  const _ContinueExploringSection({
    required this.profile,
    required this.applications,
    required this.isLoadingProfile,
    required this.profileError,
    required this.isLoadingApplications,
    required this.applicationsError,
    required this.onBrowseOpportunities,
    required this.onViewApplications,
    required this.onOpenProfile,
  });

  final StudentProfileResponse? profile;
  final List<Map<String, dynamic>> applications;
  final bool isLoadingProfile;
  final String? profileError;
  final bool isLoadingApplications;
  final String? applicationsError;
  final VoidCallback onBrowseOpportunities;
  final VoidCallback onViewApplications;
  final VoidCallback onOpenProfile;

  String get _profileStatus {
    if (isLoadingProfile) {
      return 'Loading profile...';
    }
    if (profileError != null) {
      return 'Profile unavailable';
    }

    final readiness = _ReadinessSnapshot.fromProfile(
      profile: profile,
      applicationCount: 0,
    );
    if (!readiness.isProfileComplete) {
      return 'Complete profile';
    }
    return readiness.hasCv ? 'Profile ready' : 'Upload CV';
  }

  String get _applicationsStatus {
    if (isLoadingApplications) {
      return 'Loading applications...';
    }
    if (applicationsError != null) {
      return 'Applications unavailable';
    }
    if (applications.isEmpty) {
      return 'No applications yet';
    }

    final counts = _ApplicationCounts.fromApplications(applications);
    final activeCount = counts.actionRequired + counts.pending;
    if (activeCount > 0) {
      return '$activeCount active';
    }
    return '${applications.length} submitted';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compactLayout = constraints.maxWidth < 300;
        final profileTile = _ExplorationTile(
          icon: Icons.person_outline_rounded,
          title: 'Internship profile',
          subtitle: _profileStatus,
          onTap: onOpenProfile,
        );
        final applicationsTile = _ExplorationTile(
          icon: Icons.assignment_outlined,
          title: 'Applications',
          subtitle: _applicationsStatus,
          onTap: onViewApplications,
        );

        return Column(
          children: [
            _BrowseOpportunitiesTile(onTap: onBrowseOpportunities),
            const SizedBox(height: 10),
            if (compactLayout) ...[
              applicationsTile,
              const SizedBox(height: 10),
              profileTile,
            ] else
              Row(
                children: [
                  Expanded(child: applicationsTile),
                  const SizedBox(width: 10),
                  Expanded(child: profileTile),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _BrowseOpportunitiesTile extends StatelessWidget {
  const _BrowseOpportunitiesTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              _ExplorationIcon(icon: Icons.travel_explore_rounded),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse opportunities',
                      style: TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Find internships that match your profile',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorationTile extends StatelessWidget {
  const _ExplorationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ExplorationIcon(icon: icon),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorationIcon extends StatelessWidget {
  const _ExplorationIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: AppColors.primary, size: 18),
    );
  }
}

class _OpportunitySpotlightPanel extends StatefulWidget {
  const _OpportunitySpotlightPanel({
    required this.jobs,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onBrowseAll,
    required this.onOpenJob,
  });

  final List<JobFeedModel> jobs;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBrowseAll;
  final ValueChanged<JobFeedModel> onOpenJob;

  @override
  State<_OpportunitySpotlightPanel> createState() =>
      _OpportunitySpotlightPanelState();
}

class _OpportunitySpotlightPanelState
    extends State<_OpportunitySpotlightPanel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.96);
  }

  @override
  void didUpdateWidget(covariant _OpportunitySpotlightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentPage >= widget.jobs.length && widget.jobs.isNotEmpty) {
      _currentPage = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const _SurfaceCard(
        child: SizedBox(
          height: 168,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }
    if (widget.errorMessage != null) {
      return _SurfaceCard(
        child: _DashboardLoadError(
          message: widget.errorMessage!,
          onRetry: widget.onRetry,
        ),
      );
    }
    if (widget.jobs.isEmpty) {
      return _SurfaceCard(
        child: _OpportunitySpotlightEmptyState(onBrowseAll: widget.onBrowseAll),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 204,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.jobs.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(
                right: index == widget.jobs.length - 1 ? 0 : 8,
              ),
              child: _OpportunitySpotlightCard(
                job: widget.jobs[index],
                onTap: () => widget.onOpenJob(widget.jobs[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_currentPage + 1} / ${widget.jobs.length}',
          style: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OpportunitySpotlightCard extends StatelessWidget {
  const _OpportunitySpotlightCard({
    required this.job,
    required this.onTap,
  });

  final JobFeedModel job;
  final VoidCallback onTap;

  String get _companyDetails {
    final details = <String>[job.companyName.trim()];
    final location = job.locationCity.trim();
    final workTypes = job.internshipType
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty);
    if (location.isNotEmpty) {
      details.add(location);
    }
    if (workTypes.isNotEmpty) {
      details.add(workTypes.first);
    }
    return details.join(' \u2022 ');
  }

  bool get _isClosingSoon {
    final deadline = job.applicationDeadline.toLocal();
    return deadline.difference(DateTime.now()).inDays <= 2;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06111827),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.business_center_outlined,
                      color: AppColors.primary,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'OPEN ROLE',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.jobTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _companyDetails,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _DeadlineChip(
                    text: _formatClosingDeadline(job.applicationDeadline),
                    isClosingSoon: _isClosingSoon,
                  ),
                  const Spacer(),
                  const Text(
                    'View role',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({
    required this.text,
    required this.isClosingSoon,
  });

  final String text;
  final bool isClosingSoon;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isClosingSoon
        ? const Color(0xFFFFF7E6)
        : AppColors.primary.withValues(alpha: 0.08);
    final foregroundColor = isClosingSoon
        ? const Color(0xFFB45309)
        : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OpportunitySpotlightEmptyState extends StatelessWidget {
  const _OpportunitySpotlightEmptyState({required this.onBrowseAll});

  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      child: Column(
        children: [
          const Text(
            'No opportunities available right now',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check back soon for new internship openings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onBrowseAll,
            icon: const Icon(Icons.work_outline_rounded, size: 18),
            label: const Text('Browse all jobs'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatClosingDeadline(DateTime deadline) {
  final localDeadline = deadline.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final deadlineDay = DateTime(
    localDeadline.year,
    localDeadline.month,
    localDeadline.day,
  );
  final daysUntilDeadline = deadlineDay.difference(today).inDays;

  if (daysUntilDeadline == 0) {
    return 'Closes today';
  }
  if (daysUntilDeadline == 1) {
    return 'Closes tomorrow';
  }
  if (daysUntilDeadline <= 7) {
    return 'Closes in $daysUntilDeadline days';
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final year = localDeadline.year == now.year ? '' : ', ${localDeadline.year}';
  return 'Closes ${months[localDeadline.month - 1]} ${localDeadline.day}$year';
}

class _UpcomingEventsPanel extends StatelessWidget {
  const _UpcomingEventsPanel({
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
    final events = _UpcomingApplicationEvent.fromApplications(applications);

    return _SurfaceCard(
      child: isLoading
          ? const SizedBox(
              height: 84,
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
          : events.isEmpty
          ? const _UpcomingEventsEmptyState()
          : Column(
              children: [
                for (var index = 0; index < events.length; index++) ...[
                  _UpcomingApplicationEventItem(
                    event: events[index],
                    onTap: () => onOpenApplications(0),
                  ),
                  if (index < events.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
              ],
            ),
    );
  }
}

class _UpcomingApplicationEventItem extends StatelessWidget {
  const _UpcomingApplicationEventItem({
    required this.event,
    required this.onTap,
  });

  final _UpcomingApplicationEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isInterview = event.type == _UpcomingEventType.interview;
    return DashboardEventItem(
      icon: isInterview
          ? Icons.video_call_outlined
          : Icons.timer_outlined,
      title: '${event.companyName} \u2014 ${isInterview ? 'Interview' : 'Decision deadline'}',
      dateTime: event.formattedDateTime,
      iconColor: isInterview
          ? const Color(0xFF2563EB)
          : const Color(0xFFD97706),
      badge: isInterview ? 'Interview' : 'Deadline',
      badgeColor: isInterview
          ? const Color(0xFFDBEAFE)
          : const Color(0xFFFFF7E6),
      badgeTextColor: isInterview
          ? const Color(0xFF1D4ED8)
          : const Color(0xFFB45309),
      onTap: onTap,
    );
  }
}

class _UpcomingEventsEmptyState extends StatelessWidget {
  const _UpcomingEventsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Column(
        children: [
          Text(
            'No upcoming interviews or deadlines',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your scheduled interviews and decision deadlines will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

enum _UpcomingEventType { interview, deadline }

class _UpcomingApplicationEvent {
  const _UpcomingApplicationEvent({
    required this.type,
    required this.companyName,
    required this.dateTime,
  });

  final _UpcomingEventType type;
  final String companyName;
  final DateTime dateTime;

  String get formattedDateTime {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final displayHour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour < 12 ? 'AM' : 'PM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}, $displayHour:$minute $period';
  }

  static List<_UpcomingApplicationEvent> fromApplications(
    List<Map<String, dynamic>> applications,
  ) {
    final now = DateTime.now();
    final events = <_UpcomingApplicationEvent>[];

    for (final application in applications) {
      final companyName = application['companyName']?.toString().trim() ?? '';
      if (companyName.isEmpty) {
        continue;
      }

      final status = application['status']?.toString();
      if (status == 'Company_Scheduled') {
        final dateTime = _interviewDateTime(application);
        if (dateTime != null && dateTime.isAfter(now)) {
          events.add(
            _UpcomingApplicationEvent(
              type: _UpcomingEventType.interview,
              companyName: companyName,
              dateTime: dateTime,
            ),
          );
        }
      } else if (status == 'Admin_Approved') {
        final dateTime = _localDateTime(application['decisionDeadline']);
        if (dateTime != null && dateTime.isAfter(now)) {
          events.add(
            _UpcomingApplicationEvent(
              type: _UpcomingEventType.deadline,
              companyName: companyName,
              dateTime: dateTime,
            ),
          );
        }
      }
    }

    events.sort((left, right) => left.dateTime.compareTo(right.dateTime));
    return events.take(3).toList();
  }

  static DateTime? _interviewDateTime(Map<String, dynamic> application) {
    final date = _localDateTime(application['interviewDate']);
    final time = _timeParts(application['interviewTime']);
    if (date == null || time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.$1, time.$2, time.$3);
  }

  static DateTime? _localDateTime(dynamic value) {
    final rawValue = value?.toString().trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return DateTime.tryParse(rawValue)?.toLocal();
  }

  static (int, int, int)? _timeParts(dynamic value) {
    final rawValue = value?.toString().trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2})(?:\.\d+)?)?$',
    ).firstMatch(rawValue);
    if (match == null) {
      return null;
    }

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    final second = int.tryParse(match.group(3) ?? '0');
    if (hour == null || minute == null || second == null ||
        hour > 23 || minute > 59 || second > 59) {
      return null;
    }
    return (hour, minute, second);
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
    final isCompact = MediaQuery.sizeOf(context).width < 360;
    final horizontalPadding = isCompact ? 16.0 : 20.0;
    final displayStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: isCompact ? 24 : 26,
          height: 1.15,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.7,
        ) ??
        TextStyle(
          fontSize: isCompact ? 24 : 26,
          height: 1.15,
          color: AppColors.textPrimaryLight,
          letterSpacing: -0.7,
        );
    final greetingSeparator = greeting.indexOf(',');
    final hasName = greetingSeparator > 0 &&
        greetingSeparator < greeting.length - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 18, horizontalPadding, 0),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                style: displayStyle,
                children: hasName
                    ? [
                        TextSpan(
                          text: greeting.substring(0, greetingSeparator + 1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TextSpan(
                          text: greeting.substring(greetingSeparator + 1),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ]
                    : [
                        TextSpan(
                          text: greeting,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onNotificationsTap,
                style: IconButton.styleFrom(fixedSize: const Size(44, 44)),
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimaryLight),
              ),
              Positioned(right: 8, top: 7, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
            ],
          ),
        ],
      ),
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: isLoading
          ? const SizedBox(
              height: 116,
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
        Text(
          nextStep.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
            height: 1.12,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          nextStep.explanation,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFDDE5FF),
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text(
                nextStep.progressLabel,
                style: const TextStyle(
                  color: Color(0xFFE0E7FF),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${readiness.overallProgress}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: readiness.overallProgress / 100,
            minHeight: 4,
            backgroundColor: const Color(0x3DFFFFFF),
            valueColor: const AlwaysStoppedAnimation(Color(0xFFC7D2FE)),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: nextStep.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.primaryDark,
            elevation: 0,
            minimumSize: const Size(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            nextStep.actionLabel,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
        title: 'Complete your profile',
        explanation: 'Add the remaining required details to continue.',
        progressLabel: '$completedProfileFields of $requiredProfileFieldCount required fields completed',
        actionLabel: 'Complete profile',
        onPressed: onCompleteProfile,
      );
    }
    if (!hasCv) {
      return _NextStep(
        title: 'Your profile is ready',
        explanation: 'Upload your CV to complete your internship registration.',
        progressLabel: 'Profile complete \u2022 CV remaining',
        actionLabel: 'Upload CV',
        onPressed: onManageCv,
      );
    }
    if (applicationCount == 0) {
      return _NextStep(
        title: 'Ready to explore',
        explanation: 'Your internship profile is complete. Find a role that suits you.',
        progressLabel: 'Profile and CV complete',
        actionLabel: 'Explore jobs',
        onPressed: onExploreJobs,
      );
    }
    return _NextStep(
      title: 'Keep your applications moving',
      explanation: 'You have $applicationCount application${applicationCount == 1 ? '' : 's'} in progress.',
      progressLabel: 'Profile, CV and applications complete',
      actionLabel: 'View applications',
      onPressed: onViewApplications,
    );
  }

  static bool _hasText(String value) => value.trim().isNotEmpty;
}

class _NextStep {
  const _NextStep({
    required this.title,
    required this.explanation,
    required this.progressLabel,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String explanation;
  final String progressLabel;
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
