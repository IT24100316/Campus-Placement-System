import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.jobTitle,
    required this.companyName,
    required this.locationCity,
    required this.internshipTypes,
    required this.targetDomain,
    required this.tags,
    required this.applicationDeadline,
    required this.onTap,
  });

  final String jobTitle;
  final String companyName;
  final String locationCity;
  final List<String> internshipTypes;
  final String targetDomain;
  final List<String> tags;
  final DateTime applicationDeadline;
  final VoidCallback onTap;

  String? get _workType {
    for (final type in internshipTypes) {
      final value = type.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  List<String> get _displayTags {
    final values = <String>[];
    final domain = targetDomain.trim();
    if (domain.isNotEmpty) values.add(domain);
    for (final tag in tags) {
      final value = tag.trim();
      if (value.isNotEmpty && !values.any((item) => item == value)) {
        values.add(value);
      }
    }
    return values.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final workType = _workType;
    final displayTags = _displayTags;
    final location = locationCity.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD7E2F4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06111827),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CompanyMark(companyName: companyName),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (workType != null) ...[
                    const SizedBox(width: 8),
                    _WorkTypePill(label: workType),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Text(
                jobTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimaryLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                  letterSpacing: -0.25,
                ),
              ),
              if (location.isNotEmpty || workType != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    if (location.isNotEmpty)
                      _JobMetadata(
                        icon: Icons.location_on_outlined,
                        label: location,
                      ),
                    if (workType != null)
                      _JobMetadata(
                        icon: Icons.work_outline_rounded,
                        label: workType,
                      ),
                  ],
                ),
              ],
              if (displayTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final tag in displayTags) _JobTag(label: tag)],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _DeadlineChip(deadline: applicationDeadline),
                  const Spacer(),
                  const Text(
                    'View role',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.primary,
                    size: 17,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyMark extends StatelessWidget {
  const _CompanyMark({required this.companyName});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    final trimmedName = companyName.trim();
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: trimmedName.isEmpty
          ? const Icon(
              Icons.business_center_outlined,
              color: AppColors.primary,
              size: 20,
            )
          : Text(
              trimmedName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}

class _WorkTypePill extends StatelessWidget {
  const _WorkTypePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF2458A8),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JobMetadata extends StatelessWidget {
  const _JobMetadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondaryLight),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _JobTag extends StatelessWidget {
  const _JobTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FC),
        border: Border.all(color: const Color(0xFFE2E8F4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF526178),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeadlineChip extends StatelessWidget {
  const _DeadlineChip({required this.deadline});

  final DateTime deadline;

  @override
  Widget build(BuildContext context) {
    final localDeadline = deadline.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final deadlineDay = DateUtils.dateOnly(localDeadline);
    final daysUntilClosing = deadlineDay.difference(today).inDays;
    final isUrgent = daysUntilClosing <= 0;
    final isClosingSoon = !isUrgent && daysUntilClosing <= 2;
    final backgroundColor = isUrgent
        ? const Color(0xFFFFE9E9)
        : isClosingSoon
        ? const Color(0xFFFFF4E5)
        : const Color(0xFFEAF2FF);
    final foregroundColor = isUrgent
        ? const Color(0xFFB42318)
        : isClosingSoon
        ? const Color(0xFFB45309)
        : const Color(0xFF2458A8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        _deadlineLabel(context, daysUntilClosing, localDeadline),
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _deadlineLabel(
    BuildContext context,
    int daysUntilClosing,
    DateTime localDeadline,
  ) {
    if (daysUntilClosing <= 0) return 'Closes today';
    if (daysUntilClosing == 1) return 'Closes tomorrow';
    if (daysUntilClosing <= 7) return 'Closes in $daysUntilClosing days';
    return 'Closes ${MaterialLocalizations.of(context).formatMediumDate(localDeadline)}';
  }
}
