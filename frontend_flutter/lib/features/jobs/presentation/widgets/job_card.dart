import 'package:flutter/material.dart';
import 'ai_match_score_badge.dart';

class JobCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final int matchScore;
  final String location;
  final String stipend;

  const JobCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.matchScore,
    required this.location,
    required this.stipend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                AiMatchScoreBadge(score: matchScore),
              ],
            ),
            const SizedBox(height: 6),
            Text(companyName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(location, style: const TextStyle(fontSize: 13)),
                const Spacer(),
                const Icon(Icons.payments_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(stipend, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
