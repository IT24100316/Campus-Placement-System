import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../data/student_profile_models.dart';
import '../../data/student_profile_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({
    super.key,
    this.initialProfile,
    this.profileService,
  });

  final StudentProfileResponse? initialProfile;
  final StudentProfileService? profileService;

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late final StudentProfileService _profileService;
  StudentProfileResponse? _profile;
  CampusIdDocument? _campusIdDocument;
  bool _isLoading = true;
  bool _isLoadingCampusId = false;
  bool _isCampusIdUnavailable = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _campusIdError;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? StudentProfileService();
    _profile = widget.initialProfile;
    _isLoading = _profile == null;
    _syncControllers();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  void _syncControllers() {
    _nameController.text = _profile?.fullName ?? '';
    _phoneController.text = _profile?.phone ?? '';
    _universityController.text = _profile?.universityName ?? '';
  }

  Future<void> _loadProfile() async {
    final token = StudentSession.token?.trim();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Sign in again to view your saved details.';
        });
      }
      return;
    }

    try {
      final profile = await _profileService.loadProfile(bearerToken: token);
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
          _errorMessage = null;
          _syncControllers();
        });
        _loadCampusId();
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
          _errorMessage = 'Unable to load your saved details. Please try again.';
        });
      }
    }
  }

  Future<void> _loadCampusId() async {
    final profile = _profile;
    final token = StudentSession.token?.trim();
    if (profile == null ||
        profile.campusIdPhotoUrl.trim().isEmpty ||
        token == null ||
        token.isEmpty) {
      return;
    }

    setState(() {
      _isLoadingCampusId = true;
      _isCampusIdUnavailable = false;
      _campusIdError = null;
    });
    try {
      final document = await _profileService.loadCampusId(bearerToken: token);
      if (mounted) {
        setState(() {
          _campusIdDocument = document;
          _isLoadingCampusId = false;
          _isCampusIdUnavailable = document == null;
        });
      }
    } on StudentProfileException catch (error) {
      if (mounted) {
        setState(() {
          _campusIdError = error.message;
          _isLoadingCampusId = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _campusIdError = 'Unable to load the registered ID preview.';
          _isLoadingCampusId = false;
        });
      }
    }
  }

  void _showCampusId() {
    final document = _campusIdDocument;
    if (document == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'University / Campus ID',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  document.bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 180,
                    child: Center(
                      child: Icon(
                        Icons.badge_outlined,
                        color: AppColors.textSecondaryLight,
                        size: 42,
                      ),
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startEditing() {
    _syncControllers();
    setState(() => _isEditing = true);
  }

  void _cancelEditing() {
    _syncControllers();
    setState(() => _isEditing = false);
  }

  Future<void> _saveDetails() async {
    final profile = _profile;
    final token = StudentSession.token?.trim();
    if (profile == null || token == null || token.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final savedProfile = await _profileService.saveProfile(
        bearerToken: token,
        profile: StudentProfileUpsertRequest(
          fullName: _nameController.text,
          phone: _phoneController.text,
          campusIdPhotoUrl: profile.campusIdPhotoUrl,
          portfolioUrl: profile.portfolioUrl,
          universityName: _universityController.text,
          academicStatus: profile.academicStatus,
          degreeProgram: profile.degreeProgram,
          currentYearOfStudy: profile.currentYearOfStudy,
          gpa: profile.gpa,
          expectedGraduationDate: profile.expectedGraduationDate,
          desiredJobTitle: profile.desiredJobTitle,
          primaryDomain: profile.primaryDomain,
          careerObjectivesSummary: profile.careerObjectivesSummary,
          skills: profile.skills,
          toolsAndTechnologies: profile.toolsAndTechnologies,
          internshipType: profile.internshipType,
          lectureScheduleType: profile.lectureScheduleType,
          preferredLocations: profile.preferredLocations,
          isDraft: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _profile = savedProfile;
        _isEditing = false;
        _isSaving = false;
        _syncControllers();
      });
      StudentSession.fullName = savedProfile.fullName;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal details saved.')),
      );
    } on StudentProfileException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Unable to save personal details. Please try again.';
        });
      }
    }
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Personal details',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (profile != null && !_isEditing)
            TextButton(
              onPressed: _startEditing,
              child: const Text(
                'Edit personal details',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (_isEditing)
            TextButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Cancel'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading && profile == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : profile == null
          ? _DetailsUnavailable(errorMessage: _errorMessage, onRetry: _loadProfile)
          : _isEditing
          ? _PersonalDetailsEditForm(
              formKey: _formKey,
              nameController: _nameController,
              phoneController: _phoneController,
              universityController: _universityController,
              universityEmail: StudentSession.email?.trim() ?? '',
              isSaving: _isSaving,
              onSave: _saveDetails,
            )
          : _PersonalDetailsView(
              profile: profile,
              universityEmail: StudentSession.email?.trim() ?? '',
              hasText: _hasText,
              campusIdDocument: _campusIdDocument,
              isLoadingCampusId: _isLoadingCampusId,
              isCampusIdUnavailable: _isCampusIdUnavailable,
              campusIdError: _campusIdError,
              onViewCampusId: _showCampusId,
            ),
    );
  }
}

