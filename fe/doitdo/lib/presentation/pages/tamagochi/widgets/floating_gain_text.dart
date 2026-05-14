import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:doitdo/core/theme/app_text_styles.dart';
import 'package:doitdo/presentation/pages/shop/widgets/coin_icon.dart';

/// 캐릭터 탭 시 손가락 위치에서 "+N" 코인 표시가 살짝 솟아오르며 페이드아웃되는
/// 부유 텍스트. 자체 [AnimationController] 로 라이프사이클을 관리하며, 종료
/// 시점에 [onComplete] 를 호출해 부모가 트리에서 제거하도록 한다.
///
/// 부모는 이 위젯을 [Positioned] 의 left/top 에 손가락 좌표를 그대로 넘기고,
/// 위젯 내부에서 [FractionalTranslation] 으로 자기 폭/높이의 -50% 만큼 보정해
/// (탭한 좌표 = 시각적 중앙) 이 되도록 한다.
class FloatingGainText extends StatefulWidget {
  const FloatingGainText({
    super.key,
    required this.amount,
    required this.onComplete,
  });

  final int amount;
  final VoidCallback onComplete;

  @override
  State<FloatingGainText> createState() => _FloatingGainTextState();
}

class _FloatingGainTextState extends State<FloatingGainText>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 1500);
  static const double _riseDistance = 36;

  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translateY;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _duration);
    // pop in (0~15%) → hold (15~60%) → fade out (60~100%).
    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 45),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1, end: 0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_ctrl);
    _translateY = Tween<double>(begin: 0, end: -_riseDistance)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    // 가벼운 over-shoot: 작게 시작해 살짝 부풀었다 1.0 로 안착.
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 65),
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
    // 부모가 left/top 에 손가락 글로벌 좌표를 그대로 넣을 수 있게, 자체적으로
    // -50% 보정해 그 좌표가 위젯의 시각 중심이 되도록 한다.
    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _translateY.value),
            child: Opacity(
              opacity: _opacity.value,
              child: Transform.scale(scale: _scale.value, child: child),
            ),
          );
        },
        child: _GainPill(amount: widget.amount),
      ),
    );
  }
}

class _GainPill extends StatelessWidget {
  const _GainPill({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    // 배경 없이 텍스트 + 코인 아이콘만. 어떤 배경(밝은 grass / 다크모드 / 흰 카드)
    // 위에서도 읽히도록 텍스트는 4방향 1px 검정 외곽선 + 살짝 큰 drop shadow 로
    // 처리. 코인 아이콘도 떠보이도록 drop shadow.
    const outlineColor = Colors.black;
    final textShadows = <Shadow>[
      const Shadow(color: outlineColor, offset: Offset(-1, -1), blurRadius: 0),
      const Shadow(color: outlineColor, offset: Offset(1, -1), blurRadius: 0),
      const Shadow(color: outlineColor, offset: Offset(-1, 1), blurRadius: 0),
      const Shadow(color: outlineColor, offset: Offset(1, 1), blurRadius: 0),
      Shadow(
        color: Colors.black.withValues(alpha: 0.35),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CoinIcon(size: 18.sp),
        ),
        SizedBox(width: 4.w),
        Text(
          '+$amount',
          style: AppTextStyles.bodyMedium.copyWith(
            color: const Color(0xFFFFD27A),
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            height: 1.1,
            shadows: textShadows,
          ),
        ),
      ],
    );
  }
}
