class AppConstants {
  AppConstants._();

  static const Duration apiTimeout = Duration(seconds: 10);

  // 다마고치 경험치 (TODO 하나당 4~7%)
  static const int expPerTodoMin = 4;
  static const int expPerTodoMax = 7;
}
