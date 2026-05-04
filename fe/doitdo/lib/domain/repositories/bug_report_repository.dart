abstract class BugReportRepository {
  Future<void> submit({required String title, required String content});
}
