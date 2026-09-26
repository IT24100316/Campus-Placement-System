class StudentProfileUpsertRequest {
  const StudentProfileUpsertRequest({
    required this.fullName,
    required this.phone,
    required this.campusIdPhotoUrl,
    this.portfolioUrl,
    required this.universityName,
    required this.academicStatus,
    required this.degreeProgram,
    required this.currentYearOfStudy,
    required this.gpa,
    required this.expectedGraduationDate,
    required this.desiredJobTitle,
    required this.primaryDomain,
    required this.careerObjectivesSummary,
    required this.skills,
    required this.toolsAndTechnologies,
    required this.internshipType,
    required this.lectureScheduleType,
    required this.preferredLocations,
  });

  final String fullName;
  final String phone;
  final String campusIdPhotoUrl;
  final String? portfolioUrl;
  final String universityName;
  final String academicStatus;
  final String degreeProgram;
  final int currentYearOfStudy;
  final double gpa;
  final DateTime expectedGraduationDate;
  final String desiredJobTitle;
  final String primaryDomain;
  final String careerObjectivesSummary;
  final List<String> skills;
  final List<String> toolsAndTechnologies;
  final List<String> internshipType;
  final String lectureScheduleType;
  final List<String> preferredLocations;

  Map<String, Object?> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'campusIdPhotoUrl': campusIdPhotoUrl,
    'portfolioUrl': portfolioUrl,
    'universityName': universityName,
    'academicStatus': academicStatus,
    'degreeProgram': degreeProgram,
    'currentYearOfStudy': currentYearOfStudy,
    'gpa': gpa,
    'expectedGraduationDate': expectedGraduationDate.toUtc().toIso8601String(),
    'desiredJobTitle': desiredJobTitle,
    'primaryDomain': primaryDomain,
    'careerObjectivesSummary': careerObjectivesSummary,
    'skills': skills,
    'toolsAndTechnologies': toolsAndTechnologies,
    'internshipType': internshipType,
    'lectureScheduleType': lectureScheduleType,
    'preferredLocations': preferredLocations,
  };
}

class StudentProfileResponse {
  const StudentProfileResponse({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.campusIdPhotoUrl,
    required this.portfolioUrl,
    required this.universityName,
    required this.academicStatus,
    required this.degreeProgram,
    required this.currentYearOfStudy,
    required this.gpa,
    required this.expectedGraduationDate,
    required this.desiredJobTitle,
    required this.primaryDomain,
    required this.careerObjectivesSummary,
    required this.skills,
    required this.toolsAndTechnologies,
    required this.internshipType,
    required this.lectureScheduleType,
    required this.preferredLocations,
    required this.cvPdfUrl,
  });

  final String userId;
  final String fullName;
  final String phone;
  final String campusIdPhotoUrl;
  final String? portfolioUrl;
  final String universityName;
  final String academicStatus;
  final String degreeProgram;
  final int currentYearOfStudy;
  final double gpa;
  final DateTime? expectedGraduationDate;
  final String desiredJobTitle;
  final String primaryDomain;
  final String careerObjectivesSummary;
  final List<String> skills;
  final List<String> toolsAndTechnologies;
  final List<String> internshipType;
  final String lectureScheduleType;
  final List<String> preferredLocations;
  final String cvPdfUrl;

  factory StudentProfileResponse.fromJson(Map<String, dynamic> json) {
    List<String> strings(String key) =>
        (json[key] as List<dynamic>).cast<String>();

    return StudentProfileResponse(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      campusIdPhotoUrl: json['campusIdPhotoUrl'] as String,
      portfolioUrl: json['portfolioUrl'] as String?,
      universityName: json['universityName'] as String,
      academicStatus: json['academicStatus'] as String,
      degreeProgram: json['degreeProgram'] as String,
      currentYearOfStudy: json['currentYearOfStudy'] as int,
      gpa: (json['gpa'] as num).toDouble(),
      expectedGraduationDate: json['expectedGraduationDate'] == null
          ? null
          : DateTime.parse(json['expectedGraduationDate'] as String),
      desiredJobTitle: json['desiredJobTitle'] as String,
      primaryDomain: json['primaryDomain'] as String,
      careerObjectivesSummary: json['careerObjectivesSummary'] as String,
      skills: strings('skills'),
      toolsAndTechnologies: strings('toolsAndTechnologies'),
      internshipType: strings('internshipType'),
      lectureScheduleType: json['lectureScheduleType'] as String,
      preferredLocations: strings('preferredLocations'),
      cvPdfUrl: json['cvPdfUrl'] as String,
    );
  }
}
