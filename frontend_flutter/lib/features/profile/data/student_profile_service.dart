import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import 'student_profile_models.dart';

enum StudentProfileErrorType {
  missingToken,
  validation,
  unauthorized,
  forbidden,
  conflict,
  server,
  network,
  invalidResponse,
}

class StudentProfileException implements Exception {
  const StudentProfileException(this.type, this.message);

  final StudentProfileErrorType type;
  final String message;

  @override
  String toString() => message;
}

class StudentProfileService {
  StudentProfileService({http.Client? client, Uri? profileEndpoint})
    : _client = client ?? http.Client(),
      _profileEndpoint =
          profileEndpoint ?? Uri.parse(ApiEndpoints.studentProfile);

  final http.Client _client;
  final Uri _profileEndpoint;

  Future<StudentProfileResponse> saveProfile({
    required StudentProfileUpsertRequest profile,
    required String bearerToken,
  }) async {
    final token = bearerToken.trim();
    if (token.isEmpty) {
      throw const StudentProfileException(
        StudentProfileErrorType.missingToken,
        'Sign in before saving your student profile.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .put(
            _profileEndpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(profile.toJson()),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const StudentProfileException(
        StudentProfileErrorType.network,
        'The profile save timed out. Please try again.',
      );
    } on http.ClientException {
      throw const StudentProfileException(
        StudentProfileErrorType.network,
        'Unable to reach the server. Check your connection and try again.',
      );
    }

    final data = _decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data == null) {
        throw const StudentProfileException(
          StudentProfileErrorType.invalidResponse,
          'The server returned an invalid student profile.',
        );
      }
      try {
        return StudentProfileResponse.fromJson(data);
      } on Object {
        throw const StudentProfileException(
          StudentProfileErrorType.invalidResponse,
          'The server returned an invalid student profile.',
        );
      }
    }

    final serverMessage = _errorMessage(data);
    final type = switch (response.statusCode) {
      400 => StudentProfileErrorType.validation,
      401 => StudentProfileErrorType.unauthorized,
      403 => StudentProfileErrorType.forbidden,
      409 => StudentProfileErrorType.conflict,
      _ => StudentProfileErrorType.server,
    };
    final fallback = switch (type) {
      StudentProfileErrorType.validation =>
        'Check your profile details and try again.',
      StudentProfileErrorType.unauthorized =>
        'Your session has expired. Please sign in again.',
      StudentProfileErrorType.forbidden =>
        'Your account cannot save a student profile.',
      StudentProfileErrorType.conflict =>
        'Your profile changed while saving. Please try again.',
      _ => 'Unable to save your student profile right now. Please try again later.',
    };
    throw StudentProfileException(type, serverMessage ?? fallback);
  }

  Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  String? _errorMessage(Map<String, dynamic>? data) {
    final message = data?['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    final errors = data?['errors'];
    if (errors is Map) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty && value.first is String) {
          return value.first as String;
        }
      }
    }
    return null;
  }
}
