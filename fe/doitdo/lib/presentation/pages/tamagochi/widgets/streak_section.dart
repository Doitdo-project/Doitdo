import 'package:flutter/material.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';

/// 스트릭 시작일(slot[0])부터 7일 단위 블록으로 진행 상황을 표시한다.
/// 스트릭이 7일을 넘기면 다음 7일 블록으로 통째로 이동하며, 끊어지면
/// ViewModel 이 시작일을 새로 찍어주는 방식으로 초기화된다.
///
/// 7칸을 모두 채운 시점부터 [isRewardClaimable] 이 true 가 되어 우상단에
/// "🎁 보상 받기" CTA 가 노출된다. 탭 시 [onClaimReward] 콜백 발화.
class StreakSection extends StatelessWidget {
  const StreakSection({
    super.key,
    required this.streakDays,
    required this.slots,
    this.isRewardClaimable = false,
    this.isClaimingReward = false,
    this.onClaimReward,
  }) : assert(slots.length == 7, 'slots 는 7칸이어야 합니다.');

  final int streakDays;
  final List<bool> slots;

  /// 7일 블록을 모두 채워 보상 수령이 가능한 상태인지.
  final bool isRewardClaimable;

  /// 보상 수령 API 진행 중인지. true 면 버튼 비활성화 + 스피너.
  final bool isClaimingReward;

  /// "보상 받기" 버튼 탭 콜백. null 이면 [isRewardClaimable] 이 true 여도 노출하지 않음.
  final VoidCallback? onClaimReward;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final showRewardCta = isRewardClaimable && onClaimReward != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colors.streakCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🔥 $streakDays일 연속 달성 중!',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (showRewardCta) _RewardButton(
                isLoading: isClaimingReward,
                onTap: onClaimReward!,
              ),
            ],
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

class _RewardButton extends StatelessWidget {
  const _RewardButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.streakDotActive,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '🎁 보상 받기',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
