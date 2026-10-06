import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/api_endpoints.dart';

class StudentSession {
  static String? userId;
  static String? token;
  static String? fullName;
  static String? email;
  static String? role;
  static String? accountStatus;

  static void clear() {
    userId = null;
    token = null;
    fullName = null;
    email = null;
    role = null;
    accountStatus = null;
  }
}

class ApiService {
  // Sends the student's registration details and campus ID image to the backend to create a new account.
  Future<Map<String, dynamic>> registerStudent({
    required String fullName,
    required String email,
    required String phone,
    required String universityName,
    required String password,
    required PlatformFile campusId,
  }) async {
    final extension =
        campusId.extension?.toLowerCase() ??
        campusId.name.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => MediaType('image', 'jpeg'),
      'png' => MediaType('image', 'png'),
      _ => throw Exception('Campus ID must be a JPG, JPEG, or PNG image.'),
    };
    final request =
        http.MultipartRequest('POST', Uri.parse(ApiEndpoints.registerStudent))
          ..fields.addAll({
            'fullName': fullName.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'universityName': universityName.trim(),
            'password': password,
          });
    final campusIdBytes = await campusId.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'campusIdPhoto',
        campusIdBytes,
        filename: campusId.name,
        contentType: contentType,
      ),
    );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  // Logs the user in by sending their email/password. If successful, it securely saves their JWT token in the StudentSession.
  Future<Map<String, dynamic>> login(String email, String password) async {
    StudentSession.clear();
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    final data = _decode(response);
    if (data['isPending'] == true || data['success'] != true) {
      return data;
    }

    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('The authentication server did not return a JWT.');
    }

    final meResponse = await http.get(
      Uri.parse(ApiEndpoints.currentUser),
      headers: {'Authorization': 'Bearer $token'},
    );
    final user = _decode(meResponse);
    final userId = user['id']?.toString();
    if (userId == null) {
      throw Exception('The authenticated user identity is invalid.');
    }

    StudentSession.token = token;
    StudentSession.userId = userId;
    StudentSession.fullName = user['fullName']?.toString();
    StudentSession.email = user['email']?.toString();
    StudentSession.role = user['role']?.toString();
    StudentSession.accountStatus = user['status']?.toString();

    // Keep the screen-facing shape stable while taking identity exclusively
    // from the JWT-protected /me response.
    return {
      ...data,
      'userId': userId,
      'role': user['role'],
      'email': user['email'],
      'fullName': user['fullName'],
      'status': user['status'],
      'user': user,
    };
  }

  // Fetches a list of all job applications (matches) for the currently logged-in student.
  Future<List<Map<String, dynamic>>> getApplications() async {
    final token = StudentSession.token;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sign in before loading applications.');
    }
    final response = await http.get(
      Uri.parse(ApiEndpoints.myApplications),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

  // Tells the backend that the student has clicked "Accept" on a job offer.
  Future<void> acceptOffer(String appId) async {
    final token = StudentSession.token;
    if (token == null) throw Exception('Not authenticated.');
    final response = await http.post(
      Uri.parse('${ApiEndpoints.baseUrl}/Applications/$appId/student-accept'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response); // Throws the error inside _decode
    }
  }

  // Tells the backend that the student has clicked "Decline" on a job offer.
  Future<void> declineOffer(String appId) async {
    final token = StudentSession.token;
    if (token == null) throw Exception('Not authenticated.');
    final response = await http.post(
      Uri.parse('${ApiEndpoints.baseUrl}/Applications/$appId/student-decline'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _decode(response);
    }
  }

  // Allows a logged-in user to securely change their password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = StudentSession.token?.trim();
    if (token == null || token.isEmpty) {
      throw Exception('Sign in again before changing your password.');
    }
    final response = await http.put(
      Uri.parse(ApiEndpoints.changePassword),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    _decode(response);
  }

  // Triggers an email to be sent to the user if they forgot their password.
  Future<String> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.requestPasswordReset),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );
    return _decode(response)['message']?.toString() ??
        'If this is an approved student account, a reset code has been sent.';
  }

  // Sets a brand new password for the user after they click the reset link in their email.
  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'newPassword': newPassword,
      }),
    );
    _decode(response);
  }

  // A helper function that decodes the JSON response from the server.
  // If the server returns an error (like a 400 or 500 status code), this throws an Exception automatically!
  Map<String, dynamic> _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message'] ?? 'Request failed (${response.statusCode}).',
      );
    }
    return data;
  }
}
