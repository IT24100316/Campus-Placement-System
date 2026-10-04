import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/global_app_header.dart';
import '../../data/student_profile_models.dart';
import '../../data/student_profile_service.dart';
import 'profile_screen.dart';

/// Resume-tab landing screen. Editing remains in the existing registration form.
class ResumeHubScreen extends StatefulWidget {
  const ResumeHubScreen({
    super.key,
    this.isActive = true,
    this.profileService,
  });

  final bool isActive;
  final StudentProfileService? profileService;

  @override
  State<ResumeHubScreen> createState() => _ResumeHubScreenState();
}

class _ResumeHubScreenState extends State<ResumeHubScreen> {
  late final StudentProfileService _profileService;
  StudentProfileResponse? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? StudentProfileService();
    if (widget.isActive) _loadResume();
  }

  @override
  void didUpdateWidget(covariant ResumeHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _loadResume();
  }

  Future<void> _loadResume() async {
    final token = StudentSession.token?.trim();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _profile = null;
          _isLoading = false;
          _errorMessage = 'Sign in to view your resume.';
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.loadProfile(bearerToken: token);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } on StudentProfileException catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load your resume. Please try again.';
        });
      }
    }
  }

  Future<void> _openEditor({bool scrollToCv = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          showBackButton: true,
          scrollToCv: scrollToCv,
        ),
      ),
    );
    if (mounted) _loadResume();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _ResumeSnapshot.fromProfile(_profile);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: const GlobalAppHeader(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadResume,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text(
                'Resume',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Keep your internship information ready for opportunities.',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const _ResumeLoadingCard()
              else if (_errorMessage != null)
                _ResumeErrorCard(
                  message: _errorMessage!,
                  onRetry: _loadResume,
                )
              else
                _ResumeStateCard(
                  snapshot: snapshot,
                  onOpenEditor: _openEditor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ResumeStage { notStarted, incomplete, uploadCv, complete }

class _ResumeSnapshot {
  const _ResumeSnapshot({
    required this.stage,
    required this.completedRequiredFields,
  });

  // This matches the existing form/backend registration requirements. CV is a
  // separate completion condition, so it is deliberately not counted here.
  static const totalRequiredFields = 16;

  final _ResumeStage stage;
  final int completedRequiredFields;

  factory _ResumeSnapshot.fromProfile(StudentProfileResponse? profile) {
    if (profile == null) {
      return const _ResumeSnapshot(
        stage: _ResumeStage.notStarted,
        completedRequiredFields: 0,
      );
    }

    final today = DateTime.now();
    final graduationDate = profile.expectedGraduationDate;
    final completedFields = <bool>[
      _hasText(profile.fullName),
      _isValidPhone(profile.phone),
      _hasText(profile.universityName),
      _hasText(profile.academicStatus),
      _hasText(profile.degreeProgram),
      profile.currentYearOfStudy >= 1 && profile.currentYearOfStudy <= 8,
      profile.gpa >= 0 && profile.gpa <= 4,
      graduationDate != null &&
          !DateTime(
            graduationDate.year,
            graduationDate.month,
            graduationDate.day,
          ).isBefore(DateTime(today.year, today.month, today.day)),
      _hasText(profile.desiredJobTitle),
      _hasText(profile.primaryDomain),
      _hasText(profile.careerObjectivesSummary),
      profile.skills.any(_hasText),
      profile.toolsAndTechnologies.any(_hasText),
      profile.internshipType.any(_hasText),
      _hasText(profile.lectureScheduleType),
      profile.preferredLocations.any(_hasText),
    ].where((isComplete) => isComplete).length;

    // Registration creates a profile with account details already filled in.
    // A resume starts only when a resume-specific field is actually saved.
    final hasStarted = [
      profile.degreeProgram,
      profile.currentYearOfStudy > 0 ? 'year' : '',
      profile.gpa > 0 ? 'gpa' : '',
      profile.expectedGraduationDate?.toIso8601String() ?? '',
      profile.desiredJobTitle,
      profile.primaryDomain,
      profile.careerObjectivesSummary,
      ...profile.skills,
      ...profile.toolsAndTechnologies,
      ...profile.internshipType,
      profile.lectureScheduleType,
      ...profile.preferredLocations,
    ].any(_hasText);

    if (!hasStarted) {
      return const _ResumeSnapshot(
        stage: _ResumeStage.notStarted,
        completedRequiredFields: 0,
      );
    }
    if (completedFields < totalRequiredFields) {
      return _ResumeSnapshot(
        stage: _ResumeStage.incomplete,
        completedRequiredFields: completedFields,
      );
    }
    if (!_hasText(profile.cvPdfUrl)) {
      return _ResumeSnapshot(
        stage: _ResumeStage.uploadCv,
        completedRequiredFields: completedFields,
      );
    }
    return _ResumeSnapshot(
      stage: _ResumeStage.complete,
      completedRequiredFields: completedFields,
    );
  }

  static bool _hasText(String? value) => value?.trim().isNotEmpty == true;

  static bool _isValidPhone(String value) {
    return RegExp(r'^\+?[0-9][0-9\s\-()]{6,24}$').hasMatch(value.trim());
  }
}

class _ResumeStateCard extends StatelessWidget {
  const _ResumeStateCard({required this.snapshot, required this.onOpenEditor});

  final _ResumeSnapshot snapshot;
  final Future<void> Function({bool scrollToCv}) onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final content = switch (snapshot.stage) {
      _ResumeStage.notStarted => _ResumeCardContent(
        title: 'Create your resume',
        description: 'Add your details to start your internship resume.',
        action: 'Create resume',
        icon: Icons.add_rounded,
        progress: null,
        onTap: () => onOpenEditor(),
      ),
      _ResumeStage.incomplete => _ResumeCardContent(
        title: 'Complete your resume',
        description:
            'Add ${_remainingDetailsText(snapshot.completedRequiredFields)} to finish your internship resume.',
        action: 'Continue editing',
        icon: Icons.edit_note_outlined,
        progress:
            '${snapshot.completedRequiredFields} of ${_ResumeSnapshot.totalRequiredFields} required details completed',
        onTap: () => onOpenEditor(),
      ),
      _ResumeStage.uploadCv => _ResumeCardContent(
        title: 'Your resume is ready',
        description: 'Upload your CV to complete your internship registration.',
        action: 'Upload CV',
        icon: Icons.upload_file_outlined,
        progress: null,
        onTap: () => onOpenEditor(scrollToCv: true),
      ),
      _ResumeStage.complete => _ResumeCardContent(
        title: 'Your resume is complete',
        description: 'Keep your information up to date for new opportunities.',
        action: 'Edit resume',
        icon: Icons.description_outlined,
        progress: null,
        onTap: () => onOpenEditor(),
      ),
    };

    return Semantics(
      button: true,
      child: InkWell(
        onTap: content.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(content.icon, color: AppColors.primary),
                  ),
                  const Spacer(),
                  if (snapshot.stage == _ResumeStage.notStarted)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                content.title,
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                content.description,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              if (content.progress != null) ...[
                const SizedBox(height: 18),
                Text(
                  content.progress!,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: snapshot.completedRequiredFields /
                        _ResumeSnapshot.totalRequiredFields,
                    minHeight: 6,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  onPressed: content.onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: Text(
                    content.action,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _remainingDetailsText(int completed) {
    final remaining = _ResumeSnapshot.totalRequiredFields - completed;
    return '$remaining remaining required ${remaining == 1 ? 'detail' : 'details'}';
  }
}

class _ResumeCardContent {
  const _ResumeCardContent({
    required this.title,
    required this.description,
    required this.action,
    required this.icon,
    required this.progress,
    required this.onTap,
  });

  final String title;
  final String description;
  final String action;
  final IconData icon;
  final String? progress;
  final VoidCallback onTap;
}

class _ResumeLoadingCard extends StatelessWidget {
  const _ResumeLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2.5,
            ),
          ),
          SizedBox(width: 14),
          Text(
            'Loading your resume…',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeErrorCard extends StatelessWidget {
  const _ResumeErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your resume could not be loaded',
            style: TextStyle(
              color: AppColors.textPrimaryLight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
