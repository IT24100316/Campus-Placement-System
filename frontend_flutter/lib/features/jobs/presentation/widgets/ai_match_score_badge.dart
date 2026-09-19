import 'package:flutter/material.dart';

class AiMatchScoreBadge extends StatelessWidget {
  final int score;

  const AiMatchScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80 ? Colors.green : (score >= 60 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '$score% Match',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
