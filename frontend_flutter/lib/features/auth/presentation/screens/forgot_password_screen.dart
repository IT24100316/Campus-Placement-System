import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;
  bool _hideNewPassword = true;
  bool _hideConfirmation = true;
  bool _emailVerified = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
      _message = null;
    });
    try {
      final message = await ApiService().requestPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _emailVerified = true;
        _message = message;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
      _message = null;
    });
    try {
      await ApiService().resetPassword(
        email: _email.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully. Please sign in.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _friendlyError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(backgroundColor: AppColors.backgroundLight, elevation: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 460),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 44),
                      const SizedBox(height: 16),
                      Text(
                        _emailVerified ? 'Set a new password' : 'Forgot your password?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _emailVerified
                            ? 'Choose a new password for your verified student account.'
                            : 'Enter the email for your approved student account to continue.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      if (_message != null) _notice(_message!, AppColors.primary),
                      if (_error != null) _notice(_error!, Colors.red),
                      if (_message != null || _error != null) const SizedBox(height: 16),
                      TextFormField(
                        controller: _email,
                        enabled: !_emailVerified && !_isSubmitting,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _decoration('University email', Icons.email_outlined),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty) return 'Enter your university email.';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      if (_emailVerified) ...[
                        _passwordField(
                          controller: _newPassword,
                          label: 'New password',
                          hidden: _hideNewPassword,
                          onToggle: () => setState(() => _hideNewPassword = !_hideNewPassword),
                          validator: (value) => (value?.length ?? 0) >= 8
                              ? null
                              : 'Use at least 8 characters.',
                        ),
                        const SizedBox(height: 16),
                        _passwordField(
                          controller: _confirmPassword,
                          label: 'Confirm new password',
                          hidden: _hideConfirmation,
                          onToggle: () => setState(() => _hideConfirmation = !_hideConfirmation),
                          validator: (value) => value == _newPassword.text
                              ? null
                              : 'Passwords do not match.',
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : (_emailVerified ? _resetPassword : _verifyEmail),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_emailVerified ? 'Reset password' : 'Continue'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _notice(String text, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool hidden,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) => TextFormField(
        controller: controller,
        obscureText: hidden,
        decoration: _decoration(label, Icons.lock_outline).copyWith(
          suffixIcon: IconButton(
            tooltip: hidden ? 'Show password' : 'Hide password',
            icon: Icon(hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: onToggle,
          ),
        ),
        validator: validator,
      );
}
