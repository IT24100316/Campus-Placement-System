import 'package:flutter/material.dart';
import 'ai_match_score_badge.dart';

class JobCard extends StatelessWidget {
  final String jobTitle;
  final String companyName;
  final int matchScore;
  final String location;
  final String stipend;
  final List<String> tags;
  final String imageUrl;

  const JobCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.matchScore,
    required this.location,
    required this.stipend,
    required this.tags,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE9FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.business, color: Colors.grey);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0B1C30),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, color: Color(0xFF003594), size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'AI & Engineering',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF003594),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              AiMatchScoreBadge(score: matchScore),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            jobTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0B1C30),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Build high-throughput trajectory planners and real-time sensor fusion runtimes deployed on edge aerial hardware platforms.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF434655),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF434655),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )),
              if (matchScore > 90)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBE1FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome, size: 11, color: Color(0xFF003EA8)),
                      SizedBox(width: 2),
                      Text(
                        'Agentic AI',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF003EA8),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
