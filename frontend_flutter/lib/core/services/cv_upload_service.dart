import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../constants/api_endpoints.dart';

class CvUploadService {
  CvUploadService({http.Client? client, Uri? uploadEndpoint})
    : _client = client ?? http.Client(),
      _uploadEndpoint = uploadEndpoint ?? Uri.parse(ApiEndpoints.uploadCv);

  final http.Client _client;
  final Uri _uploadEndpoint;

  Future<CvUploadResult> uploadPdf({
    required Uint8List fileBytes,
    required String fileName,
    required String authToken,
  }) async {
    final token = authToken.trim();
    if (token.isEmpty) {
      throw const CvUploadException('Sign in before uploading your CV.');
    }
    if (fileBytes.isEmpty) {
      throw const CvUploadException(
        'Select a non-empty PDF CV before uploading.',
      );
    }

    if (!fileName.toLowerCase().endsWith('.pdf')) {
      throw const CvUploadException('Only PDF CV files can be uploaded.');
    }

    final request = http.MultipartRequest('POST', _uploadEndpoint)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
          contentType: MediaType('application', 'pdf'),
        ),
      );

    request.headers['Authorization'] = 'Bearer $token';

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
      final responseBody = await streamedResponse.stream.bytesToString();
      final responseData = _tryDecodeJson(responseBody);

      if (streamedResponse.statusCode >= 200 &&
          streamedResponse.statusCode < 300) {
        final storageKey = responseData?['cvStorageKey'] as String?;
        if (storageKey == null || storageKey.isEmpty) {
          throw const CvUploadException(
            'The server did not return a CV storage identifier.',
          );
        }

        return CvUploadResult(storageKey: storageKey);
      }

      throw CvUploadException(
        _messageForResponse(streamedResponse.statusCode, responseData),
        statusCode: streamedResponse.statusCode,
      );
    } on TimeoutException {
      throw const CvUploadException(
        'The upload timed out. Please check your connection and try again.',
      );
    } on http.ClientException {
      throw const CvUploadException(
        'Unable to reach the server. Please check your connection and try again.',
      );
    }
  }

  Map<String, dynamic>? _tryDecodeJson(String responseBody) {
    if (responseBody.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  String _messageForResponse(
    int statusCode,
    Map<String, dynamic>? responseData,
  ) {
    final serverMessage = responseData?['message'] as String?;
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }

    return switch (statusCode) {
      400 => 'The selected CV was rejected. Please choose a valid PDF under the size limit.',
      401 =>
        'Your session has expired. Please sign in again before uploading a CV.',
      403 => 'Your account is not allowed to upload a CV.',
      404 => 'Save your student profile before uploading a CV.',
      409 => 'Your profile changed while uploading. Please try again.',
      _ => 'The CV could not be uploaded right now. Please try again later.',
    };
  }
}

class CvUploadResult {
  const CvUploadResult({required this.storageKey});

  final String storageKey;
}

class CvUploadException implements Exception {
  const CvUploadException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
