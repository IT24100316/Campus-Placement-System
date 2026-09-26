import 'package:flutter/material.dart';
import '../data/models/job_details_model.dart';
import '../data/repositories/job_repository.dart';
import '../widgets/ai_match_score_badge.dart';

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

  final Color primaryColor = const Color(0xFF003594);
  final Color onSurfaceVariant = const Color(0xFF434655);

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
        appBar: AppBar(title: const Text('Job Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorMessage != null || _jobDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(_errorMessage ?? 'Unknown error')),
      );
    }

    final job = _jobDetails!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(job.companyName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.business, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.jobTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${job.companyName} • ${job.locationCity}',
                        style: TextStyle(color: onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                AiMatchScoreBadge(score: job.matchScore),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Overview'),
            Text(job.jobDescriptionSummary),
            const SizedBox(height: 24),
            _buildSectionTitle('Requirements'),
            _buildInfoRow(Icons.school, 'Minimum GPA', job.minimumGPA.toString()),
            _buildInfoRow(Icons.date_range, 'Allowed Years', job.allowedYearsOfStudy.join(', ')),
            _buildInfoRow(Icons.workspace_premium, 'Preferred Degrees', job.preferredDegreePrograms.join(', ')),
            const SizedBox(height: 24),
            _buildSectionTitle('Mandatory Skills'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.mandatorySkills.map((s) => Chip(label: Text(s))).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Nice-to-Have Skills'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: job.niceToHaveSkills.map((s) => Chip(label: Text(s))).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // Apply Logic
            },
            child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryColor),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.w600, color: onSurfaceVariant)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
