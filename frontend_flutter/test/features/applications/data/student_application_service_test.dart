import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_flutter/features/applications/data/student_application_service.dart';

void main() {
  const jobId = 'c4e5d7fe-2877-4e38-9f83-afbd42bc8541';
  const appId = 'a322e630-2c38-45f3-a2ef-d7bc7f53d190';
  final endpoint = Uri.parse('https://example.test/api/applications/apply');

  test(
    'posts only the job ID with a bearer token and parses the receipt',
    () async {
      final service = StudentApplicationService(
        applyEndpoint: endpoint,
        client: MockClient((request) async {
          expect(request.url, endpoint);
          expect(request.method, 'POST');
          expect(request.headers['Authorization'], 'Bearer verified-token');
          expect(request.headers['Content-Type'], 'application/json');
          expect(jsonDecode(request.body), {'jobId': jobId});
          return http.Response(
            jsonEncode({'appId': appId, 'jobId': jobId, 'status': 'Pending'}),
            201,
          );
        }),
      );

      final receipt = await service.apply(
        jobId: jobId,
        bearerToken: ' verified-token ',
      );

      expect(receipt.appId, appId);
      expect(receipt.jobId, jobId);
      expect(receipt.status, 'Pending');
    },
  );

  test('rejects a blank token before sending', () async {
    final service = StudentApplicationService(
      applyEndpoint: endpoint,
      client: MockClient((_) async => fail('Request must not be sent')),
    );

    await expectLater(
      service.apply(jobId: jobId, bearerToken: '  '),
      throwsA(
        isA<StudentApplicationException>().having(
          (error) => error.type,
          'type',
          StudentApplicationErrorType.missingToken,
        ),
      ),
    );
  });

  for (final invalidJobId in [
    '',
    'not-a-guid',
    '00000000-0000-0000-0000-000000000000',
  ]) {
    test('rejects invalid job ID "$invalidJobId" before sending', () async {
      final service = StudentApplicationService(
        applyEndpoint: endpoint,
        client: MockClient((_) async => fail('Request must not be sent')),
      );

      await expectLater(
        service.apply(jobId: invalidJobId, bearerToken: 'token'),
        throwsA(
          isA<StudentApplicationException>().having(
            (error) => error.type,
            'type',
            StudentApplicationErrorType.invalidJobId,
          ),
        ),
      );
    });
  }

  for (final (status, message, expectedType) in [
    (
      400,
      'Complete your student profile.',
      StudentApplicationErrorType.invalidProfile,
    ),
    (
      401,
      'An authenticated student identity is required.',
      StudentApplicationErrorType.unauthorized,
    ),
    (
      403,
      'Only student accounts can apply.',
      StudentApplicationErrorType.forbidden,
    ),
    (
      404,
      'The internship job was not found.',
      StudentApplicationErrorType.jobNotFound,
    ),
    (
      409,
      'You have already applied for this internship.',
      StudentApplicationErrorType.duplicate,
    ),
    (
      409,
      'The application deadline has passed.',
      StudentApplicationErrorType.expired,
    ),
    (500, 'Unable to save application.', StudentApplicationErrorType.server),
  ]) {
    test('maps $status response "$message" to a typed error', () async {
      final service = StudentApplicationService(
        applyEndpoint: endpoint,
        client: MockClient(
          (_) async => http.Response(jsonEncode({'message': message}), status),
        ),
      );

      await expectLater(
        service.apply(jobId: jobId, bearerToken: 'token'),
        throwsA(
          isA<StudentApplicationException>()
              .having((error) => error.type, 'type', expectedType)
              .having((error) => error.message, 'message', message),
        ),
      );
    });
  }

  test('maps a network failure to a typed error', () async {
    final service = StudentApplicationService(
      applyEndpoint: endpoint,
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      service.apply(jobId: jobId, bearerToken: 'token'),
      throwsA(
        isA<StudentApplicationException>().having(
          (error) => error.type,
          'type',
          StudentApplicationErrorType.network,
        ),
      ),
    );
  });

  test('rejects a malformed success response', () async {
    final service = StudentApplicationService(
      applyEndpoint: endpoint,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'appId': appId,
            'jobId': 'another-job',
            'status': 'Pending',
          }),
          201,
        ),
      ),
    );

    await expectLater(
      service.apply(jobId: jobId, bearerToken: 'token'),
      throwsA(
        isA<StudentApplicationException>().having(
          (error) => error.type,
          'type',
          StudentApplicationErrorType.invalidResponse,
        ),
      ),
    );
  });
}
