import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';
import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/cv_upload_service.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../data/student_profile_models.dart';
import '../../data/student_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.profileService,
    this.referenceClient,
    this.cvUploadService,
    this.pickCvFile,
    this.showBackButton = false,
    this.scrollToCv = false,
  });

  final StudentProfileService? profileService;
  final http.Client? referenceClient;
  final CvUploadService? cvUploadService;
  final Future<PlatformFile?> Function()? pickCvFile;
  final bool showBackButton;
  final bool scrollToCv;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _CvUploadedStatus extends StatelessWidget {
  const _CvUploadedStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.16)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.accent, size: 18),
          SizedBox(width: 8),
          Text(
            'CV uploaded',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxCvFileSizeBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _cvUploadSectionKey = GlobalKey();
  final List<String> _skills = [];
  final List<String> _tools = [];

  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _toolController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController();
  final TextEditingController _expectedGraduationController =
      TextEditingController();
  final TextEditingController _portfolioUrlController = TextEditingController();
  final TextEditingController _careerObjectivesController =
      TextEditingController();

  final Set<String> _selectedWorkArrangements = {};
  final Set<String> _selectedLocations = {};
  String? _selectedSchedule;
  String? _selectedDegree;
  String? _selectedAcademicStatus;
  int? _selectedYearOfStudy;
  String _campusIdPhotoUrl = '';

  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  bool _isCompletingRegistration = false;
  String? _profileMessage;
  bool _profileMessageIsError = false;
  bool _profileLoadFailed = false;
  bool _sessionExpired = false;
  bool _registrationComplete = false;
  bool _showFinalValidation = false;

  List<dynamic> _domains = [];
  List<dynamic> _jobTitles = [];
  bool _isLoadingDomains = false;
  bool _isLoadingTitles = false;
  int? _selectedDomainId;
  int? _selectedJobTitleId;
  String? _skillsError;
  String? _toolsError;
  String? _internshipTypeError;
  String? _locationError;
  PlatformFile? _selectedCvFile;
  int? _selectedCvFileSize;
  String? _cvSelectionError;
  String? _cvUploadError;
  String? _uploadedCvStorageKey;
  DateTime? _cvNextEligibleUploadAt;
  Timer? _cvCooldownRefreshTimer;
  bool _isSelectingCv = false;

  late final StudentProfileService _profileService;
  late final CvUploadService _cvUploadService;
  late final http.Client _referenceClient;

  static const List<String> degreePrograms = [
    'BSc (Hons) Information Technology',
    'BSc (Hons) Software Engineering',
    'BSc (Hons) Computer Science',
    'BSc (Hons) Data Science',
    'BSc (Hons) Cyber Security',
  ];
  static const List<String> internshipTypes = ['OnSite', 'Hybrid', 'Remote'];

  @override
  void initState() {
    super.initState();
    _profileService = widget.profileService ?? StudentProfileService();
    _cvUploadService = widget.cvUploadService ?? CvUploadService();
    _referenceClient = widget.referenceClient ?? http.Client();
    for (final controller in [
      _fullNameController,
      _phoneController,
      _universityController,
      _gpaController,
      _expectedGraduationController,
      _careerObjectivesController,
    ]) {
      controller.addListener(_refreshPrimaryAction);
    }
    _initializeProfile();
  }

  void _refreshPrimaryAction() {
    if (mounted && !_isLoadingProfile) setState(() {});
  }

  bool get _isCvReplacementCooldownActive {
    final nextEligible = _cvNextEligibleUploadAt;
    return _uploadedCvStorageKey != null &&
        nextEligible != null &&
        DateTime.now().toUtc().isBefore(nextEligible);
  }

  void _scheduleCvCooldownRefresh() {
    _cvCooldownRefreshTimer?.cancel();
    final nextEligible = _cvNextEligibleUploadAt;
    if (nextEligible == null || _uploadedCvStorageKey == null) return;
    final wait = nextEligible.difference(DateTime.now().toUtc());
    if (wait <= Duration.zero) return;
    _cvCooldownRefreshTimer = Timer(wait, () {
      if (mounted) setState(() {});
    });
  }

  String _formatNextEligibleUpload(BuildContext context) {
    final nextEligible = _cvNextEligibleUploadAt;
    if (nextEligible == null) return '';
    final local = nextEligible.toLocal();
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(local)} at '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  Future<void> _initializeProfile() async {
    await _fetchDomains();
    await _loadProfile();
    _scrollToCvIfRequested();
  }

  void _scrollToCvIfRequested() {
    if (!widget.scrollToCv) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _cvUploadSectionKey.currentContext;
      if (mounted && targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: 0.12,
        );
      }
    });
  }

  Future<void> _fetchDomains() async {
    setState(() => _isLoadingDomains = true);
    try {
      final response = await _referenceClient.get(
        Uri.parse('${ApiEndpoints.baseUrl}/jobs/reference/domains'),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _domains = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching domains: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDomains = false);
    }
  }

  Future<void> _fetchJobTitles(int domainId) async {
    setState(() {
      _isLoadingTitles = true;
      _jobTitles = [];
      _selectedJobTitleId = null;
    });
    try {
      final response = await _referenceClient.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}/jobs/reference/titles?domainId=$domainId',
        ),
      );
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _jobTitles = json.decode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching job titles: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTitles = false);
    }
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() {
        _isLoadingProfile = true;
        _profileMessage = null;
        _profileLoadFailed = false;
      });
    }
    try {
      final profile = await _profileService.loadProfile(
        bearerToken: StudentSession.token ?? '',
      );
      if (!mounted) return;
      if (profile == null) {
        setState(() {
          _fullNameController.text = StudentSession.fullName ?? '';
          _profileMessage = 'Create your student profile to get started.';
          _profileMessageIsError = false;
          _registrationComplete = false;
        });
        return;
      }
      await _populateProfile(profile);
      if (mounted) {
        setState(() {
          _profileMessage = _registrationComplete
              ? 'Internship registration completed successfully'
              : 'Your saved profile is ready to edit.';
          _profileMessageIsError = false;
        });
      }
    } on StudentProfileException catch (error) {
      if (mounted) {
        if (error.type == StudentProfileErrorType.unauthorized) {
          _expireSession();
        }
        setState(() {
          _profileMessage = error.message;
          _profileMessageIsError = true;
          _profileLoadFailed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _populateProfile(StudentProfileResponse profile) async {
    if (!mounted) return;
    setState(() {
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phone;
      _campusIdPhotoUrl = profile.campusIdPhotoUrl;
      _portfolioUrlController.text = profile.portfolioUrl ?? '';
      _universityController.text = profile.universityName;
      _gpaController.text = profile.gpa.toString();
      _expectedGraduationController.text =
          profile.expectedGraduationDate == null
          ? ''
          : '${profile.expectedGraduationDate!.year.toString().padLeft(4, '0')}-${profile.expectedGraduationDate!.month.toString().padLeft(2, '0')}-${profile.expectedGraduationDate!.day.toString().padLeft(2, '0')}';
      _careerObjectivesController.text = profile.careerObjectivesSummary;
      _selectedAcademicStatus = profile.academicStatus.isEmpty
          ? null
          : profile.academicStatus;
      _selectedDegree = profile.degreeProgram.isEmpty
          ? null
          : profile.degreeProgram;
      _selectedYearOfStudy = profile.currentYearOfStudy == 0
          ? null
          : profile.currentYearOfStudy;
      _selectedSchedule = profile.lectureScheduleType.isEmpty
          ? null
          : profile.lectureScheduleType;
      _skills
        ..clear()
        ..addAll(profile.skills);
      _tools
        ..clear()
        ..addAll(profile.toolsAndTechnologies);
      _selectedWorkArrangements
        ..clear()
        ..addAll(profile.internshipType);
      _selectedLocations
        ..clear()
        ..addAll(profile.preferredLocations);
      _uploadedCvStorageKey = profile.cvPdfUrl.isEmpty
          ? null
          : profile.cvPdfUrl;
      _cvNextEligibleUploadAt = profile.cvNextEligibleUploadAt;
      _registrationComplete =
          _uploadedCvStorageKey != null && _isStoredProfileComplete(profile);

      final matchingDomain = _domains.where(
        (domain) =>
            domain['name'].toString().toLowerCase() ==
            profile.primaryDomain.toLowerCase(),
      );
      if (matchingDomain.isNotEmpty) {
        _selectedDomainId = matchingDomain.first['id'] as int;
      } else if (profile.primaryDomain.isNotEmpty) {
        _domains = [
          ..._domains,
          {'id': -2, 'name': profile.primaryDomain},
        ];
        _selectedDomainId = -2;
      }
    });
    _scheduleCvCooldownRefresh();

    if (_selectedDomainId != null && _selectedDomainId! > 0) {
      await _fetchJobTitles(_selectedDomainId!);
    }
    if (!mounted) return;
    setState(() {
      final matchingTitle = _jobTitles.where(
        (title) =>
            title['title'].toString().toLowerCase() ==
            profile.desiredJobTitle.toLowerCase(),
      );
      if (matchingTitle.isNotEmpty) {
        _selectedJobTitleId = matchingTitle.first['id'] as int;
      } else if (profile.desiredJobTitle.isNotEmpty) {
        _jobTitles = [
          ..._jobTitles,
          {'id': -2, 'title': profile.desiredJobTitle},
        ];
        _selectedJobTitleId = -2;
      }
    });
  }

  void _addSkill() {
    final text = _skillController.text.trim();
    final error = _tagEntryError(text, _skills, 'skill');
    setState(() {
      _skillsError = error;
      if (error == null) {
        _skills.add(text);
        _skillController.clear();
      }
    });
  }

  void _addTool() {
    final text = _toolController.text.trim();
    final error = _tagEntryError(text, _tools, 'tool or technology');
    setState(() {
      _toolsError = error;
      if (error == null) {
        _tools.add(text);
        _toolController.clear();
      }
    });
  }

  String? _tagEntryError(String value, List<String> items, String label) {
    if (value.isEmpty) return 'Enter a $label before adding it.';
    if (items.any((item) => item.trim().toLowerCase() == value.toLowerCase())) {
      return 'This $label has already been added.';
    }
    return null;
  }

  Future<void> _selectCvFile() async {
    if (_isSelectingCv || _isSavingProfile) {
      return;
    }

    setState(() {
      _isSelectingCv = true;
      _cvSelectionError = null;
    });

    try {
      final file =
          await (widget.pickCvFile?.call() ??
              FilePicker.pickFile(
                type: FileType.custom,
                allowedExtensions: const ['pdf'],
              ));

      if (file == null) {
        return;
      }

      final fileSize = file.lengthSync() ?? await file.length();
      if (fileSize == null || fileSize <= 0) {
        _setCvSelectionError(
          'The selected PDF could not be read. Please try again.',
        );
        return;
      }

      if (fileSize > _maxCvFileSizeBytes) {
        _setCvSelectionError('The CV must not exceed 10 MB.');
        return;
      }

      if (!file.name.toLowerCase().endsWith('.pdf')) {
        _setCvSelectionError('Only PDF files can be selected.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (!_hasPdfSignature(bytes)) {
        _setCvSelectionError(
          'The selected file does not contain valid PDF content.',
        );
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCvFile = file;
        _selectedCvFileSize = fileSize;
        _cvSelectionError = null;
        _cvUploadError = null;
      });
    } catch (_) {
      _setCvSelectionError(
        'Unable to access the selected file. Please check permissions and try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSelectingCv = false);
      }
    }
  }

  void _removeSelectedCv() {
    setState(() {
      _selectedCvFile = null;
      _selectedCvFileSize = null;
      _cvSelectionError = null;
      _cvUploadError = null;
    });
  }

  void _setCvSelectionError(String message) {
    if (mounted) {
      setState(() => _cvSelectionError = message);
    }
  }

  bool _hasPdfSignature(Uint8List bytes) {
    const pdfSignature = [0x25, 0x50, 0x44, 0x46, 0x2D];
    if (bytes.length < pdfSignature.length) {
      return false;
    }

    return List.generate(
      pdfSignature.length,
      (index) => index,
    ).every((index) => bytes[index] == pdfSignature[index]);
  }

  String _formatFileSize(int bytes) {
    const bytesPerMegabyte = 1024 * 1024;
    return '${(bytes / bytesPerMegabyte).toStringAsFixed(1)} MB';
  }

  void _expireSession() {
    StudentSession.clear();
    _sessionExpired = true;
  }

  void _goToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  Future<Uint8List> _validatedPdfBytes(PlatformFile file) async {
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      throw const CvUploadException('Only PDF files can be selected.');
    }
    final size = file.lengthSync() ?? await file.length();
    if (size == null || size <= 0) {
      throw const CvUploadException(
        'The selected PDF could not be read. Please try again.',
      );
    }
    if (size > _maxCvFileSizeBytes) {
      throw const CvUploadException('The CV must not exceed 10 MB.');
    }
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty ||
        bytes.length > _maxCvFileSizeBytes ||
        !_hasPdfSignature(bytes)) {
      throw const CvUploadException(
        'The selected file does not contain valid PDF content.',
      );
    }
    return bytes;
  }

  bool get _canCompleteRegistration =>
      _hasCompleteProfileInputs() &&
      _cvSelectionError == null &&
      (_selectedCvFile != null || _uploadedCvStorageKey != null);

  static const _requiredResumeFieldCount = 16;

  int get _completedResumeFieldCount {
    final graduation = DateTime.tryParse(
      _expectedGraduationController.text.trim(),
    );
    final today = DateTime.now();
    final gpa = double.tryParse(_gpaController.text.trim());
    return <bool>[
      _validateFullName(_fullNameController.text, required: true) == null,
      _validatePhone(_phoneController.text, required: true) == null,
      _validateUniversityName(_universityController.text, required: true) ==
          null,
      _selectedAcademicStatus?.trim().isNotEmpty == true,
      _selectedDegree?.trim().isNotEmpty == true,
      (_selectedYearOfStudy ?? 0) >= 1 && (_selectedYearOfStudy ?? 0) <= 8,
      gpa != null && gpa >= 0 && gpa <= 4,
      graduation != null &&
          !DateTime(
            graduation.year,
            graduation.month,
            graduation.day,
          ).isBefore(DateTime(today.year, today.month, today.day)),
      _selectedReferenceValue(
            _jobTitles,
            _selectedJobTitleId,
            'title',
          )?.trim().isNotEmpty ==
          true,
      _selectedReferenceValue(
            _domains,
            _selectedDomainId,
            'name',
          )?.trim().isNotEmpty ==
          true,
      _validateCareerObjectives(
            _careerObjectivesController.text,
            required: true,
          ) ==
          null,
      _skills.isNotEmpty,
      _tools.isNotEmpty,
      _selectedWorkArrangements.isNotEmpty,
      _selectedSchedule?.trim().isNotEmpty == true,
      _selectedLocations.isNotEmpty,
    ].where((isComplete) => isComplete).length;
  }

  int _completedIn(List<bool> requirements) =>
      requirements.where((isComplete) => isComplete).length;

  String get _primaryButtonText {
    if (_isSavingProfile) {
      return _isCompletingRegistration
          ? 'Completing registration...'
          : 'Saving progress...';
    }
    return _canCompleteRegistration
        ? 'Complete Internship Registration'
        : 'Save to continue later';
  }

  IconData get _primaryButtonIcon => _canCompleteRegistration
      ? Icons.check_circle_outline
      : Icons.save_outlined;

  Future<void> _handlePrimaryAction() async {
    if (_isLoadingProfile || _isSavingProfile) return;
    if (_canCompleteRegistration) {
      await _completeRegistration();
    } else {
      await _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    if (!_hasActiveSession()) return;
    if (!_validateDraftValues()) return;

    setState(() {
      _isSavingProfile = true;
      _isCompletingRegistration = false;
      _profileMessage = null;
      _profileLoadFailed = false;
    });

    try {
      final result = await _profileService.saveProfile(
        profile: _buildProfileRequest(isDraft: true),
        bearerToken: StudentSession.token ?? '',
      );
      if (!mounted) return;
      setState(() {
        _campusIdPhotoUrl = result.campusIdPhotoUrl;
        _uploadedCvStorageKey = result.cvPdfUrl.isEmpty
            ? null
            : result.cvPdfUrl;
        _cvNextEligibleUploadAt = result.cvNextEligibleUploadAt;
        _registrationComplete =
            _uploadedCvStorageKey != null && _isStoredProfileComplete(result);
        _profileMessage = 'Your progress has been saved.';
        _profileMessageIsError = false;
      });
      _scheduleCvCooldownRefresh();
    } on StudentProfileException catch (error) {
      _handleProfileSaveError(error);
    } catch (_) {
      _showSaveFailure();
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
          _isCompletingRegistration = false;
        });
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (!_hasActiveSession()) return;

    setState(() => _showFinalValidation = true);
    final isFormValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _skillsError = _validateTagItems(_skills, label: 'skill', required: true);
      _toolsError = _validateTagItems(
        _tools,
        label: 'tool or technology',
        required: true,
      );
      _internshipTypeError = _selectedWorkArrangements.isEmpty
          ? 'Select at least one internship type.'
          : null;
      _locationError = _selectedLocations.isEmpty
          ? 'Select at least one preferred location.'
          : null;
    });

    if (!isFormValid ||
        _skillsError != null ||
        _toolsError != null ||
        _internshipTypeError != null ||
        _locationError != null ||
        !_hasCompleteProfileInputs()) {
      return;
    }

    final selectedCv = _selectedCvFile;
    if (selectedCv == null && _uploadedCvStorageKey == null) {
      setState(() {
        _cvSelectionError = 'Select a valid PDF CV to complete registration.';
        _profileMessage =
            'A PDF CV is required to complete internship registration.';
        _profileMessageIsError = true;
      });
      return;
    }

    setState(() {
      _isSavingProfile = true;
      _isCompletingRegistration = true;
      _profileMessage = null;
      _profileLoadFailed = false;
    });

    try {
      final cvBytes = selectedCv == null
          ? null
          : await _validatedPdfBytes(selectedCv);
      final result = await _profileService.saveProfile(
        profile: _buildProfileRequest(isDraft: false),
        bearerToken: StudentSession.token ?? '',
      );
      if (!mounted) return;

      setState(() {
        _campusIdPhotoUrl = result.campusIdPhotoUrl;
        if (result.cvPdfUrl.isNotEmpty) _uploadedCvStorageKey = result.cvPdfUrl;
        _cvNextEligibleUploadAt = result.cvNextEligibleUploadAt;
      });
      _scheduleCvCooldownRefresh();

      if (selectedCv != null && cvBytes != null) {
        try {
          final uploaded = await _cvUploadService.uploadPdf(
            fileBytes: cvBytes,
            fileName: selectedCv.name,
            authToken: StudentSession.token ?? '',
          );
          if (!mounted) return;
          setState(() {
            _uploadedCvStorageKey = uploaded.storageKey;
            _cvNextEligibleUploadAt = uploaded.nextEligibleUploadAt;
            _selectedCvFile = null;
            _selectedCvFileSize = null;
            _cvUploadError = null;
          });
          _scheduleCvCooldownRefresh();
        } on CvUploadException catch (error) {
          if (!mounted) return;
          if (error.statusCode == 401) _expireSession();
          setState(() {
            _profileMessage =
                'Profile saved, but the CV still needs to be uploaded. ${error.message}';
            _profileMessageIsError = true;
            _cvUploadError = error.message;
            _registrationComplete = false;
          });
          return;
        } catch (_) {
          if (!mounted) return;
          setState(() {
            _profileMessage = 'Profile saved, but the CV still needs to be uploaded. Please retry.';
            _profileMessageIsError = true;
            _registrationComplete = false;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _registrationComplete = _uploadedCvStorageKey != null;
        _profileMessage = _registrationComplete
            ? 'Internship registration completed successfully'
            : 'A PDF CV is required to complete internship registration.';
        _profileMessageIsError = !_registrationComplete;
      });
    } on StudentProfileException catch (error) {
      _handleProfileSaveError(error);
    } on CvUploadException catch (error) {
      if (mounted) {
        setState(() {
          _cvSelectionError = error.message;
          _profileMessage = error.message;
          _profileMessageIsError = true;
          _registrationComplete = false;
        });
      }
    } catch (_) {
      _showSaveFailure();
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
          _isCompletingRegistration = false;
        });
      }
    }
  }

  bool _hasActiveSession() {
    if (StudentSession.token?.trim().isNotEmpty == true) return true;
    setState(() {
      _expireSession();
      _profileMessage = 'Your session has expired. Please sign in again.';
      _profileMessageIsError = true;
    });
    return false;
  }

  void _handleProfileSaveError(StudentProfileException error) {
    if (!mounted) return;
    if (error.type == StudentProfileErrorType.unauthorized) _expireSession();
    setState(() {
      _profileMessage = error.message;
      _profileMessageIsError = true;
      _registrationComplete = false;
    });
  }

  void _showSaveFailure() {
    if (!mounted) return;
    setState(() {
      _profileMessage =
          'Unable to save your profile. Please check the form and try again.';
      _profileMessageIsError = true;
      _registrationComplete = false;
    });
  }

  StudentProfileUpsertRequest _buildProfileRequest({required bool isDraft}) {
    final graduation = DateTime.tryParse(
      _expectedGraduationController.text.trim(),
    );
    return StudentProfileUpsertRequest(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      campusIdPhotoUrl: _campusIdPhotoUrl,
      portfolioUrl: _portfolioUrlController.text.trim().isEmpty
          ? null
          : _portfolioUrlController.text.trim(),
      universityName: _universityController.text.trim(),
      academicStatus: _selectedAcademicStatus,
      degreeProgram: _selectedDegree,
      currentYearOfStudy: _selectedYearOfStudy,
      gpa: double.tryParse(_gpaController.text.trim()),
      expectedGraduationDate: graduation == null
          ? null
          : DateTime.utc(graduation.year, graduation.month, graduation.day),
      desiredJobTitle: _selectedReferenceValue(
        _jobTitles,
        _selectedJobTitleId,
        'title',
      ),
      primaryDomain: _selectedReferenceValue(
        _domains,
        _selectedDomainId,
        'name',
      ),
      careerObjectivesSummary: _careerObjectivesController.text.trim(),
      skills: List.of(_skills),
      toolsAndTechnologies: List.of(_tools),
      internshipType: _selectedWorkArrangements.toList(),
      lectureScheduleType: _selectedSchedule,
      preferredLocations: _selectedLocations.toList(),
      isDraft: isDraft,
    );
  }

  String? _selectedReferenceValue(
    List<dynamic> values,
    int? selectedId,
    String property,
  ) {
    if (selectedId == null) return null;
    for (final value in values) {
      if (value['id'] == selectedId) return value[property]?.toString();
    }
    return null;
  }

  bool _hasCompleteProfileInputs() {
    final graduation = DateTime.tryParse(
      _expectedGraduationController.text.trim(),
    );
    final today = DateTime.now();
    final gpa = double.tryParse(_gpaController.text.trim());
    return _validateFullName(_fullNameController.text, required: true) ==
            null &&
        _validatePhone(_phoneController.text, required: true) == null &&
        _validateUniversityName(_universityController.text, required: true) ==
            null &&
        _selectedAcademicStatus?.trim().isNotEmpty == true &&
        _selectedDegree?.trim().isNotEmpty == true &&
        (_selectedYearOfStudy ?? 0) >= 1 &&
        (_selectedYearOfStudy ?? 0) <= 8 &&
        gpa != null &&
        gpa >= 0 &&
        gpa <= 4 &&
        graduation != null &&
        !DateTime(
          graduation.year,
          graduation.month,
          graduation.day,
        ).isBefore(DateTime(today.year, today.month, today.day)) &&
        _selectedReferenceValue(
              _jobTitles,
              _selectedJobTitleId,
              'title',
            )?.trim().isNotEmpty ==
            true &&
        _selectedReferenceValue(
              _domains,
              _selectedDomainId,
              'name',
            )?.trim().isNotEmpty ==
            true &&
        _validateCareerObjectives(
              _careerObjectivesController.text,
              required: true,
            ) ==
            null &&
        _validateOptionalUrl(_portfolioUrlController.text) == null &&
        _validateTagItems(_skills, label: 'skill', required: true) == null &&
        _validateTagItems(
              _tools,
              label: 'tool or technology',
              required: true,
            ) ==
            null &&
        _selectedWorkArrangements.isNotEmpty &&
        _selectedSchedule?.trim().isNotEmpty == true &&
        _selectedLocations.isNotEmpty;
  }

  bool _isStoredProfileComplete(StudentProfileResponse profile) {
    final today = DateTime.now();
    final graduation = profile.expectedGraduationDate;
    return _validateFullName(profile.fullName, required: true) == null &&
        _validatePhone(profile.phone, required: true) == null &&
        _validateUniversityName(profile.universityName, required: true) ==
            null &&
        profile.academicStatus.trim().isNotEmpty &&
        profile.degreeProgram.trim().isNotEmpty &&
        profile.currentYearOfStudy >= 1 &&
        profile.currentYearOfStudy <= 8 &&
        profile.gpa >= 0 &&
        profile.gpa <= 4 &&
        graduation != null &&
        !DateTime(
          graduation.year,
          graduation.month,
          graduation.day,
        ).isBefore(DateTime(today.year, today.month, today.day)) &&
        profile.desiredJobTitle.trim().isNotEmpty &&
        profile.primaryDomain.trim().isNotEmpty &&
        _validateCareerObjectives(
              profile.careerObjectivesSummary,
              required: true,
            ) ==
            null &&
        _validateOptionalUrl(profile.portfolioUrl) == null &&
        _validateTagItems(profile.skills, label: 'skill', required: true) ==
            null &&
        _validateTagItems(
              profile.toolsAndTechnologies,
              label: 'tool or technology',
              required: true,
            ) ==
            null &&
        profile.internshipType.isNotEmpty &&
        profile.lectureScheduleType.trim().isNotEmpty &&
        profile.preferredLocations.isNotEmpty;
  }

  @override
  void dispose() {
    _cvCooldownRefreshTimer?.cancel();
    _skillController.dispose();
    _toolController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    _gpaController.dispose();
    _expectedGraduationController.dispose();
    _portfolioUrlController.dispose();
    _careerObjectivesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Build your resume',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 100.0,
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Complete your details to unlock CV upload.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_isLoadingProfile) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                    const Text('Loading student profile...'),
                    const SizedBox(height: 16),
                  ],
                  if (_profileMessage != null) ...[
                    Text(
                      _profileMessage!,
                      style: TextStyle(
                        color: _profileMessageIsError
                            ? Colors.red
                            : AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    if (_profileLoadFailed && !_isLoadingProfile)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _loadProfile,
                          child: const Text('Retry loading'),
                        ),
                      ),
                    if (_sessionExpired)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: _goToLogin,
                          child: const Text('Sign in again'),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

                  _buildCompletenessMeter(),
                  const SizedBox(height: 20),

                  _buildCardSection(
                    icon: Icons.person_outline,
                    title: 'Personal information',
                    completedFields: _completedIn([
                      _validateFullName(
                            _fullNameController.text,
                            required: true,
                          ) ==
                          null,
                      _validatePhone(_phoneController.text, required: true) ==
                          null,
                    ]),
                    totalFields: 2,
                    children: [
                      _buildInputField(
                        'Full Name',
                        Icons.person_outline,
                        _fullNameController,
                        validator: (value) => _validateFullName(
                          value,
                          required: _showFinalValidation,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        'Phone Number',
                        Icons.phone_outlined,
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: (value) => _validatePhone(
                          value,
                          required: _showFinalValidation,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Academic Information Section
                  _buildCardSection(
                    icon: Icons.school,
                    title: 'Academic background',
                    completedFields: _completedIn([
                      _validateUniversityName(
                            _universityController.text,
                            required: true,
                          ) ==
                          null,
                      _selectedDegree?.trim().isNotEmpty == true,
                      _selectedAcademicStatus?.trim().isNotEmpty == true,
                      (_selectedYearOfStudy ?? 0) >= 1 &&
                          (_selectedYearOfStudy ?? 0) <= 8,
                      double.tryParse(_gpaController.text.trim()) != null &&
                          (double.tryParse(_gpaController.text.trim()) ?? -1) >=
                              0 &&
                          (double.tryParse(_gpaController.text.trim()) ?? 5) <=
                              4,
                      _validateExpectedGraduationDate(
                            _expectedGraduationController.text,
                            required: true,
                          ) ==
                          null,
                      _selectedSchedule?.trim().isNotEmpty == true,
                    ]),
                    totalFields: 7,
                    children: [
                      _buildInputField(
                        'University / Institution',
                        Icons.account_balance,
                        _universityController,
                        validator: (value) => _validateUniversityName(
                          value,
                          required: _showFinalValidation,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDegreeDropdown(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildAcademicStatusDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildYearOfStudyDropdown()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildGpaField()),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInputField(
                              'Expected Grad',
                              Icons.event,
                              _expectedGraduationController,
                              hintText: 'YYYY-MM-DD',
                              keyboardType: TextInputType.datetime,
                              validator: (value) =>
                                  _validateExpectedGraduationDate(
                                    value,
                                    required: _showFinalValidation,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildScheduleDropdown(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Career Goals & Preferences Section
                  _buildCardSection(
                    icon: Icons.track_changes,
                    title: 'Career goals and preferences',
                    completedFields: _completedIn([
                      _selectedReferenceValue(
                            _domains,
                            _selectedDomainId,
                            'name',
                          )?.trim().isNotEmpty ==
                          true,
                      _selectedReferenceValue(
                            _jobTitles,
                            _selectedJobTitleId,
                            'title',
                          )?.trim().isNotEmpty ==
                          true,
                      _validateCareerObjectives(
                            _careerObjectivesController.text,
                            required: true,
                          ) ==
                          null,
                      _selectedWorkArrangements.isNotEmpty,
                      _selectedLocations.isNotEmpty,
                    ]),
                    totalFields: 5,
                    children: [
                      _buildInputField(
                        'Portfolio URL',
                        Icons.link,
                        _portfolioUrlController,
                        keyboardType: TextInputType.url,
                        validator: _validateOptionalUrl,
                      ),
                      const SizedBox(height: 16),
                      _buildDomainDropdown(),
                      const SizedBox(height: 16),
                      _buildJobTitleDropdown(),
                      const SizedBox(height: 16),
                      _buildTextAreaField(
                        'Career Objectives Summary',
                        _careerObjectivesController,
                        validator: (value) => _validateCareerObjectives(
                          value,
                          required: _showFinalValidation,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInternshipTypeChips(),
                      const SizedBox(height: 16),
                      _buildPreferredLocationsChips(),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Technical Profile Section
                  _buildCardSection(
                    icon: Icons.code,
                    title: 'Skills and tools',
                    completedFields: _completedIn([
                      _skills.isNotEmpty,
                      _tools.isNotEmpty,
                    ]),
                    totalFields: 2,
                    children: [
                      _buildTagsSection(
                        title: 'Core Programming & Skills',
                        tags: _skills,
                        controller: _skillController,
                        onAdd: _addSkill,
                        onRemove: (tag) => setState(() => _skills.remove(tag)),
                        validationMessage: _skillsError,
                        tagColor: AppColors.primary,
                        tagBgColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 24),
                      _buildTagsSection(
                        title: 'Tools, Cloud & Infra',
                        tags: _tools,
                        controller: _toolController,
                        onAdd: _addTool,
                        onRemove: (tag) => setState(() => _tools.remove(tag)),
                        validationMessage: _toolsError,
                        tagColor: Colors.deepPurple,
                        tagBgColor: Colors.deepPurple.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  KeyedSubtree(
                    key: _cvUploadSectionKey,
                    child: _buildCardSection(
                      icon: Icons.upload_file_outlined,
                      title: 'CV upload',
                      completedFields: _uploadedCvStorageKey == null ? 0 : 1,
                      totalFields: 1,
                      children: [
                        if (!_hasCompleteProfileInputs())
                          _buildCvLockedState()
                        else ...[
                          _buildDocumentUploadDropzone(),
                          const SizedBox(height: 12),
                          if (_uploadedCvStorageKey != null) ...[
                            const _CvUploadedStatus(),
                            const SizedBox(height: 12),
                          ],
                          _buildUploadedFileItem(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sticky Bottom Save Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ElevatedButton.icon(
                onPressed:
                    _isLoadingProfile || _isSavingProfile || _sessionExpired
                    ? null
                    : _handlePrimaryAction,
                icon: _isSavingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(_primaryButtonIcon, size: 20),
                label: Text(
                  _primaryButtonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSavingProfile
                      ? Colors.teal
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletenessMeter() {
    final completed = _completedResumeFieldCount;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resume progress',
                style: TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$completed of $_requiredResumeFieldCount details',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: completed / _requiredResumeFieldCount,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadDropzone() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload CV (PDF)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Choose a PDF from your device. '),
                const TextSpan(text: 'Maximum 10MB.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed:
                _isSelectingCv ||
                    _isSavingProfile ||
                    _isCvReplacementCooldownActive
                ? null
                : _selectCvFile,
            icon: _isSelectingCv
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            label: Text(_selectedCvFile == null ? 'Select PDF' : 'Change PDF'),
          ),
          if (_isCvReplacementCooldownActive) ...[
            const SizedBox(height: 10),
            Text(
              'You can update your CV again on ${_formatNextEligibleUpload(context)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
          if (_cvSelectionError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _cvSelectionError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          if (_cvUploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _cvUploadError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCvLockedState() {
    final remaining = _requiredResumeFieldCount - _completedResumeFieldCount;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CV upload is locked',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Complete the required resume details to unlock CV upload.${remaining > 0 ? ' $remaining remaining.' : ''}',
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem() {
    final file = _selectedCvFile;
    if (file == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _selectedCvFileSize == null
                          ? 'Size unavailable'
                          : _formatFileSize(_selectedCvFileSize!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.pending_outlined,
                      color: Colors.orange,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ready to upload',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.red,
              size: 20,
            ),
            onPressed: _isSavingProfile ? null : _removeSelectedCv,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required IconData icon,
    required String title,
    required int completedFields,
    required int totalFields,
    required List<Widget> children,
  }) {
    final isComplete = completedFields == totalFields;
    final stateLabel = isComplete
        ? 'Complete'
        : '${totalFields - completedFields} ${totalFields - completedFields == 1 ? 'field' : 'fields'} remaining';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isComplete ? AppColors.accent : AppColors.primary)
                      .withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    color: isComplete ? AppColors.accent : AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  String? _validateRequired(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required.'
        : null;
  }

  String? _validateFullName(String? value, {required bool required}) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return required ? 'Full name is required.' : null;
    final validName = RegExp(
      r"^[\p{L}\p{M}]+(?:[ '\-][\p{L}\p{M}]+)*$",
      unicode: true,
    );
    return name.length >= 2 && name.length <= 100 && validName.hasMatch(name)
        ? null
        : 'Enter a valid full name using 2 to 100 letters.';
  }

  String? _validatePhone(String? value, {required bool required}) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return required ? 'Phone number is required.' : null;
    return RegExp(r'^(?:07\d{8}|\+947\d{8})$').hasMatch(phone)
        ? null
        : 'Enter a valid Sri Lankan mobile number, for example 0771234567.';
  }

  String? _validateUniversityName(String? value, {required bool required}) {
    final university = value?.trim() ?? '';
    if (university.isEmpty)
      return required ? 'University name is required.' : null;
    final hasLetter = RegExp(r'\p{L}', unicode: true).hasMatch(university);
    final hasControlCharacter = RegExp(
      r'[\p{Cc}\p{Cf}]',
      unicode: true,
    ).hasMatch(university);
    return university.length >= 2 &&
            university.length <= 255 &&
            hasLetter &&
            !hasControlCharacter
        ? null
        : 'Enter a valid university name using 2 to 255 characters.';
  }

  String? _validateExpectedGraduationDate(
    String? value, {
    required bool required,
  }) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Expected graduation date is required.' : null;
    }

    final date = DateTime.tryParse(value.trim());
    if (date == null) {
      return 'Use YYYY-MM-DD.';
    }

    final today = DateUtils.dateOnly(DateTime.now());
    return date.isBefore(today) ? 'Date cannot be in the past.' : null;
  }

  String? _validateOptionalUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value.trim());
    return uri != null &&
            uri.isAbsolute &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty
        ? null
        : 'Enter a valid HTTPS URL.';
  }

  String? _validateCareerObjectives(String? value, {required bool required}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Career objectives are required.' : null;
    }

    final length = value.trim().length;
    if (length < 20) return 'Enter at least 20 characters.';
    if (length > 1000) {
      return 'Keep career objectives to 1000 characters or fewer.';
    }
    return null;
  }

  String? _validateGpa(String? value, {required bool required}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'GPA is required.' : null;
    }
    final gpa = double.tryParse(value.trim());
    return gpa != null && gpa >= 0 && gpa <= 4
        ? null
        : 'Enter a GPA from 0.00 to 4.00.';
  }

  String? _validateTagItems(
    List<String> items, {
    required String label,
    required bool required,
  }) {
    if (items.isEmpty) return required ? 'Add at least one $label.' : null;
    if (items.any((item) => item.trim().isEmpty)) {
      return '${label[0].toUpperCase()}${label.substring(1)} cannot be empty.';
    }
    final normalized = items.map((item) => item.trim().toLowerCase()).toSet();
    return normalized.length == items.length
        ? null
        : 'Duplicate $label entries are not allowed.';
  }

  bool _validateDraftValues() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final skillsError = _validateTagItems(
      _skills,
      label: 'skill',
      required: false,
    );
    final toolsError = _validateTagItems(
      _tools,
      label: 'tool or technology',
      required: false,
    );
    setState(() {
      _skillsError = skillsError;
      _toolsError = toolsError;
    });
    return formValid && skillsError == null && toolsError == null;
  }

  Widget _buildInputField(
    String label,
    IconData? icon,
    TextEditingController controller, {
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: validator == null
                ? const []
                : const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(color: AppColors.statusRejected),
                    ),
                  ],
          ),
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimaryLight,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.textSecondaryLight, size: 19)
                : null,
            hintText: hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedAcademicStatus,
            hint: const Text(
              'Select status',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
            items:
                {
                      ...const ['Full-time Student', 'Graduating Senior'],
                      ?_selectedAcademicStatus,
                    }
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
            onChanged: (status) =>
                setState(() => _selectedAcademicStatus = status),
            validator: (value) =>
                _showFinalValidation ? _validateRequired(value) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildYearOfStudyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Year of Study',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedYearOfStudy,
            hint: const Text(
              'Select year',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
            items: List.generate(8, (index) {
              final year = index + 1;
              return DropdownMenuItem(value: year, child: Text('Year $year'));
            }),
            onChanged: (year) => setState(() => _selectedYearOfStudy = year),
            validator: (year) =>
                _showFinalValidation && year == null ? 'Select a year.' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: label,
                  children: validator == null
                      ? const []
                      : const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: AppColors.statusRejected),
                          ),
                        ],
                ),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${controller.text.trim().length} / 1000',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimaryLight,
              height: 1.5,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lecture Schedule Type',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedSchedule,
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.calendar_month, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimaryLight,
            ),
            dropdownColor: Colors.white,
            items:
                {
                  ...const ['Weekday', 'Weekend'],
                  ?_selectedSchedule,
                }.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedSchedule = newValue);
              }
            },
            validator: (value) =>
                _showFinalValidation ? _validateRequired(value) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferredLocationsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferred Work Locations',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              {
                ...const ['Colombo', 'Gampaha', 'Kandy', 'Remote'],
                ..._selectedLocations,
              }.map((location) {
                final isSelected = _selectedLocations.contains(location);
                return FilterChip(
                  label: Text(
                    location,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedLocations.add(location);
                      } else {
                        _selectedLocations.remove(location);
                      }
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide.none,
                  ),
                  showCheckmark: true,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                );
              }).toList(),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _locationError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildInternshipTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Internship Work Arrangement',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: {...internshipTypes, ..._selectedWorkArrangements}.map((
            type,
          ) {
            final isSelected = _selectedWorkArrangements.contains(type);
            return FilterChip(
              label: Text(
                type,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedWorkArrangements.add(type);
                  } else {
                    _selectedWorkArrangements.remove(type);
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide.none,
              ),
              showCheckmark: true,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            );
          }).toList(),
        ),
        if (_internshipTypeError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _internshipTypeError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildGpaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cumulative GPA',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: _gpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimaryLight,
            ),
            decoration: const InputDecoration(
              icon: Icon(Icons.grade, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (value) =>
                _validateGpa(value, required: _showFinalValidation),
          ),
        ),
      ],
    );
  }

  Widget _buildDegreeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Degree Program',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            initialValue: _selectedDegree,
            hint: const Text(
              'Select Degree Program',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryLight,
              ),
            ),
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.menu_book, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            isExpanded: true,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimaryLight,
            ),
            dropdownColor: Colors.white,
            items: {...degreePrograms, ?_selectedDegree}.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedDegree = newValue);
            },
            validator: (value) =>
                _showFinalValidation ? _validateRequired(value) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDomainDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Primary Domain',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedDomainId,
            hint: _isLoadingDomains
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Select Domain',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.hub, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            isExpanded: true,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimaryLight,
            ),
            dropdownColor: Colors.white,
            items: _domains.isEmpty
                ? [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text(
                        'No Domains (Backend Offline?)',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ]
                : _domains.map<DropdownMenuItem<int>>((dynamic domain) {
                    return DropdownMenuItem<int>(
                      value: domain['id'],
                      child: Text(
                        domain['name'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
            onChanged: (newValue) {
              if (newValue != null &&
                  newValue != -1 &&
                  newValue != _selectedDomainId) {
                setState(() {
                  _selectedDomainId = newValue;
                });
                if (newValue > 0) _fetchJobTitles(newValue);
              }
            },
            validator: (domainId) =>
                _showFinalValidation && (domainId == null || domainId == -1)
                ? 'Select a primary domain.'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildJobTitleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Target Job Title',
          style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<int>(
            initialValue: _selectedJobTitleId,
            hint: _isLoadingTitles
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Select Job Title',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.badge, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            isExpanded: true,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimaryLight,
            ),
            dropdownColor: Colors.white,
            items: _jobTitles.isEmpty
                ? [
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text(
                        'No Titles Found',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ]
                : _jobTitles.map<DropdownMenuItem<int>>((dynamic title) {
                    return DropdownMenuItem<int>(
                      value: title['id'],
                      child: Text(
                        title['title'].toString(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
            onChanged: _selectedDomainId == null
                ? null
                : (newValue) {
                    if (newValue != -1) {
                      setState(() {
                        _selectedJobTitleId = newValue;
                      });
                    }
                  },
            validator: (jobTitleId) =>
                _showFinalValidation && (jobTitleId == null || jobTitleId == -1)
                ? 'Select a target job title.'
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection({
    required String title,
    required List<String> tags,
    required TextEditingController controller,
    required VoidCallback onAdd,
    required Function(String) onRemove,
    String? validationMessage,
    required Color tagColor,
    required Color tagBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryLight,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${tags.length} active',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tagBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tagColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onRemove(tag),
                    child: Icon(Icons.close, size: 14, color: tagColor),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimaryLight,
                  ),
                  decoration: const InputDecoration(
                    hintText: '+ Add Skill (press enter)...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: tagBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.add, size: 16, color: tagColor),
                ),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        if (validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              validationMessage,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
