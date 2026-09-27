class JobFeedModel {
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String targetDomain;
  final String locationCity;
  final List<String> internshipType;
  final bool stipendOffered;
  final String? stipendAmountOrDetails;
  final int durationMonths;
  final DateTime applicationDeadline;
  final List<String> tags;
  final DateTime createdAt;
  final int matchScore;

  JobFeedModel({
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.targetDomain,
    required this.locationCity,
    required this.internshipType,
    required this.stipendOffered,
    this.stipendAmountOrDetails,
    required this.durationMonths,
    required this.applicationDeadline,
    required this.tags,
    required this.createdAt,
    required this.matchScore,
  });

  factory JobFeedModel.fromJson(Map<String, dynamic> json) {
    return JobFeedModel(
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
    );
  }
}

class PaginatedJobFeed {
  final List<JobFeedModel> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PaginatedJobFeed({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory PaginatedJobFeed.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List<dynamic>? ?? [];
    return PaginatedJobFeed(
      items: itemsList.map((j) => JobFeedModel.fromJson(j)).toList(),
      totalCount: json['totalCount'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
    );
  }
}
