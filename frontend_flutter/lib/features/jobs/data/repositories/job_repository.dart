import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_feed_model.dart';
import '../models/job_details_model.dart';
import '../../../../core/constants/api_endpoints.dart';

class JobRepository {
  static String get baseUrl => ApiEndpoints.jobsFeed;

  Future<PaginatedJobFeed> fetchJobFeed({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? domain,
    String? skills,
    List<String>? workArrangements,
    bool? isPaidOnly,
    bool? isEligible,
    double? minGpa,
    double? maxGpa,
    List<int>? allowedYears,
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
    if (minGpa != null) queryParams['minGpa'] = minGpa.toStringAsFixed(1);
    if (maxGpa != null) queryParams['maxGpa'] = maxGpa.toStringAsFixed(1);
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;

    var uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    
    // Manually append array parameters for .NET binding
    String arrParams = '';
    if (workArrangements != null && workArrangements.isNotEmpty) {
       arrParams += workArrangements.map((w) => 'workArrangements=$w').join('&');
    }
    if (allowedYears != null && allowedYears.isNotEmpty) {
       if (arrParams.isNotEmpty) arrParams += '&';
       arrParams += allowedYears.map((y) => 'allowedYears=$y').join('&');
    }
    if (arrParams.isNotEmpty) {
       final queryString = uri.query;
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
    final uri = Uri.parse(ApiEndpoints.jobDetails(jobId));
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
