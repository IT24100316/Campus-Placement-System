import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_feed_model.dart';
import '../models/job_details_model.dart';

class JobRepository {
  // Using 10.0.2.2 for Android Emulator. Change to localhost or real IP for other platforms.
  static const String baseUrl = 'http://10.0.2.2:5000/api/jobs';

  Future<PaginatedJobFeed> fetchJobFeed({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? domain,
    String? skills,
    List<String>? workArrangements,
    bool? isPaidOnly,
    bool? isEligible,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (domain != null && domain != 'All Roles') queryParams['domain'] = domain;
    if (skills != null && skills.isNotEmpty) queryParams['skills'] = skills;
    if (isPaidOnly == true) queryParams['isPaidOnly'] = 'true';
    if (isEligible == true) queryParams['isEligible'] = 'true';
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;

    var uri = Uri.parse('$baseUrl/feed').replace(queryParameters: queryParams);
    
    // Manually append array parameters for .NET binding
    if (workArrangements != null && workArrangements.isNotEmpty) {
       final queryString = uri.query;
       final arrParams = workArrangements.map((w) => 'workArrangements=$w').join('&');
       uri = Uri.parse('${uri.origin}${uri.path}?$queryString&$arrParams');
    }

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return PaginatedJobFeed.fromJson(decoded);
      } else {
        throw Exception('Failed to load jobs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching jobs: $e');
    }
  }

  Future<JobDetailsModel> fetchJobDetails(String jobId) async {
    final uri = Uri.parse('$baseUrl/$jobId');
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return JobDetailsModel.fromJson(decoded);
      } else {
        throw Exception('Failed to load job details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching job details: $e');
    }
  }
}
