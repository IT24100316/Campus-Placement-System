import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_flutter/features/profile/data/student_profile_models.dart';
import 'package:frontend_flutter/features/profile/data/student_profile_service.dart';

void main() {
  final endpoint = Uri.parse('https://example.test/api/students/profile');
  final campusIdEndpoint = Uri.parse(
    'https://example.test/api/students/campus-id',
  );
  final profile = StudentProfileUpsertRequest(
    fullName: 'Alex Student',
    phone: '+94111222333',
    campusIdPhotoUrl: '',
    portfolioUrl: 'https://example.test/portfolio',
    universityName: 'Campus University',
    academicStatus: 'Full-time Student',
    degreeProgram: 'Software Engineering',
    currentYearOfStudy: 3,
    gpa: 3.5,
    expectedGraduationDate: DateTime.utc(2028, 6, 1),
    desiredJobTitle: 'Software Intern',
    primaryDomain: 'Software Engineering',
    careerObjectivesSummary: 'Build useful software.',
    skills: ['Dart'],
    toolsAndTechnologies: ['Flutter'],
    internshipType: ['Hybrid'],
    lectureScheduleType: 'Weekday',
    preferredLocations: ['Colombo'],
  );

  Map<String, dynamic> responseBody() => {
    ...profile.toJson(),
    'userId': '4cff9580-8dc7-4625-8a59-93ff7466a6df',
    'cvPdfUrl': '',
  };

  test('loads the authenticated profile with a bearer token', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, endpoint);
        expect(request.headers['Authorization'], 'Bearer verified-token');
        expect(request.body, isEmpty);
        return http.Response(jsonEncode(responseBody()), 200);
      }),
    );

    final result = await service.loadProfile(bearerToken: ' verified-token ');
    expect(result?.fullName, 'Alex Student');
    expect(result?.userId, responseBody()['userId']);
  });

  test('treats a missing profile as a new profile', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((_) async => http.Response('', 404)),
    );
    expect(await service.loadProfile(bearerToken: 'token'), isNull);
  });

  test('rejects a blank token before loading', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((_) async => fail('Request must not be sent')),
    );
    await expectLater(
      service.loadProfile(bearerToken: ' '),
      throwsA(
        isA<StudentProfileException>().having(
          (error) => error.type,
          'type',
          StudentProfileErrorType.missingToken,
        ),
      ),
    );
  });

  test('loads a registered campus ID through the authorized endpoint', () async {
    final service = StudentProfileService(
      campusIdEndpoint: campusIdEndpoint,
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url, campusIdEndpoint);
        expect(request.headers['Authorization'], 'Bearer verified-token');
        return http.Response.bytes(
          [0x89, 0x50, 0x4e, 0x47],
          200,
          headers: {'content-type': 'image/png'},
        );
      }),
    );

    final document = await service.loadCampusId(
      bearerToken: ' verified-token ',
    );

    expect(document?.bytes, [0x89, 0x50, 0x4e, 0x47]);
    expect(document?.contentType, 'image/png');
  });

  test('returns no campus ID when none is registered', () async {
    final service = StudentProfileService(
      campusIdEndpoint: campusIdEndpoint,
      client: MockClient((_) async => http.Response('', 404)),
    );

    expect(await service.loadCampusId(bearerToken: 'token'), isNull);
  });

  test('reports unauthorized loading', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((_) async => http.Response('', 401)),
    );
    await expectLater(
      service.loadProfile(bearerToken: 'token'),
      throwsA(
        isA<StudentProfileException>().having(
          (error) => error.type,
          'type',
          StudentProfileErrorType.unauthorized,
        ),
      ),
    );
  });

  test('sends the complete JSON payload without a student ID', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url, endpoint);
        expect(request.headers['Authorization'], 'Bearer verified-token');
        expect(request.headers['Content-Type'], 'application/json');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, profile.toJson());
        expect(body.containsKey('userId'), isFalse);
        expect(body.containsKey('studentId'), isFalse);
        return http.Response(jsonEncode(responseBody()), 201);
      }),
    );

    final result = await service.saveProfile(
      profile: profile,
      bearerToken: ' verified-token ',
    );
    expect(result.userId, responseBody()['userId']);
    expect(result.skills, ['Dart']);
    expect(result.gpa, 3.5);
    expect(result.expectedGraduationDate, DateTime.utc(2028, 6, 1));
  });

  test('parses an updated profile response', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient(
        (_) async => http.Response(jsonEncode(responseBody()), 200),
      ),
    );
    final result = await service.saveProfile(
      profile: profile,
      bearerToken: 'token',
    );
    expect(result.fullName, 'Alex Student');
    expect(result.toolsAndTechnologies, ['Flutter']);
    expect(result.cvPdfUrl, '');
  });

  test('rejects a blank token without sending a request', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((_) async => fail('Request must not be sent')),
    );
    await expectLater(
      service.saveProfile(profile: profile, bearerToken: '  '),
      throwsA(
        isA<StudentProfileException>().having(
          (error) => error.type,
          'type',
          StudentProfileErrorType.missingToken,
        ),
      ),
    );
  });

  for (final status in [400, 401, 403, 409, 500]) {
    test('parses the $status response as a typed error', () async {
      final service = StudentProfileService(
        profileEndpoint: endpoint,
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'message': 'Server detail'}), status),
        ),
      );
      final type = switch (status) {
        400 => StudentProfileErrorType.validation,
        401 => StudentProfileErrorType.unauthorized,
        403 => StudentProfileErrorType.forbidden,
        409 => StudentProfileErrorType.conflict,
        _ => StudentProfileErrorType.server,
      };
      await expectLater(
        service.saveProfile(profile: profile, bearerToken: 'token'),
        throwsA(
          isA<StudentProfileException>()
              .having((error) => error.type, 'type', type)
              .having((error) => error.message, 'message', 'Server detail'),
        ),
      );
    });
  }

  test('parses backend validation details', () async {
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'errors': {
              'Phone': ['Enter a valid phone number.'],
            },
          }),
          400,
        ),
      ),
    );
    await expectLater(
      service.saveProfile(profile: profile, bearerToken: 'token'),
      throwsA(
        isA<StudentProfileException>().having(
          (error) => error.message,
          'message',
          'Enter a valid phone number.',
        ),
      ),
    );
  });
}
