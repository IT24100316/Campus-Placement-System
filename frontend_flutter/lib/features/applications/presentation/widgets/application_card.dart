import 'package:flutter/material.dart';
import '../../../../core/widgets/status_chip.dart';

class ApplicationCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final String status;
  final String appliedDate;

  const ApplicationCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.status,
    required this.appliedDate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    jobTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 6),
            Text(companyName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 10),
            Text('Applied on: $appliedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
