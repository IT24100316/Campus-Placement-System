import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:frontend_flutter/core/services/cv_upload_service.dart';

void main() {
  test('uploads a PDF multipart request and returns its storage key', () async {
    final client = _RecordingClient(
      statusCode: 200,
      responseBody: jsonEncode({'cvStorageKey': 'student/cv.pdf'}),
    );
    final service = CvUploadService(
      client: client,
      uploadEndpoint: Uri.parse('https://example.test/api/students/upload-cv'),
    );

    final result = await service.uploadPdf(
      fileName: 'resume.pdf',
      fileBytes: Uint8List.fromList('%PDF-test'.codeUnits),
      authToken: 'student-token',
    );

    expect(result.storageKey, 'student/cv.pdf');
    expect(client.authorizationHeader, 'Bearer student-token');
    expect(client.contentType, startsWith('multipart/form-data; boundary='));
  });

  test('returns a user-friendly error for an unauthorized upload', () async {
    final service = CvUploadService(
      client: _RecordingClient(statusCode: 401, responseBody: '{}'),
      uploadEndpoint: Uri.parse('https://example.test/api/students/upload-cv'),
    );

    expect(
      () => service.uploadPdf(
        fileName: 'resume.pdf',
        fileBytes: Uint8List.fromList('%PDF-test'.codeUnits),
      ),
      throwsA(
        isA<CvUploadException>().having(
          (error) => error.message,
          'message',
          'Your session has expired. Please sign in again before uploading a CV.',
        ),
      ),
    );
  });
}

class _RecordingClient extends http.BaseClient {
  _RecordingClient({required this.statusCode, required this.responseBody});

  final int statusCode;
  final String responseBody;
  String? authorizationHeader;
  String? contentType;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    authorizationHeader = request.headers['Authorization'];
    contentType = request.headers['content-type'];
    await request.finalize().drain<void>();

    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(responseBody)),
      statusCode,
      headers: const {'content-type': 'application/json'},
    );
  }
}
