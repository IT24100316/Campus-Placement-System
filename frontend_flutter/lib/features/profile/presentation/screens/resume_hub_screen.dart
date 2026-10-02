import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Presentation prototype for a student's public application resume.
class ResumeHubScreen extends StatelessWidget {
  const ResumeHubScreen({super.key});

  void _showApplicationComposer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Start an application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 7),
          const Text('Choose how you want to begin your internship application.', style: TextStyle(color: AppColors.textSecondaryLight)),
          const SizedBox(height: 18),
          _SheetAction(icon: Icons.upload_file_outlined, title: 'Use this resume', subtitle: 'Apply with your current PDF', onTap: () => Navigator.pop(context)),
          const SizedBox(height: 10),
          _SheetAction(icon: Icons.edit_note_rounded, title: 'Tailor a new version', subtitle: 'Create a role-specific resume', onTap: () => Navigator.pop(context)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FF),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showApplicationComposer(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New application', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('My resume', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
            const SizedBox(height: 6),
            const Text('The story employers see when you apply.', style: TextStyle(color: AppColors.textSecondaryLight)),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1E1B4B), Color(0xFF4F46E5)]), borderRadius: BorderRadius.circular(25)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [CircleAvatar(radius: 25, backgroundColor: Color(0xFFDCD8FF), child: Text('AM', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800))), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Alex Morgan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)), Text('Software Engineering • Year 3', style: TextStyle(color: Color(0xFFDCD8FF), fontSize: 12))]))]),
                const SizedBox(height: 20),
                const Row(children: [Expanded(child: _ResumeMetric(value: '82%', label: 'profile score')), Expanded(child: _ResumeMetric(value: '12', label: 'skills added')), Expanded(child: _ResumeMetric(value: '3', label: 'projects'))]),
                const SizedBox(height: 19),
                const LinearProgressIndicator(value: .82, minHeight: 7, borderRadius: BorderRadius.all(Radius.circular(8)), backgroundColor: Color(0x55FFFFFF), valueColor: AlwaysStoppedAnimation(Color(0xFF6EE7B7))),
              ]),
            ),
            const SizedBox(height: 25),
            const Text('Resume sections', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const _ResumeSection(icon: Icons.person_outline_rounded, title: 'About me', detail: 'A short, confident introduction', complete: true),
            const _ResumeSection(icon: Icons.psychology_outlined, title: 'Skills & strengths', detail: 'Flutter, Dart, UI design + 9 more', complete: true),
            const _ResumeSection(icon: Icons.rocket_launch_outlined, title: 'Projects', detail: 'Show the work you are proud of', complete: false),
            const _ResumeSection(icon: Icons.workspace_premium_outlined, title: 'Achievements', detail: 'Certifications, awards and activities', complete: false),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: const Color(0xFFE9E7F4))), child: const Row(children: [Icon(Icons.tips_and_updates_outlined, color: Color(0xFFF59E0B)), SizedBox(width: 11), Expanded(child: Text('Add a project with results to make your profile stand out.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))])),
          ]),
        ),
      ),
    );
  }
}

class _ResumeMetric extends StatelessWidget {
  const _ResumeMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 21, color: Colors.white, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFDCD8FF)))]);
}

class _ResumeSection extends StatelessWidget {
  const _ResumeSection({required this.icon, required this.title, required this.detail, required this.complete});
  final IconData icon;
  final String title;
  final String detail;
  final bool complete;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE9E7F4))), child: Row(children: [Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .09), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: AppColors.primary)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(detail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))])), Icon(complete ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, color: complete ? AppColors.accent : AppColors.primary)])));
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Ink(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFF7F7FF), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight))])), const Icon(Icons.chevron_right_rounded)])));
}
