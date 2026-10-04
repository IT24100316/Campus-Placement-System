import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/api_service.dart';

class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.destination,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String destination;
  final bool isRead;
  final DateTime createdAt;

  factory StudentNotification.fromJson(Map<String, dynamic> json) =>
      StudentNotification(
        id: json['id'].toString(),
        type: json['type'] as String? ?? 'general',
        title: json['title'] as String? ?? 'Update',
        message: json['message'] as String? ?? '',
        destination: json['destination'] as String? ?? 'applications',
        isRead: json['isRead'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class StudentNotificationService {
  StudentNotificationService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> get _headers {
    final token = StudentSession.token?.trim() ?? '';
    if (token.isEmpty) throw StateError('Sign in to view notifications.');
    return {'Authorization': 'Bearer $token'};
  }

  Future<int> unreadCount() async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.notificationsUnreadCount),
      headers: _headers,
    );
    if (response.statusCode != 200) return 0;
    return (jsonDecode(response.body) as Map<String, dynamic>)['unreadCount'] as int? ?? 0;
  }

  Future<List<StudentNotification>> load() async {
    final response = await _client.get(
      Uri.parse(ApiEndpoints.notifications),
      headers: _headers,
    );
    if (response.statusCode != 200) throw StateError('Unable to load notifications.');
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => StudentNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> markRead(String id) => _post('${ApiEndpoints.notifications}/$id/read');
  Future<void> markAllRead() => _post('${ApiEndpoints.notifications}/mark-all-read');

  Future<void> _post(String endpoint) async {
    final response = await _client.post(Uri.parse(endpoint), headers: _headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Unable to update notifications.');
    }
  }
}
