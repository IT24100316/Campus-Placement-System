class StudentApplicationSubmissionRequest {
  const StudentApplicationSubmissionRequest({required this.jobId});

  final String jobId;

  Map<String, String> toJson() => {'jobId': jobId};
}

class StudentApplicationReceipt {
  const StudentApplicationReceipt({
    required this.appId,
    required this.jobId,
    required this.status,
  });

  final String appId;
  final String jobId;
  final String status;

  factory StudentApplicationReceipt.fromJson(Map<String, dynamic> json) {
    final appId = json['appId'];
    final jobId = json['jobId'];
    final status = json['status'];
    if (appId is! String ||
        jobId is! String ||
        status is! String ||
        appId.isEmpty ||
        jobId.isEmpty ||
        status.trim().isEmpty) {
      throw const FormatException('Invalid application receipt.');
    }
    return StudentApplicationReceipt(
      appId: appId,
      jobId: jobId,
      status: status,
    );
  }
}
