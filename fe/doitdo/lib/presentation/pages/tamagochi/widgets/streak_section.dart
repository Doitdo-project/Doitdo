import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_colors.dart';
import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 스트릭 시작일(slot[0])부터 7일 단위 블록으로 진행 상황을 표시한다.
/// 스트릭이 7일을 넘기면 다음 7일 블록으로 통째로 이동하며, 끊어지면
/// ViewModel 이 시작일을 새로 찍어주는 방식으로 초기화된다.
class StreakSection extends StatelessWidget {
  const StreakSection({
    super.key,
    required this.streakDays,
    required this.slots,
    required this.slotDates,
  })  : assert(slots.length == 7, 'slots 는 7칸이어야 합니다.'),
        assert(slotDates.length == 7, 'slotDates 는 7칸이어야 합니다.');

  final int streakDays;
  final List<bool> slots;
  final List<DateTime> slotDates;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.streakBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔥 $streakDays일 연속 달성 중!',
            style: AppTextStyles.labelLarge.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _StreakEntry(
                  achieved: slots[i],
                  date: slotDates[i],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakEntry extends StatelessWidget {
  const _StreakEntry({required this.achieved, required this.date});

  final bool achieved;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreakDot(achieved: achieved),
        const SizedBox(height: 4),
        Text(
          _formatMMdd(date),
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  static String _formatMMdd(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
}

class _StreakDot extends StatelessWidget {
  const _StreakDot({required this.achieved});

  final bool achieved;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: achieved ? AppColors.streakCheck : AppColors.streakCheckX,
        shape: BoxShape.circle,
      ),
    );
  }
}