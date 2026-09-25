import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter/core/services/api_service.dart';
import 'package:frontend_flutter/core/services/cv_upload_service.dart';
import 'package:frontend_flutter/features/profile/data/student_profile_service.dart';
import 'package:frontend_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const token = 'student-token';
  final endpoint = Uri.parse('https://example.test/api/students/profile');

  setUp(() {
    StudentSession.token = token;
    StudentSession.fullName = 'Session Student';
  });
  tearDown(() {
    StudentSession.token = null;
    StudentSession.fullName = null;
  });

  final profile = <String, dynamic>{
    'userId': 'server-student-id',
    'fullName': 'Alex Student',
    'phone': '+94111222333',
    'campusIdPhotoUrl': 'campus-key',
    'portfolioUrl': 'https://example.test/portfolio',
    'universityName': 'Campus University',
    'academicStatus': 'Full-time Student',
    'degreeProgram': 'BSc (Hons) Software Engineering',
    'currentYearOfStudy': 3,
    'gpa': 3.5,
    'expectedGraduationDate': '2028-06-01T00:00:00Z',
    'desiredJobTitle': 'Software Intern',
    'primaryDomain': 'Software Engineering',
    'careerObjectivesSummary': 'Build useful software for students.',
    'skills': ['Dart'],
    'toolsAndTechnologies': ['Flutter'],
    'internshipType': ['Hybrid'],
    'lectureScheduleType': 'Weekday',
    'preferredLocations': ['Colombo'],
    'cvPdfUrl': 'existing-cv-key',
  };

  testWidgets('loads and saves the current student without uploading a CV', (
    tester,
  ) async {
    var saves = 0;
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((request) async {
        expect(request.url, endpoint);
        expect(request.headers['Authorization'], 'Bearer $token');
        if (request.method == 'GET') {
          return http.Response(jsonEncode(profile), 200);
        }
        expect(request.method, 'PUT');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fullName'], 'Alex Student');
        expect(body['phone'], '+94111222333');
        expect(body['campusIdPhotoUrl'], 'campus-key');
        expect(body.containsKey('studentId'), isFalse);
        expect(body.containsKey('userId'), isFalse);
        saves++;
        return http.Response(jsonEncode(profile), 200);
      }),
    );
    final referenceClient = MockClient((request) async {
      if (request.url.path.endsWith('/domains')) {
        return http.Response(
          jsonEncode([
            {'id': 1, 'name': 'Software Engineering'},
          ]),
          200,
        );
      }
      if (request.url.path.endsWith('/titles')) {
        return http.Response(
          jsonEncode([
            {'id': 2, 'title': 'Software Intern'},
          ]),
          200,
        );
      }
      fail('Unexpected reference request: ${request.url}');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          profileService: service,
          referenceClient: referenceClient,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your saved profile is ready to edit.'), findsOneWidget);
    expect(find.text('Alex Student'), findsOneWidget);
    expect(find.text('Campus University'), findsOneWidget);
    await tester.tap(find.text('Save Profile'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(find.text('Student profile saved successfully.'), findsOneWidget);
  });

  for (final uploadStatus in [200, 500, 401]) {
    testWidgets('saves profile before CV upload and handles $uploadStatus', (
      tester,
    ) async {
      final events = <String>[];
      final profileService = StudentProfileService(
        profileEndpoint: endpoint,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer $token');
          if (request.method == 'GET') {
            return http.Response(jsonEncode(profile), 200);
          }
          events.add('profile');
          return http.Response(jsonEncode(profile), 200);
        }),
      );
      final cvService = CvUploadService(
        uploadEndpoint: Uri.parse(
          'https://example.test/api/students/upload-cv',
        ),
        client: MockClient((request) async {
          events.add('cv');
          expect(events, ['profile', 'cv']);
          expect(request.headers['Authorization'], 'Bearer $token');
          return http.Response(
            uploadStatus == 200
                ? jsonEncode({'cvStorageKey': 'new-cv-key'})
                : '{}',
            uploadStatus,
          );
        }),
      );
      final references = MockClient((request) async {
        if (request.url.path.endsWith('/domains')) {
          return http.Response(
            jsonEncode([
              {'id': 1, 'name': 'Software Engineering'},
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {'id': 2, 'title': 'Software Intern'},
          ]),
          200,
        );
      });
      final pdf = Uint8List.fromList('%PDF-test'.codeUnits);
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profileService: profileService,
            cvUploadService: cvService,
            referenceClient: references,
            pickCvFile: () async => _TestPdfFile(pdf),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select PDF'));
      await tester.tap(find.text('Select PDF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Profile'));
      await tester.pumpAndSettle();
      expect(events, ['profile', 'cv']);
      if (uploadStatus == 200) {
        expect(
          find.text('Student profile saved successfully.'),
          findsOneWidget,
        );
        expect(StudentSession.token, token);
      } else {
        expect(
          find.textContaining(
            'Profile saved, but the CV still needs to be uploaded.',
          ),
          findsOneWidget,
        );
        if (uploadStatus == 401) {
          expect(StudentSession.token, isNull);
          expect(find.text('Sign in again'), findsOneWidget);
        }
      }
    });
  }
}

final class _TestPdfFile extends PlatformFile {
  _TestPdfFile(this.data);

  final Uint8List data;

  @override
  String get name => 'resume.pdf';

  @override
  Uri get uri => Uri.dataFromBytes(data);

  @override
  int? lengthSync() => data.length;

  @override
  Future<int?> length() async => data.length;

  @override
  Future<Uint8List> readAsBytes() async => data;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(data);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
