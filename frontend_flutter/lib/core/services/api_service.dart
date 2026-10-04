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

  Future<List<Map<String, dynamic>>> getApplications() async {
    final token = StudentSession.token;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Sign in before loading applications.');
    }
    final response = await http.get(
      Uri.parse(ApiEndpoints.myApplications),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300)
      _decode(response);
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
  }

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
