import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/widgets/campus_ai_logo.dart';
import '../../../dashboard/presentation/screens/dashboard_shell_screen.dart';
import 'account_pending_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _error;
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty && password.isEmpty) {
      setState(() => _error = 'Enter your university email and password to sign in.');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Enter your university email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Enter your password.');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid university email address.');
      return;
    }

    setState(() { _isSubmitting = true; _error = null; });
    try {
      final result = await ApiService().login(email, password);
      if (result['isPending'] == true) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccountPendingScreen()));
        return;
      }
      if (result['success'] != true || result['role'] != 'Student') {
        throw Exception('Use an approved student account to access this portal.');
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const DashboardShellScreen()), (route) => false);
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const CampusAILogo(size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'CampusAI',
                  style: TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'STUDENT PORTAL',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Sign in to explore internship opportunities, manage applications, and stay updated on your placement journey.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Main Authentication Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sign in to your student account',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Use the email and password you registered with.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 24),
                    _buildLabeledField(
                      label: 'University Student Email',
                      required: true,
                      hint: 'e.g. a.morgan@university.edu',
                      icon: Icons.mail_outline,
                      controller: _email,
                      trailing: const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      helperText: 'Only authorized institutional accounts are permitted.',
                      helperIcon: Icons.domain,
                      rightLabel: 'Domain Verified',
                    ),
                    const SizedBox(height: 20),

                    _buildLabeledField(
                      label: 'Password',
                      required: true,
                      hint: 'Enter secure password',
                      icon: Icons.lock_outline,
                      controller: _password,
                      obscureText: _obscurePassword,
                      onToggleVisibility: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text)),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.lock_reset_outlined, size: 17),
                        label: const Text('Forgot password?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Sign In Button
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _login,
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
                          else const Icon(Icons.login, size: 20),
                          const SizedBox(width: 8),
                          Text(_isSubmitting ? 'Signing in...' : 'Sign In to Student Portal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Alternative SSO Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: AppColors.borderLight)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('FIRST TIME HERE?', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey, letterSpacing: 0.7)),
                  ),
                  Expanded(child: Divider(color: AppColors.borderLight)),
                ],
              ),
              const SizedBox(height: 18),

              // Registration Redirection Card
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Need a student account? ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Register Now',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Security & Compliance Badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.verified_user_outlined, size: 17, color: Colors.grey),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Secured end-to-end with 256-bit placement ledger encryption. Authorized access only.',
                        style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
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
    String? rightLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            if (rightLabel != null)
              Text(
                rightLabel,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent),
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
                      tooltip: obscureText ? 'Show password' : 'Hide password',
                      icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off, color: Colors.grey, size: 20),
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
                Icon(helperIcon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  helperText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
