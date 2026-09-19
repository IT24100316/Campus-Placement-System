class ApiEndpoints {
  static const String baseUrl = 'http://localhost:5168/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String registerStudent = '$baseUrl/auth/register-student';

  // Profile
  static const String studentProfile = '$baseUrl/students/profile';
  static const String uploadCv = '$baseUrl/students/upload-cv';

  // Jobs
  static const String jobsFeed = '$baseUrl/jobs';
  static String jobDetails(String id) => '$baseUrl/jobs/$id';

  // Applications
  static const String myApplications = '$baseUrl/applications/my-applications';
  static const String applyJob = '$baseUrl/applications/apply';
}
