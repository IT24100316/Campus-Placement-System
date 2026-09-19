import 'package:flutter/material.dart';
import '../widgets/job_card.dart';

class JobFeedScreen extends StatelessWidget {
  const JobFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Placement Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return JobCard(
            jobTitle: 'Software Engineering Intern #${index + 1}',
            companyName: 'TechCorp Solutions',
            matchScore: 92 - (index * 5),
            location: 'Colombo / Remote',
            stipend: 'LKR 50,000/mo',
          );
        },
      ),
    );
  }
}
