import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/core/theme/doitdo_colors.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';

/// 일일 자동 출석 보상 셀러브레이션 오버레이.
///
/// 부모가 `Positioned` 등으로 위치를 잡아주는 작은 카드 위젯. 자체적으로는
/// pop-in → 짧게 유지 → 위로 살짝 떠오르며 fade-out 만 처리. `IgnorePointer` 라
/// 입력을 가로채지 않으며, 종료 시 [onComplete] 로 부모가 트리에서 제거하도록 한다.
///
/// 시각 언어는 캐릭터 탭의 floating "+N" 과 구분된다 — 탭 보상은 손가락
/// 위치의 작은 부유 텍스트, 출석 보상은 캐릭터 카드 위에 떠오르는 작은 토스트형 카드.
class AttendanceCelebration extends StatefulWidget {
  const AttendanceCelebration({
    super.key,
    required this.amount,
    required this.onComplete,
  });

  final int amount;
  final VoidCallback onComplete;

  @override
  State<AttendanceCelebration> createState() => _AttendanceCelebrationState();
}

class _AttendanceCelebrationState extends State<AttendanceCelebration>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 2000);

  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _floatY;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    // pop-in (0~13%) → hold (13~70%) → fade-out (70~100%)
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 13,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 57),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);
    // 가벼운 fade-in 효과 — over-shoot 은 최소화하고 거의 즉시 1.0 으로 안착.
    // 페이드아웃 구간에서도 살짝(1.02)만 부풀어 "둥실" 정도의 잔효과만 남긴다.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.92, end: 1.02)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 45),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);
    // 페이드아웃 구간에서 천천히 위로 떠오름.
    _floatY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 70),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -24)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(_ctrl);

    _ctrl.forward().whenComplete(() {
      if (!mounted) return;
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.translate(
              offset: Offset(0, _floatY.value),
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          );
        },
        child: _CelebrationCard(amount: widget.amount),
      ),
    );
  }
}

class _CelebrationCard extends StatelessWidget {
  const _CelebrationCard({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 캐릭터 카드 위에 떠오르는 작은 사각 카드. 흰 배경에 살짝 투명도(alpha 0.88)
    // 를 줘 뒤 일러스트가 은은히 비치게 한다 — 무거운 인상을 줄이는 의도.
    return Container(
      width: 124.w,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18.r),
        border:
            Border.all(color: colors.border.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🎁', style: TextStyle(fontSize: 24.sp, height: 1.0)),
          SizedBox(height: 8.h),
          Text(
            '출석 보상',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoinIcon(size: 14.sp),
              SizedBox(width: 4.w),
              Text(
                '+$amount',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: const Color(0xFFE2782B),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
