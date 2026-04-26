import 'package:doitdo/domain/entities/streak.dart';

/// `GET /api/users/me/streak` 응답(envelope 내부 `data`) 과 1:1 매핑되는 DTO.
///
/// ```json
/// {
///   "currentStreakCount": 0,
///   "currentStreakStartDate": "2026-04-26",
///   "lastActiveDate": "2026-04-26",
///   "longestStreakCount": 0,
///   "longestStreakStartDate": "2026-04-26",
///   "longestStreakEndDate": "2026-04-26"
/// }
/// ```
class StreakDto {
  const StreakDto({
    required this.currentStreakCount,
    required this.longestStreakCount,
    this.currentStreakStartDate,
    this.lastActiveDate,
    this.longestStreakStartDate,
    this.longestStreakEndDate,
  });

  final int currentStreakCount;
  final int longestStreakCount;
  final String? currentStreakStartDate;
  final String? lastActiveDate;
  final String? longestStreakStartDate;
  final String? longestStreakEndDate;

  factory StreakDto.fromJson(Map<String, dynamic> json) {
    return StreakDto(
      currentStreakCount:
          (json['currentStreakCount'] as num?)?.toInt() ?? 0,
      longestStreakCount:
          (json['longestStreakCount'] as num?)?.toInt() ?? 0,
      currentStreakStartDate: json['currentStreakStartDate'] as String?,
      lastActiveDate: json['lastActiveDate'] as String?,
      longestStreakStartDate: json['longestStreakStartDate'] as String?,
      longestStreakEndDate: json['longestStreakEndDate'] as String?,
    );
  }

  Streak toEntity() => Streak(
        currentCount: currentStreakCount,
        longestCount: longestStreakCount,
        currentStartDate: _parseDate(currentStreakStartDate),
        lastActiveDate: _parseDate(lastActiveDate),
        longestStartDate: _parseDate(longestStreakStartDate),
        longestEndDate: _parseDate(longestStreakEndDate),
      );

  /// "yyyy-MM-dd" / ISO-8601 둘 다 흡수. 파싱 실패는 null.
  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
