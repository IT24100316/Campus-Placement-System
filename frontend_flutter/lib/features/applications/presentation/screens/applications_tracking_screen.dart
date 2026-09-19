import 'package:flutter/material.dart';
import '../widgets/application_card.dart';

class ApplicationsTrackingScreen extends StatelessWidget {
  const ApplicationsTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ApplicationCard(
            jobTitle: 'Frontend Engineer Intern',
            companyName: 'Apex Innovations',
            status: 'Agent_Evaluated',
            appliedDate: '2026-09-15',
          ),
          ApplicationCard(
            jobTitle: 'Backend C# Developer Intern',
            companyName: 'DataPulse Corp',
            status: 'Company_Scheduled',
            appliedDate: '2026-09-12',
          ),
          ApplicationCard(
            jobTitle: 'UI/UX Designer',
            companyName: 'CreativeStudio',
            status: 'Pending',
            appliedDate: '2026-09-18',
          ),
        ],
      ),
    );
  }
}
