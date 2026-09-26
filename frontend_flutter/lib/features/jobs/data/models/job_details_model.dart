import 'job_feed_model.dart';

class JobDetailsModel extends JobFeedModel {
  final String jobDescriptionSummary;
  final double minimumGPA;
  final List<int> allowedYearsOfStudy;
  final List<String> mandatorySkills;
  final List<String> niceToHaveSkills;
  final List<String> preferredDegreePrograms;

  JobDetailsModel({
    required super.jobId,
    required super.jobTitle,
    required super.companyName,
    required super.targetDomain,
    required super.locationCity,
    required super.internshipType,
    required super.stipendOffered,
    super.stipendAmountOrDetails,
    required super.durationMonths,
    required super.applicationDeadline,
    required super.tags,
    required super.createdAt,
    required super.matchScore,
    required this.jobDescriptionSummary,
    required this.minimumGPA,
    required this.allowedYearsOfStudy,
    required this.mandatorySkills,
    required this.niceToHaveSkills,
    required this.preferredDegreePrograms,
  });

  factory JobDetailsModel.fromJson(Map<String, dynamic> json) {
    return JobDetailsModel(
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      targetDomain: json['targetDomain'] ?? '',
      locationCity: json['locationCity'] ?? '',
      internshipType: (json['internshipType'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stipendOffered: json['stipendOffered'] ?? false,
      stipendAmountOrDetails: json['stipendAmountOrDetails'],
      durationMonths: json['durationMonths'] ?? 0,
      applicationDeadline: DateTime.tryParse(json['applicationDeadline'] ?? '') ?? DateTime.now(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      matchScore: json['matchScore'] ?? 0,
      jobDescriptionSummary: json['jobDescriptionSummary'] ?? '',
      minimumGPA: (json['minimumGPA'] as num?)?.toDouble() ?? 0.0,
      allowedYearsOfStudy: (json['allowedYearsOfStudy'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      mandatorySkills: (json['mandatorySkills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      niceToHaveSkills: (json['niceToHaveSkills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      preferredDegreePrograms: (json['preferredDegreePrograms'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
