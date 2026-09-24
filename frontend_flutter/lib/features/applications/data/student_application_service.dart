import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import 'student_application_models.dart';

enum StudentApplicationErrorType {
  missingToken,
  invalidJobId,
  invalidProfile,
  unauthorized,
  forbidden,
  jobNotFound,
  duplicate,
  expired,
  conflict,
  network,
  invalidResponse,
  server,
}

class StudentApplicationException implements Exception {
  const StudentApplicationException(this.type, this.message);

  final StudentApplicationErrorType type;
  final String message;

  @override
  String toString() => message;
}

class StudentApplicationService {
  StudentApplicationService({http.Client? client, Uri? applyEndpoint})
    : _client = client ?? http.Client(),
      _applyEndpoint = applyEndpoint ?? Uri.parse(ApiEndpoints.applyJob);

  static final RegExp _guidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
  static const String _emptyGuid = '00000000-0000-0000-0000-000000000000';

  final http.Client _client;
  final Uri _applyEndpoint;

  Future<StudentApplicationReceipt> apply({
    required String jobId,
    required String bearerToken,
  }) async {
    final token = bearerToken.trim();
    if (token.isEmpty) {
      throw const StudentApplicationException(
        StudentApplicationErrorType.missingToken,
        'Sign in before applying for an internship.',
      );
    }

    final requestedJobId = jobId.trim();
    if (!_isValidGuid(requestedJobId)) {
      throw const StudentApplicationException(
        StudentApplicationErrorType.invalidJobId,
        'Select a valid internship job before applying.',
      );
    }

    http.Response response;
    try {
      response = await _client
          .post(
            _applyEndpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
              StudentApplicationSubmissionRequest(jobId: requestedJobId)
                  .toJson(),
            ),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const StudentApplicationException(
        StudentApplicationErrorType.network,
        'The application request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const StudentApplicationException(
        StudentApplicationErrorType.network,
        'Unable to reach the server. Check your connection and try again.',
      );
    }

    final data = _decode(response.body);
    if (response.statusCode == 201) {
      try {
        if (data == null) throw const FormatException('Missing receipt.');
        final receipt = StudentApplicationReceipt.fromJson(data);
        if (!_isValidGuid(receipt.appId) ||
            !_isValidGuid(receipt.jobId) ||
            receipt.jobId.toLowerCase() != requestedJobId.toLowerCase()) {
          throw const FormatException('Invalid receipt IDs.');
        }
        return receipt;
      } on FormatException {
        throw const StudentApplicationException(
          StudentApplicationErrorType.invalidResponse,
          'The server returned an invalid application receipt.',
        );
      }
    }

    final serverMessage = _errorMessage(data);
    final type = switch (response.statusCode) {
      400 => StudentApplicationErrorType.invalidProfile,
      401 => StudentApplicationErrorType.unauthorized,
      403 => StudentApplicationErrorType.forbidden,
      404 => StudentApplicationErrorType.jobNotFound,
      409 when serverMessage?.toLowerCase().contains('deadline') == true =>
        StudentApplicationErrorType.expired,
      409
          when serverMessage?.toLowerCase().contains('already applied') ==
              true =>
        StudentApplicationErrorType.duplicate,
      409 => StudentApplicationErrorType.conflict,
      _ => StudentApplicationErrorType.server,
    };
    final fallback = switch (type) {
      StudentApplicationErrorType.invalidProfile =>
        'Complete your student profile and upload your CV before applying.',
      StudentApplicationErrorType.unauthorized =>
        'Your session has expired. Please sign in again.',
      StudentApplicationErrorType.forbidden =>
        'Only student accounts can apply for internships.',
      StudentApplicationErrorType.jobNotFound =>
        'This internship job is no longer available.',
      StudentApplicationErrorType.duplicate =>
        'You have already applied for this internship.',
      StudentApplicationErrorType.expired =>
        'The application deadline for this internship has passed.',
      StudentApplicationErrorType.conflict => 'This application could not be accepted. Please check the job and try again.',
      _ =>
        'Unable to submit your application right now. Please try again later.',
    };
    throw StudentApplicationException(type, serverMessage ?? fallback);
  }

  bool _isValidGuid(String value) =>
      _guidPattern.hasMatch(value) && value.toLowerCase() != _emptyGuid;

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
    return message is String && message.trim().isNotEmpty ? message : null;
  }
}
