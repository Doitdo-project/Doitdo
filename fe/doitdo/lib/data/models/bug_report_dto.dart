class BugReportResp {
  const BugReportResp({required this.bugReportId, required this.createdAt});

  final int bugReportId;
  final DateTime createdAt;

  factory BugReportResp.fromJson(Map<String, dynamic> json) => BugReportResp(
        bugReportId: json['bugReportId'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
