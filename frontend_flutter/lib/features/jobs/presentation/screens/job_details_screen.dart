import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/job_details_model.dart';
import '../../data/repositories/job_repository.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  final JobRepository _repository = JobRepository();
  bool _isLoading = true;
  JobDetailsModel? _jobDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final details = await _repository.fetchJobDetails(widget.jobId);
      setState(() {
        _jobDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load job details.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_errorMessage != null || _jobDetails == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundLight,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        ),
        body: Center(child: Text(_errorMessage ?? 'Unknown error', style: const TextStyle(color: AppColors.textPrimaryLight))),
      );
    }

    final job = _jobDetails!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
        title: Text(
          job.companyName,
          style: const TextStyle(
            color: AppColors.textPrimaryLight,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${job.companyName} • ${job.locationCity}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Overview
            _buildSectionCard(
              title: 'Overview',
              child: Text(
                job.jobDescriptionSummary,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryLight,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Requirements
            _buildSectionCard(
              title: 'Requirements',
              child: Column(
                children: [
                  _buildInfoRow(Icons.school_outlined, 'Minimum GPA', job.minimumGPA.toString()),
                  _buildInfoRow(Icons.calendar_today_outlined, 'Allowed Years', job.allowedYearsOfStudy.join(', ')),
                  _buildInfoRow(Icons.workspace_premium_outlined, 'Preferred Degrees', job.preferredDegreePrograms.join(', ')),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Mandatory Skills
            if (job.mandatorySkills.isNotEmpty)
              _buildSectionCard(
                title: 'Mandatory Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.mandatorySkills.map((s) => _buildSkillChip(s, mandatory: true)).toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Nice-to-Have Skills
            if (job.niceToHaveSkills.isNotEmpty)
              _buildSectionCard(
                title: 'Nice-to-Have Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: job.niceToHaveSkills.map((s) => _buildSkillChip(s, mandatory: false)).toList(),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty || value == '0.0') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight))),
        ],
      ),
    );
  }

  Widget _buildSkillChip(String skill, {required bool mandatory}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: mandatory
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: mandatory ? AppColors.primary.withValues(alpha: 0.3) : AppColors.borderLight,
        ),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: mandatory ? AppColors.primary : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}
