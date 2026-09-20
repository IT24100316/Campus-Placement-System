import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> _skills = ['Python', 'Dart / Flutter', 'TypeScript', 'React', 'PyTorch', 'PostgreSQL'];
  final List<String> _tools = ['Docker', 'AWS', 'Git & GitHub', 'Kubernetes', 'Figma', 'FastAPI'];
  
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _toolController = TextEditingController();
  final TextEditingController _gpaController = TextEditingController(text: '3.88');

  final Set<String> _selectedWorkArrangements = {'Remote', 'Hybrid'};
  final Set<String> _selectedLocations = {'Colombo', 'Remote'};
  String _selectedSchedule = 'Weekday';
  String? _selectedDegree;

  bool _isSaving = false;
  String _saveButtonText = 'Save Resume';
  IconData _saveButtonIcon = Icons.verified;

  final String _baseUrl = 'http://127.0.0.1:5168';

  List<dynamic> _domains = [];
  List<dynamic> _jobTitles = [];
  bool _isLoadingDomains = false;
  bool _isLoadingTitles = false;
  int? _selectedDomainId;
  int? _selectedJobTitleId;

  static const List<String> degreePrograms = ['BSc (Hons) Information Technology', 'BSc (Hons) Software Engineering', 'BSc (Hons) Computer Science', 'BSc (Hons) Data Science', 'BSc (Hons) Cyber Security'];
  static const List<String> internshipTypes = ['OnSite', 'Hybrid', 'Remote'];

  @override
  void initState() {
    super.initState();
    _fetchDomains();
  }

  Future<void> _fetchDomains() async {
    setState(() => _isLoadingDomains = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/Jobs/reference/domains'));
      if (response.statusCode == 200) {
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
      final response = await http.get(Uri.parse('$_baseUrl/api/Jobs/reference/titles?domainId=$domainId'));
      if (response.statusCode == 200) {
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

  void _triggerSaveAnimation() async {
    setState(() {
      _isSaving = true;
      _saveButtonText = 'Profile Synchronized!';
      _saveButtonIcon = Icons.check_circle;
    });

    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _saveButtonText = 'Save Resume';
        _saveButtonIcon = Icons.verified;
      });
    }
  }

  @override
  void dispose() {
    _skillController.dispose();
    _toolController.dispose();
    _gpaController.dispose();
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
                ),
                Text(
                  'Autonomous Placement',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight, fontWeight: FontWeight.normal),
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
              child: Icon(Icons.notifications_outlined, color: AppColors.textSecondaryLight),
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
                  child: const Icon(Icons.person, color: Colors.white, size: 18),
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
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
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
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'My Resume',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimaryLight),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Build and synchronize your placement profile for AI match drives',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
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
                      child: const Icon(Icons.description, color: AppColors.primary, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildCompletenessMeter(),
                const SizedBox(height: 24),

                // Document Upload Section
                _buildSectionHeader('upload_file', 'Document Upload', badgeText: 'Primary Source'),
                const SizedBox(height: 12),
                _buildDocumentUploadDropzone(),
                const SizedBox(height: 12),
                _buildUploadedFileItem(),
                const SizedBox(height: 24),

                // Academic Information Section
                _buildCardSection(
                  icon: Icons.school,
                  title: 'Academic Information',
                  headerBadgeIcon: Icons.verified_user,
                  children: [
                    _buildInputField('University / Institution', Icons.account_balance, 'Stanford University / National Institute of Technology'),
                    const SizedBox(height: 16),
                    _buildDegreeDropdown(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildDropdownField('Status', null, ['Full-time Student', 'Graduating Senior'])),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDropdownField('Year of Study', null, ['4th Year (Final)', '3rd Year (Junior)'])),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildGpaField()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInputField('Expected Grad', Icons.event, 'June 2026')),
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
                    _buildInputField('Portfolio URL', Icons.link, 'https://github.com/alexmorgan'),
                    const SizedBox(height: 16),
                    _buildDomainDropdown(),
                    const SizedBox(height: 16),
                    _buildJobTitleDropdown(),
                    const SizedBox(height: 16),
                    _buildTextAreaField('Career Objectives Summary', 'Passionate software engineer focused on building robust scalable systems and generative AI infrastructure. Seeking summer internship or graduate engineering role.'),
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
                      tagColor: Colors.deepPurple,
                      tagBgColor: Colors.deepPurple.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sticky Bottom Save Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ElevatedButton.icon(
                onPressed: _triggerSaveAnimation,
                icon: Icon(_saveButtonIcon, size: 20),
                label: Text(_saveButtonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving ? Colors.teal : AppColors.primary,
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
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
                  Text('Profile Completeness', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('85% Complete', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.5), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('13 of 15 parameters optimized', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                ],
              ),
              const Text('View Gaps', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String iconName, String title, {String? badgeText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.upload_file, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
          ],
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
            child: Text(badgeText, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)), // Approximating dashed with a light solid border
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
            child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('Upload CV (PDF)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Drag & drop or '),
                const TextSpan(text: 'tap to browse', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                const TextSpan(text: ' from device. Maximum 10MB.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)]),
                child: const Text('PDF format only', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                child: const Text('Campus AI OCR', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUploadedFileItem() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.picture_as_pdf, color: Colors.red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('alex_morgan_cv_2025.pdf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text('1.8 MB', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                    const SizedBox(width: 6),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Icon(Icons.task_alt, color: Colors.teal, size: 12),
                    const SizedBox(width: 4),
                    const Text('AI Parsed', style: TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: Colors.grey, size: 20),
            onPressed: () {},
            style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red, size: 20),
            onPressed: () {},
            style: IconButton.styleFrom(backgroundColor: Colors.red.shade50, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({required IconData icon, required String title, IconData? headerBadgeIcon, String? headerBadgeText, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
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
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                ],
              ),
              if (headerBadgeIcon != null && headerBadgeText == null)
                Icon(headerBadgeIcon, color: AppColors.primary, size: 20),
              if (headerBadgeIcon != null && headerBadgeText != null)
                Row(
                  children: [
                    Icon(headerBadgeIcon, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(headerBadgeText, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildInputField(String label, IconData? icon, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            initialValue: initialValue,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
            decoration: InputDecoration(
              icon: icon != null ? Icon(icon, color: Colors.grey, size: 20) : null,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, IconData? icon, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(items.first, style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, String initialValue) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            const Text('174 / 300', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            initialValue: initialValue,
            maxLines: 3,
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight, height: 1.5),
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
        const Text('Lecture Schedule Type', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonFormField<String>(
            value: _selectedSchedule,
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.calendar_month, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
            dropdownColor: Colors.white,
            items: ['Weekday', 'Weekend'].map((String value) {
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
          ),
        ),
      ],
    );
  }

  Widget _buildPreferredLocationsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preferred Work Locations', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Colombo', 'Gampaha', 'Kandy', 'Remote'].map((location) {
            final isSelected = _selectedLocations.contains(location);
            return FilterChip(
              label: Text(
                location,
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInternshipTypeChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Internship Work Arrangement', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: internshipTypes.map((type) {
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
      ],
    );
  }

  Widget _buildGpaField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Cumulative GPA', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: TextFormField(
            controller: _gpaController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
            decoration: const InputDecoration(
              icon: Icon(Icons.grade, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final numValue = double.tryParse(value);
              if (numValue == null || numValue < 0.0 || numValue > 4.0) {
                return 'Invalid';
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
        const Text('Degree Program', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonFormField<String>(
            value: _selectedDegree,
            hint: const Text('Select Degree Program', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.menu_book, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
            dropdownColor: Colors.white,
            items: degreePrograms.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _selectedDegree = newValue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDomainDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Domain', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonFormField<int>(
            value: _selectedDomainId,
            hint: _isLoadingDomains
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Select Domain', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.hub, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
            dropdownColor: Colors.white,
            items: _domains.isEmpty 
              ? [const DropdownMenuItem<int>(value: -1, child: Text('No Domains (Backend Offline?)', style: TextStyle(color: Colors.red)))]
              : _domains.map<DropdownMenuItem<int>>((dynamic domain) {
                  return DropdownMenuItem<int>(
                    value: domain['id'],
                    child: Text(domain['name'].toString(), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
            onChanged: (newValue) {
              if (newValue != null && newValue != -1 && newValue != _selectedDomainId) {
                setState(() {
                  _selectedDomainId = newValue;
                });
                _fetchJobTitles(newValue);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJobTitleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Target Job Title', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonFormField<int>(
            value: _selectedJobTitleId,
            hint: _isLoadingTitles
                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Select Job Title', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            icon: const Icon(Icons.expand_more, color: Colors.grey, size: 18),
            decoration: const InputDecoration(
              icon: Icon(Icons.badge, color: Colors.grey, size: 20),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
            dropdownColor: Colors.white,
            items: _jobTitles.isEmpty
              ? [const DropdownMenuItem<int>(value: -1, child: Text('No Titles Found', style: TextStyle(color: Colors.red)))]
              : _jobTitles.map<DropdownMenuItem<int>>((dynamic title) {
                  return DropdownMenuItem<int>(
                    value: title['id'],
                    child: Text(title['title'].toString(), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
            onChanged: _selectedDomainId == null ? null : (newValue) {
              if (newValue != -1) {
                setState(() {
                  _selectedJobTitleId = newValue;
                });
              }
            },
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
    required Color tagColor,
    required Color tagBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
            Text('${tags.length} active', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tagColor)),
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
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onSubmitted: (_) => onAdd(),
                  style: const TextStyle(fontSize: 13, color: AppColors.textPrimaryLight),
                  decoration: const InputDecoration(
                    hintText: '+ Add Skill (press enter)...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.add, size: 16, color: tagColor),
                ),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
