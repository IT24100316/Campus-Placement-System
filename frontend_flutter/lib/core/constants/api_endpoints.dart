import '../config/api_config.dart';

class ApiEndpoints {
  static String get baseUrl => ApiConfig.baseUrl;

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get registerStudent => '$baseUrl/auth/register-student';

  // Profile
  static String get studentProfile => '$baseUrl/students/profile';
  static String get uploadCv => '$baseUrl/students/upload-cv';

  // Jobs
  static String get jobsFeed => '$baseUrl/jobs';
  static String jobDetails(String id) => '$baseUrl/jobs/$id';

  // Applications
  static String myApplications(String studentId) => '$baseUrl/applications/student/$studentId';
  static const String applyJob = '$baseUrl/applications/apply';
}
