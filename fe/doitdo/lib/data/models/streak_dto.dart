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
///   "longestStreakEndDate": "2026-04-26",
///   "canClaim": false
/// }
/// ```
class StreakDto {
  const StreakDto({
    required this.currentStreakCount,
    required this.longestStreakCount,
    required this.canClaim,
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

  /// BE 가 판정한 "지금 보상 수령 가능 여부".
  /// 필드 누락 케이스(구버전 BE) 는 false 로 간주 — 받지 못 하는 게 잘못 받는 것보다 안전.
  final bool canClaim;

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
      canClaim: (json['canClaim'] as bool?) ?? false,
    );
  }

  Streak toEntity() => Streak(
        currentCount: currentStreakCount,
        longestCount: longestStreakCount,
        canClaim: canClaim,
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
