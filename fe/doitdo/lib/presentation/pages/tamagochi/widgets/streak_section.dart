import 'package:flutter/material.dart';

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
  }) : assert(slots.length == 7, 'slots 는 7칸이어야 합니다.');

  final int streakDays;
  final List<bool> slots;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.streakCardBg,
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
              for (var i = 0; i < 7; i++) _StreakDot(achieved: slots[i]),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  const _StreakDot({required this.achieved});

  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        // 라이트는 브랜드 오렌지 / 라이트 그레이, 다크는 톤 다운된 오렌지 / 다크 그레이.
        color:
            achieved ? colors.streakDotActive : colors.streakDotInactive,
        shape: BoxShape.circle,
      ),
    );
  }
}