import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:doitdo/presentation/providers/app_data_providers.dart';

class BugReportViewModel extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async => false;

  Future<void> submit({required String title, required String content}) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(bugReportRepositoryProvider).submit(
            title: title.trim(),
            content: content.trim(),
          );
      return true;
    });
  }
}

final bugReportViewModelProvider =
    AsyncNotifierProvider.autoDispose<BugReportViewModel, bool>(
  BugReportViewModel.new,
);
