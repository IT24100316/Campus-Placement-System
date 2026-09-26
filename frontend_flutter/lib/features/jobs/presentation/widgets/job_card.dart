import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

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
    final bool isPaid = stipend != 'Unpaid';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Company logo + name + location
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  'https://ui-avatars.com/api/?name=${Uri.encodeComponent(companyName)}&background=EEF2FF&color=4F46E5&size=80&bold=true&font-size=0.4',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.business_outlined, color: AppColors.primary, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 2: Job title (main focus)
          Text(
            jobTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryLight,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 14),

          // Row 3: Tags + stipend badge at end
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(width: 8),
              // Stipend badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPaid
                        ? AppColors.accent.withValues(alpha: 0.3)
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPaid ? Icons.attach_money : Icons.money_off_csred_outlined,
                      size: 12,
                      color: isPaid ? AppColors.accent : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      isPaid ? stipend : 'Unpaid',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPaid ? AppColors.accent : AppColors.textSecondaryLight,
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
