import '../config/api_config.dart';

class ApiEndpoints {
  static String get baseUrl => ApiConfig.baseUrl;

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get currentUser => '$baseUrl/auth/me';
  static String get registerStudent => '$baseUrl/Auth/register-student';

  // Profile
  static String get studentProfile => '$baseUrl/students/profile';
  static String get studentCampusId => '$baseUrl/students/campus-id';
  static String get uploadCv => '$baseUrl/students/upload-cv';

  // Jobs
  static String get jobsFeed => '$baseUrl/jobs/feed';
  static String jobDetails(String id) => '$baseUrl/jobs/$id';

  // Applications
  static String get myApplications => '$baseUrl/applications/me';
}
