import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import 'account_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;
  String? _error;
  PlatformFile? _campusId;
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _university = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  @override
  void dispose() {
    for (final controller in [_fullName, _email, _phone, _university, _password, _confirmPassword]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCampusId() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png'], withData: true);
    final file = result?.files.single;
    if (file == null) return;
    if (file.size > 5 * 1024 * 1024) {
      setState(() => _error = 'Campus ID must be smaller than 5 MB.');
      return;
    }
    setState(() { _campusId = file; _error = null; });
  }

  Future<void> _submit() async {
    if ([_fullName, _email, _phone, _university, _password, _confirmPassword].any((c) => c.text.trim().isEmpty)) {
      setState(() => _error = 'Complete every required field.');
      return;
    }
    if (_password.text.length < 8 || _password.text != _confirmPassword.text) {
      setState(() => _error = 'Passwords must match and contain at least 8 characters.');
      return;
    }
    if (_campusId == null) {
      setState(() => _error = 'Upload a campus ID photo.');
      return;
    }
    setState(() { _isSubmitting = true; _error = null; });
    try {
      await ApiService().registerStudent(
        fullName: _fullName.text,
        email: _email.text,
        phone: _phone.text,
        universityName: _university.text,
        password: _password.text,
        campusId: _campusId!,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccountPendingScreen()));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimaryLight),
            ),
          ),
        ),
        leadingWidth: 64,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'Student Registration',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your student placement profile to access campus hiring drives and AI career matching.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Role Indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Student Candidate',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildLabeledField(
              label: 'Full Legal Name',
              required: true,
              hint: 'Enter full legal name',
              icon: Icons.person_outline,
              controller: _fullName,
              trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 20),

            _buildLabeledField(
              label: 'University Student Email',
              required: true,
              hint: 'your.name@university.edu',
              icon: Icons.mail_outline,
              controller: _email,
              trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
              helperText: 'Use official university student domain (@university.edu)',
              helperIcon: Icons.domain,
            ),
            const SizedBox(height: 20),

            _buildLabeledField(
              label: 'Mobile Phone Number',
              required: true,
              hint: '+1 (555) 000-0000',
              icon: Icons.phone_iphone_outlined,
              controller: _phone,
              trailing: const Icon(Icons.verified, color: AppColors.primary, size: 20),
              helperText: 'Used for secure two-factor auth & drive interview alerts',
            ),
            const SizedBox(height: 20),

            _buildLabeledField(
              label: 'University Name',
              required: true,
              hint: 'Enter your university',
              icon: Icons.account_balance_outlined,
              controller: _university,
            ),
            const SizedBox(height: 20),

            _buildLabeledField(
              label: 'Create Password',
              required: true,
              hint: 'At least 8 characters',
              icon: Icons.lock_outline,
              controller: _password,
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              showPasswordStrength: true,
            ),
            const SizedBox(height: 20),

            _buildLabeledField(
              label: 'Confirm Password',
              required: true,
              hint: 'Re-enter password',
              icon: Icons.shield_outlined,
              controller: _confirmPassword,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              helperText: 'Passwords match',
              helperIcon: Icons.done_all,
              helperColor: AppColors.primary,
            ),
            const SizedBox(height: 32),

            // Campus ID Upload Section
            _buildCampusIdUploadSection(),
            const SizedBox(height: 32),

            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isSubmitting) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  else const Icon(Icons.person_add_alt_1, size: 20),
                  const SizedBox(width: 8),
                  Text(_isSubmitting ? 'Uploading ID...' : 'Create Student Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Institutional Review Protocol',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimaryLight),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your account will be manually verified by your University Placement Cell before you can build your resume or submit job drive applications.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account?', style: TextStyle(color: AppColors.textSecondaryLight)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Log in', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ),
              ],
            ),
            const Center(
              child: Text(
                'CampusAI Placement Ecosystem • v4.8.2',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required bool required,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
    Widget? trailing,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? helperText,
    IconData? helperIcon,
    Color? helperColor,
    bool showPasswordStrength = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimaryLight),
            ),
            if (required) const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(color: Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(icon, color: Colors.grey, size: 22),
              suffixIcon: onToggleVisibility != null
                  ? IconButton(
                      icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20),
                      onPressed: onToggleVisibility,
                    )
                  : trailing,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (helperIcon != null) ...[
                Icon(helperIcon, size: 14, color: helperColor ?? Colors.grey),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  helperText,
                  style: TextStyle(
                    fontSize: 12,
                    color: helperColor ?? Colors.grey,
                    fontWeight: helperColor != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showPasswordStrength) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 8),
              const Text('Strong', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCampusIdUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Campus ID Card Photo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimaryLight),
            ),
            Text(' *', style: TextStyle(color: Colors.red, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickCampusId,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 36),
                const SizedBox(height: 12),
                Text(
                  _campusId?.name ?? 'Tap to upload your ID card',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG, PNG (Max 5MB)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
