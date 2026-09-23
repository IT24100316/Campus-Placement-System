import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/api_service.dart';
import '../widgets/application_card.dart';

class ApplicationsTrackingScreen extends StatefulWidget {
  const ApplicationsTrackingScreen({super.key});

  @override
  State<ApplicationsTrackingScreen> createState() => _ApplicationsTrackingScreenState();
}

class _ApplicationsTrackingScreenState extends State<ApplicationsTrackingScreen> {
  late Future<List<Map<String, dynamic>>> _applications;

  @override
  void initState() {
    super.initState();
    _applications = ApiService().getApplications();
  }

  Future<void> _refresh() async {
    final request = ApiService().getApplications();
    setState(() => _applications = request);
    await request;
  }

  String _friendlyStatus(String status) => switch (status) {
    'Agent_Evaluated' => 'Waiting for Admin Approval',
    'Admin_Approved' => 'Admin Approved',
    'Company_Scheduled' => 'Interview Scheduled',
    'Student_Accepted' => 'Interview Accepted',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Applications'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh))],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _applications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load applications.\n${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final applications = snapshot.data ?? [];
          final scheduled = applications.where((item) => item['status'] == 'Company_Scheduled').toList();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (scheduled.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.event_available, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${scheduled.length} interview${scheduled.length == 1 ? '' : 's'} scheduled. The latest date appears on the application card.',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 96),
                    child: Center(child: Text('No applications yet. Pull down to refresh.')),
                  ),
                for (final item in applications)
                  ApplicationCard(
                    jobTitle: item['jobTitle']?.toString() ?? 'Role',
                    companyName: item['companyName']?.toString() ?? 'Company',
                    status: _friendlyStatus(item['status']?.toString() ?? 'Pending'),
                    appliedDate: item['interviewDate'] == null
                        ? 'Awaiting next update'
                        : 'Interview: ${item['interviewDate']} ${item['interviewTime'] ?? ''}',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
