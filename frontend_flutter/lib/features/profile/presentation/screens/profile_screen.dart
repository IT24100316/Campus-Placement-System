import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/api_service.dart';
import '../../data/student_profile_models.dart';
import '../../data/student_profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.profileService, this.referenceClient});

  final StudentProfileService? profileService;
  final http.Client? referenceClient;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const int _maxCvFileSizeBytes = 10 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
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
  String _saveButtonText = 'Save Profile';
  IconData _saveButtonIcon = Icons.save_outlined;
  String? _profileMessage;
  bool _profileMessageIsError = false;
  bool _profileLoadFailed = false;

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
  bool _isSelectingCv = false;

  late final StudentProfileService _profileService;
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
    _referenceClient = widget.referenceClient ?? http.Client();
    _initializeProfile();
  }

  Future<void> _initializeProfile() async {
    await _fetchDomains();
    await _loadProfile();
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
        });
        return;
      }
      await _populateProfile(profile);
      if (mounted) {
        setState(() {
          _profileMessage = 'Your saved profile is ready to edit.';
          _profileMessageIsError = false;
        });
      }
    } on StudentProfileException catch (error) {
      if (mounted) {
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
    if (text.isNotEmpty && !_skills.contains(text)) {
      setState(() {
        _skills.add(text);
        _skillController.clear();
      });
    }
  }

  void _addTool() {
    final text = _toolController.text.trim();
    if (text.isNotEmpty && !_tools.contains(text)) {
      setState(() {
        _tools.add(text);
        _toolController.clear();
      });
    }
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
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );

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

  Future<void> _saveProfile() async {
    if (_isLoadingProfile || _isSavingProfile) {
      return;
    }

    final isFormValid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _skillsError = _skills.isEmpty ? 'Add at least one skill.' : null;
      _toolsError = _tools.isEmpty
          ? 'Add at least one tool or technology.'
          : null;
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
        _locationError != null) {
      return;
    }

    setState(() {
      _isSavingProfile = true;
      _profileMessage = null;
      _profileLoadFailed = false;
      _saveButtonText = 'Saving...';
    });

    try {
      final graduation = DateTime.parse(
        _expectedGraduationController.text.trim(),
      );
      final domain = _domains.firstWhere(
        (item) => item['id'] == _selectedDomainId,
      );
      final title = _jobTitles.firstWhere(
        (item) => item['id'] == _selectedJobTitleId,
      );
      final request = StudentProfileUpsertRequest(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        campusIdPhotoUrl: _campusIdPhotoUrl,
        portfolioUrl: _portfolioUrlController.text.trim().isEmpty
            ? null
            : _portfolioUrlController.text.trim(),
        universityName: _universityController.text.trim(),
        academicStatus: _selectedAcademicStatus!,
        degreeProgram: _selectedDegree!,
        currentYearOfStudy: _selectedYearOfStudy!,
        gpa: double.parse(_gpaController.text.trim()),
        expectedGraduationDate: DateTime.utc(
          graduation.year,
          graduation.month,
          graduation.day,
        ),
        desiredJobTitle: title['title'].toString(),
        primaryDomain: domain['name'].toString(),
        careerObjectivesSummary: _careerObjectivesController.text.trim(),
        skills: List.of(_skills),
        toolsAndTechnologies: List.of(_tools),
        internshipType: _selectedWorkArrangements.toList(),
        lectureScheduleType: _selectedSchedule!,
        preferredLocations: _selectedLocations.toList(),
      );
      final result = await _profileService.saveProfile(
        profile: request,
        bearerToken: StudentSession.token ?? '',
      );

      if (!mounted) return;

      setState(() {
        _campusIdPhotoUrl = result.campusIdPhotoUrl;
        _uploadedCvStorageKey = result.cvPdfUrl.isEmpty
            ? null
            : result.cvPdfUrl;
        _profileMessage = 'Student profile saved successfully.';
        _profileMessageIsError = false;
        _saveButtonText = 'Profile Saved';
        _saveButtonIcon = Icons.check_circle;
      });
    } on StudentProfileException catch (error) {
      if (mounted) {
        setState(() {
          _profileMessage = error.message;
          _profileMessageIsError = true;
          _saveButtonText = 'Save Profile';
          _saveButtonIcon = Icons.save_outlined;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _profileMessage = 'Unable to save your profile. Please check the form and try again.';
          _profileMessageIsError = true;
          _saveButtonText = 'Save Profile';
          _saveButtonIcon = Icons.save_outlined;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  @override
  void dispose() {
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
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.layers, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CampusAI Portal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  'Autonomous Placement',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.normal,
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
              smallSize: 8,
              child: Icon(
                Icons.notifications_outlined,
                color: AppColors.textSecondaryLight,
              ),
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header & Completeness
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AUTONOMOUS MATCH READY',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'My Resume',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Build and synchronize your placement profile for AI match drives',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

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
                    const SizedBox(height: 16),
                  ],

                  _buildCompletenessMeter(),
                  const SizedBox(height: 24),

                  // Document Upload Section
                  _buildSectionHeader(
                    'upload_file',
                    'Document Upload',
                    badgeText: 'Primary Source',
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentUploadDropzone(),
                  const SizedBox(height: 12),
                  _buildUploadedFileItem(),
                  const SizedBox(height: 24),

                  _buildCardSection(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    children: [
                      _buildInputField(
                        'Full Name',
                        Icons.person_outline,
                        _fullNameController,
                        validator: _validateRequired,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        'Phone Number',
                        Icons.phone_outlined,
                        _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: _validatePhone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Academic Information Section
                  _buildCardSection(
                    icon: Icons.school,
                    title: 'Academic Information',
                    headerBadgeIcon: Icons.verified_user,
                    children: [
                      _buildInputField(
                        'University / Institution',
                        Icons.account_balance,
                        _universityController,
                        validator: _validateRequired,
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
                              validator: _validateExpectedGraduationDate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildScheduleDropdown(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Career Goals & Preferences Section
                  _buildCardSection(
                    icon: Icons.track_changes,
                    title: 'Career Goals & Preferences',
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
                        validator: _validateCareerObjectives,
                      ),
                      const SizedBox(height: 16),
                      _buildInternshipTypeChips(),
                      const SizedBox(height: 16),
                      _buildPreferredLocationsChips(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Technical Profile Section
                  _buildCardSection(
                    icon: Icons.code,
                    title: 'Technical Profile',
                    headerBadgeText: 'Sync Engine',
                    headerBadgeIcon: Icons.auto_awesome,
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
                onPressed: _isLoadingProfile || _isSavingProfile
                    ? null
                    : _saveProfile,
                icon: _isSavingProfile
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(_saveButtonIcon, size: 20),
                label: Text(
                  _saveButtonText,
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
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified, color: AppColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Profile Completeness',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '85% Complete',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.85,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '13 of 15 parameters optimized',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const Text(
                'View Gaps',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String iconName,
    String title, {
    String? badgeText,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.upload_file, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentUploadDropzone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
        ), // Approximating dashed with a light solid border
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: AppColors.primary,
              size: 26,
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
                const TextSpan(text: 'Drag & drop or '),
                const TextSpan(
                  text: 'tap to browse',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(text: ' from device. Maximum 10MB.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: const Text(
                  'PDF format only',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Campus AI OCR',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSelectingCv || _isSavingProfile
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
                Row(
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
                      _uploadedCvStorageKey == null
                          ? Icons.pending_outlined
                          : Icons.check_circle_outline,
                      color: _uploadedCvStorageKey == null
                          ? Colors.orange
                          : Colors.teal,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _uploadedCvStorageKey == null
                          ? 'Ready to upload'
                          : 'Uploaded',
                      style: TextStyle(
                        fontSize: 11,
                        color: _uploadedCvStorageKey == null
                            ? Colors.orange
                            : Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_uploadedCvStorageKey != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Storage ID: $_uploadedCvStorageKey',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
    IconData? headerBadgeIcon,
    String? headerBadgeText,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              if (headerBadgeIcon != null && headerBadgeText == null)
                Icon(headerBadgeIcon, color: AppColors.primary, size: 20),
              if (headerBadgeIcon != null && headerBadgeText != null)
                Row(
                  children: [
                    Icon(headerBadgeIcon, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      headerBadgeText,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required.';
    return RegExp(r'^\+?[0-9][0-9\s\-()]{6,24}$').hasMatch(phone)
        ? null
        : 'Enter a valid phone number.';
  }

  String? _validateExpectedGraduationDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Expected graduation date is required.';
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
    return uri != null && uri.hasScheme && uri.hasAuthority
        ? null
        : 'Enter a valid URL.';
  }

  String? _validateCareerObjectives(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Career objectives are required.';
    }

    return value.trim().length < 20 ? 'Enter at least 20 characters.' : null;
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimaryLight,
            ),
            decoration: InputDecoration(
              icon: icon != null
                  ? Icon(icon, color: Colors.grey, size: 20)
                  : null,
              hintText: hintText,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            value: _selectedAcademicStatus,
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
                      if (_selectedAcademicStatus != null)
                        _selectedAcademicStatus!,
                    }
                    .map(
                      (status) =>
                          DropdownMenuItem(value: status, child: Text(status)),
                    )
                    .toList(),
            onChanged: (status) =>
                setState(() => _selectedAcademicStatus = status),
            validator: _validateRequired,
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
            value: _selectedYearOfStudy,
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
            validator: (year) => year == null ? 'Select a year.' : null,
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const Text(
              '174 / 300',
              style: TextStyle(
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
            value: _selectedSchedule,
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
                  if (_selectedSchedule != null) _selectedSchedule!,
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
            validator: _validateRequired,
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
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'GPA is required.';
              final numValue = double.tryParse(value);
              if (numValue == null || numValue < 0.0 || numValue > 4.0) {
                return 'Enter a GPA from 0.00 to 4.00.';
              }
              return null;
            },
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
            value: _selectedDegree,
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
            items:
                {
                  ...degreePrograms,
                  if (_selectedDegree != null) _selectedDegree!,
                }.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedDegree = newValue);
            },
            validator: _validateRequired,
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
            value: _selectedDomainId,
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
            validator: (domainId) => domainId == null || domainId == -1
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
            value: _selectedJobTitleId,
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
            validator: (jobTitleId) => jobTitleId == null || jobTitleId == -1
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
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
