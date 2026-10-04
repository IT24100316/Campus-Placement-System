import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_flutter/core/services/api_service.dart';
import 'package:frontend_flutter/features/profile/data/student_profile_service.dart';
import 'package:frontend_flutter/features/profile/presentation/screens/resume_hub_screen.dart';

void main() {
  const token = 'resume-test-token';
  final profileEndpoint = Uri.parse(
    'https://example.test/api/students/profile',
  );

  setUp(() => StudentSession.token = token);
  tearDown(StudentSession.clear);

  testWidgets('shows the create-resume state when no profile exists', (
    tester,
  ) async {
    await _pumpHub(
      tester,
      StudentProfileService(
        profileEndpoint: profileEndpoint,
        client: MockClient((_) async => http.Response('', 404)),
      ),
    );

    expect(find.text('Create your resume'), findsOneWidget);
    expect(find.text('Create resume'), findsOneWidget);
  });

  testWidgets('shows progress for a saved incomplete resume draft', (
    tester,
  ) async {
    await _pumpHub(tester, _serviceFor(_profileJson(desiredJobTitle: 'Intern')));

    expect(find.text('Complete your resume'), findsOneWidget);
    expect(find.textContaining('of 16 required details completed'), findsOneWidget);
    expect(find.text('Continue editing'), findsOneWidget);
  });

  testWidgets('requires a CV only after all resume details are complete', (
    tester,
  ) async {
    await _pumpHub(tester, _serviceFor(_profileJson(complete: true)));

    expect(find.text('Your resume is ready'), findsOneWidget);
    expect(find.text('Upload CV'), findsOneWidget);
  });

  testWidgets('marks the resume complete only with a stored CV', (
    tester,
  ) async {
    await _pumpHub(
      tester,
      _serviceFor(_profileJson(complete: true, cvPdfUrl: 'stored-cv-key')),
    );

    expect(find.text('Your resume is complete'), findsOneWidget);
    expect(find.text('Edit resume'), findsOneWidget);
  });

  Future<void> _pumpHub(
    WidgetTester tester,
    StudentProfileService service,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: ResumeHubScreen(profileService: service)),
    );
    await tester.pumpAndSettle();
  }

  StudentProfileService _serviceFor(Map<String, Object?> response) {
    return StudentProfileService(
      profileEndpoint: profileEndpoint,
      client: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer $token');
        return http.Response(jsonEncode(response), 200);
      }),
    );
  }

  Map<String, Object?> _profileJson({
    bool complete = false,
    String desiredJobTitle = '',
    String cvPdfUrl = '',
  }) {
    return {
      'userId': '4cff9580-8dc7-4625-8a59-93ff7466a6df',
      'fullName': 'Alex Student',
      'phone': '+94111222333',
      'campusIdPhotoUrl': 'registered-campus-id',
      'portfolioUrl': null,
      'universityName': 'Campus University',
      'academicStatus': complete ? 'Full-time Student' : 'Pending verification',
      'degreeProgram': complete ? 'Software Engineering' : '',
      'currentYearOfStudy': complete ? 3 : 0,
      'gpa': complete ? 3.5 : 0,
      'expectedGraduationDate': complete ? '2028-06-01T00:00:00Z' : null,
      'desiredJobTitle': complete ? 'Software Intern' : desiredJobTitle,
      'primaryDomain': complete ? 'Software Engineering' : '',
      'careerObjectivesSummary': complete ? 'Build useful software.' : '',
      'skills': complete ? ['Dart'] : <String>[],
      'toolsAndTechnologies': complete ? ['Flutter'] : <String>[],
      'internshipType': complete ? ['Hybrid'] : <String>[],
      'lectureScheduleType': complete ? 'Weekday' : '',
      'preferredLocations': complete ? ['Colombo'] : <String>[],
      'cvPdfUrl': cvPdfUrl,
    };
  }
}
