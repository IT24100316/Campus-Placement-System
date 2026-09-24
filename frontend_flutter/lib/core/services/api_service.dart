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

  static void clear() {
    userId = null;
    token = null;
    fullName = null;
    email = null;
    role = null;
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
    if (campusId.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'campusIdPhoto',
          campusId.bytes!,
          filename: campusId.name,
          contentType: contentType,
        ),
      );
    } else if (campusId.path != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'campusIdPhoto',
          campusId.path!,
          filename: campusId.name,
          contentType: contentType,
        ),
      );
    } else {
      throw Exception('The selected campus ID could not be read.');
    }
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

    // Keep the screen-facing shape stable while taking identity exclusively
    // from the JWT-protected /me response.
    return {
      ...data,
      'userId': userId,
      'role': user['role'],
      'email': user['email'],
      'fullName': user['fullName'],
      'user': user,
    };
  }

  Future<List<Map<String, dynamic>>> getApplications() async {
    final studentId = StudentSession.userId;
    if (studentId == null) return [];
    final response = await http.get(
      Uri.parse(ApiEndpoints.myApplications(studentId)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300)
      _decode(response);
    return (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
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
