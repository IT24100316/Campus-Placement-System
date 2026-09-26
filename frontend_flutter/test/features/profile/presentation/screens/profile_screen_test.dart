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

  http.Client references() => MockClient((request) async {
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
        expect(body.containsKey('jobId'), isFalse);
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

    expect(
      find.text('Internship registration completed successfully'),
      findsOneWidget,
    );
    expect(find.text('Alex Student'), findsOneWidget);
    expect(find.text('Campus University'), findsOneWidget);
    expect(find.text('CV uploaded'), findsOneWidget);
    await tester.tap(find.text('Complete Internship Registration'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(
      find.text('Internship registration completed successfully'),
      findsOneWidget,
    );
  });

  testWidgets(
    'Document Upload follows all profile sections and stays scrollable',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final service = StudentProfileService(
        profileEndpoint: endpoint,
        client: MockClient(
          (request) async => http.Response(jsonEncode(profile), 200),
        ),
      );

      for (final size in [const Size(390, 844), const Size(1200, 900)]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MaterialApp(
            home: ProfileScreen(
              profileService: service,
              referenceClient: references(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final titles = [
          'Personal Information',
          'Academic Information',
          'Career Goals & Preferences',
          'Technical Profile',
          'Document Upload',
        ];
        final positions = titles.map((title) {
          final section = find.text(title);
          expect(section, findsOneWidget);
          return tester.getTopLeft(section).dy;
        }).toList();
        expect(positions, orderedEquals([...positions]..sort()));
        expect(
          find.ancestor(
            of: find.text('Document Upload'),
            matching: find.byType(SingleChildScrollView),
          ),
          findsOneWidget,
        );

        await tester.ensureVisible(find.text('Select PDF'));
        await tester.pumpAndSettle();
        expect(find.text('Select PDF'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );

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
      await tester.tap(find.text('Complete Internship Registration'));
      await tester.pumpAndSettle();
      expect(events, ['profile', 'cv']);
      if (uploadStatus == 200) {
        expect(
          find.text('Internship registration completed successfully'),
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

  testWidgets('missing token prevents registration submission', (tester) async {
    var saves = 0;
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode(profile), 200);
        }
        saves++;
        return http.Response(jsonEncode(profile), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          profileService: service,
          referenceClient: references(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    StudentSession.token = null;
    await tester.tap(find.text('Complete Internship Registration'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('Sign in again'), findsOneWidget);
  });

  testWidgets('a missing CV cannot complete registration', (tester) async {
    var saves = 0;
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({...profile, 'cvPdfUrl': ''}), 200);
        }
        saves++;
        return http.Response(jsonEncode(profile), 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          profileService: service,
          referenceClient: references(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Internship Registration'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(
      find.text('A PDF CV is required to complete internship registration.'),
      findsOneWidget,
    );
  });

  testWidgets('invalid profile response prevents CV upload', (tester) async {
    var uploads = 0;
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient(
        (request) async => request.method == 'GET'
            ? http.Response(jsonEncode({...profile, 'cvPdfUrl': ''}), 200)
            : http.Response(
                jsonEncode({'message': 'Profile validation failed.'}),
                400,
              ),
      ),
    );
    final cvService = CvUploadService(
      client: MockClient((_) async {
        uploads++;
        return http.Response('{}', 200);
      }),
    );
    final pdf = Uint8List.fromList('%PDF-test'.codeUnits);
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          profileService: service,
          cvUploadService: cvService,
          referenceClient: references(),
          pickCvFile: () async => _TestPdfFile(pdf),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select PDF'));
    await tester.tap(find.text('Select PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Internship Registration'));
    await tester.pumpAndSettle();
    expect(uploads, 0);
    expect(find.text('Profile validation failed.'), findsOneWidget);
  });

  testWidgets('invalid PDF cannot be uploaded or complete registration', (
    tester,
  ) async {
    var saves = 0;
    var uploads = 0;
    final service = StudentProfileService(
      profileEndpoint: endpoint,
      client: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(jsonEncode({...profile, 'cvPdfUrl': ''}), 200);
        }
        saves++;
        return http.Response(jsonEncode(profile), 200);
      }),
    );
    final cvService = CvUploadService(
      client: MockClient((_) async {
        uploads++;
        return http.Response('{}', 200);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          profileService: service,
          cvUploadService: cvService,
          referenceClient: references(),
          pickCvFile: () async =>
              _TestPdfFile(Uint8List.fromList('not-a-pdf'.codeUnits)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select PDF'));
    await tester.tap(find.text('Select PDF'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('does not contain valid PDF content'),
      findsOneWidget,
    );
    await tester.tap(find.text('Complete Internship Registration'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(uploads, 0);
  });

  testWidgets(
    'partial success retries the selected CV without losing profile data',
    (tester) async {
      final events = <String>[];
      var uploads = 0;
      final savedProfile = {...profile, 'cvPdfUrl': ''};
      final service = StudentProfileService(
        profileEndpoint: endpoint,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer $token');
          if (request.method == 'GET') {
            return http.Response(jsonEncode(savedProfile), 200);
          }
          events.add('profile');
          expect(jsonDecode(request.body)['jobId'], isNull);
          return http.Response(jsonEncode(savedProfile), 200);
        }),
      );
      final cvService = CvUploadService(
        client: MockClient((request) async {
          events.add('cv');
          expect(request.headers['Authorization'], 'Bearer $token');
          uploads++;
          return uploads == 1
              ? http.Response('{}', 500)
              : http.Response(
                  jsonEncode({'cvStorageKey': 'student/new-cv.pdf'}),
                  200,
                );
        }),
      );
      final pdf = Uint8List.fromList('%PDF-test'.codeUnits);
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(
            profileService: service,
            cvUploadService: cvService,
            referenceClient: references(),
            pickCvFile: () async => _TestPdfFile(pdf),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select PDF'));
      await tester.tap(find.text('Select PDF'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete Internship Registration'));
      await tester.pumpAndSettle();
      expect(events, ['profile', 'cv']);
      expect(
        find.textContaining(
          'Profile saved, but the CV still needs to be uploaded.',
        ),
        findsOneWidget,
      );
      expect(find.text('resume.pdf'), findsOneWidget);
      await tester.tap(find.text('Complete Internship Registration'));
      await tester.pumpAndSettle();
      expect(events, ['profile', 'cv', 'profile', 'cv']);
      expect(
        find.text('Internship registration completed successfully'),
        findsOneWidget,
      );
      expect(find.text('CV uploaded'), findsOneWidget);
    },
  );
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
