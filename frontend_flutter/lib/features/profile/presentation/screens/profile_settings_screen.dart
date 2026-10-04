import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../../../auth/presentation/screens/landing_screen.dart';
import '../../data/student_profile_models.dart';
import '../../data/student_profile_service.dart';
import 'personal_details_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final StudentProfileService _profileService = StudentProfileService();
  StudentProfileResponse? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final token = StudentSession.token?.trim();
    if (token == null || token.isEmpty) return;
    try {
      final profile = await _profileService.loadProfile(bearerToken: token);
      if (mounted) setState(() => _profile = profile);
    } on StudentProfileException {
      // Session display details remain available when the profile is unavailable.
    } catch (_) {
      // Keep the account screen usable without replacing real data with mock data.
    }
  }

  String get _displayName {
    final profileName = _profile?.fullName.trim() ?? '';
    final sessionName = StudentSession.fullName?.trim() ?? '';
    if (profileName.isNotEmpty) return profileName;
    if (sessionName.isNotEmpty) return sessionName;
    return 'Student';
  }

  String get _displayEmail => StudentSession.email?.trim() ?? '';

  String get _initials {
    final words = _displayName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'S';
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();
    return (words.first[0] + words.last[0]).toUpperCase();
  }

  bool get _hasUploadedCv => _profile?.cvPdfUrl.trim().isNotEmpty == true;

  Future<void> _openPersonalDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonalDetailsScreen(initialProfile: _profile),
      ),
    );
    if (mounted) _loadProfile();
  }

  void _signOut() {
    StudentSession.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = _profile?.phone.trim() ?? '';
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                initials: _initials,
                name: _displayName,
                email: _displayEmail,
                hasUploadedCv: _hasUploadedCv,
              ),
              const SizedBox(height: 28),
              const _SectionLabel(label: 'ACCOUNT'),
              const SizedBox(height: 8),
              _SettingsSurface(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal details',
                    subtitle: phone.isEmpty ? null : phone,
                    onTap: _openPersonalDetails,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionLabel(label: 'ACCOUNT SECURITY'),
              const SizedBox(height: 8),
              _SettingsSurface(
                children: [
                  const _SettingsRow(
                    icon: Icons.key_outlined,
                    title: 'Change password',
                    showChevron: false,
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _SettingsRow(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    isDestructive: true,
                    onTap: _signOut,
                    showChevron: false,
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.hasUploadedCv,
  });

  final String initials;
  final String name;
  final String email;
  final bool hasUploadedCv;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.25,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 13,
                  ),
                ),
              ],
              if (hasUploadedCv) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'CV uploaded',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

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

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFB42318)
        : AppColors.textPrimaryLight;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDestructive
                  ? const Color(0xFFFFF1F0)
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondaryLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive
                  ? const Color(0xFFB42318)
                  : AppColors.textSecondaryLight,
            ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: row,
    );
  }
}