class _PersonalDetailsView extends StatelessWidget {
  const _PersonalDetailsView({
    required this.profile,
    required this.universityEmail,
    required this.hasText,
    required this.campusIdDocument,
    required this.isLoadingCampusId,
    required this.isCampusIdUnavailable,
    required this.campusIdError,
    required this.onViewCampusId,
  });

  final StudentProfileResponse profile;
  final String universityEmail;
  final bool Function(String?) hasText;
  final CampusIdDocument? campusIdDocument;
  final bool isLoadingCampusId;
  final bool isCampusIdUnavailable;
  final String? campusIdError;
  final VoidCallback onViewCampusId;

  @override
  Widget build(BuildContext context) {
    final fields = <_DetailField>[
      if (hasText(profile.fullName)) _DetailField('Full name', profile.fullName),
      if (hasText(universityEmail))
        _DetailField('University email', universityEmail),
      if (hasText(profile.phone)) _DetailField('Mobile number', profile.phone),
      if (hasText(profile.universityName))
        _DetailField('University name', profile.universityName),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('ACCOUNT INFORMATION'),
          const SizedBox(height: 8),
          if (fields.isNotEmpty) _DetailsSurface(fields: fields),
          if (fields.isEmpty) const _EmptyDetailsState(),
          if (hasText(profile.campusIdPhotoUrl)) ...[
            const SizedBox(height: 24),
            _CampusIdPreview(
              document: campusIdDocument,
              isLoading: isLoadingCampusId,
              isUnavailable: isCampusIdUnavailable,
              errorMessage: campusIdError,
              onView: onViewCampusId,
            ),
          ],
        ],
      ),
    );
  }
}

class _CampusIdPreview extends StatelessWidget {
  const _CampusIdPreview({
    required this.document,
    required this.isLoading,
    required this.isUnavailable,
    required this.errorMessage,
    required this.onView,
  });

  final CampusIdDocument? document;
  final bool isLoading;
  final bool isUnavailable;
  final String? errorMessage;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UNIVERSITY / CAMPUS ID',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 72,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(15),
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      )
                    : document != null
                    ? Image.memory(
                        document!.bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.badge_outlined,
                          color: AppColors.primary,
                        ),
                      )
                    : const Icon(
                        Icons.badge_outlined,
                        color: AppColors.primary,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUnavailable
                          ? 'No registered ID available'
                          : 'Registered ID',
                      style: const TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      errorMessage ??
                          (isUnavailable
                              ? 'No readable campus ID is currently available.'
                              : 'Read-only campus ID on file'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (document != null)
                TextButton(
                  onPressed: onView,
                  child: const Text('View ID'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PersonalDetailsEditForm extends StatelessWidget {
  const _PersonalDetailsEditForm({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.universityController,
    required this.universityEmail,
    required this.isSaving,
    required this.onSave,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController universityController;
  final String universityEmail;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionLabel('EDIT PERSONAL DETAILS'),
            const SizedBox(height: 8),
            _EditSurface(
              children: [
                _EditableField(
                  label: 'Full name',
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  validator: _requiredValidator,
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _EditableField(
                  label: 'Mobile number',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _requiredValidator,
                ),
                const Divider(height: 1, color: AppColors.borderLight),
                _EditableField(
                  label: 'University name',
                  controller: universityController,
                  keyboardType: TextInputType.text,
                  validator: _requiredValidator,
                ),
              ],
            ),
            if (universityEmail.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionLabel('UNIVERSITY EMAIL'),
              const SizedBox(height: 8),
              _DetailsSurface(
                fields: [
                  _DetailField('University email', universityEmail),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Email changes require an account security flow and are not available here.',
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Save personal details',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required.';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _DetailsSurface extends StatelessWidget {
  const _DetailsSurface({required this.fields});

  final List<_DetailField> fields;

  @override
  Widget build(BuildContext context) {
    return _EditSurface(
      children: [
        for (var index = 0; index < fields.length; index++) ...[
          _DetailRow(field: fields[index]),
          if (index < fields.length - 1)
            const Divider(height: 1, color: AppColors.borderLight),
        ],
      ],
    );
  }
}

class _EditSurface extends StatelessWidget {
  const _EditSurface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _DetailField {
  const _DetailField(this.label, this.value);

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.field});

  final _DetailField field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.label,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            field.value,
            style: const TextStyle(
              color: AppColors.textPrimaryLight,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    required this.keyboardType,
    required this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondaryLight,
            fontSize: 13,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}

class _DetailsUnavailable extends StatelessWidget {
  const _DetailsUnavailable({required this.errorMessage, required this.onRetry});

  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline_rounded,
              size: 44,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 12),
            const Text(
              'Saved details are unavailable',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyDetailsState extends StatelessWidget {
  const _EmptyDetailsState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Text(
          'No saved personal details yet.',
          style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 14),
        ),
      ),
    );
  }
}
